-- ============================================================================
-- MULTI-ESTABELECIMENTO: VIEWS E FUNÇÕES CIENTES DE estabelecimento_id
-- ============================================================================
-- Arquivo: 13_views_funcoes_tenant.sql
-- Descrição: Recria as views existentes para (a) expor a coluna
--            estabelecimento_id e (b) respeitar o isolamento por RLS das
--            tabelas base via security_invoker. Também recria as funções
--            existentes que escrevem em Tabelas_de_Dominio para propagar o
--            estabelecimento_id (evitando violar o NOT NULL aplicado em 12).
-- Ordem de execução: APÓS 12_tenant_not_null_e_rls.sql.
-- Requisitos: 5.8 (views), 5.9 (funções)
-- Data: 21/01/2026
-- ============================================================================
-- NOTA SOBRE security_invoker:
--   Por padrão, uma view no PostgreSQL roda com os privilégios do DONO da view,
--   então NÃO aplica a RLS do usuário que a consulta — o que vazaria dados entre
--   estabelecimentos. A partir do PostgreSQL 15 (este banco é PG17) é possível
--   definir `WITH (security_invoker = true)`, fazendo a view respeitar a RLS das
--   tabelas base com os direitos do INVOCADOR. Todas as views abaixo usam
--   security_invoker = true para herdar o isolamento por tenant (Req 5.8).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Assistente IA: vw_conversas_resumo  (agrega contadores por conversa)
-- Expõe estabelecimento_id para escopo por tenant.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_conversas_resumo
WITH (security_invoker = true) AS
SELECT
  id,
  estabelecimento_id,
  status,
  jsonb_array_length(mensagens) AS total_mensagens,
  dados_extraidos->>'nome' AS produto_nome,
  (SELECT COUNT(*) FROM ia_arquivos_temp WHERE conversa_id = ia_conversas.id) AS total_arquivos,
  criado_em,
  atualizado_em
FROM ia_conversas;

COMMENT ON VIEW vw_conversas_resumo IS 'Resumo das conversas do assistente IA com contadores (escopo por estabelecimento via RLS)';

-- ----------------------------------------------------------------------------
-- Assistente IA: vw_arquivos_por_conversa
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_arquivos_por_conversa
WITH (security_invoker = true) AS
SELECT
  c.id AS conversa_id,
  c.estabelecimento_id,
  c.status AS conversa_status,
  a.nome_arquivo,
  a.tipo_arquivo,
  a.url_arquivo,
  a.criado_em AS arquivo_criado_em
FROM ia_conversas c
LEFT JOIN ia_arquivos_temp a ON a.conversa_id = c.id;

COMMENT ON VIEW vw_arquivos_por_conversa IS 'Arquivos associados a cada conversa do assistente IA (escopo por estabelecimento via RLS)';

-- ----------------------------------------------------------------------------
-- vw_pedidos_completos  (pedido + dados do cliente)
-- p.* já inclui p.estabelecimento_id; qualificamos colunas para evitar
-- ambiguidade com clientes.estabelecimento_id.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_pedidos_completos
WITH (security_invoker = true) AS
SELECT
  p.*,
  c.total_pedidos AS cliente_total_pedidos,
  c.valor_total_gasto AS cliente_valor_total_gasto
FROM pedidos p
LEFT JOIN clientes c ON p.cliente_id = c.id;

COMMENT ON VIEW vw_pedidos_completos IS 'Pedidos com informações adicionais do cliente (escopo por estabelecimento via RLS; estabelecimento_id vem de pedidos)';

-- ----------------------------------------------------------------------------
-- vw_produtos_com_categoria
-- p.* inclui p.estabelecimento_id (do produto).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_produtos_com_categoria
WITH (security_invoker = true) AS
SELECT
  p.*,
  cat.nome AS categoria_nome_completo,
  cat.tem_sabores,
  cat.tem_borda,
  cat.tem_tamanhos,
  cat.tem_adicionais
FROM produtos p
LEFT JOIN categorias cat ON p.categoria_id = cat.id;

COMMENT ON VIEW vw_produtos_com_categoria IS 'Produtos com informações completas da categoria (escopo por estabelecimento via RLS)';

-- ----------------------------------------------------------------------------
-- vw_estatisticas_pedidos_dia  (AGREGADA — agora por estabelecimento + data)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_estatisticas_pedidos_dia
WITH (security_invoker = true) AS
SELECT
  estabelecimento_id,
  DATE(criado_em) AS data,
  COUNT(*) AS total_pedidos,
  SUM(total) AS valor_total,
  AVG(total) AS ticket_medio,
  COUNT(DISTINCT cliente_id) AS clientes_unicos
FROM pedidos
GROUP BY estabelecimento_id, DATE(criado_em)
ORDER BY data DESC;

COMMENT ON VIEW vw_estatisticas_pedidos_dia IS 'Estatísticas diárias de pedidos agrupadas por estabelecimento e data';

-- ----------------------------------------------------------------------------
-- vw_produtos_mais_vendidos  (AGREGADA — agora por estabelecimento)
-- Reescrita com subconsulta lateral para extrair itens do JSONB sem repetir
-- jsonb_array_elements em colunas distintas (evita produto cartesiano de set).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_produtos_mais_vendidos
WITH (security_invoker = true) AS
SELECT
  p.estabelecimento_id,
  item->>'nome' AS produto_nome,
  COUNT(*) AS quantidade_vendida,
  SUM((item->>'preco')::numeric) AS valor_total
FROM pedidos p
CROSS JOIN LATERAL jsonb_array_elements(p.itens) AS item
WHERE p.status NOT IN ('Cancelado')
GROUP BY p.estabelecimento_id, item->>'nome'
ORDER BY quantidade_vendida DESC;

COMMENT ON VIEW vw_produtos_mais_vendidos IS 'Ranking de produtos mais vendidos por estabelecimento';

-- ----------------------------------------------------------------------------
-- vw_comandas_abertas
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_comandas_abertas
WITH (security_invoker = true) AS
SELECT
  estabelecimento_id,
  numero_comanda,
  status,
  jsonb_array_length(itens) AS total_itens,
  subtotal,
  total,
  criado_em,
  atualizado_em,
  EXTRACT(EPOCH FROM (NOW() - criado_em))/60 AS minutos_aberta
FROM comandas
WHERE status = 'aberta'
ORDER BY numero_comanda;

COMMENT ON VIEW vw_comandas_abertas IS 'Comandas abertas com tempo de abertura (escopo por estabelecimento via RLS)';

-- ----------------------------------------------------------------------------
-- vw_avaliacoes_publicas  (média recalculada POR estabelecimento)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_avaliacoes_publicas
WITH (security_invoker = true) AS
SELECT
  a.*,
  (SELECT AVG(estrelas)
     FROM avaliacoes a2
    WHERE a2.aprovada = true
      AND a2.estabelecimento_id = a.estabelecimento_id) AS media_geral
FROM avaliacoes a
WHERE a.aprovada = true
ORDER BY a.criado_em DESC;

COMMENT ON VIEW vw_avaliacoes_publicas IS 'Avaliações aprovadas com média por estabelecimento (escopo via RLS)';

-- ----------------------------------------------------------------------------
-- vw_estoque_baixo  (estoque legado; e.* inclui estabelecimento_id)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_estoque_baixo
WITH (security_invoker = true) AS
SELECT
  e.*,
  (e.quantidade_minima - e.quantidade) AS deficit
FROM estoque e
WHERE e.quantidade <= e.quantidade_minima
ORDER BY deficit DESC;

COMMENT ON VIEW vw_estoque_baixo IS 'Itens de estoque abaixo do mínimo (escopo por estabelecimento via RLS)';

-- ----------------------------------------------------------------------------
-- vw_funcionarios_ativos  (f.* inclui estabelecimento_id)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_funcionarios_ativos
WITH (security_invoker = true) AS
SELECT
  f.*,
  CASE
    WHEN f.bloqueado THEN 'Bloqueado'
    WHEN NOT f.ativo THEN 'Inativo'
    ELSE 'Ativo'
  END AS status_completo
FROM funcionarios f
WHERE f.ativo = true AND f.bloqueado = false;

COMMENT ON VIEW vw_funcionarios_ativos IS 'Funcionários ativos e não bloqueados (escopo por estabelecimento via RLS)';

-- ============================================================================
-- FUNÇÕES — análise e atualizações
-- ============================================================================
-- Revisão das funções de 02_functions.sql quanto à necessidade de escopo por
-- estabelecimento (Req 5.9):
--
--   * atualizar_timestamp / update_comandas_updated_at /
--     update_tamanhos_updated_at / update_updated_at_column
--       -> Triggers BEFORE que só ajustam NEW.atualizado_em. Operam sobre a
--          própria linha; NÃO precisam de estabelecimento_id. SEM ALTERAÇÃO.
--
--   * obter_ultima_mensagem(uuid) / contar_conversas_por_status() /
--     limpar_arquivos_orfaos()
--       -> Funções utilitárias de IA. Quando chamadas por um usuário via API,
--          rodam sob a RLS das tabelas base (não são SECURITY DEFINER), então já
--          ficam limitadas aos dados acessíveis. contar_conversas_por_status já
--          poderia ganhar estabelecimento_id, mas não é usada em caminho
--          multi-tenant crítico; mantida SEM ALTERAÇÃO para não quebrar
--          assinaturas. (Pode ser revista futuramente.)
--
--   * sync_pedido_status_to_historico()
--       -> CRÍTICA: insere em historico_pedidos, que agora tem
--          estabelecimento_id NOT NULL (arquivo 12). A versão original NÃO
--          informava estabelecimento_id, o que passaria a violar a constraint.
--          RECRIADA ABAIXO para propagar NEW.estabelecimento_id.
-- ----------------------------------------------------------------------------

-- Recriação: propaga o estabelecimento_id do pedido para o histórico (Req 5.9).
CREATE OR REPLACE FUNCTION public.sync_pedido_status_to_historico()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO historico_pedidos (pedido_id, status, observacao, estabelecimento_id)
    VALUES (
      COALESCE(NEW.codigo_pedido, NEW.pedido_id),
      NEW.status,
      'Status atualizado automaticamente para ' || NEW.status,
      NEW.estabelecimento_id
    );
  END IF;
  RETURN NEW;
END;
$function$;

COMMENT ON FUNCTION public.sync_pedido_status_to_historico() IS
  'Sincroniza mudança de status do pedido para historico_pedidos, propagando estabelecimento_id (multi-tenant).';

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================

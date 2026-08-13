-- ============================================================================
-- VIEWS ÚTEIS - CORRIGIDO
-- ============================================================================

-- View: Conversas com resumo (Assistente IA)
CREATE OR REPLACE VIEW vw_conversas_resumo AS
SELECT 
  id,
  status,
  jsonb_array_length(mensagens) as total_mensagens,
  dados_extraidos->>'nome' as produto_nome,
  (SELECT COUNT(*) FROM ia_arquivos_temp WHERE conversa_id = ia_conversas.id) as total_arquivos,
  criado_em,
  atualizado_em
FROM ia_conversas;

-- View: Arquivos por conversa (Assistente IA)
CREATE OR REPLACE VIEW vw_arquivos_por_conversa AS
SELECT 
  c.id as conversa_id,
  c.status as conversa_status,
  a.nome_arquivo,
  a.tipo_arquivo,
  a.url_arquivo,
  a.criado_em as arquivo_criado_em
FROM ia_conversas c
LEFT JOIN ia_arquivos_temp a ON a.conversa_id = c.id;

-- View: Pedidos com informações do cliente
CREATE OR REPLACE VIEW vw_pedidos_completos AS
SELECT 
  p.*,
  c.total_pedidos as cliente_total_pedidos,
  c.valor_total_gasto as cliente_valor_total_gasto
FROM pedidos p
LEFT JOIN clientes c ON p.cliente_id = c.id;

-- View: Produtos com categoria
CREATE OR REPLACE VIEW vw_produtos_com_categoria AS
SELECT 
  p.*,
  cat.nome as categoria_nome_completo,
  cat.tem_sabores,
  cat.tem_borda,
  cat.tem_tamanhos,
  cat.tem_adicionais
FROM produtos p
LEFT JOIN categorias cat ON p.categoria_id = cat.id;

-- View: Estatísticas de pedidos por dia
CREATE OR REPLACE VIEW vw_estatisticas_pedidos_dia AS
SELECT 
  DATE(criado_em) as data,
  COUNT(*) as total_pedidos,
  SUM(total) as valor_total,
  AVG(total) as ticket_medio,
  COUNT(DISTINCT cliente_id) as clientes_unicos
FROM pedidos
GROUP BY DATE(criado_em)
ORDER BY data DESC;

-- View: Produtos mais vendidos (CORRIGIDA)
CREATE OR REPLACE VIEW vw_produtos_mais_vendidos AS
WITH itens_expandidos AS (
  SELECT 
    jsonb_array_elements(itens) as item
  FROM pedidos
  WHERE status NOT IN ('Cancelado')
)
SELECT 
  item->>'nome' as produto_nome,
  COUNT(*) as quantidade_vendida,
  SUM((item->>'preco')::numeric) as valor_total
FROM itens_expandidos
GROUP BY item->>'nome'
ORDER BY quantidade_vendida DESC;

-- View: Comandas abertas com resumo
CREATE OR REPLACE VIEW vw_comandas_abertas AS
SELECT 
  numero_comanda,
  status,
  jsonb_array_length(itens) as total_itens,
  subtotal,
  total,
  criado_em,
  atualizado_em,
  EXTRACT(EPOCH FROM (NOW() - criado_em))/60 as minutos_aberta
FROM comandas
WHERE status = 'aberta'
ORDER BY numero_comanda;

-- View: Avaliações aprovadas com média
CREATE OR REPLACE VIEW vw_avaliacoes_publicas AS
SELECT 
  *,
  (SELECT AVG(estrelas) FROM avaliacoes WHERE aprovada = true) as media_geral
FROM avaliacoes
WHERE aprovada = true
ORDER BY criado_em DESC;

-- View: Estoque baixo
CREATE OR REPLACE VIEW vw_estoque_baixo AS
SELECT 
  *,
  (quantidade_minima - quantidade) as deficit
FROM estoque
WHERE quantidade <= quantidade_minima
ORDER BY deficit DESC;

-- View: Funcionários ativos
CREATE OR REPLACE VIEW vw_funcionarios_ativos AS
SELECT 
  f.*,
  CASE 
    WHEN f.bloqueado THEN 'Bloqueado'
    WHEN NOT f.ativo THEN 'Inativo'
    ELSE 'Ativo'
  END as status_completo
FROM funcionarios f
WHERE f.ativo = true AND f.bloqueado = false;

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================

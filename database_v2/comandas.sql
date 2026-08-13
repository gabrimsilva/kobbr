-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - COMANDAS (MESAS/ATENDIMENTO LOCAL)
-- ============================================================================
-- Sistema de comandas para restaurante/pizzaria com mesas
-- Complementa todos os SQLs anteriores
-- ============================================================================

-- ============================================================================
-- FILOSOFIA: COMANDA SEMPRE VIRA PEDIDO
-- ============================================================================
-- 
-- REGRA FUNDAMENTAL: Toda comanda fechada gera um pedido
-- 
-- Por quê sempre virar pedido?
--   ✅ Histórico completo (até cancelamentos)
--   ✅ Auditoria (quem pediu o quê, quando)
--   ✅ Relatórios precisos de vendas
--   ✅ Estoque rastreável (consumo via pedidos)
--   ✅ Integração com PDV (pagamento)
-- 
-- Fluxo básico:
--   1. Garçom abre comanda na Mesa 5
--   2. Adiciona itens (pizza, bebida, sobremesa)
--   3. Cozinha prepara (status: pendente → preparando → pronto)
--   4. Garçom entrega (status: entregue)
--   5. Cliente pede conta
--   6. Sistema converte comanda → pedido (snapshot)
--   7. Pagamento no PDV
--   8. Fecha comanda
-- 
-- Cancelamento:
--   - Comanda pode ser cancelada antes de virar pedido
--   - Comanda cancelada TAMBÉM vira pedido (status='cancelado')
--   - Mantém histórico e auditoria
-- 
-- Divisão de conta:
--   - Mesa 5 pode virar 2 ou mais pedidos
--   - Cada cliente paga sua parte
--   - Itens são distribuídos entre as divisões
-- 
-- ============================================================================

-- ============================================================================
-- TABELA: comandas_mesas
-- ============================================================================
-- Cadastro de mesas do restaurante
-- Mínimo 24 mesas, pode adicionar mais conforme necessário
CREATE TABLE comandas_mesas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loja_id UUID NOT NULL REFERENCES lojas(id) ON DELETE CASCADE,
    
    -- Identificação
    numero_mesa INTEGER NOT NULL, -- 1, 2, 3... 24+
    nome TEXT, -- Opcional: "Mesa VIP", "Varanda", "Salão Principal"
    
    -- Capacidade
    capacidade_pessoas INTEGER DEFAULT 4 CHECK (capacidade_pessoas > 0),
    
    -- Localização/Área
    area TEXT, -- Ex: "Salão Principal", "Varanda", "Área Externa"
    
    -- Ordenação e status
    ordem_exibicao INTEGER DEFAULT 0,
    ativa BOOLEAN DEFAULT true,
    
    -- Soft delete
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Auditoria
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação: mesmo número de mesa não pode aparecer 2x na mesma loja
    UNIQUE(loja_id, numero_mesa)
);

-- Índices para performance
CREATE INDEX idx_comandas_mesas_loja ON comandas_mesas(loja_id);
CREATE INDEX idx_comandas_mesas_ativa ON comandas_mesas(ativa);
CREATE INDEX idx_comandas_mesas_deleted_at ON comandas_mesas(deleted_at);
CREATE INDEX idx_comandas_mesas_area ON comandas_mesas(area);

-- ============================================================================
-- TABELA: comandas
-- ============================================================================
-- Comandas abertas (mesas ocupadas)
CREATE TABLE comandas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loja_id UUID NOT NULL REFERENCES lojas(id) ON DELETE CASCADE,
    mesa_id UUID NOT NULL REFERENCES comandas_mesas(id) ON DELETE RESTRICT,
    
    -- Identificação
    numero_comanda INTEGER NOT NULL, -- Número sequencial por loja (gerado pelo backend)
    
    -- Status
    status TEXT NOT NULL DEFAULT 'aberta' CHECK (status IN (
        'aberta', 'aguardando_pagamento', 'fechada', 'cancelada'
    )),
    
    -- Abertura
    aberta_por UUID NOT NULL REFERENCES auth.users(id), -- Garçom
    aberta_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Fechamento
    fechada_por UUID REFERENCES auth.users(id),
    fechada_em TIMESTAMP WITH TIME ZONE,
    
    -- Cancelamento
    cancelada_por UUID REFERENCES auth.users(id),
    cancelada_em TIMESTAMP WITH TIME ZONE,
    motivo_cancelamento TEXT,
    
    -- Integração com pedido
    pedido_id UUID REFERENCES pedidos(id) ON DELETE SET NULL,
    -- IMPORTANTE: Quando comanda vira pedido, pedido_id é preenchido
    -- Se divisão de conta, apenas a primeira divisão preenche pedido_id
    -- As outras divisões criam pedidos separados (ver comanda_divisoes)
    
    -- Observações
    observacoes TEXT,
    
    -- Soft delete (consistência com resto do banco)
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Auditoria
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação: mesmo número de comanda não pode aparecer 2x na mesma loja
    UNIQUE(loja_id, numero_comanda)
);

-- Índices para performance
CREATE INDEX idx_comandas_loja ON comandas(loja_id);
CREATE INDEX idx_comandas_mesa ON comandas(mesa_id);
CREATE INDEX idx_comandas_status ON comandas(status);
CREATE INDEX idx_comandas_aberta_por ON comandas(aberta_por);
CREATE INDEX idx_comandas_fechada_por ON comandas(fechada_por);
CREATE INDEX idx_comandas_aberta_em ON comandas(aberta_em DESC);
CREATE INDEX idx_comandas_pedido ON comandas(pedido_id);
CREATE INDEX idx_comandas_deleted_at ON comandas(deleted_at);

-- Índice único parcial: apenas uma comanda aberta por mesa (não deletadas)
CREATE UNIQUE INDEX idx_comandas_mesa_aberta 
    ON comandas(mesa_id) 
    WHERE status = 'aberta' AND deleted_at IS NULL;

-- ============================================================================
-- TABELA: comanda_itens
-- ============================================================================
-- Itens da comanda (antes de virar pedido)
-- Estrutura similar a pedido_itens, mas com status de preparo
CREATE TABLE comanda_itens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comanda_id UUID NOT NULL REFERENCES comandas(id) ON DELETE CASCADE,
    
    -- Tipo do item
    tipo_item TEXT NOT NULL CHECK (tipo_item IN ('produto', 'combo')),
    
    -- Referências (apenas uma será preenchida)
    produto_id UUID REFERENCES produtos(id) ON DELETE RESTRICT,
    combo_id UUID REFERENCES combos(id) ON DELETE RESTRICT,
    
    -- Snapshot do item (preserva dados se produto/combo for alterado)
    nome TEXT NOT NULL,
    descricao TEXT,
    
    -- Tamanho escolhido (apenas para produtos)
    tamanho_id UUID REFERENCES tamanhos(id) ON DELETE RESTRICT,
    tamanho_label TEXT, -- Ex: P, M, G (snapshot)
    
    -- Quantidade e valores
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    valor_unitario NUMERIC(10, 2) NOT NULL CHECK (valor_unitario >= 0),
    valor_total NUMERIC(10, 2) NOT NULL CHECK (valor_total >= 0),
    
    -- Status de preparo (importante para cozinha)
    status TEXT NOT NULL DEFAULT 'pendente' CHECK (status IN (
        'pendente', 'preparando', 'pronto', 'entregue', 'cancelado'
    )),
    
    -- Observações do item
    observacoes TEXT,
    
    -- Ordenação
    ordem_exibicao INTEGER DEFAULT 0,
    
    -- Auditoria
    adicionado_por UUID NOT NULL REFERENCES auth.users(id), -- Garçom
    adicionado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Validação: produto OU combo (não ambos)
    CHECK (
        (tipo_item = 'produto' AND produto_id IS NOT NULL AND combo_id IS NULL) OR
        (tipo_item = 'combo' AND combo_id IS NOT NULL AND produto_id IS NULL)
    )
);

-- Índices para performance
CREATE INDEX idx_comanda_itens_comanda ON comanda_itens(comanda_id);
CREATE INDEX idx_comanda_itens_produto ON comanda_itens(produto_id);
CREATE INDEX idx_comanda_itens_combo ON comanda_itens(combo_id);
CREATE INDEX idx_comanda_itens_status ON comanda_itens(status);
CREATE INDEX idx_comanda_itens_adicionado_por ON comanda_itens(adicionado_por);

-- ============================================================================
-- TABELA: comanda_item_sabores
-- ============================================================================
-- Sabores escolhidos para produtos da comanda
CREATE TABLE comanda_item_sabores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comanda_item_id UUID NOT NULL REFERENCES comanda_itens(id) ON DELETE CASCADE,
    sabor_id UUID REFERENCES sabores(id) ON DELETE RESTRICT,
    
    -- Snapshot do sabor
    sabor_nome TEXT NOT NULL,
    sabor_descricao TEXT,
    
    -- Valor adicional cobrado (se houver)
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_comanda_item_sabores_item ON comanda_item_sabores(comanda_item_id);
CREATE INDEX idx_comanda_item_sabores_sabor ON comanda_item_sabores(sabor_id);

-- ============================================================================
-- TABELA: comanda_item_borda
-- ============================================================================
-- Borda escolhida para produtos da comanda (se houver)
CREATE TABLE comanda_item_borda (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comanda_item_id UUID NOT NULL REFERENCES comanda_itens(id) ON DELETE CASCADE,
    borda_id UUID REFERENCES bordas(id) ON DELETE RESTRICT,
    
    -- Snapshot da borda
    borda_nome TEXT NOT NULL,
    borda_descricao TEXT,
    
    -- Valor adicional cobrado
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Um item só pode ter uma borda
    UNIQUE(comanda_item_id)
);

-- Índices para performance
CREATE INDEX idx_comanda_item_borda_item ON comanda_item_borda(comanda_item_id);
CREATE INDEX idx_comanda_item_borda_borda ON comanda_item_borda(borda_id);

-- ============================================================================
-- TABELA: comanda_item_adicionais
-- ============================================================================
-- Adicionais escolhidos para produtos da comanda
CREATE TABLE comanda_item_adicionais (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comanda_item_id UUID NOT NULL REFERENCES comanda_itens(id) ON DELETE CASCADE,
    adicional_id UUID REFERENCES adicionais(id) ON DELETE RESTRICT,
    
    -- Snapshot do adicional
    adicional_nome TEXT NOT NULL,
    adicional_descricao TEXT,
    
    -- Quantidade e valor
    quantidade INTEGER NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    valor_unitario NUMERIC(10, 2) NOT NULL CHECK (valor_unitario >= 0),
    valor_total NUMERIC(10, 2) NOT NULL CHECK (valor_total >= 0),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_comanda_item_adicionais_item ON comanda_item_adicionais(comanda_item_id);
CREATE INDEX idx_comanda_item_adicionais_adicional ON comanda_item_adicionais(adicional_id);

-- ============================================================================
-- TABELA: comanda_divisoes
-- ============================================================================
-- Divisão de conta (quando mesa é dividida em múltiplos pagamentos)
-- Exemplo: Mesa 5 com 4 pessoas, cada uma paga sua parte
CREATE TABLE comanda_divisoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comanda_id UUID NOT NULL REFERENCES comandas(id) ON DELETE CASCADE,
    
    -- Identificação da divisão
    numero_divisao INTEGER NOT NULL CHECK (numero_divisao > 0), -- 1, 2, 3...
    descricao TEXT, -- Ex: "Cliente 1", "Conta A"
    
    -- Valor total desta divisão
    valor_total NUMERIC(10, 2) NOT NULL CHECK (valor_total >= 0),
    
    -- Pedido gerado por esta divisão
    pedido_id UUID REFERENCES pedidos(id) ON DELETE SET NULL,
    
    -- Auditoria
    criado_por UUID NOT NULL REFERENCES auth.users(id),
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação
    UNIQUE(comanda_id, numero_divisao)
);

-- Índices para performance
CREATE INDEX idx_comanda_divisoes_comanda ON comanda_divisoes(comanda_id);
CREATE INDEX idx_comanda_divisoes_pedido ON comanda_divisoes(pedido_id);

-- ============================================================================
-- TABELA: comanda_divisao_itens
-- ============================================================================
-- Distribui itens da comanda entre as divisões
-- Permite quantidade parcial (ex: 2 de 3 pizzas vão para divisão 1)
CREATE TABLE comanda_divisao_itens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    divisao_id UUID NOT NULL REFERENCES comanda_divisoes(id) ON DELETE CASCADE,
    comanda_item_id UUID NOT NULL REFERENCES comanda_itens(id) ON DELETE CASCADE,
    
    -- Quantidade deste item nesta divisão
    quantidade NUMERIC(10, 3) NOT NULL CHECK (quantidade > 0),
    
    -- Valor proporcional
    valor_unitario NUMERIC(10, 2) NOT NULL CHECK (valor_unitario >= 0),
    valor_total NUMERIC(10, 2) NOT NULL CHECK (valor_total >= 0),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_comanda_divisao_itens_divisao ON comanda_divisao_itens(divisao_id);
CREATE INDEX idx_comanda_divisao_itens_item ON comanda_divisao_itens(comanda_item_id);

-- ============================================================================
-- TRIGGERS PARA ATUALIZAR updated_at
-- ============================================================================

CREATE TRIGGER update_comandas_mesas_updated_at
    BEFORE UPDATE ON comandas_mesas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comandas_updated_at
    BEFORE UPDATE ON comandas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View de mesas com status (ocupada/livre)
CREATE OR REPLACE VIEW comandas_mesas_status AS
SELECT 
    m.*,
    c.id AS comanda_id,
    c.numero_comanda,
    c.status AS comanda_status,
    c.aberta_em,
    CASE 
        WHEN c.id IS NOT NULL AND c.status = 'aberta' THEN 'OCUPADA'
        ELSE 'LIVRE'
    END AS status_mesa,
    COUNT(ci.id) AS total_itens,
    SUM(ci.valor_total) AS valor_total_comanda
FROM comandas_mesas m
LEFT JOIN comandas c ON m.id = c.mesa_id AND c.status = 'aberta'
LEFT JOIN comanda_itens ci ON c.id = ci.comanda_id AND ci.status != 'cancelado'
WHERE m.deleted_at IS NULL AND m.ativa = true
GROUP BY m.id, c.id, c.numero_comanda, c.status, c.aberta_em
ORDER BY m.ordem_exibicao, m.numero_mesa;

-- View de comandas abertas com detalhes
CREATE OR REPLACE VIEW comandas_abertas AS
SELECT 
    c.*,
    m.numero_mesa,
    m.nome AS mesa_nome,
    m.area AS mesa_area,
    p.nome AS aberta_por_nome,
    COUNT(ci.id) AS total_itens,
    COUNT(ci.id) FILTER (WHERE ci.status = 'pendente') AS itens_pendentes,
    COUNT(ci.id) FILTER (WHERE ci.status = 'preparando') AS itens_preparando,
    COUNT(ci.id) FILTER (WHERE ci.status = 'pronto') AS itens_prontos,
    COUNT(ci.id) FILTER (WHERE ci.status = 'entregue') AS itens_entregues,
    SUM(ci.valor_total) AS valor_total,
    EXTRACT(EPOCH FROM (NOW() - c.aberta_em))/60 AS minutos_aberta
FROM comandas c
INNER JOIN comandas_mesas m ON c.mesa_id = m.id
LEFT JOIN profiles p ON c.aberta_por = p.id
LEFT JOIN comanda_itens ci ON c.id = ci.comanda_id AND ci.status != 'cancelado'
WHERE c.status = 'aberta' AND c.deleted_at IS NULL
GROUP BY c.id, m.numero_mesa, m.nome, m.area, p.nome
ORDER BY c.aberta_em;

-- View de itens da comanda com detalhes
CREATE OR REPLACE VIEW comanda_itens_detalhado AS
SELECT 
    ci.*,
    c.numero_comanda,
    c.mesa_id,
    m.numero_mesa,
    p.nome AS adicionado_por_nome,
    ARRAY_AGG(DISTINCT cis.sabor_nome ORDER BY cis.sabor_nome) FILTER (WHERE cis.sabor_nome IS NOT NULL) AS sabores,
    cib.borda_nome,
    COUNT(DISTINCT cia.id) AS total_adicionais
FROM comanda_itens ci
INNER JOIN comandas c ON ci.comanda_id = c.id
INNER JOIN comandas_mesas m ON c.mesa_id = m.id
LEFT JOIN profiles p ON ci.adicionado_por = p.id
LEFT JOIN comanda_item_sabores cis ON ci.id = cis.comanda_item_id
LEFT JOIN comanda_item_borda cib ON ci.id = cib.comanda_item_id
LEFT JOIN comanda_item_adicionais cia ON ci.id = cia.comanda_item_id
GROUP BY ci.id, c.numero_comanda, c.mesa_id, m.numero_mesa, p.nome, cib.borda_nome
ORDER BY ci.adicionado_em DESC;

-- View de itens para cozinha (apenas pendentes e preparando)
CREATE OR REPLACE VIEW comanda_itens_cozinha AS
SELECT 
    ci.id,
    ci.comanda_id,
    c.numero_comanda,
    m.numero_mesa,
    ci.nome AS item_nome,
    ci.quantidade,
    ci.status,
    ci.observacoes,
    ci.adicionado_em,
    EXTRACT(EPOCH FROM (NOW() - ci.adicionado_em))/60 AS minutos_aguardando,
    ARRAY_AGG(DISTINCT cis.sabor_nome ORDER BY cis.sabor_nome) FILTER (WHERE cis.sabor_nome IS NOT NULL) AS sabores,
    cib.borda_nome
FROM comanda_itens ci
INNER JOIN comandas c ON ci.comanda_id = c.id
INNER JOIN comandas_mesas m ON c.mesa_id = m.id
LEFT JOIN comanda_item_sabores cis ON ci.id = cis.comanda_item_id
LEFT JOIN comanda_item_borda cib ON ci.id = cib.comanda_item_id
WHERE ci.status IN ('pendente', 'preparando')
  AND c.status = 'aberta'
  AND c.deleted_at IS NULL
GROUP BY ci.id, c.numero_comanda, m.numero_mesa, ci.nome, ci.quantidade, ci.status, ci.observacoes, ci.adicionado_em, cib.borda_nome
ORDER BY ci.adicionado_em;

-- ============================================================================
-- COMENTÁRIOS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE comandas_mesas IS 'Cadastro de mesas do restaurante. Mínimo 24 mesas, pode adicionar mais conforme necessário';
COMMENT ON TABLE comandas IS 'Comandas abertas (mesas ocupadas). Toda comanda fechada gera um pedido (tipo=local). Soft delete para correções operacionais';
COMMENT ON TABLE comanda_itens IS 'Itens da comanda antes de virar pedido. Estrutura similar a pedido_itens, mas com status de preparo';
COMMENT ON TABLE comanda_item_sabores IS 'Sabores escolhidos para produtos da comanda';
COMMENT ON TABLE comanda_item_borda IS 'Borda escolhida para produtos da comanda (máximo uma por item)';
COMMENT ON TABLE comanda_item_adicionais IS 'Adicionais escolhidos para produtos da comanda';
COMMENT ON TABLE comanda_divisoes IS 'Divisão de conta quando mesa é dividida em múltiplos pagamentos';
COMMENT ON TABLE comanda_divisao_itens IS 'Distribui itens da comanda entre as divisões. Permite quantidade parcial';

COMMENT ON COLUMN comandas.numero_comanda IS 'Número sequencial da comanda POR LOJA (gerado pelo backend). Evita "vazamento" de números entre lojas';
COMMENT ON COLUMN comandas.status IS 'Status: aberta (consumindo), aguardando_pagamento (conta pedida), fechada (paga e finalizada), cancelada (abortada antes de pagar)';
COMMENT ON COLUMN comandas.deleted_at IS 'Soft delete para correções operacionais. Mantém consistência com resto do banco';
COMMENT ON COLUMN comandas.pedido_id IS 'Pedido gerado quando comanda é fechada. NULL enquanto comanda está aberta. IMPORTANTE: Comanda SEMPRE vira pedido (mesmo se cancelada)';

COMMENT ON COLUMN comanda_itens.status IS 'Status de preparo: pendente (aguardando cozinha), preparando (em produção), pronto (aguardando entrega), entregue (na mesa), cancelado';

COMMENT ON COLUMN comanda_divisoes.numero_divisao IS 'Número da divisão (1, 2, 3...). Usado quando mesa é dividida em múltiplos pagamentos';
COMMENT ON COLUMN comanda_divisao_itens.quantidade IS 'Quantidade deste item nesta divisão. Pode ser parcial (ex: 2 de 3 pizzas). ⚠️ VALIDAÇÃO BACKEND: Somatório das quantidades por comanda_item_id NÃO PODE ultrapassar comanda_itens.quantidade';

COMMENT ON VIEW comandas_mesas_status IS 'View com mesas e status atual (ocupada/livre) com valor total da comanda';
COMMENT ON VIEW comandas_abertas IS 'View com comandas abertas e estatísticas (itens por status, valor total, tempo aberta)';
COMMENT ON VIEW comanda_itens_detalhado IS 'View com itens da comanda e informações relacionadas (sabores, bordas, adicionais)';
COMMENT ON VIEW comanda_itens_cozinha IS 'View com itens pendentes/preparando para exibição na cozinha';

-- ============================================================================
-- REGRAS DE NEGÓCIO (PARA BACKEND/FRONTEND)
-- ============================================================================
-- 
-- 1. ABERTURA DE COMANDA
--    - Apenas uma comanda aberta por mesa (garantido por índice único)
--    - Garçom deve ter permissão para abrir comanda
--    - Mesa deve estar ativa e não deletada
--    - Backend gera numero_comanda sequencial por loja
--    - Exemplo: SELECT COALESCE(MAX(numero_comanda), 0) + 1 FROM comandas WHERE loja_id = ?
-- 
-- 2. ADIÇÃO DE ITENS
--    - ✅ PODE adicionar itens enquanto status = 'aberta'
--    - ❌ NÃO PODE adicionar itens após status = 'aguardando_pagamento' ou 'fechada'
--    - Validação no backend (obrigatória): IF status != 'aberta' THEN bloquear
--    - Itens começam com status='pendente'
--    - Cozinha muda para 'preparando' → 'pronto'
--    - Garçom muda para 'entregue' quando leva para mesa
--    - Snapshot de valores no momento da adição
-- 
-- 3. CANCELAMENTO DE ITENS
--    - Item pode ser cancelado antes de ser preparado
--    - Item cancelado não entra no valor total
--    - Mantém histórico (não deletar)
-- 
-- 4. CANCELAMENTO DE COMANDA
--    - Comanda pode ser cancelada antes de virar pedido
--    - Comanda cancelada TAMBÉM vira pedido (status='cancelado')
--    - Motivo de cancelamento é obrigatório
--    - ⚠️ IMPORTANTE: Ao cancelar comanda, backend deve:
--      a) Marcar TODOS os itens como status='cancelado'
--      b) Gerar pedido com status='cancelado'
--      c) Fechar comanda com status='cancelada'
-- 
-- 5. VALOR TOTAL DA COMANDA (REGRA DE OURO)
--    - ⚠️ NUNCA salvar valor_total na tabela comandas
--    - ✅ SEMPRE calcular a partir dos itens não cancelados
--    - Fórmula: SUM(ci.valor_total) WHERE ci.status != 'cancelado'
--    - Views já fazem isso corretamente
--    - Mantém integridade: itens são fonte da verdade
-- 
-- 6. FECHAMENTO DE COMANDA (SEM DIVISÃO)
--    - Cliente pede conta (status muda para 'aguardando_pagamento')
--    - Sistema converte comanda → pedido (tipo='local')
--    - Snapshot de todos os itens não cancelados
--    - Pedido.comanda_id = comanda.id (vinculação explícita)
--    - Pagamento no PDV (pedido_pagamentos.caixa_id preenchido)
--    - Fecha comanda (status='fechada', pedido_id preenchido)
-- 
-- 7. DIVISÃO DE CONTA
--    - Cliente pede para dividir conta
--    - Sistema cria comanda_divisoes (divisão 1, 2, 3...)
--    - Garçom distribui itens entre divisões
--    - ⚠️ VALIDAÇÃO IMPORTANTE (backend):
--      Somatório de comanda_divisao_itens.quantidade por comanda_item_id
--      NÃO PODE ultrapassar comanda_itens.quantidade
--      Exemplo: Pizza tem quantidade=1, não pode dividir 0.6 + 0.5 (= 1.1)
--    - Cada divisão vira um pedido separado
--    - Pagamentos separados no PDV
--    - Fecha comanda quando todas divisões pagas
-- 
-- 8. INTEGRAÇÃO COM ESTOQUE
--    - Quando comanda vira pedido, consumo de estoque é registrado
--    - Usar produto_ingredientes para calcular consumo
--    - Criar movimentações tipo='saida_consumo'
-- 
-- 9. SEMÂNTICA DOS STATUS (DOCUMENTAÇÃO)
--    - 'aberta' = Mesa consumindo, PODE adicionar mais itens
--    - 'aguardando_pagamento' = Conta pedida, NÃO PODE adicionar mais itens
--    - 'fechada' = Paga e finalizada, mesa liberada
--    - 'cancelada' = Abortada antes de pagar (também vira pedido cancelado)
-- 
-- 10. INTEGRAÇÃO COM PDV (VINCULAÇÃO EXPLÍCITA)
--     - pedidos.comanda_id → comandas.id (vinculação bidirecional)
--     - comandas.pedido_id → pedidos.id (já existe)
--     - Permite rastrear: qual comanda gerou qual pedido
--     - Facilita relatórios e auditoria
--     - ✅ JÁ IMPLEMENTADO: Campo comanda_id em pedidos.sql
-- 
-- ============================================================================

-- ============================================================================
-- DADOS INICIAIS: 24 MESAS PADRÃO
-- ============================================================================

-- Inserir 24 mesas padrão para cada loja
-- Executar este INSERT após criar a primeira loja

/*
INSERT INTO comandas_mesas (loja_id, numero_mesa, capacidade_pessoas, area, ordem_exibicao)
SELECT 
    (SELECT id FROM lojas LIMIT 1) AS loja_id,
    numero,
    4 AS capacidade_pessoas,
    CASE 
        WHEN numero <= 12 THEN 'Salão Principal'
        WHEN numero <= 20 THEN 'Varanda'
        ELSE 'Área Externa'
    END AS area,
    numero AS ordem_exibicao
FROM generate_series(1, 24) AS numero;
*/

-- ============================================================================
-- DADOS DE EXEMPLO (OPCIONAL - COMENTADO)
-- ============================================================================

/*
-- Exemplo de abertura de comanda
INSERT INTO comandas (
    loja_id,
    mesa_id,
    aberta_por,
    observacoes
)
VALUES (
    (SELECT id FROM lojas LIMIT 1),
    (SELECT id FROM comandas_mesas WHERE numero_mesa = 5 LIMIT 1),
    (SELECT id FROM profiles WHERE role_principal = 'funcionario' LIMIT 1),
    'Mesa 5 - 4 pessoas'
);

-- Exemplo de adição de item
INSERT INTO comanda_itens (
    comanda_id,
    tipo_item,
    produto_id,
    nome,
    tamanho_id,
    tamanho_label,
    quantidade,
    valor_unitario,
    valor_total,
    adicionado_por
)
VALUES (
    (SELECT id FROM comandas WHERE status = 'aberta' ORDER BY aberta_em DESC LIMIT 1),
    'produto',
    (SELECT id FROM produtos WHERE nome LIKE '%Pizza%' LIMIT 1),
    'Pizza Calabresa',
    (SELECT id FROM tamanhos WHERE tamanho_label = 'G' LIMIT 1),
    'G',
    1,
    45.00,
    45.00,
    (SELECT id FROM profiles WHERE role_principal = 'funcionario' LIMIT 1)
);
*/

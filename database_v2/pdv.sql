-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - PDV (PONTO DE VENDA)
-- ============================================================================
-- Sistema de controle de caixa para PDV
-- Complementa todos os SQLs anteriores
-- ============================================================================

-- ============================================================================
-- FILOSOFIA: CONTROLE DE CAIXA ÚNICO POR LOJA
-- ============================================================================
-- 
-- REGRA FUNDAMENTAL: Um caixa por loja, múltiplas aberturas/fechamentos
-- 
-- Por quê único por loja?
--   ✅ Simplicidade operacional
--   ✅ Menos complexidade no frontend
--   ✅ Adequado para pequenas/médias operações
--   ✅ Fácil de evoluir para múltiplos caixas depois
-- 
-- Fluxo básico:
--   1. Funcionário abre caixa (valor inicial em dinheiro)
--   2. Realiza vendas (pedidos tipo='local')
--   3. Faz sangria se necessário (retirar dinheiro)
--   4. Fecha caixa (conta dinheiro, compara com esperado)
--   5. Sistema calcula diferença (quebra de caixa)
-- 
-- Integração com pedidos:
--   - Pedidos tipo='local' são vendas do PDV
--   - Pagamentos vinculados ao caixa aberto
--   - Relatórios unificados (delivery + local)
-- 
-- ============================================================================

-- ============================================================================
-- TABELA: pdv_caixas
-- ============================================================================
-- Controle de abertura e fechamento de caixa
-- Um caixa por loja, múltiplas aberturas ao longo do tempo
CREATE TABLE pdv_caixas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loja_id UUID NOT NULL REFERENCES lojas(id) ON DELETE CASCADE,
    
    -- Abertura
    aberto_por UUID NOT NULL REFERENCES auth.users(id),
    aberto_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    valor_abertura NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (valor_abertura >= 0),
    observacoes_abertura TEXT,
    
    -- Fechamento
    fechado_por UUID REFERENCES auth.users(id),
    fechado_em TIMESTAMP WITH TIME ZONE,
    valor_fechamento NUMERIC(10, 2) CHECK (valor_fechamento >= 0),
    valor_esperado NUMERIC(10, 2) CHECK (valor_esperado >= 0),
    diferenca NUMERIC(10, 2), -- Quebra de caixa (positivo = sobra, negativo = falta)
    observacoes_fechamento TEXT,
    
    -- Status
    status TEXT NOT NULL DEFAULT 'aberto' CHECK (status IN ('aberto', 'fechado')),
    
    -- Auditoria
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Validação: se fechado, campos de fechamento são obrigatórios
    CHECK (
        (status = 'aberto') OR
        (status = 'fechado' AND fechado_por IS NOT NULL AND fechado_em IS NOT NULL AND valor_fechamento IS NOT NULL)
    )
);

-- Índices para performance
CREATE INDEX idx_pdv_caixas_loja ON pdv_caixas(loja_id);
CREATE INDEX idx_pdv_caixas_status ON pdv_caixas(status);
CREATE INDEX idx_pdv_caixas_aberto_por ON pdv_caixas(aberto_por);
CREATE INDEX idx_pdv_caixas_fechado_por ON pdv_caixas(fechado_por);
CREATE INDEX idx_pdv_caixas_aberto_em ON pdv_caixas(aberto_em DESC);
CREATE INDEX idx_pdv_caixas_fechado_em ON pdv_caixas(fechado_em DESC);

-- Índice único parcial: apenas um caixa aberto por loja por vez
CREATE UNIQUE INDEX idx_pdv_caixas_loja_aberto 
    ON pdv_caixas(loja_id) 
    WHERE status = 'aberto';

-- ============================================================================
-- TABELA: pdv_movimentacoes_caixa
-- ============================================================================
-- Movimentações de caixa (sangria e suprimento)
-- Sangria: retirada de dinheiro (segurança)
-- Suprimento: entrada de dinheiro (troco)
CREATE TABLE pdv_movimentacoes_caixa (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caixa_id UUID NOT NULL REFERENCES pdv_caixas(id) ON DELETE CASCADE,
    loja_id UUID NOT NULL REFERENCES lojas(id) ON DELETE CASCADE,
    
    -- Tipo de movimentação
    tipo TEXT NOT NULL CHECK (tipo IN ('sangria', 'suprimento')),
    
    -- Tipo de pagamento (opcional - para versão 2)
    -- Permite registrar sangria/suprimento em outras formas além de dinheiro
    -- Exemplo: Sangria via PIX, Suprimento via transferência
    tipo_pagamento TEXT DEFAULT 'dinheiro' CHECK (tipo_pagamento IN ('dinheiro', 'pix', 'cartao', 'transferencia')),
    
    -- Valor (sempre positivo, tipo define se é entrada ou saída)
    valor NUMERIC(10, 2) NOT NULL CHECK (valor > 0),
    
    -- Motivo/Observação
    motivo TEXT NOT NULL,
    observacoes TEXT,
    
    -- Auditoria
    realizado_por UUID NOT NULL REFERENCES auth.users(id),
    realizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_pdv_movimentacoes_caixa ON pdv_movimentacoes_caixa(caixa_id);
CREATE INDEX idx_pdv_movimentacoes_loja ON pdv_movimentacoes_caixa(loja_id);
CREATE INDEX idx_pdv_movimentacoes_tipo ON pdv_movimentacoes_caixa(tipo);
CREATE INDEX idx_pdv_movimentacoes_realizado_por ON pdv_movimentacoes_caixa(realizado_por);
CREATE INDEX idx_pdv_movimentacoes_realizado_em ON pdv_movimentacoes_caixa(realizado_em DESC);

-- ============================================================================
-- TRIGGERS PARA ATUALIZAR updated_at
-- ============================================================================

CREATE TRIGGER update_pdv_caixas_updated_at
    BEFORE UPDATE ON pdv_caixas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER: Calcular diferença no fechamento
-- ============================================================================
-- Calcula automaticamente a diferença (quebra de caixa) ao fechar

CREATE OR REPLACE FUNCTION calcular_diferenca_caixa()
RETURNS TRIGGER AS $$
BEGIN
    -- Se está fechando o caixa, calcula diferença
    IF NEW.status = 'fechado' AND OLD.status = 'aberto' THEN
        -- Calcula diferença: valor_fechamento - valor_esperado
        NEW.diferenca := NEW.valor_fechamento - NEW.valor_esperado;
        NEW.fechado_em := COALESCE(NEW.fechado_em, NOW());
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calcular_diferenca_caixa
    BEFORE UPDATE ON pdv_caixas
    FOR EACH ROW
    WHEN (NEW.status = 'fechado' AND OLD.status = 'aberto')
    EXECUTE FUNCTION calcular_diferenca_caixa();

-- ============================================================================
-- TRIGGER: Validar caixa aberto para pedidos locais (OPCIONAL - AVANÇADO)
-- ============================================================================
-- Garante que pedidos tipo='local' só podem ser criados com caixa aberto
-- IMPORTANTE: Esta validação também deve existir no backend
-- Este trigger é uma camada extra de segurança no banco

CREATE OR REPLACE FUNCTION validar_caixa_aberto_pedido_local()
RETURNS TRIGGER AS $$
DECLARE
    v_caixa_aberto BOOLEAN;
BEGIN
    -- Apenas valida para pedidos tipo='local'
    IF NEW.tipo_entrega = 'local' THEN
        -- Verifica se existe caixa aberto para esta loja
        SELECT EXISTS (
            SELECT 1 FROM pdv_caixas
            WHERE loja_id = (SELECT loja_id FROM profiles WHERE id = NEW.created_by LIMIT 1)
              AND status = 'aberto'
        ) INTO v_caixa_aberto;
        
        -- Se não existe caixa aberto, bloqueia criação do pedido
        IF NOT v_caixa_aberto THEN
            RAISE EXCEPTION 'Não é possível criar pedido local sem caixa aberto. Abra o caixa primeiro.';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplica trigger em INSERT de pedidos
-- NOTA: Este trigger assume que pedidos tem loja_id ou que created_by está em profiles
-- Se estrutura for diferente, ajustar a query acima
CREATE TRIGGER trigger_validar_caixa_aberto_pedido_local
    BEFORE INSERT ON pedidos
    FOR EACH ROW
    WHEN (NEW.tipo_entrega = 'local')
    EXECUTE FUNCTION validar_caixa_aberto_pedido_local();

-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View de caixas com totalizadores
CREATE OR REPLACE VIEW pdv_caixas_resumo AS
SELECT 
    c.*,
    p_abriu.nome AS aberto_por_nome,
    p_fechou.nome AS fechado_por_nome,
    
    -- Total de vendas em dinheiro (entra na diferença física)
    COALESCE(SUM(pp.valor) FILTER (WHERE pp.tipo_pagamento = 'dinheiro' AND pp.caixa_id = c.id), 0) AS total_dinheiro,
    
    -- Total de outras formas de pagamento (não entra na diferença física)
    COALESCE(SUM(pp.valor) FILTER (WHERE pp.tipo_pagamento != 'dinheiro' AND pp.caixa_id = c.id), 0) AS total_outras_formas,
    COALESCE(SUM(pp.valor) FILTER (WHERE pp.tipo_pagamento = 'pix' AND pp.caixa_id = c.id), 0) AS total_pix,
    COALESCE(SUM(pp.valor) FILTER (WHERE pp.tipo_pagamento IN ('cartao_credito', 'cartao_debito') AND pp.caixa_id = c.id), 0) AS total_cartao,
    
    -- Total de sangrias (por forma de pagamento)
    COALESCE(SUM(m.valor) FILTER (WHERE m.tipo = 'sangria' AND m.tipo_pagamento = 'dinheiro'), 0) AS total_sangrias_dinheiro,
    COALESCE(SUM(m.valor) FILTER (WHERE m.tipo = 'sangria' AND m.tipo_pagamento != 'dinheiro'), 0) AS total_sangrias_outras,
    
    -- Total de suprimentos (por forma de pagamento)
    COALESCE(SUM(m.valor) FILTER (WHERE m.tipo = 'suprimento' AND m.tipo_pagamento = 'dinheiro'), 0) AS total_suprimentos_dinheiro,
    COALESCE(SUM(m.valor) FILTER (WHERE m.tipo = 'suprimento' AND m.tipo_pagamento != 'dinheiro'), 0) AS total_suprimentos_outras,
    
    -- Quantidade de pedidos
    COUNT(DISTINCT ped.id) AS total_pedidos,
    
    -- Valor total de vendas (todas as formas)
    COALESCE(SUM(ped.total), 0) AS total_vendas
FROM pdv_caixas c
LEFT JOIN profiles p_abriu ON c.aberto_por = p_abriu.id
LEFT JOIN profiles p_fechou ON c.fechado_por = p_fechou.id
LEFT JOIN pedidos ped ON ped.tipo_entrega = 'local' 
    AND ped.created_at >= c.aberto_em 
    AND (c.fechado_em IS NULL OR ped.created_at <= c.fechado_em)
    AND ped.status NOT IN ('cancelado', 'rejeitado')
LEFT JOIN pedido_pagamentos pp ON ped.id = pp.pedido_id
LEFT JOIN pdv_movimentacoes_caixa m ON c.id = m.caixa_id
GROUP BY c.id, p_abriu.nome, p_fechou.nome
ORDER BY c.aberto_em DESC;

-- View de caixa aberto (se houver)
CREATE OR REPLACE VIEW pdv_caixa_aberto AS
SELECT * FROM pdv_caixas
WHERE status = 'aberto'
ORDER BY aberto_em DESC
LIMIT 1;

-- View de movimentações com detalhes
CREATE OR REPLACE VIEW pdv_movimentacoes_detalhado AS
SELECT 
    m.*,
    c.aberto_em AS caixa_aberto_em,
    c.status AS caixa_status,
    p.nome AS realizado_por_nome,
    CASE 
        WHEN m.tipo = 'sangria' THEN 'SAÍDA'
        ELSE 'ENTRADA'
    END AS direcao,
    CASE 
        WHEN m.tipo_pagamento = 'dinheiro' THEN '💵 Dinheiro'
        WHEN m.tipo_pagamento = 'pix' THEN '📱 PIX'
        WHEN m.tipo_pagamento = 'cartao' THEN '💳 Cartão'
        WHEN m.tipo_pagamento = 'transferencia' THEN '🏦 Transferência'
        ELSE m.tipo_pagamento
    END AS forma_pagamento_label
FROM pdv_movimentacoes_caixa m
INNER JOIN pdv_caixas c ON m.caixa_id = c.id
LEFT JOIN profiles p ON m.realizado_por = p.id
ORDER BY m.realizado_em DESC;

-- View de histórico de fechamentos
CREATE OR REPLACE VIEW pdv_historico_fechamentos AS
SELECT 
    c.id,
    c.loja_id,
    c.aberto_em,
    c.fechado_em,
    c.valor_abertura,
    c.valor_fechamento,
    c.valor_esperado,
    c.diferenca,
    p_abriu.nome AS aberto_por_nome,
    p_fechou.nome AS fechado_por_nome,
    EXTRACT(EPOCH FROM (c.fechado_em - c.aberto_em))/3600 AS horas_abertas,
    CASE 
        WHEN c.diferenca > 0 THEN 'SOBRA'
        WHEN c.diferenca < 0 THEN 'FALTA'
        ELSE 'CORRETO'
    END AS status_diferenca
FROM pdv_caixas c
LEFT JOIN profiles p_abriu ON c.aberto_por = p_abriu.id
LEFT JOIN profiles p_fechou ON c.fechado_por = p_fechou.id
WHERE c.status = 'fechado'
ORDER BY c.fechado_em DESC;

-- ============================================================================
-- COMENTÁRIOS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE pdv_caixas IS 'Controle de abertura e fechamento de caixa. Um caixa único por loja, múltiplas aberturas ao longo do tempo';
COMMENT ON TABLE pdv_movimentacoes_caixa IS 'Movimentações de caixa (sangria e suprimento) para controle de dinheiro';

COMMENT ON COLUMN pdv_caixas.valor_abertura IS 'Valor inicial em dinheiro ao abrir o caixa (troco inicial)';
COMMENT ON COLUMN pdv_caixas.valor_fechamento IS 'Valor contado em dinheiro ao fechar o caixa';
COMMENT ON COLUMN pdv_caixas.valor_esperado IS 'Valor esperado calculado (abertura + vendas - sangrias + suprimentos)';
COMMENT ON COLUMN pdv_caixas.diferenca IS 'Quebra de caixa (positivo = sobra, negativo = falta). Calculado automaticamente: valor_fechamento - valor_esperado';
COMMENT ON COLUMN pdv_caixas.status IS 'Status do caixa: aberto (em operação) ou fechado (finalizado)';

COMMENT ON COLUMN pdv_movimentacoes_caixa.tipo IS 'Tipo de movimentação: sangria (retirada de dinheiro) ou suprimento (entrada de dinheiro para troco)';
COMMENT ON COLUMN pdv_movimentacoes_caixa.tipo_pagamento IS 'Forma de pagamento da movimentação (padrão: dinheiro). Versão 2: permite sangria/suprimento via PIX, cartão, transferência';
COMMENT ON COLUMN pdv_movimentacoes_caixa.valor IS 'Valor da movimentação (sempre positivo, tipo define se é entrada ou saída)';
COMMENT ON COLUMN pdv_movimentacoes_caixa.motivo IS 'Motivo da movimentação (ex: "Sangria para segurança", "Suprimento de troco")';

COMMENT ON VIEW pdv_caixas_resumo IS 'View com caixas e totalizadores. IMPORTANTE: Separa dinheiro (entra na diferença física) de outras formas (PIX, cartão - apenas relatório). Usa caixa_id de pedido_pagamentos para auditoria precisa';
COMMENT ON VIEW pdv_caixa_aberto IS 'View com o caixa atualmente aberto (se houver)';
COMMENT ON VIEW pdv_movimentacoes_detalhado IS 'View com movimentações e informações relacionadas (caixa, usuário)';
COMMENT ON VIEW pdv_historico_fechamentos IS 'View com histórico de fechamentos e análise de diferenças';

COMMENT ON FUNCTION calcular_diferenca_caixa IS 'Trigger que calcula automaticamente a diferença (quebra de caixa) ao fechar: valor_fechamento - valor_esperado';
COMMENT ON FUNCTION validar_caixa_aberto_pedido_local IS 'Trigger que valida se existe caixa aberto antes de criar pedido tipo=local. Camada extra de segurança (validação principal deve ser no backend)';

-- ============================================================================
-- REGRAS DE NEGÓCIO (PARA BACKEND/FRONTEND)
-- ============================================================================
-- 
-- 1. ABERTURA DE CAIXA
--    - Apenas um caixa aberto por loja por vez (garantido por índice único)
--    - Valor de abertura é o troco inicial em dinheiro
--    - Funcionário deve ter permissão 'pdv.abrir_fechar_caixa'
-- 
-- 2. VENDAS NO PDV
--    - Criar pedido com tipo_entrega = 'local'
--    - Pedido deve ser criado enquanto caixa está aberto
--    - Ao criar pagamento, preencher caixa_id (vinculação explícita)
--    - Pagamentos vinculados ao caixa via pedido_pagamentos.caixa_id
--    - IMPORTANTE: Dinheiro entra na diferença física, outras formas apenas no relatório
-- 
-- 3. SANGRIA
--    - Retirar dinheiro do caixa (segurança)
--    - Apenas com caixa aberto
--    - Motivo obrigatório
--    - Funcionário deve ter permissão 'pdv.sangria'
--    - Versão 2: Pode ser em outras formas (PIX, cartão, transferência)
-- 
-- 4. FECHAMENTO DE CAIXA
--    - Contar dinheiro físico (valor_fechamento)
--    - Backend calcula valor_esperado:
--      valor_esperado = valor_abertura 
--                     + total_vendas_dinheiro (apenas dinheiro!)
--                     - total_sangrias_dinheiro 
--                     + total_suprimentos_dinheiro
--    - IMPORTANTE: PIX, cartão e outras formas NÃO entram na diferença física
--    - Sistema calcula diferença automaticamente
--    - Funcionário deve ter permissão 'pdv.abrir_fechar_caixa'
--    - Relatório mostra todas as formas, mas diferença é só dinheiro
-- 
-- 5. PEDIDOS LOCAIS
--    - Pedidos tipo='local' só podem ser criados com caixa aberto
--    - Validação no backend (obrigatória)
--    - Validação no banco via trigger (camada extra de segurança)
--    - Se tentar criar pedido local sem caixa aberto, trigger bloqueia
-- 
-- 6. RELATÓRIOS
--    - Usar view pdv_caixas_resumo para relatórios
--    - Filtrar pedidos por período do caixa (aberto_em até fechado_em)
--    - Quebra de caixa deve ser justificada se > R$ 10
-- 
-- 6. MÚLTIPLAS FORMAS DE PAGAMENTO (VERSÃO 2)
--    - Sangria/suprimento podem ser em outras formas além de dinheiro
--    - Exemplo: Sangria via PIX (transferir dinheiro para banco)
--    - Exemplo: Suprimento via transferência (trazer dinheiro do banco)
--    - Campo tipo_pagamento permite rastreamento completo
-- 
-- 7. AUDITORIA E RELATÓRIOS
--    - View pdv_caixas_resumo separa dinheiro de outras formas
--    - Dinheiro: entra na diferença física (quebra de caixa)
--    - PIX/Cartão: entram no relatório, não na diferença
--    - Vinculação via pedido_pagamentos.caixa_id garante precisão
--    - Evita erro se pedido for ajustado depois
-- 
-- 8. COMBOS E PRODUTOS
--    - PDV não precisa diferenciar combo de produto
--    - Ambos entram como pedido normal (tipo='local')
--    - Relatórios de combo vêm da estrutura de pedido_itens
--    - PDV é apenas reflexo dos pedidos locais
-- 
-- ============================================================================

-- ============================================================================
-- DADOS DE EXEMPLO (OPCIONAL - COMENTADO)
-- ============================================================================

/*
-- Exemplo de abertura de caixa
INSERT INTO pdv_caixas (
    loja_id,
    aberto_por,
    valor_abertura,
    observacoes_abertura
)
VALUES (
    (SELECT id FROM lojas LIMIT 1),
    (SELECT id FROM profiles WHERE role_principal = 'funcionario' LIMIT 1),
    100.00,
    'Abertura do caixa - turno manhã'
);

-- Exemplo de sangria em dinheiro
INSERT INTO pdv_movimentacoes_caixa (
    caixa_id,
    loja_id,
    tipo,
    tipo_pagamento,
    valor,
    motivo,
    realizado_por
)
VALUES (
    (SELECT id FROM pdv_caixas WHERE status = 'aberto' LIMIT 1),
    (SELECT loja_id FROM pdv_caixas WHERE status = 'aberto' LIMIT 1),
    'sangria',
    'dinheiro',
    200.00,
    'Sangria para segurança - muito dinheiro no caixa',
    (SELECT aberto_por FROM pdv_caixas WHERE status = 'aberto' LIMIT 1)
);

-- Exemplo de sangria via PIX (Versão 2)
INSERT INTO pdv_movimentacoes_caixa (
    caixa_id,
    loja_id,
    tipo,
    tipo_pagamento,
    valor,
    motivo,
    observacoes,
    realizado_por
)
VALUES (
    (SELECT id FROM pdv_caixas WHERE status = 'aberto' LIMIT 1),
    (SELECT loja_id FROM pdv_caixas WHERE status = 'aberto' LIMIT 1),
    'sangria',
    'pix',
    500.00,
    'Transferência para conta bancária',
    'Chave PIX: 11999999999',
    (SELECT aberto_por FROM pdv_caixas WHERE status = 'aberto' LIMIT 1)
);

-- Exemplo de fechamento de caixa
UPDATE pdv_caixas
SET status = 'fechado',
    fechado_por = (SELECT id FROM profiles WHERE role_principal = 'funcionario' LIMIT 1),
    valor_fechamento = 495.00,
    valor_esperado = 500.00, -- Calculado pelo backend
    observacoes_fechamento = 'Fechamento do caixa - turno manhã'
WHERE status = 'aberto';
-- Trigger calcula diferenca = -5.00 automaticamente
*/

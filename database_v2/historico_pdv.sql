-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - HISTÓRICO DE PDV
-- ============================================================================
-- Sistema de auditoria completa para operações do PDV (caixa)
-- Registra TODAS as operações financeiras e movimentações
-- ============================================================================

-- ============================================================================
-- FILOSOFIA: AUDITORIA FINANCEIRA TOTAL
-- ============================================================================
-- 
-- REGRA FUNDAMENTAL: Histórico financeiro NUNCA é alterado ou deletado
-- 
-- Por quê auditoria financeira total?
--   ✅ Compliance fiscal e contábil
--   ✅ Prevenção de fraudes
--   ✅ Resolução de disputas financeiras
--   ✅ Auditoria interna e externa
--   ✅ Rastreabilidade de dinheiro
-- 
-- O que registrar?
--   - Abertura e fechamento de caixa
--   - Sangrias e suprimentos
--   - Vendas (pedidos locais)
--   - Diferenças de caixa (quebra)
--   - Justificativas de diferenças
--   - Qualquer operação financeira
-- 
-- Como funciona?
--   - Trigger captura INSERT/UPDATE
--   - Registra operação com contexto completo
--   - Identifica quem fez a operação
--   - Timestamp automático
--   - Valores em JSONB para auditoria
-- 
-- IMPORTANTE: Dados financeiros são SENSÍVEIS
--   - Acesso restrito (apenas admins/gerentes)
--   - Logs de acesso ao histórico
--   - Criptografia em trânsito
--   - Backup frequente
-- 
-- ============================================================================

-- ============================================================================
-- TABELA: historico_pdv
-- ============================================================================
-- Registro de todas as operações do PDV
CREATE TABLE historico_pdv (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caixa_id UUID NOT NULL REFERENCES pdv_caixas(id) ON DELETE RESTRICT,
    loja_id UUID NOT NULL REFERENCES lojas(id) ON DELETE CASCADE,
    
    -- Tipo de evento
    tipo_evento TEXT NOT NULL CHECK (tipo_evento IN (
        'caixa_aberto',         -- Caixa foi aberto
        'caixa_fechado',        -- Caixa foi fechado
        'sangria',              -- Sangria realizada
        'suprimento',           -- Suprimento realizado
        'venda_registrada',     -- Venda (pedido local) registrada
        'diferenca_registrada', -- Diferença de caixa registrada
        'justificativa_adicionada', -- Justificativa de diferença
        'correcao_valor',       -- Correção de valor (raro)
        'outro'                 -- Outros tipos de evento
    )),
    
    -- Descrição do evento
    descricao TEXT NOT NULL, -- Ex: "Caixa aberto com R$ 100,00"
    
    -- Dados do evento (JSON flexível)
    dados_evento JSONB, -- Detalhes específicos do evento
    
    -- Valores envolvidos
    valor NUMERIC(10, 2), -- Valor da operação (se aplicável)
    tipo_pagamento TEXT CHECK (tipo_pagamento IN ('dinheiro', 'pix', 'cartao', 'transferencia')),
    
    -- Referências relacionadas
    movimentacao_id UUID REFERENCES pdv_movimentacoes_caixa(id) ON DELETE SET NULL, -- Se evento é sobre movimentação
    pedido_id UUID REFERENCES pedidos(id) ON DELETE SET NULL, -- Se evento é sobre venda
    
    -- Estado anterior e novo (para mudanças)
    campo_alterado TEXT, -- Nome do campo alterado
    valor_anterior TEXT, -- Valor anterior
    valor_novo TEXT,     -- Valor novo
    
    -- Auditoria
    realizado_por UUID REFERENCES auth.users(id), -- Quem fez a operação
    realizado_por_nome TEXT, -- Snapshot do nome
    realizado_por_cargo TEXT, -- Cargo no momento (caixa, gerente, admin)
    realizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Segurança (auditoria avançada)
    ip_address INET, -- IP de onde veio a operação
    user_agent TEXT, -- Browser/app que fez a operação
    
    -- Metadados
    origem TEXT, -- Ex: 'web', 'mobile', 'sistema'
    observacoes TEXT, -- Observações adicionais
    
    -- Flags de segurança
    requer_atencao BOOLEAN DEFAULT false, -- Marcar operações suspeitas
    revisado BOOLEAN DEFAULT false, -- Se operação foi revisada por gerente
    revisado_por UUID REFERENCES auth.users(id),
    revisado_em TIMESTAMP WITH TIME ZONE
);

-- Índices para performance
CREATE INDEX idx_historico_pdv_caixa ON historico_pdv(caixa_id);
CREATE INDEX idx_historico_pdv_loja ON historico_pdv(loja_id);
CREATE INDEX idx_historico_pdv_tipo_evento ON historico_pdv(tipo_evento);
CREATE INDEX idx_historico_pdv_realizado_por ON historico_pdv(realizado_por);
CREATE INDEX idx_historico_pdv_realizado_em ON historico_pdv(realizado_em DESC);
CREATE INDEX idx_historico_pdv_movimentacao ON historico_pdv(movimentacao_id);
CREATE INDEX idx_historico_pdv_pedido ON historico_pdv(pedido_id);
CREATE INDEX idx_historico_pdv_requer_atencao ON historico_pdv(requer_atencao) WHERE requer_atencao = true;
CREATE INDEX idx_historico_pdv_revisado ON historico_pdv(revisado) WHERE revisado = false;

-- Índice composto para consultas comuns
CREATE INDEX idx_historico_pdv_caixa_evento 
    ON historico_pdv(caixa_id, tipo_evento, realizado_em DESC);

-- Índice GIN para busca em JSONB
CREATE INDEX idx_historico_pdv_dados_evento ON historico_pdv USING GIN (dados_evento);

-- ============================================================================
-- TRIGGER: Registrar abertura e fechamento de caixa
-- ============================================================================

CREATE OR REPLACE FUNCTION registrar_historico_pdv_caixa()
RETURNS TRIGGER AS $$
DECLARE
    v_tipo_evento TEXT;
    v_descricao TEXT;
    v_dados_evento JSONB;
    v_requer_atencao BOOLEAN := false;
BEGIN
    -- Abertura de caixa
    IF TG_OP = 'INSERT' THEN
        INSERT INTO historico_pdv (
            caixa_id, loja_id, tipo_evento, descricao,
            valor, tipo_pagamento, dados_evento,
            realizado_por, realizado_por_cargo, realizado_em
        ) VALUES (
            NEW.id, NEW.loja_id,
            'caixa_aberto',
            format('Caixa aberto com R$ %s', NEW.valor_abertura),
            NEW.valor_abertura, 'dinheiro',
            jsonb_build_object(
                'valor_abertura', NEW.valor_abertura,
                'observacoes', NEW.observacoes_abertura
            ),
            NEW.aberto_por,
            (SELECT cargo_id FROM profiles WHERE id = NEW.aberto_por),
            NEW.aberto_em
        );
        RETURN NEW;
    END IF;
    
    -- Fechamento de caixa
    IF TG_OP = 'UPDATE' AND OLD.status = 'aberto' AND NEW.status = 'fechado' THEN
        -- Verificar se diferença é significativa (> R$ 10)
        IF ABS(NEW.diferenca) > 10 THEN
            v_requer_atencao := true;
        END IF;
        
        v_dados_evento := jsonb_build_object(
            'valor_abertura', NEW.valor_abertura,
            'valor_fechamento', NEW.valor_fechamento,
            'valor_esperado', NEW.valor_esperado,
            'diferenca', NEW.diferenca,
            'observacoes', NEW.observacoes_fechamento,
            'tempo_aberto_horas', EXTRACT(EPOCH FROM (NEW.fechado_em - NEW.aberto_em))/3600
        );
        
        INSERT INTO historico_pdv (
            caixa_id, loja_id, tipo_evento, descricao,
            valor, dados_evento,
            realizado_por, realizado_por_cargo, realizado_em,
            requer_atencao
        ) VALUES (
            NEW.id, NEW.loja_id,
            'caixa_fechado',
            format('Caixa fechado. Diferença: R$ %s (%s)', 
                NEW.diferenca,
                CASE 
                    WHEN NEW.diferenca > 0 THEN 'SOBRA'
                    WHEN NEW.diferenca < 0 THEN 'FALTA'
                    ELSE 'CORRETO'
                END
            ),
            NEW.diferenca,
            v_dados_evento,
            NEW.fechado_por,
            (SELECT cargo_id FROM profiles WHERE id = NEW.fechado_por),
            NEW.fechado_em,
            v_requer_atencao
        );
        
        -- Registrar diferença separadamente se houver
        IF NEW.diferenca != 0 THEN
            INSERT INTO historico_pdv (
                caixa_id, loja_id, tipo_evento, descricao,
                valor, dados_evento,
                realizado_por, realizado_em,
                requer_atencao
            ) VALUES (
                NEW.id, NEW.loja_id,
                'diferenca_registrada',
                format('Diferença de caixa: R$ %s (%s)', 
                    ABS(NEW.diferenca),
                    CASE 
                        WHEN NEW.diferenca > 0 THEN 'SOBRA'
                        ELSE 'FALTA'
                    END
                ),
                NEW.diferenca,
                jsonb_build_object(
                    'tipo', CASE WHEN NEW.diferenca > 0 THEN 'sobra' ELSE 'falta' END,
                    'valor_absoluto', ABS(NEW.diferenca),
                    'percentual', ROUND((ABS(NEW.diferenca) / NULLIF(NEW.valor_esperado, 0) * 100), 2)
                ),
                NEW.fechado_por,
                NEW.fechado_em,
                v_requer_atencao
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em pdv_caixas
CREATE TRIGGER trigger_historico_pdv_caixa
    AFTER INSERT OR UPDATE ON pdv_caixas
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_pdv_caixa();

-- ============================================================================
-- TRIGGER: Registrar movimentações (sangria/suprimento)
-- ============================================================================

CREATE OR REPLACE FUNCTION registrar_historico_pdv_movimentacao()
RETURNS TRIGGER AS $$
DECLARE
    v_tipo_evento TEXT;
    v_descricao TEXT;
    v_requer_atencao BOOLEAN := false;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_tipo_evento := NEW.tipo;
        
        -- Verificar se valor é muito alto (> R$ 500)
        IF NEW.valor > 500 THEN
            v_requer_atencao := true;
        END IF;
        
        v_descricao := format('%s de R$ %s (%s): %s',
            CASE NEW.tipo
                WHEN 'sangria' THEN 'Sangria'
                WHEN 'suprimento' THEN 'Suprimento'
            END,
            NEW.valor,
            NEW.tipo_pagamento,
            NEW.motivo
        );
        
        INSERT INTO historico_pdv (
            caixa_id, loja_id, movimentacao_id,
            tipo_evento, descricao,
            valor, tipo_pagamento, dados_evento,
            realizado_por, realizado_em,
            requer_atencao
        ) VALUES (
            NEW.caixa_id, NEW.loja_id, NEW.id,
            v_tipo_evento, v_descricao,
            NEW.valor, NEW.tipo_pagamento,
            jsonb_build_object(
                'tipo', NEW.tipo,
                'valor', NEW.valor,
                'tipo_pagamento', NEW.tipo_pagamento,
                'motivo', NEW.motivo,
                'observacoes', NEW.observacoes
            ),
            NEW.realizado_por, NEW.realizado_em,
            v_requer_atencao
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em pdv_movimentacoes_caixa
CREATE TRIGGER trigger_historico_pdv_movimentacao
    AFTER INSERT ON pdv_movimentacoes_caixa
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_pdv_movimentacao();

-- ============================================================================
-- TRIGGER: Registrar vendas (pedidos locais)
-- ============================================================================

CREATE OR REPLACE FUNCTION registrar_historico_pdv_venda()
RETURNS TRIGGER AS $$
DECLARE
    v_caixa_id UUID;
BEGIN
    -- Apenas para pedidos locais com pagamento vinculado a caixa
    IF NEW.tipo_entrega = 'local' AND TG_OP = 'INSERT' THEN
        -- Buscar caixa_id do pagamento
        SELECT pp.caixa_id INTO v_caixa_id
        FROM pedido_pagamentos pp
        WHERE pp.pedido_id = NEW.id
        LIMIT 1;
        
        IF v_caixa_id IS NOT NULL THEN
            INSERT INTO historico_pdv (
                caixa_id, loja_id, pedido_id,
                tipo_evento, descricao,
                valor, dados_evento,
                realizado_em
            ) VALUES (
                v_caixa_id,
                (SELECT loja_id FROM pdv_caixas WHERE id = v_caixa_id),
                NEW.id,
                'venda_registrada',
                format('Venda registrada: Pedido %s - R$ %s', NEW.codigo_pedido, NEW.total),
                NEW.total,
                jsonb_build_object(
                    'pedido_id', NEW.id,
                    'codigo_pedido', NEW.codigo_pedido,
                    'total', NEW.total,
                    'tipo_entrega', NEW.tipo_entrega,
                    'comanda_id', NEW.comanda_id
                ),
                NEW.created_at
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em pedidos
CREATE TRIGGER trigger_historico_pdv_venda
    AFTER INSERT ON pedidos
    FOR EACH ROW
    WHEN (NEW.tipo_entrega = 'local')
    EXECUTE FUNCTION registrar_historico_pdv_venda();

-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View de histórico completo com detalhes
CREATE OR REPLACE VIEW historico_pdv_detalhado AS
SELECT 
    hp.*,
    pc.aberto_em AS caixa_aberto_em,
    pc.fechado_em AS caixa_fechado_em,
    pc.status AS caixa_status,
    prof.nome AS realizado_por_nome_atual,
    prof.email AS realizado_por_email,
    CASE 
        WHEN hp.pedido_id IS NOT NULL THEN ped.codigo_pedido
        ELSE NULL
    END AS pedido_codigo
FROM historico_pdv hp
INNER JOIN pdv_caixas pc ON hp.caixa_id = pc.id
LEFT JOIN profiles prof ON hp.realizado_por = prof.id
LEFT JOIN pedidos ped ON hp.pedido_id = ped.id
ORDER BY hp.realizado_em DESC;

-- View de operações que requerem atenção
CREATE OR REPLACE VIEW historico_pdv_requer_atencao AS
SELECT 
    hp.*,
    pc.aberto_em,
    pc.fechado_em,
    prof.nome AS realizado_por_nome,
    CASE 
        WHEN hp.tipo_evento = 'diferenca_registrada' THEN 
            format('Diferença de R$ %s (%s%%)', 
                ABS(hp.valor),
                hp.dados_evento->>'percentual'
            )
        WHEN hp.tipo_evento IN ('sangria', 'suprimento') THEN
            format('Valor alto: R$ %s', hp.valor)
        ELSE hp.descricao
    END AS motivo_atencao
FROM historico_pdv hp
INNER JOIN pdv_caixas pc ON hp.caixa_id = pc.id
LEFT JOIN profiles prof ON hp.realizado_por = prof.id
WHERE hp.requer_atencao = true AND hp.revisado = false
ORDER BY hp.realizado_em DESC;

-- View de resumo financeiro por caixa
CREATE OR REPLACE VIEW historico_pdv_resumo_caixa AS
SELECT 
    hp.caixa_id,
    pc.aberto_em,
    pc.fechado_em,
    pc.status,
    prof_abriu.nome AS aberto_por_nome,
    prof_fechou.nome AS fechado_por_nome,
    
    -- Valores
    MAX(CASE WHEN hp.tipo_evento = 'caixa_aberto' THEN hp.valor END) AS valor_abertura,
    MAX(CASE WHEN hp.tipo_evento = 'caixa_fechado' THEN 
        (hp.dados_evento->>'valor_fechamento')::NUMERIC END) AS valor_fechamento,
    MAX(CASE WHEN hp.tipo_evento = 'caixa_fechado' THEN 
        (hp.dados_evento->>'valor_esperado')::NUMERIC END) AS valor_esperado,
    MAX(CASE WHEN hp.tipo_evento = 'diferenca_registrada' THEN hp.valor END) AS diferenca,
    
    -- Movimentações
    SUM(CASE WHEN hp.tipo_evento = 'sangria' AND hp.tipo_pagamento = 'dinheiro' THEN hp.valor ELSE 0 END) AS total_sangrias_dinheiro,
    SUM(CASE WHEN hp.tipo_evento = 'suprimento' AND hp.tipo_pagamento = 'dinheiro' THEN hp.valor ELSE 0 END) AS total_suprimentos_dinheiro,
    
    -- Vendas
    SUM(CASE WHEN hp.tipo_evento = 'venda_registrada' THEN hp.valor ELSE 0 END) AS total_vendas,
    COUNT(CASE WHEN hp.tipo_evento = 'venda_registrada' THEN 1 END) AS total_pedidos,
    
    -- Flags
    BOOL_OR(hp.requer_atencao) AS tem_operacoes_suspeitas,
    COUNT(CASE WHEN hp.requer_atencao = true AND hp.revisado = false THEN 1 END) AS operacoes_pendentes_revisao
    
FROM historico_pdv hp
INNER JOIN pdv_caixas pc ON hp.caixa_id = pc.id
LEFT JOIN profiles prof_abriu ON pc.aberto_por = prof_abriu.id
LEFT JOIN profiles prof_fechou ON pc.fechado_por = prof_fechou.id
GROUP BY hp.caixa_id, pc.aberto_em, pc.fechado_em, pc.status, prof_abriu.nome, prof_fechou.nome
ORDER BY pc.aberto_em DESC;

-- View de diferenças de caixa (quebras)
CREATE OR REPLACE VIEW historico_pdv_diferencas AS
SELECT 
    hp.caixa_id,
    pc.aberto_em,
    pc.fechado_em,
    prof.nome AS fechado_por_nome,
    hp.valor AS diferenca,
    hp.dados_evento->>'tipo' AS tipo_diferenca,
    (hp.dados_evento->>'percentual')::NUMERIC AS percentual,
    hp.requer_atencao,
    hp.revisado,
    hp.observacoes
FROM historico_pdv hp
INNER JOIN pdv_caixas pc ON hp.caixa_id = pc.id
LEFT JOIN profiles prof ON hp.realizado_por = prof.id
WHERE hp.tipo_evento = 'diferenca_registrada'
ORDER BY ABS(hp.valor) DESC;

-- View de sangrias e suprimentos
CREATE OR REPLACE VIEW historico_pdv_movimentacoes AS
SELECT 
    hp.caixa_id,
    pc.aberto_em,
    hp.tipo_evento,
    hp.valor,
    hp.tipo_pagamento,
    hp.dados_evento->>'motivo' AS motivo,
    hp.realizado_por_nome,
    hp.realizado_em,
    hp.requer_atencao
FROM historico_pdv hp
INNER JOIN pdv_caixas pc ON hp.caixa_id = pc.id
WHERE hp.tipo_evento IN ('sangria', 'suprimento')
ORDER BY hp.realizado_em DESC;

-- View de performance por operador de caixa
CREATE OR REPLACE VIEW historico_pdv_performance_operador AS
SELECT 
    hp.realizado_por,
    hp.realizado_por_nome,
    COUNT(DISTINCT CASE WHEN hp.tipo_evento = 'caixa_aberto' THEN hp.caixa_id END) AS caixas_abertos,
    COUNT(DISTINCT CASE WHEN hp.tipo_evento = 'caixa_fechado' THEN hp.caixa_id END) AS caixas_fechados,
    COUNT(CASE WHEN hp.tipo_evento = 'sangria' THEN 1 END) AS total_sangrias,
    COUNT(CASE WHEN hp.tipo_evento = 'suprimento' THEN 1 END) AS total_suprimentos,
    COUNT(CASE WHEN hp.tipo_evento = 'diferenca_registrada' THEN 1 END) AS total_diferencas,
    AVG(CASE WHEN hp.tipo_evento = 'diferenca_registrada' THEN ABS(hp.valor) END) AS media_diferenca,
    COUNT(CASE WHEN hp.requer_atencao = true THEN 1 END) AS operacoes_suspeitas
FROM historico_pdv hp
WHERE hp.realizado_por IS NOT NULL
GROUP BY hp.realizado_por, hp.realizado_por_nome
ORDER BY caixas_fechados DESC;

-- ============================================================================
-- COMENTÁRIOS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE historico_pdv IS 'Registro imutável de todas as operações do PDV. NUNCA deletar ou alterar. Auditoria financeira completa para compliance e prevenção de fraudes';

COMMENT ON COLUMN historico_pdv.tipo_evento IS 'Tipo do evento: caixa_aberto, caixa_fechado, sangria, suprimento, venda_registrada, diferenca_registrada, justificativa_adicionada, correcao_valor, outro';
COMMENT ON COLUMN historico_pdv.dados_evento IS 'Dados detalhados do evento em formato JSON. Estrutura varia por tipo de evento';
COMMENT ON COLUMN historico_pdv.ip_address IS 'IP de onde veio a operação (para auditoria avançada). NUNCA expor publicamente. Acesso restrito';
COMMENT ON COLUMN historico_pdv.user_agent IS 'Browser/app que fez a operação (para auditoria avançada). NUNCA expor publicamente. Acesso restrito';
COMMENT ON COLUMN historico_pdv.requer_atencao IS 'Flag para operações suspeitas ou que requerem revisão (diferença alta, sangria alta, etc)';
COMMENT ON COLUMN historico_pdv.revisado IS 'Se operação foi revisada por gerente/admin. Importante para operações que requerem atenção';

COMMENT ON FUNCTION registrar_historico_pdv_caixa IS 'Trigger que registra abertura e fechamento de caixa, incluindo diferenças. Marca diferenças > R$ 10 como requer_atencao';
COMMENT ON FUNCTION registrar_historico_pdv_movimentacao IS 'Trigger que registra sangrias e suprimentos. Marca valores > R$ 500 como requer_atencao';
COMMENT ON FUNCTION registrar_historico_pdv_venda IS 'Trigger que registra vendas (pedidos locais) vinculadas ao caixa';

COMMENT ON VIEW historico_pdv_detalhado IS 'View com histórico completo e informações relacionadas (caixa, usuário, pedido)';
COMMENT ON VIEW historico_pdv_requer_atencao IS 'View com operações que requerem atenção (diferenças altas, sangrias altas, etc) e ainda não foram revisadas';
COMMENT ON VIEW historico_pdv_resumo_caixa IS 'View com resumo financeiro completo por caixa (abertura, fechamento, movimentações, vendas, flags)';
COMMENT ON VIEW historico_pdv_diferencas IS 'View com todas as diferenças de caixa (quebras) ordenadas por valor absoluto';
COMMENT ON VIEW historico_pdv_movimentacoes IS 'View com sangrias e suprimentos';
COMMENT ON VIEW historico_pdv_performance_operador IS 'View com performance de operadores de caixa (útil para identificar problemas ou treinamento)';

-- ============================================================================
-- REGRAS DE NEGÓCIO (PARA BACKEND/FRONTEND)
-- ============================================================================
-- 
-- 1. IMUTABILIDADE
--    - NUNCA deletar registros de histórico
--    - NUNCA alterar registros de histórico
--    - Histórico é append-only
--    - Dados financeiros são SENSÍVEIS
-- 
-- 2. SEGURANÇA
--    - Acesso restrito (apenas admins/gerentes)
--    - IP e User Agent são confidenciais
--    - Logs de acesso ao histórico
--    - Criptografia em trânsito
--    - Backup frequente e seguro
-- 
-- 3. OPERAÇÕES QUE REQUEREM ATENÇÃO
--    - Diferença de caixa > R$ 10
--    - Sangria/suprimento > R$ 500
--    - Múltiplas sangrias no mesmo caixa
--    - Caixa aberto por muito tempo (> 12h)
--    - Gerente deve revisar e justificar
-- 
-- 4. REVISÃO DE OPERAÇÕES
--    - Operações marcadas como requer_atencao
--    - Gerente/admin deve revisar
--    - Adicionar justificativa se necessário
--    - Marcar como revisado após análise
-- 
-- 5. RELATÓRIOS FINANCEIROS
--    - Diferenças de caixa por período
--    - Performance de operadores
--    - Sangrias e suprimentos
--    - Vendas por caixa
--    - Operações suspeitas
-- 
-- 6. COMPLIANCE
--    - Manter histórico por no mínimo 5 anos
--    - Disponibilizar para auditoria externa
--    - Relatórios fiscais e contábeis
--    - Rastreabilidade total de dinheiro
-- 
-- 7. PREVENÇÃO DE FRAUDES
--    - Monitorar operações suspeitas
--    - Alertar gerente em tempo real
--    - Análise de padrões (ML futuro)
--    - Cruzamento com outros dados
-- 
-- 8. PERFORMANCE
--    - Histórico cresce rapidamente
--    - Considerar particionamento por data
--    - Arquivar histórico antigo (> 2 anos)
--    - Manter índices otimizados
-- 
-- ============================================================================

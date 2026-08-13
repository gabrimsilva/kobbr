-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - HISTÓRICO DE PEDIDOS
-- ============================================================================
-- Sistema de auditoria completa para pedidos
-- Registra TODAS as mudanças em pedidos para rastreabilidade total
-- ============================================================================

-- ============================================================================
-- FILOSOFIA: AUDITORIA IMUTÁVEL
-- ============================================================================
-- 
-- REGRA FUNDAMENTAL: Histórico NUNCA é alterado ou deletado
-- 
-- Por quê auditoria imutável?
--   ✅ Rastreabilidade completa (quem mudou o quê, quando)
--   ✅ Compliance e regulamentação
--   ✅ Resolução de disputas (cliente vs loja)
--   ✅ Análise de comportamento (tempo médio por status)
--   ✅ Debug de problemas (o que aconteceu?)
-- 
-- O que registrar?
--   - Mudanças de status
--   - Alterações de valores
--   - Cancelamentos
--   - Atribuições (entregador, cozinha)
--   - Observações adicionadas
--   - Qualquer UPDATE em campos críticos
-- 
-- Como funciona?
--   - Trigger captura UPDATE/DELETE em pedidos
--   - Registra estado anterior e novo
--   - Identifica quem fez a mudança
--   - Timestamp automático
--   - Snapshot completo do pedido (opcional)
-- 
-- ============================================================================

-- ============================================================================
-- TABELA: historico_pedidos
-- ============================================================================
-- Registro de todas as mudanças em pedidos
CREATE TABLE historico_pedidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE RESTRICT,
    loja_id UUID NOT NULL REFERENCES lojas(id) ON DELETE CASCADE,
    
    -- Tipo de evento
    tipo_evento TEXT NOT NULL CHECK (tipo_evento IN (
        'criacao',              -- Pedido criado
        'status_alterado',      -- Status mudou
        'valor_alterado',       -- Valores alterados (raro, mas pode acontecer)
        'cancelamento',         -- Pedido cancelado
        'observacao_adicionada',-- Observação adicionada/alterada
        'entregador_atribuido', -- Entregador designado
        'tempo_estimado_alterado', -- Previsão de entrega alterada
        'pagamento_alterado',   -- Forma de pagamento alterada
        'endereco_alterado',    -- Endereço corrigido
        'outro'                 -- Outros tipos de alteração
    )),
    
    -- Descrição do evento
    descricao TEXT NOT NULL, -- Ex: "Status alterado de 'pendente' para 'confirmado'"
    
    -- Dados do evento (JSON flexível para diferentes tipos)
    dados_evento JSONB, -- Armazena detalhes específicos do evento
    
    -- Estado anterior e novo (para mudanças de campo único)
    campo_alterado TEXT, -- Nome do campo alterado (ex: 'status', 'total', 'observacoes')
    valor_anterior TEXT, -- Valor anterior (convertido para texto)
    valor_novo TEXT,     -- Valor novo (convertido para texto)
    
    -- Snapshot completo do pedido (opcional, para eventos críticos)
    snapshot_pedido JSONB, -- Estado completo do pedido no momento do evento
    
    -- Auditoria
    alterado_por UUID REFERENCES auth.users(id), -- Quem fez a mudança
    alterado_por_nome TEXT, -- Snapshot do nome (caso usuário seja deletado)
    alterado_por_tipo TEXT CHECK (alterado_por_tipo IN ('usuario', 'sistema', 'webhook', 'api')),
    alterado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- IP e User Agent (para auditoria avançada)
    ip_address INET, -- IP de onde veio a mudança
    user_agent TEXT, -- Browser/app que fez a mudança
    
    -- Metadados
    origem TEXT, -- Ex: 'web', 'mobile', 'api', 'webhook', 'sistema'
    observacoes TEXT -- Observações adicionais sobre a mudança
);

-- Índices para performance
CREATE INDEX idx_historico_pedidos_pedido ON historico_pedidos(pedido_id);
CREATE INDEX idx_historico_pedidos_loja ON historico_pedidos(loja_id);
CREATE INDEX idx_historico_pedidos_tipo_evento ON historico_pedidos(tipo_evento);
CREATE INDEX idx_historico_pedidos_alterado_por ON historico_pedidos(alterado_por);
CREATE INDEX idx_historico_pedidos_alterado_em ON historico_pedidos(alterado_em DESC);
CREATE INDEX idx_historico_pedidos_campo ON historico_pedidos(campo_alterado);

-- Índice composto para consultas comuns
CREATE INDEX idx_historico_pedidos_pedido_evento 
    ON historico_pedidos(pedido_id, tipo_evento, alterado_em DESC);

-- Índice GIN para busca em JSONB
CREATE INDEX idx_historico_pedidos_dados_evento ON historico_pedidos USING GIN (dados_evento);
CREATE INDEX idx_historico_pedidos_snapshot ON historico_pedidos USING GIN (snapshot_pedido);

-- ============================================================================
-- TRIGGER: Registrar mudanças em pedidos
-- ============================================================================
-- Captura automaticamente mudanças em campos críticos

CREATE OR REPLACE FUNCTION registrar_historico_pedido()
RETURNS TRIGGER AS $$
DECLARE
    v_tipo_evento TEXT;
    v_descricao TEXT;
    v_campo TEXT;
    v_valor_anterior TEXT;
    v_valor_novo TEXT;
    v_dados_evento JSONB;
BEGIN
    -- Criação de pedido
    IF TG_OP = 'INSERT' THEN
        INSERT INTO historico_pedidos (
            pedido_id, loja_id, tipo_evento, descricao,
            dados_evento, alterado_por_tipo, alterado_em
        ) VALUES (
            NEW.id,
            (SELECT loja_id FROM profiles WHERE id = NEW.created_by LIMIT 1),
            'criacao',
            format('Pedido %s criado', NEW.codigo_pedido),
            jsonb_build_object(
                'numero_pedido', NEW.numero_pedido,
                'codigo_pedido', NEW.codigo_pedido,
                'tipo_entrega', NEW.tipo_entrega,
                'total', NEW.total,
                'status', NEW.status
            ),
            'sistema',
            NOW()
        );
        RETURN NEW;
    END IF;
    
    -- Mudança de status
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        v_tipo_evento := 'status_alterado';
        v_descricao := format('Status alterado de "%s" para "%s"', OLD.status, NEW.status);
        v_campo := 'status';
        v_valor_anterior := OLD.status;
        v_valor_novo := NEW.status;
        v_dados_evento := jsonb_build_object(
            'status_anterior', OLD.status,
            'status_novo', NEW.status,
            'timestamp_anterior', CASE OLD.status
                WHEN 'confirmado' THEN OLD.confirmado_em
                WHEN 'preparando' THEN OLD.preparando_em
                WHEN 'pronto' THEN OLD.pronto_em
                WHEN 'saiu_entrega' THEN OLD.saiu_entrega_em
                WHEN 'entregue' THEN OLD.entregue_em
                WHEN 'cancelado' THEN OLD.cancelado_em
                WHEN 'rejeitado' THEN OLD.rejeitado_em
                ELSE NULL
            END,
            'timestamp_novo', CASE NEW.status
                WHEN 'confirmado' THEN NEW.confirmado_em
                WHEN 'preparando' THEN NEW.preparando_em
                WHEN 'pronto' THEN NEW.pronto_em
                WHEN 'saiu_entrega' THEN NEW.saiu_entrega_em
                WHEN 'entregue' THEN NEW.entregue_em
                WHEN 'cancelado' THEN NEW.cancelado_em
                WHEN 'rejeitado' THEN NEW.rejeitado_em
                ELSE NULL
            END
        );
        
        INSERT INTO historico_pedidos (
            pedido_id, loja_id, tipo_evento, descricao,
            campo_alterado, valor_anterior, valor_novo,
            dados_evento, alterado_por, alterado_por_tipo, alterado_em
        ) VALUES (
            NEW.id,
            (SELECT loja_id FROM profiles WHERE id = NEW.updated_by LIMIT 1),
            v_tipo_evento, v_descricao,
            v_campo, v_valor_anterior, v_valor_novo,
            v_dados_evento, NEW.updated_by, 'usuario', NOW()
        );
    END IF;
    
    -- Cancelamento
    IF OLD.pedido_cancelado = false AND NEW.pedido_cancelado = true THEN
        INSERT INTO historico_pedidos (
            pedido_id, loja_id, tipo_evento, descricao,
            dados_evento, alterado_por, alterado_por_tipo, alterado_em
        ) VALUES (
            NEW.id,
            (SELECT loja_id FROM profiles WHERE id = NEW.cancelado_por LIMIT 1),
            'cancelamento',
            format('Pedido cancelado: %s', NEW.motivo_cancelamento),
            jsonb_build_object(
                'motivo', NEW.motivo_cancelamento,
                'cancelado_em', NEW.cancelado_em,
                'status_anterior', OLD.status
            ),
            NEW.cancelado_por, 'usuario', NOW()
        );
    END IF;
    
    -- Alteração de valores (raro, mas importante registrar)
    IF OLD.total IS DISTINCT FROM NEW.total OR
       OLD.sub_total IS DISTINCT FROM NEW.sub_total OR
       OLD.desconto IS DISTINCT FROM NEW.desconto OR
       OLD.taxa_entrega IS DISTINCT FROM NEW.taxa_entrega THEN
        
        INSERT INTO historico_pedidos (
            pedido_id, loja_id, tipo_evento, descricao,
            dados_evento, alterado_por, alterado_por_tipo, alterado_em
        ) VALUES (
            NEW.id,
            (SELECT loja_id FROM profiles WHERE id = NEW.updated_by LIMIT 1),
            'valor_alterado',
            'Valores do pedido foram alterados',
            jsonb_build_object(
                'valores_anteriores', jsonb_build_object(
                    'sub_total', OLD.sub_total,
                    'taxa_entrega', OLD.taxa_entrega,
                    'desconto', OLD.desconto,
                    'total', OLD.total
                ),
                'valores_novos', jsonb_build_object(
                    'sub_total', NEW.sub_total,
                    'taxa_entrega', NEW.taxa_entrega,
                    'desconto', NEW.desconto,
                    'total', NEW.total
                )
            ),
            NEW.updated_by, 'usuario', NOW()
        );
    END IF;
    
    -- Alteração de observações
    IF OLD.observacoes IS DISTINCT FROM NEW.observacoes OR
       OLD.observacoes_cozinha IS DISTINCT FROM NEW.observacoes_cozinha THEN
        
        INSERT INTO historico_pedidos (
            pedido_id, loja_id, tipo_evento, descricao,
            dados_evento, alterado_por, alterado_por_tipo, alterado_em
        ) VALUES (
            NEW.id,
            (SELECT loja_id FROM profiles WHERE id = NEW.updated_by LIMIT 1),
            'observacao_adicionada',
            'Observações do pedido foram alteradas',
            jsonb_build_object(
                'observacoes_anteriores', OLD.observacoes,
                'observacoes_novas', NEW.observacoes,
                'observacoes_cozinha_anteriores', OLD.observacoes_cozinha,
                'observacoes_cozinha_novas', NEW.observacoes_cozinha
            ),
            NEW.updated_by, 'usuario', NOW()
        );
    END IF;
    
    -- Alteração de tempo estimado
    IF OLD.tempo_estimado_minutos IS DISTINCT FROM NEW.tempo_estimado_minutos OR
       OLD.previsao_entrega IS DISTINCT FROM NEW.previsao_entrega THEN
        
        INSERT INTO historico_pedidos (
            pedido_id, loja_id, tipo_evento, descricao,
            dados_evento, alterado_por, alterado_por_tipo, alterado_em
        ) VALUES (
            NEW.id,
            (SELECT loja_id FROM profiles WHERE id = NEW.updated_by LIMIT 1),
            'tempo_estimado_alterado',
            'Tempo estimado de entrega foi alterado',
            jsonb_build_object(
                'tempo_anterior_minutos', OLD.tempo_estimado_minutos,
                'tempo_novo_minutos', NEW.tempo_estimado_minutos,
                'previsao_anterior', OLD.previsao_entrega,
                'previsao_nova', NEW.previsao_entrega
            ),
            NEW.updated_by, 'usuario', NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em pedidos
CREATE TRIGGER trigger_historico_pedido
    AFTER INSERT OR UPDATE ON pedidos
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_pedido();

-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View de histórico completo com nomes de usuários
CREATE OR REPLACE VIEW historico_pedidos_detalhado AS
SELECT 
    hp.*,
    p.codigo_pedido,
    p.numero_pedido,
    p.status AS status_atual,
    p.total AS total_atual,
    prof.nome AS alterado_por_nome_atual,
    prof.email AS alterado_por_email
FROM historico_pedidos hp
INNER JOIN pedidos p ON hp.pedido_id = p.id
LEFT JOIN profiles prof ON hp.alterado_por = prof.id
ORDER BY hp.alterado_em DESC;

-- View de mudanças de status por pedido
CREATE OR REPLACE VIEW historico_pedidos_status AS
SELECT 
    hp.pedido_id,
    p.codigo_pedido,
    hp.valor_anterior AS status_anterior,
    hp.valor_novo AS status_novo,
    hp.alterado_em,
    hp.alterado_por,
    prof.nome AS alterado_por_nome,
    EXTRACT(EPOCH FROM (
        LEAD(hp.alterado_em) OVER (PARTITION BY hp.pedido_id ORDER BY hp.alterado_em) - hp.alterado_em
    ))/60 AS minutos_no_status
FROM historico_pedidos hp
INNER JOIN pedidos p ON hp.pedido_id = p.id
LEFT JOIN profiles prof ON hp.alterado_por = prof.id
WHERE hp.tipo_evento = 'status_alterado'
ORDER BY hp.pedido_id, hp.alterado_em;

-- View de tempo médio por status
CREATE OR REPLACE VIEW historico_pedidos_tempo_medio_status AS
SELECT 
    valor_anterior AS status,
    COUNT(*) AS total_transicoes,
    AVG(EXTRACT(EPOCH FROM (
        LEAD(alterado_em) OVER (PARTITION BY pedido_id ORDER BY alterado_em) - alterado_em
    ))/60) AS tempo_medio_minutos,
    MIN(EXTRACT(EPOCH FROM (
        LEAD(alterado_em) OVER (PARTITION BY pedido_id ORDER BY alterado_em) - alterado_em
    ))/60) AS tempo_minimo_minutos,
    MAX(EXTRACT(EPOCH FROM (
        LEAD(alterado_em) OVER (PARTITION BY pedido_id ORDER BY alterado_em) - alterado_em
    ))/60) AS tempo_maximo_minutos
FROM historico_pedidos
WHERE tipo_evento = 'status_alterado'
GROUP BY valor_anterior
ORDER BY tempo_medio_minutos DESC;

-- View de cancelamentos
CREATE OR REPLACE VIEW historico_pedidos_cancelamentos AS
SELECT 
    hp.*,
    p.codigo_pedido,
    p.total,
    prof.nome AS cancelado_por_nome,
    hp.dados_evento->>'motivo' AS motivo_cancelamento,
    hp.dados_evento->>'status_anterior' AS status_antes_cancelamento
FROM historico_pedidos hp
INNER JOIN pedidos p ON hp.pedido_id = p.id
LEFT JOIN profiles prof ON hp.alterado_por = prof.id
WHERE hp.tipo_evento = 'cancelamento'
ORDER BY hp.alterado_em DESC;

-- View de alterações de valores
CREATE OR REPLACE VIEW historico_pedidos_alteracoes_valores AS
SELECT 
    hp.*,
    p.codigo_pedido,
    prof.nome AS alterado_por_nome,
    (hp.dados_evento->'valores_anteriores'->>'total')::NUMERIC AS total_anterior,
    (hp.dados_evento->'valores_novos'->>'total')::NUMERIC AS total_novo,
    (hp.dados_evento->'valores_novos'->>'total')::NUMERIC - 
    (hp.dados_evento->'valores_anteriores'->>'total')::NUMERIC AS diferenca
FROM historico_pedidos hp
INNER JOIN pedidos p ON hp.pedido_id = p.id
LEFT JOIN profiles prof ON hp.alterado_por = prof.id
WHERE hp.tipo_evento = 'valor_alterado'
ORDER BY hp.alterado_em DESC;

-- ============================================================================
-- COMENTÁRIOS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE historico_pedidos IS 'Registro imutável de todas as mudanças em pedidos. NUNCA deletar ou alterar registros. Auditoria completa para compliance e resolução de disputas';

COMMENT ON COLUMN historico_pedidos.tipo_evento IS 'Tipo do evento: criacao, status_alterado, valor_alterado, cancelamento, observacao_adicionada, entregador_atribuido, tempo_estimado_alterado, pagamento_alterado, endereco_alterado, outro';
COMMENT ON COLUMN historico_pedidos.dados_evento IS 'Dados detalhados do evento em formato JSON. Estrutura varia por tipo de evento';
COMMENT ON COLUMN historico_pedidos.snapshot_pedido IS 'Snapshot completo do pedido no momento do evento (opcional, para eventos críticos como cancelamento)';
COMMENT ON COLUMN historico_pedidos.alterado_por_tipo IS 'Origem da mudança: usuario (humano), sistema (automático), webhook (integração), api (externa)';
COMMENT ON COLUMN historico_pedidos.ip_address IS 'IP de onde veio a mudança (para auditoria avançada). NUNCA expor publicamente';
COMMENT ON COLUMN historico_pedidos.user_agent IS 'Browser/app que fez a mudança (para auditoria avançada). NUNCA expor publicamente';

COMMENT ON FUNCTION registrar_historico_pedido IS 'Trigger que registra automaticamente mudanças em pedidos. Captura: criação, mudanças de status, cancelamentos, alterações de valores, observações e tempo estimado';

COMMENT ON VIEW historico_pedidos_detalhado IS 'View com histórico completo e informações do pedido e usuário';
COMMENT ON VIEW historico_pedidos_status IS 'View com mudanças de status e tempo gasto em cada status';
COMMENT ON VIEW historico_pedidos_tempo_medio_status IS 'View com tempo médio que pedidos ficam em cada status (útil para otimização de processos)';
COMMENT ON VIEW historico_pedidos_cancelamentos IS 'View com todos os cancelamentos e motivos';
COMMENT ON VIEW historico_pedidos_alteracoes_valores IS 'View com alterações de valores (raro, mas importante para auditoria)';

-- ============================================================================
-- REGRAS DE NEGÓCIO (PARA BACKEND/FRONTEND)
-- ============================================================================
-- 
-- 1. IMUTABILIDADE
--    - NUNCA deletar registros de histórico
--    - NUNCA alterar registros de histórico
--    - Histórico é append-only (apenas inserção)
-- 
-- 2. PRIVACIDADE
--    - IP e User Agent são para auditoria interna
--    - NUNCA expor esses dados publicamente
--    - Apenas admins/super_admins podem ver
-- 
-- 3. SNAPSHOT COMPLETO
--    - Usar snapshot_pedido para eventos críticos:
--      * Cancelamento
--      * Alteração de valores
--      * Disputas
--    - Snapshot facilita análise posterior
-- 
-- 4. PERFORMANCE
--    - Histórico cresce rapidamente
--    - Considerar particionamento por data (futuro)
--    - Arquivar histórico antigo (> 2 anos)
-- 
-- 5. CONSULTAS
--    - Usar views para consultas comuns
--    - Índices otimizados para pedido_id + alterado_em
--    - JSONB permite busca flexível em dados_evento
-- 
-- 6. RELATÓRIOS
--    - Tempo médio por status (otimização)
--    - Taxa de cancelamento (qualidade)
--    - Alterações de valores (auditoria)
--    - Quem faz mais mudanças (treinamento)
-- 
-- ============================================================================

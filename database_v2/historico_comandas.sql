-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - HISTÓRICO DE COMANDAS
-- ============================================================================
-- Sistema de auditoria completa para comandas (mesas)
-- Registra TODAS as mudanças e eventos em comandas
-- ============================================================================

-- ============================================================================
-- FILOSOFIA: RASTREABILIDADE TOTAL
-- ============================================================================
-- 
-- REGRA FUNDAMENTAL: Histórico NUNCA é alterado ou deletado
-- 
-- Por quê rastreabilidade total?
--   ✅ Auditoria de operações (quem fez o quê)
--   ✅ Resolução de disputas (cliente vs garçom)
--   ✅ Análise de performance (tempo de atendimento)
--   ✅ Treinamento (identificar erros comuns)
--   ✅ Compliance (registro de todas as operações)
-- 
-- O que registrar?
--   - Abertura e fechamento de comanda
--   - Adição e cancelamento de itens
--   - Mudanças de status dos itens
--   - Divisão de conta
--   - Transferência de mesa (futuro)
--   - Observações adicionadas
--   - Qualquer mudança relevante
-- 
-- Como funciona?
--   - Trigger captura INSERT/UPDATE/DELETE
--   - Registra evento com contexto completo
--   - Identifica quem fez a ação
--   - Timestamp automático
--   - Dados em JSONB para flexibilidade
-- 
-- ============================================================================

-- ============================================================================
-- TABELA: historico_comandas
-- ============================================================================
-- Registro de todos os eventos em comandas
CREATE TABLE historico_comandas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    comanda_id UUID NOT NULL REFERENCES comandas(id) ON DELETE RESTRICT,
    loja_id UUID NOT NULL REFERENCES lojas(id) ON DELETE CASCADE,
    mesa_id UUID NOT NULL REFERENCES comandas_mesas(id) ON DELETE RESTRICT,
    
    -- Tipo de evento
    tipo_evento TEXT NOT NULL CHECK (tipo_evento IN (
        'comanda_aberta',       -- Comanda foi aberta
        'comanda_fechada',      -- Comanda foi fechada
        'comanda_cancelada',    -- Comanda foi cancelada
        'status_alterado',      -- Status da comanda mudou
        'item_adicionado',      -- Item foi adicionado
        'item_cancelado',       -- Item foi cancelado
        'item_status_alterado', -- Status do item mudou (pendente→preparando→pronto→entregue)
        'divisao_criada',       -- Divisão de conta criada
        'observacao_adicionada',-- Observação adicionada/alterada
        'pedido_gerado',        -- Comanda virou pedido
        'outro'                 -- Outros tipos de evento
    )),
    
    -- Descrição do evento
    descricao TEXT NOT NULL, -- Ex: "Item 'Pizza Calabresa' adicionado à comanda"
    
    -- Dados do evento (JSON flexível)
    dados_evento JSONB, -- Detalhes específicos do evento
    
    -- Referências relacionadas
    comanda_item_id UUID REFERENCES comanda_itens(id) ON DELETE SET NULL, -- Se evento é sobre um item
    divisao_id UUID REFERENCES comanda_divisoes(id) ON DELETE SET NULL,   -- Se evento é sobre divisão
    pedido_id UUID REFERENCES pedidos(id) ON DELETE SET NULL,             -- Se comanda virou pedido
    
    -- Estado anterior e novo (para mudanças simples)
    campo_alterado TEXT, -- Nome do campo alterado
    valor_anterior TEXT, -- Valor anterior
    valor_novo TEXT,     -- Valor novo
    
    -- Auditoria
    realizado_por UUID REFERENCES auth.users(id), -- Quem fez a ação
    realizado_por_nome TEXT, -- Snapshot do nome
    realizado_por_tipo TEXT CHECK (realizado_por_tipo IN ('garcom', 'cozinha', 'caixa', 'gerente', 'sistema')),
    realizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Metadados
    origem TEXT, -- Ex: 'web', 'mobile', 'tablet', 'sistema'
    observacoes TEXT -- Observações adicionais
);

-- Índices para performance
CREATE INDEX idx_historico_comandas_comanda ON historico_comandas(comanda_id);
CREATE INDEX idx_historico_comandas_loja ON historico_comandas(loja_id);
CREATE INDEX idx_historico_comandas_mesa ON historico_comandas(mesa_id);
CREATE INDEX idx_historico_comandas_tipo_evento ON historico_comandas(tipo_evento);
CREATE INDEX idx_historico_comandas_realizado_por ON historico_comandas(realizado_por);
CREATE INDEX idx_historico_comandas_realizado_em ON historico_comandas(realizado_em DESC);
CREATE INDEX idx_historico_comandas_item ON historico_comandas(comanda_item_id);
CREATE INDEX idx_historico_comandas_pedido ON historico_comandas(pedido_id);

-- Índice composto para consultas comuns
CREATE INDEX idx_historico_comandas_comanda_evento 
    ON historico_comandas(comanda_id, tipo_evento, realizado_em DESC);

-- Índice GIN para busca em JSONB
CREATE INDEX idx_historico_comandas_dados_evento ON historico_comandas USING GIN (dados_evento);

-- ============================================================================
-- TRIGGER: Registrar eventos de comanda
-- ============================================================================

CREATE OR REPLACE FUNCTION registrar_historico_comanda()
RETURNS TRIGGER AS $$
DECLARE
    v_tipo_evento TEXT;
    v_descricao TEXT;
    v_dados_evento JSONB;
    v_realizado_por UUID;
    v_realizado_por_tipo TEXT;
BEGIN
    -- Abertura de comanda
    IF TG_OP = 'INSERT' AND TG_TABLE_NAME = 'comandas' THEN
        INSERT INTO historico_comandas (
            comanda_id, loja_id, mesa_id, tipo_evento, descricao,
            dados_evento, realizado_por, realizado_por_tipo, realizado_em
        ) VALUES (
            NEW.id, NEW.loja_id, NEW.mesa_id,
            'comanda_aberta',
            format('Comanda #%s aberta na mesa %s', 
                NEW.numero_comanda,
                (SELECT numero_mesa FROM comandas_mesas WHERE id = NEW.mesa_id)
            ),
            jsonb_build_object(
                'numero_comanda', NEW.numero_comanda,
                'mesa_id', NEW.mesa_id,
                'observacoes', NEW.observacoes
            ),
            NEW.aberta_por, 'garcom', NEW.aberta_em
        );
        RETURN NEW;
    END IF;
    
    -- Mudança de status da comanda
    IF TG_OP = 'UPDATE' AND TG_TABLE_NAME = 'comandas' AND OLD.status IS DISTINCT FROM NEW.status THEN
        v_tipo_evento := CASE NEW.status
            WHEN 'fechada' THEN 'comanda_fechada'
            WHEN 'cancelada' THEN 'comanda_cancelada'
            ELSE 'status_alterado'
        END;
        
        v_descricao := format('Status da comanda alterado de "%s" para "%s"', OLD.status, NEW.status);
        
        v_dados_evento := jsonb_build_object(
            'status_anterior', OLD.status,
            'status_novo', NEW.status,
            'pedido_id', NEW.pedido_id,
            'motivo_cancelamento', NEW.motivo_cancelamento
        );
        
        v_realizado_por := CASE NEW.status
            WHEN 'fechada' THEN NEW.fechado_por
            WHEN 'cancelada' THEN NEW.cancelada_por
            ELSE NEW.updated_by
        END;
        
        INSERT INTO historico_comandas (
            comanda_id, loja_id, mesa_id, tipo_evento, descricao,
            campo_alterado, valor_anterior, valor_novo,
            dados_evento, pedido_id, realizado_por, realizado_por_tipo, realizado_em
        ) VALUES (
            NEW.id, NEW.loja_id, NEW.mesa_id,
            v_tipo_evento, v_descricao,
            'status', OLD.status, NEW.status,
            v_dados_evento, NEW.pedido_id, v_realizado_por, 'garcom', NOW()
        );
    END IF;
    
    -- Pedido gerado
    IF TG_OP = 'UPDATE' AND TG_TABLE_NAME = 'comandas' AND 
       OLD.pedido_id IS NULL AND NEW.pedido_id IS NOT NULL THEN
        
        INSERT INTO historico_comandas (
            comanda_id, loja_id, mesa_id, tipo_evento, descricao,
            dados_evento, pedido_id, realizado_por_tipo, realizado_em
        ) VALUES (
            NEW.id, NEW.loja_id, NEW.mesa_id,
            'pedido_gerado',
            format('Comanda convertida em pedido #%s', 
                (SELECT codigo_pedido FROM pedidos WHERE id = NEW.pedido_id)
            ),
            jsonb_build_object(
                'pedido_id', NEW.pedido_id,
                'total_itens', (SELECT COUNT(*) FROM comanda_itens WHERE comanda_id = NEW.id AND status != 'cancelado'),
                'valor_total', (SELECT SUM(valor_total) FROM comanda_itens WHERE comanda_id = NEW.id AND status != 'cancelado')
            ),
            NEW.pedido_id, 'sistema', NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em comandas
CREATE TRIGGER trigger_historico_comanda
    AFTER INSERT OR UPDATE ON comandas
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_comanda();

-- ============================================================================
-- TRIGGER: Registrar eventos de itens da comanda
-- ============================================================================

CREATE OR REPLACE FUNCTION registrar_historico_comanda_item()
RETURNS TRIGGER AS $$
DECLARE
    v_tipo_evento TEXT;
    v_descricao TEXT;
    v_dados_evento JSONB;
    v_comanda_loja_id UUID;
    v_comanda_mesa_id UUID;
BEGIN
    -- Buscar loja_id e mesa_id da comanda
    SELECT c.loja_id, c.mesa_id INTO v_comanda_loja_id, v_comanda_mesa_id
    FROM comandas c
    WHERE c.id = COALESCE(NEW.comanda_id, OLD.comanda_id);
    
    -- Item adicionado
    IF TG_OP = 'INSERT' THEN
        INSERT INTO historico_comandas (
            comanda_id, loja_id, mesa_id, comanda_item_id,
            tipo_evento, descricao, dados_evento,
            realizado_por, realizado_por_tipo, realizado_em
        ) VALUES (
            NEW.comanda_id, v_comanda_loja_id, v_comanda_mesa_id, NEW.id,
            'item_adicionado',
            format('Item "%s" adicionado (qtd: %s)', NEW.nome, NEW.quantidade),
            jsonb_build_object(
                'item_id', NEW.id,
                'tipo_item', NEW.tipo_item,
                'produto_id', NEW.produto_id,
                'combo_id', NEW.combo_id,
                'nome', NEW.nome,
                'quantidade', NEW.quantidade,
                'valor_unitario', NEW.valor_unitario,
                'valor_total', NEW.valor_total,
                'observacoes', NEW.observacoes
            ),
            NEW.adicionado_por, 'garcom', NEW.adicionado_em
        );
        RETURN NEW;
    END IF;
    
    -- Mudança de status do item
    IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
        v_tipo_evento := CASE NEW.status
            WHEN 'cancelado' THEN 'item_cancelado'
            ELSE 'item_status_alterado'
        END;
        
        v_descricao := format('Item "%s": status alterado de "%s" para "%s"', 
            NEW.nome, OLD.status, NEW.status
        );
        
        v_dados_evento := jsonb_build_object(
            'item_id', NEW.id,
            'nome', NEW.nome,
            'status_anterior', OLD.status,
            'status_novo', NEW.status,
            'quantidade', NEW.quantidade
        );
        
        INSERT INTO historico_comandas (
            comanda_id, loja_id, mesa_id, comanda_item_id,
            tipo_evento, descricao,
            campo_alterado, valor_anterior, valor_novo,
            dados_evento, realizado_por_tipo, realizado_em
        ) VALUES (
            NEW.comanda_id, v_comanda_loja_id, v_comanda_mesa_id, NEW.id,
            v_tipo_evento, v_descricao,
            'status', OLD.status, NEW.status,
            v_dados_evento,
            CASE NEW.status
                WHEN 'preparando' THEN 'cozinha'
                WHEN 'pronto' THEN 'cozinha'
                WHEN 'entregue' THEN 'garcom'
                WHEN 'cancelado' THEN 'garcom'
                ELSE 'sistema'
            END,
            NOW()
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em comanda_itens
CREATE TRIGGER trigger_historico_comanda_item
    AFTER INSERT OR UPDATE ON comanda_itens
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_comanda_item();

-- ============================================================================
-- TRIGGER: Registrar divisão de conta
-- ============================================================================

CREATE OR REPLACE FUNCTION registrar_historico_comanda_divisao()
RETURNS TRIGGER AS $$
DECLARE
    v_comanda_loja_id UUID;
    v_comanda_mesa_id UUID;
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Buscar loja_id e mesa_id da comanda
        SELECT c.loja_id, c.mesa_id INTO v_comanda_loja_id, v_comanda_mesa_id
        FROM comandas c
        WHERE c.id = NEW.comanda_id;
        
        INSERT INTO historico_comandas (
            comanda_id, loja_id, mesa_id, divisao_id,
            tipo_evento, descricao, dados_evento,
            realizado_por, realizado_por_tipo, realizado_em
        ) VALUES (
            NEW.comanda_id, v_comanda_loja_id, v_comanda_mesa_id, NEW.id,
            'divisao_criada',
            format('Divisão #%s criada: %s (R$ %s)', 
                NEW.numero_divisao, 
                COALESCE(NEW.descricao, 'Sem descrição'),
                NEW.valor_total
            ),
            jsonb_build_object(
                'divisao_id', NEW.id,
                'numero_divisao', NEW.numero_divisao,
                'descricao', NEW.descricao,
                'valor_total', NEW.valor_total,
                'pedido_id', NEW.pedido_id
            ),
            NEW.criado_por, 'garcom', NEW.criado_em
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em comanda_divisoes
CREATE TRIGGER trigger_historico_comanda_divisao
    AFTER INSERT ON comanda_divisoes
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_comanda_divisao();

-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View de histórico completo com detalhes
CREATE OR REPLACE VIEW historico_comandas_detalhado AS
SELECT 
    hc.*,
    c.numero_comanda,
    c.status AS status_atual_comanda,
    m.numero_mesa,
    m.nome AS nome_mesa,
    prof.nome AS realizado_por_nome_atual,
    prof.email AS realizado_por_email,
    CASE 
        WHEN hc.comanda_item_id IS NOT NULL THEN ci.nome
        ELSE NULL
    END AS item_nome,
    CASE 
        WHEN hc.pedido_id IS NOT NULL THEN ped.codigo_pedido
        ELSE NULL
    END AS pedido_codigo
FROM historico_comandas hc
INNER JOIN comandas c ON hc.comanda_id = c.id
INNER JOIN comandas_mesas m ON hc.mesa_id = m.id
LEFT JOIN profiles prof ON hc.realizado_por = prof.id
LEFT JOIN comanda_itens ci ON hc.comanda_item_id = ci.id
LEFT JOIN pedidos ped ON hc.pedido_id = ped.id
ORDER BY hc.realizado_em DESC;

-- View de timeline da comanda (todos os eventos em ordem)
CREATE OR REPLACE VIEW historico_comandas_timeline AS
SELECT 
    hc.comanda_id,
    c.numero_comanda,
    m.numero_mesa,
    hc.tipo_evento,
    hc.descricao,
    hc.realizado_em,
    hc.realizado_por_nome,
    hc.realizado_por_tipo,
    EXTRACT(EPOCH FROM (
        LEAD(hc.realizado_em) OVER (PARTITION BY hc.comanda_id ORDER BY hc.realizado_em) - hc.realizado_em
    ))/60 AS minutos_ate_proximo_evento
FROM historico_comandas hc
INNER JOIN comandas c ON hc.comanda_id = c.id
INNER JOIN comandas_mesas m ON hc.mesa_id = m.id
ORDER BY hc.comanda_id, hc.realizado_em;

-- View de tempo médio de atendimento por mesa
CREATE OR REPLACE VIEW historico_comandas_tempo_atendimento AS
SELECT 
    m.numero_mesa,
    m.nome AS nome_mesa,
    COUNT(DISTINCT hc.comanda_id) AS total_comandas,
    AVG(EXTRACT(EPOCH FROM (
        MAX(CASE WHEN hc.tipo_evento IN ('comanda_fechada', 'comanda_cancelada') THEN hc.realizado_em END) -
        MIN(CASE WHEN hc.tipo_evento = 'comanda_aberta' THEN hc.realizado_em END)
    ))/60) AS tempo_medio_minutos,
    MIN(EXTRACT(EPOCH FROM (
        MAX(CASE WHEN hc.tipo_evento IN ('comanda_fechada', 'comanda_cancelada') THEN hc.realizado_em END) -
        MIN(CASE WHEN hc.tipo_evento = 'comanda_aberta' THEN hc.realizado_em END)
    ))/60) AS tempo_minimo_minutos,
    MAX(EXTRACT(EPOCH FROM (
        MAX(CASE WHEN hc.tipo_evento IN ('comanda_fechada', 'comanda_cancelada') THEN hc.realizado_em END) -
        MIN(CASE WHEN hc.tipo_evento = 'comanda_aberta' THEN hc.realizado_em END)
    ))/60) AS tempo_maximo_minutos
FROM historico_comandas hc
INNER JOIN comandas_mesas m ON hc.mesa_id = m.id
GROUP BY m.numero_mesa, m.nome
ORDER BY tempo_medio_minutos DESC;

-- View de itens mais cancelados
CREATE OR REPLACE VIEW historico_comandas_itens_cancelados AS
SELECT 
    hc.dados_evento->>'nome' AS item_nome,
    COUNT(*) AS total_cancelamentos,
    SUM((hc.dados_evento->>'quantidade')::INTEGER) AS quantidade_total_cancelada,
    SUM((hc.dados_evento->>'valor_total')::NUMERIC) AS valor_total_cancelado,
    ARRAY_AGG(DISTINCT hc.realizado_por_nome) AS cancelado_por
FROM historico_comandas hc
WHERE hc.tipo_evento = 'item_cancelado'
GROUP BY hc.dados_evento->>'nome'
ORDER BY total_cancelamentos DESC;

-- View de performance por garçom
CREATE OR REPLACE VIEW historico_comandas_performance_garcom AS
SELECT 
    hc.realizado_por,
    hc.realizado_por_nome,
    COUNT(DISTINCT CASE WHEN hc.tipo_evento = 'comanda_aberta' THEN hc.comanda_id END) AS comandas_abertas,
    COUNT(DISTINCT CASE WHEN hc.tipo_evento = 'comanda_fechada' THEN hc.comanda_id END) AS comandas_fechadas,
    COUNT(CASE WHEN hc.tipo_evento = 'item_adicionado' THEN 1 END) AS itens_adicionados,
    COUNT(CASE WHEN hc.tipo_evento = 'item_cancelado' THEN 1 END) AS itens_cancelados,
    ROUND(
        COUNT(CASE WHEN hc.tipo_evento = 'item_cancelado' THEN 1 END)::NUMERIC / 
        NULLIF(COUNT(CASE WHEN hc.tipo_evento = 'item_adicionado' THEN 1 END), 0) * 100,
        2
    ) AS taxa_cancelamento_pct
FROM historico_comandas hc
WHERE hc.realizado_por_tipo = 'garcom'
GROUP BY hc.realizado_por, hc.realizado_por_nome
ORDER BY comandas_fechadas DESC;

-- ============================================================================
-- COMENTÁRIOS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE historico_comandas IS 'Registro imutável de todos os eventos em comandas. NUNCA deletar ou alterar. Rastreabilidade total para auditoria e análise de performance';

COMMENT ON COLUMN historico_comandas.tipo_evento IS 'Tipo do evento: comanda_aberta, comanda_fechada, comanda_cancelada, status_alterado, item_adicionado, item_cancelado, item_status_alterado, divisao_criada, observacao_adicionada, pedido_gerado, outro';
COMMENT ON COLUMN historico_comandas.dados_evento IS 'Dados detalhados do evento em formato JSON. Estrutura varia por tipo de evento';
COMMENT ON COLUMN historico_comandas.realizado_por_tipo IS 'Tipo de quem realizou: garcom, cozinha, caixa, gerente, sistema';

COMMENT ON FUNCTION registrar_historico_comanda IS 'Trigger que registra eventos de comandas: abertura, fechamento, cancelamento, mudanças de status, geração de pedido';
COMMENT ON FUNCTION registrar_historico_comanda_item IS 'Trigger que registra eventos de itens: adição, cancelamento, mudanças de status (pendente→preparando→pronto→entregue)';
COMMENT ON FUNCTION registrar_historico_comanda_divisao IS 'Trigger que registra criação de divisões de conta';

COMMENT ON VIEW historico_comandas_detalhado IS 'View com histórico completo e informações relacionadas (comanda, mesa, usuário, item, pedido)';
COMMENT ON VIEW historico_comandas_timeline IS 'View com timeline completa de eventos por comanda e tempo entre eventos';
COMMENT ON VIEW historico_comandas_tempo_atendimento IS 'View com tempo médio de atendimento por mesa (útil para otimização de layout)';
COMMENT ON VIEW historico_comandas_itens_cancelados IS 'View com itens mais cancelados (útil para identificar problemas no cardápio ou preparo)';
COMMENT ON VIEW historico_comandas_performance_garcom IS 'View com performance de garçons (comandas atendidas, itens adicionados, taxa de cancelamento)';

-- ============================================================================
-- REGRAS DE NEGÓCIO (PARA BACKEND/FRONTEND)
-- ============================================================================
-- 
-- 1. IMUTABILIDADE
--    - NUNCA deletar registros de histórico
--    - NUNCA alterar registros de histórico
--    - Histórico é append-only
-- 
-- 2. ANÁLISE DE PERFORMANCE
--    - Tempo médio de atendimento por mesa
--    - Itens mais cancelados (problema no cardápio?)
--    - Performance de garçons (treinamento)
--    - Horários de pico (staffing)
-- 
-- 3. RESOLUÇÃO DE DISPUTAS
--    - Timeline completa da comanda
--    - Quem adicionou cada item
--    - Quando item foi cancelado e por quem
--    - Observações registradas
-- 
-- 4. RELATÓRIOS
--    - Taxa de cancelamento por garçom
--    - Tempo médio por status de item
--    - Mesas mais/menos rentáveis
--    - Horários de maior movimento
-- 
-- 5. OTIMIZAÇÃO
--    - Identificar gargalos (cozinha lenta?)
--    - Treinar garçons com alta taxa de cancelamento
--    - Ajustar cardápio (remover itens muito cancelados)
--    - Otimizar layout (mesas com atendimento lento)
-- 
-- ============================================================================

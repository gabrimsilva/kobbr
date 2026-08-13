-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - PEDIDOS
-- ============================================================================
-- Complementa futuro_banco_sql.sql, produtos_pedidos.sql e combos.sql
-- Sistema de pedidos com suporte a produtos e combos
-- ============================================================================

-- ============================================================================
-- FILOSOFIA: SNAPSHOT IMUTÁVEL
-- ============================================================================
-- 
-- REGRA FUNDAMENTAL: Pedido é uma FOTOGRAFIA do momento da compra
-- 
-- Por que snapshot?
--   ✅ Histórico imutável (produto/combo pode mudar depois)
--   ✅ Relatórios corretos (preços não mudam retroativamente)
--   ✅ Reprocessar pedido antigo sem erro
--   ✅ Cancelamento/reembolso com valores corretos
--   ✅ Auditoria confiável
-- 
-- O que fazer snapshot?
--   - Nomes (produto, combo, sabor, adicional)
--   - Preços (unitário, adicional, total)
--   - Descrições
--   - Tamanhos
--   - Quantidades
-- 
-- O que NÃO fazer snapshot?
--   - IDs (mantém referência para relatórios)
--   - Status (muda durante o ciclo de vida)
--   - Timestamps
-- 
-- ============================================================================
-- IMPORTANTE: VALORES CONSTANTES (ENUMS)
-- ============================================================================
-- 
-- Usamos TEXT + CHECK em vez de ENUM do Postgres
-- 
-- Por quê?
--   ✅ Mais flexível para SaaS (adicionar valores sem migration)
--   ✅ Melhor para Supabase (RLS e políticas)
--   ✅ Evita problemas de ordem e alteração
-- 
-- REGRA: Mantenha valores centralizados
--   - Backend: constants/enums.ts
--   - Documentação: README ou Wiki
--   - Validação: aplicação + banco (CHECK)
-- 
-- Valores usados neste schema:
--   - tipo_entrega: 'domicilio', 'retirada', 'local'
--   - tipo_desconto: 'percentual', 'valor', 'cupom'
--   - status: 'pendente', 'confirmado', 'preparando', 'pronto', 
--            'saiu_entrega', 'entregue', 'cancelado', 'rejeitado'
--   - tipo_pagamento: 'dinheiro', 'pix', 'cartao_credito', 'cartao_debito',
--                     'vale_refeicao', 'vale_alimentacao', 'mercado_pago', 'outro'
--   - status_pagamento: 'pendente', 'processando', 'aprovado', 'recusado',
--                       'cancelado', 'estornado'
--   - tipo_cancelamento: 'cliente', 'loja', 'sistema'
--   - gateway: 'mercado_pago', 'stripe', 'pagseguro', 'outro'
-- 
-- ============================================================================

-- ============================================================================
-- TABELA: pedidos
-- ============================================================================
-- Pedidos realizados pelos clientes
CREATE TABLE pedidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_pedido SERIAL UNIQUE NOT NULL, -- Número sequencial interno
    codigo_pedido TEXT UNIQUE NOT NULL, -- Código legível para cliente/loja (ex: #PED-2024-001)
    
    -- Integração com comanda (para pedidos locais de mesa)
    -- Vinculação bidirecional: pedidos.comanda_id ↔ comandas.pedido_id
    -- Permite rastrear qual comanda gerou qual pedido
    comanda_id UUID REFERENCES comandas(id) ON DELETE SET NULL,
    
    -- Cliente (snapshot - preserva dados mesmo se cliente mudar cadastro)
    cliente_id UUID REFERENCES auth.users(id),
    cliente_nome TEXT NOT NULL,
    cliente_sobrenome TEXT,
    cliente_telefone TEXT NOT NULL,
    cliente_email TEXT,
    cliente_cpf TEXT,
    
    -- Endereço (snapshot - preserva endereço do momento da compra)
    cliente_cep TEXT,
    cliente_endereco TEXT,
    cliente_numero TEXT,
    cliente_complemento TEXT,
    cliente_bairro TEXT,
    cliente_cidade TEXT,
    cliente_estado TEXT,
    cliente_referencia TEXT, -- Ponto de referência
    cliente_latitude NUMERIC(10, 8), -- Para cálculo de distância
    cliente_longitude NUMERIC(11, 8),
    
    -- Tipo de entrega
    tipo_entrega TEXT NOT NULL CHECK (tipo_entrega IN ('domicilio', 'retirada', 'local')),
    
    -- Valores (snapshot do momento da compra)
    sub_total NUMERIC(10, 2) NOT NULL CHECK (sub_total >= 0),
    taxa_entrega NUMERIC(10, 2) DEFAULT 0.00 CHECK (taxa_entrega >= 0),
    taxa_extra_km NUMERIC(10, 2) DEFAULT 0.00 CHECK (taxa_extra_km >= 0),
    desconto NUMERIC(10, 2) DEFAULT 0.00 CHECK (desconto >= 0),
    tipo_desconto TEXT CHECK (tipo_desconto IN ('percentual', 'valor', 'cupom')),
    cupom_codigo TEXT, -- Código do cupom usado (se houver)
    acrescimo NUMERIC(10, 2) DEFAULT 0.00 CHECK (acrescimo >= 0), -- Taxa de serviço, embalagem, etc
    total NUMERIC(10, 2) NOT NULL CHECK (total >= 0),
    
    -- Status do pedido
    status TEXT NOT NULL DEFAULT 'pendente' CHECK (status IN (
        'pendente', 'confirmado', 'preparando', 'pronto', 
        'saiu_entrega', 'entregue', 'cancelado', 'rejeitado'
    )),
    
    -- Cancelamento
    pedido_cancelado BOOLEAN DEFAULT false,
    motivo_cancelamento TEXT,
    cancelado_em TIMESTAMP WITH TIME ZONE,
    cancelado_por UUID REFERENCES auth.users(id),
    
    -- Observações
    observacoes TEXT, -- Observações do cliente
    observacoes_cozinha TEXT, -- Observações internas
    motivo_rejeicao TEXT,
    
    -- Tempo estimado
    previsao_entrega TIMESTAMP WITH TIME ZONE, -- Data/hora prevista de entrega
    tempo_estimado_minutos INTEGER, -- Tempo estimado em minutos
    
    -- Timestamps importantes
    confirmado_em TIMESTAMP WITH TIME ZONE,
    preparando_em TIMESTAMP WITH TIME ZONE,
    pronto_em TIMESTAMP WITH TIME ZONE,
    saiu_entrega_em TIMESTAMP WITH TIME ZONE,
    entregue_em TIMESTAMP WITH TIME ZONE,
    rejeitado_em TIMESTAMP WITH TIME ZONE,
    
    -- Auditoria
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Validação: total = sub_total - desconto + taxa_entrega + taxa_extra_km + acrescimo
    CHECK (total = sub_total - desconto + taxa_entrega + taxa_extra_km + acrescimo)
);

-- Índices para performance
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_comanda ON pedidos(comanda_id);
CREATE INDEX idx_pedidos_status ON pedidos(status);
CREATE INDEX idx_pedidos_tipo_entrega ON pedidos(tipo_entrega);
CREATE INDEX idx_pedidos_created_at ON pedidos(created_at DESC);
CREATE INDEX idx_pedidos_numero ON pedidos(numero_pedido);
CREATE INDEX idx_pedidos_codigo ON pedidos(codigo_pedido);
CREATE INDEX idx_pedidos_cancelado ON pedidos(pedido_cancelado);
CREATE INDEX idx_pedidos_previsao ON pedidos(previsao_entrega);

-- Índices compostos para consultas comuns
CREATE INDEX idx_pedidos_status_tipo ON pedidos(status, tipo_entrega, created_at DESC);
CREATE INDEX idx_pedidos_cliente_created ON pedidos(cliente_id, created_at DESC); -- Performance para histórico do cliente

-- ============================================================================
-- TABELA: pedido_itens
-- ============================================================================
-- Itens do pedido (produtos OU combos)
-- Snapshot completo do item no momento da compra
CREATE TABLE pedido_itens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    
    -- Tipo do item
    tipo_item TEXT NOT NULL CHECK (tipo_item IN ('produto', 'combo')),
    
    -- Referências (apenas uma será preenchida)
    produto_id UUID REFERENCES produtos(id) ON DELETE RESTRICT,
    combo_id UUID REFERENCES combos(id) ON DELETE RESTRICT,
    
    -- Snapshot do item (preserva dados mesmo se produto/combo for alterado/deletado)
    nome TEXT NOT NULL,
    descricao TEXT,
    imagem_url TEXT,
    
    -- Tamanho escolhido (apenas para produtos)
    tamanho_id UUID REFERENCES tamanhos(id) ON DELETE RESTRICT,
    tamanho_label TEXT, -- Ex: P, M, G (snapshot)
    
    -- Quantidade e valores
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    valor_unitario NUMERIC(10, 2) NOT NULL CHECK (valor_unitario >= 0),
    valor_total NUMERIC(10, 2) NOT NULL CHECK (valor_total >= 0),
    
    -- Observações do item
    observacoes TEXT,
    
    -- Ordenação
    ordem_exibicao INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Validação: produto OU combo (não ambos)
    CHECK (
        (tipo_item = 'produto' AND produto_id IS NOT NULL AND combo_id IS NULL) OR
        (tipo_item = 'combo' AND combo_id IS NOT NULL AND produto_id IS NULL)
    )
);

-- Índices para performance
CREATE INDEX idx_pedido_itens_pedido ON pedido_itens(pedido_id);
CREATE INDEX idx_pedido_itens_produto ON pedido_itens(produto_id);
CREATE INDEX idx_pedido_itens_combo ON pedido_itens(combo_id);
CREATE INDEX idx_pedido_itens_tipo ON pedido_itens(tipo_item);

-- ============================================================================
-- TABELA: pedido_item_sabores
-- ============================================================================
-- Sabores escolhidos para produtos do pedido
CREATE TABLE pedido_item_sabores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_item_id UUID NOT NULL REFERENCES pedido_itens(id) ON DELETE CASCADE,
    sabor_id UUID REFERENCES sabores(id) ON DELETE RESTRICT,
    
    -- Snapshot do sabor
    sabor_nome TEXT NOT NULL,
    sabor_descricao TEXT,
    
    -- Valor adicional cobrado (se houver)
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_pedido_item_sabores_item ON pedido_item_sabores(pedido_item_id);
CREATE INDEX idx_pedido_item_sabores_sabor ON pedido_item_sabores(sabor_id);

-- ============================================================================
-- TABELA: pedido_item_borda
-- ============================================================================
-- Borda escolhida para produtos do pedido (se houver)
CREATE TABLE pedido_item_borda (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_item_id UUID NOT NULL REFERENCES pedido_itens(id) ON DELETE CASCADE,
    borda_id UUID REFERENCES bordas(id) ON DELETE RESTRICT,
    
    -- Snapshot da borda
    borda_nome TEXT NOT NULL,
    borda_descricao TEXT,
    
    -- Valor adicional cobrado
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Um item só pode ter uma borda
    UNIQUE(pedido_item_id)
);

-- Índices para performance
CREATE INDEX idx_pedido_item_borda_item ON pedido_item_borda(pedido_item_id);
CREATE INDEX idx_pedido_item_borda_borda ON pedido_item_borda(borda_id);

-- ============================================================================
-- TABELA: pedido_item_adicionais
-- ============================================================================
-- Adicionais escolhidos para produtos do pedido
CREATE TABLE pedido_item_adicionais (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_item_id UUID NOT NULL REFERENCES pedido_itens(id) ON DELETE CASCADE,
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
CREATE INDEX idx_pedido_item_adicionais_item ON pedido_item_adicionais(pedido_item_id);
CREATE INDEX idx_pedido_item_adicionais_adicional ON pedido_item_adicionais(adicional_id);

-- ============================================================================
-- TABELA: pedido_combo_itens
-- ============================================================================
-- Detalha os produtos que vieram dentro de cada combo do pedido
-- "Raio-X" do combo no momento da compra
CREATE TABLE pedido_combo_itens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_item_id UUID NOT NULL REFERENCES pedido_itens(id) ON DELETE CASCADE,
    produto_id UUID REFERENCES produtos(id) ON DELETE RESTRICT,
    
    -- Snapshot do produto
    produto_nome TEXT NOT NULL,
    produto_descricao TEXT,
    
    -- Tamanho do produto no combo
    tamanho_id UUID REFERENCES tamanhos(id) ON DELETE RESTRICT,
    tamanho_label TEXT, -- Ex: P, M, G (snapshot)
    
    -- Quantidade deste produto no combo
    quantidade INTEGER NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    
    -- Preço snapshot (para histórico)
    preco_unitario NUMERIC(10, 2) CHECK (preco_unitario >= 0),
    
    -- Ordenação
    ordem_exibicao INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_pedido_combo_itens_pedido_item ON pedido_combo_itens(pedido_item_id);
CREATE INDEX idx_pedido_combo_itens_produto ON pedido_combo_itens(produto_id);

-- ============================================================================
-- TABELA: pedido_combo_escolhas
-- ============================================================================
-- Escolhas/personalizações feitas dentro dos produtos do combo
-- Exemplo: sabores escolhidos, trocas realizadas, adicionais pagos
CREATE TABLE pedido_combo_escolhas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_combo_item_id UUID NOT NULL REFERENCES pedido_combo_itens(id) ON DELETE CASCADE,
    
    -- Tipo de escolha
    tipo_escolha TEXT NOT NULL CHECK (tipo_escolha IN ('sabor', 'borda', 'adicional', 'troca')),
    
    -- Referência ao item escolhido
    referencia_id UUID, -- ID do sabor, borda, adicional ou produto (troca)
    referencia_nome TEXT NOT NULL, -- Nome snapshot
    referencia_descricao TEXT,
    
    -- Quantidade (para adicionais)
    quantidade INTEGER DEFAULT 1 CHECK (quantidade > 0),
    
    -- Valor adicional cobrado (se houver)
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_pedido_combo_escolhas_combo_item ON pedido_combo_escolhas(pedido_combo_item_id);
CREATE INDEX idx_pedido_combo_escolhas_tipo ON pedido_combo_escolhas(tipo_escolha);
CREATE INDEX idx_pedido_combo_escolhas_referencia ON pedido_combo_escolhas(referencia_id);

-- ============================================================================
-- TABELA: pedido_pagamentos
-- ============================================================================
-- Formas de pagamento do pedido (suporta pagamento único ou dividido)
CREATE TABLE pedido_pagamentos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    
    -- Vinculação com caixa do PDV (para pedidos locais)
    -- IMPORTANTE: Permite auditoria precisa e relatórios confiáveis
    -- NULL para pedidos delivery/retirada (não passam pelo caixa)
    caixa_id UUID REFERENCES pdv_caixas(id) ON DELETE SET NULL,
    
    -- Tipo de pagamento
    tipo_pagamento TEXT NOT NULL CHECK (tipo_pagamento IN (
        'dinheiro', 'pix', 'cartao_credito', 'cartao_debito', 
        'vale_refeicao', 'vale_alimentacao', 'mercado_pago', 'outro'
    )),
    
    -- Valor pago nesta forma
    valor NUMERIC(10, 2) NOT NULL CHECK (valor >= 0),
    
    -- Troco (apenas para dinheiro)
    precisa_troco BOOLEAN DEFAULT false,
    valor_troco NUMERIC(10, 2) CHECK (valor_troco >= 0),
    
    -- Status do pagamento
    status_pagamento TEXT DEFAULT 'pendente' CHECK (status_pagamento IN (
        'pendente', 'processando', 'aprovado', 'recusado', 'cancelado', 'estornado'
    )),
    
    -- Ordenação (para pagamento dividido: pagamento 1, pagamento 2, etc)
    ordem INTEGER DEFAULT 1,
    
    -- Observações
    observacoes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_pedido_pagamentos_pedido ON pedido_pagamentos(pedido_id);
CREATE INDEX idx_pedido_pagamentos_caixa ON pedido_pagamentos(caixa_id);
CREATE INDEX idx_pedido_pagamentos_tipo ON pedido_pagamentos(tipo_pagamento);
CREATE INDEX idx_pedido_pagamentos_status ON pedido_pagamentos(status_pagamento);

-- ============================================================================
-- TABELA: pedido_pagamento_gateway
-- ============================================================================
-- Integração com gateways de pagamento (Mercado Pago, Stripe, etc)
-- Mantém dados do gateway separados para facilitar manutenção
CREATE TABLE pedido_pagamento_gateway (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_pagamento_id UUID NOT NULL REFERENCES pedido_pagamentos(id) ON DELETE CASCADE,
    
    -- Gateway usado
    gateway TEXT NOT NULL CHECK (gateway IN ('mercado_pago', 'stripe', 'pagseguro', 'outro')),
    
    -- Dados do Mercado Pago (quando gateway = 'mercado_pago')
    mercado_pago_payment_id TEXT,
    mercado_pago_status TEXT,
    mercado_pago_status_detail TEXT,
    mercado_pago_date_approved TIMESTAMP WITH TIME ZONE,
    mercado_pago_date_created TIMESTAMP WITH TIME ZONE,
    mercado_pago_payment_method_id TEXT,
    mercado_pago_payment_type_id TEXT,
    
    -- Resposta completa do gateway (JSON para auditoria)
    raw_response JSONB,
    
    -- Webhook
    webhook_recebido BOOLEAN DEFAULT false,
    webhook_recebido_em TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_pedido_pagamento_gateway_pagamento ON pedido_pagamento_gateway(pedido_pagamento_id);
CREATE INDEX idx_pedido_pagamento_gateway_mp_payment ON pedido_pagamento_gateway(mercado_pago_payment_id);
CREATE INDEX idx_pedido_pagamento_gateway_gateway ON pedido_pagamento_gateway(gateway);

-- ============================================================================
-- TABELA: pedido_cancelamentos
-- ============================================================================
-- Histórico de cancelamentos e estornos
-- Mantém auditoria completa de cancelamentos
CREATE TABLE pedido_cancelamentos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    
    -- Motivo do cancelamento
    motivo TEXT NOT NULL,
    motivo_detalhado TEXT,
    
    -- Estorno
    requer_estorno BOOLEAN DEFAULT false,
    valor_estorno NUMERIC(10, 2) CHECK (valor_estorno >= 0),
    forma_estorno TEXT, -- Como será feito o estorno (dinheiro, estorno cartão, pix, etc)
    estorno_realizado BOOLEAN DEFAULT false,
    estorno_realizado_em TIMESTAMP WITH TIME ZONE,
    
    -- Quem cancelou
    cancelado_por UUID REFERENCES auth.users(id),
    cancelado_por_nome TEXT, -- Snapshot do nome
    tipo_cancelamento TEXT CHECK (tipo_cancelamento IN ('cliente', 'loja', 'sistema')),
    
    -- Observações
    observacoes TEXT,
    
    cancelado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_pedido_cancelamentos_pedido ON pedido_cancelamentos(pedido_id);
CREATE INDEX idx_pedido_cancelamentos_cancelado_por ON pedido_cancelamentos(cancelado_por);
CREATE INDEX idx_pedido_cancelamentos_tipo ON pedido_cancelamentos(tipo_cancelamento);
CREATE INDEX idx_pedido_cancelamentos_requer_estorno ON pedido_cancelamentos(requer_estorno);

-- ============================================================================
-- TRIGGERS PARA ATUALIZAR updated_at
-- ============================================================================

CREATE TRIGGER update_pedidos_updated_at
    BEFORE UPDATE ON pedidos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pedido_pagamentos_updated_at
    BEFORE UPDATE ON pedido_pagamentos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pedido_pagamento_gateway_updated_at
    BEFORE UPDATE ON pedido_pagamento_gateway
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER: Validação de integridade de valores (OPCIONAL MAS RECOMENDADO)
-- ============================================================================
-- Garante que valor_total do item = quantidade * valor_unitario
-- Importante: Não valida adicionais aqui (são calculados na aplicação)
-- Este trigger é uma camada extra de segurança contra bugs financeiros

CREATE OR REPLACE FUNCTION validar_valor_item_pedido()
RETURNS TRIGGER AS $$
DECLARE
    v_valor_calculado NUMERIC(10, 2);
BEGIN
    -- Calcula o valor esperado (quantidade * unitário)
    v_valor_calculado := NEW.quantidade * NEW.valor_unitario;
    
    -- Valida se o valor_total é pelo menos o valor base
    -- (pode ser maior devido a adicionais, sabores premium, etc)
    IF NEW.valor_total < v_valor_calculado THEN
        RAISE EXCEPTION 'Valor total do item (%) não pode ser menor que quantidade * valor unitário (%)', 
            NEW.valor_total, v_valor_calculado;
    END IF;
    
    -- Valida se a diferença não é absurda (proteção contra erro de digitação)
    -- Permite até 10x o valor base (para casos extremos de muitos adicionais)
    IF NEW.valor_total > (v_valor_calculado * 10) THEN
        RAISE EXCEPTION 'Valor total do item (%) parece incorreto. Muito maior que o esperado (%)', 
            NEW.valor_total, v_valor_calculado;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_valor_item_pedido
    BEFORE INSERT OR UPDATE ON pedido_itens
    FOR EACH ROW
    EXECUTE FUNCTION validar_valor_item_pedido();

-- ============================================================================
-- TRIGGER: Sincronização de status cancelado
-- ============================================================================
-- Garante coerência entre pedido_cancelado e status
-- Quando status = 'cancelado', pedido_cancelado deve ser true

CREATE OR REPLACE FUNCTION sincronizar_status_cancelado()
RETURNS TRIGGER AS $$
BEGIN
    -- Se status mudou para cancelado, marca flag
    IF NEW.status = 'cancelado' AND NEW.pedido_cancelado = false THEN
        NEW.pedido_cancelado := true;
        NEW.cancelado_em := COALESCE(NEW.cancelado_em, NOW());
    END IF;
    
    -- Se status mudou de cancelado para outro, desmarca flag
    IF NEW.status != 'cancelado' AND OLD.status = 'cancelado' THEN
        NEW.pedido_cancelado := false;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sincronizar_status_cancelado
    BEFORE UPDATE ON pedidos
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION sincronizar_status_cancelado();

-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View de pedidos com totalizadores
CREATE OR REPLACE VIEW pedidos_resumo AS
SELECT 
    p.*,
    COUNT(DISTINCT pi.id) AS total_itens,
    SUM(pi.quantidade) AS total_produtos,
    CASE 
        WHEN p.entregue_em IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (p.entregue_em - p.created_at))/60
        WHEN p.pronto_em IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (p.pronto_em - p.created_at))/60
        ELSE NULL
    END AS tempo_total_minutos
FROM pedidos p
LEFT JOIN pedido_itens pi ON p.id = pi.pedido_id
GROUP BY p.id
ORDER BY p.created_at DESC;

-- View de pedidos ativos (não finalizados)
CREATE OR REPLACE VIEW pedidos_ativos AS
SELECT * FROM pedidos
WHERE status NOT IN ('entregue', 'cancelado', 'rejeitado')
ORDER BY created_at;

-- View de pedidos do dia
CREATE OR REPLACE VIEW pedidos_hoje AS
SELECT * FROM pedidos
WHERE DATE(created_at) = CURRENT_DATE
ORDER BY created_at DESC;

-- View detalhada de pedido com itens
CREATE OR REPLACE VIEW pedidos_detalhado AS
SELECT 
    p.id AS pedido_id,
    p.numero_pedido,
    p.codigo_pedido,
    p.cliente_nome,
    p.status,
    p.tipo_entrega,
    p.total,
    pi.id AS item_id,
    pi.tipo_item,
    pi.nome AS item_nome,
    pi.quantidade,
    pi.valor_unitario,
    pi.valor_total AS item_valor_total
FROM pedidos p
INNER JOIN pedido_itens pi ON p.id = pi.pedido_id
ORDER BY p.created_at DESC, pi.ordem_exibicao;

-- ============================================================================
-- COMENTÁRIOS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE pedidos IS 'Pedidos realizados pelos clientes (domicilio, retirada ou local) com snapshot imutável';
COMMENT ON TABLE pedido_itens IS 'Itens do pedido (produtos OU combos) com snapshot completo no momento da compra';
COMMENT ON TABLE pedido_item_sabores IS 'Sabores escolhidos para produtos do pedido';
COMMENT ON TABLE pedido_item_borda IS 'Borda escolhida para produtos do pedido (máximo uma por item)';
COMMENT ON TABLE pedido_item_adicionais IS 'Adicionais escolhidos para produtos do pedido';
COMMENT ON TABLE pedido_combo_itens IS 'Detalha os produtos que vieram dentro de cada combo (raio-X do combo)';
COMMENT ON TABLE pedido_combo_escolhas IS 'Escolhas/personalizações feitas dentro dos produtos do combo (sabores, trocas, adicionais)';
COMMENT ON TABLE pedido_pagamentos IS 'Formas de pagamento do pedido (suporta pagamento único ou dividido em múltiplas formas)';
COMMENT ON TABLE pedido_pagamento_gateway IS 'Integração com gateways de pagamento (Mercado Pago, Stripe, etc) - mantém dados separados';
COMMENT ON TABLE pedido_cancelamentos IS 'Histórico de cancelamentos e estornos com auditoria completa';

COMMENT ON COLUMN pedidos.comanda_id IS 'Vinculação com comanda (para pedidos locais de mesa). Vinculação bidirecional: pedidos.comanda_id ↔ comandas.pedido_id. Permite rastrear qual comanda gerou qual pedido. NULL para pedidos delivery/retirada';
COMMENT ON COLUMN pedidos.numero_pedido IS 'Número sequencial interno do pedido';
COMMENT ON COLUMN pedidos.codigo_pedido IS 'Código legível para exibição ao cliente/loja (ex: #PED-2024-001)';
COMMENT ON COLUMN pedidos.sub_total IS 'Soma dos valores dos itens (antes de taxas e descontos)';
COMMENT ON COLUMN pedidos.taxa_entrega IS 'Taxa de entrega cobrada (snapshot do momento)';
COMMENT ON COLUMN pedidos.taxa_extra_km IS 'Taxa extra por quilometragem adicional';
COMMENT ON COLUMN pedidos.desconto IS 'Desconto aplicado no pedido (cupom, promoção, etc)';
COMMENT ON COLUMN pedidos.tipo_desconto IS 'Tipo do desconto: percentual, valor fixo ou cupom';
COMMENT ON COLUMN pedidos.acrescimo IS 'Acréscimo aplicado (taxa de serviço, embalagem, etc)';
COMMENT ON COLUMN pedidos.total IS 'Valor final do pedido (sub_total + taxa_entrega + taxa_extra_km + acrescimo - desconto)';
COMMENT ON COLUMN pedidos.previsao_entrega IS 'Data/hora prevista de entrega/retirada';
COMMENT ON COLUMN pedidos.tempo_estimado_minutos IS 'Tempo estimado de preparo/entrega informado ao cliente';
COMMENT ON COLUMN pedidos.pedido_cancelado IS 'Flag rápida para identificar pedidos cancelados (ver pedido_cancelamentos para detalhes). Sincronizada automaticamente com status';
COMMENT ON COLUMN pedidos.cancelado_em IS 'Data/hora do cancelamento. Preenchida automaticamente quando status muda para cancelado';

COMMENT ON COLUMN pedido_itens.tipo_item IS 'Tipo do item: produto (individual) ou combo (agrupado)';
COMMENT ON COLUMN pedido_itens.valor_unitario IS 'Valor unitário do item no momento da compra (snapshot)';
COMMENT ON COLUMN pedido_itens.valor_total IS 'Valor total do item (unitário * quantidade + adicionais)';

COMMENT ON COLUMN pedido_combo_itens.preco_unitario IS 'Preço unitário do produto no momento (para histórico e relatórios)';

COMMENT ON COLUMN pedido_combo_escolhas.tipo_escolha IS 'Tipo de escolha: sabor, borda, adicional ou troca';
COMMENT ON COLUMN pedido_combo_escolhas.referencia_id IS 'ID do sabor, borda, adicional ou produto (para relatórios)';
COMMENT ON COLUMN pedido_combo_escolhas.referencia_nome IS 'Nome snapshot do item escolhido';
COMMENT ON COLUMN pedido_combo_escolhas.valor_adicional IS 'Valor adicional cobrado por esta escolha';

COMMENT ON COLUMN pedido_pagamentos.tipo_pagamento IS 'Tipo de pagamento: dinheiro, pix, cartão, etc';
COMMENT ON COLUMN pedido_pagamentos.caixa_id IS 'Vinculação com caixa do PDV (apenas para pedidos locais). NULL para delivery/retirada. Permite auditoria precisa e relatórios confiáveis';
COMMENT ON COLUMN pedido_pagamentos.valor IS 'Valor pago nesta forma de pagamento';
COMMENT ON COLUMN pedido_pagamentos.precisa_troco IS 'Se true, cliente precisa de troco (apenas para dinheiro)';
COMMENT ON COLUMN pedido_pagamentos.valor_troco IS 'Valor do troco a ser dado (apenas para dinheiro)';
COMMENT ON COLUMN pedido_pagamentos.ordem IS 'Ordem do pagamento (1 = primeiro, 2 = segundo) para pagamento dividido';

COMMENT ON COLUMN pedido_pagamento_gateway.gateway IS 'Gateway de pagamento usado (mercado_pago, stripe, etc)';
COMMENT ON COLUMN pedido_pagamento_gateway.mercado_pago_payment_id IS 'ID do pagamento no Mercado Pago';
COMMENT ON COLUMN pedido_pagamento_gateway.mercado_pago_status IS 'Status do pagamento no Mercado Pago';
COMMENT ON COLUMN pedido_pagamento_gateway.mercado_pago_date_approved IS 'Data de aprovação do pagamento no Mercado Pago';
COMMENT ON COLUMN pedido_pagamento_gateway.raw_response IS 'Resposta completa do gateway em JSON (para auditoria e debug)';

COMMENT ON COLUMN pedido_cancelamentos.motivo IS 'Motivo resumido do cancelamento';
COMMENT ON COLUMN pedido_cancelamentos.requer_estorno IS 'Se true, pedido requer estorno de pagamento';
COMMENT ON COLUMN pedido_cancelamentos.valor_estorno IS 'Valor a ser estornado ao cliente';
COMMENT ON COLUMN pedido_cancelamentos.forma_estorno IS 'Como será feito o estorno (dinheiro, estorno cartão, pix, etc)';
COMMENT ON COLUMN pedido_cancelamentos.tipo_cancelamento IS 'Quem iniciou o cancelamento: cliente, loja ou sistema';

COMMENT ON FUNCTION validar_valor_item_pedido IS 'Trigger que valida integridade financeira: valor_total >= quantidade * valor_unitario. Permite até 10x para adicionais';
COMMENT ON FUNCTION sincronizar_status_cancelado IS 'Trigger que mantém coerência entre status=cancelado e flag pedido_cancelado';

COMMENT ON VIEW pedidos_resumo IS 'View com totalizadores e tempo de processamento dos pedidos';
COMMENT ON VIEW pedidos_ativos IS 'View com apenas pedidos em andamento (não finalizados)';
COMMENT ON VIEW pedidos_hoje IS 'View com pedidos do dia atual';
COMMENT ON VIEW pedidos_detalhado IS 'View completa com pedido e todos os itens relacionados';

-- ============================================================================
-- DADOS DE EXEMPLO (OPCIONAL - COMENTADO)
-- ============================================================================

/*
-- Exemplo de pedido delivery
INSERT INTO pedidos (
    cliente_nome, cliente_telefone, tipo_pedido,
    endereco_completo, endereco_cep, endereco_rua, endereco_numero, endereco_bairro,
    subtotal, taxa_entrega, valor_total, forma_pagamento, status
)
VALUES (
    'João Silva', '11999999999', 'delivery',
    'Rua das Flores, 123 - Centro', '01234-567', 'Rua das Flores', '123', 'Centro',
    45.00, 5.00, 50.00, 'dinheiro', 'pendente'
);

-- Exemplo de item produto
INSERT INTO pedido_itens (
    pedido_id, tipo_item, produto_id, nome, tamanho_label,
    quantidade, valor_unitario, valor_total
)
VALUES (
    (SELECT id FROM pedidos ORDER BY created_at DESC LIMIT 1),
    'produto',
    (SELECT id FROM produtos WHERE slug = 'pizza-calabresa'),
    'Pizza Calabresa',
    'G',
    1,
    45.00,
    45.00
);

-- Exemplo de item combo
INSERT INTO pedido_itens (
    pedido_id, tipo_item, combo_id, nome,
    quantidade, valor_unitario, valor_total
)
VALUES (
    (SELECT id FROM pedidos ORDER BY created_at DESC LIMIT 1),
    'combo',
    (SELECT id FROM combos WHERE slug = 'combo-familia'),
    'Combo Família',
    1,
    89.90,
    89.90
);
*/

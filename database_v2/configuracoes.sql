-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - CONFIGURAÇÕES
-- ============================================================================
-- Sistema de configurações flexível para o sistema de delivery/pizzaria
-- Permite configurar horários, taxas, áreas de entrega, formas de pagamento, etc
-- ============================================================================
-- IMPORTANTE: Sistema de LOJA ÚNICA (não multi-tenant)
-- ============================================================================

-- ============================================================================
-- FILOSOFIA: CONFIGURAÇÃO FLEXÍVEL E TIPADA
-- ============================================================================
-- 
-- REGRA FUNDAMENTAL: Configurações são chave-valor com tipo e categoria
-- 
-- Por quê chave-valor?
--   ✅ Flexibilidade total (adicionar configs sem migration)
--   ✅ Fácil de gerenciar via interface
--   ✅ Suporta múltiplos tipos de dados
--   ✅ Categorização para organização
--   ✅ Validação por tipo
--   ✅ Troca de valores sem deploy
-- 
-- Tipos suportados:
--   - texto: Strings simples
--   - numero: Valores numéricos (inteiros ou decimais)
--   - booleano: true/false
--   - json: Objetos complexos (horários, áreas, etc)
-- 
-- Categorias sugeridas:
--   - geral: Configurações gerais do sistema
--   - entrega: Taxas, áreas, tempo estimado
--   - pagamento: Formas de pagamento aceitas
--   - visual: Cores, logos, temas
--   - notificacao: Configurações de notificações
--   - horario: Horários de funcionamento
--   - cardapio: Configurações do cardápio
--   - impressao: Configurações de impressão
--   - integracao: APIs externas (Mercado Pago, etc)
-- 
-- ============================================================================

-- ============================================================================
-- TABELA: configuracoes
-- ============================================================================
-- Armazena todas as configurações do sistema (loja única)
CREATE TABLE configuracoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Chave e valor
    chave TEXT NOT NULL UNIQUE, -- Ex: 'taxa_entrega_base', 'horario_funcionamento'
    valor TEXT NOT NULL, -- Valor em formato texto (convertido conforme tipo)
    
    -- Metadados
    descricao TEXT, -- Descrição da configuração
    tipo TEXT NOT NULL DEFAULT 'texto' CHECK (tipo IN ('texto', 'numero', 'booleano', 'json')),
    categoria TEXT NOT NULL DEFAULT 'geral' CHECK (categoria IN (
        'geral', 'entrega', 'pagamento', 'visual', 'notificacao', 
        'horario', 'cardapio', 'impressao', 'integracao'
    )),
    
    -- Controle
    obrigatoria BOOLEAN DEFAULT false, -- Se true, não pode ser deletada
    valor_padrao TEXT, -- Valor padrão se não configurado
    
    -- Segurança
    sensivel BOOLEAN DEFAULT false, -- Se true, valor só visível para admins (tokens, keys, senhas)
    
    -- Auditoria
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id), -- Backend SEMPRE deve setar (não confiar em trigger)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Validação de JSON: se tipo='json', valor deve ser JSON válido
    -- NOTA TÉCNICA: valor::jsonb IS NOT NULL funciona porque:
    --   - Se JSON for válido: cast funciona, retorna NOT NULL = true
    --   - Se JSON for inválido: cast falha, constraint falha (comportamento desejado)
    --   - Pode criar função is_json(text) futuramente para mais clareza
    CHECK (
        tipo != 'json' 
        OR valor IS NULL 
        OR valor::jsonb IS NOT NULL
    )
);

-- Índices para performance
CREATE INDEX idx_configuracoes_chave ON configuracoes(chave);
CREATE INDEX idx_configuracoes_categoria ON configuracoes(categoria);
CREATE INDEX idx_configuracoes_tipo ON configuracoes(tipo);
CREATE INDEX idx_configuracoes_obrigatoria ON configuracoes(obrigatoria);
CREATE INDEX idx_configuracoes_sensivel ON configuracoes(sensivel);

-- ============================================================================
-- TABELA: configuracoes_historico
-- ============================================================================
-- Histórico de alterações em configurações (auditoria completa)
-- Registra QUEM mudou, QUANDO mudou, e O QUE mudou (valor antigo → novo)

CREATE TABLE configuracoes_historico (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    configuracao_id UUID REFERENCES configuracoes(id) ON DELETE CASCADE,
    
    -- Dados da configuração
    chave TEXT NOT NULL,
    valor_antigo TEXT,
    valor_novo TEXT,
    
    -- Metadados
    tipo TEXT,
    categoria TEXT,
    
    -- Auditoria
    alterado_por UUID REFERENCES auth.users(id),
    alterado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Contexto adicional (opcional)
    motivo TEXT, -- Motivo da alteração (opcional, backend pode enviar, apenas admins visualizam)
    ip_address INET, -- IP de onde veio a alteração (NUNCA expor publicamente)
    user_agent TEXT -- User agent (NUNCA expor publicamente)
);

-- Índices para consultas de auditoria
CREATE INDEX idx_configuracoes_historico_configuracao ON configuracoes_historico(configuracao_id);
CREATE INDEX idx_configuracoes_historico_chave ON configuracoes_historico(chave);
CREATE INDEX idx_configuracoes_historico_alterado_por ON configuracoes_historico(alterado_por);
CREATE INDEX idx_configuracoes_historico_alterado_em ON configuracoes_historico(alterado_em DESC);

-- Índice composto para consultas comuns
CREATE INDEX idx_configuracoes_historico_chave_data ON configuracoes_historico(chave, alterado_em DESC);

-- ============================================================================
-- TRIGGER PARA ATUALIZAR updated_at
-- ============================================================================

CREATE TRIGGER update_configuracoes_updated_at
    BEFORE UPDATE ON configuracoes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER PARA REGISTRAR HISTÓRICO DE ALTERAÇÕES
-- ============================================================================

CREATE OR REPLACE FUNCTION registrar_historico_configuracao()
RETURNS TRIGGER AS $$
BEGIN
    -- Só registra se o valor mudou
    IF OLD.valor IS DISTINCT FROM NEW.valor THEN
        INSERT INTO configuracoes_historico (
            configuracao_id,
            chave,
            valor_antigo,
            valor_novo,
            tipo,
            categoria,
            alterado_por
        ) VALUES (
            NEW.id,
            NEW.chave,
            OLD.valor,
            NEW.valor,
            NEW.tipo,
            NEW.categoria,
            NEW.updated_by
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_registrar_historico_configuracao
    AFTER UPDATE ON configuracoes
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historico_configuracao();

-- ============================================================================
-- FUNÇÃO: Obter configuração com fallback para valor padrão
-- ============================================================================

CREATE OR REPLACE FUNCTION obter_configuracao(
    p_chave TEXT,
    p_valor_padrao TEXT DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
    v_valor TEXT;
BEGIN
    -- Buscar configuração
    SELECT valor INTO v_valor
    FROM configuracoes
    WHERE chave = p_chave;
    
    -- Se não encontrou, retornar valor padrão da tabela ou parâmetro
    IF v_valor IS NULL THEN
        SELECT COALESCE(valor_padrao, p_valor_padrao) INTO v_valor
        FROM configuracoes
        WHERE chave = p_chave;
    END IF;
    
    RETURN v_valor;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNÇÃO: Obter configuração como JSON
-- ============================================================================

CREATE OR REPLACE FUNCTION obter_configuracao_json(
    p_chave TEXT,
    p_valor_padrao JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_valor TEXT;
BEGIN
    v_valor := obter_configuracao(p_chave);
    
    IF v_valor IS NULL THEN
        RETURN p_valor_padrao;
    END IF;
    
    RETURN v_valor::JSONB;
EXCEPTION
    WHEN OTHERS THEN
        RETURN p_valor_padrao;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNÇÃO: Obter configuração como número
-- ============================================================================

CREATE OR REPLACE FUNCTION obter_configuracao_numero(
    p_chave TEXT,
    p_valor_padrao NUMERIC DEFAULT NULL
)
RETURNS NUMERIC AS $$
DECLARE
    v_valor TEXT;
BEGIN
    v_valor := obter_configuracao(p_chave);
    
    IF v_valor IS NULL THEN
        RETURN p_valor_padrao;
    END IF;
    
    RETURN v_valor::NUMERIC;
EXCEPTION
    WHEN OTHERS THEN
        RETURN p_valor_padrao;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNÇÃO: Obter configuração como booleano
-- ============================================================================

CREATE OR REPLACE FUNCTION obter_configuracao_booleano(
    p_chave TEXT,
    p_valor_padrao BOOLEAN DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_valor TEXT;
BEGIN
    v_valor := obter_configuracao(p_chave);
    
    IF v_valor IS NULL THEN
        RETURN p_valor_padrao;
    END IF;
    
    -- Aceita: 'true', 'false', '1', '0', 't', 'f', 'yes', 'no'
    RETURN v_valor::BOOLEAN;
EXCEPTION
    WHEN OTHERS THEN
        RETURN p_valor_padrao;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View de configurações por categoria
CREATE OR REPLACE VIEW configuracoes_por_categoria AS
SELECT 
    categoria,
    COUNT(*) AS total_configuracoes,
    COUNT(*) FILTER (WHERE obrigatoria = true) AS total_obrigatorias,
    COUNT(*) FILTER (WHERE sensivel = true) AS total_sensiveis,
    ARRAY_AGG(chave ORDER BY chave) AS chaves
FROM configuracoes
GROUP BY categoria
ORDER BY categoria;

-- View de configurações com valores tipados (OCULTA valores sensíveis)
CREATE OR REPLACE VIEW configuracoes_detalhado AS
SELECT 
    c.id,
    c.chave,
    -- SEGURANÇA: Oculta valores sensíveis (backend deve filtrar por permissão)
    CASE 
        WHEN c.sensivel = true THEN '********'
        ELSE c.valor
    END AS valor,
    c.descricao,
    c.tipo,
    c.categoria,
    c.obrigatoria,
    c.sensivel,
    c.valor_padrao,
    c.created_by,
    c.updated_by,
    c.created_at,
    c.updated_at,
    prof.nome AS atualizado_por_nome,
    CASE c.tipo
        WHEN 'numero' THEN 
            CASE WHEN c.valor ~ '^[0-9]+\.?[0-9]*$' THEN 'VÁLIDO' ELSE 'INVÁLIDO' END
        WHEN 'booleano' THEN 
            CASE WHEN c.valor IN ('true', 'false', '1', '0', 't', 'f', 'yes', 'no') THEN 'VÁLIDO' ELSE 'INVÁLIDO' END
        WHEN 'json' THEN 
            CASE WHEN c.valor::TEXT IS NOT NULL THEN 
                CASE WHEN c.valor::JSONB IS NOT NULL THEN 'VÁLIDO' ELSE 'INVÁLIDO' END
            ELSE 'INVÁLIDO' END
        ELSE 'VÁLIDO'
    END AS validacao_tipo
FROM configuracoes c
LEFT JOIN profiles prof ON c.updated_by = prof.id
ORDER BY c.categoria, c.chave;

-- View de histórico de configurações (últimas 100 alterações)
CREATE OR REPLACE VIEW configuracoes_historico_recente AS
SELECT 
    h.*,
    prof.nome AS alterado_por_nome,
    -- Indica se foi aumento ou redução (útil para taxas, valores)
    CASE 
        WHEN h.tipo = 'numero' AND h.valor_antigo::NUMERIC < h.valor_novo::NUMERIC THEN 'AUMENTO'
        WHEN h.tipo = 'numero' AND h.valor_antigo::NUMERIC > h.valor_novo::NUMERIC THEN 'REDUÇÃO'
        WHEN h.valor_antigo != h.valor_novo THEN 'ALTERAÇÃO'
        ELSE 'SEM MUDANÇA'
    END AS tipo_mudanca
FROM configuracoes_historico h
LEFT JOIN profiles prof ON h.alterado_por = prof.id
ORDER BY h.alterado_em DESC
LIMIT 100;

-- View de auditoria: configurações sensíveis alteradas (ACESSO RESTRITO)
CREATE OR REPLACE VIEW configuracoes_sensiveis_auditoria AS
SELECT 
    h.id,
    h.chave,
    h.alterado_por,
    prof.nome AS alterado_por_nome,
    h.alterado_em,
    h.ip_address,
    h.user_agent,
    -- NÃO mostra valores (apenas que houve mudança)
    'VALOR ALTERADO' AS status
FROM configuracoes_historico h
INNER JOIN configuracoes c ON h.configuracao_id = c.id
LEFT JOIN profiles prof ON h.alterado_por = prof.id
WHERE c.sensivel = true
ORDER BY h.alterado_em DESC;

-- ============================================================================
-- COMENTÁRIOS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE configuracoes IS 'Configurações flexíveis do sistema (loja única). Sistema chave-valor com tipo e categoria. IMPORTANTE: Habilitar RLS - apenas backend/admins acessam';
COMMENT ON TABLE configuracoes_historico IS 'Histórico imutável de alterações em configurações. Registra quem mudou, quando e o que mudou. IMPORTANTE: Habilitar RLS - apenas admins acessam';

COMMENT ON COLUMN configuracoes.chave IS 'Chave única da configuração (ex: taxa_entrega_base, horario_funcionamento)';
COMMENT ON COLUMN configuracoes.valor IS 'Valor da configuração em formato texto (convertido conforme tipo)';
COMMENT ON COLUMN configuracoes.tipo IS 'Tipo do valor: texto, numero, booleano, json';
COMMENT ON COLUMN configuracoes.categoria IS 'Categoria da configuração: geral, entrega, pagamento, visual, notificacao, horario, cardapio, impressao, integracao';
COMMENT ON COLUMN configuracoes.obrigatoria IS 'Se true, configuração não pode ser deletada (apenas editada)';
COMMENT ON COLUMN configuracoes.sensivel IS 'Se true, valor só visível para admins (tokens, keys, senhas). Backend deve filtrar acesso';
COMMENT ON COLUMN configuracoes.valor_padrao IS 'Valor padrão se configuração não estiver definida';

COMMENT ON COLUMN configuracoes_historico.valor_antigo IS 'Valor antes da alteração';
COMMENT ON COLUMN configuracoes_historico.valor_novo IS 'Valor após a alteração';
COMMENT ON COLUMN configuracoes_historico.motivo IS 'Motivo da alteração (opcional). Backend pode enviar. Apenas admins visualizam. Ex: "ajuste de taxa", "correção de horário"';
COMMENT ON COLUMN configuracoes_historico.ip_address IS 'IP de origem da alteração. NUNCA expor publicamente - apenas auditoria interna';
COMMENT ON COLUMN configuracoes_historico.user_agent IS 'User agent da alteração. NUNCA expor publicamente - apenas auditoria interna';

COMMENT ON FUNCTION obter_configuracao IS 'Obtém valor de configuração com fallback para valor padrão';
COMMENT ON FUNCTION obter_configuracao_json IS 'Obtém configuração como JSONB com fallback';
COMMENT ON FUNCTION obter_configuracao_numero IS 'Obtém configuração como NUMERIC com fallback';
COMMENT ON FUNCTION obter_configuracao_booleano IS 'Obtém configuração como BOOLEAN com fallback';
COMMENT ON FUNCTION registrar_historico_configuracao IS 'Trigger function que registra automaticamente alterações em configurações';

COMMENT ON VIEW configuracoes_por_categoria IS 'View com resumo de configurações agrupadas por categoria';
COMMENT ON VIEW configuracoes_detalhado IS 'View com configurações e validação de tipo. OCULTA valores sensíveis (mostra *******)';
COMMENT ON VIEW configuracoes_historico_recente IS 'View com últimas 100 alterações em configurações';
COMMENT ON VIEW configuracoes_sensiveis_auditoria IS 'View de auditoria para configurações sensíveis. ACESSO RESTRITO - apenas admins';

-- ============================================================================
-- CONFIGURAÇÕES PADRÃO (EXEMPLOS)
-- ============================================================================
-- Estas configurações devem ser inseridas ao inicializar o sistema
-- Executar uma única vez na instalação

/*
-- CATEGORIA: GERAL
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria, obrigatoria, valor_padrao)
VALUES 
    ('nome_loja', 'Minha Pizzaria', 'Nome da loja', 'texto', 'geral', true, 'Minha Loja'),
    ('telefone_loja', '(11) 99999-9999', 'Telefone da loja', 'texto', 'geral', true, ''),
    ('email_loja', 'contato@pizzaria.com', 'Email da loja', 'texto', 'geral', true, ''),
    ('endereco_loja', 'Rua das Flores, 123', 'Endereço da loja', 'texto', 'geral', true, '');

-- CATEGORIA: ENTREGA
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria, obrigatoria, valor_padrao)
VALUES 
    ('taxa_entrega_base', '5.00', 'Taxa de entrega base em reais', 'numero', 'entrega', true, '5.00'),
    ('taxa_entrega_por_km', '2.00', 'Taxa adicional por km', 'numero', 'entrega', false, '0.00'),
    ('distancia_maxima_entrega', '10', 'Distância máxima de entrega em km', 'numero', 'entrega', false, '10'),
    ('tempo_estimado_preparo', '40', 'Tempo estimado de preparo em minutos', 'numero', 'entrega', true, '40'),
    ('valor_minimo_pedido', '30.00', 'Valor mínimo do pedido', 'numero', 'entrega', false, '0.00'),
    ('entrega_gratis_acima', '100.00', 'Valor para entrega grátis', 'numero', 'entrega', false, '0.00');

-- CATEGORIA: PAGAMENTO
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria, obrigatoria, valor_padrao)
VALUES 
    ('aceita_dinheiro', 'true', 'Aceita pagamento em dinheiro', 'booleano', 'pagamento', true, 'true'),
    ('aceita_pix', 'true', 'Aceita pagamento via PIX', 'booleano', 'pagamento', true, 'true'),
    ('aceita_cartao_credito', 'true', 'Aceita cartão de crédito', 'booleano', 'pagamento', true, 'true'),
    ('aceita_cartao_debito', 'true', 'Aceita cartão de débito', 'booleano', 'pagamento', true, 'true'),
    ('aceita_vale_refeicao', 'false', 'Aceita vale refeição', 'booleano', 'pagamento', false, 'false'),
    ('chave_pix', '11999999999', 'Chave PIX da loja', 'texto', 'pagamento', false, '');

-- CATEGORIA: HORARIO
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria, obrigatoria, valor_padrao)
VALUES 
    ('horario_funcionamento', '{"segunda":{"aberto":true,"inicio":"18:00","fim":"23:00"},"terca":{"aberto":true,"inicio":"18:00","fim":"23:00"},"quarta":{"aberto":true,"inicio":"18:00","fim":"23:00"},"quinta":{"aberto":true,"inicio":"18:00","fim":"23:00"},"sexta":{"aberto":true,"inicio":"18:00","fim":"23:30"},"sabado":{"aberto":true,"inicio":"18:00","fim":"23:30"},"domingo":{"aberto":true,"inicio":"18:00","fim":"23:00"}}', 'Horário de funcionamento por dia da semana', 'json', 'horario', true, '{}'),
    ('loja_aberta', 'true', 'Loja está aberta para pedidos', 'booleano', 'horario', true, 'true');

-- CATEGORIA: VISUAL
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria, obrigatoria, valor_padrao)
VALUES 
    ('cor_primaria', '#FF6B6B', 'Cor primária do tema', 'texto', 'visual', false, '#FF6B6B'),
    ('cor_secundaria', '#4ECDC4', 'Cor secundária do tema', 'texto', 'visual', false, '#4ECDC4'),
    ('logo_url', '', 'URL do logo da loja', 'texto', 'visual', false, ''),
    ('banner_url', '', 'URL do banner da loja', 'texto', 'visual', false, '');

-- CATEGORIA: NOTIFICACAO
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria, obrigatoria, valor_padrao)
VALUES 
    ('notificar_whatsapp', 'true', 'Enviar notificações via WhatsApp', 'booleano', 'notificacao', false, 'false'),
    ('notificar_email', 'false', 'Enviar notificações via email', 'booleano', 'notificacao', false, 'false'),
    ('notificar_sms', 'false', 'Enviar notificações via SMS', 'booleano', 'notificacao', false, 'false'),
    ('som_novo_pedido', 'true', 'Tocar som ao receber novo pedido', 'booleano', 'notificacao', false, 'true');

-- CATEGORIA: CARDAPIO
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria, obrigatoria, valor_padrao)
VALUES 
    ('exibir_produtos_esgotados', 'false', 'Exibir produtos esgotados no cardápio', 'booleano', 'cardapio', false, 'false'),
    ('permitir_observacoes', 'true', 'Permitir observações nos pedidos', 'booleano', 'cardapio', false, 'true'),
    ('maximo_sabores_pizza', '3', 'Máximo de sabores por pizza', 'numero', 'cardapio', false, '3');

-- CATEGORIA: IMPRESSAO
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria, obrigatoria, valor_padrao)
VALUES 
    ('impressao_automatica', 'false', 'Imprimir pedidos automaticamente', 'booleano', 'impressao', false, 'false'),
    ('impressora_padrao', '', 'Nome da impressora padrão', 'texto', 'impressao', false, ''),
    ('imprimir_cozinha', 'true', 'Imprimir cópia para cozinha', 'booleano', 'impressao', false, 'true');

-- CATEGORIA: INTEGRACAO (ATENÇÃO: Marcar sensivel=true para tokens/keys)
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria, obrigatoria, sensivel, valor_padrao)
VALUES 
    ('mercado_pago_public_key', '', 'Chave pública do Mercado Pago', 'texto', 'integracao', false, false, ''),
    ('mercado_pago_access_token', '', 'Access token do Mercado Pago', 'texto', 'integracao', false, true, ''), -- SENSÍVEL
    ('google_analytics_id', '', 'ID do Google Analytics', 'texto', 'integracao', false, false, '');

-- EXEMPLO: Configurações sensíveis (tokens, senhas, keys)
-- Estas NUNCA devem ser expostas publicamente
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria, obrigatoria, sensivel, valor_padrao)
VALUES 
    ('smtp_password', '', 'Senha do servidor SMTP', 'texto', 'integracao', false, true, ''),
    ('api_secret_key', '', 'Chave secreta da API', 'texto', 'integracao', false, true, ''),
    ('webhook_secret', '', 'Secret para validar webhooks', 'texto', 'integracao', false, true, '');
*/

-- ============================================================================
-- REGRAS DE NEGÓCIO (PARA BACKEND/FRONTEND)
-- ============================================================================
-- 
-- 1. CRIAÇÃO DE CONFIGURAÇÕES
--    - Ao inicializar o sistema, inserir configurações padrão
--    - Usar valores padrão sensatos
--    - Marcar configurações críticas como obrigatórias
--    - Marcar tokens/keys como sensíveis
-- 
-- 2. VALIDAÇÃO DE TIPO
--    - Backend deve validar tipo antes de salvar
--    - numero: validar se é numérico
--    - booleano: aceitar true/false, 1/0, yes/no
--    - json: validar se é JSON válido (CHECK constraint no banco)
--    - ⚠️ NOTA TÉCNICA: CHECK (valor::jsonb IS NOT NULL) funciona mas não é explícito
--      * Ele falha se JSON for inválido (comportamento desejado)
--      * Pode criar função is_json(text) futuramente se quiser mais clareza
--      * Por enquanto, está correto e funcional
-- 
-- 3. OBTENÇÃO DE CONFIGURAÇÕES
--    - Usar funções helper (obter_configuracao_*)
--    - Sempre ter fallback para valor padrão
--    - Cache no backend para performance
--    - Exemplo: obter_configuracao('taxa_entrega_base', '5.00')
-- 
-- 4. CONFIGURAÇÕES OBRIGATÓRIAS
--    - Não podem ser deletadas
--    - Apenas editadas
--    - Validar no backend antes de deletar
-- 
-- 5. CONFIGURAÇÕES SENSÍVEIS (SEGURANÇA CRÍTICA)
--    - sensivel = true: tokens, keys, senhas, secrets
--    - Backend DEVE filtrar por permissão:
--      * Admin/SuperAdmin: vê valor real
--      * Outros: vê '********' ou null
--    - Frontend: sempre exibir '********' se sensivel=true
--    - NUNCA expor em logs, analytics, ou APIs públicas
--    - Frontend NUNCA acessa tokens diretamente (sempre via backend)
--    - Exemplos: mercado_pago_access_token, smtp_password, api_secret_key
-- 
-- 6. HISTÓRICO DE ALTERAÇÕES (AUDITORIA)
--    - Trigger automático registra TODAS as mudanças
--    - Registra: quem, quando, valor antigo, valor novo
--    - Campo 'motivo' (opcional):
--      * Backend pode enviar motivo da alteração
--      * Não obrigatório
--      * Apenas admins visualizam
--      * Exemplos: "ajuste de taxa", "correção de horário", "troca de token"
--    - Útil para:
--      * Rastrear mudanças em taxas de entrega
--      * Investigar cobranças erradas
--      * Auditoria de segurança (quem mudou tokens)
--      * Suporte ao cliente (quando mudou horário)
--    - IP e User Agent: NUNCA expor publicamente
-- 
-- 7. AUDITORIA (updated_by)
--    - Campo updated_by é opcional no banco (correto)
--    - ⚠️ REGRA DE NEGÓCIO CRÍTICA:
--      * Backend SEMPRE deve setar updated_by
--      * NUNCA confiar em trigger para isso
--      * É responsabilidade da API, não do SQL
--      * Validar no backend antes de UPDATE
-- 
-- 8. HORÁRIO DE FUNCIONAMENTO
--    - Armazenar como JSON
--    - Estrutura: {dia: {aberto, inicio, fim}}
--    - Backend valida se loja está aberta
--    - Histórico rastreia mudanças de horário
-- 
-- 9. PERFORMANCE
--    - Cache de configurações no backend
--    - Invalidar cache ao atualizar
--    - Índices otimizados para consultas
--    - Views pré-calculadas
-- 
-- 10. INTERFACE
--     - Agrupar por categoria
--     - Validação em tempo real
--     - Ajuda contextual (descrição)
--     - Preview de mudanças
--     - Ocultar valores sensíveis (*******)
--     - Mostrar histórico de alterações
-- 
-- 11. INTEGRAÇÃO COM OUTROS MÓDULOS
--     - Pedidos: taxa_entrega_base, valor_minimo_pedido, tempo_estimado_preparo
--     - Checkout: aceita_pix, aceita_cartao, chave_pix
--     - Cardápio: maximo_sabores_pizza, exibir_produtos_esgotados
--     - Mercado Pago: mercado_pago_access_token (sensível), mercado_pago_public_key
--     - Perfis: apenas admin/superadmin pode alterar
-- 
-- 12. SEGURANÇA (RLS - Row Level Security) - SUPABASE
--     ⚠️ CONFIGURAÇÃO CRÍTICA:
--     
--     Tabela: configuracoes
--     - SELECT: apenas backend (service_role)
--     - INSERT/UPDATE/DELETE: apenas admin/superadmin
--     - Frontend NUNCA acessa diretamente
--     
--     Tabela: configuracoes_historico
--     - SELECT: apenas admin/superadmin
--     - INSERT: apenas trigger (automático)
--     - UPDATE/DELETE: NUNCA (histórico imutável)
--     - Frontend NUNCA acessa
--     
--     Exemplo de RLS (Supabase):
--     
--     -- Configurações: apenas backend
--     ALTER TABLE configuracoes ENABLE ROW LEVEL SECURITY;
--     
--     CREATE POLICY "Backend pode ler configurações"
--     ON configuracoes FOR SELECT
--     TO service_role
--     USING (true);
--     
--     CREATE POLICY "Apenas admins podem alterar"
--     ON configuracoes FOR ALL
--     TO authenticated
--     USING (
--       EXISTS (
--         SELECT 1 FROM profiles
--         WHERE profiles.id = auth.uid()
--         AND profiles.cargo IN ('superadmin', 'admin')
--       )
--     );
--     
--     -- Histórico: apenas admins
--     ALTER TABLE configuracoes_historico ENABLE ROW LEVEL SECURITY;
--     
--     CREATE POLICY "Apenas admins podem ver histórico"
--     ON configuracoes_historico FOR SELECT
--     TO authenticated
--     USING (
--       EXISTS (
--         SELECT 1 FROM profiles
--         WHERE profiles.id = auth.uid()
--         AND profiles.cargo IN ('superadmin', 'admin')
--       )
--     );
-- 
-- 13. NORMALIZAÇÃO FUTURA (OPCIONAL)
--     - Algumas configs MUITO usadas podem virar tabelas próprias:
--       * status_loja (aberta/fechada) → campo na tabela principal
--       * horarios_especiais (feriados) → tabela própria
--       * taxas_por_bairro → tabela areas_entrega
--     - Por enquanto, chave-valor é suficiente e flexível
--     - Refatorar apenas se houver necessidade de performance/complexidade
-- 
-- ============================================================================

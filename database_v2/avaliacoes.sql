-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - AVALIAÇÕES
-- ============================================================================
-- Complementa todos os SQLs anteriores
-- Sistema de avaliações de pedidos com badges e moderação
-- ============================================================================

-- ============================================================================
-- FILOSOFIA: AVALIAÇÃO VINCULADA A PEDIDO + AVALIAÇÃO DA LOJA
-- ============================================================================
-- 
-- REGRA FUNDAMENTAL: Dois tipos de avaliação
-- 
-- 1. AVALIAÇÃO DE PEDIDO (obrigatória)
--    - Vinculada a um pedido específico
--    - Avalia a experiência daquele pedido
--    - Usado para: NPS, relatórios, histórico
-- 
-- 2. AVALIAÇÃO DA LOJA (opcional)
--    - Avaliação geral do estabelecimento
--    - Pode ser feita sem pedido (visitante, Google, etc)
--    - Usado para: média geral, página pública
-- 
-- Por quê dois tipos?
--   ✅ Avaliação de pedido: rastreável, confiável, auditável
--   ✅ Avaliação de loja: permite feedback de visitantes
--   ✅ Relatórios precisos (separar por origem)
--   ✅ Flexibilidade (importar do Google, redes sociais)
-- 
-- Fluxo pedido:
--   1. Cliente faz pedido
--   2. Pedido é entregue
--   3. Sistema envia link de avaliação
--   4. Cliente avalia (1x por pedido)
--   5. Loja modera (aprova/rejeita)
--   6. Avaliação aprovada aparece publicamente
-- 
-- Fluxo loja:
--   1. Cliente/visitante acessa página de avaliação
--   2. Avalia experiência geral (sem pedido vinculado)
--   3. Loja modera
--   4. Aparece na média geral
-- 
-- ============================================================================

-- ============================================================================
-- TABELA: badges_disponiveis
-- ============================================================================
-- Cadastro de badges que podem ser atribuídos às avaliações
-- Permite gerenciar badges sem alterar código
CREATE TABLE badges_disponiveis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo TEXT UNIQUE NOT NULL, -- Ex: comida-deliciosa, entrega-rapida
    nome TEXT NOT NULL, -- Ex: Comida Deliciosa, Entrega Rápida
    descricao TEXT,
    icone TEXT, -- Nome do ícone ou emoji
    cor TEXT, -- Cor hex para exibição (#FF5733)
    categoria TEXT CHECK (categoria IN ('comida', 'entrega', 'atendimento', 'ambiente', 'geral')),
    ordem_exibicao INTEGER DEFAULT 0,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_badges_disponiveis_ativo ON badges_disponiveis(ativo);
CREATE INDEX idx_badges_disponiveis_categoria ON badges_disponiveis(categoria);
CREATE INDEX idx_badges_disponiveis_codigo ON badges_disponiveis(codigo);

-- ============================================================================
-- TABELA: avaliacoes
-- ============================================================================
-- Avaliações de pedidos E da loja feitas pelos clientes
CREATE TABLE avaliacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Tipo de avaliação
    tipo_avaliacao TEXT NOT NULL CHECK (tipo_avaliacao IN ('pedido', 'loja')) DEFAULT 'pedido',
    
    -- Vinculação com pedido (obrigatória para tipo='pedido', opcional para tipo='loja')
    pedido_id UUID REFERENCES pedidos(id) ON DELETE RESTRICT,
    
    -- Cliente (snapshot + referência)
    cliente_id UUID REFERENCES auth.users(id),
    cliente_nome TEXT NOT NULL,
    cliente_email TEXT, -- Para resposta da loja
    
    -- Avaliação
    estrelas INTEGER NOT NULL CHECK (estrelas >= 1 AND estrelas <= 5),
    titulo TEXT, -- Título curto da avaliação (opcional)
    descricao TEXT, -- Descrição detalhada
    
    -- Aspectos específicos (opcional - permite avaliação detalhada)
    estrelas_comida INTEGER CHECK (estrelas_comida >= 1 AND estrelas_comida <= 5),
    estrelas_entrega INTEGER CHECK (estrelas_entrega >= 1 AND estrelas_entrega <= 5),
    estrelas_atendimento INTEGER CHECK (estrelas_atendimento >= 1 AND estrelas_atendimento <= 5),
    
    -- Recomendação
    recomenda BOOLEAN, -- Cliente recomendaria o estabelecimento? (NPS)
    
    -- Anonimato (permite avaliação pública sem mostrar nome)
    anonima BOOLEAN DEFAULT false,
    
    -- Status de moderação (simplificado)
    status_moderacao TEXT NOT NULL DEFAULT 'pendente' CHECK (status_moderacao IN ('pendente', 'aprovada', 'rejeitada')),
    motivo_rejeicao TEXT,
    moderado_por UUID REFERENCES auth.users(id),
    moderado_em TIMESTAMP WITH TIME ZONE,
    
    -- Resposta da loja
    resposta_loja TEXT,
    respondido_por UUID REFERENCES auth.users(id),
    respondido_em TIMESTAMP WITH TIME ZONE,
    
    -- Visibilidade
    publica BOOLEAN DEFAULT true, -- Se false, avaliação fica privada
    destaque BOOLEAN DEFAULT false, -- Destacar na página principal
    
    -- Origem da avaliação (para rastreamento)
    origem TEXT DEFAULT 'sistema' CHECK (origem IN ('sistema', 'google', 'facebook', 'instagram', 'manual', 'importacao')),
    origem_url TEXT, -- URL de origem (se importada)
    
    -- Denúncia (se cliente ou loja reportar problema)
    denunciada BOOLEAN DEFAULT false,
    motivo_denuncia TEXT,
    denunciada_em TIMESTAMP WITH TIME ZONE,
    
    -- Metadados úteis (NUNCA expor publicamente)
    ip_cliente INET, -- IP do cliente (para auditoria)
    user_agent TEXT, -- Navegador usado (para auditoria)
    
    -- Soft delete
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    -- Auditoria
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Validação: se tipo='pedido', pedido_id é obrigatório
    CHECK (
        (tipo_avaliacao = 'pedido' AND pedido_id IS NOT NULL) OR
        (tipo_avaliacao = 'loja')
    ),
    
    -- Validação: avaliações detalhadas (comida, entrega, atendimento) só para pedidos
    CHECK (
        tipo_avaliacao = 'pedido' OR 
        (estrelas_comida IS NULL AND estrelas_entrega IS NULL AND estrelas_atendimento IS NULL)
    )
);

-- Índices para performance
CREATE INDEX idx_avaliacoes_tipo ON avaliacoes(tipo_avaliacao);
CREATE INDEX idx_avaliacoes_pedido ON avaliacoes(pedido_id);
CREATE INDEX idx_avaliacoes_cliente ON avaliacoes(cliente_id);
CREATE INDEX idx_avaliacoes_estrelas ON avaliacoes(estrelas);
CREATE INDEX idx_avaliacoes_status_moderacao ON avaliacoes(status_moderacao);
CREATE INDEX idx_avaliacoes_publica ON avaliacoes(publica);
CREATE INDEX idx_avaliacoes_destaque ON avaliacoes(destaque);
CREATE INDEX idx_avaliacoes_deleted_at ON avaliacoes(deleted_at);
CREATE INDEX idx_avaliacoes_created_at ON avaliacoes(created_at DESC);
CREATE INDEX idx_avaliacoes_origem ON avaliacoes(origem);

-- Índice composto para consultas públicas
CREATE INDEX idx_avaliacoes_publicas ON avaliacoes(status_moderacao, publica, deleted_at, created_at DESC);
CREATE INDEX idx_avaliacoes_tipo_status ON avaliacoes(tipo_avaliacao, status_moderacao, deleted_at);

-- Índice para moderação por data (performance em alto volume)
CREATE INDEX idx_avaliacoes_moderacao_data 
    ON avaliacoes(status_moderacao, created_at DESC) 
    WHERE deleted_at IS NULL;

-- Índice para acelerar joins pedido + tipo
CREATE INDEX idx_avaliacoes_pedido_tipo 
    ON avaliacoes(pedido_id, tipo_avaliacao) 
    WHERE deleted_at IS NULL;

-- Índice único parcial: garante que um pedido só tenha uma avaliação (apenas para tipo='pedido' e não deletados)
-- IMPORTANTE: Este índice substitui a necessidade de trigger de validação de duplicata
-- Índice único é mais eficiente e garante atomicidade em race conditions
CREATE UNIQUE INDEX uniq_avaliacao_pedido 
    ON avaliacoes(pedido_id) 
    WHERE tipo_avaliacao = 'pedido' AND deleted_at IS NULL;

-- ============================================================================
-- TABELA: avaliacao_badges
-- ============================================================================
-- Relaciona avaliações com badges escolhidos pelo cliente
CREATE TABLE avaliacao_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    avaliacao_id UUID NOT NULL REFERENCES avaliacoes(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL REFERENCES badges_disponiveis(id) ON DELETE RESTRICT,
    
    -- Snapshot do badge (preserva se badge for alterado/deletado)
    badge_codigo TEXT NOT NULL,
    badge_nome TEXT NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação: mesmo badge não pode aparecer 2x na mesma avaliação
    UNIQUE(avaliacao_id, badge_id)
);

-- Índices para performance
CREATE INDEX idx_avaliacao_badges_avaliacao ON avaliacao_badges(avaliacao_id);
CREATE INDEX idx_avaliacao_badges_badge ON avaliacao_badges(badge_id);

-- ============================================================================
-- TABELA: avaliacao_midias
-- ============================================================================
-- Fotos/vídeos anexados à avaliação pelo cliente
CREATE TABLE avaliacao_midias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    avaliacao_id UUID NOT NULL REFERENCES avaliacoes(id) ON DELETE CASCADE,
    
    -- Mídia
    tipo_midia TEXT NOT NULL CHECK (tipo_midia IN ('foto', 'video')),
    url_midia TEXT NOT NULL, -- URL no storage do Supabase
    url_thumbnail TEXT, -- Thumbnail para fotos/vídeos
    
    -- Metadados
    tamanho_bytes BIGINT,
    largura INTEGER,
    altura INTEGER,
    
    -- Ordenação
    ordem_exibicao INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_avaliacao_midias_avaliacao ON avaliacao_midias(avaliacao_id);
CREATE INDEX idx_avaliacao_midias_tipo ON avaliacao_midias(tipo_midia);

-- ============================================================================
-- TRIGGERS PARA ATUALIZAR updated_at
-- ============================================================================

CREATE TRIGGER update_badges_disponiveis_updated_at
    BEFORE UPDATE ON badges_disponiveis
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_avaliacoes_updated_at
    BEFORE UPDATE ON avaliacoes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER: Validação de pedido entregue
-- ============================================================================
-- Garante que só pedidos entregues podem ser avaliados
-- Roda em INSERT e UPDATE para evitar bypass via mudança de tipo

CREATE OR REPLACE FUNCTION validar_pedido_entregue()
RETURNS TRIGGER AS $$
DECLARE
    v_status TEXT;
BEGIN
    -- Apenas valida para avaliações de pedido
    IF NEW.tipo_avaliacao = 'pedido' AND NEW.pedido_id IS NOT NULL THEN
        -- Busca status do pedido
        SELECT status INTO v_status
        FROM pedidos
        WHERE id = NEW.pedido_id;
        
        -- Valida se pedido foi entregue
        IF v_status != 'entregue' THEN
            RAISE EXCEPTION 'Apenas pedidos entregues podem ser avaliados. Status atual: %', v_status;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_pedido_entregue
    BEFORE INSERT OR UPDATE ON avaliacoes
    FOR EACH ROW
    EXECUTE FUNCTION validar_pedido_entregue();

-- ============================================================================
-- TRIGGER: Preencher dados do cliente automaticamente
-- ============================================================================
-- Busca dados do pedido para preencher snapshot (apenas para avaliações de pedido)

CREATE OR REPLACE FUNCTION preencher_dados_cliente_avaliacao()
RETURNS TRIGGER AS $$
DECLARE
    v_pedido RECORD;
BEGIN
    -- Apenas preenche para avaliações de pedido
    IF NEW.tipo_avaliacao = 'pedido' AND NEW.pedido_id IS NOT NULL THEN
        -- Busca dados do pedido
        SELECT cliente_id, cliente_nome, cliente_email
        INTO v_pedido
        FROM pedidos
        WHERE id = NEW.pedido_id;
        
        -- Preenche automaticamente se não foi informado
        IF NEW.cliente_id IS NULL THEN
            NEW.cliente_id := v_pedido.cliente_id;
        END IF;
        
        IF NEW.cliente_nome IS NULL OR NEW.cliente_nome = '' THEN
            NEW.cliente_nome := v_pedido.cliente_nome;
        END IF;
        
        IF NEW.cliente_email IS NULL OR NEW.cliente_email = '' THEN
            NEW.cliente_email := v_pedido.cliente_email;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_preencher_dados_cliente_avaliacao
    BEFORE INSERT ON avaliacoes
    FOR EACH ROW
    EXECUTE FUNCTION preencher_dados_cliente_avaliacao();

-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View de avaliações públicas (aprovadas e visíveis)
CREATE OR REPLACE VIEW avaliacoes_publicas AS
SELECT 
    a.id,
    a.tipo_avaliacao,
    a.pedido_id,
    a.cliente_id,
    CASE 
        WHEN a.anonima = true THEN 'Anônimo'
        ELSE a.cliente_nome
    END AS cliente_nome,
    a.estrelas,
    a.titulo,
    a.descricao,
    a.estrelas_comida,
    a.estrelas_entrega,
    a.estrelas_atendimento,
    a.recomenda,
    a.resposta_loja,
    a.respondido_em,
    a.destaque,
    a.origem,
    a.created_at,
    p.codigo_pedido,
    p.tipo_entrega,
    p.total AS valor_pedido,
    ARRAY_AGG(ab.badge_nome ORDER BY ab.created_at) FILTER (WHERE ab.badge_nome IS NOT NULL) AS badges
FROM avaliacoes a
LEFT JOIN pedidos p ON a.pedido_id = p.id
LEFT JOIN avaliacao_badges ab ON a.id = ab.avaliacao_id
WHERE a.deleted_at IS NULL
  AND a.status_moderacao = 'aprovada'
  AND a.publica = true
GROUP BY a.id, p.codigo_pedido, p.tipo_entrega, p.total
ORDER BY a.created_at DESC;

-- View de estatísticas de avaliações (geral)
CREATE OR REPLACE VIEW avaliacoes_estatisticas AS
SELECT 
    COUNT(*) AS total_avaliacoes,
    COUNT(*) FILTER (WHERE status_moderacao = 'aprovada') AS total_aprovadas,
    COUNT(*) FILTER (WHERE status_moderacao = 'rejeitada') AS total_rejeitadas,
    COUNT(*) FILTER (WHERE status_moderacao = 'pendente') AS total_pendentes,
    COUNT(*) FILTER (WHERE tipo_avaliacao = 'pedido') AS total_pedidos,
    COUNT(*) FILTER (WHERE tipo_avaliacao = 'loja') AS total_loja,
    ROUND(AVG(estrelas), 2) AS media_estrelas,
    ROUND(AVG(estrelas) FILTER (WHERE status_moderacao = 'aprovada'), 2) AS media_estrelas_aprovadas,
    ROUND(AVG(estrelas) FILTER (WHERE tipo_avaliacao = 'pedido' AND status_moderacao = 'aprovada'), 2) AS media_estrelas_pedidos,
    ROUND(AVG(estrelas) FILTER (WHERE tipo_avaliacao = 'loja' AND status_moderacao = 'aprovada'), 2) AS media_estrelas_loja,
    COUNT(*) FILTER (WHERE estrelas = 5) AS total_5_estrelas,
    COUNT(*) FILTER (WHERE estrelas = 4) AS total_4_estrelas,
    COUNT(*) FILTER (WHERE estrelas = 3) AS total_3_estrelas,
    COUNT(*) FILTER (WHERE estrelas = 2) AS total_2_estrelas,
    COUNT(*) FILTER (WHERE estrelas = 1) AS total_1_estrela,
    COUNT(*) FILTER (WHERE recomenda = true) AS total_recomenda,
    ROUND(
        COUNT(*) FILTER (WHERE recomenda = true)::NUMERIC / 
        NULLIF(COUNT(*) FILTER (WHERE recomenda IS NOT NULL), 0) * 100, 
        2
    ) AS percentual_recomendacao
FROM avaliacoes
WHERE deleted_at IS NULL;

-- View de avaliações pendentes de moderação
CREATE OR REPLACE VIEW avaliacoes_pendentes AS
SELECT 
    a.*,
    p.codigo_pedido,
    p.cliente_telefone,
    p.total AS valor_pedido
FROM avaliacoes a
LEFT JOIN pedidos p ON a.pedido_id = p.id
WHERE a.deleted_at IS NULL
  AND a.status_moderacao = 'pendente'
ORDER BY a.created_at;

-- View de badges mais usados
CREATE OR REPLACE VIEW badges_ranking AS
SELECT 
    bd.id,
    bd.codigo,
    bd.nome,
    bd.categoria,
    COUNT(ab.id) AS total_usos,
    COUNT(ab.id) FILTER (WHERE a.status_moderacao = 'aprovada') AS total_usos_aprovados
FROM badges_disponiveis bd
LEFT JOIN avaliacao_badges ab ON bd.id = ab.badge_id
LEFT JOIN avaliacoes a ON ab.avaliacao_id = a.id AND a.deleted_at IS NULL
WHERE bd.ativo = true
GROUP BY bd.id, bd.codigo, bd.nome, bd.categoria
ORDER BY total_usos_aprovados DESC, bd.ordem_exibicao;

-- ============================================================================
-- COMENTÁRIOS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE badges_disponiveis IS 'Cadastro de badges que podem ser atribuídos às avaliações (gerenciável sem alterar código)';
COMMENT ON TABLE avaliacoes IS 'Avaliações de pedidos feitas pelos clientes com moderação e resposta da loja';
COMMENT ON TABLE avaliacao_badges IS 'Relaciona avaliações com badges escolhidos pelo cliente';
COMMENT ON TABLE avaliacao_midias IS 'Fotos e vídeos anexados às avaliações pelos clientes';

COMMENT ON COLUMN avaliacoes.tipo_avaliacao IS 'Tipo: pedido (vinculada a compra) ou loja (avaliação geral do estabelecimento)';
COMMENT ON COLUMN avaliacoes.pedido_id IS 'Pedido avaliado (obrigatório para tipo=pedido, opcional para tipo=loja)';
COMMENT ON COLUMN avaliacoes.estrelas IS 'Nota geral de 1 a 5 estrelas';
COMMENT ON COLUMN avaliacoes.estrelas_comida IS 'Nota específica para comida (apenas para tipo=pedido)';
COMMENT ON COLUMN avaliacoes.estrelas_entrega IS 'Nota específica para entrega (apenas para tipo=pedido)';
COMMENT ON COLUMN avaliacoes.estrelas_atendimento IS 'Nota específica para atendimento (apenas para tipo=pedido)';
COMMENT ON COLUMN avaliacoes.recomenda IS 'Se cliente recomendaria o estabelecimento (NPS)';
COMMENT ON COLUMN avaliacoes.anonima IS 'Se true, nome do cliente não é exibido publicamente (avaliação anônima)';
COMMENT ON COLUMN avaliacoes.status_moderacao IS 'Status da moderação: pendente, aprovada ou rejeitada';
COMMENT ON COLUMN avaliacoes.publica IS 'Se avaliação é visível publicamente (mesmo aprovada, pode ser privada)';
COMMENT ON COLUMN avaliacoes.destaque IS 'Se avaliação deve ser destacada na página principal';
COMMENT ON COLUMN avaliacoes.resposta_loja IS 'Resposta da loja à avaliação do cliente';
COMMENT ON COLUMN avaliacoes.origem IS 'Origem da avaliação: sistema (padrão), google, facebook, instagram, manual, importacao';
COMMENT ON COLUMN avaliacoes.origem_url IS 'URL de origem se avaliação foi importada de outra plataforma';
COMMENT ON COLUMN avaliacoes.ip_cliente IS 'IP do cliente (NUNCA expor publicamente - apenas auditoria interna)';
COMMENT ON COLUMN avaliacoes.user_agent IS 'Navegador usado (NUNCA expor publicamente - apenas auditoria interna)';

COMMENT ON VIEW avaliacoes_publicas IS 'View com avaliações aprovadas e públicas, incluindo badges agregados';
COMMENT ON VIEW avaliacoes_estatisticas IS 'View com estatísticas gerais de avaliações (média, distribuição, NPS)';
COMMENT ON VIEW avaliacoes_pendentes IS 'View com avaliações aguardando moderação';
COMMENT ON VIEW badges_ranking IS 'View com ranking de badges mais usados';

COMMENT ON FUNCTION validar_pedido_entregue IS 'Trigger que garante que apenas pedidos entregues podem ser avaliados (roda em INSERT e UPDATE)';
COMMENT ON FUNCTION preencher_dados_cliente_avaliacao IS 'Trigger que preenche automaticamente dados do cliente a partir do pedido (apenas para tipo=pedido)';

-- ============================================================================
-- DADOS INICIAIS: BADGES PADRÃO
-- ============================================================================

INSERT INTO badges_disponiveis (codigo, nome, descricao, icone, cor, categoria, ordem_exibicao) VALUES
('comida-deliciosa', 'Comida Deliciosa', 'Comida saborosa e bem preparada', '🍕', '#FF6B6B', 'comida', 1),
('entrega-rapida', 'Entrega Rápida', 'Entrega dentro do prazo ou antes', '⚡', '#4ECDC4', 'entrega', 2),
('ambiente-agradavel', 'Ambiente Agradável', 'Local limpo e aconchegante', '🏠', '#95E1D3', 'ambiente', 3),
('qualidade-premium', 'Qualidade Premium', 'Ingredientes de alta qualidade', '⭐', '#FFD93D', 'comida', 4),
('atendimento-excelente', 'Atendimento Excelente', 'Equipe atenciosa e educada', '👏', '#6BCB77', 'atendimento', 5),
('preco-justo', 'Preço Justo', 'Ótimo custo-benefício', '💰', '#4D96FF', 'geral', 6),
('localizacao-otima', 'Localização Ótima', 'Fácil acesso e bem localizado', '📍', '#FF8787', 'geral', 7),
('recomendo', 'Recomendo', 'Recomendo para amigos e família', '👍', '#A8E6CF', 'geral', 8),
('embalagem-caprichada', 'Embalagem Caprichada', 'Produto bem embalado e protegido', '📦', '#FFB6B9', 'entrega', 9),
('porcao-generosa', 'Porção Generosa', 'Quantidade satisfatória', '🍽️', '#FEC8D8', 'comida', 10);

-- ============================================================================
-- DADOS DE EXEMPLO (OPCIONAL - COMENTADO)
-- ============================================================================

/*
-- Exemplo de avaliação
INSERT INTO avaliacoes (
    pedido_id, cliente_nome, estrelas, titulo, descricao, recomenda
)
VALUES (
    (SELECT id FROM pedidos WHERE codigo_pedido = '#PED-2024-001'),
    'João Silva',
    5,
    'Excelente!',
    'Pizza deliciosa, entrega rápida e atendimento impecável. Super recomendo!',
    true
);

-- Exemplo de badges na avaliação
INSERT INTO avaliacao_badges (avaliacao_id, badge_id, badge_codigo, badge_nome)
VALUES 
    (
        (SELECT id FROM avaliacoes ORDER BY created_at DESC LIMIT 1),
        (SELECT id FROM badges_disponiveis WHERE codigo = 'comida-deliciosa'),
        'comida-deliciosa',
        'Comida Deliciosa'
    ),
    (
        (SELECT id FROM avaliacoes ORDER BY created_at DESC LIMIT 1),
        (SELECT id FROM badges_disponiveis WHERE codigo = 'entrega-rapida'),
        'entrega-rapida',
        'Entrega Rápida'
    );
*/

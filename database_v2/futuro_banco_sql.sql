-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - DELIVERY (SABORES, BORDAS, ADICIONAIS)
-- ============================================================================
-- Sistema de delivery com foco em pizzaria
-- Estrutura normalizada e flexível para Supabase + React
-- ============================================================================
-- IMPORTANTE: Sistema de LOJA ÚNICA (não multi-tenant)
-- ============================================================================

-- ============================================================================
-- HIERARQUIA DE REGRAS (IMPORTANTE - LEIA ANTES DE USAR)
-- ============================================================================
-- 
-- categoria_configuracoes → Define o que É POSSÍVEL
--   - Exemplo: permite_sabores = true significa que produtos desta categoria
--              PODEM ter sabores, mas não são obrigados
-- 
-- produtos → Define o que É USADO
--   - Exemplo: permite_sabores = false significa que ESTE produto específico
--              não aceita sabores, mesmo que a categoria permita
--   - Regra: Produto NÃO PODE ativar algo que a categoria proíbe
-- 
-- produto_tamanhos → Define PREÇO
--   - Exemplo: Pizza Calabresa tamanho G = R$ 45,00
--   - Cada produto pode ter múltiplos tamanhos com preços diferentes
-- 
-- RESUMO: Categoria = máximo permitido | Produto = uso real | Tamanho = preço
-- ============================================================================

-- ============================================================================
-- TABELA: categorias
-- ============================================================================
-- Armazena informações básicas das categorias de produtos
CREATE TABLE categorias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    descricao TEXT,
    slug TEXT UNIQUE NOT NULL,
    ordem_exibicao INTEGER DEFAULT 0,
    ativa BOOLEAN DEFAULT true,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_categorias_ativa ON categorias(ativa);
CREATE INDEX idx_categorias_ordem ON categorias(ordem_exibicao);
CREATE INDEX idx_categorias_slug ON categorias(slug);
CREATE INDEX idx_categorias_created_by ON categorias(created_by);
CREATE INDEX idx_categorias_updated_by ON categorias(updated_by);

-- ============================================================================
-- TABELA: categoria_configuracoes
-- ============================================================================
-- Define o comportamento e permissões de cada categoria
-- Relação 1:1 explícita: categoria_id é PK e FK ao mesmo tempo
CREATE TABLE categoria_configuracoes (
    categoria_id UUID PRIMARY KEY REFERENCES categorias(id) ON DELETE CASCADE,
    permite_sabores BOOLEAN DEFAULT false,
    permite_bordas BOOLEAN DEFAULT false,
    permite_adicionais BOOLEAN DEFAULT false,
    permite_tamanhos BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- TABELA: tipos_sabor
-- ============================================================================
-- Define os tipos de sabores (Doce, Salgado, Especial, etc)
-- Permite regras de negócio como "meio a meio só pode doce + doce"
CREATE TABLE tipos_sabor (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    ativo BOOLEAN DEFAULT true,
    ordem_exibicao INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_tipos_sabor_ativo ON tipos_sabor(ativo);
CREATE INDEX idx_tipos_sabor_ordem ON tipos_sabor(ordem_exibicao);
CREATE INDEX idx_tipos_sabor_slug ON tipos_sabor(slug);

-- ============================================================================
-- TABELA: sabores
-- ============================================================================
-- Cadastro global de sabores (podem ser usados em múltiplas categorias)
CREATE TABLE sabores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    descricao TEXT,
    imagem_url TEXT,
    tipo_id UUID REFERENCES tipos_sabor(id),
    premium BOOLEAN DEFAULT false,
    ativo BOOLEAN DEFAULT true, -- Controla se aparece no cardápio
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete: preserva histórico
    slug TEXT UNIQUE NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_sabores_ativo ON sabores(ativo);
CREATE INDEX idx_sabores_premium ON sabores(premium);
CREATE INDEX idx_sabores_slug ON sabores(slug);
CREATE INDEX idx_sabores_deleted_at ON sabores(deleted_at);
CREATE INDEX idx_sabores_tipo ON sabores(tipo_id);
CREATE INDEX idx_sabores_created_by ON sabores(created_by);
CREATE INDEX idx_sabores_updated_by ON sabores(updated_by);

-- ============================================================================
-- TABELA: categoria_sabores
-- ============================================================================
-- Relaciona sabores às categorias com preço específico por categoria
CREATE TABLE categoria_sabores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    categoria_id UUID NOT NULL REFERENCES categorias(id) ON DELETE CASCADE,
    sabor_id UUID NOT NULL REFERENCES sabores(id) ON DELETE CASCADE,
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    ordem_exibicao INTEGER DEFAULT 0,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação: um sabor não pode estar duas vezes na mesma categoria
    UNIQUE(categoria_id, sabor_id)
);

-- Índices para performance
CREATE INDEX idx_categoria_sabores_categoria ON categoria_sabores(categoria_id);
CREATE INDEX idx_categoria_sabores_sabor ON categoria_sabores(sabor_id);
CREATE INDEX idx_categoria_sabores_ativo ON categoria_sabores(ativo);

-- ============================================================================
-- TABELA: tipos_borda
-- ============================================================================
-- Define os tipos de bordas (Doce, Salgada, Especial, etc)
-- Permite regras de negócio e validações (ex: pizza salgada não aceita borda doce)
CREATE TABLE tipos_borda (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    ativo BOOLEAN DEFAULT true,
    ordem_exibicao INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_tipos_borda_ativo ON tipos_borda(ativo);
CREATE INDEX idx_tipos_borda_ordem ON tipos_borda(ordem_exibicao);
CREATE INDEX idx_tipos_borda_slug ON tipos_borda(slug);

-- ============================================================================
-- TABELA: bordas
-- ============================================================================
-- Cadastro global de bordas (podem ser usadas em múltiplas categorias)
CREATE TABLE bordas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    descricao TEXT,
    imagem_url TEXT,
    tipo_borda_id UUID REFERENCES tipos_borda(id),
    premium BOOLEAN DEFAULT false,
    ativo BOOLEAN DEFAULT true, -- Controla se aparece no cardápio
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete: preserva histórico
    slug TEXT UNIQUE NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_bordas_ativo ON bordas(ativo);
CREATE INDEX idx_bordas_premium ON bordas(premium);
CREATE INDEX idx_bordas_slug ON bordas(slug);
CREATE INDEX idx_bordas_deleted_at ON bordas(deleted_at);
CREATE INDEX idx_bordas_tipo ON bordas(tipo_borda_id);
CREATE INDEX idx_bordas_created_by ON bordas(created_by);
CREATE INDEX idx_bordas_updated_by ON bordas(updated_by);

-- ============================================================================
-- TABELA: categoria_bordas
-- ============================================================================
-- Relaciona bordas às categorias com preço específico por categoria
CREATE TABLE categoria_bordas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    categoria_id UUID NOT NULL REFERENCES categorias(id) ON DELETE CASCADE,
    borda_id UUID NOT NULL REFERENCES bordas(id) ON DELETE CASCADE,
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    ordem_exibicao INTEGER DEFAULT 0,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação: uma borda não pode estar duas vezes na mesma categoria
    UNIQUE(categoria_id, borda_id)
);

-- Índices para performance
CREATE INDEX idx_categoria_bordas_categoria ON categoria_bordas(categoria_id);
CREATE INDEX idx_categoria_bordas_borda ON categoria_bordas(borda_id);
CREATE INDEX idx_categoria_bordas_ativo ON categoria_bordas(ativo);

-- ============================================================================
-- TABELA: adicionais
-- ============================================================================
-- Cadastro global de adicionais (podem ser usados em múltiplas categorias)
CREATE TABLE adicionais (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    descricao TEXT,
    imagem_url TEXT,
    ativo BOOLEAN DEFAULT true, -- Controla se aparece no cardápio
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete: preserva histórico
    slug TEXT UNIQUE NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_adicionais_ativo ON adicionais(ativo);
CREATE INDEX idx_adicionais_slug ON adicionais(slug);
CREATE INDEX idx_adicionais_deleted_at ON adicionais(deleted_at);
CREATE INDEX idx_adicionais_created_by ON adicionais(created_by);
CREATE INDEX idx_adicionais_updated_by ON adicionais(updated_by);

-- ============================================================================
-- TABELA: categoria_adicionais
-- ============================================================================
-- Relaciona adicionais às categorias com preço específico por categoria
CREATE TABLE categoria_adicionais (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    categoria_id UUID NOT NULL REFERENCES categorias(id) ON DELETE CASCADE,
    adicional_id UUID NOT NULL REFERENCES adicionais(id) ON DELETE CASCADE,
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    ordem_exibicao INTEGER DEFAULT 0,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação: um adicional não pode estar duas vezes na mesma categoria
    UNIQUE(categoria_id, adicional_id)
);

-- Índices para performance
CREATE INDEX idx_categoria_adicionais_categoria ON categoria_adicionais(categoria_id);
CREATE INDEX idx_categoria_adicionais_adicional ON categoria_adicionais(adicional_id);
CREATE INDEX idx_categoria_adicionais_ativo ON categoria_adicionais(ativo);

-- ============================================================================
-- TABELA: tamanhos
-- ============================================================================
-- Define tamanhos/porções de produtos por categoria com precificação
-- Tamanho é uma label semântica (P, M, G, 100g, Família, etc)
-- Sistema não interpreta, apenas exibe, ordena e precifica
CREATE TABLE tamanhos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    categoria_id UUID NOT NULL REFERENCES categorias(id) ON DELETE CASCADE,
    nome TEXT NOT NULL, -- Ex: Fritas de Frango, Pizza Calabresa (nome comercial do item)
    tamanho_label TEXT NOT NULL, -- Ex: P, M, G, GG, 100g, 200g, Individual, Família
    valor NUMERIC(10, 2) NOT NULL CHECK (valor >= 0),
    valor_promocional NUMERIC(10, 2) CHECK (valor_promocional >= 0),
    ordem_exibicao INTEGER DEFAULT 0, -- Controla ordem manual no cardápio
    ativo BOOLEAN DEFAULT true, -- Controla se aparece no cardápio
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete: preserva histórico
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação: mesma categoria + nome + tamanho
    UNIQUE(categoria_id, nome, tamanho_label),
    
    -- Garante coerência: promoção não pode ser maior que preço normal
    CHECK (valor_promocional IS NULL OR valor_promocional <= valor)
);

-- Índices para performance
CREATE INDEX idx_tamanhos_categoria ON tamanhos(categoria_id);
CREATE INDEX idx_tamanhos_ativo ON tamanhos(ativo);
CREATE INDEX idx_tamanhos_deleted_at ON tamanhos(deleted_at);
CREATE INDEX idx_tamanhos_ordem ON tamanhos(ordem_exibicao);
CREATE INDEX idx_tamanhos_created_by ON tamanhos(created_by);
CREATE INDEX idx_tamanhos_updated_by ON tamanhos(updated_by);

-- ============================================================================
-- TRIGGERS PARA ATUALIZAR updated_at AUTOMATICAMENTE
-- ============================================================================

-- Função genérica para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em todas as tabelas
CREATE TRIGGER update_categorias_updated_at
    BEFORE UPDATE ON categorias
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categoria_configuracoes_updated_at
    BEFORE UPDATE ON categoria_configuracoes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tipos_sabor_updated_at
    BEFORE UPDATE ON tipos_sabor
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sabores_updated_at
    BEFORE UPDATE ON sabores
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tipos_borda_updated_at
    BEFORE UPDATE ON tipos_borda
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categoria_sabores_updated_at
    BEFORE UPDATE ON categoria_sabores
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bordas_updated_at
    BEFORE UPDATE ON bordas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categoria_bordas_updated_at
    BEFORE UPDATE ON categoria_bordas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_adicionais_updated_at
    BEFORE UPDATE ON adicionais
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categoria_adicionais_updated_at
    BEFORE UPDATE ON categoria_adicionais
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tamanhos_updated_at
    BEFORE UPDATE ON tamanhos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMENTÁRIOS NAS TABELAS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE categorias IS 'Categorias de produtos do delivery (ex: Pizzas, Bebidas, Sobremesas)';
COMMENT ON TABLE categoria_configuracoes IS 'Define quais recursos cada categoria permite (sabores, bordas, adicionais, tamanhos). Relação 1:1 com categorias';
COMMENT ON TABLE tipos_sabor IS 'Tipos de sabores (Doce, Salgado, Especial) para regras de negócio e filtros';
COMMENT ON TABLE sabores IS 'Cadastro global de sabores que podem ser vinculados a múltiplas categorias';
COMMENT ON TABLE categoria_sabores IS 'Relacionamento N:N entre categorias e sabores com preço específico';
COMMENT ON TABLE tipos_borda IS 'Tipos de bordas (Doce, Salgada, Especial) para regras de negócio e validações';
COMMENT ON TABLE bordas IS 'Cadastro global de bordas que podem ser vinculadas a múltiplas categorias';
COMMENT ON TABLE categoria_bordas IS 'Relacionamento N:N entre categorias e bordas com preço específico';
COMMENT ON TABLE adicionais IS 'Cadastro global de adicionais que podem ser vinculados a múltiplas categorias';
COMMENT ON TABLE categoria_adicionais IS 'Relacionamento N:N entre categorias e adicionais com preço específico';
COMMENT ON TABLE tamanhos IS 'Define tamanhos/porções de produtos por categoria. Tamanho é label semântica (P, M, G, 100g, Família) sem interpretação técnica';

-- ============================================================================
-- COMENTÁRIOS SOBRE SOFT DELETE
-- ============================================================================

COMMENT ON COLUMN sabores.ativo IS 'Controla se o sabor aparece no cardápio (true = visível, false = oculto)';
COMMENT ON COLUMN sabores.deleted_at IS 'Soft delete: preserva histórico de pedidos. NULL = ativo, timestamp = removido';
COMMENT ON COLUMN sabores.created_by IS 'Usuário que criou o registro (auditoria)';
COMMENT ON COLUMN sabores.updated_by IS 'Último usuário que editou o registro (auditoria)';
COMMENT ON COLUMN bordas.ativo IS 'Controla se a borda aparece no cardápio (true = visível, false = oculto)';
COMMENT ON COLUMN bordas.deleted_at IS 'Soft delete: preserva histórico de pedidos. NULL = ativo, timestamp = removido';
COMMENT ON COLUMN bordas.created_by IS 'Usuário que criou o registro (auditoria)';
COMMENT ON COLUMN bordas.updated_by IS 'Último usuário que editou o registro (auditoria)';
COMMENT ON COLUMN adicionais.ativo IS 'Controla se o adicional aparece no cardápio (true = visível, false = oculto)';
COMMENT ON COLUMN adicionais.deleted_at IS 'Soft delete: preserva histórico de pedidos. NULL = ativo, timestamp = removido';
COMMENT ON COLUMN adicionais.created_by IS 'Usuário que criou o registro (auditoria)';
COMMENT ON COLUMN adicionais.updated_by IS 'Último usuário que editou o registro (auditoria)';
COMMENT ON COLUMN tamanhos.nome IS 'Nome comercial do item/produto (ex: Fritas de Frango, Pizza Calabresa)';
COMMENT ON COLUMN tamanhos.tamanho_label IS 'Label semântica do tamanho (ex: P, M, G, 100g, Família) - não é interpretada pelo sistema';
COMMENT ON COLUMN tamanhos.valor IS 'Preço base do produto neste tamanho';
COMMENT ON COLUMN tamanhos.valor_promocional IS 'Preço promocional (opcional). Se preenchido, deve ser menor ou igual ao valor base';
COMMENT ON COLUMN tamanhos.ordem_exibicao IS 'Ordem manual de exibição no cardápio (evita ordenação alfabética incorreta)';
COMMENT ON COLUMN tamanhos.ativo IS 'Controla se o tamanho aparece no cardápio (true = visível, false = oculto)';
COMMENT ON COLUMN tamanhos.deleted_at IS 'Soft delete: preserva histórico de pedidos. NULL = ativo, timestamp = removido';
COMMENT ON COLUMN tamanhos.created_by IS 'Usuário que criou o registro (auditoria)';
COMMENT ON COLUMN tamanhos.updated_by IS 'Último usuário que editou o registro (auditoria)';

-- ============================================================================
-- DADOS INICIAIS: TIPOS DE SABOR
-- ============================================================================

INSERT INTO tipos_sabor (nome, slug, ordem_exibicao) VALUES
('Salgado', 'salgado', 1),
('Doce', 'doce', 2),
('Especial', 'especial', 3);

-- ============================================================================
-- DADOS INICIAIS: TIPOS DE BORDA
-- ============================================================================

INSERT INTO tipos_borda (nome, slug, ordem_exibicao) VALUES
('Salgada', 'salgada', 1),
('Doce', 'doce', 2),
('Especial', 'especial', 3);

-- ============================================================================
-- DADOS DE EXEMPLO (OPCIONAL - COMENTADO)
-- ============================================================================

/*
-- Exemplo de categoria
INSERT INTO categorias (nome, descricao, slug, ordem_exibicao, ativa)
VALUES ('Pizzas Tradicionais', 'Pizzas clássicas com massa tradicional', 'pizzas-tradicionais', 1, true);

-- Exemplo de configuração
INSERT INTO categoria_configuracoes (categoria_id, permite_sabores, permite_bordas, permite_adicionais, permite_tamanhos)
VALUES ((SELECT id FROM categorias WHERE slug = 'pizzas-tradicionais'), true, true, true, true);

-- Exemplo de sabor com tipo
INSERT INTO sabores (nome, descricao, slug, tipo_id, premium, ativo)
VALUES (
    'Calabresa', 
    'Calabresa fatiada, cebola e azeitonas', 
    'calabresa', 
    (SELECT id FROM tipos_sabor WHERE nome = 'Salgado'),
    false, 
    true
);

-- Exemplo de sabor doce
INSERT INTO sabores (nome, descricao, slug, tipo_id, premium, ativo)
VALUES (
    'Chocolate', 
    'Chocolate ao leite com granulado', 
    'chocolate', 
    (SELECT id FROM tipos_sabor WHERE nome = 'Doce'),
    false, 
    true
);

-- Exemplo de tamanhos para pizzas
INSERT INTO tamanhos (categoria_id, nome, tamanho_label, valor, ordem_exibicao)
VALUES 
    (
        (SELECT id FROM categorias WHERE slug = 'pizzas-tradicionais'),
        'Pizza Calabresa',
        'P',
        25.00,
        1
    ),
    (
        (SELECT id FROM categorias WHERE slug = 'pizzas-tradicionais'),
        'Pizza Calabresa',
        'M',
        35.00,
        2
    ),
    (
        (SELECT id FROM categorias WHERE slug = 'pizzas-tradicionais'),
        'Pizza Calabresa',
        'G',
        45.00,
        3
    ),
    (
        (SELECT id FROM categorias WHERE slug = 'pizzas-tradicionais'),
        'Pizza Calabresa',
        'GG',
        55.00,
        4
    );

-- Exemplo de relacionamento
INSERT INTO categoria_sabores (categoria_id, sabor_id, valor_adicional, ordem_exibicao)
VALUES (
    (SELECT id FROM categorias WHERE slug = 'pizzas-tradicionais'),
    (SELECT id FROM sabores WHERE slug = 'calabresa'),
    0.00,
    1
);

-- ============================================================================
-- EXEMPLOS DE USO: SOFT DELETE
-- ============================================================================

-- ❌ NUNCA FAÇA ISSO:
-- DELETE FROM sabores WHERE id = '...';

-- ✅ FAÇA ISSO (Soft Delete):
-- UPDATE sabores SET deleted_at = NOW() WHERE id = '...';

-- ✅ CONSULTA PADRÃO (apenas itens não deletados e ativos):
-- SELECT * FROM sabores WHERE deleted_at IS NULL AND ativo = true;

-- ✅ OCULTAR DO CARDÁPIO (mas manter no banco):
-- UPDATE sabores SET ativo = false WHERE id = '...';

-- ✅ RESTAURAR ITEM DELETADO:
-- UPDATE sabores SET deleted_at = NULL WHERE id = '...';
*/

-- ============================================================================
-- VIEWS ÚTEIS (OPCIONAL)
-- ============================================================================

-- View para sabores ativos (não deletados e visíveis no cardápio)
CREATE OR REPLACE VIEW sabores_ativos AS
SELECT * FROM sabores 
WHERE deleted_at IS NULL AND ativo = true;

-- View para bordas ativas
CREATE OR REPLACE VIEW bordas_ativas AS
SELECT * FROM bordas 
WHERE deleted_at IS NULL AND ativo = true;

-- View para adicionais ativos
CREATE OR REPLACE VIEW adicionais_ativos AS
SELECT * FROM adicionais 
WHERE deleted_at IS NULL AND ativo = true;

-- View para tamanhos ativos
CREATE OR REPLACE VIEW tamanhos_ativos AS
SELECT * FROM tamanhos 
WHERE deleted_at IS NULL AND ativo = true
ORDER BY categoria_id, ordem_exibicao;

-- View para tamanhos no cardápio com preço final calculado
CREATE OR REPLACE VIEW tamanhos_cardapio AS
SELECT *,
    COALESCE(valor_promocional, valor) AS valor_final
FROM tamanhos 
WHERE deleted_at IS NULL AND ativo = true
ORDER BY categoria_id, ordem_exibicao;

-- View para sabores por tipo (útil para filtros no frontend)
CREATE OR REPLACE VIEW sabores_por_tipo AS
SELECT 
    s.*,
    ts.nome AS tipo_nome,
    ts.ordem_exibicao AS tipo_ordem
FROM sabores s
LEFT JOIN tipos_sabor ts ON s.tipo_id = ts.id
WHERE s.deleted_at IS NULL AND s.ativo = true
ORDER BY ts.ordem_exibicao, s.nome;

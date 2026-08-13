-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - PRODUTOS
-- ============================================================================
-- Complementa o futuro_banco_sql.sql com a tabela de produtos
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
--   - Validação: Trigger validar_produto_categoria() garante essa regra
-- 
-- produto_tamanhos → Define PREÇO
--   - Exemplo: Pizza Calabresa tamanho G = R$ 45,00
--   - Cada produto pode ter múltiplos tamanhos com preços diferentes
-- 
-- produto_sabores_permitidos → Define QUAIS sabores são válidos
-- produto_bordas_permitidas → Define QUAIS bordas são válidas
-- produto_adicionais_permitidos → Define QUAIS adicionais são válidos
-- 
-- RESUMO: Categoria = máximo permitido | Produto = uso real | Tamanho = preço
-- ============================================================================

-- ============================================================================
-- TABELA: produtos
-- ============================================================================
-- Cadastro de produtos que pertencem a uma categoria
-- Produtos podem ter múltiplos tamanhos (via tabela tamanhos)
-- 
-- REGRA DE NEGÓCIO IMPORTANTE:
-- - Categoria define o MÁXIMO permitido (categoria_configuracoes)
-- - Produto define o USO REAL (campos abaixo)
-- - Exemplo: Se categoria permite_sabores = true, produto pode ter false
--            Se categoria permite_sabores = false, produto DEVE ter false
CREATE TABLE produtos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    categoria_id UUID NOT NULL REFERENCES categorias(id) ON DELETE RESTRICT,
    nome TEXT NOT NULL,
    descricao TEXT,
    imagem_url TEXT, -- Path no storage do Supabase
    slug TEXT UNIQUE NOT NULL,
    
    -- Controle de estoque
    controla_estoque BOOLEAN DEFAULT false,
    quantidade_estoque INTEGER DEFAULT 0 CHECK (quantidade_estoque >= 0),
    estoque_minimo INTEGER DEFAULT 0 CHECK (estoque_minimo >= 0),
    
    -- Configurações de sabores (para pizzas, esfihas, etc)
    permite_sabores BOOLEAN DEFAULT false,
    quantidade_sabores_min INTEGER DEFAULT 1 CHECK (quantidade_sabores_min >= 1),
    quantidade_sabores_max INTEGER DEFAULT 1 CHECK (quantidade_sabores_max >= 1),
    
    -- Configurações de adicionais
    permite_adicionais BOOLEAN DEFAULT false,
    
    -- Configurações de bordas (para pizzas)
    permite_bordas BOOLEAN DEFAULT false,
    
    -- Destaque e ordenação
    destaque BOOLEAN DEFAULT false,
    ordem_exibicao INTEGER DEFAULT 0,
    
    -- Status e auditoria
    ativo BOOLEAN DEFAULT true,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Validação: max deve ser >= min
    CHECK (quantidade_sabores_max >= quantidade_sabores_min)
);

-- Índices para performance
CREATE INDEX idx_produtos_categoria ON produtos(categoria_id);
CREATE INDEX idx_produtos_ativo ON produtos(ativo);
CREATE INDEX idx_produtos_deleted_at ON produtos(deleted_at);
CREATE INDEX idx_produtos_slug ON produtos(slug);
CREATE INDEX idx_produtos_destaque ON produtos(destaque);
CREATE INDEX idx_produtos_controla_estoque ON produtos(controla_estoque);

-- Índice composto para consultas de cardápio (performance otimizada)
CREATE INDEX idx_produtos_cardapio ON produtos(categoria_id, ativo, deleted_at);

-- ============================================================================
-- TABELA: produto_tamanhos
-- ============================================================================
-- Relaciona produtos com tamanhos e define preços específicos
-- Um produto pode ter múltiplos tamanhos (P, M, G, etc)
CREATE TABLE produto_tamanhos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    tamanho_id UUID NOT NULL REFERENCES tamanhos(id) ON DELETE RESTRICT,
    
    -- Preço específico para este produto neste tamanho
    valor NUMERIC(10, 2) NOT NULL CHECK (valor >= 0),
    valor_promocional NUMERIC(10, 2) CHECK (valor_promocional >= 0),
    
    -- Controle de estoque por tamanho (opcional)
    quantidade_estoque INTEGER CHECK (quantidade_estoque >= 0),
    
    ativo BOOLEAN DEFAULT true,
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete: preserva histórico
    ordem_exibicao INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação
    UNIQUE(produto_id, tamanho_id),
    
    -- Garante coerência de promoção
    CHECK (valor_promocional IS NULL OR valor_promocional <= valor)
);

-- Índices para performance
CREATE INDEX idx_produto_tamanhos_produto ON produto_tamanhos(produto_id);
CREATE INDEX idx_produto_tamanhos_tamanho ON produto_tamanhos(tamanho_id);
CREATE INDEX idx_produto_tamanhos_ativo ON produto_tamanhos(ativo);
CREATE INDEX idx_produto_tamanhos_deleted_at ON produto_tamanhos(deleted_at);

-- ============================================================================
-- TABELA: produto_sabores_permitidos
-- ============================================================================
-- Define quais sabores podem ser escolhidos para cada produto
-- Exemplo: Pizza Tradicional pode ter sabores X, Y, Z
CREATE TABLE produto_sabores_permitidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    sabor_id UUID NOT NULL REFERENCES sabores(id) ON DELETE RESTRICT,
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    ativo BOOLEAN DEFAULT true,
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete: preserva histórico
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação
    UNIQUE(produto_id, sabor_id)
);

-- Índices para performance
CREATE INDEX idx_produto_sabores_produto ON produto_sabores_permitidos(produto_id);
CREATE INDEX idx_produto_sabores_sabor ON produto_sabores_permitidos(sabor_id);
CREATE INDEX idx_produto_sabores_ativo ON produto_sabores_permitidos(ativo);
CREATE INDEX idx_produto_sabores_deleted_at ON produto_sabores_permitidos(deleted_at);

-- ============================================================================
-- TABELA: produto_bordas_permitidas
-- ============================================================================
-- Define quais bordas podem ser escolhidas para cada produto
CREATE TABLE produto_bordas_permitidas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    borda_id UUID NOT NULL REFERENCES bordas(id) ON DELETE RESTRICT,
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    ativo BOOLEAN DEFAULT true,
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete: preserva histórico
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação
    UNIQUE(produto_id, borda_id)
);

-- Índices para performance
CREATE INDEX idx_produto_bordas_produto ON produto_bordas_permitidas(produto_id);
CREATE INDEX idx_produto_bordas_borda ON produto_bordas_permitidas(borda_id);
CREATE INDEX idx_produto_bordas_ativo ON produto_bordas_permitidas(ativo);
CREATE INDEX idx_produto_bordas_deleted_at ON produto_bordas_permitidas(deleted_at);

-- ============================================================================
-- TABELA: produto_adicionais_permitidos
-- ============================================================================
-- Define quais adicionais podem ser escolhidos para cada produto
CREATE TABLE produto_adicionais_permitidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    adicional_id UUID NOT NULL REFERENCES adicionais(id) ON DELETE RESTRICT,
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    ativo BOOLEAN DEFAULT true,
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete: preserva histórico
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação
    UNIQUE(produto_id, adicional_id)
);

-- Índices para performance
CREATE INDEX idx_produto_adicionais_produto ON produto_adicionais_permitidos(produto_id);
CREATE INDEX idx_produto_adicionais_adicional ON produto_adicionais_permitidos(adicional_id);
CREATE INDEX idx_produto_adicionais_ativo ON produto_adicionais_permitidos(ativo);
CREATE INDEX idx_produto_adicionais_deleted_at ON produto_adicionais_permitidos(deleted_at);



-- ============================================================================
-- TRIGGERS PARA ATUALIZAR updated_at
-- ============================================================================

CREATE TRIGGER update_produtos_updated_at
    BEFORE UPDATE ON produtos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_produto_tamanhos_updated_at
    BEFORE UPDATE ON produto_tamanhos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER: Validação de categoria × produto
-- ============================================================================
-- Garante que produto não ativa recursos proibidos pela categoria

CREATE OR REPLACE FUNCTION validar_produto_categoria()
RETURNS TRIGGER AS $$
DECLARE
    v_config RECORD;
BEGIN
    -- Busca configurações da categoria
    SELECT 
        permite_sabores,
        permite_bordas,
        permite_adicionais
    INTO v_config
    FROM categoria_configuracoes
    WHERE categoria_id = NEW.categoria_id;
    
    -- Se não encontrou configuração, permite tudo (fallback seguro)
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;
    
    -- Valida sabores
    IF NEW.permite_sabores = true AND v_config.permite_sabores = false THEN
        RAISE EXCEPTION 'Produto não pode permitir sabores: categoria não permite sabores';
    END IF;
    
    -- Valida bordas
    IF NEW.permite_bordas = true AND v_config.permite_bordas = false THEN
        RAISE EXCEPTION 'Produto não pode permitir bordas: categoria não permite bordas';
    END IF;
    
    -- Valida adicionais
    IF NEW.permite_adicionais = true AND v_config.permite_adicionais = false THEN
        RAISE EXCEPTION 'Produto não pode permitir adicionais: categoria não permite adicionais';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplica trigger em INSERT e UPDATE
CREATE TRIGGER trigger_validar_produto_categoria
    BEFORE INSERT OR UPDATE ON produtos
    FOR EACH ROW
    EXECUTE FUNCTION validar_produto_categoria();



-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View de produtos ativos com informações da categoria
CREATE OR REPLACE VIEW produtos_cardapio AS
SELECT 
    p.*,
    c.nome AS categoria_nome,
    c.slug AS categoria_slug
FROM produtos p
INNER JOIN categorias c ON p.categoria_id = c.id
WHERE p.deleted_at IS NULL AND p.ativo = true
ORDER BY p.ordem_exibicao, p.nome;

-- View de produtos com estoque baixo
CREATE OR REPLACE VIEW produtos_estoque_baixo AS
SELECT 
    p.*,
    c.nome AS categoria_nome
FROM produtos p
INNER JOIN categorias c ON p.categoria_id = c.id
WHERE p.controla_estoque = true
  AND p.quantidade_estoque <= p.estoque_minimo
  AND p.deleted_at IS NULL
  AND p.ativo = true
ORDER BY p.quantidade_estoque;

-- View de produto_tamanhos com preço final calculado
CREATE OR REPLACE VIEW produto_tamanhos_cardapio AS
SELECT 
    pt.*,
    p.nome AS produto_nome,
    p.slug AS produto_slug,
    p.categoria_id,
    t.tamanho_label,
    t.nome AS tamanho_nome,
    COALESCE(pt.valor_promocional, pt.valor) AS valor_final,
    CASE 
        WHEN pt.valor_promocional IS NOT NULL THEN true 
        ELSE false 
    END AS em_promocao
FROM produto_tamanhos pt
INNER JOIN produtos p ON pt.produto_id = p.id
INNER JOIN tamanhos t ON pt.tamanho_id = t.id
WHERE pt.deleted_at IS NULL 
  AND pt.ativo = true
  AND p.deleted_at IS NULL 
  AND p.ativo = true
ORDER BY p.categoria_id, p.ordem_exibicao, pt.ordem_exibicao;



-- ============================================================================
-- COMENTÁRIOS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE produtos IS 'Cadastro de produtos do delivery vinculados a categorias';
COMMENT ON TABLE produto_tamanhos IS 'Relaciona produtos com tamanhos e define preços específicos';
COMMENT ON TABLE produto_sabores_permitidos IS 'Define quais sabores podem ser escolhidos para cada produto';
COMMENT ON TABLE produto_bordas_permitidas IS 'Define quais bordas podem ser escolhidas para cada produto';
COMMENT ON TABLE produto_adicionais_permitidos IS 'Define quais adicionais podem ser escolhidos para cada produto';

COMMENT ON VIEW produto_tamanhos_cardapio IS 'View otimizada para cardápio com preço final calculado (considera promoção automaticamente)';

COMMENT ON FUNCTION validar_produto_categoria IS 'Trigger que valida se produto respeita as permissões da categoria (hierarquia: categoria define máximo, produto define uso real)';

COMMENT ON COLUMN produtos.controla_estoque IS 'Define se o produto tem controle de estoque ativo';
COMMENT ON COLUMN produtos.quantidade_estoque IS 'Quantidade atual em estoque';
COMMENT ON COLUMN produtos.estoque_minimo IS 'Quantidade mínima para alerta de estoque baixo';
COMMENT ON COLUMN produtos.permite_sabores IS 'Define se o produto permite escolha de sabores. Deve respeitar categoria_configuracoes.permite_sabores';
COMMENT ON COLUMN produtos.quantidade_sabores_min IS 'Quantidade mínima de sabores que devem ser escolhidos';
COMMENT ON COLUMN produtos.quantidade_sabores_max IS 'Quantidade máxima de sabores que podem ser escolhidos';
COMMENT ON COLUMN produtos.permite_bordas IS 'Define se o produto permite escolha de bordas. Deve respeitar categoria_configuracoes.permite_bordas';
COMMENT ON COLUMN produtos.permite_adicionais IS 'Define se o produto permite escolha de adicionais. Deve respeitar categoria_configuracoes.permite_adicionais';

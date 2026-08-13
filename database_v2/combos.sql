-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - COMBOS
-- ============================================================================
-- Complementa futuro_banco_sql.sql e produtos_pedidos.sql
-- Sistema de combos/promoções com produtos agrupados
-- ============================================================================

-- ============================================================================
-- HIERARQUIA DE REGRAS - COMBOS
-- ============================================================================
-- 
-- combos → Define o combo (nome, preço, regras gerais)
--   - Exemplo: "Combo Família" com preço promocional
--   - Pode ter categoria própria (ex: "Promoções", "Combos")
-- 
-- combo_produtos → Define QUAIS produtos fazem parte do combo
--   - Exemplo: 2 pizzas G + 1 refrigerante 2L
--   - Cada produto tem quantidade e regras específicas
-- 
-- combo_produto_opcoes → Define OPÇÕES de escolha dentro do combo
--   - Exemplo: "Escolha 1 sabor entre: Calabresa, Mussarela, Portuguesa"
--   - Permite flexibilidade sem perder controle
-- 
-- RESUMO: Combo = pacote | combo_produtos = itens | combo_produto_opcoes = escolhas
-- 
-- ============================================================================
-- IMPORTANTE: PRECIFICAÇÃO E DESCONTO
-- ============================================================================
-- 
-- preco_combo → FONTE DE VERDADE (preço real cobrado do cliente)
-- preco_original → CACHE/MARKETING (valor de referência para exibição)
-- desconto_combo → CACHE/MARKETING (diferença calculada para exibição)
-- 
-- Regra: preco_combo é o único valor usado no pedido
-- Regra: preco_original e desconto_combo são para UX/marketing
-- Regra: Backend/Frontend podem recalcular esses valores dinamicamente
-- 
-- ============================================================================
-- IMPORTANTE: LIMITE DE ESCOLHAS (HIERARQUIA)
-- ============================================================================
-- 
-- combos.limite_escolhas → Limite GLOBAL do combo
--   - Exemplo: "Escolha até 3 personalizações no combo todo"
--   - Aplica-se ao combo inteiro, somando todas as escolhas
-- 
-- combo_produtos.limite_escolhas → Limite POR ITEM específico
--   - Exemplo: "Escolha até 2 sabores nesta pizza"
--   - Aplica-se apenas a este item do combo
-- 
-- Regra: Se ambos existem, o mais restritivo prevalece
-- Regra: Se apenas um existe, ele é usado
-- Regra: Se nenhum existe (0), não há limite
-- 
-- ============================================================================
-- IMPORTANTE: SABORES E ADICIONAIS PERMITIDOS (LÓGICA)
-- ============================================================================
-- 
-- permite_escolha_sabor = false
--   → Cliente NÃO pode escolher sabores
--   → Tabela combo_sabores_permitidos é IGNORADA
-- 
-- permite_escolha_sabor = true + combo_sabores_permitidos VAZIA
--   → Cliente pode escolher TODOS os sabores disponíveis
--   → Sem restrições
-- 
-- permite_escolha_sabor = true + combo_sabores_permitidos PREENCHIDA
--   → Cliente pode escolher SOMENTE os sabores listados na tabela
--   → Restrição aplicada
-- 
-- MESMA LÓGICA aplica-se para:
--   - permite_escolha_tamanho + tamanhos permitidos
--   - permite_troca_produto + combo_produto_opcoes
--   - adicionais (via combo_adicionais_permitidos)
-- 
-- ============================================================================

-- ============================================================================
-- TABELA: combos
-- ============================================================================
-- Cadastro de combos/promoções que agrupam produtos
CREATE TABLE combos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    categoria_id UUID REFERENCES categorias(id) ON DELETE RESTRICT,
    nome TEXT NOT NULL,
    descricao TEXT,
    imagem_url TEXT, -- Path no storage do Supabase
    slug TEXT UNIQUE NOT NULL,
    
    -- Precificação
    preco_combo NUMERIC(10, 2) NOT NULL CHECK (preco_combo >= 0),
    preco_original NUMERIC(10, 2) CHECK (preco_original >= 0), -- Valor de referência (soma dos produtos)
    desconto_combo NUMERIC(10, 2) CHECK (desconto_combo >= 0), -- Pode ser calculado, mas útil manter
    
    -- Regras do combo
    permite_troca_produto BOOLEAN DEFAULT false, -- Ex: trocar refrigerante por suco
    permite_escolha_sabor BOOLEAN DEFAULT false, -- Ex: escolher sabores das pizzas
    permite_escolha_tamanho BOOLEAN DEFAULT false, -- Ex: escolher tamanho das pizzas
    limite_escolhas INTEGER DEFAULT 0, -- Quantidade máxima de escolhas permitidas
    
    -- Validade da promoção (opcional)
    valido_de TIMESTAMP WITH TIME ZONE,
    valido_ate TIMESTAMP WITH TIME ZONE,
    
    -- Destaque e ordenação
    destaque BOOLEAN DEFAULT false,
    ordem_exibicao INTEGER DEFAULT 0,
    
    -- Status e auditoria
    ativo BOOLEAN DEFAULT true,
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete: preserva histórico
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Validação: desconto não pode ser maior que a diferença
    CHECK (desconto_combo IS NULL OR preco_original IS NULL OR desconto_combo <= (preco_original - preco_combo))
);

-- Índices para performance
CREATE INDEX idx_combos_categoria ON combos(categoria_id);
CREATE INDEX idx_combos_ativo ON combos(ativo);
CREATE INDEX idx_combos_deleted_at ON combos(deleted_at);
CREATE INDEX idx_combos_slug ON combos(slug);
CREATE INDEX idx_combos_destaque ON combos(destaque);
CREATE INDEX idx_combos_validade ON combos(valido_de, valido_ate);

-- Índice composto para consultas de cardápio
CREATE INDEX idx_combos_cardapio ON combos(categoria_id, ativo, deleted_at);

-- ============================================================================
-- TABELA: combo_produtos
-- ============================================================================
-- Define quais produtos fazem parte de cada combo e suas quantidades
-- Exemplo: Combo Família = 2 pizzas G + 1 refrigerante 2L + 1 sobremesa
CREATE TABLE combo_produtos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    combo_id UUID NOT NULL REFERENCES combos(id) ON DELETE CASCADE,
    produto_id UUID REFERENCES produtos(id) ON DELETE RESTRICT,
    
    -- Quantidade e regras
    quantidade INTEGER NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    obrigatorio BOOLEAN DEFAULT true, -- Se false, cliente pode remover este item
    permite_troca BOOLEAN DEFAULT false, -- Se true, cliente pode trocar por outro produto
    
    -- Tamanho específico (opcional)
    tamanho_id UUID REFERENCES tamanhos(id) ON DELETE RESTRICT,
    tamanho_fixo BOOLEAN DEFAULT false, -- Se true, não permite trocar tamanho
    
    -- Valor adicional se cliente quiser trocar/adicionar
    valor_adicional_troca NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional_troca >= 0),
    
    -- Limite de escolhas para este item específico (opcional)
    -- Exemplo: "Escolha até 2 sabores" ou "Escolha 1 refrigerante entre 3 opções"
    limite_escolhas INTEGER DEFAULT 0,
    
    -- Ordenação e status
    ordem_exibicao INTEGER DEFAULT 0,
    ativo BOOLEAN DEFAULT true,
    deleted_at TIMESTAMP WITH TIME ZONE, -- Soft delete
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_combo_produtos_combo ON combo_produtos(combo_id);
CREATE INDEX idx_combo_produtos_produto ON combo_produtos(produto_id);
CREATE INDEX idx_combo_produtos_tamanho ON combo_produtos(tamanho_id);
CREATE INDEX idx_combo_produtos_ativo ON combo_produtos(ativo);
CREATE INDEX idx_combo_produtos_deleted_at ON combo_produtos(deleted_at);

-- ============================================================================
-- TABELA: combo_produto_opcoes
-- ============================================================================
-- Define opções de escolha dentro de um item do combo
-- Exemplo: "Escolha 1 sabor entre: Calabresa, Mussarela, Portuguesa"
-- Exemplo: "Escolha 1 refrigerante entre: Coca-Cola, Guaraná, Fanta"
CREATE TABLE combo_produto_opcoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    combo_produto_id UUID NOT NULL REFERENCES combo_produtos(id) ON DELETE CASCADE,
    produto_opcao_id UUID NOT NULL REFERENCES produtos(id) ON DELETE RESTRICT,
    
    -- Valor adicional se esta opção for mais cara
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    
    -- Status
    ativo BOOLEAN DEFAULT true,
    ordem_exibicao INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação
    UNIQUE(combo_produto_id, produto_opcao_id)
);

-- Índices para performance
CREATE INDEX idx_combo_produto_opcoes_combo_produto ON combo_produto_opcoes(combo_produto_id);
CREATE INDEX idx_combo_produto_opcoes_produto ON combo_produto_opcoes(produto_opcao_id);
CREATE INDEX idx_combo_produto_opcoes_ativo ON combo_produto_opcoes(ativo);

-- ============================================================================
-- TABELA: combo_sabores_permitidos
-- ============================================================================
-- Define quais sabores podem ser escolhidos nos produtos do combo
-- Útil quando combo permite escolha de sabor mas com restrições
CREATE TABLE combo_sabores_permitidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    combo_id UUID NOT NULL REFERENCES combos(id) ON DELETE CASCADE,
    sabor_id UUID NOT NULL REFERENCES sabores(id) ON DELETE RESTRICT,
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação
    UNIQUE(combo_id, sabor_id)
);

-- Índices para performance
CREATE INDEX idx_combo_sabores_combo ON combo_sabores_permitidos(combo_id);
CREATE INDEX idx_combo_sabores_sabor ON combo_sabores_permitidos(sabor_id);
CREATE INDEX idx_combo_sabores_ativo ON combo_sabores_permitidos(ativo);

-- ============================================================================
-- TABELA: combo_adicionais_permitidos (ROADMAP FUTURO)
-- ============================================================================
-- Define quais adicionais podem ser escolhidos nos produtos do combo
-- Útil quando combo permite adicionais mas com restrições ou preços especiais
-- Segue o mesmo padrão de produto_adicionais_permitidos e combo_sabores_permitidos
CREATE TABLE combo_adicionais_permitidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    combo_id UUID NOT NULL REFERENCES combos(id) ON DELETE CASCADE,
    adicional_id UUID NOT NULL REFERENCES adicionais(id) ON DELETE RESTRICT,
    valor_adicional NUMERIC(10, 2) DEFAULT 0.00 CHECK (valor_adicional >= 0),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação
    UNIQUE(combo_id, adicional_id)
);

-- Índices para performance
CREATE INDEX idx_combo_adicionais_combo ON combo_adicionais_permitidos(combo_id);
CREATE INDEX idx_combo_adicionais_adicional ON combo_adicionais_permitidos(adicional_id);
CREATE INDEX idx_combo_adicionais_ativo ON combo_adicionais_permitidos(ativo);

-- ============================================================================
-- TRIGGERS PARA ATUALIZAR updated_at
-- ============================================================================

CREATE TRIGGER update_combos_updated_at
    BEFORE UPDATE ON combos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_combo_produtos_updated_at
    BEFORE UPDATE ON combo_produtos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER: Validação de validade do combo
-- ============================================================================
-- Garante que data de início não seja maior que data de fim

CREATE OR REPLACE FUNCTION validar_validade_combo()
RETURNS TRIGGER AS $$
BEGIN
    -- Valida datas de validade
    IF NEW.valido_de IS NOT NULL AND NEW.valido_ate IS NOT NULL THEN
        IF NEW.valido_de > NEW.valido_ate THEN
            RAISE EXCEPTION 'Data de início não pode ser maior que data de fim';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_validade_combo
    BEFORE INSERT OR UPDATE ON combos
    FOR EACH ROW
    EXECUTE FUNCTION validar_validade_combo();

-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View de combos ativos no cardápio
CREATE OR REPLACE VIEW combos_cardapio AS
SELECT 
    c.*,
    cat.nome AS categoria_nome,
    cat.slug AS categoria_slug,
    CASE 
        WHEN c.valido_de IS NOT NULL AND c.valido_ate IS NOT NULL THEN
            NOW() BETWEEN c.valido_de AND c.valido_ate
        WHEN c.valido_de IS NOT NULL THEN
            NOW() >= c.valido_de
        WHEN c.valido_ate IS NOT NULL THEN
            NOW() <= c.valido_ate
        ELSE true
    END AS combo_valido
FROM combos c
LEFT JOIN categorias cat ON c.categoria_id = cat.id
WHERE c.deleted_at IS NULL 
  AND c.ativo = true
ORDER BY c.ordem_exibicao, c.nome;

-- View de combos com contagem de produtos
CREATE OR REPLACE VIEW combos_resumo AS
SELECT 
    c.*,
    COUNT(cp.id) AS total_produtos,
    SUM(cp.quantidade) AS total_itens
FROM combos c
LEFT JOIN combo_produtos cp ON c.id = cp.combo_id AND cp.deleted_at IS NULL AND cp.ativo = true
WHERE c.deleted_at IS NULL
GROUP BY c.id
ORDER BY c.ordem_exibicao, c.nome;

-- View de combos válidos (dentro do período de validade)
CREATE OR REPLACE VIEW combos_validos AS
SELECT * FROM combos
WHERE deleted_at IS NULL 
  AND ativo = true
  AND (
    (valido_de IS NULL AND valido_ate IS NULL) OR
    (valido_de IS NOT NULL AND valido_ate IS NOT NULL AND NOW() BETWEEN valido_de AND valido_ate) OR
    (valido_de IS NOT NULL AND valido_ate IS NULL AND NOW() >= valido_de) OR
    (valido_de IS NULL AND valido_ate IS NOT NULL AND NOW() <= valido_ate)
  )
ORDER BY ordem_exibicao, nome;

-- View detalhada de combo com produtos
CREATE OR REPLACE VIEW combos_detalhado AS
SELECT 
    c.id AS combo_id,
    c.nome AS combo_nome,
    c.preco_combo,
    c.preco_original,
    c.desconto_combo,
    cp.id AS combo_produto_id,
    cp.quantidade,
    cp.obrigatorio,
    cp.permite_troca,
    p.id AS produto_id,
    p.nome AS produto_nome,
    p.slug AS produto_slug,
    t.id AS tamanho_id,
    t.tamanho_label,
    cp.valor_adicional_troca
FROM combos c
INNER JOIN combo_produtos cp ON c.id = cp.combo_id
LEFT JOIN produtos p ON cp.produto_id = p.id
LEFT JOIN tamanhos t ON cp.tamanho_id = t.id
WHERE c.deleted_at IS NULL 
  AND c.ativo = true
  AND cp.deleted_at IS NULL 
  AND cp.ativo = true
ORDER BY c.ordem_exibicao, cp.ordem_exibicao;

-- ============================================================================
-- COMENTÁRIOS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE combos IS 'Cadastro de combos/promoções que agrupam produtos com preço especial';
COMMENT ON TABLE combo_produtos IS 'Define quais produtos fazem parte de cada combo com quantidades e regras';
COMMENT ON TABLE combo_produto_opcoes IS 'Define opções de escolha dentro de um item do combo (ex: escolher entre 3 sabores)';
COMMENT ON TABLE combo_sabores_permitidos IS 'Define quais sabores podem ser escolhidos nos produtos do combo (quando há restrição)';
COMMENT ON TABLE combo_adicionais_permitidos IS 'Define quais adicionais podem ser escolhidos nos produtos do combo (quando há restrição ou preço especial)';

COMMENT ON COLUMN combos.preco_combo IS 'Preço promocional do combo (FONTE DE VERDADE - usado no pedido)';
COMMENT ON COLUMN combos.preco_original IS 'Valor de referência para marketing (soma dos produtos individuais) - CACHE/EXIBIÇÃO';
COMMENT ON COLUMN combos.desconto_combo IS 'Valor do desconto para marketing (diferença entre original e combo) - CACHE/EXIBIÇÃO';
COMMENT ON COLUMN combos.permite_troca_produto IS 'Define se cliente pode trocar produtos do combo (ver combo_produto_opcoes para opções disponíveis)';
COMMENT ON COLUMN combos.permite_escolha_sabor IS 'Define se cliente pode escolher sabores. Se true + combo_sabores_permitidos vazia = todos sabores. Se true + tabela preenchida = apenas listados';
COMMENT ON COLUMN combos.permite_escolha_tamanho IS 'Define se cliente pode escolher tamanhos nos produtos do combo';
COMMENT ON COLUMN combos.limite_escolhas IS 'Quantidade máxima de escolhas/personalizações permitidas NO COMBO TODO (limite global)';
COMMENT ON COLUMN combos.valido_de IS 'Data/hora de início da validade do combo (NULL = sem limite)';
COMMENT ON COLUMN combos.valido_ate IS 'Data/hora de fim da validade do combo (NULL = sem limite)';
COMMENT ON COLUMN combos.ativo IS 'Controla se o combo aparece no cardápio (true = visível, false = oculto)';
COMMENT ON COLUMN combos.deleted_at IS 'Soft delete: preserva histórico de pedidos. NULL = ativo, timestamp = removido';

COMMENT ON COLUMN combo_produtos.quantidade IS 'Quantidade deste produto no combo';
COMMENT ON COLUMN combo_produtos.obrigatorio IS 'Se false, cliente pode remover este item do combo';
COMMENT ON COLUMN combo_produtos.permite_troca IS 'Se true, cliente pode trocar por outro produto (ver combo_produto_opcoes)';
COMMENT ON COLUMN combo_produtos.tamanho_fixo IS 'Se true, não permite trocar o tamanho do produto';
COMMENT ON COLUMN combo_produtos.valor_adicional_troca IS 'Valor adicional cobrado se cliente trocar este item';
COMMENT ON COLUMN combo_produtos.limite_escolhas IS 'Quantidade máxima de escolhas PARA ESTE ITEM específico (ex: escolha até 2 sabores nesta pizza). Se 0, sem limite no item';

COMMENT ON COLUMN combo_produto_opcoes.valor_adicional IS 'Valor adicional se esta opção for mais cara que a padrão';

COMMENT ON COLUMN combo_sabores_permitidos.valor_adicional IS 'Valor adicional se este sabor for premium ou especial no contexto do combo';
COMMENT ON COLUMN combo_adicionais_permitidos.valor_adicional IS 'Valor adicional se este adicional tiver preço especial no contexto do combo';

COMMENT ON VIEW combos_cardapio IS 'View otimizada para exibição de combos no cardápio com validação de período';
COMMENT ON VIEW combos_resumo IS 'View com contagem de produtos por combo';
COMMENT ON VIEW combos_validos IS 'View com apenas combos dentro do período de validade';
COMMENT ON VIEW combos_detalhado IS 'View completa com combo e todos os produtos relacionados';

-- ============================================================================
-- DADOS DE EXEMPLO (OPCIONAL - COMENTADO)
-- ============================================================================

/*
-- Exemplo de combo
INSERT INTO combos (nome, descricao, slug, preco_combo, preco_original, desconto_combo, permite_escolha_sabor, ativo)
VALUES (
    'Combo Família',
    '2 Pizzas Grandes + 1 Refrigerante 2L + 1 Sobremesa',
    'combo-familia',
    89.90,
    120.00,
    30.10,
    true,
    true
);

-- Exemplo de produtos do combo
INSERT INTO combo_produtos (combo_id, produto_id, quantidade, tamanho_id, obrigatorio, permite_troca)
VALUES 
    (
        (SELECT id FROM combos WHERE slug = 'combo-familia'),
        (SELECT id FROM produtos WHERE slug = 'pizza-tradicional'),
        2,
        (SELECT id FROM tamanhos WHERE tamanho_label = 'G'),
        true,
        false
    ),
    (
        (SELECT id FROM combos WHERE slug = 'combo-familia'),
        (SELECT id FROM produtos WHERE slug = 'refrigerante'),
        1,
        (SELECT id FROM tamanhos WHERE tamanho_label = '2L'),
        true,
        true
    );

-- Exemplo de opções de escolha
INSERT INTO combo_produto_opcoes (combo_produto_id, produto_opcao_id, valor_adicional)
VALUES 
    (
        (SELECT id FROM combo_produtos WHERE combo_id = (SELECT id FROM combos WHERE slug = 'combo-familia') LIMIT 1),
        (SELECT id FROM produtos WHERE slug = 'coca-cola'),
        0.00
    ),
    (
        (SELECT id FROM combo_produtos WHERE combo_id = (SELECT id FROM combos WHERE slug = 'combo-familia') LIMIT 1),
        (SELECT id FROM produtos WHERE slug = 'guarana'),
        0.00
    );
*/

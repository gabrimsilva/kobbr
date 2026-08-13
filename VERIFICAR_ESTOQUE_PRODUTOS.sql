-- ============================================================================
-- VERIFICAR ESTOQUE E PRODUTOS
-- ============================================================================

-- Ver todos os produtos
SELECT 
    id,
    nome,
    ativo,
    requires_stock,
    stock_item_id
FROM produtos
ORDER BY criado_em DESC;

-- Ver todos os itens de estoque
SELECT 
    id,
    product_id,
    nome,
    quantidade,
    ativo,
    criado_em
FROM stock_items
ORDER BY criado_em DESC;

-- Ver produtos COM estoque criado
SELECT 
    p.id as produto_id,
    p.nome as produto_nome,
    p.requires_stock,
    p.stock_item_id,
    s.id as estoque_id,
    s.quantidade,
    s.ativo as estoque_ativo
FROM produtos p
LEFT JOIN stock_items s ON s.product_id = p.id
WHERE p.ativo = true
ORDER BY p.criado_em DESC;

-- ============================================================================
-- EXECUTAR ESTAS QUERIES NO SUPABASE SQL EDITOR
-- ============================================================================

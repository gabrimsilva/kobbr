-- ============================================================================
-- DEBUG: Por que está aparecendo quantidade 100?
-- ============================================================================

-- Ver o produto criado
SELECT 
    id,
    nome,
    ativo,
    requires_stock,
    stock_item_id,
    criado_em
FROM produtos
WHERE nome ILIKE '%pão%queijo%'
ORDER BY criado_em DESC
LIMIT 5;

-- Ver o estoque desse produto
SELECT 
    s.id,
    s.product_id,
    s.nome,
    s.quantidade,
    s.ativo,
    s.criado_em,
    p.nome as produto_nome
FROM stock_items s
LEFT JOIN produtos p ON p.id = s.product_id
WHERE s.nome ILIKE '%pão%queijo%'
   OR p.nome ILIKE '%pão%queijo%'
ORDER BY s.criado_em DESC
LIMIT 5;

-- Ver TODOS os stock_items
SELECT 
    s.id,
    s.product_id,
    s.nome,
    s.quantidade,
    s.ativo,
    s.criado_em
FROM stock_items s
ORDER BY s.criado_em DESC;

-- ============================================================================
-- EXECUTAR NO SUPABASE SQL EDITOR
-- ============================================================================

-- ============================================
-- VERIFICAR DADOS DE ESTOQUE
-- ============================================

-- 1. Verificar se existem produtos
SELECT COUNT(*) as total_produtos FROM produtos WHERE ativo = true;

-- 2. Verificar se existem stock_items
SELECT COUNT(*) as total_stock_items FROM stock_items WHERE active = true;

-- 3. Ver produtos SEM stock_item
SELECT 
  p.id,
  p.nome,
  p.preco,
  'SEM ESTOQUE CONFIGURADO' as status
FROM produtos p
LEFT JOIN stock_items si ON si.product_id = p.id
WHERE p.ativo = true
  AND si.id IS NULL
ORDER BY p.nome;

-- 4. Ver produtos COM stock_item
SELECT 
  p.nome as produto,
  si.total_qty as estoque_atual,
  si.min_qty as estoque_minimo,
  si.reorder_qty as qtd_reposicao,
  CASE 
    WHEN si.min_qty = 0 THEN '🟢 HEALTHY'
    WHEN si.total_qty <= si.min_qty THEN '🔴 CRITICAL'
    WHEN si.total_qty <= si.min_qty * 1.3 THEN '🟡 WARNING'
    ELSE '🟢 HEALTHY'
  END as status
FROM stock_items si
JOIN produtos p ON p.id = si.product_id
WHERE si.active = true
ORDER BY 
  CASE 
    WHEN si.min_qty = 0 THEN 3
    WHEN si.total_qty <= si.min_qty THEN 1
    WHEN si.total_qty <= si.min_qty * 1.3 THEN 2
    ELSE 3
  END,
  p.nome;


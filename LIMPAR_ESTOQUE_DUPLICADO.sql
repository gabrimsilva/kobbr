-- ============================================================================
-- LIMPAR ESTOQUES DUPLICADOS E PREVENIR NOVAS DUPLICAÇÕES
-- ============================================================================
-- Contexto: produtos com requires_stock=true estavam gerando 2 stock_items
-- (um pelo trigger do banco + um pelo frontend). O frontend já foi corrigido
-- para ser idempotente. Este script limpa os duplicados existentes e adiciona
-- a constraint UNIQUE em product_id para impedir o problema no banco.
-- Rode no SQL Editor do Supabase.
-- ============================================================================

-- 1. Conferir duplicados antes de remover
SELECT product_id, COUNT(*) AS qtd
FROM stock_items
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY qtd DESC;

-- 2. Remover duplicados, mantendo o estoque mais ANTIGO (menor criado_em).
--    A maior quantidade é preservada no registro mantido para não perder saldo.
WITH ranked AS (
  SELECT
    id,
    product_id,
    ROW_NUMBER() OVER (
      PARTITION BY product_id
      ORDER BY criado_em ASC, id ASC
    ) AS rn,
    MAX(quantidade) OVER (PARTITION BY product_id) AS max_qtd
  FROM stock_items
)
-- Atualiza o registro mantido com a maior quantidade encontrada entre os duplicados
UPDATE stock_items s
SET quantidade = r.max_qtd
FROM ranked r
WHERE s.id = r.id
  AND r.rn = 1;

-- Apaga os duplicados (todos exceto o primeiro de cada produto)
WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY product_id
      ORDER BY criado_em ASC, id ASC
    ) AS rn
  FROM stock_items
)
DELETE FROM stock_items
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- 3. Religar produtos.stock_item_id ao estoque remanescente
UPDATE produtos p
SET stock_item_id = s.id
FROM stock_items s
WHERE s.product_id = p.id
  AND (p.stock_item_id IS DISTINCT FROM s.id);

-- 4. Garantir UNIQUE em product_id para impedir duplicação no banco
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'stock_items'::regclass
      AND contype = 'u'
      AND conname = 'stock_items_product_id_unique'
  ) THEN
    ALTER TABLE stock_items
      ADD CONSTRAINT stock_items_product_id_unique UNIQUE (product_id);
  END IF;
END $$;

-- 5. Verificar resultado (não deve haver mais duplicados)
SELECT product_id, COUNT(*) AS qtd
FROM stock_items
GROUP BY product_id
HAVING COUNT(*) > 1;

-- ============================================================================
-- Script: Limpar Duplicatas de Stock Items
-- Descrição: Remove duplicatas de stock_items mantendo apenas o mais antigo ativo
-- Data: 4 de Agosto de 2026
-- ============================================================================

-- 1. VERIFICAR duplicatas existentes
SELECT 
  product_id,
  COUNT(*) as total_stocks,
  COUNT(CASE WHEN ativo = true THEN 1 END) as ativos,
  COUNT(CASE WHEN ativo = false THEN 1 END) as inativos,
  ARRAY_AGG(id) as ids,
  ARRAY_AGG(criado_em ORDER BY criado_em) as datas_criacao
FROM stock_items
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY total_stocks DESC;

-- ============================================================================
-- Se encontrou duplicatas, executar o script de limpeza abaixo:
-- ============================================================================

-- 2. DESATIVAR todos os stock_items duplicados (manter apenas o primeiro)
WITH duplicatas AS (
  SELECT 
    product_id,
    id,
    ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY criado_em ASC) as rn
  FROM stock_items
)
UPDATE stock_items
SET ativo = false
WHERE id IN (
  SELECT id FROM duplicatas WHERE rn > 1
);

-- 3. VERIFICAR se limpeza funcionou
SELECT 
  product_id,
  COUNT(*) as total_stocks,
  COUNT(CASE WHEN ativo = true THEN 1 END) as ativos,
  COUNT(CASE WHEN ativo = false THEN 1 END) as inativos
FROM stock_items
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY total_stocks DESC;

-- Se retornar 0 linhas, está tudo certo! ✓

-- ============================================================================
-- Alternativa: Se quiser DELETAR fisicamente os duplicados (não recomendado)
-- ============================================================================

-- BACKUP antes de deletar:
-- CREATE TABLE stock_items_backup AS SELECT * FROM stock_items;

-- WITH duplicatas AS (
--   SELECT 
--     product_id,
--     id,
--     ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY criado_em ASC) as rn
--   FROM stock_items
-- )
-- DELETE FROM stock_items
-- WHERE id IN (
--   SELECT id FROM duplicatas WHERE rn > 1
-- );

-- ============================================================================
-- Verificar integridade após limpeza
-- ============================================================================

-- Produtos sem stock_item ativo (devem ter ativo = false)
SELECT 
  p.id,
  p.nome,
  COUNT(si.id) as stocks,
  MAX(si.ativo) as tem_ativo
FROM produtos p
LEFT JOIN stock_items si ON p.id = si.product_id
WHERE p.requires_stock = true
GROUP BY p.id, p.nome
HAVING COUNT(si.id) = 0 OR MAX(si.ativo) = false
ORDER BY p.nome;

-- ============================================================================
-- Log de limpeza
-- ============================================================================

-- Quantos produtos tiveram duplicatas limpas?
-- (Executar DEPOIS da limpeza)
SELECT 
  COUNT(DISTINCT product_id) as produtos_com_duplicatas_limpas,
  COUNT(*) as total_duplicatas_desativadas
FROM stock_items
WHERE ativo = false
  AND criado_em::date = CURRENT_DATE;

-- ============================================================================
-- Notas:
-- - Os stock_items duplicados foram DESATIVADOS (não deletados)
-- - Isso preserva histórico e referências em outras tabelas
-- - Para cada produto com estoque, haverá 1 ativo e N inativos
-- - O código agora (produtoService.ts) evita novas duplicatas
-- ============================================================================

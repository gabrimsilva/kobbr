-- ============================================================================
-- CORRIGIR CASCADE DELETE PARA PERMITIR EXCLUSÃO DE PRODUTOS
-- ============================================================================

-- Remover constraint antiga de stock_items.product_id
ALTER TABLE stock_items 
DROP CONSTRAINT IF EXISTS stock_items_product_id_fkey;

-- Adicionar constraint com ON DELETE CASCADE
ALTER TABLE stock_items 
ADD CONSTRAINT stock_items_product_id_fkey 
FOREIGN KEY (product_id) 
REFERENCES produtos(id) 
ON DELETE CASCADE;

-- Remover constraint antiga de produtos.stock_item_id
ALTER TABLE produtos 
DROP CONSTRAINT IF EXISTS produtos_stock_item_id_fkey;

-- Adicionar constraint com ON DELETE SET NULL
-- (quando o stock_item for deletado, apenas limpa a referência no produto)
ALTER TABLE produtos 
ADD CONSTRAINT produtos_stock_item_id_fkey 
FOREIGN KEY (stock_item_id) 
REFERENCES stock_items(id) 
ON DELETE SET NULL;

-- ============================================================================
-- PRONTO! Agora você pode excluir produtos sem erro
-- Quando excluir um produto, o item de estoque vinculado será excluído também
-- ============================================================================

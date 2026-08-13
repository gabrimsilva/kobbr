-- ============================================================================
-- ADICIONAR COLUNA PRODUCT_ID NA TABELA STOCK_ITEMS
-- ============================================================================

-- Adicionar coluna product_id para relacionar com produtos
ALTER TABLE public.stock_items 
ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES public.produtos(id);

-- ============================================================================
-- PRONTO! Coluna product_id adicionada
-- ============================================================================

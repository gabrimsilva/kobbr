-- ============================================================================
-- ADICIONAR COLUNA ATIVO NA TABELA STOCK_ITEMS
-- ============================================================================

-- Adicionar coluna ativo se não existir
ALTER TABLE public.stock_items 
ADD COLUMN IF NOT EXISTS ativo BOOLEAN DEFAULT true;

-- ============================================================================
-- PRONTO! Coluna ativo adicionada
-- ============================================================================

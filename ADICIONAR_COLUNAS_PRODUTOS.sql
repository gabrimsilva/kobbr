-- ============================================================================
-- ADICIONAR COLUNAS FALTANTES NA TABELA PRODUTOS
-- ============================================================================

-- Adicionar coluna requires_stock
ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS requires_stock BOOLEAN DEFAULT false;

-- Adicionar outras colunas que podem estar faltando
ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS codigo_barras VARCHAR;

ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS stock_item_id UUID REFERENCES public.stock_items(id);

-- ============================================================================
-- PRONTO! Colunas adicionadas na tabela produtos
-- ============================================================================

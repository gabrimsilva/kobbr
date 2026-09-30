-- Preço do produto nos pedidos online (catálogo), separado do preço do PDV.
-- null = o catálogo usa o preço do PDV (ou o promocional).
ALTER TABLE public.produtos
  ADD COLUMN IF NOT EXISTS preco_online numeric(10,2)
    CHECK (preco_online IS NULL OR preco_online > 0);

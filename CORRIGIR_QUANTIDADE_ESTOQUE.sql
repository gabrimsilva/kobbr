-- ============================================================================
-- CORRIGIR QUANTIDADE DO ESTOQUE
-- ============================================================================

-- Atualizar a quantidade para 0 (zero)
UPDATE stock_items 
SET quantidade = 0
WHERE id = 'fbcea188-3362-414f-9f29-56933fabc51b';

-- Verificar se foi atualizado
SELECT 
    id,
    product_id,
    nome,
    quantidade,
    ativo,
    criado_em
FROM stock_items
WHERE id = 'fbcea188-3362-414f-9f29-56933fabc51b';

-- ============================================================================
-- TAMBÉM: Verificar o valor padrão da coluna quantidade
-- ============================================================================

SELECT 
    column_name,
    column_default,
    data_type
FROM information_schema.columns
WHERE table_name = 'stock_items'
  AND column_name = 'quantidade';

-- Se o padrão não for 0, corrigir:
ALTER TABLE stock_items 
ALTER COLUMN quantidade SET DEFAULT 0;

-- ============================================================================
-- PRONTO! Execute este SQL no Supabase
-- ============================================================================

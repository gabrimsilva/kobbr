-- ============================================================================
-- ATUALIZAÇÃO SIMPLES E DIRETA
-- ============================================================================

-- Apenas atualizar a quantidade para 0
UPDATE stock_items 
SET quantidade = 0
WHERE nome = 'pão de queijo';

-- Verificar o resultado
SELECT 
    id,
    product_id,
    nome,
    quantidade,
    ativo,
    criado_em
FROM stock_items
WHERE nome = 'pão de queijo';

-- ============================================================================
-- EXECUTAR NO SUPABASE SQL EDITOR
-- ============================================================================

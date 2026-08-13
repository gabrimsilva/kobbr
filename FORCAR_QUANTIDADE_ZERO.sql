-- ============================================================================
-- FORÇAR QUANTIDADE PARA ZERO
-- ============================================================================

-- Atualizar TODOS os stock_items para quantidade 0
UPDATE stock_items 
SET quantidade = 0;

-- Verificar se foi atualizado
SELECT 
    id,
    product_id,
    nome,
    quantidade,
    ativo
FROM stock_items;

-- ============================================================================
-- Se ainda não funcionar, pode ser um problema de tipo de dados
-- Vamos verificar o tipo da coluna
-- ============================================================================

SELECT 
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'stock_items'
  AND column_name = 'quantidade';

-- ============================================================================
-- ALTERNATIVA: Recriar a tabela do zero
-- ============================================================================

-- Salvar os product_ids antes de deletar
CREATE TEMP TABLE temp_products AS
SELECT DISTINCT product_id, nome
FROM stock_items;

-- Deletar todos os registros
DELETE FROM stock_items;

-- Recriar com quantidade 0
INSERT INTO stock_items (product_id, nome, descricao, quantidade, ativo)
SELECT 
    product_id,
    nome,
    'Estoque de ' || nome,
    0,
    true
FROM temp_products;

-- Verificar resultado
SELECT * FROM stock_items;

-- ============================================================================
-- EXECUTAR NO SUPABASE SQL EDITOR
-- ============================================================================

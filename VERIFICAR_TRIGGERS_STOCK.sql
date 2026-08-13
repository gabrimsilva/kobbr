-- ============================================================================
-- VERIFICAR TRIGGERS E FUNÇÕES NA TABELA STOCK_ITEMS
-- ============================================================================

-- Ver todos os triggers na tabela stock_items
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'stock_items';

-- Ver todas as funções relacionadas a stock
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines
WHERE routine_name LIKE '%stock%'
   OR routine_name LIKE '%estoque%';

-- Ver constraints da tabela
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'stock_items'::regclass;

-- ============================================================================
-- EXECUTAR NO SUPABASE SQL EDITOR
-- ============================================================================

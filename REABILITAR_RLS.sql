-- ============================================================================
-- REABILITAR RLS
-- ============================================================================

-- Reabilitar RLS na tabela pedidos
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;

-- Verificar se foi reabilitado
SELECT 
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'pedidos';

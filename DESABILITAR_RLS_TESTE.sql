-- ============================================================================
-- DESABILITAR RLS TEMPORARIAMENTE PARA TESTE
-- ============================================================================
-- ATENÇÃO: Use apenas para teste! Reabilite depois!
-- ============================================================================

-- Desabilitar RLS na tabela pedidos
ALTER TABLE public.pedidos DISABLE ROW LEVEL SECURITY;

-- Verificar se foi desabilitado
SELECT 
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'pedidos';

-- DEPOIS DE TESTAR, REABILITE COM:
-- ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- DESABILITAR RLS TEMPORARIAMENTE - PARA TESTE
-- ============================================================================
-- ATENÇÃO: Isso remove a segurança! Use apenas para testar!
-- ============================================================================

-- Desabilitar RLS nas tabelas essenciais
ALTER TABLE public.configuracoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PRONTO! RLS desabilitado. O sistema deve funcionar agora.
-- Depois que confirmar que funciona, podemos reabilitar com políticas corretas.
-- ============================================================================

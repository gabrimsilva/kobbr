-- ============================================================================
-- CORRIGIR POLÍTICAS RLS - CASA DO PAI
-- Remove políticas duplicadas e recria corretamente
-- ============================================================================

-- Remover políticas antigas se existirem
DROP POLICY IF EXISTS "Permitir tudo para autenticados" ON public.configuracoes;
DROP POLICY IF EXISTS "Permitir tudo para autenticados" ON public.categorias;
DROP POLICY IF EXISTS "Permitir tudo para autenticados" ON public.produtos;
DROP POLICY IF EXISTS "Permitir tudo para autenticados" ON public.clientes;
DROP POLICY IF EXISTS "Permitir tudo para autenticados" ON public.pedidos;

-- Criar políticas com nomes únicos
CREATE POLICY "configuracoes_all" ON public.configuracoes 
FOR ALL TO authenticated 
USING (true) 
WITH CHECK (true);

CREATE POLICY "categorias_all" ON public.categorias 
FOR ALL TO authenticated 
USING (true) 
WITH CHECK (true);

CREATE POLICY "produtos_all" ON public.produtos 
FOR ALL TO authenticated 
USING (true) 
WITH CHECK (true);

CREATE POLICY "clientes_all" ON public.clientes 
FOR ALL TO authenticated 
USING (true) 
WITH CHECK (true);

CREATE POLICY "pedidos_all" ON public.pedidos 
FOR ALL TO authenticated 
USING (true) 
WITH CHECK (true);

-- ============================================================================
-- PRONTO! Políticas RLS corrigidas
-- ============================================================================

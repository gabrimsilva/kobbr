-- ============================================================================
-- MULTI-ESTABELECIMENTO: RLS DOS FLUXOS PÚBLICOS POR SLUG
-- ============================================================================
-- Arquivo: 14_rls_publico_slug.sql
-- Descrição: Refina as políticas anônimas (papel `anon`) introduzidas
--            temporariamente em 12_tenant_not_null_e_rls.sql para os fluxos
--            públicos por slug. Os inserts públicos passam a EXIGIR que o
--            estabelecimento_id informado pertença a um estabelecimento ATIVO,
--            evitando que o site público grave dados em estabelecimento
--            inexistente/inativo. As leituras anônimas do catálogo permanecem
--            abertas (o frontend filtra pelo slug); poderiam ser ainda mais
--            restritas se o catálogo precisar ser privado por prédio.
-- Ordem de execução: APÓS 12_tenant_not_null_e_rls.sql.
-- Requisitos: 5.2, 5.3, 5.7, 11.x (fluxos públicos por slug)
-- Data: 21/01/2026
-- ============================================================================
-- NOTA: o cliente público usa a chave `anon` e não possui sessão de usuário,
-- portanto não há auth.uid() para derivar o estabelecimento. O slug da URL
-- resolve o estabelecimento no frontend, que injeta estabelecimento_id nos
-- inserts. Esta política valida, no banco, que esse id é de um estabelecimento
-- ativo (defesa adicional contra inserts forjados).
-- ============================================================================

-- Função auxiliar: verdadeiro se o id é de um estabelecimento ativo.
CREATE OR REPLACE FUNCTION public.fn_estabelecimento_ativo(p_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.estabelecimentos e
        WHERE e.id = p_id AND e.ativo = true
    );
$$;

COMMENT ON FUNCTION public.fn_estabelecimento_ativo(UUID) IS
    'True se o estabelecimento informado existe e está ativo. Usada nas políticas anônimas dos fluxos públicos por slug.';

-- ----------------------------------------------------------------------------
-- pedidos — insert público exige estabelecimento ativo
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "pedidos_insert_publico" ON public.pedidos;
CREATE POLICY "pedidos_insert_publico" ON public.pedidos
    FOR INSERT TO anon
    WITH CHECK (public.fn_estabelecimento_ativo(estabelecimento_id));

-- ----------------------------------------------------------------------------
-- clientes — insert público exige estabelecimento ativo
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "clientes_insert_publico" ON public.clientes;
CREATE POLICY "clientes_insert_publico" ON public.clientes
    FOR INSERT TO anon
    WITH CHECK (public.fn_estabelecimento_ativo(estabelecimento_id));

-- ----------------------------------------------------------------------------
-- avaliacoes — insert público exige estabelecimento ativo;
-- leitura pública continua restrita a aprovadas (frontend filtra por slug).
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "avaliacoes_insert_publico" ON public.avaliacoes;
CREATE POLICY "avaliacoes_insert_publico" ON public.avaliacoes
    FOR INSERT TO anon
    WITH CHECK (public.fn_estabelecimento_ativo(estabelecimento_id));

-- ----------------------------------------------------------------------------
-- (Opcional) Acompanhamento público de pedido por código:
-- Se o fluxo /:slug exibir status de pedido ao cliente, habilite leitura anônima
-- escopada por estabelecimento ativo. Mantido comentado por padrão.
-- ----------------------------------------------------------------------------
-- DROP POLICY IF EXISTS "pedidos_select_publico" ON public.pedidos;
-- CREATE POLICY "pedidos_select_publico" ON public.pedidos
--     FOR SELECT TO anon
--     USING (public.fn_estabelecimento_ativo(estabelecimento_id));

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================

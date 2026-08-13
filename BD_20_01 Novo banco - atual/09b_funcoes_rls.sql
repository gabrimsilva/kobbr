-- ============================================================================
-- MULTI-ESTABELECIMENTO: FUNÇÕES DE APOIO À RLS + POLÍTICAS DAS TABELAS BASE
-- ============================================================================
-- Arquivo: 09b_funcoes_rls.sql
-- Descrição: Define as funções SECURITY DEFINER que derivam a autorização
--            multi-tenant a partir de auth.uid() (sem JWT claims nem set_config)
--            e habilita o Row Level Security (RLS) das três tabelas base
--            (estabelecimentos, usuarios_estabelecimento, logs_auditoria).
-- Ordem de execução: APÓS 09_estabelecimentos.sql (depende das tabelas base)
--                    e ANTES das políticas RLS por tenant das Tabelas_de_Dominio
--                    (12_tenant_not_null_e_rls.sql / tarefa 4.2).
-- Requisitos: 5.5, 5.6, 1.6, 2.8, 2.9, 9.6
-- Data: 20/01/2026
-- ============================================================================
-- NOTA DE SEGURANÇA:
--   As funções abaixo usam SECURITY DEFINER para consultar
--   usuarios_estabelecimento de DENTRO das políticas RLS sem causar recursão
--   (a tabela protegida por RLS é consultada por uma função que roda com os
--   privilégios do dono). O search_path é FIXO em "public" para evitar ataques
--   de search_path e garantir resolução determinística dos objetos.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Função: fn_is_admin_geral()
-- Retorna true quando o usuário autenticado é um administrador_geral ativo.
-- (Req 5.5)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_is_admin_geral()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.usuarios_estabelecimento ue
        WHERE ue.user_id = auth.uid()
          AND ue.ativo = true
          AND ue.perfil = 'administrador_geral'
    );
$$;

COMMENT ON FUNCTION public.fn_is_admin_geral() IS
    'SECURITY DEFINER: true se o usuário autenticado (auth.uid()) for administrador_geral ativo. '
    'Usada nas políticas RLS para conceder acesso global. search_path fixo evita recursão de RLS '
    'e ataques de search_path (Req 5.5, 5.6).';

-- ----------------------------------------------------------------------------
-- Função: fn_is_admin_estabelecimento()
-- Função de apoio: retorna true quando o usuário autenticado é um
-- administrador_estabelecimento ativo. Necessária para que as políticas das
-- tabelas de gestão (usuarios_estabelecimento, logs_auditoria) distingam um
-- administrador de estabelecimento de um operador, mantendo o operador sem
-- acesso de gestão (Req 2.8, 2.9, 9.5/9.8) sem recorrer a subconsultas
-- recursivas sobre a própria tabela protegida por RLS.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_is_admin_estabelecimento()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.usuarios_estabelecimento ue
        WHERE ue.user_id = auth.uid()
          AND ue.ativo = true
          AND ue.perfil = 'administrador_estabelecimento'
    );
$$;

COMMENT ON FUNCTION public.fn_is_admin_estabelecimento() IS
    'SECURITY DEFINER: true se o usuário autenticado for administrador_estabelecimento ativo. '
    'Apoia as políticas de gestão para excluir operadores do acesso de gestão (Req 2.9). '
    'search_path fixo evita recursão de RLS e ataques de search_path.';

-- ----------------------------------------------------------------------------
-- Função: fn_estabelecimentos_do_usuario()
-- Retorna o conjunto de identificadores de estabelecimentos que o usuário
-- autenticado pode acessar: TODOS quando administrador_geral; caso contrário,
-- apenas o estabelecimento vinculado ao usuário ativo. (Req 5.5, 5.6)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_estabelecimentos_do_usuario()
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT e.id
    FROM public.estabelecimentos e
    WHERE public.fn_is_admin_geral()              -- admin geral vê todos
       OR e.id = (
            SELECT ue.estabelecimento_id
            FROM public.usuarios_estabelecimento ue
            WHERE ue.user_id = auth.uid()
              AND ue.ativo = true
       );
$$;

COMMENT ON FUNCTION public.fn_estabelecimentos_do_usuario() IS
    'SECURITY DEFINER: conjunto de estabelecimento_id que o usuário autenticado pode acessar — '
    'todos os estabelecimentos quando administrador_geral, senão apenas o estabelecimento vinculado '
    'ao usuário ativo. Base das políticas RLS por tenant. search_path fixo evita recursão de RLS '
    'e ataques de search_path (Req 5.5, 5.6).';

-- ============================================================================
-- POLÍTICAS RLS — estabelecimentos (Req 1.6, 5.5)
-- ============================================================================
-- Leitura: qualquer usuário autenticado cujo estabelecimento esteja autorizado
--          (administrador_geral enxerga todos, demais apenas o vinculado).
-- Escrita (INSERT/UPDATE/DELETE): exclusivamente administrador_geral (Req 1.6).
-- ----------------------------------------------------------------------------
ALTER TABLE public.estabelecimentos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "estabelecimentos_select" ON public.estabelecimentos;
CREATE POLICY "estabelecimentos_select" ON public.estabelecimentos
    FOR SELECT TO authenticated
    USING (
        public.fn_is_admin_geral()
        OR id IN (SELECT public.fn_estabelecimentos_do_usuario())
    );

DROP POLICY IF EXISTS "estabelecimentos_insert" ON public.estabelecimentos;
CREATE POLICY "estabelecimentos_insert" ON public.estabelecimentos
    FOR INSERT TO authenticated
    WITH CHECK (public.fn_is_admin_geral());

DROP POLICY IF EXISTS "estabelecimentos_update" ON public.estabelecimentos;
CREATE POLICY "estabelecimentos_update" ON public.estabelecimentos
    FOR UPDATE TO authenticated
    USING (public.fn_is_admin_geral())
    WITH CHECK (public.fn_is_admin_geral());

DROP POLICY IF EXISTS "estabelecimentos_delete" ON public.estabelecimentos;
CREATE POLICY "estabelecimentos_delete" ON public.estabelecimentos
    FOR DELETE TO authenticated
    USING (public.fn_is_admin_geral());

-- ============================================================================
-- POLÍTICAS RLS — usuarios_estabelecimento (Req 2.8, 2.9)
-- ============================================================================
-- SELECT: o próprio usuário sempre lê o seu registro (necessário ao contexto
--         do frontend); administrador_geral lê todos; administrador_estabelecimento
--         lê os usuários do(s) seu(s) estabelecimento(s). Operador só vê a si mesmo.
-- Gestão (INSERT/UPDATE/DELETE): administrador_geral (todos) e
--         administrador_estabelecimento (apenas do próprio estabelecimento).
--         Operador NÃO tem acesso de gestão (Req 2.9). Apenas administrador_geral
--         pode atribuir/alterar para o perfil administrador_geral (Req 2.8).
-- ----------------------------------------------------------------------------
ALTER TABLE public.usuarios_estabelecimento ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "usuarios_estab_select" ON public.usuarios_estabelecimento;
CREATE POLICY "usuarios_estab_select" ON public.usuarios_estabelecimento
    FOR SELECT TO authenticated
    USING (
        user_id = (SELECT auth.uid())
        OR public.fn_is_admin_geral()
        OR (
            public.fn_is_admin_estabelecimento()
            AND estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario())
        )
    );

DROP POLICY IF EXISTS "usuarios_estab_insert" ON public.usuarios_estabelecimento;
CREATE POLICY "usuarios_estab_insert" ON public.usuarios_estabelecimento
    FOR INSERT TO authenticated
    WITH CHECK (
        (
            public.fn_is_admin_geral()
            OR (
                public.fn_is_admin_estabelecimento()
                AND estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario())
            )
        )
        -- Somente administrador_geral pode conceder o perfil administrador_geral (Req 2.8)
        AND (perfil <> 'administrador_geral' OR public.fn_is_admin_geral())
    );

DROP POLICY IF EXISTS "usuarios_estab_update" ON public.usuarios_estabelecimento;
CREATE POLICY "usuarios_estab_update" ON public.usuarios_estabelecimento
    FOR UPDATE TO authenticated
    USING (
        public.fn_is_admin_geral()
        OR (
            public.fn_is_admin_estabelecimento()
            AND estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario())
        )
    )
    WITH CHECK (
        (
            public.fn_is_admin_geral()
            OR (
                public.fn_is_admin_estabelecimento()
                AND estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario())
            )
        )
        AND (perfil <> 'administrador_geral' OR public.fn_is_admin_geral())
    );

DROP POLICY IF EXISTS "usuarios_estab_delete" ON public.usuarios_estabelecimento;
CREATE POLICY "usuarios_estab_delete" ON public.usuarios_estabelecimento
    FOR DELETE TO authenticated
    USING (
        public.fn_is_admin_geral()
        OR (
            public.fn_is_admin_estabelecimento()
            AND estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario())
        )
    );

-- ============================================================================
-- POLÍTICAS RLS — logs_auditoria (Req 9.6 — imutável/append-only)
-- ============================================================================
-- SELECT: administrador_geral (estabelecimentos autorizados = todos) e
--         administrador_estabelecimento (apenas do próprio estabelecimento).
--         Operador não consulta auditoria (Req 9.8).
-- INSERT: permitido a qualquer usuário autenticado (registro de ação).
-- SEM política de UPDATE e SEM política de DELETE: com RLS habilitado e sem
--         política permissiva, toda tentativa de UPDATE/DELETE é negada,
--         tornando os registros imutáveis e append-only (Req 9.6, Property 11).
-- ----------------------------------------------------------------------------
ALTER TABLE public.logs_auditoria ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "logs_auditoria_select" ON public.logs_auditoria;
CREATE POLICY "logs_auditoria_select" ON public.logs_auditoria
    FOR SELECT TO authenticated
    USING (
        public.fn_is_admin_geral()
        OR (
            public.fn_is_admin_estabelecimento()
            AND estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario())
        )
    );

DROP POLICY IF EXISTS "logs_auditoria_insert" ON public.logs_auditoria;
CREATE POLICY "logs_auditoria_insert" ON public.logs_auditoria
    FOR INSERT TO authenticated
    WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

-- Intencionalmente NÃO há políticas de UPDATE/DELETE para logs_auditoria:
-- a ausência de política permissiva sob RLS habilitado garante a imutabilidade
-- e o comportamento append-only exigido pelo Req 9.6.

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================

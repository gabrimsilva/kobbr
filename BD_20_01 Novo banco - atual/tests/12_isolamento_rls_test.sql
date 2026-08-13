-- ============================================================================
-- TESTE DE ISOLAMENTO RLS POR TENANT (cross-tenant)
-- ============================================================================
-- Arquivo: tests/12_isolamento_rls_test.sql
-- Cobre: Tarefa 4.4 da spec multi-estabelecimento
-- Valida: Property 1 (sem vazamento), Property 2 (escrita confinada),
--         Property 4 (RLS independe do frontend).
-- Requisitos: 5.3, 5.4, 5.6, 5.7
-- Tipo: Teste SQL de RLS — executar em banco Supabase (Postgres) de TESTE.
-- ============================================================================
--
-- PRÉ-REQUISITOS (executar antes, na ordem):
--   03_tables.sql, 03b_tables_stock_sales.sql, 09_estabelecimentos.sql,
--   09b_funcoes_rls.sql, 10_tenant_columns.sql, 10b_configuracoes_unique.sql,
--   11_migracao_dados.sql, 12_tenant_not_null_e_rls.sql
--
-- COMO RODAR:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f tests/12_isolamento_rls_test.sql
--   (ou cole no Supabase SQL Editor). Sucesso => NOTICE final "[OK] ...".
--
-- ESTRATÉGIA:
--   Simula auth.uid() via set_config('request.jwt.claims', ...) e o papel via
--   set_config('role', 'authenticated', true). Cria 2 estabelecimentos (A,B) e
--   um operador vinculado ao A. Verifica que, autenticado como operador_A:
--     - SELECT em produtos só retorna linhas do A (Property 1);
--     - INSERT em produtos com estabelecimento_id = B é bloqueado (Property 2);
--     - INSERT com estabelecimento_id = A é permitido;
--     - mesmo SEM filtro no SELECT, B nunca aparece (Property 4).
--   Tudo dentro de BEGIN ... ROLLBACK (não persiste fixtures).
-- ============================================================================

BEGIN;

-- Fixtures de usuários auth
INSERT INTO auth.users (instance_id, id, aud, role, email)
VALUES
    ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-0000000a0a0a', 'authenticated', 'authenticated', 'op_a@test.local')
ON CONFLICT (id) DO NOTHING;

-- Estabelecimentos A e B
INSERT INTO public.estabelecimentos (id, nome, slug, cor_tema, ativo) VALUES
    ('00000000-0000-0000-0000-0000000000a1', 'TEST A', 'test-a', '#2563EB', true),
    ('00000000-0000-0000-0000-0000000000b1', 'TEST B', 'test-b', '#16A34A', true);

-- Operador vinculado ao A
INSERT INTO public.usuarios_estabelecimento (user_id, nome, email, perfil, estabelecimento_id, ativo)
VALUES ('00000000-0000-0000-0000-0000000a0a0a', 'Op A', 'op_a@test.local', 'operador',
        '00000000-0000-0000-0000-0000000000a1', true);

-- Produtos em A e B (inseridos como superusuário, antes de simular o papel)
INSERT INTO public.produtos (id, nome, preco, ativo, estabelecimento_id) VALUES
    ('00000000-0000-0000-0000-0000000a0001', 'Produto A', 10, true, '00000000-0000-0000-0000-0000000000a1'),
    ('00000000-0000-0000-0000-0000000b0001', 'Produto B', 20, true, '00000000-0000-0000-0000-0000000000b1');

-- ----------------------------------------------------------------------------
-- Simular sessão autenticada do operador_A
-- ----------------------------------------------------------------------------
SELECT set_config('request.jwt.claims',
    json_build_object('sub','00000000-0000-0000-0000-0000000a0a0a','role','authenticated')::text, true);
SELECT set_config('role', 'authenticated', true);

DO $$
DECLARE
    v_count INTEGER;
    v_erro_capturado BOOLEAN := false;
BEGIN
    -- Property 1: SELECT sem filtro só vê produtos do A
    SELECT count(*) INTO v_count FROM public.produtos;
    ASSERT v_count = 1, format('Property 1 FALHOU: operador_A deveria ver 1 produto (do A), viu %s', v_count);
    ASSERT EXISTS (SELECT 1 FROM public.produtos WHERE id = '00000000-0000-0000-0000-0000000a0001'),
        'Property 1 FALHOU: produto do A deveria ser visível';
    ASSERT NOT EXISTS (SELECT 1 FROM public.produtos WHERE id = '00000000-0000-0000-0000-0000000b0001'),
        'Property 1/4 FALHOU: produto do B NÃO deveria ser visível (vazamento entre tenants)';
    RAISE NOTICE '[OK] Property 1/4: SELECT escopado ao estabelecimento A.';

    -- Property 2: INSERT com estabelecimento_id de B deve ser bloqueado pela RLS
    BEGIN
        INSERT INTO public.produtos (nome, preco, ativo, estabelecimento_id)
        VALUES ('Intruso em B', 5, true, '00000000-0000-0000-0000-0000000000b1');
    EXCEPTION WHEN insufficient_privilege OR check_violation THEN
        v_erro_capturado := true;
    END;
    ASSERT v_erro_capturado,
        'Property 2 FALHOU: INSERT em produtos com estabelecimento_id do B deveria ser negado pela RLS';
    RAISE NOTICE '[OK] Property 2: INSERT cross-tenant (B) bloqueado.';

    -- INSERT no próprio estabelecimento (A) é permitido
    INSERT INTO public.produtos (nome, preco, ativo, estabelecimento_id)
    VALUES ('Novo em A', 7, true, '00000000-0000-0000-0000-0000000000a1');
    SELECT count(*) INTO v_count FROM public.produtos;
    ASSERT v_count = 2, format('FALHOU: após inserir no A, operador_A deveria ver 2 produtos, viu %s', v_count);
    RAISE NOTICE '[OK] INSERT no próprio estabelecimento (A) permitido.';

    RAISE NOTICE '[OK] TODOS OS TESTES DE ISOLAMENTO RLS PASSARAM';
END $$;

-- Restaura papel e desfaz tudo
SELECT set_config('role', 'postgres', true);
ROLLBACK;
-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================

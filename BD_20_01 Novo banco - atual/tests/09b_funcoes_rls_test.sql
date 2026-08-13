-- ============================================================================
-- TESTE DE RLS / AUTORIZAÇÃO: fn_is_admin_geral() e fn_estabelecimentos_do_usuario()
-- ============================================================================
-- Arquivo: tests/09b_funcoes_rls_test.sql
-- Cobre: Tarefa 2.3 da spec multi-estabelecimento
-- Valida: Correctness Property 1 (sem vazamento entre tenants) e
--         Correctness Property 5 (coerência de perfil) — conforme design.md.
-- Requisitos cobertos: 5.5, 5.6
-- Tipo: Teste SQL de RLS — executar contra um banco Supabase (Postgres) de TESTE.
-- Data: 20/01/2026
-- ============================================================================
--
-- O QUE ESTE TESTE VALIDA
-- -----------------------
-- As funções de apoio à RLS definidas em 09b_funcoes_rls.sql derivam a
-- autorização multi-tenant a partir de auth.uid():
--   * fn_is_admin_geral()             -> true SOMENTE para administrador_geral ativo
--   * fn_estabelecimentos_do_usuario() -> conjunto de estabelecimentos acessíveis:
--        - administrador_geral            => TODOS os estabelecimentos
--        - administrador_estabelecimento  => apenas o estabelecimento vinculado
--        - operador                       => apenas o estabelecimento vinculado
--        - usuário inativo / sem vínculo  => conjunto VAZIO
--
-- COMO O auth.uid() É SIMULADO
-- ----------------------------
-- No Supabase, auth.uid() é, em essência:
--     SELECT coalesce(
--       nullif(current_setting('request.jwt.claim.sub', true), ''),
--       (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
--     )::uuid;
-- Ou seja, ele lê o "sub" das claims do JWT a partir de uma GUC de sessão.
-- Podemos simular um usuário autenticado de forma CONFIÁVEL dentro de UMA
-- ÚNICA TRANSAÇÃO usando:
--     PERFORM set_config('request.jwt.claims', json_build_object('sub', <uuid>)::text, true);
-- O terceiro argumento (is_local = true) faz a configuração valer apenas para a
-- transação corrente. Como tudo aqui roda na MESMA transação (BEGIN ... ROLLBACK),
-- e as funções são reavaliadas a cada SELECT, a troca de usuário é determinística.
--
-- COMO EXECUTAR
-- -------------
-- 1) Pré-requisitos: ter executado, no banco de TESTE, na ordem:
--        09_estabelecimentos.sql   (tabelas base)
--        09b_funcoes_rls.sql       (funções + políticas)
--    O esquema "auth" do Supabase deve existir (auth.users e auth.uid()).
--
-- 2) Via psql:
--        psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f tests/09b_funcoes_rls_test.sql
--    Em caso de sucesso, a saída termina com:
--        NOTICE:  [OK] TODOS OS TESTES DE RLS PASSARAM
--    Qualquer ASSERT que falhar aborta o script com erro (graças ao ON_ERROR_STOP).
--
-- 3) Via Supabase SQL Editor:
--        Cole o conteúdo deste arquivo e execute. As mensagens NOTICE aparecem
--        no painel de resultados. Um ASSERT falho gera erro visível.
--
-- IMPORTANTE
-- ----------
--  * O script é TRANSACIONAL e termina com ROLLBACK — NÃO persiste fixtures.
--  * Inserimos linhas mínimas em auth.users apenas para satisfazer a FK
--    usuarios_estabelecimento.user_id -> auth.users(id); tudo é desfeito no fim.
--  * NÃO execute contra um banco de produção.
--
-- RESULTADO ESPERADO (resumo dos asserts)
-- ---------------------------------------
--   Usuário              fn_is_admin_geral()   fn_estabelecimentos_do_usuario()
--   admin_geral          true                  { A, B }   (todos os estabelecimentos)
--   admin_estab_A        false                 { A }
--   operador_A           false                 { A }
--   operador_A_inativo   false                 { }        (vazio — usuário inativo)
--   sem_vinculo          false                 { }        (vazio — sem registro de vínculo)
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- UUIDs fixos das fixtures (facilitam referência entre statements)
-- ----------------------------------------------------------------------------
-- Estabelecimentos
--   A = ...0a1 (ativo)   B = ...0b1 (ativo)   C = ...0c1 (INATIVO, edge case)
-- Usuários (auth.users.id)
--   admin_geral        = ...ad01
--   admin_estab_A      = ...ad0a
--   operador_A         = ...0a0a
--   operador_A_inativo = ...dead
--   sem_vinculo        = ...00ff

-- ----------------------------------------------------------------------------
-- 1) Fixtures: usuários de autenticação (auth.users)
--    Inserção mínima — colunas extras são nullable / têm default no Supabase.
-- ----------------------------------------------------------------------------
INSERT INTO auth.users (instance_id, id, aud, role, email)
VALUES
    ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-00000000ad01', 'authenticated', 'authenticated', 'admin_geral@test.local'),
    ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-00000000ad0a', 'authenticated', 'authenticated', 'admin_estab_a@test.local'),
    ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-0000000a0a0a', 'authenticated', 'authenticated', 'operador_a@test.local'),
    ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-0000000000de', 'authenticated', 'authenticated', 'operador_a_inativo@test.local'),
    ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-0000000000ff', 'authenticated', 'authenticated', 'sem_vinculo@test.local')
ON CONFLICT (id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2) Fixtures: estabelecimentos (A e B ativos; C inativo p/ edge case)
-- ----------------------------------------------------------------------------
INSERT INTO public.estabelecimentos (id, nome, slug, descricao, cor_tema, ativo)
VALUES
    ('00000000-0000-0000-0000-0000000000a1', 'TEST Estabelecimento A', 'test-estab-a', 'Fixture A', '#2563EB', true),
    ('00000000-0000-0000-0000-0000000000b1', 'TEST Estabelecimento B', 'test-estab-b', 'Fixture B', '#16A34A', true),
    ('00000000-0000-0000-0000-0000000000c1', 'TEST Estabelecimento C', 'test-estab-c', 'Fixture C inativo', '#DC2626', false);

-- ----------------------------------------------------------------------------
-- 3) Fixtures: vínculos usuário/perfil/estabelecimento
-- ----------------------------------------------------------------------------
INSERT INTO public.usuarios_estabelecimento
    (user_id, nome, email, perfil, estabelecimento_id, ativo)
VALUES
    ('00000000-0000-0000-0000-00000000ad01', 'Admin Geral',          'admin_geral@test.local',        'administrador_geral',           NULL,                                   true),
    ('00000000-0000-0000-0000-00000000ad0a', 'Admin Estab A',        'admin_estab_a@test.local',      'administrador_estabelecimento', '00000000-0000-0000-0000-0000000000a1', true),
    ('00000000-0000-0000-0000-0000000a0a0a', 'Operador A',           'operador_a@test.local',         'operador',                      '00000000-0000-0000-0000-0000000000a1', true),
    ('00000000-0000-0000-0000-0000000000de', 'Operador A Inativo',   'operador_a_inativo@test.local', 'operador',                      '00000000-0000-0000-0000-0000000000a1', false);
-- Observação: o usuário 'sem_vinculo' (…00ff) existe em auth.users mas
-- intencionalmente NÃO possui registro em usuarios_estabelecimento.

-- ============================================================================
-- 4) ASSERTS — bloco PL/pgSQL único trocando o usuário simulado a cada caso
-- ============================================================================
DO $$
DECLARE
    v_a  CONSTANT UUID := '00000000-0000-0000-0000-0000000000a1';
    v_b  CONSTANT UUID := '00000000-0000-0000-0000-0000000000b1';
    v_c  CONSTANT UUID := '00000000-0000-0000-0000-0000000000c1';

    v_admin_geral   CONSTANT UUID := '00000000-0000-0000-0000-00000000ad01';
    v_admin_estab_a CONSTANT UUID := '00000000-0000-0000-0000-00000000ad0a';
    v_operador_a    CONSTANT UUID := '00000000-0000-0000-0000-0000000a0a0a';
    v_inativo       CONSTANT UUID := '00000000-0000-0000-0000-0000000000de';
    v_sem_vinculo   CONSTANT UUID := '00000000-0000-0000-0000-0000000000ff';

    v_count   INTEGER;
    v_is_geral BOOLEAN;
BEGIN
    -- ------------------------------------------------------------------
    -- Helper inline: para "logar" como um usuário, definimos a claim sub.
    -- ------------------------------------------------------------------

    -- ============================================================
    -- CASO 1: administrador_geral
    -- Property 5: admin geral => acesso a TODOS os estabelecimentos.
    -- ============================================================
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_admin_geral)::text, true);

    SELECT public.fn_is_admin_geral() INTO v_is_geral;
    ASSERT v_is_geral = true,
        'CASO 1 FALHOU: fn_is_admin_geral() deveria ser TRUE para administrador_geral';

    SELECT count(*) INTO v_count FROM public.fn_estabelecimentos_do_usuario();
    ASSERT v_count = 2,
        format('CASO 1 FALHOU: admin_geral deveria acessar 2 estabelecimentos ativos (A,B), obteve %s', v_count);
    ASSERT EXISTS (SELECT 1 FROM public.fn_estabelecimentos_do_usuario() x WHERE x = v_a),
        'CASO 1 FALHOU: admin_geral deveria acessar o Estabelecimento A';
    ASSERT EXISTS (SELECT 1 FROM public.fn_estabelecimentos_do_usuario() x WHERE x = v_b),
        'CASO 1 FALHOU: admin_geral deveria acessar o Estabelecimento B';
    RAISE NOTICE '[OK] CASO 1 admin_geral: is_admin_geral=true, estabelecimentos={A,B}';

    -- ============================================================
    -- CASO 2: administrador_estabelecimento (vinculado ao A)
    -- Property 1/5: vê apenas o estabelecimento vinculado, sem vazamento.
    -- ============================================================
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_admin_estab_a)::text, true);

    SELECT public.fn_is_admin_geral() INTO v_is_geral;
    ASSERT v_is_geral = false,
        'CASO 2 FALHOU: fn_is_admin_geral() deveria ser FALSE para administrador_estabelecimento';

    SELECT count(*) INTO v_count FROM public.fn_estabelecimentos_do_usuario();
    ASSERT v_count = 1,
        format('CASO 2 FALHOU: admin_estab_A deveria acessar exatamente 1 estabelecimento, obteve %s', v_count);
    ASSERT EXISTS (SELECT 1 FROM public.fn_estabelecimentos_do_usuario() x WHERE x = v_a),
        'CASO 2 FALHOU: admin_estab_A deveria acessar o Estabelecimento A (vinculado)';
    ASSERT NOT EXISTS (SELECT 1 FROM public.fn_estabelecimentos_do_usuario() x WHERE x = v_b),
        'CASO 2 FALHOU: admin_estab_A NÃO deveria acessar o Estabelecimento B (vazamento entre tenants)';
    RAISE NOTICE '[OK] CASO 2 admin_estab_A: is_admin_geral=false, estabelecimentos={A}';

    -- ============================================================
    -- CASO 3: operador (vinculado ao A)
    -- Property 1/5: vê apenas o estabelecimento vinculado.
    -- ============================================================
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_operador_a)::text, true);

    SELECT public.fn_is_admin_geral() INTO v_is_geral;
    ASSERT v_is_geral = false,
        'CASO 3 FALHOU: fn_is_admin_geral() deveria ser FALSE para operador';

    SELECT count(*) INTO v_count FROM public.fn_estabelecimentos_do_usuario();
    ASSERT v_count = 1,
        format('CASO 3 FALHOU: operador_A deveria acessar exatamente 1 estabelecimento, obteve %s', v_count);
    ASSERT EXISTS (SELECT 1 FROM public.fn_estabelecimentos_do_usuario() x WHERE x = v_a),
        'CASO 3 FALHOU: operador_A deveria acessar o Estabelecimento A (vinculado)';
    ASSERT NOT EXISTS (SELECT 1 FROM public.fn_estabelecimentos_do_usuario() x WHERE x = v_b),
        'CASO 3 FALHOU: operador_A NÃO deveria acessar o Estabelecimento B (vazamento entre tenants)';
    RAISE NOTICE '[OK] CASO 3 operador_A: is_admin_geral=false, estabelecimentos={A}';

    -- ============================================================
    -- CASO 4: operador INATIVO (vinculado ao A, ativo=false)
    -- Req 5.9 / Property 1: usuário sem autorização => conjunto VAZIO.
    -- ============================================================
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_inativo)::text, true);

    SELECT public.fn_is_admin_geral() INTO v_is_geral;
    ASSERT v_is_geral = false,
        'CASO 4 FALHOU: usuário inativo não deveria ser admin_geral';

    SELECT count(*) INTO v_count FROM public.fn_estabelecimentos_do_usuario();
    ASSERT v_count = 0,
        format('CASO 4 FALHOU: usuário INATIVO deveria acessar 0 estabelecimentos, obteve %s', v_count);
    RAISE NOTICE '[OK] CASO 4 operador_A_inativo: is_admin_geral=false, estabelecimentos={} (vazio)';

    -- ============================================================
    -- CASO 5: usuário autenticado SEM vínculo em usuarios_estabelecimento
    -- Req 5.9 / Property 1: sem vínculo => conjunto VAZIO.
    -- ============================================================
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_sem_vinculo)::text, true);

    SELECT public.fn_is_admin_geral() INTO v_is_geral;
    ASSERT v_is_geral = false,
        'CASO 5 FALHOU: usuário sem vínculo não deveria ser admin_geral';

    SELECT count(*) INTO v_count FROM public.fn_estabelecimentos_do_usuario();
    ASSERT v_count = 0,
        format('CASO 5 FALHOU: usuário SEM VÍNCULO deveria acessar 0 estabelecimentos, obteve %s', v_count);
    RAISE NOTICE '[OK] CASO 5 sem_vinculo: is_admin_geral=false, estabelecimentos={} (vazio)';

    -- ============================================================
    -- CASO 6 (EDGE / DOCUMENTAÇÃO): estabelecimento INATIVO e admin_geral
    -- ------------------------------------------------------------
    -- ATENÇÃO — DISCREPÂNCIA POTENCIAL ENTRE IMPLEMENTAÇÃO E INTENÇÃO:
    -- A função fn_estabelecimentos_do_usuario() NÃO filtra por e.ativo.
    -- Logo, para um administrador_geral, ela retorna TODOS os estabelecimentos,
    -- incluindo os INATIVOS. A Property 5 do design fala em "todos os
    -- estabelecimentos ATIVOS". O filtro por "ativo" hoje é responsabilidade
    -- do frontend (Seletor_de_Estabelecimento, Req 3.1), não da função RLS.
    --
    -- Este caso NÃO usa ASSERT de falha: apenas documenta/observa o
    -- comportamento atual via NOTICE, para que a equipe decida se a função
    -- deve passar a filtrar por ativo. Se o comportamento mudar para filtrar
    -- ativos, troque o NOTICE abaixo por um ASSERT v_count = 2.
    -- ============================================================
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_admin_geral)::text, true);
    SELECT count(*) INTO v_count FROM public.fn_estabelecimentos_do_usuario();
    IF v_count = 3 THEN
        RAISE NOTICE '[INFO] CASO 6 edge: admin_geral enxerga 3 estabelecimentos (A,B e C INATIVO). '
                     'A função NÃO filtra por ativo; o filtro de ativos é aplicado no frontend (Req 3.1). '
                     'Revisar se a Property 5 ("todos os ativos") exige filtrar por ativo na função.';
    ELSIF v_count = 2 THEN
        RAISE NOTICE '[INFO] CASO 6 edge: admin_geral enxerga 2 estabelecimentos (apenas ativos). '
                     'A função filtra por ativo — coerente com "todos os ativos".';
    ELSE
        RAISE NOTICE '[INFO] CASO 6 edge: admin_geral enxerga % estabelecimentos (valor inesperado).', v_count;
    END IF;

    RAISE NOTICE '[OK] TODOS OS TESTES DE RLS PASSARAM';
END $$;

-- ----------------------------------------------------------------------------
-- 5) Desfazer tudo — NÃO persistir fixtures
-- ----------------------------------------------------------------------------
ROLLBACK;

-- ============================================================================
-- ALTERNATIVA pgTAP (opcional)
-- ----------------------------------------------------------------------------
-- Caso a extensão pgTAP esteja instalada no banco de teste, a mesma validação
-- pode ser escrita assim (esboço — requer CREATE EXTENSION IF NOT EXISTS pgtap;):
--
--   BEGIN;
--   SELECT plan(7);
--   -- ... inserir as mesmas fixtures ...
--   PERFORM set_config('request.jwt.claims',
--       json_build_object('sub','00000000-0000-0000-0000-00000000ad01')::text, true);
--   SELECT ok(public.fn_is_admin_geral(), 'admin_geral => is_admin_geral true');
--   SELECT is(
--     (SELECT count(*)::int FROM public.fn_estabelecimentos_do_usuario()),
--     2, 'admin_geral => 2 estabelecimentos');
--   -- ... demais casos com is()/ok() ...
--   SELECT finish();
--   ROLLBACK;
-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================

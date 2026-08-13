-- ============================================================================
-- MULTI-ESTABELECIMENTO: MIGRAÇÃO DE DADOS EXISTENTES
-- ============================================================================
-- Arquivo: 11_migracao_dados.sql
-- Descrição: Migra os dados pré-existentes (single-tenant) para a camada
--            multi-estabelecimento. Em uma única transação atômica:
--              1. Cria (ou reusa) o Estabelecimento_Padrao.
--              2. Faz o backfill de `estabelecimento_id` em TODAS as
--                 Tabelas_de_Dominio onde o valor ainda está nulo.
--              3. Vincula os usuários pré-existentes (profile / funcionarios)
--                 à camada de autorização (usuarios_estabelecimento).
-- Ordem de execução: APÓS 10_tenant_columns.sql (coluna estabelecimento_id já
--                    existe, NULLABLE) e 10b_configuracoes_unique.sql.
--                    ANTES de 12_tenant_not_null_e_rls.sql (tarefa 4.2), que
--                    aplica NOT NULL e as políticas RLS por tenant.
-- Requisitos: 10.1, 10.2, 10.3, 10.5
-- Properties:  9 (Idempotência da migração), 10 (Atomicidade da migração)
-- Data: 20/01/2026
-- ============================================================================
-- CARACTERÍSTICAS:
--   * IDEMPOTENTE (Property 9): a reexecução não cria um Estabelecimento_Padrao
--     duplicado (SELECT por nome antes de inserir) nem re-sobrescreve um
--     `estabelecimento_id` já preenchido (todo UPDATE usa WHERE estabelecimento_id
--     IS NULL). O vínculo de usuários usa NOT EXISTS + ON CONFLICT DO NOTHING.
--   * TRANSACIONAL / ATÔMICA (Property 10): tudo roda dentro de um único
--     BEGIN/COMMIT. Se qualquer passo falhar, a transação inteira sofre ROLLBACK,
--     preservando os dados originais e sem aplicar a restrição NOT NULL
--     (que é responsabilidade exclusiva da tarefa 4.2).
--
--   ESTE ARQUIVO **NÃO**:
--     - aplica NOT NULL em estabelecimento_id (tarefa 4.2 / 12_*.sql);
--     - cria/substitui políticas RLS (tarefa 4.2 / 12_*.sql);
--     - cria a UNIQUE de configuracoes (tarefa 4.2 — arquivo 10b_*).
-- ============================================================================

BEGIN;

DO $$
DECLARE
    v_estab UUID;
    v_slug_base TEXT := 'padrao';
    v_slug TEXT;
    v_seq INT := 0;
    v_vinc_admin INT := 0;
    v_vinc_oper INT := 0;
BEGIN
    -- ------------------------------------------------------------------------
    -- 1. Estabelecimento_Padrao (cria se não existir; reusa se já existir)
    --    Req 10.1 (cria exatamente um, ativo) / Req 10.2 (reusa, sem duplicar)
    -- ------------------------------------------------------------------------
    SELECT id INTO v_estab
    FROM public.estabelecimentos
    WHERE nome = 'Estabelecimento Padrão';

    IF v_estab IS NULL THEN
        -- Garante slug único caso já exista algum 'padrao' por outra via
        v_slug := v_slug_base;
        WHILE EXISTS (SELECT 1 FROM public.estabelecimentos WHERE slug = v_slug) LOOP
            v_seq := v_seq + 1;
            v_slug := v_slug_base || '-' || v_seq::text;
        END LOOP;

        INSERT INTO public.estabelecimentos (nome, slug, descricao, cor_tema, ativo)
        VALUES (
            'Estabelecimento Padrão',
            v_slug,
            'Estabelecimento criado automaticamente na migração inicial multi-estabelecimento. Recebe todos os dados e usuários pré-existentes.',
            '#2563EB',
            true
        )
        RETURNING id INTO v_estab;

        RAISE NOTICE 'Estabelecimento_Padrao criado (id=%, slug=%).', v_estab, v_slug;
    ELSE
        RAISE NOTICE 'Estabelecimento_Padrao já existe (id=%). Reutilizando sem duplicar.', v_estab;
    END IF;

    -- ------------------------------------------------------------------------
    -- 2. Backfill de estabelecimento_id nas Tabelas_de_Dominio (Req 10.3)
    --    Atribui o padrão apenas onde estabelecimento_id está nulo
    --    (WHERE IS NULL garante a idempotência — Property 9).
    --    Cobre as 25 tabelas listadas em 10_tenant_columns.sql.
    -- ------------------------------------------------------------------------

    -- Catálogo de produtos
    UPDATE public.categorias       SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.produtos         SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.sabores          SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.tamanhos         SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.adicionais       SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.combos           SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    -- Relacionamentos N:N (poderiam ser derivados do produto pai; por simplicidade
    -- e completude do backfill, atribui o padrão a todas as linhas nulas).
    UPDATE public.produto_sabores  SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.combo_produtos   SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;

    -- Pedidos e históricos
    UPDATE public.pedidos             SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.historico_pedidos   SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.historico_geral     SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;

    -- Clientes
    UPDATE public.clientes         SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;

    -- Comandas
    UPDATE public.comandas            SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.historico_comandas  SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;

    -- Funcionários
    UPDATE public.funcionarios     SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;

    -- Estoque (legado) + estoque novo (stock_*) + vendas (sales)
    UPDATE public.estoque          SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.stock_items      SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.stock_variants   SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.stock_movements  SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.sales            SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;

    -- Avaliações
    UPDATE public.avaliacoes       SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;

    -- Configurações
    UPDATE public.configuracoes    SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;

    -- Assistente de IA
    UPDATE public.ia_config        SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.ia_conversas     SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;
    UPDATE public.ia_arquivos_temp SET estabelecimento_id = v_estab WHERE estabelecimento_id IS NULL;

    RAISE NOTICE 'Backfill de estabelecimento_id concluído nas 25 Tabelas_de_Dominio.';

    -- ------------------------------------------------------------------------
    -- 3. Vincular usuários pré-existentes (Req 10.5)
    --    Ordem importa: primeiro os administradores (profile), depois os
    --    funcionários (operador). Assim, um usuário presente nas duas origens
    --    permanece como administrador_geral.
    --    Idempotência: NOT EXISTS (por user_id e por email) + ON CONFLICT DO NOTHING
    --    cobrem as duas constraints UNIQUE (user_id, email) de
    --    usuarios_estabelecimento. A reexecução não cria vínculos duplicados.
    -- ------------------------------------------------------------------------

    -- 3.1 Administradores existentes (public.profile) -> administrador_geral
    --     estabelecimento_id NULL = acesso a todos os estabelecimentos.
    INSERT INTO public.usuarios_estabelecimento (user_id, nome, email, perfil, estabelecimento_id, ativo)
    SELECT p.user_id, p.nome, p.email, 'administrador_geral', NULL, true
    FROM public.profile p
    WHERE p.ativo = true
      AND p.user_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM public.usuarios_estabelecimento ue WHERE ue.user_id = p.user_id)
      AND NOT EXISTS (SELECT 1 FROM public.usuarios_estabelecimento ue WHERE ue.email   = p.email)
    ON CONFLICT (user_id) DO NOTHING;

    GET DIAGNOSTICS v_vinc_admin = ROW_COUNT;

    -- 3.2 Funcionários com credencial (public.funcionarios.user_id NOT NULL)
    --     -> operador, vinculados ao Estabelecimento_Padrao.
    INSERT INTO public.usuarios_estabelecimento (user_id, nome, email, perfil, estabelecimento_id, ativo)
    SELECT f.user_id, f.nome, f.email, 'operador', v_estab, COALESCE(f.ativo, true)
    FROM public.funcionarios f
    WHERE f.user_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM public.usuarios_estabelecimento ue WHERE ue.user_id = f.user_id)
      AND NOT EXISTS (SELECT 1 FROM public.usuarios_estabelecimento ue WHERE ue.email   = f.email)
    ON CONFLICT (user_id) DO NOTHING;

    GET DIAGNOSTICS v_vinc_oper = ROW_COUNT;

    RAISE NOTICE 'Vínculo de usuários concluído: % administrador_geral, % operador.', v_vinc_admin, v_vinc_oper;
    RAISE NOTICE 'Migração de dados finalizada com sucesso. NOT NULL e RLS por tenant serão aplicados na tarefa 4.2 (12_tenant_not_null_e_rls.sql).';
END $$;

COMMIT;

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================
-- Próximo passo da migração:
--   12_tenant_not_null_e_rls.sql (tarefa 4.2) — verifica que todos os registros
--   possuem estabelecimento_id preenchido, aplica SET NOT NULL e substitui as
--   políticas RLS permissivas pelas políticas por tenant.
-- ============================================================================

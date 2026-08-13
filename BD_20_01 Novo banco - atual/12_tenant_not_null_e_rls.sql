-- ============================================================================
-- MULTI-ESTABELECIMENTO: VERIFICAÇÃO + NOT NULL + RLS POR TENANT
-- ============================================================================
-- Arquivo: 12_tenant_not_null_e_rls.sql
-- Descrição: Etapa final da camada de banco multi-tenant. Em UMA única
--            transação atômica:
--              1. VERIFICA que o backfill (tarefa 4.1 / 11_migracao_dados.sql)
--                 foi 100% concluído — nenhuma Tabela_de_Dominio pode ter
--                 estabelecimento_id NULL. Se houver qualquer linha NULL, a
--                 transação é ABORTADA (RAISE EXCEPTION) e NADA é aplicado
--                 (nem NOT NULL nem novas políticas). (Req 10.4, 10.7 / Property 10)
--              2. Aplica `ALTER COLUMN estabelecimento_id SET NOT NULL` às 25
--                 Tabelas_de_Dominio, somente após a verificação passar. (Req 10.6)
--              3. Substitui as políticas RLS permissivas (USING true) pelas
--                 políticas por TENANT, escopadas por
--                 fn_estabelecimentos_do_usuario(). (Req 5.3, 5.4, 5.6, 5.7)
-- Ordem de execução: APÓS 11_migracao_dados.sql (backfill) e
--                    10b_configuracoes_unique.sql. É o ÚLTIMO passo da camada
--                    de banco multi-tenant (exceto os fluxos públicos por slug
--                    da tarefa 14.x).
-- Requisitos: 5.3, 5.4, 5.6, 5.7, 10.4, 10.6, 10.7
-- Properties:  1 (sem vazamento), 2 (escrita confinada), 4 (RLS independe do
--              frontend), 10 (atomicidade: NOT NULL só após verificação)
-- Data: 20/01/2026
-- ============================================================================
-- ATOMICIDADE (Property 10 / Req 10.7):
--   Todo o arquivo roda dentro de um único BEGIN/COMMIT. Como DDL em PostgreSQL
--   é transacional, se a verificação do passo 1 disparar RAISE EXCEPTION (ou
--   qualquer passo falhar), a transação inteira sofre ROLLBACK: a restrição
--   NOT NULL NÃO é aplicada e as políticas permissivas antigas permanecem
--   intactas. O banco fica em um estado consistente e seguro.
--
-- IDEMPOTÊNCIA:
--   * Passo 1 (verificação) é apenas leitura.
--   * Passo 2 (SET NOT NULL) é seguro de reexecutar: aplicar SET NOT NULL a uma
--     coluna que já é NOT NULL não gera erro.
--   * Passo 3 (políticas) usa DROP POLICY IF EXISTS antes de cada CREATE POLICY,
--     podendo ser reexecutado sem erro.
--
-- COMPATIBILIDADE COM O SITE PÚBLICO (anon) — DECISÃO DOCUMENTADA:
--   As novas políticas por tenant são para o papel `authenticated` (o painel
--   administrativo / operação interna). O site público de delivery acessa o
--   banco como `anon` (chave anônima do Supabase) e hoje:
--     - LÊ o catálogo: produtos, categorias, sabores, combos, tamanhos, adicionais;
--     - LÊ avaliações aprovadas (vitrine de avaliações);
--     - INSERE pedidos, clientes e avaliações (checkout e formulário de avaliação).
--   Se removêssemos as políticas permissivas anônimas agora, o site público
--   quebraria imediatamente. Como o escopo público por estabelecimento depende
--   do SLUG na URL (decisão de design item 3) e isso só é implementado na
--   tarefa 14.4, ESTE ARQUIVO MANTÉM/RECRIA, para o papel `anon`, a leitura
--   pública do catálogo e os inserts públicos — AINDA SEM escopo por tenant.
--   >>> Essas políticas anônimas são TEMPORÁRIAS e serão SUBSTITUÍDAS por
--       políticas escopadas pelo estabelecimento do slug na tarefa 14.4. <<<
--   Cada política anônima abaixo está marcada com o comentário
--   "TEMPORÁRIA — escopar por slug na tarefa 14.4".
-- ============================================================================

BEGIN;

-- ============================================================================
-- PASSO 1 — VERIFICAÇÃO DE BACKFILL COMPLETO (Req 10.4, 10.7 / Property 10)
-- ============================================================================
-- Percorre as 25 Tabelas_de_Dominio e conta linhas com estabelecimento_id NULL.
-- Se QUALQUER tabela tiver ao menos uma linha NULL, aborta a transação inteira
-- com RAISE EXCEPTION, garantindo que o NOT NULL e as políticas por tenant NÃO
-- sejam aplicados sobre um backfill incompleto.
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_tabela            TEXT;
    v_nulos             BIGINT;
    v_total_nulos       BIGINT := 0;
    v_tabelas_com_nulos TEXT := '';
    v_tabelas           TEXT[] := ARRAY[
        'categorias','produtos','sabores','tamanhos','adicionais','combos',
        'produto_sabores','combo_produtos','pedidos','historico_pedidos',
        'historico_geral','clientes','comandas','historico_comandas',
        'funcionarios','estoque','stock_items','stock_variants',
        'stock_movements','sales','avaliacoes','configuracoes',
        'ia_config','ia_conversas','ia_arquivos_temp'
    ];
BEGIN
    FOREACH v_tabela IN ARRAY v_tabelas LOOP
        EXECUTE format(
            'SELECT count(*) FROM public.%I WHERE estabelecimento_id IS NULL',
            v_tabela
        ) INTO v_nulos;

        IF v_nulos > 0 THEN
            v_total_nulos := v_total_nulos + v_nulos;
            v_tabelas_com_nulos := v_tabelas_com_nulos
                || format('  - %s: %s linha(s) com estabelecimento_id NULL', v_tabela, v_nulos)
                || chr(10);
        END IF;
    END LOOP;

    IF v_total_nulos > 0 THEN
        RAISE EXCEPTION
            E'ABORTANDO: backfill de estabelecimento_id INCOMPLETO (% linha(s) NULL no total).\n%\nExecute (ou reexecute) 11_migracao_dados.sql antes de aplicar NOT NULL/RLS. NENHUMA alteração foi aplicada (rollback).',
            v_total_nulos, v_tabelas_com_nulos;
    END IF;

    RAISE NOTICE 'Verificação OK: nenhuma Tabela_de_Dominio possui estabelecimento_id NULL. Prosseguindo com NOT NULL e RLS por tenant.';
END $$;

-- ============================================================================
-- PASSO 2 — APLICAR NOT NULL EM estabelecimento_id (Req 10.6)
-- ============================================================================
-- Só é alcançado se o PASSO 1 não abortou. Torna estabelecimento_id obrigatório
-- em todas as Tabelas_de_Dominio, reforçando a Property 3 (estabelecimento_id
-- sempre presente) no nível do banco.
-- ----------------------------------------------------------------------------

-- Catálogo de produtos
ALTER TABLE public.categorias       ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.produtos         ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.sabores          ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.tamanhos         ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.adicionais       ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.combos           ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.produto_sabores  ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.combo_produtos   ALTER COLUMN estabelecimento_id SET NOT NULL;

-- Pedidos e históricos
ALTER TABLE public.pedidos            ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.historico_pedidos  ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.historico_geral    ALTER COLUMN estabelecimento_id SET NOT NULL;

-- Clientes
ALTER TABLE public.clientes         ALTER COLUMN estabelecimento_id SET NOT NULL;

-- Comandas
ALTER TABLE public.comandas           ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.historico_comandas ALTER COLUMN estabelecimento_id SET NOT NULL;

-- Funcionários
ALTER TABLE public.funcionarios     ALTER COLUMN estabelecimento_id SET NOT NULL;

-- Estoque (legado) + estoque novo (stock_*) + vendas (sales)
ALTER TABLE public.estoque          ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.stock_items      ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.stock_variants   ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.stock_movements  ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.sales            ALTER COLUMN estabelecimento_id SET NOT NULL;

-- Avaliações
ALTER TABLE public.avaliacoes       ALTER COLUMN estabelecimento_id SET NOT NULL;

-- Configurações
ALTER TABLE public.configuracoes    ALTER COLUMN estabelecimento_id SET NOT NULL;

-- Assistente de IA
ALTER TABLE public.ia_config        ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.ia_conversas     ALTER COLUMN estabelecimento_id SET NOT NULL;
ALTER TABLE public.ia_arquivos_temp ALTER COLUMN estabelecimento_id SET NOT NULL;

-- Nota: a constraint UNIQUE (estabelecimento_id, chave) de `configuracoes` é
-- criada no arquivo 10b_configuracoes_unique.sql (tarefa 3.2). NÃO é repetida
-- aqui para evitar conflito. Após o SET NOT NULL acima, a coluna
-- estabelecimento_id dessa constraint nunca será NULL, reforçando a unicidade.

-- ============================================================================
-- PASSO 3 — POLÍTICAS RLS POR TENANT (Req 5.3, 5.4, 5.6, 5.7)
-- ============================================================================
-- Padrão aplicado a cada Tabela_de_Dominio, para o papel `authenticated`:
--   SELECT : USING      (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
--   INSERT : WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
--   UPDATE : USING + WITH CHECK (mesma condição)
--   DELETE : USING      (mesma condição)
--
-- A RLS é a barreira REAL de segurança: a restrição vale mesmo sem nenhum filtro
-- enviado pelo frontend (Req 5.6 / Property 4) e impede leitura/escrita fora dos
-- estabelecimentos autorizados (Req 5.3, 5.4, 5.7 / Properties 1 e 2).
--
-- Cada bloco primeiro REMOVE as políticas permissivas antigas (nomes reais de
-- 06_rls_policies.sql / 03b_tables_stock_sales.sql) e então cria as novas.
-- Todas as criações são precedidas de DROP POLICY IF EXISTS (idempotência).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- produtos  (catálogo — leitura anônima pública mantida temporariamente)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Leitura pública produtos" ON public.produtos;
DROP POLICY IF EXISTS "Inserção autenticada produtos" ON public.produtos;
DROP POLICY IF EXISTS "Atualização autenticada produtos" ON public.produtos;
DROP POLICY IF EXISTS "Exclusão autenticada produtos" ON public.produtos;

DROP POLICY IF EXISTS "produtos_select_tenant" ON public.produtos;
CREATE POLICY "produtos_select_tenant" ON public.produtos
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "produtos_insert_tenant" ON public.produtos;
CREATE POLICY "produtos_insert_tenant" ON public.produtos
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "produtos_update_tenant" ON public.produtos;
CREATE POLICY "produtos_update_tenant" ON public.produtos
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "produtos_delete_tenant" ON public.produtos;
CREATE POLICY "produtos_delete_tenant" ON public.produtos
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- TEMPORÁRIA — escopar por slug na tarefa 14.4: leitura pública do catálogo (anon)
DROP POLICY IF EXISTS "produtos_select_publico" ON public.produtos;
CREATE POLICY "produtos_select_publico" ON public.produtos
    FOR SELECT TO anon
    USING (true);

-- ----------------------------------------------------------------------------
-- categorias  (catálogo — leitura anônima pública mantida temporariamente)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Leitura pública categorias" ON public.categorias;
DROP POLICY IF EXISTS "Inserção autenticada categorias" ON public.categorias;
DROP POLICY IF EXISTS "Atualização autenticada categorias" ON public.categorias;
DROP POLICY IF EXISTS "Exclusão autenticada categorias" ON public.categorias;

DROP POLICY IF EXISTS "categorias_select_tenant" ON public.categorias;
CREATE POLICY "categorias_select_tenant" ON public.categorias
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "categorias_insert_tenant" ON public.categorias;
CREATE POLICY "categorias_insert_tenant" ON public.categorias
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "categorias_update_tenant" ON public.categorias;
CREATE POLICY "categorias_update_tenant" ON public.categorias
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "categorias_delete_tenant" ON public.categorias;
CREATE POLICY "categorias_delete_tenant" ON public.categorias
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- TEMPORÁRIA — escopar por slug na tarefa 14.4: leitura pública do catálogo (anon)
DROP POLICY IF EXISTS "categorias_select_publico" ON public.categorias;
CREATE POLICY "categorias_select_publico" ON public.categorias
    FOR SELECT TO anon
    USING (true);

-- ----------------------------------------------------------------------------
-- sabores  (catálogo — leitura anônima pública mantida temporariamente)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Leitura pública sabores" ON public.sabores;
DROP POLICY IF EXISTS "Inserção autenticada sabores" ON public.sabores;
DROP POLICY IF EXISTS "Atualização autenticada sabores" ON public.sabores;
DROP POLICY IF EXISTS "Exclusão autenticada sabores" ON public.sabores;

DROP POLICY IF EXISTS "sabores_select_tenant" ON public.sabores;
CREATE POLICY "sabores_select_tenant" ON public.sabores
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "sabores_insert_tenant" ON public.sabores;
CREATE POLICY "sabores_insert_tenant" ON public.sabores
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "sabores_update_tenant" ON public.sabores;
CREATE POLICY "sabores_update_tenant" ON public.sabores
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "sabores_delete_tenant" ON public.sabores;
CREATE POLICY "sabores_delete_tenant" ON public.sabores
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- TEMPORÁRIA — escopar por slug na tarefa 14.4: leitura pública do catálogo (anon)
DROP POLICY IF EXISTS "sabores_select_publico" ON public.sabores;
CREATE POLICY "sabores_select_publico" ON public.sabores
    FOR SELECT TO anon
    USING (true);

-- ----------------------------------------------------------------------------
-- tamanhos  (catálogo — leitura anônima pública mantida temporariamente)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Leitura pública tamanhos" ON public.tamanhos;
DROP POLICY IF EXISTS "Inserção autenticada tamanhos" ON public.tamanhos;
DROP POLICY IF EXISTS "Atualização autenticada tamanhos" ON public.tamanhos;
DROP POLICY IF EXISTS "Exclusão autenticada tamanhos" ON public.tamanhos;

DROP POLICY IF EXISTS "tamanhos_select_tenant" ON public.tamanhos;
CREATE POLICY "tamanhos_select_tenant" ON public.tamanhos
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "tamanhos_insert_tenant" ON public.tamanhos;
CREATE POLICY "tamanhos_insert_tenant" ON public.tamanhos
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "tamanhos_update_tenant" ON public.tamanhos;
CREATE POLICY "tamanhos_update_tenant" ON public.tamanhos
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "tamanhos_delete_tenant" ON public.tamanhos;
CREATE POLICY "tamanhos_delete_tenant" ON public.tamanhos
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- TEMPORÁRIA — escopar por slug na tarefa 14.4: leitura pública do catálogo (anon)
DROP POLICY IF EXISTS "tamanhos_select_publico" ON public.tamanhos;
CREATE POLICY "tamanhos_select_publico" ON public.tamanhos
    FOR SELECT TO anon
    USING (true);

-- ----------------------------------------------------------------------------
-- adicionais  (catálogo — leitura anônima pública mantida temporariamente)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Permitir leitura pública de adicionais" ON public.adicionais;
DROP POLICY IF EXISTS "Permitir inserção autenticada de adicionais" ON public.adicionais;
DROP POLICY IF EXISTS "Permitir atualização autenticada de adicionais" ON public.adicionais;
DROP POLICY IF EXISTS "Permitir exclusão autenticada de adicionais" ON public.adicionais;

DROP POLICY IF EXISTS "adicionais_select_tenant" ON public.adicionais;
CREATE POLICY "adicionais_select_tenant" ON public.adicionais
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "adicionais_insert_tenant" ON public.adicionais;
CREATE POLICY "adicionais_insert_tenant" ON public.adicionais
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "adicionais_update_tenant" ON public.adicionais;
CREATE POLICY "adicionais_update_tenant" ON public.adicionais
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "adicionais_delete_tenant" ON public.adicionais;
CREATE POLICY "adicionais_delete_tenant" ON public.adicionais
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- TEMPORÁRIA — escopar por slug na tarefa 14.4: leitura pública do catálogo (anon)
DROP POLICY IF EXISTS "adicionais_select_publico" ON public.adicionais;
CREATE POLICY "adicionais_select_publico" ON public.adicionais
    FOR SELECT TO anon
    USING (true);

-- ----------------------------------------------------------------------------
-- combos  (catálogo — leitura anônima pública mantida temporariamente)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Leitura pública combos" ON public.combos;
DROP POLICY IF EXISTS "Inserção autenticada combos" ON public.combos;
DROP POLICY IF EXISTS "Atualização autenticada combos" ON public.combos;
DROP POLICY IF EXISTS "Exclusão autenticada combos" ON public.combos;

DROP POLICY IF EXISTS "combos_select_tenant" ON public.combos;
CREATE POLICY "combos_select_tenant" ON public.combos
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "combos_insert_tenant" ON public.combos;
CREATE POLICY "combos_insert_tenant" ON public.combos
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "combos_update_tenant" ON public.combos;
CREATE POLICY "combos_update_tenant" ON public.combos
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "combos_delete_tenant" ON public.combos;
CREATE POLICY "combos_delete_tenant" ON public.combos
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- TEMPORÁRIA — escopar por slug na tarefa 14.4: leitura pública do catálogo (anon)
DROP POLICY IF EXISTS "combos_select_publico" ON public.combos;
CREATE POLICY "combos_select_publico" ON public.combos
    FOR SELECT TO anon
    USING (true);

-- ----------------------------------------------------------------------------
-- produto_sabores  (relacionamento N:N do catálogo — leitura anônima mantida)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Leitura pública produto_sabores" ON public.produto_sabores;
DROP POLICY IF EXISTS "Inserção autenticada produto_sabores" ON public.produto_sabores;
DROP POLICY IF EXISTS "Atualização autenticada produto_sabores" ON public.produto_sabores;
DROP POLICY IF EXISTS "Exclusão autenticada produto_sabores" ON public.produto_sabores;

DROP POLICY IF EXISTS "produto_sabores_select_tenant" ON public.produto_sabores;
CREATE POLICY "produto_sabores_select_tenant" ON public.produto_sabores
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "produto_sabores_insert_tenant" ON public.produto_sabores;
CREATE POLICY "produto_sabores_insert_tenant" ON public.produto_sabores
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "produto_sabores_update_tenant" ON public.produto_sabores;
CREATE POLICY "produto_sabores_update_tenant" ON public.produto_sabores
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "produto_sabores_delete_tenant" ON public.produto_sabores;
CREATE POLICY "produto_sabores_delete_tenant" ON public.produto_sabores
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- TEMPORÁRIA — escopar por slug na tarefa 14.4: leitura pública do catálogo (anon)
DROP POLICY IF EXISTS "produto_sabores_select_publico" ON public.produto_sabores;
CREATE POLICY "produto_sabores_select_publico" ON public.produto_sabores
    FOR SELECT TO anon
    USING (true);

-- ----------------------------------------------------------------------------
-- combo_produtos  (relacionamento N:N do catálogo — leitura anônima mantida)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Leitura pública combo_produtos" ON public.combo_produtos;
DROP POLICY IF EXISTS "Inserção autenticada combo_produtos" ON public.combo_produtos;
DROP POLICY IF EXISTS "Atualização autenticada combo_produtos" ON public.combo_produtos;
DROP POLICY IF EXISTS "Exclusão autenticada combo_produtos" ON public.combo_produtos;

DROP POLICY IF EXISTS "combo_produtos_select_tenant" ON public.combo_produtos;
CREATE POLICY "combo_produtos_select_tenant" ON public.combo_produtos
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "combo_produtos_insert_tenant" ON public.combo_produtos;
CREATE POLICY "combo_produtos_insert_tenant" ON public.combo_produtos
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "combo_produtos_update_tenant" ON public.combo_produtos;
CREATE POLICY "combo_produtos_update_tenant" ON public.combo_produtos
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "combo_produtos_delete_tenant" ON public.combo_produtos;
CREATE POLICY "combo_produtos_delete_tenant" ON public.combo_produtos
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- TEMPORÁRIA — escopar por slug na tarefa 14.4: leitura pública do catálogo (anon)
DROP POLICY IF EXISTS "combo_produtos_select_publico" ON public.combo_produtos;
CREATE POLICY "combo_produtos_select_publico" ON public.combo_produtos
    FOR SELECT TO anon
    USING (true);

-- ----------------------------------------------------------------------------
-- pedidos  (checkout público insere; painel autenticado opera por tenant)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Permitir leitura pública de pedidos" ON public.pedidos;
DROP POLICY IF EXISTS "Permitir inserção pública de pedidos" ON public.pedidos;
DROP POLICY IF EXISTS "Permitir atualização pública pedidos" ON public.pedidos;
DROP POLICY IF EXISTS "Permitir exclusão pública de pedidos" ON public.pedidos;

DROP POLICY IF EXISTS "pedidos_select_tenant" ON public.pedidos;
CREATE POLICY "pedidos_select_tenant" ON public.pedidos
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "pedidos_insert_tenant" ON public.pedidos;
CREATE POLICY "pedidos_insert_tenant" ON public.pedidos
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "pedidos_update_tenant" ON public.pedidos;
CREATE POLICY "pedidos_update_tenant" ON public.pedidos
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "pedidos_delete_tenant" ON public.pedidos;
CREATE POLICY "pedidos_delete_tenant" ON public.pedidos
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- TEMPORÁRIA — escopar por slug na tarefa 14.4: insert público de pedido (anon).
-- O checkout público (anon) precisa criar o pedido. Na 14.4 esta política será
-- substituída por uma que exige estabelecimento_id = estabelecimento do slug.
DROP POLICY IF EXISTS "pedidos_insert_publico" ON public.pedidos;
CREATE POLICY "pedidos_insert_publico" ON public.pedidos
    FOR INSERT TO anon
    WITH CHECK (true);

-- ----------------------------------------------------------------------------
-- clientes  (checkout público cria/atualiza; painel autenticado opera por tenant)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Permitir todas as operações em clientes" ON public.clientes;

DROP POLICY IF EXISTS "clientes_select_tenant" ON public.clientes;
CREATE POLICY "clientes_select_tenant" ON public.clientes
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "clientes_insert_tenant" ON public.clientes;
CREATE POLICY "clientes_insert_tenant" ON public.clientes
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "clientes_update_tenant" ON public.clientes;
CREATE POLICY "clientes_update_tenant" ON public.clientes
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "clientes_delete_tenant" ON public.clientes;
CREATE POLICY "clientes_delete_tenant" ON public.clientes
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- TEMPORÁRIA — escopar por slug na tarefa 14.4: insert público de cliente (anon).
DROP POLICY IF EXISTS "clientes_insert_publico" ON public.clientes;
CREATE POLICY "clientes_insert_publico" ON public.clientes
    FOR INSERT TO anon
    WITH CHECK (true);

-- ----------------------------------------------------------------------------
-- avaliacoes  (formulário público insere; vitrine pública lê aprovadas)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Permitir leitura pública de avaliações aprovadas" ON public.avaliacoes;
DROP POLICY IF EXISTS "Permitir inserção pública de avaliações" ON public.avaliacoes;
DROP POLICY IF EXISTS "Permitir atualização de avaliações" ON public.avaliacoes;

DROP POLICY IF EXISTS "avaliacoes_select_tenant" ON public.avaliacoes;
CREATE POLICY "avaliacoes_select_tenant" ON public.avaliacoes
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "avaliacoes_insert_tenant" ON public.avaliacoes;
CREATE POLICY "avaliacoes_insert_tenant" ON public.avaliacoes
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "avaliacoes_update_tenant" ON public.avaliacoes;
CREATE POLICY "avaliacoes_update_tenant" ON public.avaliacoes
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "avaliacoes_delete_tenant" ON public.avaliacoes;
CREATE POLICY "avaliacoes_delete_tenant" ON public.avaliacoes
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- TEMPORÁRIA — escopar por slug na tarefa 14.4: leitura pública de avaliações aprovadas (anon)
DROP POLICY IF EXISTS "avaliacoes_select_publico" ON public.avaliacoes;
CREATE POLICY "avaliacoes_select_publico" ON public.avaliacoes
    FOR SELECT TO anon
    USING (aprovada = true);

-- TEMPORÁRIA — escopar por slug na tarefa 14.4: insert público de avaliação (anon)
DROP POLICY IF EXISTS "avaliacoes_insert_publico" ON public.avaliacoes;
CREATE POLICY "avaliacoes_insert_publico" ON public.avaliacoes
    FOR INSERT TO anon
    WITH CHECK (true);

-- ----------------------------------------------------------------------------
-- historico_pedidos  (somente autenticado, escopado por tenant)
-- Antes possuía leitura/inserção/atualização públicas. O acompanhamento público
-- de pedido por slug, se necessário, será reavaliado na tarefa 14.4.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Permitir leitura pública do histórico" ON public.historico_pedidos;
DROP POLICY IF EXISTS "Permitir inserção pública historico_pedidos" ON public.historico_pedidos;
DROP POLICY IF EXISTS "Permitir atualização pública historico_pedidos" ON public.historico_pedidos;

DROP POLICY IF EXISTS "historico_pedidos_select_tenant" ON public.historico_pedidos;
CREATE POLICY "historico_pedidos_select_tenant" ON public.historico_pedidos
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "historico_pedidos_insert_tenant" ON public.historico_pedidos;
CREATE POLICY "historico_pedidos_insert_tenant" ON public.historico_pedidos
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "historico_pedidos_update_tenant" ON public.historico_pedidos;
CREATE POLICY "historico_pedidos_update_tenant" ON public.historico_pedidos
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "historico_pedidos_delete_tenant" ON public.historico_pedidos;
CREATE POLICY "historico_pedidos_delete_tenant" ON public.historico_pedidos
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- historico_geral  (somente autenticado, escopado por tenant)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Enable all operations for historico_geral" ON public.historico_geral;

DROP POLICY IF EXISTS "historico_geral_select_tenant" ON public.historico_geral;
CREATE POLICY "historico_geral_select_tenant" ON public.historico_geral
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "historico_geral_insert_tenant" ON public.historico_geral;
CREATE POLICY "historico_geral_insert_tenant" ON public.historico_geral
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "historico_geral_update_tenant" ON public.historico_geral;
CREATE POLICY "historico_geral_update_tenant" ON public.historico_geral
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "historico_geral_delete_tenant" ON public.historico_geral;
CREATE POLICY "historico_geral_delete_tenant" ON public.historico_geral
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- comandas  (somente autenticado, escopado por tenant)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Usuários autenticados podem visualizar comandas" ON public.comandas;
DROP POLICY IF EXISTS "Usuários autenticados podem criar comandas" ON public.comandas;
DROP POLICY IF EXISTS "Usuários autenticados podem atualizar comandas" ON public.comandas;
DROP POLICY IF EXISTS "Usuários autenticados podem deletar comandas" ON public.comandas;

DROP POLICY IF EXISTS "comandas_select_tenant" ON public.comandas;
CREATE POLICY "comandas_select_tenant" ON public.comandas
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "comandas_insert_tenant" ON public.comandas;
CREATE POLICY "comandas_insert_tenant" ON public.comandas
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "comandas_update_tenant" ON public.comandas;
CREATE POLICY "comandas_update_tenant" ON public.comandas
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "comandas_delete_tenant" ON public.comandas;
CREATE POLICY "comandas_delete_tenant" ON public.comandas
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- historico_comandas  (somente autenticado, escopado por tenant)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Usuários autenticados podem visualizar histórico" ON public.historico_comandas;
DROP POLICY IF EXISTS "Usuários autenticados podem criar histórico" ON public.historico_comandas;

DROP POLICY IF EXISTS "historico_comandas_select_tenant" ON public.historico_comandas;
CREATE POLICY "historico_comandas_select_tenant" ON public.historico_comandas
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "historico_comandas_insert_tenant" ON public.historico_comandas;
CREATE POLICY "historico_comandas_insert_tenant" ON public.historico_comandas
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "historico_comandas_update_tenant" ON public.historico_comandas;
CREATE POLICY "historico_comandas_update_tenant" ON public.historico_comandas
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "historico_comandas_delete_tenant" ON public.historico_comandas;
CREATE POLICY "historico_comandas_delete_tenant" ON public.historico_comandas
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- funcionarios  (somente autenticado, escopado por tenant)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Permitir leitura funcionarios autenticados" ON public.funcionarios;
DROP POLICY IF EXISTS "Permitir criacao funcionarios autenticados" ON public.funcionarios;
DROP POLICY IF EXISTS "Permitir atualizacao funcionarios autenticados" ON public.funcionarios;
DROP POLICY IF EXISTS "Permitir exclusao funcionarios autenticados" ON public.funcionarios;

DROP POLICY IF EXISTS "funcionarios_select_tenant" ON public.funcionarios;
CREATE POLICY "funcionarios_select_tenant" ON public.funcionarios
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "funcionarios_insert_tenant" ON public.funcionarios;
CREATE POLICY "funcionarios_insert_tenant" ON public.funcionarios
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "funcionarios_update_tenant" ON public.funcionarios;
CREATE POLICY "funcionarios_update_tenant" ON public.funcionarios
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "funcionarios_delete_tenant" ON public.funcionarios;
CREATE POLICY "funcionarios_delete_tenant" ON public.funcionarios
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- estoque  (legado — somente autenticado, escopado por tenant)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Acesso autenticado estoque" ON public.estoque;

DROP POLICY IF EXISTS "estoque_select_tenant" ON public.estoque;
CREATE POLICY "estoque_select_tenant" ON public.estoque
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "estoque_insert_tenant" ON public.estoque;
CREATE POLICY "estoque_insert_tenant" ON public.estoque
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "estoque_update_tenant" ON public.estoque;
CREATE POLICY "estoque_update_tenant" ON public.estoque
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "estoque_delete_tenant" ON public.estoque;
CREATE POLICY "estoque_delete_tenant" ON public.estoque
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- stock_items  (somente autenticado, escopado por tenant)
-- Políticas antigas em 03b_tables_stock_sales.sql (sufixo _auth).
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "stock_items_select_auth" ON public.stock_items;
DROP POLICY IF EXISTS "stock_items_insert_auth" ON public.stock_items;
DROP POLICY IF EXISTS "stock_items_update_auth" ON public.stock_items;
DROP POLICY IF EXISTS "stock_items_delete_auth" ON public.stock_items;

DROP POLICY IF EXISTS "stock_items_select_tenant" ON public.stock_items;
CREATE POLICY "stock_items_select_tenant" ON public.stock_items
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "stock_items_insert_tenant" ON public.stock_items;
CREATE POLICY "stock_items_insert_tenant" ON public.stock_items
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "stock_items_update_tenant" ON public.stock_items;
CREATE POLICY "stock_items_update_tenant" ON public.stock_items
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "stock_items_delete_tenant" ON public.stock_items;
CREATE POLICY "stock_items_delete_tenant" ON public.stock_items
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- stock_variants  (somente autenticado, escopado por tenant)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "stock_variants_select_auth" ON public.stock_variants;
DROP POLICY IF EXISTS "stock_variants_insert_auth" ON public.stock_variants;
DROP POLICY IF EXISTS "stock_variants_update_auth" ON public.stock_variants;
DROP POLICY IF EXISTS "stock_variants_delete_auth" ON public.stock_variants;

DROP POLICY IF EXISTS "stock_variants_select_tenant" ON public.stock_variants;
CREATE POLICY "stock_variants_select_tenant" ON public.stock_variants
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "stock_variants_insert_tenant" ON public.stock_variants;
CREATE POLICY "stock_variants_insert_tenant" ON public.stock_variants
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "stock_variants_update_tenant" ON public.stock_variants;
CREATE POLICY "stock_variants_update_tenant" ON public.stock_variants
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "stock_variants_delete_tenant" ON public.stock_variants;
CREATE POLICY "stock_variants_delete_tenant" ON public.stock_variants
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- stock_movements  (somente autenticado, escopado por tenant)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "stock_movements_select_auth" ON public.stock_movements;
DROP POLICY IF EXISTS "stock_movements_insert_auth" ON public.stock_movements;
DROP POLICY IF EXISTS "stock_movements_update_auth" ON public.stock_movements;
DROP POLICY IF EXISTS "stock_movements_delete_auth" ON public.stock_movements;

DROP POLICY IF EXISTS "stock_movements_select_tenant" ON public.stock_movements;
CREATE POLICY "stock_movements_select_tenant" ON public.stock_movements
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "stock_movements_insert_tenant" ON public.stock_movements;
CREATE POLICY "stock_movements_insert_tenant" ON public.stock_movements
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "stock_movements_update_tenant" ON public.stock_movements;
CREATE POLICY "stock_movements_update_tenant" ON public.stock_movements
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "stock_movements_delete_tenant" ON public.stock_movements;
CREATE POLICY "stock_movements_delete_tenant" ON public.stock_movements
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- sales  (somente autenticado, escopado por tenant)
-- DECISÃO: assim como em 03b_tables_stock_sales.sql, NÃO há política de DELETE
-- para `sales` — vendas são preservadas (registro histórico). Sem política de
-- DELETE sob RLS habilitado, toda tentativa de exclusão é negada por padrão.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "sales_select_auth" ON public.sales;
DROP POLICY IF EXISTS "sales_insert_auth" ON public.sales;
DROP POLICY IF EXISTS "sales_update_auth" ON public.sales;

DROP POLICY IF EXISTS "sales_select_tenant" ON public.sales;
CREATE POLICY "sales_select_tenant" ON public.sales
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "sales_insert_tenant" ON public.sales;
CREATE POLICY "sales_insert_tenant" ON public.sales
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "sales_update_tenant" ON public.sales;
CREATE POLICY "sales_update_tenant" ON public.sales
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- configuracoes  (somente autenticado, escopado por tenant)
-- A política anterior permitia anon; o painel administrativo é autenticado.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "configuracoes_optimized_policy" ON public.configuracoes;

DROP POLICY IF EXISTS "configuracoes_select_tenant" ON public.configuracoes;
CREATE POLICY "configuracoes_select_tenant" ON public.configuracoes
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "configuracoes_insert_tenant" ON public.configuracoes;
CREATE POLICY "configuracoes_insert_tenant" ON public.configuracoes
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "configuracoes_update_tenant" ON public.configuracoes;
CREATE POLICY "configuracoes_update_tenant" ON public.configuracoes
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "configuracoes_delete_tenant" ON public.configuracoes;
CREATE POLICY "configuracoes_delete_tenant" ON public.configuracoes
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- ia_config  (somente autenticado, escopado por tenant)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Usuários autenticados podem ler configurações" ON public.ia_config;
DROP POLICY IF EXISTS "Usuários autenticados podem inserir configurações" ON public.ia_config;
DROP POLICY IF EXISTS "Usuários autenticados podem atualizar configurações" ON public.ia_config;

DROP POLICY IF EXISTS "ia_config_select_tenant" ON public.ia_config;
CREATE POLICY "ia_config_select_tenant" ON public.ia_config
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "ia_config_insert_tenant" ON public.ia_config;
CREATE POLICY "ia_config_insert_tenant" ON public.ia_config
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "ia_config_update_tenant" ON public.ia_config;
CREATE POLICY "ia_config_update_tenant" ON public.ia_config
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "ia_config_delete_tenant" ON public.ia_config;
CREATE POLICY "ia_config_delete_tenant" ON public.ia_config
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- ia_conversas  (somente autenticado, escopado por tenant)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Usuários autenticados podem ler conversas" ON public.ia_conversas;
DROP POLICY IF EXISTS "Usuários autenticados podem inserir conversas" ON public.ia_conversas;
DROP POLICY IF EXISTS "Usuários autenticados podem atualizar conversas" ON public.ia_conversas;
DROP POLICY IF EXISTS "Usuários autenticados podem deletar conversas" ON public.ia_conversas;

DROP POLICY IF EXISTS "ia_conversas_select_tenant" ON public.ia_conversas;
CREATE POLICY "ia_conversas_select_tenant" ON public.ia_conversas
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "ia_conversas_insert_tenant" ON public.ia_conversas;
CREATE POLICY "ia_conversas_insert_tenant" ON public.ia_conversas
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "ia_conversas_update_tenant" ON public.ia_conversas;
CREATE POLICY "ia_conversas_update_tenant" ON public.ia_conversas
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "ia_conversas_delete_tenant" ON public.ia_conversas;
CREATE POLICY "ia_conversas_delete_tenant" ON public.ia_conversas
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

-- ----------------------------------------------------------------------------
-- ia_arquivos_temp  (somente autenticado, escopado por tenant)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Usuários autenticados podem ler arquivos" ON public.ia_arquivos_temp;
DROP POLICY IF EXISTS "Usuários autenticados podem inserir arquivos" ON public.ia_arquivos_temp;
DROP POLICY IF EXISTS "Usuários autenticados podem deletar arquivos" ON public.ia_arquivos_temp;

DROP POLICY IF EXISTS "ia_arquivos_temp_select_tenant" ON public.ia_arquivos_temp;
CREATE POLICY "ia_arquivos_temp_select_tenant" ON public.ia_arquivos_temp
    FOR SELECT TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "ia_arquivos_temp_insert_tenant" ON public.ia_arquivos_temp;
CREATE POLICY "ia_arquivos_temp_insert_tenant" ON public.ia_arquivos_temp
    FOR INSERT TO authenticated
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "ia_arquivos_temp_update_tenant" ON public.ia_arquivos_temp;
CREATE POLICY "ia_arquivos_temp_update_tenant" ON public.ia_arquivos_temp
    FOR UPDATE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()))
    WITH CHECK (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

DROP POLICY IF EXISTS "ia_arquivos_temp_delete_tenant" ON public.ia_arquivos_temp;
CREATE POLICY "ia_arquivos_temp_delete_tenant" ON public.ia_arquivos_temp
    FOR DELETE TO authenticated
    USING (estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario()));

COMMIT;

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================
-- RESULTADO:
--   * Verificação garante backfill 100% completo antes de qualquer alteração
--     destrutiva (Req 10.4 / Property 10). Falha => ROLLBACK total.
--   * estabelecimento_id agora é NOT NULL nas 25 Tabelas_de_Dominio (Req 10.6).
--   * Políticas permissivas (USING true) substituídas por políticas por TENANT
--     para o papel `authenticated`, escopadas por fn_estabelecimentos_do_usuario()
--     (Req 5.3, 5.4, 5.6, 5.7 / Properties 1, 2, 4).
--   * Catálogo (produtos, categorias, sabores, tamanhos, adicionais, combos,
--     produto_sabores, combo_produtos) mantém leitura anônima TEMPORÁRIA;
--     pedidos/clientes/avaliacoes mantêm insert anônimo TEMPORÁRIO; avaliacoes
--     mantém leitura anônima de aprovadas. TODAS marcadas para serem escopadas
--     por slug na tarefa 14.4.
--
-- PRÓXIMO PASSO:
--   Tarefas 4.3 (views/funções por tenant), 4.4 (testes de isolamento RLS) e
--   14.x (fluxos públicos por slug, que substituem as políticas anônimas acima).
-- ============================================================================

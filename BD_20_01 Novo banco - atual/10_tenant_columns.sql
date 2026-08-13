-- ============================================================================
-- MULTI-ESTABELECIMENTO: COLUNA estabelecimento_id NAS TABELAS_DE_DOMINIO
-- ============================================================================
-- Arquivo: 10_tenant_columns.sql
-- Descrição: Adiciona a coluna de tenant `estabelecimento_id` (UUID) e o
--            respectivo índice a TODAS as Tabelas_de_Dominio do sistema.
--            A coluna referencia public.estabelecimentos(id).
-- Ordem de execução: APÓS 09b_funcoes_rls.sql (tabelas/funções base já existem)
--                    e APÓS 03b_tables_stock_sales.sql (tabelas stock/sales
--                    precisam existir). Antes da migração de dados (tarefa 4.1)
--                    e da aplicação de NOT NULL + RLS por tenant (tarefa 4.2).
-- Requisitos: 5.1
-- Data: 20/01/2026
-- ============================================================================
-- NOTA IMPORTANTE:
--   Neste passo a coluna `estabelecimento_id` é NULLABLE de propósito. Ela só
--   recebe NOT NULL na tarefa 4.2 (12_tenant_not_null_e_rls.sql), APÓS o
--   backfill da migração de dados (tarefa 4.1 / 11_migracao_dados.sql) garantir
--   que todos os registros pré-existentes têm um estabelecimento atribuído.
--   Adicionar a coluna como NOT NULL aqui quebraria tabelas já populadas.
--
--   Todas as operações usam IF NOT EXISTS para garantir idempotência: o arquivo
--   pode ser re-executado com segurança sem erros nem efeitos colaterais.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Catálogo de produtos
-- ----------------------------------------------------------------------------

-- categorias
ALTER TABLE public.categorias
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_categorias_estabelecimento
    ON public.categorias (estabelecimento_id);

-- produtos
ALTER TABLE public.produtos
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_produtos_estabelecimento
    ON public.produtos (estabelecimento_id);

-- sabores
ALTER TABLE public.sabores
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_sabores_estabelecimento
    ON public.sabores (estabelecimento_id);

-- tamanhos
ALTER TABLE public.tamanhos
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_tamanhos_estabelecimento
    ON public.tamanhos (estabelecimento_id);

-- adicionais
ALTER TABLE public.adicionais
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_adicionais_estabelecimento
    ON public.adicionais (estabelecimento_id);

-- combos
ALTER TABLE public.combos
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_combos_estabelecimento
    ON public.combos (estabelecimento_id);

-- produto_sabores (relacionamento N:N)
ALTER TABLE public.produto_sabores
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_produto_sabores_estabelecimento
    ON public.produto_sabores (estabelecimento_id);

-- combo_produtos (relacionamento N:N)
ALTER TABLE public.combo_produtos
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_combo_produtos_estabelecimento
    ON public.combo_produtos (estabelecimento_id);

-- ----------------------------------------------------------------------------
-- Pedidos e históricos
-- ----------------------------------------------------------------------------

-- pedidos
ALTER TABLE public.pedidos
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_pedidos_estabelecimento
    ON public.pedidos (estabelecimento_id);

-- historico_pedidos
ALTER TABLE public.historico_pedidos
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_historico_pedidos_estabelecimento
    ON public.historico_pedidos (estabelecimento_id);

-- historico_geral
ALTER TABLE public.historico_geral
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_historico_geral_estabelecimento
    ON public.historico_geral (estabelecimento_id);

-- ----------------------------------------------------------------------------
-- Clientes
-- ----------------------------------------------------------------------------

-- clientes
ALTER TABLE public.clientes
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_clientes_estabelecimento
    ON public.clientes (estabelecimento_id);

-- ----------------------------------------------------------------------------
-- Comandas
-- ----------------------------------------------------------------------------

-- comandas
ALTER TABLE public.comandas
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_comandas_estabelecimento
    ON public.comandas (estabelecimento_id);

-- historico_comandas
ALTER TABLE public.historico_comandas
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_historico_comandas_estabelecimento
    ON public.historico_comandas (estabelecimento_id);

-- ----------------------------------------------------------------------------
-- Funcionários
-- ----------------------------------------------------------------------------

-- funcionarios
ALTER TABLE public.funcionarios
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_funcionarios_estabelecimento
    ON public.funcionarios (estabelecimento_id);

-- ----------------------------------------------------------------------------
-- Estoque (legado) e estoque novo (stock_*) + vendas (sales)
-- ----------------------------------------------------------------------------

-- estoque
ALTER TABLE public.estoque
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_estoque_estabelecimento
    ON public.estoque (estabelecimento_id);

-- stock_items
ALTER TABLE public.stock_items
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_stock_items_estabelecimento
    ON public.stock_items (estabelecimento_id);

-- stock_variants
ALTER TABLE public.stock_variants
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_stock_variants_estabelecimento
    ON public.stock_variants (estabelecimento_id);

-- stock_movements
ALTER TABLE public.stock_movements
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_estabelecimento
    ON public.stock_movements (estabelecimento_id);

-- sales
ALTER TABLE public.sales
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_sales_estabelecimento
    ON public.sales (estabelecimento_id);

-- ----------------------------------------------------------------------------
-- Avaliações
-- ----------------------------------------------------------------------------

-- avaliacoes
ALTER TABLE public.avaliacoes
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_estabelecimento
    ON public.avaliacoes (estabelecimento_id);

-- ----------------------------------------------------------------------------
-- Configurações
-- ----------------------------------------------------------------------------

-- configuracoes
ALTER TABLE public.configuracoes
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_configuracoes_estabelecimento
    ON public.configuracoes (estabelecimento_id);

-- ----------------------------------------------------------------------------
-- Assistente de IA
-- ----------------------------------------------------------------------------

-- ia_config
ALTER TABLE public.ia_config
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_ia_config_estabelecimento
    ON public.ia_config (estabelecimento_id);

-- ia_conversas
ALTER TABLE public.ia_conversas
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_ia_conversas_estabelecimento
    ON public.ia_conversas (estabelecimento_id);

-- ia_arquivos_temp
ALTER TABLE public.ia_arquivos_temp
    ADD COLUMN IF NOT EXISTS estabelecimento_id UUID REFERENCES public.estabelecimentos(id);
CREATE INDEX IF NOT EXISTS idx_ia_arquivos_temp_estabelecimento
    ON public.ia_arquivos_temp (estabelecimento_id);

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================
-- Próximos passos da migração:
--   11_migracao_dados.sql        (tarefa 4.1) — cria/reusa Estabelecimento_Padrao
--                                e faz o backfill de estabelecimento_id onde nulo.
--   12_tenant_not_null_e_rls.sql (tarefa 4.2) — aplica NOT NULL após verificação
--                                e substitui as políticas RLS por políticas por tenant.
-- ============================================================================

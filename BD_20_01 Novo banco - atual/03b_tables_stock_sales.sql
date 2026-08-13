-- ============================================================================
-- TABELAS DE ESTOQUE E VENDAS (SCHEMA CANÔNICO CONSOLIDADO)
-- ============================================================================
-- Arquivo: 03b_tables_stock_sales.sql
-- Descrição: Definição canônica e única das tabelas stock_items, stock_variants,
--            stock_movements e sales. Consolida scripts SQL avulsos que estavam
--            espalhados na raiz do projeto e na pasta migrations/ com definições
--            divergentes.
-- Data: 21/01/2026
-- Ordem de execução: APÓS 03_tables.sql (depende de public.produtos e auth.users)
--                    e ANTES de 04_indexes.sql.
-- ============================================================================
--
-- CONTEXTO DA CONSOLIDAÇÃO
-- ----------------------------------------------------------------------------
-- Estas 4 tabelas nunca existiram no schema canônico de "BD_20_01 Novo banco -
-- atual/". Elas foram criadas e alteradas, ao longo do tempo, por scripts soltos
-- com definições CONFLITANTES. As fontes consolidadas aqui são:
--
--   * CRIAR_TABELAS_STOCK_E_SALES.sql ......... (nomenclatura PT-BR)
--   * migrations/add_stock_system.sql ......... (nomenclatura EN)
--   * migrations/add_min_qty_fields.sql ....... (min_qty, reorder_qty)
--   * migrations/add_barcode_support.sql ...... (barcode em stock_variants)
--   * EXECUTAR_MIGRATION_BARCODE.sql .......... (barcode/índices)
--   * migrations/create_sales_table.sql ....... (tabela sales)
--   * EXECUTAR_MIGRATION_SALES.sql ............ (tabela sales)
--   * LIMPAR_ESTOQUE_DUPLICADO.sql ............ (UNIQUE em product_id)
--   * ADICIONAR_PRODUCT_ID_STOCK.sql / ADICIONAR_COLUNA_ATIVO_STOCK.sql / etc.
--
-- DIVERGÊNCIA PT-BR x EN (decisão de consolidação)
-- ----------------------------------------------------------------------------
-- O código vivo usa AS DUAS nomenclaturas, então o schema canônico mantém ambas
-- como um superconjunto coerente, evitando quebrar qualquer caminho de código:
--
--   * src/services/stockService.ts ESCREVE/LÊ as colunas PT-BR:
--       stock_items   -> quantidade, ativo, criado_em, atualizado_em,
--                        product_id, min_qty, reorder_qty
--       stock_variants-> nome, quantidade  (ordena por "nome")
--       stock_movements (INSERT) -> tipo, quantidade, motivo, usuario_id
--   * src/pages/HistoricoMovimentacoes.tsx LÊ com fallback EN -> PT:
--       mov.qty ?? mov.quantidade ; mov.created_at ?? mov.criado_em ; v.label ?? v.nome
--   * A função RPC buscar_por_barcode (usada por PDV/Comandas) LÊ as colunas EN:
--       stock_items.total_qty, stock_items.active, stock_variants.qty, .label
--   * src/services/vendaService.ts usa a tabela sales (nomenclatura EN).
--
-- As colunas PT-BR são as PRIMÁRIAS (caminho de escrita do stockService). As
-- colunas EN são mantidas por COMPATIBILIDADE de leitura (RPC de barcode e telas
-- de histórico). A normalização para uma única nomenclatura é dívida técnica a
-- ser tratada em tarefa futura — NÃO é objetivo desta consolidação.
--
-- IMPORTANTE: este arquivo NÃO adiciona a coluna estabelecimento_id (multi-tenant).
-- Isso é feito na tarefa 3.1 (10_tenant_columns.sql). Aqui consolidamos apenas o
-- schema base existente. As políticas RLS abaixo são "base" (acesso autenticado)
-- e serão substituídas por políticas por tenant na tarefa 4.2.
-- ============================================================================


-- ============================================================================
-- 1. TABELA: stock_items  (itens de estoque, 1 produto = 1 item de estoque)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.stock_items (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Vínculo com o produto (único): src/services/stockService.buscarPorProduto
    product_id    UUID REFERENCES public.produtos(id) ON DELETE CASCADE,

    -- Descrição do item
    nome          VARCHAR,
    descricao     TEXT,
    unidade       VARCHAR DEFAULT 'un',
    preco_custo   NUMERIC,
    fornecedor    VARCHAR,
    categoria     VARCHAR,

    -- Quantidade — coluna PRIMÁRIA escrita por stockService.atualizarQuantidade
    quantidade    NUMERIC DEFAULT 0,

    -- Controle de estoque mínimo / reposição (migrations/add_min_qty_fields.sql)
    min_qty       INTEGER DEFAULT 0,
    reorder_qty   INTEGER DEFAULT 0,

    -- Indicador de ativo — PRIMÁRIO (stockService.buscarTodos filtra por "ativo")
    ativo         BOOLEAN DEFAULT true,

    -- Timestamps PRIMÁRIOS (PT-BR)
    criado_em     TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now(),

    -- --- COMPATIBILIDADE (nomenclatura EN, lida por buscar_por_barcode/RPC) ---
    total_qty     INTEGER DEFAULT 0,
    active        BOOLEAN DEFAULT true,
    created_at    TIMESTAMPTZ DEFAULT now(),
    updated_at    TIMESTAMPTZ DEFAULT now(),

    -- 1 estoque por produto (consolida LIMPAR_ESTOQUE_DUPLICADO.sql)
    CONSTRAINT stock_items_product_id_unique UNIQUE (product_id)
);

COMMENT ON TABLE  public.stock_items                IS 'Controle de estoque por produto (1 produto = 1 item de estoque)';
COMMENT ON COLUMN public.stock_items.product_id     IS 'Produto vinculado (único) - FK produtos(id)';
COMMENT ON COLUMN public.stock_items.quantidade     IS 'PRIMÁRIA: quantidade total em estoque (escrita pelo stockService)';
COMMENT ON COLUMN public.stock_items.ativo          IS 'PRIMÁRIA: item de estoque ativo';
COMMENT ON COLUMN public.stock_items.min_qty        IS 'Quantidade mínima (alerta crítico)';
COMMENT ON COLUMN public.stock_items.reorder_qty    IS 'Quantidade sugerida para reposição/compra';
COMMENT ON COLUMN public.stock_items.total_qty      IS 'COMPAT (EN): espelho de quantidade lido por buscar_por_barcode';
COMMENT ON COLUMN public.stock_items.active         IS 'COMPAT (EN): espelho de ativo lido por buscar_por_barcode';


-- ============================================================================
-- 2. TABELA: stock_variants  (variantes de um item de estoque)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.stock_variants (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_item_id  UUID NOT NULL REFERENCES public.stock_items(id) ON DELETE CASCADE,

    -- PRIMÁRIAS (PT-BR) — stockService ordena por "nome" e escreve "quantidade"
    nome           VARCHAR,
    quantidade     NUMERIC DEFAULT 0,
    criado_em      TIMESTAMPTZ DEFAULT now(),
    atualizado_em  TIMESTAMPTZ DEFAULT now(),

    -- COMPATIBILIDADE (EN) — buscar_por_barcode/HistoricoMovimentacoes
    label          VARCHAR(100),
    qty            INTEGER DEFAULT 0,
    sku            VARCHAR(100),
    barcode        VARCHAR(100),
    created_at     TIMESTAMPTZ DEFAULT now(),
    updated_at     TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE  public.stock_variants               IS 'Variantes de um item de estoque (cor, fragrância, tamanho, etc.)';
COMMENT ON COLUMN public.stock_variants.nome          IS 'PRIMÁRIA (PT-BR): nome da variante';
COMMENT ON COLUMN public.stock_variants.quantidade    IS 'PRIMÁRIA (PT-BR): quantidade da variante';
COMMENT ON COLUMN public.stock_variants.label         IS 'COMPAT (EN): rótulo da variante lido por buscar_por_barcode/PDV';
COMMENT ON COLUMN public.stock_variants.barcode       IS 'Código de barras da variante (EAN-13, EAN-8, UPC, Code128)';

-- Unicidade do rótulo dentro do mesmo item (consolida add_stock_system.sql).
-- Múltiplos NULL são permitidos pelo PostgreSQL, então não conflita com o
-- caminho PT-BR que usa "nome" em vez de "label".
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'public.stock_variants'::regclass
          AND conname  = 'uq_stock_variant_label'
    ) THEN
        ALTER TABLE public.stock_variants
            ADD CONSTRAINT uq_stock_variant_label UNIQUE (stock_item_id, label);
    END IF;
END $$;


-- ============================================================================
-- 3. TABELA: stock_movements  (histórico de movimentações - append only)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.stock_movements (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_item_id  UUID NOT NULL REFERENCES public.stock_items(id) ON DELETE CASCADE,
    variant_id     UUID REFERENCES public.stock_variants(id) ON DELETE SET NULL,

    -- PRIMÁRIAS (PT-BR) — INSERT feito por stockService.registrarMovimento
    tipo           VARCHAR CHECK (tipo IS NULL OR tipo IN ('entrada', 'saida', 'ajuste')),
    quantidade     NUMERIC,
    motivo         TEXT,
    usuario_id     UUID REFERENCES auth.users(id),
    criado_em      TIMESTAMPTZ DEFAULT now(),

    -- COMPATIBILIDADE (EN) — add_stock_system.sql / HistoricoMovimentacoes.tsx
    type           VARCHAR CHECK (type IS NULL OR type IN ('IN', 'OUT', 'ADJUST')),
    qty            INTEGER,
    ref_type       VARCHAR(50),
    ref_id         UUID,
    notes          TEXT,
    created_at     TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE  public.stock_movements            IS 'Histórico (append-only) de movimentações de estoque';
COMMENT ON COLUMN public.stock_movements.tipo       IS 'PRIMÁRIO (PT-BR): entrada | saida | ajuste';
COMMENT ON COLUMN public.stock_movements.quantidade IS 'PRIMÁRIO (PT-BR): quantidade movimentada';
COMMENT ON COLUMN public.stock_movements.type       IS 'COMPAT (EN): IN | OUT | ADJUST';
COMMENT ON COLUMN public.stock_movements.ref_type   IS 'COMPAT (EN): tipo de referência (SALE, PURCHASE, MANUAL)';
COMMENT ON COLUMN public.stock_movements.ref_id     IS 'COMPAT (EN): ID da referência (ex.: id da venda)';


-- ============================================================================
-- 4. TABELA: sales  (vendas do PDV / Delivery)
-- ============================================================================
-- Fonte: migrations/create_sales_table.sql + EXECUTAR_MIGRATION_SALES.sql.
-- Colunas confirmadas em src/services/vendaService.ts.
CREATE TABLE IF NOT EXISTS public.sales (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_number    VARCHAR(50) UNIQUE NOT NULL,
    total_amount   DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('DEBIT', 'CREDIT', 'PIX', 'CASH')),
    needs_change   BOOLEAN DEFAULT false,
    change_amount  DECIMAL(10,2),
    sale_type      VARCHAR(50) DEFAULT 'PDV',
    items          JSONB NOT NULL,
    notes          TEXT,
    created_by     UUID REFERENCES auth.users(id),
    created_at     TIMESTAMPTZ DEFAULT now(),
    updated_at     TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE  public.sales                IS 'Vendas realizadas no PDV e Delivery';
COMMENT ON COLUMN public.sales.sale_number    IS 'Número único da venda (ex.: VENDA-20250126-001)';
COMMENT ON COLUMN public.sales.payment_method IS 'Forma de pagamento: DEBIT, CREDIT, PIX, CASH';
COMMENT ON COLUMN public.sales.sale_type      IS 'Tipo de venda (PDV, DELIVERY, etc.)';
COMMENT ON COLUMN public.sales.items          IS 'Itens da venda em formato JSON';


-- ============================================================================
-- 5. ÍNDICES
-- ============================================================================
-- stock_items
CREATE INDEX IF NOT EXISTS idx_stock_items_product_id ON public.stock_items (product_id);
CREATE INDEX IF NOT EXISTS idx_stock_items_ativo      ON public.stock_items (ativo);
CREATE INDEX IF NOT EXISTS idx_stock_items_criado_em  ON public.stock_items (criado_em DESC);

-- stock_variants
CREATE INDEX IF NOT EXISTS idx_stock_variants_stock_item ON public.stock_variants (stock_item_id);
CREATE INDEX IF NOT EXISTS idx_stock_variants_sku        ON public.stock_variants (sku);
-- barcode único quando preenchido (consolida add_barcode_support.sql)
CREATE UNIQUE INDEX IF NOT EXISTS uq_stock_variants_barcode
    ON public.stock_variants (barcode) WHERE barcode IS NOT NULL;

-- stock_movements
CREATE INDEX IF NOT EXISTS idx_stock_movements_stock_item ON public.stock_movements (stock_item_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_variant    ON public.stock_movements (variant_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_tipo       ON public.stock_movements (tipo);
CREATE INDEX IF NOT EXISTS idx_stock_movements_type       ON public.stock_movements (type);
CREATE INDEX IF NOT EXISTS idx_stock_movements_ref        ON public.stock_movements (ref_type, ref_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_criado_em  ON public.stock_movements (criado_em DESC);

-- sales
CREATE INDEX IF NOT EXISTS idx_sales_sale_number    ON public.sales (sale_number);
CREATE INDEX IF NOT EXISTS idx_sales_created_at     ON public.sales (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_payment_method ON public.sales (payment_method);
CREATE INDEX IF NOT EXISTS idx_sales_created_by     ON public.sales (created_by);


-- ============================================================================
-- 6. TRIGGERS DE TIMESTAMP (atualizado_em / updated_at)
-- ============================================================================
-- Mantém criado_em/atualizado_em (PT) e created_at/updated_at (EN) coerentes.

-- stock_items e stock_variants (possuem ambos os pares de timestamp)
CREATE OR REPLACE FUNCTION public.fn_touch_stock_timestamps()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    NEW.atualizado_em = now();
    NEW.updated_at    = now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stock_items_touch ON public.stock_items;
CREATE TRIGGER trg_stock_items_touch
    BEFORE UPDATE ON public.stock_items
    FOR EACH ROW EXECUTE FUNCTION public.fn_touch_stock_timestamps();

DROP TRIGGER IF EXISTS trg_stock_variants_touch ON public.stock_variants;
CREATE TRIGGER trg_stock_variants_touch
    BEFORE UPDATE ON public.stock_variants
    FOR EACH ROW EXECUTE FUNCTION public.fn_touch_stock_timestamps();

-- sales (possui apenas updated_at)
CREATE OR REPLACE FUNCTION public.fn_touch_sales_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sales_touch ON public.sales;
CREATE TRIGGER trg_sales_touch
    BEFORE UPDATE ON public.sales
    FOR EACH ROW EXECUTE FUNCTION public.fn_touch_sales_updated_at();


-- ============================================================================
-- 7. RLS BASE (acesso autenticado)
-- ============================================================================
-- Estas políticas são a BASE pré-multi-tenant. Permitem acesso a qualquer
-- usuário autenticado, consistente com o comportamento single-tenant atual.
-- Serão SUBSTITUÍDAS por políticas por estabelecimento na tarefa 4.2
-- (12_tenant_not_null_e_rls.sql), após a coluna estabelecimento_id existir.

ALTER TABLE public.stock_items     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_variants  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales           ENABLE ROW LEVEL SECURITY;

-- ---- stock_items ----
DROP POLICY IF EXISTS "stock_items_select_auth" ON public.stock_items;
CREATE POLICY "stock_items_select_auth" ON public.stock_items
    FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "stock_items_insert_auth" ON public.stock_items;
CREATE POLICY "stock_items_insert_auth" ON public.stock_items
    FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "stock_items_update_auth" ON public.stock_items;
CREATE POLICY "stock_items_update_auth" ON public.stock_items
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "stock_items_delete_auth" ON public.stock_items;
CREATE POLICY "stock_items_delete_auth" ON public.stock_items
    FOR DELETE TO authenticated USING (true);

-- ---- stock_variants ----
DROP POLICY IF EXISTS "stock_variants_select_auth" ON public.stock_variants;
CREATE POLICY "stock_variants_select_auth" ON public.stock_variants
    FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "stock_variants_insert_auth" ON public.stock_variants;
CREATE POLICY "stock_variants_insert_auth" ON public.stock_variants
    FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "stock_variants_update_auth" ON public.stock_variants;
CREATE POLICY "stock_variants_update_auth" ON public.stock_variants
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "stock_variants_delete_auth" ON public.stock_variants;
CREATE POLICY "stock_variants_delete_auth" ON public.stock_variants
    FOR DELETE TO authenticated USING (true);

-- ---- stock_movements ----
DROP POLICY IF EXISTS "stock_movements_select_auth" ON public.stock_movements;
CREATE POLICY "stock_movements_select_auth" ON public.stock_movements
    FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "stock_movements_insert_auth" ON public.stock_movements;
CREATE POLICY "stock_movements_insert_auth" ON public.stock_movements
    FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "stock_movements_update_auth" ON public.stock_movements;
CREATE POLICY "stock_movements_update_auth" ON public.stock_movements
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "stock_movements_delete_auth" ON public.stock_movements;
CREATE POLICY "stock_movements_delete_auth" ON public.stock_movements
    FOR DELETE TO authenticated USING (true);

-- ---- sales ----
DROP POLICY IF EXISTS "sales_select_auth" ON public.sales;
CREATE POLICY "sales_select_auth" ON public.sales
    FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "sales_insert_auth" ON public.sales;
CREATE POLICY "sales_insert_auth" ON public.sales
    FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "sales_update_auth" ON public.sales;
CREATE POLICY "sales_update_auth" ON public.sales
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
-- (sem DELETE em sales: vendas são preservadas)

-- ============================================================================
-- FIM — 03b_tables_stock_sales.sql
-- ============================================================================

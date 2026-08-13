-- ============================================================================
-- CORRIGIR TABELA sales (PDV) - alinhar com o schema esperado pelo app
-- ============================================================================
-- Sintoma: "Could not find the 'change_amount' column of 'sales' in the schema cache"
-- Causa: a tabela 'sales' foi criada com schema antigo/minimo
--        (id, pedido_id, total, forma_pagamento, criado_em), faltando as colunas
--        usadas pelo PDV. Alem disso 'total NOT NULL' bloqueia o insert do app.
-- Este script e idempotente e NAO apaga dados. Rode no SQL Editor do Supabase.
-- ============================================================================

-- 1. Adicionar as colunas esperadas pelo app (se ainda nao existirem)
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS sale_number   VARCHAR(50);
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS total_amount  DECIMAL(10,2);
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20);
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS needs_change  BOOLEAN DEFAULT false;
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS change_amount DECIMAL(10,2);
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS sale_type     VARCHAR(50) DEFAULT 'PDV';
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS items         JSONB;
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS notes         TEXT;
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS created_by    UUID;
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS created_at    TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS updated_at    TIMESTAMPTZ DEFAULT NOW();

-- 2. Remover restricoes NOT NULL de colunas antigas que travam o insert do app
--    (o app nao envia 'total' nem 'forma_pagamento')
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema='public' AND table_name='sales' AND column_name='total') THEN
    ALTER TABLE public.sales ALTER COLUMN total DROP NOT NULL;
  END IF;
END $$;

-- 3. Garantir unicidade de sale_number (usado como identificador da venda)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.sales'::regclass
      AND contype = 'u'
      AND conname = 'sales_sale_number_key'
  ) THEN
    ALTER TABLE public.sales ADD CONSTRAINT sales_sale_number_key UNIQUE (sale_number);
  END IF;
END $$;

-- 4. Indices de performance
CREATE INDEX IF NOT EXISTS idx_sales_sale_number   ON public.sales(sale_number);
CREATE INDEX IF NOT EXISTS idx_sales_created_at     ON public.sales(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_payment_method ON public.sales(payment_method);
CREATE INDEX IF NOT EXISTS idx_sales_created_by     ON public.sales(created_by);

-- 5. Trigger para manter updated_at
CREATE OR REPLACE FUNCTION update_sales_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_sales_updated_at ON public.sales;
CREATE TRIGGER trigger_update_sales_updated_at
    BEFORE UPDATE ON public.sales
    FOR EACH ROW
    EXECUTE FUNCTION update_sales_updated_at();

-- 6. RLS: permitir insert/select/update para usuarios autenticados
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios autenticados podem inserir vendas" ON public.sales;
CREATE POLICY "Usuarios autenticados podem inserir vendas"
    ON public.sales FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Usuarios autenticados podem visualizar vendas" ON public.sales;
CREATE POLICY "Usuarios autenticados podem visualizar vendas"
    ON public.sales FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Usuarios autenticados podem atualizar vendas" ON public.sales;
CREATE POLICY "Usuarios autenticados podem atualizar vendas"
    ON public.sales FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- 7. Forcar o PostgREST a recarregar o cache de schema
NOTIFY pgrst, 'reload schema';

-- 8. Conferir o resultado
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'sales'
ORDER BY ordinal_position;

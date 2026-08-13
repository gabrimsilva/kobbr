-- =====================================================
-- EXECUTAR ESTA MIGRATION NO SUPABASE SQL EDITOR
-- =====================================================
-- 
-- INSTRUÇÕES:
-- 1. Abra o Supabase Dashboard
-- 2. Vá em "SQL Editor"
-- 3. Copie e cole TODO este conteúdo
-- 4. Clique em "Run" para executar
--
-- =====================================================

-- Criar tabela sales
CREATE TABLE IF NOT EXISTS public.sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_number VARCHAR(50) UNIQUE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('DEBIT', 'CREDIT', 'PIX', 'CASH')),
    needs_change BOOLEAN DEFAULT false,
    change_amount DECIMAL(10,2),
    sale_type VARCHAR(50) DEFAULT 'PDV',
    items JSONB NOT NULL,
    notes TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_sales_sale_number ON public.sales(sale_number);
CREATE INDEX IF NOT EXISTS idx_sales_created_at ON public.sales(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_payment_method ON public.sales(payment_method);
CREATE INDEX IF NOT EXISTS idx_sales_created_by ON public.sales(created_by);

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_sales_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_sales_updated_at
    BEFORE UPDATE ON public.sales
    FOR EACH ROW
    EXECUTE FUNCTION update_sales_updated_at();

-- RLS Policies
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;

-- Policy: Usuários autenticados podem inserir vendas
CREATE POLICY "Usuários autenticados podem inserir vendas"
    ON public.sales
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policy: Usuários autenticados podem visualizar vendas
CREATE POLICY "Usuários autenticados podem visualizar vendas"
    ON public.sales
    FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Apenas o criador pode atualizar (se necessário)
CREATE POLICY "Apenas criador pode atualizar venda"
    ON public.sales
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = created_by);

-- Comentários
COMMENT ON TABLE public.sales IS 'Tabela de vendas realizadas no PDV';
COMMENT ON COLUMN public.sales.sale_number IS 'Número único da venda (ex: VENDA-20250126-001)';
COMMENT ON COLUMN public.sales.total_amount IS 'Valor total da venda';
COMMENT ON COLUMN public.sales.payment_method IS 'Forma de pagamento: DEBIT, CREDIT, PIX, CASH';
COMMENT ON COLUMN public.sales.needs_change IS 'Se o cliente precisa de troco';
COMMENT ON COLUMN public.sales.change_amount IS 'Valor para o qual precisa de troco';
COMMENT ON COLUMN public.sales.sale_type IS 'Tipo de venda (PDV, DELIVERY, etc)';
COMMENT ON COLUMN public.sales.items IS 'Itens da venda em formato JSON';
COMMENT ON COLUMN public.sales.notes IS 'Observações da venda';
COMMENT ON COLUMN public.sales.created_by IS 'Usuário que criou a venda';

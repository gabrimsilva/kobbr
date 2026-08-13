-- =====================================================
-- ETAPA 1: Adicionar campos de cupom na tabela sales
-- Armazena HTML do cupom e data de impressão
-- =====================================================

-- Adicionar coluna receipt_html (HTML do cupom fiscal)
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS receipt_html TEXT;

-- Adicionar coluna printed_at (data/hora da primeira impressão)
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS printed_at TIMESTAMP WITH TIME ZONE;

-- Criar índice para consultas de vendas impressas
CREATE INDEX IF NOT EXISTS idx_sales_printed_at ON sales(printed_at);

-- Comentários para documentação
COMMENT ON COLUMN sales.receipt_html IS 'HTML do cupom fiscal gerado para esta venda';
COMMENT ON COLUMN sales.printed_at IS 'Data e hora da primeira impressão do cupom';

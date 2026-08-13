-- =====================================================
-- ETAPA 1: Adicionar campos de cupom na tabela pedidos
-- Armazena HTML do cupom e data de impressão
-- =====================================================

-- Adicionar coluna receipt_html (HTML do cupom/recibo do pedido)
ALTER TABLE pedidos 
ADD COLUMN IF NOT EXISTS receipt_html TEXT;

-- Adicionar coluna printed_at (data/hora da primeira impressão)
ALTER TABLE pedidos 
ADD COLUMN IF NOT EXISTS printed_at TIMESTAMP WITH TIME ZONE;

-- Criar índice para consultas de pedidos impressos
CREATE INDEX IF NOT EXISTS idx_pedidos_printed_at ON pedidos(printed_at);

-- Comentários para documentação
COMMENT ON COLUMN pedidos.receipt_html IS 'HTML do cupom/recibo gerado para este pedido';
COMMENT ON COLUMN pedidos.printed_at IS 'Data e hora da primeira impressão do cupom';

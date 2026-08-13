-- =====================================================
-- ETAPA 1: Criar tabela print_jobs
-- Gerencia jobs de impressão (vendas e pedidos)
-- =====================================================

-- Criar tabela print_jobs
CREATE TABLE IF NOT EXISTS print_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ref_type VARCHAR(30) NOT NULL CHECK (ref_type IN ('SALE', 'ORDER')),
  ref_id UUID NOT NULL,
  printer_name VARCHAR(120),
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SENT', 'PRINTED', 'FAILED', 'CANCELED')),
  attempts INT NOT NULL DEFAULT 0,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_print_jobs_ref ON print_jobs(ref_type, ref_id);
CREATE INDEX IF NOT EXISTS idx_print_jobs_status ON print_jobs(status);
CREATE INDEX IF NOT EXISTS idx_print_jobs_created_at ON print_jobs(created_at DESC);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_print_jobs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_print_jobs_updated_at
  BEFORE UPDATE ON print_jobs
  FOR EACH ROW
  EXECUTE FUNCTION update_print_jobs_updated_at();

-- Comentários para documentação
COMMENT ON TABLE print_jobs IS 'Gerencia jobs de impressão de cupons fiscais (vendas e pedidos)';
COMMENT ON COLUMN print_jobs.ref_type IS 'Tipo de referência: SALE (venda PDV) ou ORDER (pedido delivery)';
COMMENT ON COLUMN print_jobs.ref_id IS 'ID da venda ou pedido';
COMMENT ON COLUMN print_jobs.printer_name IS 'Nome da impressora utilizada';
COMMENT ON COLUMN print_jobs.status IS 'Status do job: PENDING, SENT, PRINTED, FAILED, CANCELED';
COMMENT ON COLUMN print_jobs.attempts IS 'Número de tentativas de impressão';
COMMENT ON COLUMN print_jobs.error_message IS 'Mensagem de erro caso falhe';

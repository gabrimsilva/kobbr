-- ============================================
-- EXECUTAR NO SUPABASE SQL EDITOR
-- ============================================
-- ETAPA 5: Criar tabela de solicitações de reposição
-- ============================================

-- Criar ENUM para status de solicitação
CREATE TYPE restock_status AS ENUM (
  'OPEN',      -- Solicitação aberta (aguardando pedido)
  'ORDERED',   -- Pedido realizado ao fornecedor
  'RECEIVED',  -- Mercadoria recebida
  'CANCELED'   -- Solicitação cancelada
);

-- Criar tabela de solicitações de reposição
CREATE TABLE IF NOT EXISTS restock_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stock_item_id UUID NOT NULL REFERENCES stock_items(id) ON DELETE CASCADE,
  suggested_qty INT NOT NULL CHECK (suggested_qty > 0),
  status restock_status NOT NULL DEFAULT 'OPEN',
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Criar índices
CREATE INDEX idx_restock_requests_stock_item_id ON restock_requests(stock_item_id);
CREATE INDEX idx_restock_requests_status ON restock_requests(status);
CREATE INDEX idx_restock_requests_created_at ON restock_requests(created_at DESC);
CREATE INDEX idx_restock_requests_stock_item_status ON restock_requests(stock_item_id, status);

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_restock_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_restock_requests_updated_at
  BEFORE UPDATE ON restock_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_restock_requests_updated_at();

-- RLS (Row Level Security)
ALTER TABLE restock_requests ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Permitir leitura de solicitações de reposição"
  ON restock_requests FOR SELECT USING (true);

CREATE POLICY "Permitir criação de solicitações de reposição"
  ON restock_requests FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Permitir atualização de solicitações de reposição"
  ON restock_requests FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Permitir exclusão de solicitações de reposição"
  ON restock_requests FOR DELETE USING (auth.uid() IS NOT NULL);

-- ============================================
-- VERIFICAÇÃO
-- ============================================
-- Após executar, rode este comando para verificar:
-- SELECT * FROM restock_requests LIMIT 5;

-- ============================================
-- MIGRATION: Criar tabela de solicitações de reposição
-- ============================================
-- Descrição: Sistema de solicitação de reposição de estoque
-- Data: 27/02/2026
-- Autor: Sistema
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
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Índices para performance
  CONSTRAINT restock_requests_stock_item_id_fkey FOREIGN KEY (stock_item_id) REFERENCES stock_items(id) ON DELETE CASCADE
);

-- Criar índices
CREATE INDEX idx_restock_requests_stock_item_id ON restock_requests(stock_item_id);
CREATE INDEX idx_restock_requests_status ON restock_requests(status);
CREATE INDEX idx_restock_requests_created_at ON restock_requests(created_at DESC);

-- Criar índice composto para buscar solicitações abertas por produto
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

-- Comentários
COMMENT ON TABLE restock_requests IS 'Solicitações de reposição de estoque';
COMMENT ON COLUMN restock_requests.id IS 'ID único da solicitação';
COMMENT ON COLUMN restock_requests.stock_item_id IS 'Referência ao item de estoque';
COMMENT ON COLUMN restock_requests.suggested_qty IS 'Quantidade sugerida para reposição';
COMMENT ON COLUMN restock_requests.status IS 'Status da solicitação (OPEN, ORDERED, RECEIVED, CANCELED)';
COMMENT ON COLUMN restock_requests.notes IS 'Observações sobre a solicitação';
COMMENT ON COLUMN restock_requests.created_by IS 'Usuário que criou a solicitação';
COMMENT ON COLUMN restock_requests.created_at IS 'Data de criação';
COMMENT ON COLUMN restock_requests.updated_at IS 'Data da última atualização';

-- RLS (Row Level Security)
ALTER TABLE restock_requests ENABLE ROW LEVEL SECURITY;

-- Policy: Todos podem visualizar
CREATE POLICY "Permitir leitura de solicitações de reposição"
  ON restock_requests
  FOR SELECT
  USING (true);

-- Policy: Apenas autenticados podem criar
CREATE POLICY "Permitir criação de solicitações de reposição"
  ON restock_requests
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Policy: Apenas autenticados podem atualizar
CREATE POLICY "Permitir atualização de solicitações de reposição"
  ON restock_requests
  FOR UPDATE
  USING (auth.uid() IS NOT NULL);

-- Policy: Apenas autenticados podem deletar
CREATE POLICY "Permitir exclusão de solicitações de reposição"
  ON restock_requests
  FOR DELETE
  USING (auth.uid() IS NOT NULL);

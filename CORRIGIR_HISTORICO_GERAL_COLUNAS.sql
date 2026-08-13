-- ============================================================================
-- ALINHAR SCHEMA DE historico_geral COM O QUE O APP ENVIA
-- ============================================================================
-- Problema: ao clicar em "Zerar Pedidos", nenhum pedido era movido (0 movidos)
-- e os pedidos voltavam ao Kanban. Causa: a tabela historico_geral em producao
-- estava SEM as colunas abaixo, entao o INSERT falhava (400) para todos os
-- pedidos. Esta migration adiciona as colunas faltantes (idempotente).
-- Rode no SQL Editor do Supabase.
-- ============================================================================

ALTER TABLE public.historico_geral
  ADD COLUMN IF NOT EXISTS taxa_extra_km NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tipo_desconto TEXT DEFAULT 'valor',
  ADD COLUMN IF NOT EXISTS forma_pagamento_dividido BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS pagamento_1_tipo TEXT,
  ADD COLUMN IF NOT EXISTS pagamento_1_valor NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS pagamento_2_tipo TEXT,
  ADD COLUMN IF NOT EXISTS pagamento_2_valor NUMERIC(10,2);

-- Conferir as colunas resultantes
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'historico_geral'
ORDER BY ordinal_position;

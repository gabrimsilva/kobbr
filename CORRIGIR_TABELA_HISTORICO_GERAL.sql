-- ============================================================================
-- CORRIGIR TABELA historico_geral - adicionar colunas usadas ao "Zerar Pedidos"
-- ============================================================================
-- Sintoma: "Could not find the 'forma_pagamento_dividido' column of
--          'historico_geral' in the schema cache"
-- Causa: a tabela foi criada sem as colunas mais novas (pagamento dividido e
--        desconto), que o app envia ao mover pedidos para o histórico.
-- Idempotente e NÃO apaga dados. Rode no SQL Editor do Supabase.
-- ============================================================================

-- Colunas de pagamento dividido
ALTER TABLE public.historico_geral ADD COLUMN IF NOT EXISTS forma_pagamento_dividido BOOLEAN DEFAULT false;
ALTER TABLE public.historico_geral ADD COLUMN IF NOT EXISTS pagamento_1_tipo  TEXT;
ALTER TABLE public.historico_geral ADD COLUMN IF NOT EXISTS pagamento_1_valor NUMERIC(10,2);
ALTER TABLE public.historico_geral ADD COLUMN IF NOT EXISTS pagamento_2_tipo  TEXT;
ALTER TABLE public.historico_geral ADD COLUMN IF NOT EXISTS pagamento_2_valor NUMERIC(10,2);

-- Colunas de desconto / taxas (também enviadas pelo app)
ALTER TABLE public.historico_geral ADD COLUMN IF NOT EXISTS desconto      NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.historico_geral ADD COLUMN IF NOT EXISTS tipo_desconto TEXT DEFAULT 'valor';
ALTER TABLE public.historico_geral ADD COLUMN IF NOT EXISTS taxa_extra_km NUMERIC(10,2) DEFAULT 0;

-- Garantir as demais colunas que o app envia (caso a tabela seja muito antiga)
ALTER TABLE public.historico_geral ADD COLUMN IF NOT EXISTS movido_em TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.historico_geral ADD COLUMN IF NOT EXISTS taxa_entrega NUMERIC(10,2);
ALTER TABLE public.historico_geral ADD COLUMN IF NOT EXISTS precisa_troco BOOLEAN DEFAULT false;
ALTER TABLE public.historico_geral ADD COLUMN IF NOT EXISTS valor_troco NUMERIC(10,2);

-- Forçar o PostgREST a recarregar o cache de schema
NOTIFY pgrst, 'reload schema';

-- Conferir o resultado
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'historico_geral'
ORDER BY ordinal_position;

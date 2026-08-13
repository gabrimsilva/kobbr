-- ============================================================================
-- ATIVAR MÓDULO DE COMANDAS (tabelas, colunas, RLS e realtime)
-- ============================================================================
-- Garante que 'comandas' e 'historico_comandas' tenham todas as colunas usadas
-- pelo app (gestão de comandas + baixa de estoque + pagamento dividido).
-- Idempotente e NÃO apaga dados. Rode no SQL Editor do Supabase.
-- ============================================================================

-- 1. Criar tabelas se não existirem (schema completo)
CREATE TABLE IF NOT EXISTS public.comandas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_comanda INTEGER NOT NULL,
    itens JSONB NOT NULL DEFAULT '[]'::jsonb,
    subtotal NUMERIC(10,2) DEFAULT 0,
    total NUMERIC(10,2) DEFAULT 0,
    desconto NUMERIC(10,2) DEFAULT 0,
    tipo_desconto TEXT DEFAULT 'valor',
    status TEXT DEFAULT 'aberta',
    forma_pagamento TEXT,
    observacoes TEXT,
    criado_por UUID,
    finalizado_por UUID,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now(),
    finalizado_em TIMESTAMPTZ,
    forma_pagamento_dividido BOOLEAN DEFAULT false,
    pagamento_1_tipo TEXT,
    pagamento_1_valor NUMERIC(10,2),
    pagamento_2_tipo TEXT,
    pagamento_2_valor NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS public.historico_comandas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_comanda INTEGER NOT NULL,
    itens JSONB NOT NULL DEFAULT '[]'::jsonb,
    subtotal NUMERIC(10,2) DEFAULT 0,
    total NUMERIC(10,2) DEFAULT 0,
    desconto NUMERIC(10,2) DEFAULT 0,
    tipo_desconto TEXT DEFAULT 'valor',
    forma_pagamento TEXT,
    observacoes TEXT,
    criado_por UUID,
    finalizado_por UUID,
    criado_em TIMESTAMPTZ DEFAULT now(),
    finalizado_em TIMESTAMPTZ DEFAULT now(),
    forma_pagamento_dividido BOOLEAN DEFAULT false,
    pagamento_1_tipo TEXT,
    pagamento_1_valor NUMERIC(10,2),
    pagamento_2_tipo TEXT,
    pagamento_2_valor NUMERIC(10,2)
);

-- 2. Garantir colunas em tabelas já existentes (idempotente)
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS itens JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS subtotal NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS total NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS desconto NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS tipo_desconto TEXT DEFAULT 'valor';
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'aberta';
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS forma_pagamento TEXT;
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS observacoes TEXT;
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS criado_por UUID;
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS finalizado_por UUID;
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS criado_em TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS atualizado_em TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS finalizado_em TIMESTAMPTZ;
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS forma_pagamento_dividido BOOLEAN DEFAULT false;
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS pagamento_1_tipo TEXT;
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS pagamento_1_valor NUMERIC(10,2);
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS pagamento_2_tipo TEXT;
ALTER TABLE public.comandas ADD COLUMN IF NOT EXISTS pagamento_2_valor NUMERIC(10,2);

ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS itens JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS subtotal NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS total NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS desconto NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS tipo_desconto TEXT DEFAULT 'valor';
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS forma_pagamento TEXT;
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS observacoes TEXT;
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS criado_por UUID;
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS finalizado_por UUID;
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS criado_em TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS finalizado_em TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS forma_pagamento_dividido BOOLEAN DEFAULT false;
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS pagamento_1_tipo TEXT;
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS pagamento_1_valor NUMERIC(10,2);
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS pagamento_2_tipo TEXT;
ALTER TABLE public.historico_comandas ADD COLUMN IF NOT EXISTS pagamento_2_valor NUMERIC(10,2);

-- 3. Índices úteis
CREATE INDEX IF NOT EXISTS idx_comandas_status ON public.comandas(status);
CREATE INDEX IF NOT EXISTS idx_comandas_numero ON public.comandas(numero_comanda);
CREATE INDEX IF NOT EXISTS idx_historico_comandas_numero ON public.historico_comandas(numero_comanda);

-- 4. RLS (acesso para usuários autenticados - admin/garçom/atendente)
ALTER TABLE public.comandas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_comandas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Comandas acesso autenticado" ON public.comandas;
CREATE POLICY "Comandas acesso autenticado"
    ON public.comandas FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Historico comandas acesso autenticado" ON public.historico_comandas;
CREATE POLICY "Historico comandas acesso autenticado"
    ON public.historico_comandas FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 5. Realtime (gestão de comandas em tempo real)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename='comandas'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.comandas;
  END IF;
END $$;

ALTER TABLE public.comandas REPLICA IDENTITY FULL;

-- 6. Recarregar cache do PostgREST
NOTIFY pgrst, 'reload schema';

-- 7. Conferência
SELECT 'comandas' AS tabela, count(*) AS colunas
FROM information_schema.columns WHERE table_schema='public' AND table_name='comandas'
UNION ALL
SELECT 'historico_comandas', count(*)
FROM information_schema.columns WHERE table_schema='public' AND table_name='historico_comandas';

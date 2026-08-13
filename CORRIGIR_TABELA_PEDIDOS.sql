-- ============================================================================
-- CORRIGIR TABELA pedidos - adicionar colunas usadas no checkout (delivery/PDV)
-- ============================================================================
-- Sintoma: "Could not find the 'cliente_bairro' column of 'pedidos' in the schema cache"
-- Causa: a tabela 'pedidos' foi criada com schema antigo, sem as colunas de
--        endereço do cliente, desconto e pagamento dividido que o app envia.
-- Idempotente e NÃO apaga dados. Rode no SQL Editor do Supabase.
-- ============================================================================

-- Dados do cliente (endereço/contato)
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_nome        VARCHAR;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_sobrenome   VARCHAR;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_cpf         VARCHAR;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_telefone    VARCHAR;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_email       VARCHAR;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_cep         VARCHAR;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_endereco    VARCHAR;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_numero      VARCHAR;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_complemento VARCHAR;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_bairro      VARCHAR;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_cidade      VARCHAR;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_estado      VARCHAR;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS cliente_id          UUID;

-- Entrega / pagamento
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS entrega_domicilio BOOLEAN DEFAULT false;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS forma_pagamento   TEXT;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS precisa_troco     BOOLEAN DEFAULT false;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS valor_troco       NUMERIC(10,2);
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS previsao_entrega  TEXT;

-- Valores
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS subtotal      NUMERIC(10,2);
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS taxa_entrega  NUMERIC(10,2);
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS taxa_extra_km NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS total         NUMERIC(10,2);
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS desconto      NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS tipo_desconto TEXT DEFAULT 'valor';

-- Pagamento dividido
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS forma_pagamento_dividido BOOLEAN DEFAULT false;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS pagamento_1_tipo  TEXT;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS pagamento_1_valor NUMERIC(10,2);
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS pagamento_2_tipo  TEXT;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS pagamento_2_valor NUMERIC(10,2);

-- Demais campos esperados
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS observacoes  TEXT;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS itens        JSONB;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS status       TEXT DEFAULT 'Pedido criado';
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS codigo_pedido TEXT;
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS criado_em    TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.pedidos ADD COLUMN IF NOT EXISTS atualizado_em TIMESTAMPTZ DEFAULT now();

-- Forçar o PostgREST a recarregar o cache de schema
NOTIFY pgrst, 'reload schema';

-- Conferir resultado
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'pedidos'
ORDER BY ordinal_position;

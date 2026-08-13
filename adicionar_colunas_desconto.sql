-- ============================================================================
-- ADICIONAR COLUNAS DE DESCONTO
-- ============================================================================
-- Arquivo: adicionar_colunas_desconto.sql
-- Descrição: Adiciona colunas de desconto nas tabelas que estão faltando
-- Data: 31/01/2026
-- ============================================================================

-- IMPORTANTE: Execute este script no banco de dados de produção via Supabase Dashboard
-- Vá em: Database > SQL Editor > Cole este código > Run

-- 1. TABELA PEDIDOS
-- Adicionar coluna desconto na tabela pedidos
ALTER TABLE public.pedidos 
ADD COLUMN IF NOT EXISTS desconto NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0);

-- Adicionar coluna tipo_desconto na tabela pedidos  
ALTER TABLE public.pedidos 
ADD COLUMN IF NOT EXISTS tipo_desconto TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual'));

-- Adicionar colunas de pagamento dividido na tabela pedidos
ALTER TABLE public.pedidos 
ADD COLUMN IF NOT EXISTS forma_pagamento_dividido BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.pedidos 
ADD COLUMN IF NOT EXISTS pagamento_1_tipo TEXT;

ALTER TABLE public.pedidos 
ADD COLUMN IF NOT EXISTS pagamento_1_valor NUMERIC(10, 2);

ALTER TABLE public.pedidos 
ADD COLUMN IF NOT EXISTS pagamento_2_tipo TEXT;

ALTER TABLE public.pedidos 
ADD COLUMN IF NOT EXISTS pagamento_2_valor NUMERIC(10, 2);

-- 2. TABELA HISTORICO_PEDIDOS
-- Adicionar coluna desconto na tabela historico_pedidos
ALTER TABLE public.historico_pedidos 
ADD COLUMN IF NOT EXISTS desconto NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0);

-- Adicionar coluna tipo_desconto na tabela historico_pedidos  
ALTER TABLE public.historico_pedidos 
ADD COLUMN IF NOT EXISTS tipo_desconto TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual'));

-- Adicionar colunas de pagamento dividido na tabela historico_pedidos
ALTER TABLE public.historico_pedidos 
ADD COLUMN IF NOT EXISTS forma_pagamento_dividido BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.historico_pedidos 
ADD COLUMN IF NOT EXISTS pagamento_1_tipo TEXT;

ALTER TABLE public.historico_pedidos 
ADD COLUMN IF NOT EXISTS pagamento_1_valor NUMERIC(10, 2);

ALTER TABLE public.historico_pedidos 
ADD COLUMN IF NOT EXISTS pagamento_2_tipo TEXT;

ALTER TABLE public.historico_pedidos 
ADD COLUMN IF NOT EXISTS pagamento_2_valor NUMERIC(10, 2);

-- 3. TABELA COMANDAS (já deve ter, mas garantindo)
-- Adicionar coluna desconto na tabela comandas
ALTER TABLE public.comandas 
ADD COLUMN IF NOT EXISTS desconto NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0);

-- Adicionar coluna tipo_desconto na tabela comandas  
ALTER TABLE public.comandas 
ADD COLUMN IF NOT EXISTS tipo_desconto TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual'));

-- 4. TABELA HISTORICO_COMANDAS (já deve ter, mas garantindo)
-- Adicionar coluna desconto na tabela historico_comandas
ALTER TABLE public.historico_comandas 
ADD COLUMN IF NOT EXISTS desconto NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0);

-- Adicionar coluna tipo_desconto na tabela historico_comandas  
ALTER TABLE public.historico_comandas 
ADD COLUMN IF NOT EXISTS tipo_desconto TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual'));

-- 5. CONSTRAINTS DE PAGAMENTO DIVIDIDO
-- Adicionar constraints para pagamento dividido na tabela pedidos
DO $$ 
BEGIN
    -- Verificar se a constraint já existe antes de adicionar
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'pedidos_pagamento_tipos_diferentes' 
        AND table_name = 'pedidos'
    ) THEN
        ALTER TABLE public.pedidos 
        ADD CONSTRAINT pedidos_pagamento_tipos_diferentes CHECK (
            NOT forma_pagamento_dividido OR 
            (pagamento_1_tipo IS NOT NULL AND pagamento_2_tipo IS NOT NULL AND pagamento_1_tipo != pagamento_2_tipo)
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'pedidos_pagamento_valores_positivos' 
        AND table_name = 'pedidos'
    ) THEN
        ALTER TABLE public.pedidos 
        ADD CONSTRAINT pedidos_pagamento_valores_positivos CHECK (
            NOT forma_pagamento_dividido OR 
            (pagamento_1_valor > 0 AND pagamento_2_valor > 0)
        );
    END IF;
END $$;

-- 6. COMENTÁRIOS PARA DOCUMENTAÇÃO
-- Comentários para tabela pedidos
COMMENT ON COLUMN public.pedidos.desconto IS 'Valor do desconto aplicado. Se tipo_desconto=valor, representa R$. Se tipo_desconto=percentual, representa %';
COMMENT ON COLUMN public.pedidos.tipo_desconto IS 'Tipo do desconto: valor (R$) ou percentual (%)';
COMMENT ON COLUMN public.pedidos.forma_pagamento_dividido IS 'Indica se o pagamento foi dividido entre duas formas de pagamento diferentes';
COMMENT ON COLUMN public.pedidos.pagamento_1_tipo IS 'Tipo da primeira forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.pedidos.pagamento_1_valor IS 'Valor pago com a primeira forma de pagamento';
COMMENT ON COLUMN public.pedidos.pagamento_2_tipo IS 'Tipo da segunda forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.pedidos.pagamento_2_valor IS 'Valor pago com a segunda forma de pagamento';

-- Comentários para tabela historico_pedidos
COMMENT ON COLUMN public.historico_pedidos.desconto IS 'Valor do desconto aplicado. Se tipo_desconto=valor, representa R$. Se tipo_desconto=percentual, representa %';
COMMENT ON COLUMN public.historico_pedidos.tipo_desconto IS 'Tipo do desconto: valor (R$) ou percentual (%)';
COMMENT ON COLUMN public.historico_pedidos.forma_pagamento_dividido IS 'Indica se o pagamento foi dividido entre duas formas de pagamento diferentes';
COMMENT ON COLUMN public.historico_pedidos.pagamento_1_tipo IS 'Tipo da primeira forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.historico_pedidos.pagamento_1_valor IS 'Valor pago com a primeira forma de pagamento';
COMMENT ON COLUMN public.historico_pedidos.pagamento_2_tipo IS 'Tipo da segunda forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.historico_pedidos.pagamento_2_valor IS 'Valor pago com a segunda forma de pagamento';

-- 7. VERIFICAÇÃO FINAL
-- Verificar se as colunas foram criadas em todas as tabelas
SELECT 
    'pedidos' as tabela,
    column_name, 
    data_type, 
    is_nullable, 
    column_default 
FROM information_schema.columns 
WHERE table_name = 'pedidos' 
AND column_name IN ('desconto', 'tipo_desconto', 'forma_pagamento_dividido', 'pagamento_1_tipo', 'pagamento_1_valor', 'pagamento_2_tipo', 'pagamento_2_valor')

UNION ALL

SELECT 
    'historico_pedidos' as tabela,
    column_name, 
    data_type, 
    is_nullable, 
    column_default 
FROM information_schema.columns 
WHERE table_name = 'historico_pedidos' 
AND column_name IN ('desconto', 'tipo_desconto', 'forma_pagamento_dividido', 'pagamento_1_tipo', 'pagamento_1_valor', 'pagamento_2_tipo', 'pagamento_2_valor')

UNION ALL

SELECT 
    'comandas' as tabela,
    column_name, 
    data_type, 
    is_nullable, 
    column_default 
FROM information_schema.columns 
WHERE table_name = 'comandas' 
AND column_name IN ('desconto', 'tipo_desconto')

UNION ALL

SELECT 
    'historico_comandas' as tabela,
    column_name, 
    data_type, 
    is_nullable, 
    column_default 
FROM information_schema.columns 
WHERE table_name = 'historico_comandas' 
AND column_name IN ('desconto', 'tipo_desconto')

ORDER BY tabela, column_name;

-- Mensagem de sucesso
SELECT 'Colunas de desconto e pagamento dividido adicionadas com sucesso em todas as tabelas!' as resultado;
-- Adicionar colunas de desconto na tabela historico_geral
-- Execute este script no Supabase SQL Editor

-- Adicionar colunas de desconto se não existirem
DO $$ 
BEGIN
    -- Adicionar coluna desconto
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'historico_geral' AND column_name = 'desconto') THEN
        ALTER TABLE historico_geral ADD COLUMN desconto DECIMAL(10,2) DEFAULT 0;
        RAISE NOTICE 'Coluna desconto adicionada à tabela historico_geral';
    ELSE
        RAISE NOTICE 'Coluna desconto já existe na tabela historico_geral';
    END IF;

    -- Adicionar coluna tipo_desconto
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'historico_geral' AND column_name = 'tipo_desconto') THEN
        ALTER TABLE historico_geral ADD COLUMN tipo_desconto VARCHAR(20) DEFAULT 'valor';
        RAISE NOTICE
         'Coluna tipo_desconto adicionada à tabela historico_geral';
    ELSE
        RAISE NOTICE 'Coluna tipo_desconto já existe na tabela historico_geral';
    END IF;

    -- Adicionar coluna taxa_extra_km se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'historico_geral' AND column_name = 'taxa_extra_km') THEN
        ALTER TABLE historico_geral ADD COLUMN taxa_extra_km DECIMAL(10,2) DEFAULT 0;
        RAISE NOTICE 'Coluna taxa_extra_km adicionada à tabela historico_geral';
    ELSE
        RAISE NOTICE 'Coluna taxa_extra_km já existe na tabela historico_geral';
    END IF;

    -- Adicionar colunas de pagamento dividido se não existirem
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'historico_geral' AND column_name = 'forma_pagamento_dividido') THEN
        ALTER TABLE historico_geral ADD COLUMN forma_pagamento_dividido BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Coluna forma_pagamento_dividido adicionada à tabela historico_geral';
    ELSE
        RAISE NOTICE 'Coluna forma_pagamento_dividido já existe na tabela historico_geral';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'historico_geral' AND column_name = 'pagamento_1_tipo') THEN
        ALTER TABLE historico_geral ADD COLUMN pagamento_1_tipo VARCHAR(50);
        RAISE NOTICE 'Coluna pagamento_1_tipo adicionada à tabela historico_geral';
    ELSE
        RAISE NOTICE 'Coluna pagamento_1_tipo já existe na tabela historico_geral';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'historico_geral' AND column_name = 'pagamento_1_valor') THEN
        ALTER TABLE historico_geral ADD COLUMN pagamento_1_valor DECIMAL(10,2);
        RAISE NOTICE 'Coluna pagamento_1_valor adicionada à tabela historico_geral';
    ELSE
        RAISE NOTICE 'Coluna pagamento_1_valor já existe na tabela historico_geral';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'historico_geral' AND column_name = 'pagamento_2_tipo') THEN
        ALTER TABLE historico_geral ADD COLUMN pagamento_2_tipo VARCHAR(50);
        RAISE NOTICE 'Coluna pagamento_2_tipo adicionada à tabela historico_geral';
    ELSE
        RAISE NOTICE 'Coluna pagamento_2_tipo já existe na tabela historico_geral';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'historico_geral' AND column_name = 'pagamento_2_valor') THEN
        ALTER TABLE historico_geral ADD COLUMN pagamento_2_valor DECIMAL(10,2);
        RAISE NOTICE 'Coluna pagamento_2_valor adicionada à tabela historico_geral';
    ELSE
        RAISE NOTICE 'Coluna pagamento_2_valor já existe na tabela historico_geral';
    END IF;

    -- Adicionar coluna movido_em se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'historico_geral' AND column_name = 'movido_em') THEN
        ALTER TABLE historico_geral ADD COLUMN movido_em TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Coluna movido_em adicionada à tabela historico_geral';
    ELSE
        RAISE NOTICE 'Coluna movido_em já existe na tabela historico_geral';
    END IF;

END $$;

-- Verificar as colunas adicionadas
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'historico_geral' 
  AND column_name IN ('desconto', 'tipo_desconto', 'taxa_extra_km', 'forma_pagamento_dividido', 
                      'pagamento_1_tipo', 'pagamento_1_valor', 'pagamento_2_tipo', 'pagamento_2_valor', 'movido_em')
ORDER BY column_name;
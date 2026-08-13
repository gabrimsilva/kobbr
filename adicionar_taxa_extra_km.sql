-- ============================================================================
-- ADICIONAR COLUNA TAXA_EXTRA_KM
-- ============================================================================
-- Arquivo: adicionar_taxa_extra_km.sql
-- Descrição: Adiciona a coluna taxa_extra_km que está faltando na tabela pedidos
-- Data: 31/01/2026
-- ============================================================================

-- IMPORTANTE: Execute este script no banco de dados de produção via Supabase Dashboard
-- Vá em: Database > SQL Editor > Cole este código > Run

-- 1. ADICIONAR COLUNA TAXA_EXTRA_KM NA TABELA PEDIDOS
ALTER TABLE public.pedidos 
ADD COLUMN IF NOT EXISTS taxa_extra_km DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (taxa_extra_km >= 0);

-- 2. ADICIONAR COLUNA TAXA_EXTRA_KM NA TABELA HISTORICO_PEDIDOS
ALTER TABLE public.historico_pedidos 
ADD COLUMN IF NOT EXISTS taxa_extra_km DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (taxa_extra_km >= 0);

-- 3. ADICIONAR COLUNA TAXA_EXTRA_KM NA TABELA HISTORICO_GERAL (se existir)
ALTER TABLE public.historico_geral 
ADD COLUMN IF NOT EXISTS taxa_extra_km DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (taxa_extra_km >= 0);

-- 4. COMENTÁRIOS PARA DOCUMENTAÇÃO
COMMENT ON COLUMN public.pedidos.taxa_extra_km IS 'Taxa adicional por quilômetro de distância para entrega. Calculada automaticamente baseada na distância do CEP do cliente.';
COMMENT ON COLUMN public.historico_pedidos.taxa_extra_km IS 'Taxa adicional por quilômetro de distância para entrega. Calculada automaticamente baseada na distância do CEP do cliente.';

-- 5. VERIFICAÇÃO FINAL
-- Verificar se a coluna foi criada em todas as tabelas
SELECT 
    'pedidos' as tabela,
    column_name, 
    data_type, 
    is_nullable, 
    column_default 
FROM information_schema.columns 
WHERE table_name = 'pedidos' 
AND column_name = 'taxa_extra_km'

UNION ALL

SELECT 
    'historico_pedidos' as tabela,
    column_name, 
    data_type, 
    is_nullable, 
    column_default 
FROM information_schema.columns 
WHERE table_name = 'historico_pedidos' 
AND column_name = 'taxa_extra_km'

UNION ALL

SELECT 
    'historico_geral' as tabela,
    column_name, 
    data_type, 
    is_nullable, 
    column_default 
FROM information_schema.columns 
WHERE table_name = 'historico_geral' 
AND column_name = 'taxa_extra_km'

ORDER BY tabela, column_name;

-- Mensagem de sucesso
SELECT 'Coluna taxa_extra_km adicionada com sucesso em todas as tabelas!' as resultado;
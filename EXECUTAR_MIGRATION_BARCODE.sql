-- ============================================
-- EXECUTAR MIGRATION: Código de Barras
-- ============================================
-- 
-- INSTRUÇÕES:
-- 1. Abra o Supabase SQL Editor
-- 2. Cole este script completo
-- 3. Execute (Run)
-- 4. Verifique as mensagens de sucesso
--
-- ============================================

-- Adicionar campo barcode na tabela produtos
ALTER TABLE produtos 
ADD COLUMN IF NOT EXISTS barcode VARCHAR(100) NULL;

-- Criar índice para busca rápida por código de barras em produtos
CREATE INDEX IF NOT EXISTS idx_produtos_barcode ON produtos(barcode) WHERE barcode IS NOT NULL;

-- Adicionar constraint de unicidade para código de barras em produtos
DO $$
BEGIN
  ALTER TABLE produtos 
  ADD CONSTRAINT unique_produtos_barcode UNIQUE (barcode);
EXCEPTION
  WHEN duplicate_table THEN NULL;
  WHEN duplicate_object THEN NULL;
END $$;

-- Adicionar campo barcode na tabela stock_variants
ALTER TABLE stock_variants 
ADD COLUMN IF NOT EXISTS barcode VARCHAR(100) NULL;

-- Criar índice para busca rápida por código de barras em variantes
CREATE INDEX IF NOT EXISTS idx_stock_variants_barcode ON stock_variants(barcode) WHERE barcode IS NOT NULL;

-- Adicionar constraint de unicidade para código de barras em variantes
DO $$
BEGIN
  ALTER TABLE stock_variants 
  ADD CONSTRAINT unique_stock_variants_barcode UNIQUE (barcode);
EXCEPTION
  WHEN duplicate_table THEN NULL;
  WHEN duplicate_object THEN NULL;
END $$;

-- Comentários nas colunas
COMMENT ON COLUMN produtos.barcode IS 'Código de barras do produto (EAN-13, EAN-8, UPC, Code128)';
COMMENT ON COLUMN stock_variants.barcode IS 'Código de barras da variante (EAN-13, EAN-8, UPC, Code128)';

-- Função para buscar produto ou variante por código de barras
CREATE OR REPLACE FUNCTION buscar_por_barcode(codigo_barras VARCHAR)
RETURNS TABLE (
  tipo VARCHAR,
  produto_id UUID,
  produto_nome VARCHAR,
  variante_id UUID,
  variante_label VARCHAR,
  stock_item_id UUID,
  quantidade_disponivel INTEGER
) AS $$
BEGIN
  -- Primeiro, tentar encontrar em variantes
  RETURN QUERY
  SELECT 
    'variante'::VARCHAR as tipo,
    p.id as produto_id,
    p.nome as produto_nome,
    sv.id as variante_id,
    sv.label as variante_label,
    sv.stock_item_id,
    sv.qty as quantidade_disponivel
  FROM stock_variants sv
  INNER JOIN stock_items si ON sv.stock_item_id = si.id
  INNER JOIN produtos p ON si.product_id = p.id
  WHERE sv.barcode = codigo_barras
  AND si.active = true
  LIMIT 1;
  
  -- Se não encontrou em variantes, buscar em produtos
  IF NOT FOUND THEN
    RETURN QUERY
    SELECT 
      'produto'::VARCHAR as tipo,
      p.id as produto_id,
      p.nome as produto_nome,
      NULL::UUID as variante_id,
      NULL::VARCHAR as variante_label,
      si.id as stock_item_id,
      si.total_qty as quantidade_disponivel
    FROM produtos p
    LEFT JOIN stock_items si ON p.id = si.product_id
    WHERE p.barcode = codigo_barras
    AND p.ativo = true
    LIMIT 1;
  END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION buscar_por_barcode IS 'Busca produto ou variante por código de barras, retornando informações completas';

-- Verificação
DO $$
BEGIN
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'VERIFICAÇÃO DA MIGRATION';
  RAISE NOTICE '==============================================';
  
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'produtos' AND column_name = 'barcode'
  ) THEN
    RAISE NOTICE '✓ Coluna barcode adicionada em produtos';
  ELSE
    RAISE NOTICE '✗ ERRO: Coluna barcode NÃO foi adicionada em produtos';
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stock_variants' AND column_name = 'barcode'
  ) THEN
    RAISE NOTICE '✓ Coluna barcode adicionada em stock_variants';
  ELSE
    RAISE NOTICE '✗ ERRO: Coluna barcode NÃO foi adicionada em stock_variants';
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_produtos_barcode'
  ) THEN
    RAISE NOTICE '✓ Índice idx_produtos_barcode criado';
  ELSE
    RAISE NOTICE '✗ ERRO: Índice idx_produtos_barcode NÃO foi criado';
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_stock_variants_barcode'
  ) THEN
    RAISE NOTICE '✓ Índice idx_stock_variants_barcode criado';
  ELSE
    RAISE NOTICE '✗ ERRO: Índice idx_stock_variants_barcode NÃO foi criado';
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'buscar_por_barcode'
  ) THEN
    RAISE NOTICE '✓ Função buscar_por_barcode criada';
  ELSE
    RAISE NOTICE '✗ ERRO: Função buscar_por_barcode NÃO foi criada';
  END IF;
  
  RAISE NOTICE '==============================================';
  RAISE NOTICE '✓ MIGRATION CONCLUÍDA COM SUCESSO!';
  RAISE NOTICE '==============================================';
END $$;

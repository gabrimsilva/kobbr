-- ============================================================================
-- CRIAR TRIGGER PARA AUTO-CRIAR ESTOQUE QUANDO PRODUTO REQUER
-- ============================================================================

-- Função que cria automaticamente o item de estoque
CREATE OR REPLACE FUNCTION criar_estoque_automatico()
RETURNS TRIGGER AS $$
DECLARE
  novo_stock_id UUID;
BEGIN
  -- Se o produto requer estoque e não tem stock_item_id
  IF NEW.requires_stock = true AND NEW.stock_item_id IS NULL THEN
    -- Criar item de estoque
    INSERT INTO stock_items (
      nome,
      descricao,
      quantidade,
      ativo,
      product_id
    ) VALUES (
      NEW.nome,
      'Estoque de ' || NEW.nome,
      0, -- quantidade inicial zero
      true,
      NEW.id
    ) RETURNING id INTO novo_stock_id;
    
    -- Atualizar o produto com o ID do item de estoque
    NEW.stock_item_id := novo_stock_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger BEFORE INSERT
DROP TRIGGER IF EXISTS trigger_criar_estoque_automatico ON produtos;
CREATE TRIGGER trigger_criar_estoque_automatico
  BEFORE INSERT ON produtos
  FOR EACH ROW
  EXECUTE FUNCTION criar_estoque_automatico();

-- Criar trigger BEFORE UPDATE (caso mude requires_stock para true)
DROP TRIGGER IF EXISTS trigger_atualizar_estoque_automatico ON produtos;
CREATE TRIGGER trigger_atualizar_estoque_automatico
  BEFORE UPDATE ON produtos
  FOR EACH ROW
  WHEN (NEW.requires_stock = true AND OLD.requires_stock = false AND NEW.stock_item_id IS NULL)
  EXECUTE FUNCTION criar_estoque_automatico();

-- ============================================================================
-- PRONTO! Agora quando criar um produto com estoque ativado,
-- o item de estoque será criado automaticamente
-- ============================================================================

-- Corrigir produtos existentes que precisam de estoque mas não têm
DO $$
DECLARE
  produto RECORD;
  novo_stock_id UUID;
BEGIN
  FOR produto IN 
    SELECT * FROM produtos 
    WHERE requires_stock = true AND stock_item_id IS NULL
  LOOP
    -- Criar item de estoque
    INSERT INTO stock_items (
      nome,
      descricao,
      quantidade,
      ativo,
      product_id
    ) VALUES (
      produto.nome,
      'Estoque de ' || produto.nome,
      0,
      true,
      produto.id
    ) RETURNING id INTO novo_stock_id;
    
    -- Atualizar produto
    UPDATE produtos 
    SET stock_item_id = novo_stock_id 
    WHERE id = produto.id;
  END LOOP;
END $$;

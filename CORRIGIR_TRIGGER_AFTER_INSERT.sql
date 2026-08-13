-- ============================================================================
-- CORRIGIR TRIGGER PARA AFTER INSERT
-- ============================================================================

-- Remover triggers antigas
DROP TRIGGER IF EXISTS trigger_criar_estoque_automatico ON produtos;
DROP TRIGGER IF EXISTS trigger_atualizar_estoque_automatico ON produtos;

-- Remover função antiga
DROP FUNCTION IF EXISTS criar_estoque_automatico();

-- Nova função que cria estoque DEPOIS do produto ser inserido
CREATE OR REPLACE FUNCTION criar_estoque_automatico_after()
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
      0,
      true,
      NEW.id
    ) RETURNING id INTO novo_stock_id;
    
    -- Atualizar o produto com o ID do item de estoque
    UPDATE produtos 
    SET stock_item_id = novo_stock_id 
    WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger AFTER INSERT (não BEFORE)
CREATE TRIGGER trigger_criar_estoque_automatico
  AFTER INSERT ON produtos
  FOR EACH ROW
  EXECUTE FUNCTION criar_estoque_automatico_after();

-- ============================================================================
-- PRONTO! Agora a trigger funciona corretamente
-- ============================================================================

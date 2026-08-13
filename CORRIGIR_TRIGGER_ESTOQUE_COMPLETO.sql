-- ============================================================================
-- CORRIGIR TRIGGER DE CRIAÇÃO AUTOMÁTICA DE ESTOQUE
-- ============================================================================

-- 1. Remover trigger antigo se existir
DROP TRIGGER IF EXISTS trigger_criar_estoque_automatico ON produtos;
DROP FUNCTION IF EXISTS criar_estoque_automatico_after();

-- 2. Criar função que cria estoque E atualiza o produto
CREATE OR REPLACE FUNCTION criar_estoque_automatico_after()
RETURNS TRIGGER AS $$
DECLARE
    novo_stock_id UUID;
BEGIN
    -- Verificar se o produto requer estoque
    IF NEW.requires_stock = true THEN
        -- Verificar se já existe um stock_item para este produto
        SELECT id INTO novo_stock_id
        FROM stock_items
        WHERE product_id = NEW.id;
        
        -- Se não existir, criar
        IF novo_stock_id IS NULL THEN
            INSERT INTO stock_items (
                product_id,
                nome,
                descricao,
                quantidade,
                ativo
            ) VALUES (
                NEW.id,
                NEW.nome,
                'Estoque de ' || NEW.nome,
                0,
                true
            )
            RETURNING id INTO novo_stock_id;
            
            -- Atualizar o produto com o stock_item_id
            UPDATE produtos
            SET stock_item_id = novo_stock_id
            WHERE id = NEW.id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Criar trigger AFTER INSERT
CREATE TRIGGER trigger_criar_estoque_automatico
AFTER INSERT ON produtos
FOR EACH ROW
EXECUTE FUNCTION criar_estoque_automatico_after();

-- 4. Criar trigger AFTER UPDATE para quando requires_stock mudar
CREATE OR REPLACE FUNCTION atualizar_estoque_on_update()
RETURNS TRIGGER AS $$
DECLARE
    novo_stock_id UUID;
BEGIN
    -- Se requires_stock mudou de false para true
    IF OLD.requires_stock = false AND NEW.requires_stock = true THEN
        -- Verificar se já existe um stock_item
        SELECT id INTO novo_stock_id
        FROM stock_items
        WHERE product_id = NEW.id;
        
        -- Se não existir, criar
        IF novo_stock_id IS NULL THEN
            INSERT INTO stock_items (
                product_id,
                nome,
                descricao,
                quantidade,
                ativo
            ) VALUES (
                NEW.id,
                NEW.nome,
                'Estoque de ' || NEW.nome,
                0,
                true
            )
            RETURNING id INTO novo_stock_id;
            
            -- Atualizar o produto
            UPDATE produtos
            SET stock_item_id = novo_stock_id
            WHERE id = NEW.id;
        ELSE
            -- Reativar stock_item existente
            UPDATE stock_items
            SET ativo = true
            WHERE id = novo_stock_id;
            
            -- Atualizar o produto
            UPDATE produtos
            SET stock_item_id = novo_stock_id
            WHERE id = NEW.id;
        END IF;
    END IF;
    
    -- Se requires_stock mudou de true para false
    IF OLD.requires_stock = true AND NEW.requires_stock = false THEN
        -- Desativar stock_item (não deletar)
        UPDATE stock_items
        SET ativo = false
        WHERE product_id = NEW.id;
        
        -- Remover referência no produto
        UPDATE produtos
        SET stock_item_id = NULL
        WHERE id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_atualizar_estoque_on_update ON produtos;
CREATE TRIGGER trigger_atualizar_estoque_on_update
AFTER UPDATE ON produtos
FOR EACH ROW
WHEN (OLD.requires_stock IS DISTINCT FROM NEW.requires_stock)
EXECUTE FUNCTION atualizar_estoque_on_update();

-- ============================================================================
-- PRONTO! Triggers corrigidos
-- ============================================================================

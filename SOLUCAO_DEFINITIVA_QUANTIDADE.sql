-- ============================================================================
-- SOLUÇÃO DEFINITIVA PARA O PROBLEMA DA QUANTIDADE 100
-- ============================================================================

-- PASSO 1: Desabilitar todos os triggers temporariamente
ALTER TABLE stock_items DISABLE TRIGGER ALL;

-- PASSO 2: Atualizar a quantidade para 0
UPDATE stock_items 
SET quantidade = 0::numeric;

-- PASSO 3: Reabilitar os triggers
ALTER TABLE stock_items ENABLE TRIGGER ALL;

-- PASSO 4: Verificar o resultado
SELECT 
    id,
    product_id,
    nome,
    quantidade,
    quantidade::text as quantidade_texto,
    pg_typeof(quantidade) as tipo_coluna,
    ativo
FROM stock_items;

-- ============================================================================
-- SE AINDA NÃO FUNCIONAR: Alterar o tipo da coluna
-- ============================================================================

-- Converter para INTEGER (mais simples que NUMERIC)
ALTER TABLE stock_items 
ALTER COLUMN quantidade TYPE INTEGER USING quantidade::integer;

-- Definir valor padrão
ALTER TABLE stock_items 
ALTER COLUMN quantidade SET DEFAULT 0;

-- Atualizar novamente
UPDATE stock_items 
SET quantidade = 0;

-- Verificar
SELECT * FROM stock_items;

-- ============================================================================
-- ÚLTIMA ALTERNATIVA: Deletar e recriar o registro
-- ============================================================================

-- Salvar o product_id
DO $$
DECLARE
    v_product_id UUID;
    v_nome VARCHAR;
BEGIN
    -- Pegar os dados atuais
    SELECT product_id, nome INTO v_product_id, v_nome
    FROM stock_items
    WHERE id = 'fbcea188-3362-414f-9f29-56933fabc51b';
    
    -- Deletar o registro
    DELETE FROM stock_items
    WHERE id = 'fbcea188-3362-414f-9f29-56933fabc51b';
    
    -- Recriar com quantidade 0
    INSERT INTO stock_items (
        product_id,
        nome,
        descricao,
        quantidade,
        ativo
    ) VALUES (
        v_product_id,
        v_nome,
        'Estoque de ' || v_nome,
        0,
        true
    );
    
    -- Atualizar o produto com o novo stock_item_id
    UPDATE produtos
    SET stock_item_id = (SELECT id FROM stock_items WHERE product_id = v_product_id)
    WHERE id = v_product_id;
END $$;

-- Verificar resultado final
SELECT 
    s.id,
    s.product_id,
    s.nome,
    s.quantidade,
    s.ativo,
    p.nome as produto_nome,
    p.stock_item_id
FROM stock_items s
LEFT JOIN produtos p ON p.id = s.product_id;

-- ============================================================================
-- EXECUTAR NO SUPABASE SQL EDITOR
-- ============================================================================

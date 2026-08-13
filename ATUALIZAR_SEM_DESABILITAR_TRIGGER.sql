-- ============================================================================
-- ATUALIZAR QUANTIDADE SEM DESABILITAR TRIGGERS
-- ============================================================================

-- Simplesmente atualizar diretamente (sem desabilitar triggers)
UPDATE stock_items 
SET quantidade = 0
WHERE nome = 'pão de queijo';

-- Verificar
SELECT 
    id,
    product_id,
    nome,
    quantidade,
    ativo
FROM stock_items
WHERE nome = 'pão de queijo';

-- ============================================================================
-- SE NÃO FUNCIONAR: Verificar se há alguma view ou regra
-- ============================================================================

-- Ver se há views sobre stock_items
SELECT 
    table_name,
    view_definition
FROM information_schema.views
WHERE table_name LIKE '%stock%';

-- Ver se há regras (rules) na tabela
SELECT 
    rulename,
    ev_type,
    ev_enabled,
    definition
FROM pg_rules
WHERE tablename = 'stock_items';

-- ============================================================================
-- ALTERNATIVA: Usar uma transação explícita
-- ============================================================================

BEGIN;

-- Atualizar
UPDATE stock_items 
SET quantidade = 0
WHERE id = 'fbcea188-3362-414f-9f29-56933fabc51b';

-- Verificar antes de commitar
SELECT quantidade FROM stock_items WHERE id = 'fbcea188-3362-414f-9f29-56933fabc51b';

-- Se estiver correto, commitar
COMMIT;

-- Se não estiver correto, fazer rollback
-- ROLLBACK;

-- ============================================================================
-- ÚLTIMA OPÇÃO: Deletar e recriar (SEM bloco DO)
-- ============================================================================

-- Pegar os dados atuais
CREATE TEMP TABLE temp_stock_backup AS
SELECT * FROM stock_items WHERE id = 'fbcea188-3362-414f-9f29-56933fabc51b';

-- Deletar
DELETE FROM stock_items WHERE id = 'fbcea188-3362-414f-9f29-56933fabc51b';

-- Recriar com quantidade 0
INSERT INTO stock_items (
    product_id,
    nome,
    descricao,
    quantidade,
    unidade,
    preco_custo,
    fornecedor,
    categoria,
    ativo
)
SELECT 
    product_id,
    nome,
    descricao,
    0 as quantidade,  -- FORÇAR ZERO AQUI
    unidade,
    preco_custo,
    fornecedor,
    categoria,
    ativo
FROM temp_stock_backup;

-- Atualizar o produto com o novo stock_item_id
UPDATE produtos
SET stock_item_id = (
    SELECT id FROM stock_items 
    WHERE product_id = (SELECT product_id FROM temp_stock_backup)
)
WHERE id = (SELECT product_id FROM temp_stock_backup);

-- Verificar resultado
SELECT * FROM stock_items WHERE nome = 'pão de queijo';

-- Limpar tabela temporária
DROP TABLE temp_stock_backup;

-- ============================================================================
-- EXECUTAR NO SUPABASE SQL EDITOR
-- ============================================================================

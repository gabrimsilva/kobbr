-- ============================================
-- ETAPA 1: Adicionar Campos de Estoque Mínimo
-- ============================================
-- Data: 27/02/2026
-- Descrição: Adiciona campos min_qty e reorder_qty para controle de estoque mínimo

-- Adicionar campos de estoque mínimo e reposição
ALTER TABLE stock_items
ADD COLUMN IF NOT EXISTS min_qty INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS reorder_qty INT DEFAULT 0;

-- Comentários
COMMENT ON COLUMN stock_items.min_qty IS 'Quantidade mínima em estoque (alerta crítico quando total_qty <= min_qty)';
COMMENT ON COLUMN stock_items.reorder_qty IS 'Quantidade sugerida para reposição/compra';

-- Atualizar produtos existentes com valores padrão razoáveis
-- min_qty = 5 (alerta quando tiver 5 ou menos)
-- reorder_qty = 10 (sugestão de comprar 10 unidades)
UPDATE stock_items
SET 
  min_qty = 5,
  reorder_qty = 10
WHERE min_qty = 0 OR min_qty IS NULL;

-- Verificar resultado
SELECT 
  p.nome as produto,
  si.total_qty as estoque_atual,
  si.min_qty as estoque_minimo,
  si.reorder_qty as qtd_reposicao,
  CASE 
    WHEN si.min_qty = 0 THEN 'HEALTHY'
    WHEN si.total_qty <= si.min_qty THEN 'CRITICAL'
    WHEN si.total_qty <= si.min_qty * 1.3 THEN 'WARNING'
    ELSE 'HEALTHY'
  END as status
FROM stock_items si
JOIN produtos p ON p.id = si.product_id
ORDER BY 
  CASE 
    WHEN si.min_qty = 0 THEN 3
    WHEN si.total_qty <= si.min_qty THEN 1
    WHEN si.total_qty <= si.min_qty * 1.3 THEN 2
    ELSE 3
  END,
  p.nome;


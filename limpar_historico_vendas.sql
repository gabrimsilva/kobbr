-- ========================================
-- SCRIPT PARA LIMPAR HISTÓRICO DE VENDAS
-- ========================================
-- Este script remove todos os registros de histórico de:
-- - Comandas finalizadas
-- - Pedidos (delivery/retirada)
-- - Vendas gerais (PDV)
-- - Tabela de sales
--
-- ⚠️ ATENÇÃO: Esta operação é IRREVERSÍVEL!
-- ⚠️ Faça backup antes de executar!
-- ========================================

-- 1. Limpar histórico de comandas
DELETE FROM historico_comandas;

-- 2. Limpar histórico de pedidos (delivery/retirada)
DELETE FROM historico_pedidos;

-- 3. Limpar histórico geral (vendas PDV)
DELETE FROM historico_geral;

-- 4. Limpar tabela de sales (vendas registradas)
DELETE FROM sales;

-- ========================================
-- RESULTADO ESPERADO:
-- ✅ Todas as vendas históricas foram removidas
-- ✅ Métricas e relatórios serão zerados
-- ✅ Produtos e estoque permanecem intactos
-- ========================================

-- Verificar quantos registros foram removidos
SELECT 
  'historico_comandas' as tabela,
  COUNT(*) as registros_restantes
FROM historico_comandas
UNION ALL
SELECT 
  'historico_pedidos' as tabela,
  COUNT(*) as registros_restantes
FROM historico_pedidos
UNION ALL
SELECT 
  'historico_geral' as tabela,
  COUNT(*) as registros_restantes
FROM historico_geral
UNION ALL
SELECT 
  'sales' as tabela,
  COUNT(*) as registros_restantes
FROM sales;

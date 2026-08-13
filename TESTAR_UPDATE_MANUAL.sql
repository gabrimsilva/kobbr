-- ============================================================================
-- TESTAR UPDATE MANUAL DE STATUS
-- ============================================================================
-- Este script testa se conseguimos atualizar o status manualmente
-- ============================================================================

-- 1. Ver um pedido existente
SELECT 
    pedido_id,
    codigo_pedido,
    cliente_nome,
    status,
    atualizado_em,
    criado_em
FROM public.pedidos
ORDER BY criado_em DESC
LIMIT 1;

-- 2. Copie o pedido_id acima e cole abaixo (substitua 'COLE_AQUI')
-- Teste 1: Atualizar para "Preparando"
-- UPDATE public.pedidos 
-- SET 
--     status = 'Preparando',
--     atualizado_em = now()
-- WHERE pedido_id = 'COLE_AQUI';

-- 3. Verificar se funcionou
-- SELECT pedido_id, status, atualizado_em 
-- FROM public.pedidos 
-- WHERE pedido_id = 'COLE_AQUI';

-- 4. Listar todos os status possíveis que existem atualmente
SELECT DISTINCT status, COUNT(*) as quantidade
FROM public.pedidos
GROUP BY status
ORDER BY status;

-- 5. Ver a estrutura completa da tabela pedidos
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'pedidos'
AND column_name IN ('status', 'atualizado_em', 'pedido_id')
ORDER BY ordinal_position;

-- 6. Verificar se há triggers que podem estar causando problema
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'pedidos';

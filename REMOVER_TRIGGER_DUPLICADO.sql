-- ============================================================================
-- REMOVER TRIGGER DUPLICADO
-- ============================================================================
-- Há 2 triggers fazendo a mesma coisa, vamos manter apenas 1
-- ============================================================================

-- Remover o trigger antigo
DROP TRIGGER IF EXISTS update_pedidos_updated_at ON public.pedidos;

-- Verificar se foi removido
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'pedidos';

-- Agora deve ter apenas 2 triggers:
-- 1. trigger_sync_pedido_status
-- 2. trigger_update_pedidos_atualizado_em

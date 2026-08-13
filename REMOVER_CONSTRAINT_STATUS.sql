-- ============================================================================
-- REMOVER CONSTRAINT DE VALIDAÇÃO DE STATUS (TEMPORÁRIO)
-- ============================================================================
-- Este script remove a constraint que pode estar bloqueando a atualização
-- ============================================================================

-- Remover constraint de validação de status
ALTER TABLE public.pedidos 
DROP CONSTRAINT IF EXISTS pedidos_status_valido;

-- Verificar se foi removida
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.pedidos'::regclass
AND conname LIKE '%status%';

-- Listar todos os status atuais dos pedidos
SELECT DISTINCT status 
FROM public.pedidos 
ORDER BY status;

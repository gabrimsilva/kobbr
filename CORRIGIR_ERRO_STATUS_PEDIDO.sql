-- ============================================================================
-- CORREÇÃO: Erro ao Atualizar Status de Pedido
-- ============================================================================
-- Descrição: Script para diagnosticar e corrigir problemas ao atualizar status
-- Data: 06/03/2026
-- ============================================================================

-- ============================================================================
-- 1. VERIFICAR ESTRUTURA DA TABELA PEDIDOS
-- ============================================================================

-- Verificar se a coluna status existe e seu tipo
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'pedidos' 
AND column_name IN ('status', 'atualizado_em', 'pedido_id');

-- ============================================================================
-- 2. VERIFICAR CONSTRAINTS NA TABELA PEDIDOS
-- ============================================================================

-- Listar todas as constraints
SELECT 
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.pedidos'::regclass;

-- ============================================================================
-- 3. ADICIONAR CONSTRAINT PARA VALIDAR STATUS (SE NÃO EXISTIR)
-- ============================================================================

-- Remover constraint antiga se existir
ALTER TABLE public.pedidos 
DROP CONSTRAINT IF EXISTS pedidos_status_valido;

-- Adicionar constraint com todos os status válidos
ALTER TABLE public.pedidos 
ADD CONSTRAINT pedidos_status_valido 
CHECK (status IN (
  'Pedido criado',
  'Aguardando pagamento',
  'Preparando',
  'Liberado',
  'Pronto para retirada',
  'Saiu para entrega',
  'Finalizado',
  'Entregue',
  'Retirado',
  'Cancelado'
));

COMMENT ON CONSTRAINT pedidos_status_valido ON public.pedidos 
IS 'Garante que apenas status válidos sejam aceitos';

-- ============================================================================
-- 4. VERIFICAR E CRIAR TRIGGER PARA ATUALIZAR atualizado_em
-- ============================================================================

-- Verificar se o trigger existe
SELECT 
    tgname AS trigger_name,
    tgtype,
    tgenabled
FROM pg_trigger
WHERE tgrelid = 'public.pedidos'::regclass
AND tgname LIKE '%atualizado_em%';

-- Criar função para atualizar atualizado_em (se não existir)
CREATE OR REPLACE FUNCTION update_atualizado_em()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_atualizado_em() 
IS 'Atualiza automaticamente o campo atualizado_em antes de cada UPDATE';

-- Remover trigger antigo se existir
DROP TRIGGER IF EXISTS trigger_update_pedidos_atualizado_em ON public.pedidos;

-- Criar trigger para atualizar atualizado_em automaticamente
CREATE TRIGGER trigger_update_pedidos_atualizado_em
    BEFORE UPDATE ON public.pedidos
    FOR EACH ROW
    EXECUTE FUNCTION update_atualizado_em();

COMMENT ON TRIGGER trigger_update_pedidos_atualizado_em ON public.pedidos 
IS 'Atualiza automaticamente atualizado_em em cada UPDATE';

-- ============================================================================
-- 5. VERIFICAR POLÍTICAS RLS
-- ============================================================================

-- Listar políticas RLS da tabela pedidos
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'pedidos';

-- ============================================================================
-- 6. RECRIAR POLÍTICAS RLS (SE NECESSÁRIO)
-- ============================================================================

-- Garantir que RLS está habilitado
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;

-- Remover políticas antigas
DROP POLICY IF EXISTS "Permitir leitura pública de pedidos" ON public.pedidos;
DROP POLICY IF EXISTS "Permitir inserção pública de pedidos" ON public.pedidos;
DROP POLICY IF EXISTS "Permitir atualização pública pedidos" ON public.pedidos;
DROP POLICY IF EXISTS "Permitir exclusão pública de pedidos" ON public.pedidos;

-- Recriar políticas
CREATE POLICY "Permitir leitura pública de pedidos" 
ON public.pedidos 
FOR SELECT 
USING (true);

CREATE POLICY "Permitir inserção pública de pedidos" 
ON public.pedidos 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Permitir atualização pública pedidos" 
ON public.pedidos 
FOR UPDATE 
USING (true) 
WITH CHECK (true);

CREATE POLICY "Permitir exclusão pública de pedidos" 
ON public.pedidos 
FOR DELETE 
USING (true);

-- ============================================================================
-- 7. TESTAR ATUALIZAÇÃO DE STATUS
-- ============================================================================

-- Buscar um pedido para teste
SELECT 
    pedido_id, 
    codigo_pedido, 
    status, 
    atualizado_em,
    cliente_nome
FROM public.pedidos
ORDER BY criado_em DESC
LIMIT 1;

-- Teste de atualização (SUBSTITUA 'PEDIDO_ID_AQUI' pelo ID real)
-- UPDATE public.pedidos 
-- SET status = 'Preparando'
-- WHERE pedido_id = 'PEDIDO_ID_AQUI';

-- Verificar se a atualização funcionou
-- SELECT 
--     pedido_id, 
--     status, 
--     atualizado_em
-- FROM public.pedidos
-- WHERE pedido_id = 'PEDIDO_ID_AQUI';

-- ============================================================================
-- 8. VERIFICAR ÍNDICES (PERFORMANCE)
-- ============================================================================

-- Listar índices da tabela pedidos
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'pedidos';

-- Criar índice no campo status se não existir (melhora performance)
CREATE INDEX IF NOT EXISTS idx_pedidos_status 
ON public.pedidos(status);

-- Criar índice no campo atualizado_em se não existir
CREATE INDEX IF NOT EXISTS idx_pedidos_atualizado_em 
ON public.pedidos(atualizado_em DESC);

-- ============================================================================
-- 9. VERIFICAR PEDIDOS COM STATUS INVÁLIDO
-- ============================================================================

-- Buscar pedidos com status que não estão na lista válida
SELECT 
    pedido_id,
    codigo_pedido,
    status,
    criado_em
FROM public.pedidos
WHERE status NOT IN (
  'Pedido criado',
  'Aguardando pagamento',
  'Preparando',
  'Liberado',
  'Pronto para retirada',
  'Saiu para entrega',
  'Finalizado',
  'Entregue',
  'Retirado',
  'Cancelado'
)
ORDER BY criado_em DESC;

-- ============================================================================
-- 10. ESTATÍSTICAS DA TABELA
-- ============================================================================

-- Contar pedidos por status
SELECT 
    status,
    COUNT(*) as quantidade
FROM public.pedidos
GROUP BY status
ORDER BY quantidade DESC;

-- Verificar pedidos recentes
SELECT 
    pedido_id,
    codigo_pedido,
    status,
    criado_em,
    atualizado_em,
    EXTRACT(EPOCH FROM (atualizado_em - criado_em)) / 60 as minutos_desde_criacao
FROM public.pedidos
ORDER BY criado_em DESC
LIMIT 10;

-- ============================================================================
-- 11. LOGS E DIAGNÓSTICO
-- ============================================================================

-- Verificar se há erros recentes no log do PostgreSQL
-- (Execute no terminal do Supabase ou painel SQL Editor)

-- Verificar permissões do usuário atual
SELECT 
    current_user,
    session_user,
    current_database();

-- Verificar role do usuário
SELECT 
    rolname,
    rolsuper,
    rolinherit,
    rolcreaterole,
    rolcreatedb
FROM pg_roles
WHERE rolname = current_user;

-- ============================================================================
-- FIM DO SCRIPT
-- ============================================================================

-- INSTRUÇÕES DE USO:
-- 1. Execute este script no SQL Editor do Supabase
-- 2. Verifique os resultados de cada seção
-- 3. Se encontrar problemas, anote-os
-- 4. Execute os comandos de correção conforme necessário
-- 5. Teste a atualização de status no frontend

-- OBSERVAÇÕES:
-- - Este script é seguro e não deleta dados
-- - Apenas adiciona constraints, triggers e índices
-- - As políticas RLS são recriadas para garantir funcionamento
-- - Todos os comandos podem ser executados múltiplas vezes

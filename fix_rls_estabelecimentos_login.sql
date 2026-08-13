-- ========================================
-- FIX: Permitir leitura de estabelecimentos no login
-- ========================================
-- Problema: Usuários não autenticados não conseguem
-- ver a lista de estabelecimentos na tela de login
--
-- Solução: Criar policy que permite leitura pública
-- apenas de estabelecimentos ATIVOS
-- ========================================

-- Remover policy antiga se existir
DROP POLICY IF EXISTS "Estabelecimentos ativos são públicos" ON estabelecimentos;

-- Criar policy para leitura pública dos estabelecimentos ATIVOS
CREATE POLICY "Estabelecimentos ativos são públicos"
ON estabelecimentos
FOR SELECT
TO public
USING (ativo = true);

-- ========================================
-- RESULTADO:
-- ✅ Usuários não autenticados podem ver
--    estabelecimentos ativos no login
-- ✅ Estabelecimentos inativos permanecem ocultos
-- ✅ Apenas admins podem criar/editar
-- ========================================

-- Verificar policies ativas
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'estabelecimentos'
ORDER BY policyname;

-- ============================================================================
-- CRIAR BUCKET 'sistema-imagens' (logo, favicon e banner - aba Aparência)
-- ============================================================================
-- Sintoma: "Bucket not found" ao subir logo/favicon/banner em Configurações > Aparência.
-- Causa: a aba usa o bucket 'sistema-imagens', que não existe no Storage do projeto.
-- Idempotente. Rode no SQL Editor do Supabase.
-- ============================================================================

-- 1. Criar o bucket (público, com limite e tipos de imagem permitidos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'sistema-imagens',
    'sistema-imagens',
    true,
    5242880, -- 5MB
    ARRAY['image/jpeg','image/jpg','image/png','image/gif','image/webp','image/svg+xml','image/x-icon','image/vnd.microsoft.icon']
)
ON CONFLICT (id) DO UPDATE
    SET public = EXCLUDED.public,
        file_size_limit = EXCLUDED.file_size_limit,
        allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Políticas de acesso para o bucket 'sistema-imagens'
-- Leitura pública (para exibir logo/favicon/banner no site e no painel)
DROP POLICY IF EXISTS "Leitura publica de imagens do sistema" ON storage.objects;
CREATE POLICY "Leitura publica de imagens do sistema"
ON storage.objects FOR SELECT
USING (bucket_id = 'sistema-imagens');

-- Upload por usuários autenticados
DROP POLICY IF EXISTS "Upload autenticado de imagens do sistema" ON storage.objects;
CREATE POLICY "Upload autenticado de imagens do sistema"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'sistema-imagens');

-- Atualização por usuários autenticados
DROP POLICY IF EXISTS "Atualizacao autenticada de imagens do sistema" ON storage.objects;
CREATE POLICY "Atualizacao autenticada de imagens do sistema"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'sistema-imagens')
WITH CHECK (bucket_id = 'sistema-imagens');

-- Exclusão por usuários autenticados
DROP POLICY IF EXISTS "Exclusao autenticada de imagens do sistema" ON storage.objects;
CREATE POLICY "Exclusao autenticada de imagens do sistema"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'sistema-imagens');

-- 3. Conferir
SELECT id, name, public, file_size_limit FROM storage.buckets WHERE id = 'sistema-imagens';

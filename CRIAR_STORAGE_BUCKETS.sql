-- ============================================================================
-- CRIAR STORAGE BUCKETS PARA IMAGENS
-- ============================================================================

-- Criar bucket para imagens de produtos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'produtos-imagens',
  'produtos-imagens',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Criar bucket para logos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'logos',
  'logos',
  true,
  2097152, -- 2MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/svg+xml']
)
ON CONFLICT (id) DO NOTHING;

-- Criar bucket para uploads da IA
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'ia-uploads',
  'ia-uploads',
  true,
  10485760, -- 10MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Políticas de acesso para produtos-imagens
CREATE POLICY "Permitir upload de imagens de produtos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'produtos-imagens');

CREATE POLICY "Permitir leitura pública de imagens de produtos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'produtos-imagens');

CREATE POLICY "Permitir atualização de imagens de produtos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'produtos-imagens');

CREATE POLICY "Permitir exclusão de imagens de produtos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'produtos-imagens');

-- Políticas de acesso para logos
CREATE POLICY "Permitir upload de logos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'logos');

CREATE POLICY "Permitir leitura pública de logos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'logos');

CREATE POLICY "Permitir atualização de logos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'logos');

CREATE POLICY "Permitir exclusão de logos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'logos');

-- Políticas de acesso para ia-uploads
CREATE POLICY "Permitir upload IA"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'ia-uploads');

CREATE POLICY "Permitir leitura IA"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'ia-uploads');

CREATE POLICY "Permitir exclusão IA"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'ia-uploads');

-- ============================================================================
-- PRONTO! Storage buckets criados com políticas de acesso
-- ============================================================================

-- ============================================================================
-- STORAGE BUCKETS E CONFIGURAÇÕES INICIAIS
-- ============================================================================
-- Arquivo: 07_storage_and_config.sql
-- Descrição: Configuração de buckets de storage e dados iniciais
-- Data: 20/01/2026
-- ============================================================================

-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================

-- Bucket para imagens de produtos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'produtos-imagens', 
    'produtos-imagens', 
    true, 
    5242880, -- 5MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- Bucket para imagens do sistema
INSERT INTO storage.buckets (id, name, public)
VALUES (
    'sistema-imagens', 
    'sistema-imagens', 
    true
) ON CONFLICT (id) DO NOTHING;

-- Bucket para uploads do assistente IA
INSERT INTO storage.buckets (id, name, public)
VALUES (
    'ia-uploads', 
    'ia-uploads', 
    false
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- POLÍTICAS DE STORAGE PARA PRODUTOS-IMAGENS
-- ============================================================================

DROP POLICY IF EXISTS "Permitir leitura pública de imagens de produtos" ON storage.objects;
CREATE POLICY "Permitir leitura pública de imagens de produtos"
ON storage.objects FOR SELECT
USING (bucket_id = 'produtos-imagens');

DROP POLICY IF EXISTS "Permitir upload autenticado de imagens de produtos" ON storage.objects;
CREATE POLICY "Permitir upload autenticado de imagens de produtos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'produtos-imagens' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Permitir atualização autenticada de imagens de produtos" ON storage.objects;
CREATE POLICY "Permitir atualização autenticada de imagens de produtos"
ON storage.objects FOR UPDATE
USING (bucket_id = 'produtos-imagens' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Permitir exclusão autenticada de imagens de produtos" ON storage.objects;
CREATE POLICY "Permitir exclusão autenticada de imagens de produtos"
ON storage.objects FOR DELETE
USING (bucket_id = 'produtos-imagens' AND auth.role() = 'authenticated');

-- ============================================================================
-- POLÍTICAS DE STORAGE PARA SISTEMA-IMAGENS
-- ============================================================================

DROP POLICY IF EXISTS "Permitir leitura pública de imagens do sistema" ON storage.objects;
CREATE POLICY "Permitir leitura pública de imagens do sistema"
ON storage.objects FOR SELECT
USING (bucket_id = 'sistema-imagens');

DROP POLICY IF EXISTS "Permitir upload autenticado de imagens do sistema" ON storage.objects;
CREATE POLICY "Permitir upload autenticado de imagens do sistema"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'sistema-imagens' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Permitir atualização autenticada de imagens do sistema" ON storage.objects;
CREATE POLICY "Permitir atualização autenticada de imagens do sistema"
ON storage.objects FOR UPDATE
USING (bucket_id = 'sistema-imagens' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Permitir exclusão autenticada de imagens do sistema" ON storage.objects;
CREATE POLICY "Permitir exclusão autenticada de imagens do sistema"
ON storage.objects FOR DELETE
USING (bucket_id = 'sistema-imagens' AND auth.role() = 'authenticated');

-- ============================================================================
-- POLÍTICAS DE STORAGE PARA IA-UPLOADS
-- ============================================================================

DROP POLICY IF EXISTS "Usuários autenticados podem fazer upload" ON storage.objects;
CREATE POLICY "Usuários autenticados podem fazer upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'ia-uploads');

DROP POLICY IF EXISTS "Usuários autenticados podem ler arquivos" ON storage.objects;
CREATE POLICY "Usuários autenticados podem ler arquivos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'ia-uploads');

DROP POLICY IF EXISTS "Usuários autenticados podem deletar arquivos" ON storage.objects;
CREATE POLICY "Usuários autenticados podem deletar arquivos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'ia-uploads');

-- ============================================================================
-- CONFIGURAÇÕES INICIAIS DO SISTEMA
-- ============================================================================

-- Configuração de taxa extra por km
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('taxa_extra_km_ativa', 'false', 'Ativar taxa extra por distância', 'booleano', 'entrega')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('taxa_extra_km_inicial', '5', 'Km inicial para cobrar taxa extra', 'numero', 'entrega')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('taxa_extra_km_faixas', '[]', 'Faixas de taxa extra por km', 'json', 'entrega')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

-- Configuração tipo de checkout
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('tipo_checkout', 'step-by-step', 'Tipo de checkout: "normal" (tudo em uma página) ou "step-by-step" (passo a passo)', 'texto', 'checkout')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

-- ============================================================================
-- CONFIGURAÇÕES DE TAMANHO DE FONTE PARA IMPRESSÃO
-- ============================================================================

-- Tamanho base do texto
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('font_size_base', '11', 'Tamanho base do texto da impressão (px)', 'numero', 'impressao')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

-- Tamanho do nome da loja
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('font_size_store_name', '16', 'Tamanho do nome da loja na impressão (px)', 'numero', 'impressao')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

-- Tamanho dos títulos de seção
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('font_size_section_title', '11', 'Tamanho dos títulos de seção na impressão (px)', 'numero', 'impressao')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

-- Tamanho dos subtítulos/detalhes
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('font_size_item_sub', '10', 'Tamanho dos subtítulos/detalhes na impressão (px)', 'numero', 'impressao')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

-- Tamanho dos valores de subtotal e taxas
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('font_size_totals', '12', 'Tamanho dos valores de subtotal e taxas (px)', 'numero', 'impressao')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

-- Tamanho do valor total final
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('font_size_total_final', '14', 'Tamanho do valor total final na impressão (px)', 'numero', 'impressao')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

-- ============================================================================
-- REALTIME - HABILITAR PARA TABELAS DE PEDIDOS
-- ============================================================================

-- Adicionar tabela pedidos ao Realtime para atualizações em tempo real
DO $$
BEGIN
    -- Verificar se a publicação existe antes de adicionar
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS pedidos;
        ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS historico_pedidos;
    END IF;
END $$;

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================

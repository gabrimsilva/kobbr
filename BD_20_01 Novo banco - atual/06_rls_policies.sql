-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - POLÍTICAS DE SEGURANÇA
-- ============================================================================
-- Arquivo: 06_rls_policies.sql
-- Descrição: Políticas de segurança em nível de linha
-- Data: 20/01/2026
-- ============================================================================

-- ============================================================================
-- HABILITAR RLS EM TODAS AS TABELAS
-- ============================================================================

ALTER TABLE public.adicionais ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comandas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.combo_produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.combos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuracoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estoque ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.funcionarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_comandas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_geral ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_sabores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sabores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tamanhos ENABLE ROW LEVEL SECURITY;
ALTER TABLE ia_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE ia_conversas ENABLE ROW LEVEL SECURITY;
ALTER TABLE ia_arquivos_temp ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- POLÍTICAS PARA ADICIONAIS
-- ============================================================================

DROP POLICY IF EXISTS "Permitir leitura pública de adicionais" ON public.adicionais;
CREATE POLICY "Permitir leitura pública de adicionais" ON public.adicionais FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir inserção autenticada de adicionais" ON public.adicionais;
CREATE POLICY "Permitir inserção autenticada de adicionais" ON public.adicionais FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir atualização autenticada de adicionais" ON public.adicionais;
CREATE POLICY "Permitir atualização autenticada de adicionais" ON public.adicionais FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Permitir exclusão autenticada de adicionais" ON public.adicionais;
CREATE POLICY "Permitir exclusão autenticada de adicionais" ON public.adicionais FOR DELETE USING (true);

-- ============================================================================
-- POLÍTICAS PARA AVALIACOES
-- ============================================================================

DROP POLICY IF EXISTS "Permitir leitura pública de avaliações aprovadas" ON public.avaliacoes;
CREATE POLICY "Permitir leitura pública de avaliações aprovadas" ON public.avaliacoes FOR SELECT USING (aprovada = true);

DROP POLICY IF EXISTS "Permitir inserção pública de avaliações" ON public.avaliacoes;
CREATE POLICY "Permitir inserção pública de avaliações" ON public.avaliacoes FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir atualização de avaliações" ON public.avaliacoes;
CREATE POLICY "Permitir atualização de avaliações" ON public.avaliacoes FOR UPDATE USING (true);

-- ============================================================================
-- POLÍTICAS PARA CATEGORIAS
-- ============================================================================

DROP POLICY IF EXISTS "Leitura pública categorias" ON public.categorias;
CREATE POLICY "Leitura pública categorias" ON public.categorias FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada categorias" ON public.categorias;
CREATE POLICY "Inserção autenticada categorias" ON public.categorias FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada categorias" ON public.categorias;
CREATE POLICY "Atualização autenticada categorias" ON public.categorias FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada categorias" ON public.categorias;
CREATE POLICY "Exclusão autenticada categorias" ON public.categorias FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- ============================================================================
-- POLÍTICAS PARA CLIENTES
-- ============================================================================

DROP POLICY IF EXISTS "Permitir todas as operações em clientes" ON public.clientes;
CREATE POLICY "Permitir todas as operações em clientes" ON public.clientes FOR ALL USING (true) WITH CHECK (true);

-- ============================================================================
-- POLÍTICAS PARA COMANDAS
-- ============================================================================

DROP POLICY IF EXISTS "Usuários autenticados podem visualizar comandas" ON public.comandas;
CREATE POLICY "Usuários autenticados podem visualizar comandas" ON public.comandas FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem criar comandas" ON public.comandas;
CREATE POLICY "Usuários autenticados podem criar comandas" ON public.comandas FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários autenticados podem atualizar comandas" ON public.comandas;
CREATE POLICY "Usuários autenticados podem atualizar comandas" ON public.comandas FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários autenticados podem deletar comandas" ON public.comandas;
CREATE POLICY "Usuários autenticados podem deletar comandas" ON public.comandas FOR DELETE TO authenticated USING (true);

-- ============================================================================
-- POLÍTICAS PARA COMBO_PRODUTOS
-- ============================================================================

DROP POLICY IF EXISTS "Leitura pública combo_produtos" ON public.combo_produtos;
CREATE POLICY "Leitura pública combo_produtos" ON public.combo_produtos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada combo_produtos" ON public.combo_produtos;
CREATE POLICY "Inserção autenticada combo_produtos" ON public.combo_produtos FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada combo_produtos" ON public.combo_produtos;
CREATE POLICY "Atualização autenticada combo_produtos" ON public.combo_produtos FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada combo_produtos" ON public.combo_produtos;
CREATE POLICY "Exclusão autenticada combo_produtos" ON public.combo_produtos FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- ============================================================================
-- POLÍTICAS PARA COMBOS
-- ============================================================================

DROP POLICY IF EXISTS "Leitura pública combos" ON public.combos;
CREATE POLICY "Leitura pública combos" ON public.combos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada combos" ON public.combos;
CREATE POLICY "Inserção autenticada combos" ON public.combos FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada combos" ON public.combos;
CREATE POLICY "Atualização autenticada combos" ON public.combos FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada combos" ON public.combos;
CREATE POLICY "Exclusão autenticada combos" ON public.combos FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- ============================================================================
-- POLÍTICAS PARA CONFIGURACOES
-- ============================================================================

DROP POLICY IF EXISTS "configuracoes_optimized_policy" ON public.configuracoes;
CREATE POLICY "configuracoes_optimized_policy" ON public.configuracoes FOR ALL 
    USING (true) 
    WITH CHECK ((SELECT auth.role()) = 'authenticated' OR (SELECT auth.role()) = 'anon');

-- ============================================================================
-- POLÍTICAS PARA ESTOQUE
-- ============================================================================

DROP POLICY IF EXISTS "Acesso autenticado estoque" ON public.estoque;
CREATE POLICY "Acesso autenticado estoque" ON public.estoque FOR ALL USING ((SELECT auth.uid()) IS NOT NULL);

-- ============================================================================
-- POLÍTICAS PARA FUNCIONARIOS
-- ============================================================================

DROP POLICY IF EXISTS "Permitir leitura funcionarios autenticados" ON public.funcionarios;
CREATE POLICY "Permitir leitura funcionarios autenticados" ON public.funcionarios FOR SELECT USING ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Permitir criacao funcionarios autenticados" ON public.funcionarios;
CREATE POLICY "Permitir criacao funcionarios autenticados" ON public.funcionarios FOR INSERT WITH CHECK ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Permitir atualizacao funcionarios autenticados" ON public.funcionarios;
CREATE POLICY "Permitir atualizacao funcionarios autenticados" ON public.funcionarios FOR UPDATE USING ((SELECT auth.role()) = 'authenticated') WITH CHECK ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Permitir exclusao funcionarios autenticados" ON public.funcionarios;
CREATE POLICY "Permitir exclusao funcionarios autenticados" ON public.funcionarios FOR DELETE USING ((SELECT auth.role()) = 'authenticated');

-- ============================================================================
-- POLÍTICAS PARA HISTORICO_COMANDAS
-- ============================================================================

DROP POLICY IF EXISTS "Usuários autenticados podem visualizar histórico" ON public.historico_comandas;
CREATE POLICY "Usuários autenticados podem visualizar histórico" ON public.historico_comandas FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem criar histórico" ON public.historico_comandas;
CREATE POLICY "Usuários autenticados podem criar histórico" ON public.historico_comandas FOR INSERT TO authenticated WITH CHECK (true);

-- ============================================================================
-- POLÍTICAS PARA HISTORICO_GERAL
-- ============================================================================

DROP POLICY IF EXISTS "Enable all operations for historico_geral" ON public.historico_geral;
CREATE POLICY "Enable all operations for historico_geral" ON public.historico_geral FOR ALL USING (true);

-- ============================================================================
-- POLÍTICAS PARA HISTORICO_PEDIDOS
-- ============================================================================

DROP POLICY IF EXISTS "Permitir leitura pública do histórico" ON public.historico_pedidos;
CREATE POLICY "Permitir leitura pública do histórico" ON public.historico_pedidos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir inserção pública historico_pedidos" ON public.historico_pedidos;
CREATE POLICY "Permitir inserção pública historico_pedidos" ON public.historico_pedidos FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir atualização pública historico_pedidos" ON public.historico_pedidos;
CREATE POLICY "Permitir atualização pública historico_pedidos" ON public.historico_pedidos FOR UPDATE USING (true) WITH CHECK (true);

-- ============================================================================
-- POLÍTICAS PARA PEDIDOS
-- ============================================================================

DROP POLICY IF EXISTS "Permitir leitura pública de pedidos" ON public.pedidos;
CREATE POLICY "Permitir leitura pública de pedidos" ON public.pedidos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir inserção pública de pedidos" ON public.pedidos;
CREATE POLICY "Permitir inserção pública de pedidos" ON public.pedidos FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir atualização pública pedidos" ON public.pedidos;
CREATE POLICY "Permitir atualização pública pedidos" ON public.pedidos FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir exclusão pública de pedidos" ON public.pedidos;
CREATE POLICY "Permitir exclusão pública de pedidos" ON public.pedidos FOR DELETE USING (true);

-- ============================================================================
-- POLÍTICAS PARA PRODUTO_SABORES
-- ============================================================================

DROP POLICY IF EXISTS "Leitura pública produto_sabores" ON public.produto_sabores;
CREATE POLICY "Leitura pública produto_sabores" ON public.produto_sabores FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada produto_sabores" ON public.produto_sabores;
CREATE POLICY "Inserção autenticada produto_sabores" ON public.produto_sabores FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada produto_sabores" ON public.produto_sabores;
CREATE POLICY "Atualização autenticada produto_sabores" ON public.produto_sabores FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada produto_sabores" ON public.produto_sabores;
CREATE POLICY "Exclusão autenticada produto_sabores" ON public.produto_sabores FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- ============================================================================
-- POLÍTICAS PARA PRODUTOS
-- ============================================================================

DROP POLICY IF EXISTS "Leitura pública produtos" ON public.produtos;
CREATE POLICY "Leitura pública produtos" ON public.produtos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada produtos" ON public.produtos;
CREATE POLICY "Inserção autenticada produtos" ON public.produtos FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada produtos" ON public.produtos;
CREATE POLICY "Atualização autenticada produtos" ON public.produtos FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada produtos" ON public.produtos;
CREATE POLICY "Exclusão autenticada produtos" ON public.produtos FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- ============================================================================
-- POLÍTICAS PARA SABORES
-- ============================================================================

DROP POLICY IF EXISTS "Leitura pública sabores" ON public.sabores;
CREATE POLICY "Leitura pública sabores" ON public.sabores FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada sabores" ON public.sabores;
CREATE POLICY "Inserção autenticada sabores" ON public.sabores FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada sabores" ON public.sabores;
CREATE POLICY "Atualização autenticada sabores" ON public.sabores FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada sabores" ON public.sabores;
CREATE POLICY "Exclusão autenticada sabores" ON public.sabores FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- ============================================================================
-- POLÍTICAS PARA TAMANHOS
-- ============================================================================

DROP POLICY IF EXISTS "Leitura pública tamanhos" ON public.tamanhos;
CREATE POLICY "Leitura pública tamanhos" ON public.tamanhos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada tamanhos" ON public.tamanhos;
CREATE POLICY "Inserção autenticada tamanhos" ON public.tamanhos FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada tamanhos" ON public.tamanhos;
CREATE POLICY "Atualização autenticada tamanhos" ON public.tamanhos FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada tamanhos" ON public.tamanhos;
CREATE POLICY "Exclusão autenticada tamanhos" ON public.tamanhos FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- ============================================================================
-- POLÍTICAS PARA IA_CONFIG
-- ============================================================================

DROP POLICY IF EXISTS "Usuários autenticados podem ler configurações" ON ia_config;
CREATE POLICY "Usuários autenticados podem ler configurações"
  ON ia_config FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem inserir configurações" ON ia_config;
CREATE POLICY "Usuários autenticados podem inserir configurações"
  ON ia_config FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários autenticados podem atualizar configurações" ON ia_config;
CREATE POLICY "Usuários autenticados podem atualizar configurações"
  ON ia_config FOR UPDATE
  TO authenticated
  USING (true);

-- ============================================================================
-- POLÍTICAS PARA IA_CONVERSAS
-- ============================================================================

DROP POLICY IF EXISTS "Usuários autenticados podem ler conversas" ON ia_conversas;
CREATE POLICY "Usuários autenticados podem ler conversas"
  ON ia_conversas FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem inserir conversas" ON ia_conversas;
CREATE POLICY "Usuários autenticados podem inserir conversas"
  ON ia_conversas FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários autenticados podem atualizar conversas" ON ia_conversas;
CREATE POLICY "Usuários autenticados podem atualizar conversas"
  ON ia_conversas FOR UPDATE
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem deletar conversas" ON ia_conversas;
CREATE POLICY "Usuários autenticados podem deletar conversas"
  ON ia_conversas FOR DELETE
  TO authenticated
  USING (true);

-- ============================================================================
-- POLÍTICAS PARA IA_ARQUIVOS_TEMP
-- ============================================================================

DROP POLICY IF EXISTS "Usuários autenticados podem ler arquivos" ON ia_arquivos_temp;
CREATE POLICY "Usuários autenticados podem ler arquivos"
  ON ia_arquivos_temp FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem inserir arquivos" ON ia_arquivos_temp;
CREATE POLICY "Usuários autenticados podem inserir arquivos"
  ON ia_arquivos_temp FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários autenticados podem deletar arquivos" ON ia_arquivos_temp;
CREATE POLICY "Usuários autenticados podem deletar arquivos"
  ON ia_arquivos_temp FOR DELETE
  TO authenticated
  USING (true);

-- ============================================================================
-- POLÍTICAS PARA PROFILE
-- ============================================================================

DROP POLICY IF EXISTS "Usuários autenticados podem ler profiles" ON public.profile;
CREATE POLICY "Usuários autenticados podem ler profiles"
    ON public.profile FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem inserir profiles" ON public.profile;
CREATE POLICY "Usuários autenticados podem inserir profiles"
    ON public.profile FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários autenticados podem atualizar profiles" ON public.profile;
CREATE POLICY "Usuários autenticados podem atualizar profiles"
    ON public.profile FOR UPDATE
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem deletar profiles" ON public.profile;
CREATE POLICY "Usuários autenticados podem deletar profiles"
    ON public.profile FOR DELETE
    TO authenticated
    USING (true);

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================

-- ============================================================================
-- TRIGGERS
-- ============================================================================
-- Arquivo: 05_triggers.sql
-- Descrição: Triggers para automação de processos
-- Data: 20/01/2026
-- ============================================================================

-- Trigger para atualizar timestamp em categorias
DROP TRIGGER IF EXISTS trigger_categorias_atualizado_em ON public.categorias;
CREATE TRIGGER trigger_categorias_atualizado_em 
    BEFORE UPDATE ON public.categorias 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em comandas
DROP TRIGGER IF EXISTS trigger_update_comandas_timestamp ON public.comandas;
CREATE TRIGGER trigger_update_comandas_timestamp 
    BEFORE UPDATE ON public.comandas 
    FOR EACH ROW EXECUTE FUNCTION update_comandas_updated_at();

-- Trigger para atualizar timestamp em combos
DROP TRIGGER IF EXISTS trigger_combos_atualizado_em ON public.combos;
CREATE TRIGGER trigger_combos_atualizado_em 
    BEFORE UPDATE ON public.combos 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em configuracoes
DROP TRIGGER IF EXISTS trigger_configuracoes_atualizado_em ON public.configuracoes;
CREATE TRIGGER trigger_configuracoes_atualizado_em 
    BEFORE UPDATE ON public.configuracoes 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em estoque
DROP TRIGGER IF EXISTS trigger_estoque_atualizado_em ON public.estoque;
CREATE TRIGGER trigger_estoque_atualizado_em 
    BEFORE UPDATE ON public.estoque 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em funcionarios
DROP TRIGGER IF EXISTS trigger_funcionarios_atualizado_em ON public.funcionarios;
CREATE TRIGGER trigger_funcionarios_atualizado_em 
    BEFORE UPDATE ON public.funcionarios 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em historico_pedidos
DROP TRIGGER IF EXISTS update_historico_pedidos_updated_at ON public.historico_pedidos;
CREATE TRIGGER update_historico_pedidos_updated_at 
    BEFORE UPDATE ON public.historico_pedidos 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para sincronizar status do pedido com histórico
DROP TRIGGER IF EXISTS trigger_sync_pedido_status ON public.pedidos;
CREATE TRIGGER trigger_sync_pedido_status 
    AFTER UPDATE ON public.pedidos 
    FOR EACH ROW EXECUTE FUNCTION sync_pedido_status_to_historico();

-- Trigger para atualizar timestamp em pedidos
DROP TRIGGER IF EXISTS update_pedidos_updated_at ON public.pedidos;
CREATE TRIGGER update_pedidos_updated_at 
    BEFORE UPDATE ON public.pedidos 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para atualizar timestamp em produtos
DROP TRIGGER IF EXISTS trigger_produtos_atualizado_em ON public.produtos;
CREATE TRIGGER trigger_produtos_atualizado_em 
    BEFORE UPDATE ON public.produtos 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em sabores
DROP TRIGGER IF EXISTS trigger_sabores_atualizado_em ON public.sabores;
CREATE TRIGGER trigger_sabores_atualizado_em 
    BEFORE UPDATE ON public.sabores 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em tamanhos
DROP TRIGGER IF EXISTS trigger_update_tamanhos_updated_at ON public.tamanhos;
CREATE TRIGGER trigger_update_tamanhos_updated_at 
    BEFORE UPDATE ON public.tamanhos 
    FOR EACH ROW EXECUTE FUNCTION update_tamanhos_updated_at();

-- Trigger para ia_config
DROP TRIGGER IF EXISTS update_ia_config_updated_at ON ia_config;
CREATE TRIGGER update_ia_config_updated_at
  BEFORE UPDATE ON ia_config
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger para ia_conversas
DROP TRIGGER IF EXISTS update_ia_conversas_atualizado_em ON ia_conversas;
CREATE TRIGGER update_ia_conversas_atualizado_em
  BEFORE UPDATE ON ia_conversas
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================

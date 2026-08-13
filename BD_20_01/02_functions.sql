-- ============================================================================
-- FUNÇÕES (FUNCTIONS)
-- ============================================================================
-- Arquivo: 02_functions.sql
-- Descrição: Funções auxiliares do banco de dados
-- Data: 20/01/2026
-- ============================================================================

-- Função para atualizar timestamp automaticamente
CREATE OR REPLACE FUNCTION public.atualizar_timestamp()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$function$;

-- Função para sincronizar status do pedido com histórico
CREATE OR REPLACE FUNCTION public.sync_pedido_status_to_historico()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO historico_pedidos (pedido_id, status, observacao)
    VALUES (
      COALESCE(NEW.codigo_pedido, NEW.pedido_id), 
      NEW.status, 
      'Status atualizado automaticamente para ' || NEW.status
    );
  END IF;
  RETURN NEW;
END;
$function$;

-- Função para atualizar timestamp de comandas
CREATE OR REPLACE FUNCTION public.update_comandas_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$function$;

-- Função para atualizar timestamp de tamanhos
CREATE OR REPLACE FUNCTION public.update_tamanhos_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$function$;

-- Função genérica para atualizar coluna updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$function$;

-- Função para limpar arquivos órfãos (sem conversa associada)
CREATE OR REPLACE FUNCTION limpar_arquivos_orfaos()
RETURNS INTEGER AS $$
DECLARE
  total_deletados INTEGER;
BEGIN
  DELETE FROM ia_arquivos_temp
  WHERE conversa_id IS NULL
     OR conversa_id NOT IN (SELECT id FROM ia_conversas);
  
  GET DIAGNOSTICS total_deletados = ROW_COUNT;
  RETURN total_deletados;
END;
$$ LANGUAGE plpgsql;

-- Função para obter última mensagem de uma conversa
CREATE OR REPLACE FUNCTION obter_ultima_mensagem(conversa_uuid UUID)
RETURNS JSONB AS $$
DECLARE
  ultima_msg JSONB;
BEGIN
  SELECT mensagens->-1 INTO ultima_msg
  FROM ia_conversas
  WHERE id = conversa_uuid;
  
  RETURN ultima_msg;
END;
$$ LANGUAGE plpgsql;

-- Função para contar conversas por status
CREATE OR REPLACE FUNCTION contar_conversas_por_status()
RETURNS TABLE(status TEXT, total BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT ia_conversas.status, COUNT(*)
  FROM ia_conversas
  GROUP BY ia_conversas.status;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================

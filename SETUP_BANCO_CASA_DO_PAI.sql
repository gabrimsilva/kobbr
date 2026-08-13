-- ============================================================================
-- SETUP COMPLETO DO BANCO DE DADOS - CASA DO PAI
-- ============================================================================
-- Execute este arquivo completo no SQL Editor do Supabase
-- URL: https://supabase.com/dashboard/project/zspvppvvjdbvgvpgzawb/sql
-- ============================================================================

-- ============================================================================
-- 1. EXTENSÕES
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

-- ============================================================================
-- 2. FUNÇÕES
-- ============================================================================

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

-- ============================================================================
-- 3. TABELAS
-- ============================================================================

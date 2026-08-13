-- ============================================================================
-- EXTENSÕES NECESSÁRIAS
-- ============================================================================
-- Arquivo: 01_extensions.sql
-- Descrição: Extensões do PostgreSQL necessárias para o sistema
-- Data: 20/01/2026
-- ============================================================================

-- Extensão para geração de UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- Extensão para funções criptográficas
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================

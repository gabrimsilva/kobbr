-- =====================================================
-- MIGRAÇÃO: Sistema de Cupom Fiscal e Impressão
-- =====================================================
-- 
-- Este script executa todas as migrações necessárias para
-- implementar o sistema de cupom fiscal e impressão automática.
--
-- ORDEM DE EXECUÇÃO:
-- 1. Criar tabela print_jobs
-- 2. Adicionar campos em sales
-- 3. Adicionar campos em pedidos
--
-- COMO USAR:
-- Execute este arquivo no Supabase SQL Editor ou via psql
-- =====================================================

\echo '🚀 Iniciando migração do sistema de cupom fiscal...'
\echo ''

-- ETAPA 1: Criar tabela print_jobs
\echo '📋 Criando tabela print_jobs...'
\i 01_criar_tabela_print_jobs.sql
\echo '✅ Tabela print_jobs criada'
\echo ''

-- ETAPA 2: Adicionar campos em sales
\echo '📋 Adicionando campos de cupom em sales...'
\i 02_adicionar_campos_cupom_sales.sql
\echo '✅ Campos adicionados em sales'
\echo ''

-- ETAPA 3: Adicionar campos em pedidos
\echo '📋 Adicionando campos de cupom em pedidos...'
\i 03_adicionar_campos_cupom_pedidos.sql
\echo '✅ Campos adicionados em pedidos'
\echo ''

\echo '🎉 Migração concluída com sucesso!'
\echo ''
\echo '📊 Resumo:'
\echo '  - Tabela print_jobs criada'
\echo '  - Campos receipt_html e printed_at adicionados em sales'
\echo '  - Campos receipt_html e printed_at adicionados em pedidos'
\echo '  - Índices criados para melhor performance'
\echo ''

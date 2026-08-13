-- ============================================================================
-- SCRIPT MASTER - EXECUTAR TODA A ESTRUTURA DO BANCO DE DADOS
-- ============================================================================
-- Arquivo: 00_EXECUTAR_TUDO.sql
-- Descrição: Script master que executa todos os arquivos SQL na ordem correta
-- Data: 20/01/2026
-- 
-- IMPORTANTE: Este script deve ser executado em um banco de dados Supabase
-- Os scripts são idempotentes (podem ser executados múltiplas vezes)
-- usando CREATE IF NOT EXISTS e ON CONFLICT para evitar erros
-- ============================================================================

-- ============================================================================
-- ORDEM DE EXECUÇÃO
-- ============================================================================
-- 1. Extensões (01_extensions.sql)
-- 2. Funções (02_functions.sql)
-- 3. Tabelas (03_tables.sql)
-- 4. Índices (04_indexes.sql)
-- 5. Triggers (05_triggers.sql)
-- 6. Políticas RLS (06_rls_policies.sql)
-- 7. Storage e Configurações (07_storage_and_config.sql)
-- 8. Views (08_views.sql)
-- ============================================================================

\echo '============================================================================'
\echo 'INICIANDO CRIAÇÃO/ATUALIZAÇÃO DA ESTRUTURA DO BANCO DE DADOS'
\echo '============================================================================'
\echo ''

\echo '1/7 - Criando extensões...'
\i 01_extensions.sql
\echo '✓ Extensões criadas com sucesso'
\echo ''

\echo '2/7 - Criando funções...'
\i 02_functions.sql
\echo '✓ Funções criadas com sucesso'
\echo ''

\echo '3/7 - Criando tabelas...'
\i 03_tables.sql
\echo '✓ Tabelas criadas com sucesso'
\echo ''

\echo '4/7 - Criando índices...'
\i 04_indexes.sql
\echo '✓ Índices criados com sucesso'
\echo ''

\echo '5/7 - Criando triggers...'
\i 05_triggers.sql
\echo '✓ Triggers criados com sucesso'
\echo ''

\echo '6/7 - Aplicando políticas RLS...'
\i 06_rls_policies.sql
\echo '✓ Políticas RLS aplicadas com sucesso'
\echo ''

\echo '7/8 - Configurando storage e dados iniciais...'
\i 07_storage_and_config.sql
\echo '✓ Storage e configurações aplicadas com sucesso'
\echo ''

\echo '8/8 - Criando views...'
\i 08_views.sql
\echo '✓ Views criadas com sucesso'
\echo ''

\echo '============================================================================'
\echo 'ESTRUTURA DO BANCO DE DADOS CRIADA/ATUALIZADA COM SUCESSO!'
\echo '============================================================================'
\echo ''
\echo 'Próximos passos:'
\echo '1. Verificar se todas as tabelas foram criadas corretamente'
\echo '2. Configurar as Edge Functions (se necessário)'
\echo '3. Testar as políticas RLS'
\echo '4. Inserir dados iniciais (categorias, produtos, etc.)'
\echo ''

-- ============================================================================
-- FIM DO SCRIPT MASTER
-- ============================================================================

-- ============================================================================
-- MULTI-ESTABELECIMENTO: UNICIDADE DE configuracoes POR ESTABELECIMENTO
-- ============================================================================
-- Arquivo: 10b_configuracoes_unique.sql
-- Descrição: Ajusta a regra de unicidade da tabela `public.configuracoes`.
--            Antes: `chave` era UNIQUE GLOBAL (uma única linha por chave em
--            todo o sistema). Agora, no modelo multi-tenant, cada
--            estabelecimento precisa ter seu próprio conjunto de chaves de
--            configuração. A unicidade passa a ser por estabelecimento:
--                UNIQUE (estabelecimento_id, chave)
-- Requisitos: 5.1, 11.1
-- Data: 20/01/2026
-- ============================================================================
-- ORDEM DE EXECUÇÃO (IMPORTANTE — LEIA ANTES DE RODAR):
--
--   01..08  ............ schema base (cria a tabela `configuracoes` com a
--                        constraint global `configuracoes_chave_key`).
--   09_estabelecimentos.sql / 09b_funcoes_rls.sql ... tabelas e funções base.
--   10_tenant_columns.sql ... adiciona a coluna `estabelecimento_id` (NULLABLE)
--                             a `configuracoes` e demais Tabelas_de_Dominio.
--   11_migracao_dados.sql (tarefa 4.1) ... cria/reusa o Estabelecimento_Padrao
--                             e faz o BACKFILL de `estabelecimento_id` onde nulo.
--
--   >>> ESTE ARQUIVO (10b) DEVE RODAR APÓS 11_migracao_dados.sql <<<
--
--   Por quê depois do backfill?
--     1. Enquanto `estabelecimento_id` estiver NULL em parte das linhas, a nova
--        constraint UNIQUE (estabelecimento_id, chave) não protege contra chaves
--        duplicadas entre tenants (em PostgreSQL, NULLs são considerados
--        distintos, então várias linhas com estabelecimento_id NULL e a mesma
--        `chave` seriam permitidas). Só faz sentido garantir a unicidade por
--        estabelecimento depois que todas as linhas têm um estabelecimento.
--     2. Se houver linhas pré-existentes com a mesma `chave` que serão
--        atribuídas ao MESMO Estabelecimento_Padrao durante o backfill, a nova
--        constraint as detectaria como duplicadas. Rodando após o backfill,
--        eventuais conflitos aparecem de forma clara aqui (e não escondem dados).
--
--   Observação sobre a tarefa 4.2 (12_tenant_not_null_e_rls.sql):
--     A troca de constraint poderia, alternativamente, viver dentro do
--     12_tenant_not_null_e_rls.sql (que também só roda após o backfill e aplica
--     NOT NULL + RLS). Optou-se por um arquivo dedicado e idempotente (10b) por
--     ser uma operação específica da tarefa 3.2. Se você executar o 12 e ele já
--     contiver esta mesma troca de constraint, ambos são idempotentes e podem
--     coexistir sem erro — a constraint nova só é criada se ainda não existir.
--
--   Idempotência:
--     Todo o arquivo pode ser re-executado com segurança. O DROP usa
--     IF EXISTS e a criação da nova constraint é protegida por verificação em
--     pg_constraint (bloco DO), evitando erro de "constraint já existe".
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) Remover a antiga unicidade GLOBAL de `chave`
-- ----------------------------------------------------------------------------
-- A constraint inline `chave VARCHAR NOT NULL UNIQUE` (definida em 03_tables.sql)
-- recebe, por padrão no PostgreSQL, o nome auto-gerado `configuracoes_chave_key`.
ALTER TABLE public.configuracoes
    DROP CONSTRAINT IF EXISTS configuracoes_chave_key;

-- Nome alternativo (defensivo): caso a constraint tenha sido criada
-- explicitamente com outro nome em algum ambiente, ou via UNIQUE INDEX.
-- Documentado aqui para cobrir variações de histórico de schema.
ALTER TABLE public.configuracoes
    DROP CONSTRAINT IF EXISTS configuracoes_chave_unique;
ALTER TABLE public.configuracoes
    DROP CONSTRAINT IF EXISTS uq_configuracoes_chave;

-- Caso a unicidade global tenha sido implementada como UNIQUE INDEX
-- (e não como constraint), removemos também o índice, se existir.
DROP INDEX IF EXISTS public.configuracoes_chave_key;
DROP INDEX IF EXISTS public.configuracoes_chave_idx;

-- ----------------------------------------------------------------------------
-- 2) Criar a nova unicidade POR ESTABELECIMENTO de forma idempotente
-- ----------------------------------------------------------------------------
-- Verifica em pg_constraint se a constraint já existe antes de criar, evitando
-- erro em re-execuções. A constraint cobre (estabelecimento_id, chave).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'configuracoes_estab_chave_unico'
          AND conrelid = 'public.configuracoes'::regclass
    ) THEN
        ALTER TABLE public.configuracoes
            ADD CONSTRAINT configuracoes_estab_chave_unico
            UNIQUE (estabelecimento_id, chave);
    END IF;
END $$;

-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================
-- Resultado: `configuracoes` deixa de ter unicidade global de `chave` e passa
-- a permitir a mesma `chave` em estabelecimentos diferentes, garantindo
-- unicidade apenas dentro de cada estabelecimento (estabelecimento_id, chave).
--
-- Próximo passo:
--   12_tenant_not_null_e_rls.sql (tarefa 4.2) — aplica NOT NULL em
--   estabelecimento_id (após verificação do backfill) e substitui as políticas
--   RLS permissivas por políticas por tenant. Após o NOT NULL, a coluna
--   estabelecimento_id desta constraint nunca será NULL, reforçando a unicidade.
-- ============================================================================

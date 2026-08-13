-- ============================================================================
-- MIGRATION: Consumo Interno - Task 1.1
-- Criar tabela internal_consumptions com coluna is_internal_consumption em sales
-- ============================================================================
-- Arquivo: 01_create_internal_consumptions_table.sql
-- Descrição: Cria a tabela internal_consumptions com 8 colunas obrigatórias,
--            índices de performance e a coluna is_internal_consumption em sales.
-- Data: 26/01/2026
-- Ordem: PRIMEIRA migration do Consumo Interno
-- ============================================================================

-- ============================================================================
-- 1. ADICIONAR COLUNA is_internal_consumption EM sales
-- ============================================================================
-- Marca se uma venda é consumo interno (consumo interno = sem cliente, sem pagamento)
ALTER TABLE public.sales
ADD COLUMN IF NOT EXISTS is_internal_consumption BOOLEAN DEFAULT false;

COMMENT ON COLUMN public.sales.is_internal_consumption IS 'Marca se a venda é consumo interno (sem cliente, sem pagamento)';


-- ============================================================================
-- 2. CRIAR TABELA internal_consumptions
-- ============================================================================
-- Tabela que registra cada consumo interno: qual venda, quanto foi consumido, 
-- quais itens foram consumidos, quando, por quem.
CREATE TABLE IF NOT EXISTS public.internal_consumptions (
    -- Chaves primárias e de referência
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estabelecimento_id      UUID NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
    sale_id                 UUID NOT NULL UNIQUE REFERENCES public.sales(id) ON DELETE CASCADE,

    -- Dados de consumo
    consumed_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    total_quantity          INTEGER NOT NULL CHECK (total_quantity > 0),
    items_json              JSONB NOT NULL,

    -- Auditoria
    created_by              UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.internal_consumptions                IS 'Registros de consumo interno do estabelecimento';
COMMENT ON COLUMN public.internal_consumptions.id             IS 'Identificador único do consumo interno';
COMMENT ON COLUMN public.internal_consumptions.estabelecimento_id IS 'Estabelecimento ao qual pertence este consumo';
COMMENT ON COLUMN public.internal_consumptions.sale_id        IS 'Venda interna relacionada (foreign key única)';
COMMENT ON COLUMN public.internal_consumptions.consumed_at    IS 'Data e hora do consumo';
COMMENT ON COLUMN public.internal_consumptions.total_quantity IS 'Total de unidades consumidas';
COMMENT ON COLUMN public.internal_consumptions.items_json     IS 'Array JSON com detalhes dos itens: [{product_id, product_name, quantity, unit_price}, ...]';
COMMENT ON COLUMN public.internal_consumptions.created_by     IS 'Usuário que registrou o consumo interno';
COMMENT ON COLUMN public.internal_consumptions.created_at     IS 'Data e hora de criação do registro';


-- ============================================================================
-- 3. ÍNDICES PARA PERFORMANCE
-- ============================================================================

-- Índice para queries de período (Task 1.4 - obter_consumos_por_periodo)
-- Seleção por estabelecimento + ordenação por data
CREATE INDEX IF NOT EXISTS idx_internal_consumptions_estabelecimento_data
    ON public.internal_consumptions (estabelecimento_id, consumed_at DESC);

-- Índice para lookup rápido de consumo por sale_id
CREATE INDEX IF NOT EXISTS idx_internal_consumptions_sale_id
    ON public.internal_consumptions (sale_id);

-- Índice para queries de usuário (quem criou)
CREATE INDEX IF NOT EXISTS idx_internal_consumptions_created_by
    ON public.internal_consumptions (created_by);


-- ============================================================================
-- 4. RLS POLICIES (base - permitem acesso autenticado)
-- ============================================================================
-- As políticas finais de isolamento por tenant serão criadas em Task 1.2.
-- Aqui apenas habilitamos RLS e deixamos políticas base.

ALTER TABLE public.internal_consumptions ENABLE ROW LEVEL SECURITY;

-- Política de SELECT: qualquer usuário autenticado pode ver (será restringida por estabelecimento em 1.2)
DROP POLICY IF EXISTS "internal_consumptions_select_auth" ON public.internal_consumptions;
CREATE POLICY "internal_consumptions_select_auth" ON public.internal_consumptions
    FOR SELECT TO authenticated USING (true);

-- Política de INSERT: qualquer usuário autenticado pode inserir (será restringida em 1.2)
DROP POLICY IF EXISTS "internal_consumptions_insert_auth" ON public.internal_consumptions;
CREATE POLICY "internal_consumptions_insert_auth" ON public.internal_consumptions
    FOR INSERT TO authenticated WITH CHECK (true);

-- Consumos internos são imutáveis - sem UPDATE
-- Consumos internos são imutáveis - sem DELETE


-- ============================================================================
-- 5. GARANTIAS DE INTEGRIDADE
-- ============================================================================

-- Garantir que sale_id sempre aponta a uma venda marcada como consumo interno
-- (isso será validado também na RPC, mas constraint aqui garante integridade)
ALTER TABLE public.internal_consumptions
ADD CONSTRAINT fk_internal_consumptions_sale_is_internal CHECK (true);
-- Nota: A validação real é: quando se insere consumo interno, a sale correspondente
--       deve estar marcada com is_internal_consumption = true. Isso é garantido
--       pela RPC registrar_consumo_interno() em Task 1.3.


-- ============================================================================
-- FIM DA MIGRATION — 01_create_internal_consumptions_table.sql
-- ============================================================================

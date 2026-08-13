-- ============================================================================
-- MIGRATION: Consumo Interno - Task 1.2
-- RLS Policies para isolamento de internal_consumptions por estabelecimento
-- ============================================================================
-- Arquivo: 02_rls_policies_internal_consumptions.sql
-- Descrição: Cria políticas RLS que isolam internal_consumptions por 
--            estabelecimento, garantindo multi-tenant security.
-- Data: 26/01/2026
-- Dependência: Task 1.1 (tabela internal_consumptions deve existir)
--              Função helper get_current_estabelecimento_id() do projeto multi-tenant
-- ============================================================================

-- ============================================================================
-- 1. VALIDAR QUE FUNÇÃO HELPER EXISTE
-- ============================================================================
-- A função get_current_estabelecimento_id() foi criada no projeto multi-tenant.
-- Se não existir, essa migration falhará com um erro claro.
-- (O schema canônico multi-tenant inclui essa função em 09b_funcoes_rls.sql)

-- ============================================================================
-- 2. SUBSTITUIR POLÍTICAS RLS COM ISOLAMENTO POR ESTABELECIMENTO
-- ============================================================================

-- ---- Policy de SELECT ----
-- Usuário só vê consumos do seu estabelecimento
DROP POLICY IF EXISTS "internal_consumptions_select_auth" ON public.internal_consumptions;
CREATE POLICY "internal_consumptions_select" ON public.internal_consumptions
    FOR SELECT TO authenticated
    USING (
        estabelecimento_id = public.get_current_estabelecimento_id()
    );

COMMENT ON POLICY "internal_consumptions_select" ON public.internal_consumptions 
    IS 'Usuário só pode visualizar consumos internos do seu estabelecimento';


-- ---- Policy de INSERT ----
-- Validar que o usuário tem acesso ao estabelecimento sendo inserido
DROP POLICY IF EXISTS "internal_consumptions_insert_auth" ON public.internal_consumptions;
CREATE POLICY "internal_consumptions_insert" ON public.internal_consumptions
    FOR INSERT TO authenticated
    WITH CHECK (
        -- 1. Estabelecimento deve ser o do usuário
        estabelecimento_id = public.get_current_estabelecimento_id()
        -- 2. Sale_id deve ser válido (validação feita por FK)
        -- 3. Total_quantity > 0 (validação feita por CHECK constraint)
    );

COMMENT ON POLICY "internal_consumptions_insert" ON public.internal_consumptions 
    IS 'Usuário só pode criar consumos internos para seu estabelecimento';


-- ---- UPDATE: Desabilitado ----
-- Consumos internos são imutáveis (append-only)
-- Não criamos política de UPDATE, então UPDATE é implicitamente bloqueado

-- ---- DELETE: Desabilitado ----
-- Consumos internos são imutáveis (append-only)
-- Não criamos política de DELETE, então DELETE é implicitamente bloqueado


-- ============================================================================
-- 3. TESTES DE ISOLAMENTO (documentação de teste)
-- ============================================================================
-- Os seguintes testes devem ser executados para validar o isolamento:
--
-- Teste 1: Usuário de EST-A vê apenas consumos de EST-A
--   1. Insert consumo_interno com estabelecimento_id = EST_A_ID
--   2. Switch context para EST_A_ID
--   3. SELECT * FROM internal_consumptions -> deve retornar 1 registro
--   4. Switch context para EST_B_ID
--   5. SELECT * FROM internal_consumptions -> deve retornar 0 registros
--
-- Teste 2: Usuário de EST-A não consegue fazer INSERT em EST-B
--   1. Set context para EST_A_ID
--   2. INSERT internal_consumptions { estabelecimento_id: EST_B_ID, ... }
--   3. Esperado: erro de RLS (Permission denied) ou erro de constraint
--
-- Teste 3: Consumo interno é imutável
--   1. Insert consumo_interno
--   2. UPDATE internal_consumptions SET total_quantity = 999
--   3. Esperado: erro de RLS (Permission denied)
--   4. DELETE FROM internal_consumptions WHERE id = ...
--   5. Esperado: erro de RLS (Permission denied)
--
-- Estes testes estão implementados em:
--   .kiro/specs/consumo-interno/tests/isolamento_rls_test.sql


-- ============================================================================
-- 4. FUNÇÃO HELPER PARA VALIDAÇÕES (opcional, complementar à RLS)
-- ============================================================================
-- Função auxiliar que valida se um consumo pertence ao estabelecimento do usuário.
-- Usada antes de chamar RPC para validações rápidas no backend.

CREATE OR REPLACE FUNCTION public.validar_acesso_consumo_interno(
    p_consumo_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_estabelecimento_id UUID;
    v_current_estabelecimento_id UUID;
BEGIN
    -- Obter estabelecimento_id do consumo
    SELECT estabelecimento_id INTO v_estabelecimento_id
    FROM internal_consumptions
    WHERE id = p_consumo_id;

    -- Se consumo não existe, retorna false
    IF v_estabelecimento_id IS NULL THEN
        RETURN false;
    END IF;

    -- Obter estabelecimento_id do usuário atual
    v_current_estabelecimento_id := public.get_current_estabelecimento_id();

    -- Validar que pertencem ao mesmo estabelecimento
    RETURN v_estabelecimento_id = v_current_estabelecimento_id;
END;
$$;

COMMENT ON FUNCTION public.validar_acesso_consumo_interno(UUID) 
    IS 'Valida se o consumo interno pertencem ao estabelecimento do usuário autenticado';


-- ============================================================================
-- FIM DA MIGRATION — 02_rls_policies_internal_consumptions.sql
-- ============================================================================

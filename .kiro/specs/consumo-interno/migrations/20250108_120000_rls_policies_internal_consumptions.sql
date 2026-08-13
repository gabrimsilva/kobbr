-- Migration: Create RLS Policies for internal_consumptions Table
-- Created: 2025-01-08
-- Description: Implements Row Level Security (RLS) policies for internal_consumptions table
--              to ensure data isolation by estabelecimento_id

-- ===== UP MIGRATION =====

-- 1. Enable RLS on internal_consumptions table (if not already enabled)
ALTER TABLE public.internal_consumptions ENABLE ROW LEVEL SECURITY;

-- ===== RLS POLICIES FOR internal_consumptions =====

-- 2. Policy: SELECT - Users can only see consumptions from their authorized establishment(s)
-- Users with admin_geral can see all, others see only their establishment's data
DROP POLICY IF EXISTS "internal_consumptions_select" ON public.internal_consumptions;
CREATE POLICY "internal_consumptions_select" ON public.internal_consumptions
    FOR SELECT TO authenticated
    USING (
        -- Allow access if estabelecimento_id matches the user's authorized establishments
        estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario())
    );

COMMENT ON POLICY "internal_consumptions_select" ON public.internal_consumptions IS
    'SELECT policy: users can only see consumptions from establishments they are authorized to access. '
    'Uses fn_estabelecimentos_do_usuario() which returns all establishments for admin_geral, '
    'and only the user''s linked establishment for other profiles.';

-- 3. Policy: INSERT - Users can only insert consumptions for their authorized establishment(s)
-- Validates that the user is inserting a consumption for an establishment they have access to
DROP POLICY IF EXISTS "internal_consumptions_insert" ON public.internal_consumptions;
CREATE POLICY "internal_consumptions_insert" ON public.internal_consumptions
    FOR INSERT TO authenticated
    WITH CHECK (
        -- Validate that the estabelecimento_id being inserted is within the user's authorized establishments
        estabelecimento_id IN (SELECT public.fn_estabelecimentos_do_usuario())
    );

COMMENT ON POLICY "internal_consumptions_insert" ON public.internal_consumptions IS
    'INSERT policy: users can only insert consumptions for establishments they are authorized to access. '
    'Validates estabelecimento_id against fn_estabelecimentos_do_usuario() to prevent cross-tenant writes.';

-- 4. NO UPDATE policy - Consumptions are immutable once created
-- By not creating an UPDATE policy with RLS enabled, all UPDATE attempts are blocked
COMMENT ON TABLE public.internal_consumptions IS
    'Internal consumptions are immutable: no UPDATE policy is defined. '
    'RLS is enabled, so UPDATE attempts will be denied by default (Req 3 / Design: consumos são imutáveis após INSERT).';

-- 5. NO DELETE policy - Consumptions are preserved for audit trail
-- By not creating a DELETE policy with RLS enabled, all DELETE attempts are blocked
COMMENT ON CONSTRAINT "internal_consumptions_pkey" ON public.internal_consumptions IS
    'Primary key. Internal consumptions are append-only (no DELETE). '
    'Auditability requirement: registros de consumo são histórico permanente.';

-- ===== DOWN MIGRATION (Rollback) =====
-- To rollback, execute the following SQL:
/*
-- Drop RLS policies
DROP POLICY IF EXISTS "internal_consumptions_select" ON public.internal_consumptions;
DROP POLICY IF EXISTS "internal_consumptions_insert" ON public.internal_consumptions;

-- Disable RLS (optional - only if this is the last policy for this table)
-- ALTER TABLE public.internal_consumptions DISABLE ROW LEVEL SECURITY;
*/

-- ===== VERIFICATION NOTES =====
-- After applying this migration:
--
-- 1. Test SELECT isolation:
--    - User from estabelecimento A tries to SELECT from internal_consumptions
--    - Should see only records where estabelecimento_id = A's establishment
--
-- 2. Test INSERT validation:
--    - User from estabelecimento A tries to INSERT with estabelecimento_id = B's establishment
--    - Should be rejected (RLS policy blocks the insert)
--
-- 3. Test UPDATE/DELETE blocking:
--    - User tries UPDATE or DELETE on internal_consumptions records
--    - Should be rejected (no policies for UPDATE/DELETE means all blocked)
--
-- 4. RLS enabled check:
--    SELECT tablename FROM pg_tables WHERE tablename = 'internal_consumptions';
--    SELECT * FROM pg_policy WHERE tablename = 'internal_consumptions';

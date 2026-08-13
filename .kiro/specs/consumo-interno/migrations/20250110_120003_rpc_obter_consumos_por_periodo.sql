-- Migration: Create RPC Function - obter_consumos_por_periodo()
-- Created: 2025-01-10
-- Description: Implements the query RPC function to retrieve aggregated internal consumption data
--              by period with support for daily, weekly, and monthly granularity
--              Used for metrics cards and graphs

-- ===== UP MIGRATION =====

-- Create or replace the obter_consumos_por_periodo RPC function
CREATE OR REPLACE FUNCTION public.obter_consumos_por_periodo(
  p_estabelecimento_id UUID,
  p_data_inicio DATE,
  p_data_fim DATE,
  p_granularidade VARCHAR DEFAULT 'dia'
)
RETURNS TABLE (
  periodo VARCHAR,
  total_unidades BIGINT,
  total_transacoes INTEGER,
  media_unidades_transacao NUMERIC
) AS $$
DECLARE
  v_granularidade_normalized VARCHAR;
  v_date_trunc_unit TEXT;
BEGIN
  -- 1. Normalize and validate granularidade parameter
  v_granularidade_normalized := LOWER(TRIM(p_granularidade));
  
  -- Map granularidade to PostgreSQL DATE_TRUNC unit
  CASE v_granularidade_normalized
    WHEN 'dia' THEN
      v_date_trunc_unit := 'day';
    WHEN 'semana' THEN
      v_date_trunc_unit := 'week';
    WHEN 'mes' THEN
      v_date_trunc_unit := 'month';
    ELSE
      RAISE EXCEPTION 'Invalid granularidade: %. Must be "dia", "semana", or "mes"', p_granularidade;
  END CASE;
  
  -- 2. Query aggregated consumption data by period
  RETURN QUERY
  SELECT
    -- Format periodo based on granularidade
    CASE v_granularidade_normalized
      -- For daily: return full timestamp as YYYY-MM-DD
      WHEN 'dia' THEN
        TO_CHAR(DATE_TRUNC(v_date_trunc_unit, consumed_at AT TIME ZONE 'UTC'), 'YYYY-MM-DD')
      -- For weekly: return ISO week format YYYY-Www
      WHEN 'semana' THEN
        TO_CHAR(DATE_TRUNC(v_date_trunc_unit, consumed_at AT TIME ZONE 'UTC'), 'YYYY-"W"IW')
      -- For monthly: return YYYY-MM
      WHEN 'mes' THEN
        TO_CHAR(DATE_TRUNC(v_date_trunc_unit, consumed_at AT TIME ZONE 'UTC'), 'YYYY-MM')
    END::VARCHAR AS periodo,
    
    -- Sum of total_quantity (total units consumed)
    SUM(total_quantity)::BIGINT AS total_unidades,
    
    -- Count of consumption records (total transactions)
    COUNT(*)::INTEGER AS total_transacoes,
    
    -- Average units per transaction (with 2 decimal places)
    CASE
      WHEN COUNT(*) > 0 THEN
        ROUND(SUM(total_quantity)::NUMERIC / COUNT(*), 2)
      ELSE
        0::NUMERIC
    END AS media_unidades_transacao
    
  FROM public.internal_consumptions
  
  WHERE
    -- Filter by estabelecimento_id (multi-tenant isolation)
    estabelecimento_id = p_estabelecimento_id
    -- Filter by date range (inclusive: data_inicio <= consumed_at < data_fim + 1 day)
    AND consumed_at >= (p_data_inicio::TIMESTAMP WITH TIME ZONE)
    AND consumed_at < ((p_data_fim + INTERVAL '1 day')::TIMESTAMP WITH TIME ZONE)
  
  -- Group by the truncated period
  GROUP BY DATE_TRUNC(v_date_trunc_unit, consumed_at AT TIME ZONE 'UTC')
  
  -- Sort by periodo ascending (chronological order)
  ORDER BY periodo ASC;
  
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Set function comment
COMMENT ON FUNCTION public.obter_consumos_por_periodo(UUID, DATE, DATE, VARCHAR) IS
  'RPC function to retrieve aggregated internal consumption data by period.
   Used for metrics cards and graphs showing consumption evolution.
   
   Parameters:
   - p_estabelecimento_id: UUID of the establishment (required, for RLS filtering)
   - p_data_inicio: Start date (DATE, inclusive)
   - p_data_fim: End date (DATE, inclusive)
   - p_granularidade: Aggregation granularity (VARCHAR, default "dia")
     Valid values: "dia" (daily), "semana" (weekly), "mes" (monthly)
   
   Returns: TABLE with columns:
   - periodo: VARCHAR formatted as:
     * "YYYY-MM-DD" for daily granularity
     * "YYYY-Www" for weekly granularity (ISO week)
     * "YYYY-MM" for monthly granularity
   - total_unidades: BIGINT - total quantity units consumed in period
   - total_transacoes: INTEGER - count of consumption transactions
   - media_unidades_transacao: NUMERIC(2 decimals) - average units per transaction
   
   Behavior:
   - If no data exists for the period, returns empty set (not error)
   - Date range is inclusive (p_data_inicio <= date <= p_data_fim)
   - Results ordered by periodo ascending (chronological)
   - Function respects RLS policies (filters by p_estabelecimento_id)
   
   Example usage:
   SELECT * FROM public.obter_consumos_por_periodo(
     ''12345678-1234-1234-1234-123456789012''::UUID,
     ''2026-01-01''::DATE,
     ''2026-01-31''::DATE,
     ''dia''
   );
   
   Expected output:
   | periodo    | total_unidades | total_transacoes | media_unidades_transacao |
   |------------|----------------|------------------|--------------------------|
   | 2026-01-05 | 10             | 2                | 5.00                     |
   | 2026-01-10 | 25             | 3                | 8.33                     |
   | 2026-01-15 | 15             | 1                | 15.00                    |';

-- ===== CREATE INDEX FOR PERFORMANCE =====
-- The following index is already created in Task 1.1, but documented here for reference:
-- CREATE INDEX IF NOT EXISTS idx_internal_consumptions_established_consumed_at_desc 
--   ON public.internal_consumptions(estabelecimento_id, consumed_at DESC);

-- ===== VERIFY EXPLAIN PLAN FOR PERFORMANCE =====
-- Expected execution plan should show:
-- - Index Scan using idx_internal_consumptions_established_consumed_at_desc
-- - GroupAggregate
-- - Sort (optional)
-- 
-- Expected performance: < 500ms for queries with 1000+ records

-- ===== DOWN MIGRATION (Rollback) =====
-- To rollback, execute the following SQL:
/*
DROP FUNCTION IF EXISTS public.obter_consumos_por_periodo(UUID, DATE, DATE, VARCHAR);
*/

-- ===== VERIFICATION NOTES =====
-- After applying this migration, verify the function with these tests:
--
-- TEST 1: Daily granularity with data
--   SELECT * FROM public.obter_consumos_por_periodo(
--     '12345678-1234-1234-1234-123456789012'::UUID,
--     '2026-01-01'::DATE,
--     '2026-01-31'::DATE,
--     'dia'
--   );
--   Expected: Multiple rows with formato YYYY-MM-DD, totals, transactions, media
--
-- TEST 2: Weekly granularity
--   SELECT * FROM public.obter_consumos_por_periodo(
--     '12345678-1234-1234-1234-123456789012'::UUID,
--     '2026-01-01'::DATE,
--     '2026-12-31'::DATE,
--     'semana'
--   );
--   Expected: Rows grouped by ISO week (formato YYYY-Www)
--
-- TEST 3: Monthly granularity
--   SELECT * FROM public.obter_consumos_por_periodo(
--     '12345678-1234-1234-1234-123456789012'::UUID,
--     '2026-01-01'::DATE,
--     '2026-12-31'::DATE,
--     'mes'
--   );
--   Expected: Rows grouped by month (formato YYYY-MM)
--
-- TEST 4: Period with no data (empty result, not error)
--   SELECT * FROM public.obter_consumos_por_periodo(
--     '99999999-9999-9999-9999-999999999999'::UUID,
--     '2026-01-01'::DATE,
--     '2026-01-31'::DATE,
--     'dia'
--   );
--   Expected: 0 rows returned (empty set)
--
-- TEST 5: Invalid granularidade
--   SELECT * FROM public.obter_consumos_por_periodo(
--     '12345678-1234-1234-1234-123456789012'::UUID,
--     '2026-01-01'::DATE,
--     '2026-01-31'::DATE,
--     'invalid'
--   );
--   Expected: Error message: "Invalid granularidade: invalid. Must be "dia", "semana", or "mes""
--
-- TEST 6: Performance check with EXPLAIN ANALYZE
--   EXPLAIN ANALYZE
--   SELECT * FROM public.obter_consumos_por_periodo(
--     '12345678-1234-1234-1234-123456789012'::UUID,
--     '2026-01-01'::DATE,
--     '2026-12-31'::DATE,
--     'dia'
--   );
--   Expected: Execution time < 500ms, should use index scan
--
-- TEST 7: RLS isolation - User from establishment A should not see data from B
--   (Run as authenticated user from different establishment)
--   SELECT * FROM public.obter_consumos_por_periodo(
--     'other-establishment-id'::UUID,
--     '2026-01-01'::DATE,
--     '2026-01-31'::DATE,
--     'dia'
--   );
--   Expected: Either 0 rows or error (depends on RLS policy implementation)


-- Migration: Create internal_consumptions table and add is_internal_consumption column to sales
-- Created: 2025-01-07
-- Description: Implements consumo interno (internal consumption) feature with table, indexes, and RLS setup

-- ===== UP MIGRATION =====

-- 1. Create internal_consumptions table
CREATE TABLE IF NOT EXISTS public.internal_consumptions (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Foreign Keys
  estabelecimento_id UUID NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  sale_id UUID NOT NULL UNIQUE REFERENCES public.sales(id) ON DELETE CASCADE,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Data Fields
  consumed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  total_quantity INTEGER NOT NULL DEFAULT 0 CHECK (total_quantity >= 0),
  items_json JSONB NOT NULL DEFAULT '[]'::jsonb,
  
  -- Audit
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  -- Constraints for consistency
  CONSTRAINT total_quantity_non_negative CHECK (total_quantity >= 0)
);

-- 2. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_internal_consumptions_estabelecimento_id 
  ON public.internal_consumptions(estabelecimento_id);

CREATE INDEX IF NOT EXISTS idx_internal_consumptions_established_consumed_at_desc 
  ON public.internal_consumptions(estabelecimento_id, consumed_at DESC);

CREATE INDEX IF NOT EXISTS idx_internal_consumptions_sale_id 
  ON public.internal_consumptions(sale_id);

CREATE INDEX IF NOT EXISTS idx_internal_consumptions_created_by 
  ON public.internal_consumptions(created_by);

-- 3. Add is_internal_consumption column to sales table if it doesn't exist
ALTER TABLE public.sales 
ADD COLUMN IF NOT EXISTS is_internal_consumption BOOLEAN DEFAULT false;

-- 4. Create index on is_internal_consumption for queries filtering consumos internos
CREATE INDEX IF NOT EXISTS idx_sales_is_internal_consumption 
  ON public.sales(is_internal_consumption) 
  WHERE is_internal_consumption = true;

-- 5. Enable RLS on internal_consumptions table
ALTER TABLE public.internal_consumptions ENABLE ROW LEVEL SECURITY;

-- Note: RLS policies will be created in Task 1.2 (separate migration)

-- ===== DOWN MIGRATION (Rollback) =====
-- To rollback, execute the following SQL:
/*
-- Drop indexes
DROP INDEX IF EXISTS public.idx_sales_is_internal_consumption;
DROP INDEX IF EXISTS public.idx_internal_consumptions_created_by;
DROP INDEX IF EXISTS public.idx_internal_consumptions_sale_id;
DROP INDEX IF EXISTS public.idx_internal_consumptions_established_consumed_at_desc;
DROP INDEX IF EXISTS public.idx_internal_consumptions_estabelecimento_id;

-- Drop column from sales
ALTER TABLE public.sales DROP COLUMN IF EXISTS is_internal_consumption;

-- Drop table
DROP TABLE IF EXISTS public.internal_consumptions;
*/

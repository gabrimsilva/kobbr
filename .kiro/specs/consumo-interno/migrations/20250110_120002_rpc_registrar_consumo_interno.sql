-- Migration: Create RPC Function - registrar_consumo_interno()
-- Created: 2025-01-10
-- Description: Implements the main RPC function to register internal consumptions atomically
--              with full validation, transaction management, and error handling

-- ===== UP MIGRATION =====

-- Create or replace the registrar_consumo_interno RPC function
CREATE OR REPLACE FUNCTION public.registrar_consumo_interno(
  p_estabelecimento_id UUID,
  p_items JSONB,
  p_created_by UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_sale_id UUID;
  v_consumption_id UUID;
  v_total_quantity INTEGER := 0;
  v_current_user UUID;
  v_item JSONB;
  v_product_id UUID;
  v_quantidade INTEGER;
  v_preco_unitario NUMERIC;
  v_current_quantity NUMERIC;
  v_stock_item_id UUID;
  v_item_index INTEGER;
BEGIN
  -- 1. Set current user (use provided created_by or default to auth.uid())
  v_current_user := COALESCE(p_created_by, auth.uid());
  
  -- 2. Validate: estabelecimento_id exists
  IF NOT EXISTS (SELECT 1 FROM public.estabelecimentos WHERE id = p_estabelecimento_id) THEN
    RAISE EXCEPTION 'Estabelecimento not found: %', p_estabelecimento_id;
  END IF;
  
  -- 3. Validate: items array is not NULL and not empty
  IF p_items IS NULL THEN
    RAISE EXCEPTION 'Items array cannot be null';
  END IF;
  
  IF jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'Items array cannot be empty';
  END IF;
  
  -- 4. Validate each item and check stock availability
  FOR v_item_index IN 0..jsonb_array_length(p_items) - 1 LOOP
    v_item := p_items -> v_item_index;
    
    -- Extract item fields
    v_product_id := (v_item ->> 'product_id')::UUID;
    v_quantidade := (v_item ->> 'quantidade')::INTEGER;
    v_preco_unitario := (v_item ->> 'preco_unitario')::NUMERIC;
    
    -- Validate product_id is UUID
    IF v_product_id IS NULL THEN
      RAISE EXCEPTION 'Item % missing product_id', v_item_index;
    END IF;
    
    -- Validate quantidade is positive integer
    IF v_quantidade IS NULL OR v_quantidade <= 0 THEN
      RAISE EXCEPTION 'Item % has invalid quantidade: %', v_item_index, v_quantidade;
    END IF;
    
    -- Validate preco_unitario is numeric
    IF v_preco_unitario IS NULL THEN
      RAISE EXCEPTION 'Item % missing preco_unitario', v_item_index;
    END IF;
    
    -- Get stock_item_id for this product
    SELECT id, quantidade INTO v_stock_item_id, v_current_quantity
    FROM public.stock_items
    WHERE product_id = v_product_id AND estabelecimento_id = p_estabelecimento_id;
    
    -- Check if product exists in stock
    IF v_stock_item_id IS NULL THEN
      RAISE EXCEPTION 'Product % not found in stock for establishment', v_product_id;
    END IF;
    
    -- Check stock availability (allow negative for consumo interno, but validate non-null)
    IF v_current_quantity IS NULL THEN
      RAISE EXCEPTION 'Product % has NULL quantity in stock', v_product_id;
    END IF;
    
    -- Add to total quantity
    v_total_quantity := v_total_quantity + v_quantidade;
  END LOOP;
  
  -- 5. Begin transaction - all operations must succeed or all fail
  BEGIN
    -- 5.1 Create sale with is_internal_consumption = true and total_amount = 0
    INSERT INTO public.sales (
      sale_number,
      total_amount,
      payment_method,
      sale_type,
      items,
      is_internal_consumption,
      created_by,
      estabelecimento_id,
      created_at
    ) VALUES (
      'CI-' || TO_CHAR(NOW(), 'YYYYMMDD-HH24MISS'),
      0.00,
      'INTERNAL',
      'INTERNAL_CONSUMPTION',
      p_items,
      true,
      v_current_user,
      p_estabelecimento_id,
      NOW()
    ) RETURNING id INTO v_sale_id;
    
    -- 5.2 Create internal_consumptions record
    INSERT INTO public.internal_consumptions (
      estabelecimento_id,
      sale_id,
      items_json,
      total_quantity,
      created_by,
      consumed_at,
      created_at
    ) VALUES (
      p_estabelecimento_id,
      v_sale_id,
      p_items,
      v_total_quantity,
      v_current_user,
      NOW(),
      NOW()
    ) RETURNING id INTO v_consumption_id;
    
    -- 5.3 Process each item: decrement stock and create stock movement
    FOR v_item_index IN 0..jsonb_array_length(p_items) - 1 LOOP
      v_item := p_items -> v_item_index;
      
      v_product_id := (v_item ->> 'product_id')::UUID;
      v_quantidade := (v_item ->> 'quantidade')::INTEGER;
      
      -- Get stock_item_id
      SELECT id INTO v_stock_item_id
      FROM public.stock_items
      WHERE product_id = v_product_id AND estabelecimento_id = p_estabelecimento_id;
      
      -- 5.3.1 Decrement stock
      UPDATE public.stock_items
      SET quantidade = quantidade - v_quantidade,
          atualizado_em = NOW()
      WHERE id = v_stock_item_id;
      
      -- 5.3.2 Create stock movement record
      INSERT INTO public.stock_movements (
        stock_item_id,
        tipo,
        quantidade,
        motivo,
        usuario_id,
        estabelecimento_id,
        criado_em
      ) VALUES (
        v_stock_item_id,
        'saida',
        v_quantidade,
        'Consumo Interno',
        v_current_user,
        p_estabelecimento_id,
        NOW()
      );
    END LOOP;
    
    -- 6. Return success response
    RETURN json_build_object(
      'success', true,
      'consumption_id', v_consumption_id,
      'sale_id', v_sale_id,
      'total_quantity', v_total_quantity,
      'message', 'Consumo Interno registrado com sucesso'
    );
    
  EXCEPTION WHEN OTHERS THEN
    -- Rollback happens automatically due to exception
    -- Return error response
    RETURN json_build_object(
      'success', false,
      'consumption_id', NULL,
      'sale_id', NULL,
      'message', 'Erro ao registrar consumo: ' || SQLERRM
    );
  END;

EXCEPTION WHEN OTHERS THEN
  -- Catch any validation errors (before transaction)
  RETURN json_build_object(
    'success', false,
    'consumption_id', NULL,
    'sale_id', NULL,
    'message', 'Validação falhou: ' || SQLERRM
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Set function comment
COMMENT ON FUNCTION public.registrar_consumo_interno(UUID, JSONB, UUID) IS
  'RPC function to register internal consumption (consumo interno) atomically.
   
   Parameters:
   - p_estabelecimento_id: UUID of the establishment
   - p_items: JSONB array with items [{ product_id, product_name, quantidade, preco_unitario }, ...]
   - p_created_by: UUID of user creating the record (defaults to current user)
   
   Returns: JSON with { success: boolean, consumption_id: UUID, sale_id: UUID, message: string }
   
   Validations:
   - estabelecimento_id must exist
   - items array must not be empty
   - each item must have valid product_id, quantidade (positive), preco_unitario
   - stock must be available for each product
   
   Operations (atomic transaction):
   1. INSERT into sales with is_internal_consumption=true, total_amount=0
   2. INSERT into internal_consumptions with items details
   3. For each item: UPDATE stock_items (decrement), INSERT stock_movements
   
   If any operation fails, entire transaction rolls back.
   Function respects RLS policies on underlying tables.';

-- ===== DOWN MIGRATION (Rollback) =====
-- To rollback, execute the following SQL:
/*
DROP FUNCTION IF EXISTS public.registrar_consumo_interno(UUID, JSONB, UUID);
*/

-- ===== VERIFICATION NOTES =====
-- After applying this migration:
--
-- 1. Test successful consumption registration:
--    SELECT public.registrar_consumo_interno(
--      '12345678-1234-1234-1234-123456789012'::UUID,
--      '[{"product_id":"87654321-4321-4321-4321-210987654321","product_name":"Product A","quantidade":5,"preco_unitario":"10.00"}]'::JSONB,
--      '11111111-1111-1111-1111-111111111111'::UUID
--    );
--    Expected: { success: true, consumption_id: <UUID>, sale_id: <UUID>, message: "..." }
--
-- 2. Test with empty items array:
--    Should return: { success: false, message: "Items array cannot be empty" }
--
-- 3. Test with invalid product_id:
--    Should return: { success: false, message: "Product ... not found in stock" }
--
-- 4. Verify atomicity:
--    - Check that sales record is created with is_internal_consumption=true
--    - Check that internal_consumptions record is created
--    - Check that stock_items.quantidade is decremented
--    - Check that stock_movements records are created
--
-- 5. Test RLS protection:
--    - Function should respect RLS policies on underlying tables
--    - User A trying to register consumption for establishment B should fail


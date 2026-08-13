-- ============================================================================
-- MIGRATION: Consumo Interno - Task 1.3
-- RPC Function: registrar_consumo_interno()
-- ============================================================================
-- Arquivo: 03_rpc_registrar_consumo_interno.sql
-- Descrição: RPC que processa consumo interno de forma ATÔMICA:
--            1. Cria venda interna (sem cliente, sem pagamento)
--            2. Registra consumo em internal_consumptions
--            3. Atualiza stock_items (decrementa quantidade)
--            4. Cria movimento de estoque (saída)
-- Data: 26/01/2026
-- Dependência: Task 1.1-1.2 (tabelas, RLS, função helper)
--              Tabelas: sales, internal_consumptions, stock_items, stock_movements, estabelecimentos
-- ============================================================================

CREATE OR REPLACE FUNCTION public.registrar_consumo_interno(
    p_estabelecimento_id UUID,
    p_items JSONB,
    p_created_by UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_sale_id                   UUID;
    v_consumption_id            UUID;
    v_sale_number               VARCHAR;
    v_established_user_id       UUID;
    v_item                      RECORD;
    v_product_id                UUID;
    v_product_name              VARCHAR;
    v_quantity_requested        INTEGER;
    v_quantity_available        INTEGER;
    v_movement_id               UUID;
    v_total_quantity            INTEGER := 0;
    v_error_message             VARCHAR;
    v_current_user_id           UUID;
    v_current_estabelecimento   UUID;
BEGIN
    -- ========================================================================
    -- 1. VALIDAÇÕES INICIAIS
    -- ========================================================================

    -- Obter usuário autenticado
    v_current_user_id := auth.uid();
    IF v_current_user_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Usuário não autenticado'
        );
    END IF;

    -- Validar que created_by é fornecido OU usar auth.uid()
    IF p_created_by IS NULL THEN
        v_established_user_id := v_current_user_id;
    ELSE
        v_established_user_id := p_created_by;
    END IF;

    -- Obter estabelecimento do usuário atual
    v_current_estabelecimento := public.get_current_estabelecimento_id();
    IF v_current_estabelecimento IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Estabelecimento do usuário não identificado'
        );
    END IF;

    -- Validar que estabelecimento_id é o do usuário (RLS)
    IF p_estabelecimento_id != v_current_estabelecimento THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Acesso negado: estabelecimento informado não corresponde ao usuário'
        );
    END IF;

    -- Validar que estabelecimento existe
    IF NOT EXISTS (SELECT 1 FROM estabelecimentos WHERE id = p_estabelecimento_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', format('Estabelecimento %s não existe', p_estabelecimento_id::text)
        );
    END IF;

    -- Validar items array
    IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Items não pode ser vazio'
        );
    END IF;


    -- ========================================================================
    -- 2. VALIDAR ESTOQUE ANTES DE INICIAR TRANSAÇÃO
    -- ========================================================================
    -- (Validação rápida: garante que temos stock suficiente antes de fazer tudo)

    FOR v_item IN
        SELECT 
            (items->>'product_id')::uuid as product_id,
            (items->>'quantity')::integer as quantity
        FROM jsonb_array_elements(p_items) as items
    LOOP
        v_product_id := v_item.product_id;
        v_quantity_requested := v_item.quantity;

        -- Validar que product_id não é null
        IF v_product_id IS NULL THEN
            RETURN jsonb_build_object(
                'success', false,
                'message', 'Item sem product_id identificado'
            );
        END IF;

        -- Validar que quantidade é positiva
        IF v_quantity_requested IS NULL OR v_quantity_requested <= 0 THEN
            RETURN jsonb_build_object(
                'success', false,
                'message', format('Quantidade inválida para produto %s', v_product_id::text)
            );
        END IF;

        -- Verificar quantidade disponível
        SELECT quantidade INTO v_quantity_available
        FROM stock_items
        WHERE product_id = v_product_id;

        IF v_quantity_available IS NULL THEN
            RETURN jsonb_build_object(
                'success', false,
                'message', format('Produto %s não encontrado no estoque', v_product_id::text)
            );
        END IF;

        IF v_quantity_available < v_quantity_requested THEN
            SELECT nome INTO v_product_name FROM produtos WHERE id = v_product_id;
            RETURN jsonb_build_object(
                'success', false,
                'message', format(
                    'Estoque insuficiente para %s: solicitado %s, disponível %s',
                    COALESCE(v_product_name, v_product_id::text),
                    v_quantity_requested,
                    v_quantity_available
                )
            );
        END IF;

        v_total_quantity := v_total_quantity + v_quantity_requested;
    END LOOP;


    -- ========================================================================
    -- 3. INICIAR TRANSAÇÃO ATÔMICA
    -- ========================================================================

    BEGIN
        -- ----
        -- 3.1. Criar SALE (venda interna)
        -- ----
        v_sale_number := 'INT-' || to_char(now(), 'YYYY-MM-DD-HH24-MI-SS') || '-' || gen_random_uuid()::text;

        INSERT INTO public.sales (
            sale_number,
            total_amount,
            payment_method,
            sale_type,
            items,
            notes,
            created_by,
            is_internal_consumption,
            created_at,
            updated_at
        ) VALUES (
            v_sale_number,
            0.00,              -- Consumo interno não tem valor
            'INTERNAL',        -- Forma de pagamento interna
            'INTERNAL',        -- Tipo de venda interna
            p_items,           -- Items JSON
            'Consumo Interno',
            v_established_user_id,
            true,              -- Marcar como consumo interno
            now(),
            now()
        )
        RETURNING id INTO v_sale_id;

        IF v_sale_id IS NULL THEN
            RAISE EXCEPTION 'Falha ao criar venda interna';
        END IF;


        -- ----
        -- 3.2. Registrar CONSUMO INTERNO
        -- ----
        INSERT INTO public.internal_consumptions (
            estabelecimento_id,
            sale_id,
            consumed_at,
            total_quantity,
            items_json,
            created_by,
            created_at
        ) VALUES (
            p_estabelecimento_id,
            v_sale_id,
            now(),
            v_total_quantity,
            p_items,
            v_established_user_id,
            now()
        )
        RETURNING id INTO v_consumption_id;

        IF v_consumption_id IS NULL THEN
            RAISE EXCEPTION 'Falha ao registrar consumo interno';
        END IF;


        -- ----
        -- 3.3. Atualizar STOCK_ITEMS (decrementa quantidade)
        -- ----
        FOR v_item IN
            SELECT 
                (items->>'product_id')::uuid as product_id,
                (items->>'quantity')::integer as quantity
            FROM jsonb_array_elements(p_items) as items
        LOOP
            UPDATE stock_items
            SET 
                quantidade = quantidade - v_item.quantity,
                atualizado_em = now(),
                updated_at = now()
            WHERE product_id = v_item.product_id;

            -- ----
            -- 3.4. Registrar MOVIMENTO DE ESTOQUE (saída)
            -- ----
            INSERT INTO public.stock_movements (
                stock_item_id,
                tipo,
                quantidade,
                motivo,
                usuario_id,
                ref_type,
                ref_id,
                criado_em,
                created_at
            ) SELECT
                id,
                'saida',
                v_item.quantity,
                'Consumo Interno',
                v_established_user_id,
                'INTERNAL_CONSUMPTION',
                v_consumption_id,
                now(),
                now()
            FROM stock_items
            WHERE product_id = v_item.product_id
            RETURNING id INTO v_movement_id;

            IF v_movement_id IS NULL THEN
                RAISE EXCEPTION 'Falha ao registrar movimento de estoque';
            END IF;
        END LOOP;


        -- ========================================================================
        -- 4. SUCESSO - RETORNAR DADOS
        -- ========================================================================
        RETURN jsonb_build_object(
            'success', true,
            'consumption_id', v_consumption_id,
            'sale_id', v_sale_id,
            'sale_number', v_sale_number,
            'total_quantity', v_total_quantity,
            'message', 'Consumo interno registrado com sucesso'
        );

    EXCEPTION WHEN OTHERS THEN
        -- Transação é automaticamente revertida pelo PostgreSQL em caso de erro
        v_error_message := SQLSTATE || ' - ' || SQLERRM;
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Erro ao registrar consumo interno: ' || v_error_message,
            'error_code', SQLSTATE
        );
    END;

END;
$$;

COMMENT ON FUNCTION public.registrar_consumo_interno(UUID, JSONB, UUID) 
    IS 'RPC que registra consumo interno de forma atômica: venda + consumo + estoque + movimento';

-- Permitir que a função seja chamada via Supabase RPC
-- (Supabase expõe automaticamente funções com SECURITY DEFINER como RPC)


-- ============================================================================
-- 5. ESTRUTURA ESPERADA DO JSONB p_items
-- ============================================================================
-- Exemplo de p_items correto:
-- [
--   {
--     "product_id": "uuid-do-produto-1",
--     "product_name": "Pizza Margherita",
--     "quantity": 2,
--     "unit_price": 25.00
--   },
--   {
--     "product_id": "uuid-do-produto-2",
--     "product_name": "Refrigerante 2L",
--     "quantity": 1,
--     "unit_price": 8.00
--   }
-- ]
--
-- Campos obrigatórios: product_id, quantity
-- Campos opcionais: product_name, unit_price (para referência/auditoria)


-- ============================================================================
-- FIM DA MIGRATION — 03_rpc_registrar_consumo_interno.sql
-- ============================================================================

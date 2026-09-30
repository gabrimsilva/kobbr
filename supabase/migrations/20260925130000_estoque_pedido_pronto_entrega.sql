-- =============================================================================
-- Estoque dos pedidos do Kanban
-- A baixa passa a acontecer quando o pedido vai para "Prontos p/ Entrega"
-- (status Liberado), chamada pelo painel. Cancelar um pedido já baixado
-- devolve ao estoque exatamente o que saiu.
-- =============================================================================

-- Baixa: igual à anterior, mas a movimentação registra o que de fato saiu do
-- saldo (quando falta estoque o saldo zera e o restante vira alerta). Assim o
-- estorno devolve só o que foi baixado.
CREATE OR REPLACE FUNCTION public.baixar_estoque_pedido(p_pedido_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pedido pedidos%ROWTYPE;
  v_item jsonb;
  v_qtd numeric;
  v_baixado numeric;
  v_produto_id uuid;
  v_variante_id uuid;
  v_requires boolean;
  v_nome text;
  v_stock_id uuid;
  v_stock_qtd numeric;
  v_var_qtd numeric;
  v_alertas text[] := '{}';
BEGIN
  SELECT * INTO v_pedido FROM pedidos WHERE id = p_pedido_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pedido % não encontrado', p_pedido_id;
  END IF;

  IF v_pedido.estoque_baixado THEN
    RETURN jsonb_build_object('ja_baixado', true, 'alertas', '[]'::jsonb);
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(coalesce(v_pedido.itens, '[]'::jsonb)) LOOP
    v_qtd := coalesce((v_item->>'quantidade')::numeric, 0);
    v_produto_id := nullif(coalesce(v_item->>'produto_id', v_item->'produto'->>'id'), '')::uuid;
    v_variante_id := nullif(coalesce(v_item->>'variantId', v_item->>'variante_id'), '')::uuid;
    CONTINUE WHEN v_qtd <= 0 OR v_produto_id IS NULL;

    SELECT requires_stock, nome INTO v_requires, v_nome FROM produtos WHERE id = v_produto_id;
    CONTINUE WHEN NOT FOUND OR v_requires IS FALSE;

    v_stock_id := NULL;
    SELECT id, coalesce(quantidade, 0) INTO v_stock_id, v_stock_qtd
      FROM stock_items WHERE product_id = v_produto_id
      ORDER BY criado_em LIMIT 1 FOR UPDATE;
    CONTINUE WHEN v_stock_id IS NULL;

    IF v_variante_id IS NOT NULL THEN
      SELECT coalesce(quantidade, 0) INTO v_var_qtd
        FROM stock_variants WHERE id = v_variante_id AND stock_item_id = v_stock_id FOR UPDATE;
      IF NOT FOUND THEN
        v_alertas := v_alertas || format('%s: variante não encontrada', v_nome);
        CONTINUE;
      END IF;
      IF v_var_qtd < v_qtd THEN
        v_alertas := v_alertas || format('%s (%s): faltaram %s un.', v_nome, v_item->>'variante_nome', v_qtd - greatest(v_var_qtd, 0));
      END IF;
      v_baixado := least(v_qtd, greatest(v_var_qtd, 0));
      UPDATE stock_variants
         SET quantidade = greatest(v_var_qtd - v_qtd, 0), atualizado_em = now()
       WHERE id = v_variante_id;
      UPDATE stock_items
         SET quantidade = (SELECT coalesce(sum(quantidade), 0) FROM stock_variants WHERE stock_item_id = v_stock_id),
             atualizado_em = now()
       WHERE id = v_stock_id;
    ELSE
      IF v_stock_qtd < v_qtd THEN
        v_alertas := v_alertas || format('%s: faltaram %s un.', v_nome, v_qtd - greatest(v_stock_qtd, 0));
      END IF;
      v_baixado := least(v_qtd, greatest(v_stock_qtd, 0));
      UPDATE stock_items
         SET quantidade = greatest(v_stock_qtd - v_qtd, 0), atualizado_em = now()
       WHERE id = v_stock_id;
    END IF;

    IF v_baixado > 0 THEN
      INSERT INTO stock_movements (stock_item_id, variant_id, tipo, quantidade, motivo, ref_type, ref_id, estabelecimento_id, usuario_id)
      VALUES (v_stock_id, v_variante_id, 'saida', v_baixado,
              format('Venda (PEDIDO #%s)', coalesce(v_pedido.codigo_pedido, v_pedido.pedido_id)),
              'CATALOGO', v_pedido.id, v_pedido.estabelecimento_id, auth.uid());
    END IF;
  END LOOP;

  UPDATE pedidos
     SET estoque_baixado = true,
         estoque_alerta = CASE WHEN array_length(v_alertas, 1) > 0 THEN array_to_string(v_alertas, '; ') END,
         atualizado_em = now()
   WHERE id = p_pedido_id;

  RETURN jsonb_build_object('ja_baixado', false, 'alertas', to_jsonb(v_alertas));
END;
$$;

-- Estorno: devolve o que as movimentações de saída do pedido registraram
CREATE OR REPLACE FUNCTION public.estornar_estoque_pedido(p_pedido_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pedido pedidos%ROWTYPE;
  v_mov record;
  v_itens integer := 0;
BEGIN
  SELECT * INTO v_pedido FROM pedidos WHERE id = p_pedido_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pedido % não encontrado', p_pedido_id;
  END IF;

  IF NOT v_pedido.estoque_baixado THEN
    RETURN jsonb_build_object('estornado', false);
  END IF;

  FOR v_mov IN
    SELECT stock_item_id, variant_id,
           sum(CASE WHEN tipo = 'saida' THEN quantidade ELSE -quantidade END) AS qtd
      FROM stock_movements
     WHERE ref_id = p_pedido_id AND ref_type IN ('CATALOGO', 'CATALOGO_ESTORNO')
     GROUP BY stock_item_id, variant_id
    HAVING sum(CASE WHEN tipo = 'saida' THEN quantidade ELSE -quantidade END) > 0
  LOOP
    PERFORM 1 FROM stock_items WHERE id = v_mov.stock_item_id FOR UPDATE;
    CONTINUE WHEN NOT FOUND;

    IF v_mov.variant_id IS NOT NULL THEN
      UPDATE stock_variants
         SET quantidade = coalesce(quantidade, 0) + v_mov.qtd, atualizado_em = now()
       WHERE id = v_mov.variant_id;
      UPDATE stock_items
         SET quantidade = (SELECT coalesce(sum(quantidade), 0) FROM stock_variants WHERE stock_item_id = v_mov.stock_item_id),
             atualizado_em = now()
       WHERE id = v_mov.stock_item_id;
    ELSE
      UPDATE stock_items
         SET quantidade = coalesce(quantidade, 0) + v_mov.qtd, atualizado_em = now()
       WHERE id = v_mov.stock_item_id;
    END IF;

    INSERT INTO stock_movements (stock_item_id, variant_id, tipo, quantidade, motivo, ref_type, ref_id, estabelecimento_id, usuario_id)
    VALUES (v_mov.stock_item_id, v_mov.variant_id, 'entrada', v_mov.qtd,
            format('Estorno (PEDIDO #%s cancelado)', coalesce(v_pedido.codigo_pedido, v_pedido.pedido_id)),
            'CATALOGO_ESTORNO', v_pedido.id, v_pedido.estabelecimento_id, auth.uid());
    v_itens := v_itens + 1;
  END LOOP;

  UPDATE pedidos
     SET estoque_baixado = false, estoque_alerta = NULL, atualizado_em = now()
   WHERE id = p_pedido_id;

  RETURN jsonb_build_object('estornado', true, 'itens', v_itens);
END;
$$;

-- O painel (usuário logado) passa a chamar as duas funções pelo Kanban
REVOKE ALL ON FUNCTION public.baixar_estoque_pedido(uuid) FROM public, anon;
REVOKE ALL ON FUNCTION public.estornar_estoque_pedido(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.baixar_estoque_pedido(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.estornar_estoque_pedido(uuid) TO authenticated, service_role;

-- =============================================================================
-- Reserva de estoque dos pedidos em aberto
-- O saldo físico só baixa em "Prontos p/ Entrega". Até lá, os itens dos pedidos
-- abertos ficam reservados: o catálogo e a edge function catalogo-pedidos
-- descontam essa reserva do saldo, para não aceitar pedido sem estoque.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.catalogo_estoque_reservado(p_produto_ids uuid[] DEFAULT NULL)
RETURNS TABLE (produto_id uuid, variante_id uuid, quantidade numeric)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    nullif(coalesce(i->>'produto_id', i->'produto'->>'id'), '')::uuid AS produto_id,
    nullif(coalesce(i->>'variantId', i->>'variante_id'), '')::uuid AS variante_id,
    sum(coalesce((i->>'quantidade')::numeric, 0)) AS quantidade
  FROM pedidos p
  CROSS JOIN LATERAL jsonb_array_elements(
    CASE WHEN jsonb_typeof(p.itens) = 'array' THEN p.itens ELSE '[]'::jsonb END
  ) AS i
  WHERE NOT coalesce(p.estoque_baixado, false)
    AND NOT coalesce(p.cancelado, false)
    AND p.status NOT IN ('Finalizado', 'Entregue', 'Retirado', 'Cancelado')
    -- Pagamento online recusado/estornado não segura estoque
    AND coalesce(p.mercado_pago_status, '') NOT IN ('rejected', 'cancelled', 'refunded', 'charged_back', 'valor_divergente')
    AND nullif(coalesce(i->>'produto_id', i->'produto'->>'id'), '') IS NOT NULL
    AND (p_produto_ids IS NULL
         OR nullif(coalesce(i->>'produto_id', i->'produto'->>'id'), '')::uuid = ANY (p_produto_ids))
  GROUP BY 1, 2;
$$;

-- Só quantidades agregadas por produto/variante: seguro para o catálogo público
REVOKE ALL ON FUNCTION public.catalogo_estoque_reservado(uuid[]) FROM public;
GRANT EXECUTE ON FUNCTION public.catalogo_estoque_reservado(uuid[]) TO anon, authenticated, service_role;

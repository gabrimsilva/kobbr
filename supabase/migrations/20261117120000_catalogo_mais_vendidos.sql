-- =============================================================================
-- Ranking de mais vendidos para o catálogo público
-- Soma as quantidades vendidas por produto na tabela sales (PDV + pedidos
-- online finalizados). Consumo interno não conta. Devolve só agregados, sem
-- dados de venda/cliente, então pode ser exposta ao anon.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.catalogo_mais_vendidos()
RETURNS TABLE (produto_id uuid, quantidade numeric)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    nullif(coalesce(i->'produto'->>'id', i->>'produto_id'), '')::uuid AS produto_id,
    sum(coalesce((i->>'quantidade')::numeric, 0)) AS quantidade
  FROM sales s
  CROSS JOIN LATERAL jsonb_array_elements(
    CASE WHEN jsonb_typeof(s.items) = 'array' THEN s.items ELSE '[]'::jsonb END
  ) AS i
  WHERE coalesce(s.sale_type::text, '') <> 'INTERNAL_CONSUMPTION'
    AND coalesce(s.payment_method::text, '') <> 'INTERNAL_CONSUMPTION'
    AND nullif(coalesce(i->'produto'->>'id', i->>'produto_id'), '') ~* '^[0-9a-f-]{36}$'
  GROUP BY 1;
$$;

REVOKE ALL ON FUNCTION public.catalogo_mais_vendidos() FROM public;
GRANT EXECUTE ON FUNCTION public.catalogo_mais_vendidos() TO anon, authenticated, service_role;

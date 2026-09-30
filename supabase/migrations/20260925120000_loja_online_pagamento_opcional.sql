-- =============================================================================
-- Loja online: pagamento online opcional
-- Com pagamento_online = false o catálogo recebe pedidos sem cobrança: o cliente
-- informa como vai pagar na retirada/entrega e o pedido cai direto no Kanban.
-- A integração com o Mercado Pago continua configurável e é usada apenas
-- quando pagamento_online = true.
-- =============================================================================

ALTER TABLE public.config_loja_online
  ADD COLUMN IF NOT EXISTS pagamento_online boolean NOT NULL DEFAULT false;

GRANT SELECT (pagamento_online) ON public.config_loja_online TO authenticated;
GRANT INSERT (pagamento_online) ON public.config_loja_online TO authenticated;
GRANT UPDATE (pagamento_online) ON public.config_loja_online TO authenticated;

-- Pedidos ficam disponíveis sem token quando não há cobrança online
CREATE OR REPLACE FUNCTION public.catalogo_config_publica(p_estabelecimento_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH estab AS (
    SELECT id FROM estabelecimentos
    WHERE ativo AND (p_estabelecimento_id IS NULL OR id = p_estabelecimento_id)
    ORDER BY criado_em
    LIMIT 1
  )
  SELECT jsonb_build_object(
    'estabelecimento_id', e.id,
    'pedidos_ativos', coalesce(c.pedidos_ativos AND (NOT c.pagamento_online OR c.token_configurado), false),
    'pagamento_online', coalesce(c.pagamento_online, false),
    'pix', coalesce(c.pix_ativo, false),
    'credito', coalesce(c.credito_ativo, false),
    'debito', coalesce(c.debito_ativo, false),
    'max_parcelas', coalesce(c.max_parcelas, 1),
    'atacado_ativo', coalesce(c.atacado_ativo, false),
    'atacado_pedido_minimo', coalesce(c.atacado_pedido_minimo, 0)
  )
  FROM estab e
  LEFT JOIN config_loja_online c ON c.estabelecimento_id = e.id;
$$;

REVOKE ALL ON FUNCTION public.catalogo_config_publica(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.catalogo_config_publica(uuid) TO anon, authenticated;

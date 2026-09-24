-- =============================================================================
-- Loja online: pedidos pelo catálogo (varejo/atacado) com Mercado Pago Checkout Pro
-- =============================================================================

-- Preço de atacado por produto (null = usa o preço de varejo)
ALTER TABLE public.produtos
  ADD COLUMN IF NOT EXISTS preco_atacado numeric(10,2)
    CHECK (preco_atacado IS NULL OR preco_atacado > 0);

-- Pedidos: origem, tipo de venda, pagamento online e controle de baixa de estoque.
-- Inclui também colunas que o Kanban já usa e ainda não existiam no banco.
ALTER TABLE public.pedidos
  ADD COLUMN IF NOT EXISTS codigo_pedido text,
  ADD COLUMN IF NOT EXISTS origem text NOT NULL DEFAULT 'balcao',
  ADD COLUMN IF NOT EXISTS tipo_venda text NOT NULL DEFAULT 'varejo'
    CHECK (tipo_venda IN ('varejo', 'atacado')),
  ADD COLUMN IF NOT EXISTS mercado_pago_preference_id text,
  ADD COLUMN IF NOT EXISTS mercado_pago_payment_id text,
  ADD COLUMN IF NOT EXISTS mercado_pago_status text,
  ADD COLUMN IF NOT EXISTS pago_em timestamptz,
  ADD COLUMN IF NOT EXISTS estoque_baixado boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS estoque_alerta text,
  ADD COLUMN IF NOT EXISTS desconto numeric(10,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tipo_desconto text NOT NULL DEFAULT 'valor',
  ADD COLUMN IF NOT EXISTS cliente_numero text,
  ADD COLUMN IF NOT EXISTS cliente_bairro text,
  ADD COLUMN IF NOT EXISTS cliente_id uuid,
  ADD COLUMN IF NOT EXISTS motivo_cancelamento text,
  ADD COLUMN IF NOT EXISTS requer_extorno boolean,
  ADD COLUMN IF NOT EXISTS valor_extorno numeric(10,2),
  ADD COLUMN IF NOT EXISTS forma_pagamento_extorno text,
  ADD COLUMN IF NOT EXISTS cancelado_em timestamptz;

CREATE UNIQUE INDEX IF NOT EXISTS pedidos_pedido_id_key ON public.pedidos (pedido_id);
CREATE INDEX IF NOT EXISTS pedidos_estab_criado_idx ON public.pedidos (estabelecimento_id, criado_em DESC);

CREATE SEQUENCE IF NOT EXISTS public.pedidos_codigo_seq START 1001;

-- -----------------------------------------------------------------------------
-- Configuração da loja online (1 linha por estabelecimento)
-- O access_token do Mercado Pago NÃO pode ser lido pelo navegador: só as edge
-- functions (service_role) enxergam a coluna. O painel vê apenas token_configurado.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.config_loja_online (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id uuid NOT NULL UNIQUE REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  pedidos_ativos boolean NOT NULL DEFAULT false,
  provedor text NOT NULL DEFAULT 'mercado_pago',
  ambiente text NOT NULL DEFAULT 'teste' CHECK (ambiente IN ('teste', 'producao')),
  access_token text,
  token_configurado boolean GENERATED ALWAYS AS (coalesce(access_token, '') <> '') STORED,
  pix_ativo boolean NOT NULL DEFAULT true,
  credito_ativo boolean NOT NULL DEFAULT true,
  debito_ativo boolean NOT NULL DEFAULT true,
  max_parcelas integer NOT NULL DEFAULT 1 CHECK (max_parcelas BETWEEN 1 AND 12),
  atacado_ativo boolean NOT NULL DEFAULT true,
  atacado_pedido_minimo numeric(10,2) NOT NULL DEFAULT 0 CHECK (atacado_pedido_minimo >= 0),
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.config_loja_online ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS config_loja_online_select_auth ON public.config_loja_online;
DROP POLICY IF EXISTS config_loja_online_insert_auth ON public.config_loja_online;
DROP POLICY IF EXISTS config_loja_online_update_auth ON public.config_loja_online;
CREATE POLICY config_loja_online_select_auth ON public.config_loja_online
  FOR SELECT TO authenticated USING (true);
CREATE POLICY config_loja_online_insert_auth ON public.config_loja_online
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY config_loja_online_update_auth ON public.config_loja_online
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- Privilégios por coluna: esconde access_token de anon/authenticated
REVOKE ALL ON public.config_loja_online FROM anon, authenticated;
GRANT SELECT (id, estabelecimento_id, pedidos_ativos, provedor, ambiente, token_configurado,
              pix_ativo, credito_ativo, debito_ativo, max_parcelas,
              atacado_ativo, atacado_pedido_minimo, criado_em, atualizado_em)
  ON public.config_loja_online TO authenticated;
GRANT INSERT (estabelecimento_id, pedidos_ativos, ambiente, access_token, pix_ativo, credito_ativo,
              debito_ativo, max_parcelas, atacado_ativo, atacado_pedido_minimo)
  ON public.config_loja_online TO authenticated;
GRANT UPDATE (pedidos_ativos, ambiente, access_token, pix_ativo, credito_ativo, debito_ativo,
              max_parcelas, atacado_ativo, atacado_pedido_minimo, atualizado_em)
  ON public.config_loja_online TO authenticated;

-- -----------------------------------------------------------------------------
-- Configuração pública para o catálogo (sem segredos)
-- -----------------------------------------------------------------------------
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
    'pedidos_ativos', coalesce(c.pedidos_ativos AND c.token_configurado, false),
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

-- -----------------------------------------------------------------------------
-- Código sequencial do pedido (usado pela edge function)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.proximo_codigo_pedido()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT nextval('public.pedidos_codigo_seq')::text;
$$;

REVOKE ALL ON FUNCTION public.proximo_codigo_pedido() FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.proximo_codigo_pedido() TO service_role;

-- -----------------------------------------------------------------------------
-- Baixa de estoque de um pedido pago. Idempotente (estoque_baixado) e atômica.
-- Mesma regra do PDV: respeita produtos.requires_stock, ignora produto sem
-- stock_item e, com variante, baixa a variante e recalcula o total do item.
-- Como o pagamento já foi aprovado, não bloqueia: se faltar saldo, zera e
-- registra o alerta no pedido para a equipe resolver.
-- -----------------------------------------------------------------------------
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
    RETURN jsonb_build_object('ja_baixado', true);
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(coalesce(v_pedido.itens, '[]'::jsonb)) LOOP
    v_qtd := coalesce((v_item->>'quantidade')::numeric, 0);
    v_produto_id := nullif(v_item->>'produto_id', '')::uuid;
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
        v_alertas := v_alertas || format('%s (%s): faltaram %s un.', v_nome, v_item->>'variante_nome', v_qtd - v_var_qtd);
      END IF;
      UPDATE stock_variants
         SET quantidade = greatest(v_var_qtd - v_qtd, 0), atualizado_em = now()
       WHERE id = v_variante_id;
      UPDATE stock_items
         SET quantidade = (SELECT coalesce(sum(quantidade), 0) FROM stock_variants WHERE stock_item_id = v_stock_id),
             atualizado_em = now()
       WHERE id = v_stock_id;
    ELSE
      IF v_stock_qtd < v_qtd THEN
        v_alertas := v_alertas || format('%s: faltaram %s un.', v_nome, v_qtd - v_stock_qtd);
      END IF;
      UPDATE stock_items
         SET quantidade = greatest(v_stock_qtd - v_qtd, 0), atualizado_em = now()
       WHERE id = v_stock_id;
    END IF;

    INSERT INTO stock_movements (stock_item_id, variant_id, tipo, quantidade, motivo, ref_type, ref_id, estabelecimento_id)
    VALUES (v_stock_id, v_variante_id, 'saida', v_qtd,
            format('Venda (CATALOGO #%s)', coalesce(v_pedido.codigo_pedido, v_pedido.pedido_id)),
            'CATALOGO', v_pedido.id, v_pedido.estabelecimento_id);
  END LOOP;

  UPDATE pedidos
     SET estoque_baixado = true,
         estoque_alerta = CASE WHEN array_length(v_alertas, 1) > 0 THEN array_to_string(v_alertas, '; ') END,
         atualizado_em = now()
   WHERE id = p_pedido_id;

  RETURN jsonb_build_object('ja_baixado', false, 'alertas', to_jsonb(v_alertas));
END;
$$;

REVOKE ALL ON FUNCTION public.baixar_estoque_pedido(uuid) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.baixar_estoque_pedido(uuid) TO service_role;

-- Realtime do Kanban de pedidos
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'pedidos'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.pedidos;
  END IF;
END $$;

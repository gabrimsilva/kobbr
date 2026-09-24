// Edge function: pedidos do catálogo público com Mercado Pago Checkout Pro.
//
// POST { action: 'criar', ... }     → valida, calcula preços no servidor, grava o pedido e cria a preferência
// POST { action: 'confirmar', ... } → consulta o pagamento no Mercado Pago e atualiza o pedido
// POST ?webhook=1&e=<estab_id>     → notificação do Mercado Pago (mesmo processamento do 'confirmar')
//
// Deploy com verify_jwt = false: o webhook do Mercado Pago não envia JWT. Nenhuma
// informação vinda do cliente é confiada: preços, estoque e status do pagamento
// são sempre lidos do banco e da API do Mercado Pago.
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
}

const MP_API = "https://api.mercadopago.com"
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

type FormaPagamento = "pix" | "credito" | "debito"
type TipoVenda = "varejo" | "atacado"

interface ConfigLoja {
  estabelecimento_id: string
  pedidos_ativos: boolean
  ambiente: "teste" | "producao"
  access_token: string | null
  pix_ativo: boolean
  credito_ativo: boolean
  debito_ativo: boolean
  max_parcelas: number
  atacado_ativo: boolean
  atacado_pedido_minimo: number
}

class ErroCliente extends Error {
  constructor(message: string, public status = 400) {
    super(message)
  }
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}

const centavos = (v: number) => Math.round(v * 100) / 100

function admin(): SupabaseClient {
  return createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  })
}

async function carregarConfig(db: SupabaseClient, estabelecimentoId: string): Promise<ConfigLoja> {
  const { data, error } = await db
    .from("config_loja_online")
    .select("*")
    .eq("estabelecimento_id", estabelecimentoId)
    .maybeSingle()
  if (error) throw error
  if (!data || !data.pedidos_ativos || !data.access_token) {
    throw new ErroCliente("Pedidos online não estão disponíveis no momento.", 409)
  }
  return { ...data, atacado_pedido_minimo: Number(data.atacado_pedido_minimo) || 0 } as ConfigLoja
}

async function mp<T>(token: string, path: string, init: RequestInit = {}): Promise<T> {
  const res = await fetch(`${MP_API}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      ...(init.headers ?? {}),
    },
  })
  const body = await res.json().catch(() => ({}))
  if (!res.ok) {
    console.error("Mercado Pago erro", res.status, path, JSON.stringify(body))
    throw new Error(`Mercado Pago respondeu ${res.status}: ${body?.message ?? "erro"}`)
  }
  return body as T
}

// ---------------------------------------------------------------------------
// criar
// ---------------------------------------------------------------------------
interface ItemEntrada {
  produto_id: string
  variante_id?: string | null
  quantidade: number
}

function validarEntradaCriar(body: any) {
  const tipoVenda: TipoVenda = body?.tipo_venda === "atacado" ? "atacado" : "varejo"
  const forma = body?.forma_pagamento as FormaPagamento
  if (!["pix", "credito", "debito"].includes(forma)) throw new ErroCliente("Forma de pagamento inválida.")

  const nome = String(body?.cliente?.nome ?? "").trim().replace(/\s+/g, " ")
  const telefone = String(body?.cliente?.telefone ?? "").replace(/\D/g, "")
  const email = String(body?.cliente?.email ?? "").trim().toLowerCase()
  if (nome.length < 3 || nome.length > 100) throw new ErroCliente("Informe seu nome completo.")
  if (telefone.length < 10 || telefone.length > 13) throw new ErroCliente("Telefone inválido.")
  if (!EMAIL_RE.test(email) || email.length > 120) throw new ErroCliente("E-mail inválido.")

  const observacoes = String(body?.observacoes ?? "").trim().slice(0, 500) || null

  const itensBrutos = Array.isArray(body?.itens) ? body.itens : []
  if (itensBrutos.length === 0) throw new ErroCliente("O carrinho está vazio.")
  if (itensBrutos.length > 100) throw new ErroCliente("Pedido com itens demais.")

  // Agrupa itens repetidos (mesmo produto + mesma variante)
  const agrupados = new Map<string, ItemEntrada>()
  for (const i of itensBrutos) {
    const produtoId = String(i?.produto_id ?? "")
    const varianteId = i?.variante_id ? String(i.variante_id) : null
    const qtd = Number(i?.quantidade)
    if (!UUID_RE.test(produtoId) || (varianteId && !UUID_RE.test(varianteId))) {
      throw new ErroCliente("Item inválido no carrinho.")
    }
    if (!Number.isInteger(qtd) || qtd < 1 || qtd > 10000) throw new ErroCliente("Quantidade inválida.")
    const chave = `${produtoId}:${varianteId ?? ""}`
    const atual = agrupados.get(chave)
    agrupados.set(chave, {
      produto_id: produtoId,
      variante_id: varianteId,
      quantidade: (atual?.quantidade ?? 0) + qtd,
    })
  }

  return { tipoVenda, forma, nome, telefone, email, observacoes, itens: [...agrupados.values()] }
}

function precoVarejo(p: { preco: number; preco_promocional: number | null }) {
  const preco = Number(p.preco) || 0
  const promo = Number(p.preco_promocional) || 0
  return promo > 0 && promo < preco ? promo : preco
}

function formatarTelefone(digitos: string) {
  const d = digitos.startsWith("55") && digitos.length > 11 ? digitos.slice(2) : digitos
  return d.length === 11
    ? `(${d.slice(0, 2)}) ${d.slice(2, 7)}-${d.slice(7)}`
    : `(${d.slice(0, 2)}) ${d.slice(2, 6)}-${d.slice(6)}`
}

async function criarPedido(req: Request, body: any) {
  const entrada = validarEntradaCriar(body)
  const db = admin()

  const origin = req.headers.get("origin") ?? ""
  let baseRetorno: URL
  try {
    baseRetorno = new URL(origin)
    if (!["http:", "https:"].includes(baseRetorno.protocol)) throw new Error()
  } catch {
    throw new ErroCliente("Origem da requisição inválida.")
  }

  // Produtos (somente ativos)
  const produtoIds = [...new Set(entrada.itens.map((i) => i.produto_id))]
  const { data: produtos, error: errProdutos } = await db
    .from("produtos")
    .select("id, nome, preco, preco_promocional, preco_atacado, categoria_nome, requires_stock, ativo, estabelecimento_id")
    .in("id", produtoIds)
  if (errProdutos) throw errProdutos
  const mapaProdutos = new Map((produtos ?? []).map((p) => [p.id, p]))
  for (const id of produtoIds) {
    const p = mapaProdutos.get(id)
    if (!p || !p.ativo) throw new ErroCliente("Um dos produtos não está mais disponível. Atualize a página.")
  }

  const estabs = new Set((produtos ?? []).map((p) => p.estabelecimento_id))
  if (estabs.size !== 1 || !produtos![0].estabelecimento_id) {
    throw new ErroCliente("Produtos de lojas diferentes no mesmo pedido.")
  }
  const estabelecimentoId = produtos![0].estabelecimento_id as string
  const config = await carregarConfig(db, estabelecimentoId)

  const formaAtiva = { pix: config.pix_ativo, credito: config.credito_ativo, debito: config.debito_ativo }
  if (!formaAtiva[entrada.forma]) throw new ErroCliente("Forma de pagamento indisponível.")
  if (entrada.tipoVenda === "atacado" && !config.atacado_ativo) {
    throw new ErroCliente("Vendas no atacado não estão disponíveis.")
  }

  // Estoque e variantes
  const { data: stockItems, error: errStock } = await db
    .from("stock_items")
    .select("id, product_id, quantidade")
    .in("product_id", produtoIds)
    .order("criado_em", { ascending: true }) // mesmo stock_item que baixar_estoque_pedido usa
  if (errStock) throw errStock
  const stockPorProduto = new Map<string, { id: string; quantidade: number }>()
  for (const s of stockItems ?? []) {
    if (!stockPorProduto.has(s.product_id)) {
      stockPorProduto.set(s.product_id, { id: s.id, quantidade: Number(s.quantidade) || 0 })
    }
  }
  const stockIds = [...stockPorProduto.values()].map((s) => s.id)
  const { data: variantes, error: errVar } = stockIds.length
    ? await db.from("stock_variants").select("id, stock_item_id, nome, label, quantidade").in("stock_item_id", stockIds)
    : { data: [], error: null }
  if (errVar) throw errVar
  const variantesPorStock = new Map<string, any[]>()
  for (const v of variantes ?? []) {
    const lista = variantesPorStock.get(v.stock_item_id) ?? []
    lista.push(v)
    variantesPorStock.set(v.stock_item_id, lista)
  }

  // Monta itens com preço do servidor
  let subtotal = 0
  const itensPedido = entrada.itens.map((item) => {
    const p = mapaProdutos.get(item.produto_id)!
    const stock = stockPorProduto.get(p.id)
    const listaVariantes = stock ? variantesPorStock.get(stock.id) ?? [] : []

    let variante: any = null
    if (listaVariantes.length > 0) {
      if (!item.variante_id) throw new ErroCliente(`Escolha uma opção para "${p.nome}".`)
      variante = listaVariantes.find((v) => v.id === item.variante_id)
      if (!variante) throw new ErroCliente(`Opção inválida para "${p.nome}".`)
    } else if (item.variante_id) {
      throw new ErroCliente(`Opção inválida para "${p.nome}".`)
    }

    if (p.requires_stock !== false && stock) {
      const disponivel = variante ? Number(variante.quantidade) || 0 : stock.quantidade
      if (disponivel < item.quantidade) {
        const rotulo = variante ? `${p.nome} (${variante.nome ?? variante.label})` : p.nome
        throw new ErroCliente(
          disponivel > 0
            ? `Estoque insuficiente para "${rotulo}". Disponível: ${disponivel}.`
            : `"${rotulo}" está esgotado.`,
          409,
        )
      }
    }

    const unitario = centavos(
      entrada.tipoVenda === "atacado" && Number(p.preco_atacado) > 0 ? Number(p.preco_atacado) : precoVarejo(p),
    )
    const totalItem = centavos(unitario * item.quantidade)
    subtotal = centavos(subtotal + totalItem)
    const varianteNome = variante ? String(variante.nome ?? variante.label ?? "") : null

    return {
      produto_id: p.id,
      variantId: variante?.id ?? null,
      variante_nome: varianteNome,
      quantidade: item.quantidade,
      preco_unitario: unitario,
      subtotal: totalItem,
      produto: {
        id: p.id,
        nome: varianteNome ? `${p.nome} - ${varianteNome}` : p.nome,
        preco: unitario,
        categoria_nome: p.categoria_nome,
      },
    }
  })

  if (subtotal <= 0) throw new ErroCliente("Total do pedido inválido.")
  if (entrada.tipoVenda === "atacado" && subtotal < config.atacado_pedido_minimo) {
    throw new ErroCliente(
      `O pedido mínimo no atacado é de R$ ${config.atacado_pedido_minimo.toFixed(2).replace(".", ",")}.`,
    )
  }

  // Grava o pedido
  const { data: codigo, error: errCodigo } = await db.rpc("proximo_codigo_pedido")
  if (errCodigo) throw errCodigo
  const [primeiroNome, ...resto] = entrada.nome.split(" ")

  const { data: pedido, error: errPedido } = await db
    .from("pedidos")
    .insert({
      pedido_id: `CAT-${codigo}`,
      codigo_pedido: String(codigo),
      origem: "catalogo",
      tipo_venda: entrada.tipoVenda,
      estabelecimento_id: estabelecimentoId,
      cliente_nome: primeiroNome,
      cliente_sobrenome: resto.join(" "),
      cliente_telefone: formatarTelefone(entrada.telefone),
      cliente_email: entrada.email,
      entrega_domicilio: false,
      forma_pagamento: entrada.forma,
      subtotal,
      taxa_entrega: 0,
      total: subtotal,
      itens: itensPedido,
      status: "Pedido criado",
      observacoes: entrada.observacoes,
      mercado_pago_status: "pending",
    })
    .select("id, codigo_pedido, total")
    .single()
  if (errPedido) throw errPedido

  // Preferência do Checkout Pro limitada à forma escolhida
  const tiposExcluidos: Record<FormaPagamento, string[]> = {
    pix: ["credit_card", "debit_card", "prepaid_card", "ticket", "atm"],
    credito: ["debit_card", "prepaid_card", "bank_transfer", "ticket", "atm"],
    debito: ["credit_card", "prepaid_card", "bank_transfer", "ticket", "atm"],
  }
  const urlRetorno = `${baseRetorno.origin}/pedido/${pedido.id}`
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!

  try {
    const preferencia = await mp<{ id: string; init_point: string; sandbox_init_point?: string }>(
      config.access_token!,
      "/checkout/preferences",
      {
        method: "POST",
        headers: { "X-Idempotency-Key": pedido.id },
        body: JSON.stringify({
          items: itensPedido.map((i) => ({
            id: i.produto_id,
            title: i.produto.nome.slice(0, 250),
            quantity: i.quantidade,
            unit_price: i.preco_unitario,
            currency_id: "BRL",
          })),
          payer: {
            name: primeiroNome,
            surname: resto.join(" ") || undefined,
            email: entrada.email,
          },
          external_reference: pedido.id,
          back_urls: { success: urlRetorno, pending: urlRetorno, failure: urlRetorno },
          // O Mercado Pago só aceita auto_return com URL https
          ...(baseRetorno.protocol === "https:" ? { auto_return: "approved" } : {}),
          notification_url: `${supabaseUrl}/functions/v1/catalogo-pedidos?webhook=1&e=${estabelecimentoId}`,
          payment_methods: {
            excluded_payment_types: tiposExcluidos[entrada.forma].map((id) => ({ id })),
            installments: entrada.forma === "credito" ? config.max_parcelas : 1,
            default_installments: 1,
          },
          statement_descriptor: "KOBE",
          metadata: { pedido_id: pedido.id, codigo_pedido: pedido.codigo_pedido },
        }),
      },
    )

    await db.from("pedidos").update({ mercado_pago_preference_id: preferencia.id }).eq("id", pedido.id)

    const checkoutUrl =
      config.ambiente === "teste" && preferencia.sandbox_init_point
        ? preferencia.sandbox_init_point
        : preferencia.init_point

    return json({
      pedido_id: pedido.id,
      codigo_pedido: pedido.codigo_pedido,
      total: Number(pedido.total),
      checkout_url: checkoutUrl,
    })
  } catch (e) {
    // Sem cobrança criada o pedido não tem como ser pago: remove do Kanban
    await db.from("pedidos").update({ status: "Cancelado", cancelado: true, motivo_cancelamento: "Falha ao gerar pagamento" }).eq("id", pedido.id)
    throw e
  }
}

// ---------------------------------------------------------------------------
// Processamento de pagamento (confirmar + webhook)
// ---------------------------------------------------------------------------
const FORMA_POR_TIPO: Record<string, string> = {
  bank_transfer: "pix",
  credit_card: "credito",
  debit_card: "debito",
  account_money: "saldo_mercado_pago",
}

async function aplicarPagamento(db: SupabaseClient, pedido: any, pagamento: any) {
  const status: string = pagamento.status
  const jaAprovado = pedido.mercado_pago_status === "approved"
  const reverteu = ["refunded", "charged_back", "cancelled"].includes(status)

  // Não regride um pedido aprovado por causa de uma tentativa recusada posterior
  if (jaAprovado && status !== "approved" && !reverteu) return pedido

  const valorOk = Number(pagamento.transaction_amount) + 0.01 >= Number(pedido.total)
  const aprovado = status === "approved" && valorOk
  if (status === "approved" && !valorOk) {
    console.error(`Pagamento ${pagamento.id} com valor menor que o pedido ${pedido.id}`)
  }

  const atualizacao: Record<string, unknown> = {
    mercado_pago_status: aprovado || status !== "approved" ? status : "valor_divergente",
    mercado_pago_payment_id: String(pagamento.id),
    atualizado_em: new Date().toISOString(),
  }
  if (FORMA_POR_TIPO[pagamento.payment_type_id]) atualizacao.forma_pagamento = FORMA_POR_TIPO[pagamento.payment_type_id]
  if (aprovado && !pedido.pago_em) atualizacao.pago_em = pagamento.date_approved ?? new Date().toISOString()

  const { data: atualizado, error } = await db
    .from("pedidos")
    .update(atualizacao)
    .eq("id", pedido.id)
    .select("*")
    .single()
  if (error) throw error

  if (aprovado && !atualizado.estoque_baixado) {
    const { error: errBaixa } = await db.rpc("baixar_estoque_pedido", { p_pedido_id: pedido.id })
    if (errBaixa) console.error("Falha ao baixar estoque do pedido", pedido.id, errBaixa)
  }
  return atualizado
}

async function buscarPedido(db: SupabaseClient, pedidoId: string) {
  const { data, error } = await db
    .from("pedidos")
    .select("*")
    .eq("id", pedidoId)
    .eq("origem", "catalogo")
    .maybeSingle()
  if (error) throw error
  if (!data) throw new ErroCliente("Pedido não encontrado.", 404)
  return data
}

async function confirmarPedido(body: any) {
  const pedidoId = String(body?.pedido_id ?? "")
  if (!UUID_RE.test(pedidoId)) throw new ErroCliente("Pedido inválido.")
  const db = admin()
  let pedido = await buscarPedido(db, pedidoId)

  const { data: cfg } = await db
    .from("config_loja_online")
    .select("access_token, ambiente")
    .eq("estabelecimento_id", pedido.estabelecimento_id)
    .maybeSingle()

  let checkoutUrl: string | null = null
  if (cfg?.access_token && !pedido.cancelado) {
    const busca = await mp<{ results: any[] }>(
      cfg.access_token,
      `/v1/payments/search?external_reference=${pedido.id}&sort=date_created&criteria=desc`,
    )
    const resultados = busca.results ?? []
    const escolhido = resultados.find((p) => p.status === "approved") ?? resultados[0]
    if (escolhido) pedido = await aplicarPagamento(db, pedido, escolhido)

    if (pedido.mercado_pago_status !== "approved" && pedido.mercado_pago_preference_id) {
      try {
        const pref = await mp<{ init_point: string; sandbox_init_point?: string }>(
          cfg.access_token,
          `/checkout/preferences/${pedido.mercado_pago_preference_id}`,
        )
        checkoutUrl = cfg.ambiente === "teste" && pref.sandbox_init_point ? pref.sandbox_init_point : pref.init_point
      } catch {
        checkoutUrl = null
      }
    }
  }

  // Resposta pública: nada de telefone/e-mail
  return json({
    pedido_id: pedido.id,
    codigo_pedido: pedido.codigo_pedido,
    tipo_venda: pedido.tipo_venda,
    forma_pagamento: pedido.forma_pagamento,
    status_pagamento: pedido.mercado_pago_status,
    status_pedido: pedido.status,
    cancelado: !!pedido.cancelado,
    total: Number(pedido.total),
    criado_em: pedido.criado_em,
    itens: (pedido.itens ?? []).map((i: any) => ({
      nome: i.produto?.nome,
      quantidade: i.quantidade,
      preco_unitario: i.preco_unitario,
      subtotal: i.subtotal,
    })),
    checkout_url: checkoutUrl,
  })
}

async function webhook(url: URL, req: Request) {
  const estabelecimentoId = url.searchParams.get("e") ?? ""
  const body = await req.json().catch(() => ({}))
  const tipo = body?.type ?? body?.topic ?? url.searchParams.get("type") ?? url.searchParams.get("topic")
  const pagamentoId = String(body?.data?.id ?? url.searchParams.get("data.id") ?? url.searchParams.get("id") ?? "")

  if (tipo !== "payment" || !/^\d+$/.test(pagamentoId) || !UUID_RE.test(estabelecimentoId)) {
    return json({ ignorado: true })
  }

  const db = admin()
  const { data: cfg } = await db
    .from("config_loja_online")
    .select("access_token")
    .eq("estabelecimento_id", estabelecimentoId)
    .maybeSingle()
  if (!cfg?.access_token) return json({ ignorado: true })

  // Busca o pagamento na API: a notificação em si não é confiável
  const pagamento = await mp<any>(cfg.access_token, `/v1/payments/${pagamentoId}`)
  const pedidoId = String(pagamento.external_reference ?? "")
  if (!UUID_RE.test(pedidoId)) return json({ ignorado: true })

  const { data: pedido } = await db
    .from("pedidos")
    .select("*")
    .eq("id", pedidoId)
    .eq("estabelecimento_id", estabelecimentoId)
    .maybeSingle()
  if (!pedido) return json({ ignorado: true })

  await aplicarPagamento(db, pedido, pagamento)
  return json({ ok: true })
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })
  if (req.method !== "POST") return json({ error: "Método não permitido" }, 405)

  const url = new URL(req.url)
  try {
    if (url.searchParams.get("webhook") === "1") return await webhook(url, req)

    const body = await req.json().catch(() => null)
    if (body?.action === "criar") return await criarPedido(req, body)
    if (body?.action === "confirmar") return await confirmarPedido(body)
    return json({ error: "Ação inválida" }, 400)
  } catch (e) {
    if (e instanceof ErroCliente) return json({ error: e.message }, e.status)
    console.error("Erro inesperado", e)
    return json({ error: "Não foi possível processar o pedido. Tente novamente." }, 500)
  }
})

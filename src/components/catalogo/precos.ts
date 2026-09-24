import type { ProdutoCatalogo } from "@/components/delivery/CatalogoProdutoCard"
import type { TipoVenda } from "@/services/lojaOnlineService"

/**
 * Preço unitário de um produto no modo de venda escolhido.
 * Mesma regra da edge function `catalogo-pedidos` (o servidor recalcula tudo):
 * - varejo: preço promocional quando menor que o preço normal
 * - atacado: preço de atacado quando cadastrado, senão o preço de varejo
 */
export function precoUnitario(produto: ProdutoCatalogo, modo: TipoVenda): number {
  const preco = Number(produto.preco) || 0
  const promo = Number(produto.precoPromocional) || 0
  const varejo = promo > 0 && promo < preco ? promo : preco
  if (modo === "atacado" && Number(produto.precoAtacado) > 0) return Number(produto.precoAtacado)
  return varejo
}

/** Preço "de" riscado: promoção no varejo ou diferença do atacado */
export function precoAnterior(produto: ProdutoCatalogo, modo: TipoVenda): number | null {
  const atual = precoUnitario(produto, modo)
  const preco = Number(produto.preco) || 0
  return preco > atual ? preco : null
}

/** Quantidade disponível para compra (null = sem controle de estoque) */
export function disponivelParaCompra(produto: ProdutoCatalogo, varianteId?: string | null): number | null {
  if (produto.controlaEstoque === false) return null
  if (varianteId) {
    const variante = produto.variantes?.find(v => v.id === varianteId)
    return variante ? variante.quantidade : 0
  }
  return produto.quantidadeEstoque ?? 0
}

export const formatarReais = (valor: number) =>
  valor.toLocaleString("pt-BR", { style: "currency", currency: "BRL" })

import type { ProdutoCatalogo } from "@/components/delivery/CatalogoProdutoCard"
import type { TipoVenda } from "@/services/lojaOnlineService"

/**
 * Preço unitário de um produto no modo de venda escolhido. O catálogo nunca
 * usa o preço do PDV. Mesma regra da edge function `catalogo-pedidos`
 * (o servidor recalcula tudo):
 * - varejo: "Preço para Pedido Online" do cadastro (0 enquanto não preenchido)
 * - atacado: "Preço de Atacado" quando cadastrado, senão o preço online
 */
export function precoUnitario(produto: ProdutoCatalogo, modo: TipoVenda): number {
  if (modo === "atacado" && Number(produto.precoAtacado) > 0) return Number(produto.precoAtacado)
  return Number(produto.precoOnline) || 0
}

/** Produto sem preço online cadastrado: aparece com R$ 0,00 e não pode ser pedido */
export function semPrecoOnline(produto: ProdutoCatalogo, modo: TipoVenda): boolean {
  return precoUnitario(produto, modo) <= 0
}

/** Preço "de" riscado: no atacado, o preço online quando maior que o de atacado */
export function precoAnterior(produto: ProdutoCatalogo, modo: TipoVenda): number | null {
  if (modo !== "atacado") return null
  const atual = precoUnitario(produto, modo)
  const online = Number(produto.precoOnline) || 0
  return online > atual ? online : null
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

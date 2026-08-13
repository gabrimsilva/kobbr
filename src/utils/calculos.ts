/**
 * Utilitários de cálculos para preços e valores
 * @module utils/calculos
 */

/**
 * Interface para representar um item no carrinho
 */
interface ItemCarrinho {
  produto: {
    id: string
    preco: number
    precoPromocional?: number
    categoria?: string
  }
  quantidade: number
  saboresSelecionados?: Array<{ preco: number }>
  bordaSelecionada?: { preco: number }
  tamanhoSelecionado?: { valor: number }
  adicionaisSelecionados?: Array<{ valor: number; quantidade: number }>
}

/**
 * Calcula o preço total de um item do carrinho
 * @param item - Item do carrinho com produto, quantidade e personalizações
 * @returns Preço total do item (preço unitário × quantidade)
 * @example
 * const item = {
 *   produto: { id: '1', preco: 30, precoPromocional: 25 },
 *   quantidade: 2
 * }
 * calcularPrecoItem(item) // 50 (25 × 2)
 */
export function calcularPrecoItem(item: ItemCarrinho): number {
  let precoTotal = 0

  // Combo personalizado - usar preço já calculado
  if (item.produto.categoria === 'combo' && item.produto.id.includes('-')) {
    precoTotal = item.produto.preco || 0
  } 
  // Para produtos com tamanho (porções), usar o valor do tamanho
  else if (item.tamanhoSelecionado) {
    precoTotal = item.tamanhoSelecionado.valor
  } 
  // Usar preço normal ou promocional do produto
  else {
    precoTotal = (item.produto.precoPromocional && item.produto.precoPromocional > 0)
      ? item.produto.precoPromocional
      : item.produto.preco

    // Adicionar preço dos sabores
    if (item.saboresSelecionados && item.saboresSelecionados.length > 0) {
      const precoSabores = item.saboresSelecionados.reduce(
        (acc, sabor) => acc + (sabor.preco || 0), 
        0
      )
      precoTotal += precoSabores
    }

    // Adicionar preço da borda
    if (item.bordaSelecionada) {
      precoTotal += item.bordaSelecionada.preco || 0
    }

    // Adicionar preço dos adicionais
    if (item.adicionaisSelecionados && item.adicionaisSelecionados.length > 0) {
      const precoAdicionais = item.adicionaisSelecionados.reduce(
        (acc, adicional) => acc + (adicional.valor * adicional.quantidade), 
        0
      )
      precoTotal += precoAdicionais
    }
  }

  return precoTotal * item.quantidade
}

/**
 * Calcula o subtotal de um carrinho (soma de todos os itens)
 * @param carrinho - Array de itens do carrinho
 * @returns Subtotal do carrinho
 * @example
 * const carrinho = [
 *   { produto: { id: '1', preco: 30 }, quantidade: 2 },
 *   { produto: { id: '2', preco: 15 }, quantidade: 1 }
 * ]
 * calcularSubtotal(carrinho) // 75 (60 + 15)
 */
export function calcularSubtotal(carrinho: ItemCarrinho[]): number {
  return carrinho.reduce((acc, item) => acc + calcularPrecoItem(item), 0)
}

/**
 * Calcula o desconto aplicado a um valor
 * @param valor - Valor original
 * @param percentualDesconto - Percentual de desconto (0-100)
 * @returns Valor do desconto
 * @example
 * calcularDesconto(100, 10) // 10
 * calcularDesconto(50, 20) // 10
 */
export function calcularDesconto(valor: number, percentualDesconto: number): number {
  if (percentualDesconto < 0 || percentualDesconto > 100) {
    throw new Error('Percentual de desconto deve estar entre 0 e 100')
  }
  return (valor * percentualDesconto) / 100
}

/**
 * Calcula o total do pedido (subtotal - desconto).
 * Sistema opera somente com retirada no local — sem taxa de entrega.
 * @param carrinho - Array de itens do carrinho
 * @param desconto - Valor do desconto (opcional)
 * @returns Total do pedido
 */
export function calcularTotal(
  carrinho: ItemCarrinho[],
  desconto: number = 0
): number {
  const subtotal = calcularSubtotal(carrinho)
  return subtotal - desconto
}

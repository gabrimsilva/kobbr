/**
 * Utilitários compartilhados para manipulação de carrinho
 * Centraliza lógica de adicionar, remover e calcular itens
 *
 * @module utils/carrinho
 */

import type {
  ItemCarrinhoDelivery,
  ItemCarrinhoPDV,
  ProdutoBase,
  Sabor,
  Borda,
  Tamanho,
  Adicional,
  ResumoCarrinho
} from '@/types/carrinho'

/**
 * Calcula o preço unitário de um item com todas as personalizações
 */
export function calcularPrecoUnitarioItem(
  precoProduto: number,
  sabores?: Sabor[],
  borda?: Borda,
  tamanho?: Tamanho,
  adicionais?: Adicional[]
): number {
  let preco = precoProduto

  // Adicionar preço do tamanho (se houver, substitui o preço base)
  if (tamanho) {
    preco = tamanho.valor
  }

  // Adicionar preço dos sabores
  if (sabores && sabores.length > 0) {
    const precoSabores = sabores.reduce((acc, sabor) => acc + (sabor.preco || 0), 0)
    preco += precoSabores
  }

  // Adicionar preço da borda
  if (borda) {
    preco += borda.preco || 0
  }

  // Adicionar preço dos adicionais
  if (adicionais && adicionais.length > 0) {
    const precoAdicionais = adicionais.reduce(
      (acc, adicional) => acc + adicional.valor * adicional.quantidade,
      0
    )
    preco += precoAdicionais
  }

  return preco
}

/**
 * Calcula o preço total de um item (unitário × quantidade)
 */
export function calcularPrecoTotalItem(
  item: ItemCarrinhoDelivery | ItemCarrinhoPDV
): number {
  if ('precoUnitario' in item) {
    // ItemCarrinhoPDV já tem precoUnitario calculado
    return item.precoUnitario * item.quantidade
  }

  // ItemCarrinhoDelivery precisa calcular
  const precoBase = item.produto.precoPromocional || item.produto.preco
  const precoUnitario = calcularPrecoUnitarioItem(
    precoBase,
    item.saboresSelecionados,
    item.bordaSelecionada,
    item.tamanhoSelecionado,
    item.adicionaisSelecionados
  )

  return precoUnitario * item.quantidade
}

/**
 * Verifica se dois itens são idênticos (mesmo produto e mesmas personalizações)
 */
export function itensIguais(
  item1: ItemCarrinhoDelivery | ItemCarrinhoPDV,
  item2: ItemCarrinhoDelivery | ItemCarrinhoPDV
): boolean {
  // Verificar se é o mesmo produto
  if (item1.produto.id !== item2.produto.id) {
    return false
  }

  // Verificar sabores
  const sabores1 = item1.saboresSelecionados || []
  const sabores2 = item2.saboresSelecionados || []
  if (sabores1.length !== sabores2.length) {
    return false
  }
  const idsSabores1 = sabores1.map(s => s.id).sort()
  const idsSabores2 = sabores2.map(s => s.id).sort()
  if (idsSabores1.join(',') !== idsSabores2.join(',')) {
    return false
  }

  // Verificar borda
  const bordaId1 = item1.bordaSelecionada?.id || null
  const bordaId2 = item2.bordaSelecionada?.id || null
  if (bordaId1 !== bordaId2) {
    return false
  }

  // Verificar tamanho
  const tamanhoId1 = item1.tamanhoSelecionado?.id || null
  const tamanhoId2 = item2.tamanhoSelecionado?.id || null
  if (tamanhoId1 !== tamanhoId2) {
    return false
  }

  // Verificar adicionais
  const adicionais1 = item1.adicionaisSelecionados || []
  const adicionais2 = item2.adicionaisSelecionados || []
  if (adicionais1.length !== adicionais2.length) {
    return false
  }
  const idsAdicionais1 = adicionais1.map(a => `${a.id}-${a.quantidade}`).sort()
  const idsAdicionais2 = adicionais2.map(a => `${a.id}-${a.quantidade}`).sort()
  if (idsAdicionais1.join(',') !== idsAdicionais2.join(',')) {
    return false
  }

  return true
}

/**
 * Encontra um item idêntico no carrinho
 */
export function encontrarItemIdentico(
  carrinho: (ItemCarrinhoDelivery | ItemCarrinhoPDV)[],
  itemBusca: ItemCarrinhoDelivery | ItemCarrinhoPDV
): number {
  return carrinho.findIndex(item => itensIguais(item, itemBusca))
}

/**
 * Adiciona ou incrementa um item no carrinho
 * Retorna o novo carrinho
 */
export function adicionarOuIncrementarItem<T extends ItemCarrinhoDelivery | ItemCarrinhoPDV>(
  carrinho: T[],
  novoItem: T
): T[] {
  const indexExistente = encontrarItemIdentico(carrinho, novoItem)

  if (indexExistente >= 0) {
    // Item já existe, incrementar quantidade
    const novoCarrinho = [...carrinho]
    const itemExistente = novoCarrinho[indexExistente]
    novoCarrinho[indexExistente] = {
      ...itemExistente,
      quantidade: itemExistente.quantidade + novoItem.quantidade
    }

    // Atualizar precoTotal se for ItemCarrinhoPDV
    if ('precoTotal' in novoCarrinho[indexExistente]) {
      const itemPDV = novoCarrinho[indexExistente] as ItemCarrinhoPDV
      itemPDV.precoTotal = itemPDV.precoUnitario * itemPDV.quantidade
    }

    return novoCarrinho
  }

  // Item não existe, adicionar
  return [...carrinho, novoItem]
}

/**
 * Remove um item do carrinho por índice
 */
export function removerItemPorIndice<T extends ItemCarrinhoDelivery | ItemCarrinhoPDV>(
  carrinho: T[],
  indice: number
): T[] {
  if (indice < 0 || indice >= carrinho.length) {
    return carrinho
  }
  return carrinho.filter((_, i) => i !== indice)
}

/**
 * Incrementa a quantidade de um item no carrinho
 */
export function incrementarQuantidade<T extends ItemCarrinhoDelivery | ItemCarrinhoPDV>(
  carrinho: T[],
  indice: number
): T[] {
  if (indice < 0 || indice >= carrinho.length) {
    return carrinho
  }

  const novoCarrinho = [...carrinho]
  const item = novoCarrinho[indice]
  novoCarrinho[indice] = {
    ...item,
    quantidade: item.quantidade + 1
  }

  // Atualizar precoTotal se for ItemCarrinhoPDV
  if ('precoTotal' in novoCarrinho[indice]) {
    const itemPDV = novoCarrinho[indice] as ItemCarrinhoPDV
    itemPDV.precoTotal = itemPDV.precoUnitario * itemPDV.quantidade
  }

  return novoCarrinho
}

/**
 * Decrementa a quantidade de um item no carrinho
 * Remove o item se a quantidade chegar a 0
 */
export function decrementarQuantidade<T extends ItemCarrinhoDelivery | ItemCarrinhoPDV>(
  carrinho: T[],
  indice: number
): T[] {
  if (indice < 0 || indice >= carrinho.length) {
    return carrinho
  }

  const item = carrinho[indice]

  if (item.quantidade <= 1) {
    // Remove o item se quantidade for 1
    return removerItemPorIndice(carrinho, indice)
  }

  const novoCarrinho = [...carrinho]
  novoCarrinho[indice] = {
    ...item,
    quantidade: item.quantidade - 1
  }

  // Atualizar precoTotal se for ItemCarrinhoPDV
  if ('precoTotal' in novoCarrinho[indice]) {
    const itemPDV = novoCarrinho[indice] as ItemCarrinhoPDV
    itemPDV.precoTotal = itemPDV.precoUnitario * itemPDV.quantidade
  }

  return novoCarrinho
}

/**
 * Remove todas as ocorrências de um produto do carrinho (produtos simples)
 */
export function removerProdutoSimples<T extends ItemCarrinhoDelivery | ItemCarrinhoPDV>(
  carrinho: T[],
  produtoId: string
): T[] {
  return carrinho.filter(item => {
    // Manter apenas se for diferente do produto OU tiver personalizações
    return item.produto.id !== produtoId ||
      (item.saboresSelecionados && item.saboresSelecionados.length > 0) ||
      item.bordaSelecionada ||
      item.tamanhoSelecionado ||
      (item.adicionaisSelecionados && item.adicionaisSelecionados.length > 0)
  })
}

/**
 * Obtém a quantidade total de um produto no carrinho (apenas produtos simples)
 */
export function obterQuantidadeProduto<T extends ItemCarrinhoDelivery | ItemCarrinhoPDV>(
  carrinho: T[],
  produtoId: string
): number {
  return carrinho
    .filter(item =>
      item.produto.id === produtoId &&
      (!item.saboresSelecionados || item.saboresSelecionados.length === 0) &&
      !item.bordaSelecionada &&
      !item.tamanhoSelecionado &&
      (!item.adicionaisSelecionados || item.adicionaisSelecionados.length === 0)
    )
    .reduce((total, item) => total + item.quantidade, 0)
}

/**
 * Calcula o subtotal do carrinho
 */
export function calcularSubtotalCarrinho<T extends ItemCarrinhoDelivery | ItemCarrinhoPDV>(
  carrinho: T[]
): number {
  return carrinho.reduce((total, item) => total + calcularPrecoTotalItem(item), 0)
}

/**
 * Calcula o resumo completo do carrinho
 */
export function calcularResumoCarrinho<T extends ItemCarrinhoDelivery | ItemCarrinhoPDV>(
  carrinho: T[],
  taxaEntrega: number = 0,
  desconto: number = 0
): ResumoCarrinho {
  const subtotal = calcularSubtotalCarrinho(carrinho)
  const quantidadeItens = carrinho.reduce((total, item) => total + item.quantidade, 0)
  const total = subtotal + taxaEntrega - desconto

  return {
    subtotal,
    taxaEntrega,
    desconto,
    total,
    quantidadeItens
  }
}

/**
 * Verifica se o produto precisa de personalização (sabores, bordas, tamanhos)
 */
export function produtoPrecisaPersonalizacao(
  produto: ProdutoBase,
  categoriaDoProduto?: { tem_sabores?: boolean; tem_borda?: boolean; tem_tamanhos?: boolean; tem_adicionais?: boolean }
): boolean {
  // Verificar se tem sabores configurados
  const produtoTemSabores = produto.saboresDisponiveis &&
    produto.quantidadeSabores &&
    produto.quantidadeSabores > 0

  // Verificar configurações da categoria
  const categoriaTemSabores = categoriaDoProduto?.tem_sabores || false
  const categoriaTemBordas = categoriaDoProduto?.tem_borda || false
  const categoriaTemTamanhos = categoriaDoProduto?.tem_tamanhos || false
  const categoriaTemAdicionais = categoriaDoProduto?.tem_adicionais || false

  return produtoTemSabores ||
    categoriaTemSabores ||
    categoriaTemBordas ||
    categoriaTemTamanhos ||
    categoriaTemAdicionais
}

/**
 * Tipos centralizados para sistema de carrinho
 * Unifica os tipos usados em delivery, PDV e outros módulos
 *
 * @module types/carrinho
 */

/**
 * Representa um sabor de produto (pizza, calzone, etc.)
 */
export interface Sabor {
  /** ID único do sabor */
  id: string
  /** Nome do sabor */
  nome: string
  /** Descrição detalhada */
  descricao?: string
  /** Categoria do sabor */
  categoria?: 'doce' | 'salgada' | 'tradicional' | 'especiais' | 'nobres' | 'doces_especiais'
  /** Lista de ingredientes */
  ingredientes?: string[]
  /** Preço adicional (se premium) */
  preco: number
  /** Indica se é sabor premium */
  isPremium?: boolean
  /** Valor adicional do premium */
  valorPremium?: number
}

/**
 * Representa uma borda de pizza
 */
export interface Borda {
  /** ID único da borda */
  id: string
  /** Nome da borda */
  nome: string
  /** Preço adicional da borda */
  preco: number
  /** Descrição da borda */
  descricao?: string
}

/**
 * Representa um tamanho de produto
 */
export interface Tamanho {
  /** ID único do tamanho */
  id: string
  /** Nome do tamanho (ex: Pequena, Média, Grande) */
  nome: string
  /** Valor adicional ou preço do tamanho */
  valor: number
  /** Código do tamanho (ex: P, M, G, GG) */
  tamanho: string
  /** Ordem de exibição */
  ordem?: number
}

/**
 * Representa um adicional selecionado
 */
export interface Adicional {
  /** ID único do adicional */
  id: string
  /** Nome do adicional */
  nome: string
  /** Valor unitário do adicional */
  valor: number
  /** Quantidade selecionada */
  quantidade: number
  /** Categoria do adicional */
  categoriaId?: string
}

/**
 * Representa um produto base (sem personalizações)
 */
export interface ProdutoBase {
  /** ID único do produto */
  id: string
  /** Nome do produto */
  nome: string
  /** Descrição do produto */
  descricao: string
  /** Preço base do produto */
  preco: number
  /** Preço promocional (se houver) */
  precoPromocional?: number
  /** ID da categoria */
  categoriaId?: string
  /** Nome da categoria */
  categoria?: string
  /** URL da imagem */
  urlImagem?: string
  /** Indica se tem sabores disponíveis */
  saboresDisponiveis?: boolean
  /** Quantidade de sabores permitidos */
  quantidadeSabores?: number
}

/**
 * Representa um combo de produtos
 */
export interface Combo {
  /** ID único do combo */
  id: string
  /** Nome do combo */
  nome: string
  /** Descrição do combo */
  descricao: string
  /** Preço do combo */
  precoCombo: number
  /** Preço original (sem desconto) */
  precoOriginal: number
  /** Percentual de desconto */
  desconto: number
  /** URL da imagem */
  urlImagem?: string
  /** Produtos inclusos no combo */
  produtos?: ProdutoBase[]
}

/**
 * Personalizações de um item
 */
export interface PersonalizacaoItem {
  /** Sabores selecionados */
  sabores?: Sabor[]
  /** Borda selecionada */
  borda?: Borda
  /** Tamanho selecionado */
  tamanho?: Tamanho
  /** Adicionais selecionados */
  adicionais?: Adicional[]
  /** Observações adicionais */
  observacoes?: string
}

/**
 * Item genérico no carrinho (base)
 */
export interface ItemCarrinhoBase {
  /** Tipo do item */
  tipo: 'produto' | 'combo'
  /** Quantidade do item */
  quantidade: number
  /** Preço unitário calculado (com personalizações) */
  precoUnitario: number
  /** Preço total do item (precoUnitario × quantidade) */
  precoTotal: number
  /** Personalizações aplicadas */
  personalizacao?: PersonalizacaoItem
}

/**
 * Item de produto no carrinho
 */
export interface ItemProduto extends ItemCarrinhoBase {
  tipo: 'produto'
  /** Produto base */
  produto: ProdutoBase
}

/**
 * Item de combo no carrinho
 */
export interface ItemCombo extends ItemCarrinhoBase {
  tipo: 'combo'
  /** Combo selecionado */
  combo: Combo
  /** Produtos do combo com personalizações */
  produtosPersonalizados?: Array<{
    produto: ProdutoBase
    personalizacao?: PersonalizacaoItem
  }>
}

/**
 * Item no carrinho (união de produto e combo)
 */
export type ItemCarrinho = ItemProduto | ItemCombo

/**
 * Resumo de valores do carrinho
 */
export interface ResumoCarrinho {
  /** Subtotal dos itens */
  subtotal: number
  /** Taxa de entrega */
  taxaEntrega: number
  /** Descontos aplicados */
  desconto: number
  /** Total a pagar */
  total: number
  /** Quantidade total de itens */
  quantidadeItens: number
}

/**
 * Interface para hook de carrinho (Delivery)
 * Mantém compatibilidade com estrutura antiga
 */
export interface ItemCarrinhoDelivery {
  produto: ProdutoBase
  quantidade: number
  saboresSelecionados?: Sabor[]
  bordaSelecionada?: Borda
  tamanhoSelecionado?: Tamanho
  adicionaisSelecionados?: Adicional[]
  observacoes?: string
  produtosCombo?: any[] // Produtos individuais do combo personalizado
}

/**
 * Interface para item do carrinho PDV
 * Mantém compatibilidade com estrutura antiga
 */
export interface ItemCarrinhoPDV {
  produto: ProdutoBase
  quantidade: number
  observacoes?: string
  precoUnitario: number
  precoTotal: number
  saboresSelecionados?: Sabor[]
  bordaSelecionada?: Borda
  tamanhoSelecionado?: Tamanho
  adicionaisSelecionados?: Adicional[]
  produtosCombo?: any[] // Produtos individuais do combo personalizado
  variantId?: string
  variantLabel?: string
}

/**
 * Opções de cálculo de preço
 */
export interface OpcoesCalculoPreco {
  /** Incluir taxa de entrega */
  incluirTaxaEntrega?: boolean
  /** Valor da taxa de entrega */
  taxaEntrega?: number
  /** Aplicar desconto */
  desconto?: number
  /** Tipo de desconto */
  tipoDesconto?: 'percentual' | 'valor'
}

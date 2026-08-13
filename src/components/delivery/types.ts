/**
 * Tipos compartilhados para componentes de delivery
 * @module components/delivery/types
 */

/**
 * Representa um produto no cardápio de delivery
 */
export interface Produto {
  /** ID único do produto */
  id: string
  /** Nome do produto */
  nome: string
  /** Descrição detalhada */
  descricao: string
  /** Preço normal */
  preco: number
  /** Preço promocional (opcional) */
  precoPromocional?: number
  /** Categoria do produto */
  categoria: string
  /** URL da imagem do produto */
  urlImagem: string
  /** Indica se o produto está disponível */
  disponivel?: boolean
  /** Indica se o produto está em destaque */
  destaque?: boolean
}

/**
 * Representa uma categoria de produtos
 */
export interface Categoria {
  /** ID único da categoria */
  id: string
  /** Nome da categoria */
  nome: string
  /** Ordem de exibição */
  ordem: number
}

/**
 * Representa um sabor de pizza
 */
export interface Sabor {
  /** ID único do sabor */
  id: string
  /** Nome do sabor */
  nome: string
  /** Descrição do sabor */
  descricao: string
  /** Categoria (doce ou salgada) */
  categoria: 'doce' | 'salgada'
  /** Lista de ingredientes */
  ingredientes: string[]
  /** Preço adicional do sabor */
  preco: number
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
}

/**
 * Representa um tamanho de pizza
 */
export interface Tamanho {
  /** ID único do tamanho */
  id: string
  /** Nome do tamanho (ex: Pequena, Média, Grande) */
  nome: string
  /** Número de fatias */
  fatias: number
  /** Número de sabores permitidos */
  sabores: number
  /** Preço do tamanho */
  preco: number
}

/**
 * Representa um item no carrinho de delivery
 */
export interface ItemCarrinho {
  /** Produto base */
  produto: Produto
  /** Quantidade do item */
  quantidade: number
  /** Sabores selecionados (para pizzas) */
  saboresSelecionados?: Sabor[]
  /** Borda selecionada (para pizzas) */
  bordaSelecionada?: Borda
  /** Tamanho selecionado (para pizzas) */
  tamanhoSelecionado?: Tamanho
  /** Observações adicionais */
  observacoes?: string
}

/**
 * Props do componente FiltroCategorias
 */
export interface FiltroCategoriaProps {
  /** Lista de categorias disponíveis */
  categorias: Categoria[]
  /** ID da categoria atualmente selecionada */
  categoriaSelecionada: string | null
  /** Callback quando uma categoria é selecionada */
  onSelecionarCategoria: (categoriaId: string | null) => void
}

/**
 * Props do componente ProdutoCard
 */
export interface ProdutoCardProps {
  /** Produto a ser exibido */
  produto: Produto
  /** Callback para adicionar produto ao carrinho */
  onAdicionar: (produto: Produto) => void
}

/**
 * Props do componente GridProdutos
 */
export interface GridProdutosProps {
  /** Lista de produtos a serem exibidos */
  produtos: Produto[]
  /** Callback para adicionar produto ao carrinho */
  onAdicionarProduto: (produto: Produto) => void
}

/**
 * Props do componente SecaoCategoria
 */
export interface SecaoCategoriaProps {
  /** Categoria da seção */
  categoria: Categoria
  /** Produtos da categoria */
  produtos: Produto[]
  /** Callback para adicionar produto ao carrinho */
  onAdicionarProduto: (produto: Produto) => void
}

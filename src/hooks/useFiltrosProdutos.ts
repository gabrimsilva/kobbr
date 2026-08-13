import { useMemo } from 'react'
import type { CategoriaSupabase } from "@/services"

/**
 * Interface para representar um produto
 */
export interface ProdutoFiltro {
  id: string
  nome: string
  descricao: string
  preco: number
  precoPromocional?: number
  categoria_id?: string
  categoria_nome?: string
  categoria?: string
  urlImagem?: string
  imagem_path?: string
  saboresDisponiveis?: boolean
  sabores_disponiveis?: boolean
  quantidadeSabores?: number
  quantidade_sabores?: number
}

/**
 * Retorno do hook useFiltrosProdutos
 */
export interface UseFiltrosProdutosReturn {
  /** Produtos filtrados pela categoria ativa */
  produtosFiltrados: ProdutoFiltro[]
  /** Produtos agrupados por categoria (quando categoriaAtiva === 'todos') */
  produtosAgrupados: Record<string, ProdutoFiltro[]> | null
  /** Função para obter nome de exibição da categoria */
  obterNomeCategoria: (categoria: string) => string
}

/**
 * Hook para filtrar e agrupar produtos por categoria
 * Inclui lógica de filtros e agrupamento
 * 
 * @param produtos - Lista completa de produtos
 * @param categorias - Lista de categorias disponíveis
 * @param categoriaAtiva - ID da categoria atualmente ativa ('todos', 'promocoes', ou ID da categoria)
 * @returns Objeto com produtos filtrados e agrupados
 * 
 * @example
 * const {
 *   produtosFiltrados,
 *   produtosAgrupados,
 *   obterNomeCategoria
 * } = useFiltrosProdutos(produtos, categorias, 'todos')
 * 
 * // Renderizar produtos filtrados
 * {produtosFiltrados.map(produto => <ProdutoCard key={produto.id} produto={produto} />)}
 * 
 * // Renderizar produtos agrupados
 * {produtosAgrupados && Object.entries(produtosAgrupados).map(([categoria, produtos]) => (
 *   <SecaoCategoria key={categoria} nomeCategoria={obterNomeCategoria(categoria)} produtos={produtos} />
 * ))}
 */
export function useFiltrosProdutos(
  produtos: ProdutoFiltro[],
  categorias: CategoriaSupabase[],
  categoriaAtiva: string
): UseFiltrosProdutosReturn {
  /**
   * Filtra produtos pela categoria ativa
   */
  const produtosFiltrados = useMemo(() => {
    if (categoriaAtiva === 'todos') {
      return produtos
    }

    if (categoriaAtiva === 'promocoes') {
      return produtos.filter(produto =>
        produto.precoPromocional && produto.precoPromocional > 0
      )
    }

    // Buscar categoria pelo ID
    const categoriaSelecionada = categorias.find(cat => cat.id === categoriaAtiva)

    if (categoriaSelecionada) {
      // Comparar com categoria_id do produto
      return produtos.filter(produto => produto.categoria_id === categoriaSelecionada.id)
    }

    // Fallback: comparar por nome (para compatibilidade com dados antigos)
    return produtos.filter(produto => {
      const produtoCategoria = produto.categoria_nome || produto.categoria || ''
      const produtoCategoriaLower = produtoCategoria.toLowerCase()
      const categoriaAtivaLower = categoriaAtiva.toLowerCase()
      return produtoCategoriaLower === categoriaAtivaLower
    })
  }, [produtos, categorias, categoriaAtiva])

  /**
   * Agrupa produtos por categoria quando categoriaAtiva === 'todos'
   */
  const produtosAgrupados = useMemo(() => {
    if (categoriaAtiva !== 'todos') {
      return null
    }

    const grupos: Record<string, ProdutoFiltro[]> = {}

    // 1. Adicionar promoções se houver
    const promocoes = produtos.filter(p => p.precoPromocional && p.precoPromocional > 0)
    if (promocoes.length > 0) {
      grupos['promocoes'] = promocoes
    }

    // 2. Agrupar por categorias ativas
    categorias.forEach(categoria => {
      const produtosDaCategoria = produtos.filter(p =>
        p.categoria_id === categoria.id &&
        (!p.precoPromocional || p.precoPromocional <= 0)
      )

      if (produtosDaCategoria.length > 0) {
        grupos[categoria.nome] = produtosDaCategoria
      }
    })

    return grupos
  }, [produtos, categorias, categoriaAtiva])

  /**
   * Obtém o nome de exibição da categoria
   */
  const obterNomeCategoria = (categoria: string): string => {
    if (categoria === 'promocoes') return 'Promoções'

    // Se a categoria já é o nome correto, retornar ela mesma
    const categoriaEncontrada = categorias.find(cat => cat.nome === categoria)
    if (categoriaEncontrada) return categoriaEncontrada.nome

    // Fallback: buscar por nome em lowercase
    const categoriaEncontradaLower = categorias.find(
      cat => cat.nome.toLowerCase() === categoria.toLowerCase()
    )
    return categoriaEncontradaLower?.nome || categoria
  }

  return {
    produtosFiltrados,
    produtosAgrupados,
    obterNomeCategoria
  }
}

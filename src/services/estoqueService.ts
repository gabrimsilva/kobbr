/**
 * Serviço para gerenciamento de estoque
 *
 * Este serviço encapsula todas as operações relacionadas ao estoque,
 * incluindo controle de quantidade e alertas de estoque baixo.
 *
 * @module services/estoqueService
 */

import { supabase } from "@/lib/supabase"
import { comTenant, tenantId } from "./tenant"
import type { EstoqueSupabase } from '@/types/supabase'

/**
 * Interface do serviço de estoque
 */
export interface EstoqueService {
  /**
   * Busca todos os itens do estoque
   * @returns Promise com array de itens
   */
  buscarTodos(): Promise<EstoqueSupabase[]>

  /**
   * Busca um item por ID
   * @param id - ID do item
   * @returns Promise com o item ou null
   */
  buscarPorId(id: string): Promise<EstoqueSupabase | null>

  /**
   * Cria um novo item no estoque
   * @param data - Dados do item
   * @returns Promise com o item criado
   */
  criar(data: Omit<EstoqueSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<EstoqueSupabase>

  /**
   * Atualiza um item existente
   * @param id - ID do item
   * @param data - Dados para atualizar
   * @returns Promise com o item atualizado
   */
  atualizar(id: string, data: Partial<EstoqueSupabase>): Promise<EstoqueSupabase>

  /**
   * Deleta um item permanentemente
   * @param id - ID do item
   */
  excluir(id: string): Promise<void>

  /**
   * Atualiza quantidade de um item
   * @param id - ID do item
   * @param novaQuantidade - Nova quantidade
   * @returns Promise com o item atualizado
   */
  atualizarQuantidade(id: string, novaQuantidade: number): Promise<EstoqueSupabase>

  /**
   * Busca itens com estoque baixo (quantidade < quantidade_minima)
   * @returns Promise com array de itens
   */
  buscarEstoqueBaixo(): Promise<EstoqueSupabase[]>

  /**
   * Dá baixa no estoque baseado no nome do produto
   * @param nomeProduto - Nome do produto vendido
   * @param quantidade - Quantidade vendida (padrão: 1)
   */
  darBaixaPorNomeProduto(nomeProduto: string, quantidade?: number): Promise<void>
}

/**
 * Implementação do serviço de estoque
 */
export const estoqueService: EstoqueService = {
  /**
   * Busca todos os itens ordenados por nome
   */
  async buscarTodos(): Promise<EstoqueSupabase[]> {
    const { data, error } = await supabase
      .from('estoque')
      .select('*')
      .eq('estabelecimento_id', tenantId())
      .order('nome', { ascending: true })

    if (error) {
      console.error('Erro ao buscar itens do estoque:', error)
      throw new Error(`Falha ao buscar itens do estoque: ${error.message}`)
    }

    return data || []
  },

  /**
   * Busca item específico por ID
   */
  async buscarPorId(id: string): Promise<EstoqueSupabase | null> {
    const { data, error } = await supabase
      .from('estoque')
      .select('*')
      .eq('id', id)
      .single()

    if (error) {
      if (error.code === 'PGRST116') {
        return null
      }
      console.error('Erro ao buscar item do estoque:', error)
      throw new Error(`Falha ao buscar item do estoque: ${error.message}`)
    }

    return data
  },

  /**
   * Cria um novo item no estoque
   */
  async criar(data: Omit<EstoqueSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<EstoqueSupabase> {
    const { data: item, error } = await supabase
      .from('estoque')
      .insert([comTenant(data as Record<string, unknown>)])
      .select()
      .single()

    if (error) {
      console.error('Erro ao criar item do estoque:', error)
      throw new Error(`Falha ao criar item do estoque: ${error.message}`)
    }

    if (!item) {
      throw new Error('Item do estoque não foi criado corretamente')
    }

    return item
  },

  /**
   * Atualiza dados de um item
   */
  async atualizar(id: string, data: Partial<EstoqueSupabase>): Promise<EstoqueSupabase> {
    const { data: item, error } = await supabase
      .from('estoque')
      .update({ ...data, atualizado_em: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Erro ao atualizar item do estoque:', error)
      throw new Error(`Falha ao atualizar item do estoque: ${error.message}`)
    }

    if (!item) {
      throw new Error('Item do estoque não encontrado')
    }

    return item
  },

  /**
   * Remove item permanentemente
   */
  async excluir(id: string): Promise<void> {
    const { error } = await supabase
      .from('estoque')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Erro ao excluir item do estoque:', error)
      throw new Error(`Falha ao excluir item do estoque: ${error.message}`)
    }
  },

  /**
   * Atualiza apenas a quantidade de um item
   */
  async atualizarQuantidade(id: string, novaQuantidade: number): Promise<EstoqueSupabase> {
    return this.atualizar(id, { quantidade: novaQuantidade })
  },

  /**
   * Busca itens com estoque abaixo do mínimo
   */
  async buscarEstoqueBaixo(): Promise<EstoqueSupabase[]> {
    // Buscar todos os itens e filtrar em memória
    // (PostgREST não suporta comparação entre colunas diretamente)
    const todos = await this.buscarTodos()

    return todos
      .filter(item => item.quantidade < item.quantidade_minima)
      .sort((a, b) => a.quantidade - b.quantidade)
  },

  /**
   * Dá baixa no estoque baseado no nome do produto
   * @param nomeProduto - Nome do produto vendido
   * @param quantidade - Quantidade vendida
   */
  async darBaixaPorNomeProduto(nomeProduto: string, quantidade: number = 1): Promise<void> {
    try {
      // Buscar item do estoque pelo nome (case insensitive)
      const { data: itens, error: searchError } = await supabase
        .from('estoque')
        .select('*')
        .ilike('nome', `%${nomeProduto}%`)

      if (searchError) {
        console.error('Erro ao buscar item no estoque:', searchError)
        return // Não bloqueia a venda se não encontrar no estoque
      }

      if (!itens || itens.length === 0) {
        console.log(`Produto "${nomeProduto}" não encontrado no estoque`)
        return // Produto não está no controle de estoque
      }

      // Pegar o primeiro item encontrado
      const item = itens[0]

      // Calcular nova quantidade
      const novaQuantidade = Math.max(0, item.quantidade - quantidade)

      // Atualizar quantidade
      await this.atualizarQuantidade(item.id, novaQuantidade)

      console.log(`Baixa no estoque: ${item.nome} - Quantidade: ${quantidade} - Novo estoque: ${novaQuantidade}`)
    } catch (error) {
      console.error('Erro ao dar baixa no estoque:', error)
      // Não lança erro para não bloquear a venda
    }
  }
}

/**
 * Exportar como default para facilitar importação
 */
export default estoqueService

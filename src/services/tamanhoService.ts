/**
 * Serviço para gerenciamento de tamanhos de produtos
 *
 * Este serviço encapsula todas as operações relacionadas a tamanhos,
 * incluindo criação em lote para produtos.
 *
 * @module services/tamanhoService
 */

import { supabase } from "@/lib/supabase"
import { comTenant, comTenantLote } from "./tenant"
import type { TamanhoSupabase } from '@/types/supabase'

/**
 * Interface do serviço de tamanhos
 */
export interface TamanhoService {
  /**
   * Busca todos os tamanhos de um produto
   * @param produtoId - ID do produto
   * @returns Promise com array de tamanhos
   */
  buscarPorProduto(produtoId: string): Promise<TamanhoSupabase[]>

  /**
   * Busca um tamanho por ID
   * @param id - ID do tamanho
   * @returns Promise com o tamanho ou null
   */
  buscarPorId(id: string): Promise<TamanhoSupabase | null>

  /**
   * Cria um novo tamanho
   * @param data - Dados do tamanho
   * @returns Promise com o tamanho criado
   */
  criar(data: Omit<TamanhoSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<TamanhoSupabase>

  /**
   * Atualiza um tamanho existente
   * @param id - ID do tamanho
   * @param data - Dados para atualizar
   * @returns Promise com o tamanho atualizado
   */
  atualizar(id: string, data: Partial<TamanhoSupabase>): Promise<TamanhoSupabase>

  /**
   * Deleta um tamanho permanentemente
   * @param id - ID do tamanho
   */
  excluir(id: string): Promise<void>

  /**
   * Cria múltiplos tamanhos para um produto (remove os antigos)
   * @param produtoId - ID do produto
   * @param tamanhos - Array com dados dos tamanhos
   * @returns Promise com array de tamanhos criados
   */
  criarMultiplos(
    produtoId: string,
    tamanhos: Array<Omit<TamanhoSupabase, 'id' | 'produto_id' | 'criado_em' | 'atualizado_em'>>
  ): Promise<TamanhoSupabase[]>
}

/**
 * Implementação do serviço de tamanhos
 */
export const tamanhoService: TamanhoService = {
  /**
   * Busca tamanhos de um produto ordenados por ordem
   */
  async buscarPorProduto(produtoId: string): Promise<TamanhoSupabase[]> {
    const { data, error } = await supabase
      .from('tamanhos')
      .select('*')
      .eq('produto_id', produtoId)
      .eq('ativo', true)
      .order('ordem', { ascending: true })

    if (error) {
      console.error('Erro ao buscar tamanhos do produto:', error)
      throw new Error(`Falha ao buscar tamanhos do produto: ${error.message}`)
    }

    return data || []
  },

  /**
   * Busca tamanho específico por ID
   */
  async buscarPorId(id: string): Promise<TamanhoSupabase | null> {
    const { data, error } = await supabase
      .from('tamanhos')
      .select('*')
      .eq('id', id)
      .single()

    if (error) {
      if (error.code === 'PGRST116') {
        return null
      }
      console.error('Erro ao buscar tamanho:', error)
      throw new Error(`Falha ao buscar tamanho: ${error.message}`)
    }

    return data
  },

  /**
   * Cria um novo tamanho
   */
  async criar(data: Omit<TamanhoSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<TamanhoSupabase> {
    const { data: tamanho, error } = await supabase
      .from('tamanhos')
      .insert([comTenant(data as Record<string, unknown>)])
      .select()
      .single()

    if (error) {
      console.error('Erro ao criar tamanho:', error)
      throw new Error(`Falha ao criar tamanho: ${error.message}`)
    }

    if (!tamanho) {
      throw new Error('Tamanho não foi criado corretamente')
    }

    return tamanho
  },

  /**
   * Atualiza dados de um tamanho
   */
  async atualizar(id: string, data: Partial<TamanhoSupabase>): Promise<TamanhoSupabase> {
    const { data: tamanho, error } = await supabase
      .from('tamanhos')
      .update({ ...data, atualizado_em: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Erro ao atualizar tamanho:', error)
      throw new Error(`Falha ao atualizar tamanho: ${error.message}`)
    }

    if (!tamanho) {
      throw new Error('Tamanho não encontrado')
    }

    return tamanho
  },

  /**
   * Remove tamanho permanentemente
   */
  async excluir(id: string): Promise<void> {
    const { error } = await supabase
      .from('tamanhos')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Erro ao excluir tamanho:', error)
      throw new Error(`Falha ao excluir tamanho: ${error.message}`)
    }
  },

  /**
   * Cria múltiplos tamanhos para um produto (remove tamanhos antigos)
   */
  async criarMultiplos(
    produtoId: string,
    tamanhos: Array<Omit<TamanhoSupabase, 'id' | 'produto_id' | 'criado_em' | 'atualizado_em'>>
  ): Promise<TamanhoSupabase[]> {
    // Remover tamanhos existentes
    await supabase
      .from('tamanhos')
      .delete()
      .eq('produto_id', produtoId)

    // Criar novos tamanhos
    if (tamanhos.length > 0) {
      const tamanhosParaCriar = tamanhos.map((tamanho, index) => ({
        ...tamanho,
        produto_id: produtoId,
        ordem: index
      }))

      const { data, error } = await supabase
        .from('tamanhos')
        .insert(comTenantLote(tamanhosParaCriar as Record<string, unknown>[]))
        .select()

      if (error) {
        console.error('Erro ao criar tamanhos:', error)
        throw new Error(`Falha ao criar tamanhos: ${error.message}`)
      }

      return data || []
    }

    return []
  }
}

/**
 * Exportar como default para facilitar importação
 */
export default tamanhoService

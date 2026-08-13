/**
 * Serviço para gerenciamento de combos
 *
 * Este serviço encapsula todas as operações relacionadas a combos,
 * incluindo associação com produtos.
 *
 * @module services/comboService
 */

import { supabase } from "@/lib/supabase"
import { comTenant, comTenantLote, tenantId } from "./tenant"
import type { ComboSupabase, ProdutoSupabase } from '@/types/supabase'

/**
 * Interface do serviço de combos
 */
export interface ComboService {
  /**
   * Busca todos os combos ativos
   * @returns Promise com array de combos
   */
  buscarTodos(): Promise<ComboSupabase[]>

  /**
   * Busca um combo por ID
   * @param id - ID do combo
   * @returns Promise com o combo ou null
   */
  buscarPorId(id: string): Promise<ComboSupabase | null>

  /**
   * Cria um novo combo
   * @param data - Dados do combo
   * @returns Promise com o combo criado
   */
  criar(data: Omit<ComboSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<ComboSupabase>

  /**
   * Atualiza um combo existente
   * @param id - ID do combo
   * @param data - Dados para atualizar
   * @returns Promise com o combo atualizado
   */
  atualizar(id: string, data: Partial<ComboSupabase>): Promise<ComboSupabase>

  /**
   * Deleta um combo permanentemente
   * @param id - ID do combo
   */
  excluir(id: string): Promise<void>

  /**
   * Busca produtos associados a um combo
   * @param comboId - ID do combo
   * @returns Promise com array de produtos
   */
  buscarProdutosCombo(comboId: string): Promise<ProdutoSupabase[]>

  /**
   * Associa produtos a um combo
   * @param comboId - ID do combo
   * @param produtoIds - Array de IDs dos produtos
   */
  associarProdutos(comboId: string, produtoIds: string[]): Promise<void>
}

/**
 * Implementação do serviço de combos
 */
export const comboService: ComboService = {
  /**
   * Busca todos os combos ativos ordenados por nome
   */
  async buscarTodos(): Promise<ComboSupabase[]> {
    const { data, error } = await supabase
      .from('combos')
      .select('*')
      .eq('ativo', true)
      .eq('estabelecimento_id', tenantId())
      .order('nome', { ascending: true })

    if (error) {
      console.error('Erro ao buscar combos:', error)
      throw new Error(`Falha ao buscar combos: ${error.message}`)
    }

    return data || []
  },

  /**
   * Busca combo específico por ID
   */
  async buscarPorId(id: string): Promise<ComboSupabase | null> {
    const { data, error } = await supabase
      .from('combos')
      .select('*')
      .eq('id', id)
      .single()

    if (error) {
      if (error.code === 'PGRST116') {
        return null
      }
      console.error('Erro ao buscar combo:', error)
      throw new Error(`Falha ao buscar combo: ${error.message}`)
    }

    return data
  },

  /**
   * Cria um novo combo
   */
  async criar(data: Omit<ComboSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<ComboSupabase> {
    const { data: combo, error } = await supabase
      .from('combos')
      .insert([comTenant(data as Record<string, unknown>)])
      .select()
      .single()

    if (error) {
      console.error('Erro ao criar combo:', error)
      throw new Error(`Falha ao criar combo: ${error.message}`)
    }

    if (!combo) {
      throw new Error('Combo não foi criado corretamente')
    }

    return combo
  },

  /**
   * Atualiza dados de um combo
   */
  async atualizar(id: string, data: Partial<ComboSupabase>): Promise<ComboSupabase> {
    const { data: combo, error } = await supabase
      .from('combos')
      .update({ ...data, atualizado_em: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Erro ao atualizar combo:', error)
      throw new Error(`Falha ao atualizar combo: ${error.message}`)
    }

    if (!combo) {
      throw new Error('Combo não encontrado')
    }

    return combo
  },

  /**
   * Remove combo permanentemente
   */
  async excluir(id: string): Promise<void> {
    const { error } = await supabase
      .from('combos')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Erro ao excluir combo:', error)
      throw new Error(`Falha ao excluir combo: ${error.message}`)
    }
  },

  /**
   * Busca produtos associados ao combo
   */
  async buscarProdutosCombo(comboId: string): Promise<ProdutoSupabase[]> {
    const { data, error } = await supabase
      .from('combo_produtos')
      .select(`
        produtos (*),
        quantidade
      `)
      .eq('combo_id', comboId)

    if (error) {
      console.error('Erro ao buscar produtos do combo:', error)
      throw new Error(`Falha ao buscar produtos do combo: ${error.message}`)
    }

    return (data?.map((item: any) => item.produtos).filter(Boolean) || []) as ProdutoSupabase[]
  },

  /**
   * Associa produtos a um combo (remove associações antigas)
   */
  async associarProdutos(comboId: string, produtoIds: string[]): Promise<void> {
    // Remover associações existentes
    await supabase
      .from('combo_produtos')
      .delete()
      .eq('combo_id', comboId)

    // Criar novas associações
    if (produtoIds.length > 0) {
      const associacoes = produtoIds.map(produtoId => ({
        combo_id: comboId,
        produto_id: produtoId,
        quantidade: 1
      }))

      const { error } = await supabase
        .from('combo_produtos')
        .insert(comTenantLote(associacoes as Record<string, unknown>[]))

      if (error) {
        console.error('Erro ao associar produtos ao combo:', error)
        throw new Error(`Falha ao associar produtos ao combo: ${error.message}`)
      }
    }
  }
}

/**
 * Exportar como default para facilitar importação
 */
export default comboService

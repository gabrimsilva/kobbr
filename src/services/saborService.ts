/**
 * Serviço para gerenciamento de sabores
 *
 * Este serviço encapsula todas as operações relacionadas a sabores,
 * incluindo filtros por tipo e categoria.
 *
 * @module services/saborService
 */

import { supabase } from "@/lib/supabase"
import { comTenant, tenantId } from "./tenant"
import type { SaborSupabase } from '@/types/supabase'

/**
 * Interface do serviço de sabores
 */
export interface SaborService {
  /**
   * Busca todos os sabores ativos
   * @returns Promise com array de sabores
   */
  buscarTodos(): Promise<SaborSupabase[]>

  /**
   * Busca um sabor por ID
   * @param id - ID do sabor
   * @returns Promise com o sabor ou null
   */
  buscarPorId(id: string): Promise<SaborSupabase | null>

  /**
   * Busca sabores por tipo
   * @param tipo - Tipo do sabor
   * @returns Promise com array de sabores
   */
  buscarPorTipo(tipo: string): Promise<SaborSupabase[]>

  /**
   * Cria um novo sabor
   * @param data - Dados do sabor
   * @returns Promise com o sabor criado
   */
  criar(data: Omit<SaborSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<SaborSupabase>

  /**
   * Atualiza um sabor existente
   * @param id - ID do sabor
   * @param data - Dados para atualizar
   * @returns Promise com o sabor atualizado
   */
  atualizar(id: string, data: Partial<SaborSupabase>): Promise<SaborSupabase>

  /**
   * Deleta um sabor permanentemente
   * @param id - ID do sabor
   */
  excluir(id: string): Promise<void>

  /**
   * Busca sabores premium
   * @returns Promise com array de sabores premium
   */
  buscarPremium(): Promise<SaborSupabase[]>
}

/**
 * Implementação do serviço de sabores
 */
export const saborService: SaborService = {
  /**
   * Busca todos os sabores ativos ordenados por tipo e nome
   */
  async buscarTodos(): Promise<SaborSupabase[]> {
    const { data, error } = await supabase
      .from('sabores')
      .select('*')
      .eq('ativo', true)
      .eq('estabelecimento_id', tenantId())
      .order('tipo', { ascending: true })
      .order('nome', { ascending: true })

    if (error) {
      console.error('Erro ao buscar sabores:', error)
      throw new Error(`Falha ao buscar sabores: ${error.message}`)
    }

    return data || []
  },

  /**
   * Busca sabor específico por ID
   */
  async buscarPorId(id: string): Promise<SaborSupabase | null> {
    const { data, error } = await supabase
      .from('sabores')
      .select('*')
      .eq('id', id)
      .single()

    if (error) {
      if (error.code === 'PGRST116') {
        return null
      }
      console.error('Erro ao buscar sabor:', error)
      throw new Error(`Falha ao buscar sabor: ${error.message}`)
    }

    return data
  },

  /**
   * Busca sabores de um tipo específico
   */
  async buscarPorTipo(tipo: string): Promise<SaborSupabase[]> {
    const { data, error } = await supabase
      .from('sabores')
      .select('*')
      .eq('tipo', tipo)
      .eq('estabelecimento_id', tenantId())
      .eq('ativo', true)
      .order('nome', { ascending: true })

    if (error) {
      console.error('Erro ao buscar sabores por tipo:', error)
      throw new Error(`Falha ao buscar sabores por tipo: ${error.message}`)
    }

    return data || []
  },

  /**
   * Cria um novo sabor
   */
  async criar(data: Omit<SaborSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<SaborSupabase> {
    const { data: sabor, error } = await supabase
      .from('sabores')
      .insert([comTenant(data as Record<string, unknown>)])
      .select()
      .single()

    if (error) {
      console.error('Erro ao criar sabor:', error)
      throw new Error(`Falha ao criar sabor: ${error.message}`)
    }

    if (!sabor) {
      throw new Error('Sabor não foi criado corretamente')
    }

    return sabor
  },

  /**
   * Atualiza dados de um sabor
   */
  async atualizar(id: string, data: Partial<SaborSupabase>): Promise<SaborSupabase> {
    const { data: sabor, error } = await supabase
      .from('sabores')
      .update({ ...data, atualizado_em: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Erro ao atualizar sabor:', error)
      throw new Error(`Falha ao atualizar sabor: ${error.message}`)
    }

    if (!sabor) {
      throw new Error('Sabor não encontrado')
    }

    return sabor
  },

  /**
   * Remove sabor permanentemente
   */
  async excluir(id: string): Promise<void> {
    const { error } = await supabase
      .from('sabores')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Erro ao excluir sabor:', error)
      throw new Error(`Falha ao excluir sabor: ${error.message}`)
    }
  },

  /**
   * Busca sabores premium ordenados por valor
   */
  async buscarPremium(): Promise<SaborSupabase[]> {
    const { data, error } = await supabase
      .from('sabores')
      .select('*')
      .eq('is_premium', true)
      .eq('estabelecimento_id', tenantId())
      .eq('ativo', true)
      .order('valor_premium', { ascending: true })

    if (error) {
      console.error('Erro ao buscar sabores premium:', error)
      throw new Error(`Falha ao buscar sabores premium: ${error.message}`)
    }

    return data || []
  }
}

/**
 * Exportar como default para facilitar importação
 */
export default saborService

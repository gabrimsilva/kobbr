/**
 * Serviço para gerenciamento de adicionais
 *
 * Este serviço encapsula todas as operações relacionadas a adicionais,
 * incluindo filtros por categoria.
 *
 * @module services/adicionalService
 */

import { supabase } from "@/lib/supabase"
import { comTenant, tenantId } from "./tenant"
import type { AdicionalSupabase } from '@/types/supabase'

/**
 * Interface do serviço de adicionais
 */
export interface AdicionalService {
  /**
   * Busca todos os adicionais
   * @returns Promise com array de adicionais
   */
  buscarTodos(): Promise<AdicionalSupabase[]>

  /**
   * Busca adicionais por categoria
   * @param categoriaId - ID da categoria
   * @returns Promise com array de adicionais
   */
  buscarPorCategoria(categoriaId: string): Promise<AdicionalSupabase[]>

  /**
   * Busca um adicional por ID
   * @param id - ID do adicional
   * @returns Promise com o adicional ou null
   */
  buscarPorId(id: string): Promise<AdicionalSupabase | null>

  /**
   * Cria um novo adicional
   * @param data - Dados do adicional
   * @returns Promise com o adicional criado
   */
  criar(data: Omit<AdicionalSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<AdicionalSupabase>

  /**
   * Atualiza um adicional existente
   * @param id - ID do adicional
   * @param data - Dados para atualizar
   * @returns Promise com o adicional atualizado
   */
  atualizar(id: string, data: Partial<AdicionalSupabase>): Promise<AdicionalSupabase>

  /**
   * Deleta um adicional permanentemente
   * @param id - ID do adicional
   */
  excluir(id: string): Promise<void>
}

/**
 * Implementação do serviço de adicionais
 */
export const adicionalService: AdicionalService = {
  /**
   * Busca todos os adicionais ordenados por nome
   */
  async buscarTodos(): Promise<AdicionalSupabase[]> {
    const { data, error } = await supabase
      .from('adicionais')
      .select('*')
      .eq('estabelecimento_id', tenantId())
      .order('nome', { ascending: true })

    if (error) {
      console.error('Erro ao buscar adicionais:', error)
      throw new Error(`Falha ao buscar adicionais: ${error.message}`)
    }

    return data || []
  },

  /**
   * Busca adicionais de uma categoria específica
   */
  async buscarPorCategoria(categoriaId: string): Promise<AdicionalSupabase[]> {
    const { data, error } = await supabase
      .from('adicionais')
      .select('*')
      .eq('categoria_id', categoriaId)
      .eq('ativo', true)
      .order('nome', { ascending: true })

    if (error) {
      console.error('Erro ao buscar adicionais por categoria:', error)
      throw new Error(`Falha ao buscar adicionais por categoria: ${error.message}`)
    }

    return data || []
  },

  /**
   * Busca adicional específico por ID
   */
  async buscarPorId(id: string): Promise<AdicionalSupabase | null> {
    const { data, error } = await supabase
      .from('adicionais')
      .select('*')
      .eq('id', id)
      .single()

    if (error) {
      if (error.code === 'PGRST116') {
        return null
      }
      console.error('Erro ao buscar adicional:', error)
      throw new Error(`Falha ao buscar adicional: ${error.message}`)
    }

    return data
  },

  /**
   * Cria um novo adicional
   */
  async criar(data: Omit<AdicionalSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<AdicionalSupabase> {
    const { data: adicional, error } = await supabase
      .from('adicionais')
      .insert([comTenant(data as Record<string, unknown>)])
      .select()
      .single()

    if (error) {
      console.error('Erro ao criar adicional:', error)
      throw new Error(`Falha ao criar adicional: ${error.message}`)
    }

    if (!adicional) {
      throw new Error('Adicional não foi criado corretamente')
    }

    return adicional
  },

  /**
   * Atualiza dados de um adicional
   */
  async atualizar(id: string, data: Partial<AdicionalSupabase>): Promise<AdicionalSupabase> {
    const { data: adicional, error } = await supabase
      .from('adicionais')
      .update({ ...data, atualizado_em: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Erro ao atualizar adicional:', error)
      throw new Error(`Falha ao atualizar adicional: ${error.message}`)
    }

    if (!adicional) {
      throw new Error('Adicional não encontrado')
    }

    return adicional
  },

  /**
   * Remove adicional permanentemente
   */
  async excluir(id: string): Promise<void> {
    const { error } = await supabase
      .from('adicionais')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Erro ao excluir adicional:', error)
      throw new Error(`Falha ao excluir adicional: ${error.message}`)
    }
  }
}

/**
 * Exportar como default para facilitar importação
 */
export default adicionalService

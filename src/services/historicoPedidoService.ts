/**
 * Serviço para gerenciamento do histórico de pedidos
 *
 * Este serviço registra todas as mudanças de status dos pedidos,
 * permitindo rastreamento completo do ciclo de vida de cada pedido.
 *
 * @module services/historicoPedidoService
 */

import { supabase } from "@/lib/supabase"
import { comTenant, tenantId } from "./tenant"
import type { HistoricoPedidoSupabase } from '@/types/supabase'

/**
 * Interface do serviço de histórico de pedidos
 */
export interface HistoricoPedidoService {
  /**
   * Busca todo o histórico de um pedido
   * @param pedidoId - ID do pedido
   * @returns Promise com array de históricos ordenados por data
   */
  buscarPorPedido(pedidoId: string): Promise<HistoricoPedidoSupabase[]>

  /**
   * Adiciona novo status ao histórico do pedido
   * @param pedidoId - ID do pedido
   * @param status - Novo status
   * @param observacao - Observação opcional
   * @returns Promise com o registro criado
   */
  adicionarStatus(pedidoId: string, status: string, observacao?: string): Promise<HistoricoPedidoSupabase>

  /**
   * Busca o último status registrado de um pedido
   * @param pedidoId - ID do pedido
   * @returns Promise com o último status ou null
   */
  buscarUltimoStatus(pedidoId: string): Promise<HistoricoPedidoSupabase | null>

  /**
   * Atualiza observação de um status já registrado
   * @param id - ID do registro de histórico
   * @param observacao - Nova observação
   * @returns Promise com o registro atualizado
   */
  atualizarObservacao(id: string, observacao: string): Promise<HistoricoPedidoSupabase>

  /**
   * Busca todos os pedidos com seus últimos status
   * @returns Promise com array de pedidos e status
   */
  buscarTodosPedidos(): Promise<Array<{ pedido_id: string; ultimo_status: string; criado_em: string }>>

  /**
   * Configura realtime para monitorar histórico de um pedido
   * @param pedidoId - ID do pedido a monitorar
   * @param callback - Função chamada quando há mudanças
   * @returns Canal de subscrição
   */
  configurarRealtime(pedidoId: string, callback: (payload: any) => void): any

  /**
   * Remove canal de realtime
   * @param channel - Canal a ser removido
   */
  removerRealtime(channel: any): Promise<'ok' | 'timed out' | 'error'>
}

/**
 * Implementação do serviço de histórico de pedidos
 */
export const historicoPedidoService: HistoricoPedidoService = {
  /**
   * Busca histórico completo de um pedido ordenado cronologicamente
   */
  async buscarPorPedido(pedidoId: string): Promise<HistoricoPedidoSupabase[]> {
    const { data, error } = await supabase
      .from('historico_pedidos')
      .select('*')
      .eq('pedido_id', pedidoId)
      .order('criado_em', { ascending: true })

    if (error) {
      console.error('Erro ao buscar histórico do pedido:', error)
      throw new Error(`Falha ao buscar histórico: ${error.message}`)
    }

    return data || []
  },

  /**
   * Adiciona novo registro de status no histórico
   */
  async adicionarStatus(pedidoId: string, status: string, observacao?: string): Promise<HistoricoPedidoSupabase> {
    const { data, error } = await supabase
      .from('historico_pedidos')
      .insert(comTenant({
        pedido_id: pedidoId,
        status,
        observacao
      }))
      .select()
      .single()

    if (error) {
      console.error('Erro ao adicionar status ao histórico:', error)
      throw new Error(`Falha ao adicionar status: ${error.message}`)
    }

    if (!data) {
      throw new Error('Status não foi adicionado ao histórico')
    }

    return data
  },

  /**
   * Busca o status mais recente de um pedido
   */
  async buscarUltimoStatus(pedidoId: string): Promise<HistoricoPedidoSupabase | null> {
    const { data, error } = await supabase
      .from('historico_pedidos')
      .select('*')
      .eq('pedido_id', pedidoId)
      .order('criado_em', { ascending: false })
      .limit(1)
      .single()

    if (error && error.code !== 'PGRST116') {
      console.error('Erro ao buscar último status:', error)
      throw new Error(`Falha ao buscar último status: ${error.message}`)
    }

    return data
  },

  /**
   * Atualiza observação de um registro de histórico
   */
  async atualizarObservacao(id: string, observacao: string): Promise<HistoricoPedidoSupabase> {
    const { data, error } = await supabase
      .from('historico_pedidos')
      .update({
        observacao,
        atualizado_em: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Erro ao atualizar observação:', error)
      throw new Error(`Falha ao atualizar observação: ${error.message}`)
    }

    if (!data) {
      throw new Error('Registro de histórico não encontrado')
    }

    return data
  },

  /**
   * Busca todos os pedidos com seus status mais recentes
   */
  async buscarTodosPedidos(): Promise<Array<{ pedido_id: string; ultimo_status: string; criado_em: string }>> {
    const { data, error } = await supabase
      .from('historico_pedidos')
      .select('pedido_id, status, criado_em')
      .eq('estabelecimento_id', tenantId())
      .order('criado_em', { ascending: false })

    if (error) {
      console.error('Erro ao buscar todos os pedidos:', error)
      throw new Error(`Falha ao buscar pedidos: ${error.message}`)
    }

    // Agrupar por pedido_id e pegar o último status
    const pedidosMap = new Map()
    data?.forEach(item => {
      if (!pedidosMap.has(item.pedido_id)) {
        pedidosMap.set(item.pedido_id, {
          pedido_id: item.pedido_id,
          ultimo_status: item.status,
          criado_em: item.criado_em
        })
      }
    })

    return Array.from(pedidosMap.values())
  },

  /**
   * Configura canal realtime para monitorar mudanças no histórico
   */
  configurarRealtime(pedidoId: string, callback: (payload: any) => void) {
    const channel = supabase
      .channel(`historico-pedido-${pedidoId}-${Date.now()}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'historico_pedidos',
          filter: `pedido_id=eq.${pedidoId}`
        },
        callback
      )
      .subscribe()

    return channel
  },

  /**
   * Remove canal de subscrição realtime
   */
  removerRealtime(channel: any) {
    return supabase.removeChannel(channel)
  }
}

/**
 * Exportar como default para facilitar importação
 */
export default historicoPedidoService

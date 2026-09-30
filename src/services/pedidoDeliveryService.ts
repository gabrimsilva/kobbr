/**
 * Serviço para integração de pedidos delivery com vendas e estoque
 *
 * @module services/pedidoDeliveryService
 */

import { supabase } from '@/lib/supabase'
import { vendaService } from './vendaService'

export interface ResultadoBaixaEstoque {
  /** A baixa já tinha sido feita antes (pagamento online ou etapa anterior) */
  jaBaixado: boolean
  /** Itens que não tinham saldo suficiente (o saldo foi zerado) */
  alertas: string[]
}

/**
 * Classe de serviço para gerenciar integração de pedidos delivery
 */
class PedidoDeliveryService {
  /**
   * Baixa o estoque do pedido (função baixar_estoque_pedido no banco).
   * Idempotente: se já foi baixado, não baixa de novo. Chamada quando o pedido
   * vai para "Prontos p/ Entrega" e, por segurança, ao finalizar.
   *
   * @param pedidoUuid - Coluna `id` do pedido (uuid)
   */
  async baixarEstoque(pedidoUuid: string): Promise<ResultadoBaixaEstoque> {
    const { data, error } = await supabase.rpc('baixar_estoque_pedido', { p_pedido_id: pedidoUuid })
    if (error) throw new Error(`Não foi possível baixar o estoque do pedido: ${error.message}`)
    return {
      jaBaixado: !!data?.ja_baixado,
      alertas: Array.isArray(data?.alertas) ? data.alertas : []
    }
  }

  /**
   * Devolve ao estoque o que foi baixado para o pedido (pedido cancelado).
   * Não faz nada se o estoque do pedido não foi baixado.
   *
   * @param pedidoUuid - Coluna `id` do pedido (uuid)
   */
  async estornarEstoque(pedidoUuid: string): Promise<boolean> {
    const { data, error } = await supabase.rpc('estornar_estoque_pedido', { p_pedido_id: pedidoUuid })
    if (error) throw new Error(`Não foi possível devolver o estoque do pedido: ${error.message}`)
    return !!data?.estornado
  }

  /**
   * Finaliza um pedido delivery:
   * 1. Garante a baixa de estoque (normalmente já feita em "Prontos p/ Entrega")
   * 2. Cria registro em sales (entra nas métricas)
   *
   * @param pedido - Dados completos do pedido
   * @returns Objeto com sucesso e dados da venda criada
   */
  async finalizarPedidoDelivery(pedido: any): Promise<{
    sucesso: boolean
    venda?: any
    erro?: string
  }> {
    try {
      console.log(`🚀 Iniciando finalização do pedido delivery: ${pedido.codigo_pedido}`)

      // Normalmente não faz nada: a baixa aconteceu em "Prontos p/ Entrega".
      // Cobre pedidos arrastados direto para "Entregues".
      const baixa = await this.baixarEstoque(pedido.id)

      const venda = await vendaService.criarVendaDelivery(pedido)
      console.log(`✅ Venda criada: ${venda?.sale_number}`)

      if (!baixa.jaBaixado && baixa.alertas.length > 0) {
        return {
          sucesso: false,
          venda,
          erro: `Venda criada, mas faltou estoque em: ${baixa.alertas.join('; ')}`
        }
      }

      return { sucesso: true, venda }
    } catch (error) {
      console.error('❌ Erro ao finalizar pedido delivery:', error)
      return {
        sucesso: false,
        erro: error instanceof Error ? error.message : 'Erro ao finalizar pedido delivery'
      }
    }
  }
}

// Exportar instância única do serviço
export const pedidoDeliveryService = new PedidoDeliveryService()

/**
 * Serviço para gerenciamento de consumo interno no PDV
 * 
 * Integra com as RPC functions do Supabase para:
 * - Registrar consumos internos de forma atômica
 * - Consultar dados de consumo por período para métricas
 * 
 * @module services/consumoInternoService
 */

import { supabase } from "@/lib/supabase"
import { tenantId } from "./tenant"

/**
 * Interface para resposta da RPC registrar_consumo_interno
 */
export interface RegistrarConsumoResponso {
  success: boolean
  consumption_id?: string
  sale_id?: string
  sale_number?: string
  total_quantity?: number
  message: string
  error_code?: string
}

/**
 * Interface para item de consumo interno
 */
export interface ItemConsumo {
  product_id: string
  product_name: string
  quantity: number
  unit_price?: number
}

/**
 * Interface para dados de consumo por período
 */
export interface ConsumosPorPeriodo {
  periodo: string
  total_unidades: number
  total_transacoes: number
  media_unidades_transacao: number
}

/**
 * Classe de serviço para gerenciar consumo interno
 */
class ConsumoInternoService {
  /**
   * Registra um consumo interno de forma atômica
   * 
   * Chama a RPC function registrar_consumo_interno() que executa:
   * 1. Validações (usuário, estabelecimento, stock)
   * 2. Criar venda interna
   * 3. Registrar consumo em internal_consumptions
   * 4. Atualizar estoque
   * 5. Criar movimento de estoque
   * 
   * Tudo em uma transação atômica (all-or-nothing)
   * 
   * @param items - Array de itens consumidos (product_id, quantity, etc)
   * @param createdBy - UUID do usuário (opcional - usa auth.uid() se não fornecido)
   * @returns Promise<RegistrarConsumoResponso>
   * 
   * @example
   * ```tsx
   * const resultado = await consumoInternoService.registrarConsumo([
   *   {
   *     product_id: '550e8400-e29b-41d4-a716-446655440001',
   *     product_name: 'Pizza Margherita',
   *     quantity: 2,
   *     unit_price: 25.00
   *   }
   * ])
   * 
   * if (resultado.success) {
   *   console.log('Consumo registrado:', resultado.consumption_id)
   * } else {
   *   console.error('Erro:', resultado.message)
   * }
   * ```
   */
  async registrarConsumo(
    items: ItemConsumo[],
    createdBy?: string
  ): Promise<RegistrarConsumoResponso> {
    try {
      // Validações básicas
      if (!items || items.length === 0) {
        return {
          success: false,
          message: 'Itens não podem estar vazios'
        }
      }

      // Validar estrutura de cada item
      for (const item of items) {
        if (!item.product_id || !item.quantity || item.quantity <= 0) {
          return {
            success: false,
            message: `Item inválido: product_id e quantity são obrigatórios e quantity deve ser > 0`
          }
        }
      }

      // Obter estabelecimento do usuário
      const estabelecimentoId = tenantId()
      if (!estabelecimentoId) {
        return {
          success: false,
          message: 'Estabelecimento do usuário não identificado'
        }
      }

      // Obter usuário autenticado se não foi fornecido
      let userId = createdBy
      if (!userId) {
        const { data: { user } } = await supabase.auth.getUser()
        userId = user?.id
        if (!userId) {
          return {
            success: false,
            message: 'Usuário não autenticado'
          }
        }
      }

      console.log('📦 [CONSUMO_INTERNO] Iniciando registro de consumo:', {
        estabelecimentoId,
        userId,
        totalItens: items.length,
        totalQuantidade: items.reduce((sum, item) => sum + item.quantity, 0)
      })

      // Chamar RPC function registrar_consumo_interno()
      const { data, error } = await supabase.rpc('registrar_consumo_interno', {
        p_estabelecimento_id: estabelecimentoId,
        p_items: items,
        p_created_by: userId
      })

      if (error) {
        console.error('❌ [CONSUMO_INTERNO] Erro ao chamar RPC:', error)
        return {
          success: false,
          message: `Erro ao registrar consumo: ${error.message}`,
          error_code: error.code
        }
      }

      // RPC retorna JSONB, então data já é um objeto
      const resultado = data as RegistrarConsumoResponso

      if (!resultado.success) {
        console.warn('⚠️ [CONSUMO_INTERNO] RPC retornou success=false:', resultado.message)
        return resultado
      }

      console.log('✅ [CONSUMO_INTERNO] Consumo registrado com sucesso:', {
        consumptionId: resultado.consumption_id,
        saleId: resultado.sale_id,
        saleNumber: resultado.sale_number,
        totalQuantidade: resultado.total_quantity
      })

      return resultado
    } catch (error) {
      const mensagemErro = error instanceof Error ? error.message : 'Erro desconhecido'
      console.error('❌ [CONSUMO_INTERNO] Erro ao registrar consumo:', mensagemErro)
      return {
        success: false,
        message: `Erro inesperado: ${mensagemErro}`
      }
    }
  }

  /**
   * Obtém consumos internos agregados por período
   * 
   * Chama a RPC function obter_consumos_por_periodo() que retorna
   * dados agregados (soma, contagem, média) de consumos por período.
   * 
   * @param dataInicio - Data de início (inclusive)
   * @param dataFim - Data de fim (inclusive)
   * @param granularidade - 'dia' | 'semana' | 'mes' (padrão: 'dia')
   * @returns Promise<ConsumosPorPeriodo[]>
   * 
   * @example
   * ```tsx
   * // Últimos 30 dias, agrupado por dia
   * const consumos = await consumoInternoService.obterPorPeriodo(
   *   new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
   *   new Date(),
   *   'dia'
   * )
   * 
   * consumos.forEach(c => {
   *   console.log(`${c.periodo}: ${c.total_unidades} unidades`)
   * })
   * ```
   */
  async obterPorPeriodo(
    dataInicio: Date,
    dataFim: Date,
    granularidade: 'dia' | 'semana' | 'mes' = 'dia'
  ): Promise<ConsumosPorPeriodo[]> {
    try {
      // Validar granularidade
      if (!['dia', 'semana', 'mes'].includes(granularidade)) {
        granularidade = 'dia'
      }

      // Obter estabelecimento do usuário
      const estabelecimentoId = tenantId()
      if (!estabelecimentoId) {
        console.warn('⚠️ [CONSUMO_INTERNO] Estabelecimento não identificado')
        return []
      }

      // Formatar datas para formato DATE
      const dataInicioStr = dataInicio.toISOString().split('T')[0]
      const dataFimStr = dataFim.toISOString().split('T')[0]

      console.log('📊 [CONSUMO_INTERNO] Consultando consumos por período:', {
        estabelecimentoId,
        dataInicio: dataInicioStr,
        dataFim: dataFimStr,
        granularidade
      })

      // Chamar RPC function obter_consumos_por_periodo()
      const { data, error } = await supabase.rpc('obter_consumos_por_periodo', {
        p_estabelecimento_id: estabelecimentoId,
        p_data_inicio: dataInicioStr,
        p_data_fim: dataFimStr,
        p_granularidade: granularidade
      })

      if (error) {
        console.error('❌ [CONSUMO_INTERNO] Erro ao chamar RPC:', error)
        return []
      }

      // data deve ser um array de ConsumosPorPeriodo
      const consumos = (data || []) as ConsumosPorPeriodo[]

      console.log('✅ [CONSUMO_INTERNO] Consumos obtidos:', {
        quantidade: consumos.length,
        periodosPrimeiros: consumos.slice(0, 3).map(c => c.periodo)
      })

      return consumos
    } catch (error) {
      const mensagemErro = error instanceof Error ? error.message : 'Erro desconhecido'
      console.error('❌ [CONSUMO_INTERNO] Erro ao obter consumos:', mensagemErro)
      return []
    }
  }

  /**
   * Valida se um consumo interno é válido antes de enviar
   * 
   * Validações incluem:
   * - Items não vazio
   * - Cada item tem product_id e quantity válidos
   * - Quantity é positiva
   * 
   * @param items - Array de itens
   * @returns { valido: boolean, mensagem?: string }
   */
  validarItems(items: any[]): { valido: boolean; mensagem?: string } {
    if (!items || items.length === 0) {
      return {
        valido: false,
        mensagem: 'Adicione pelo menos um item ao carrinho'
      }
    }

    for (const item of items) {
      if (!item.product_id) {
        return {
          valido: false,
          mensagem: `Item sem product_id identificado`
        }
      }

      const quantity = item.quantidade || item.quantity
      if (!quantity || quantity <= 0) {
        return {
          valido: false,
          mensagem: `Quantidade inválida para ${item.product_name || item.produto?.nome || 'item desconhecido'}`
        }
      }
    }

    return { valido: true }
  }

  /**
   * Formata items do carrinho PDV para o formato esperado pela RPC
   * 
   * Converte ItemCarrinhoPDV para ItemConsumo
   * 
   * @param carrinhoPDV - Array de ItemCarrinhoPDV
   * @returns Array<ItemConsumo>
   * 
   * @example
   * ```tsx
   * const items = consumoInternoService.formatarItensCarrinho(carrinho)
   * // Resultado: [{ product_id: '...', quantity: 2, ... }]
   * ```
   */
  formatarItensCarrinho(carrinhoPDV: any[]): ItemConsumo[] {
    return carrinhoPDV.map(item => ({
      product_id: item.produto.id,
      product_name: item.produto.nome,
      quantity: item.quantidade,
      unit_price: item.precoUnitario
    }))
  }
}

// Exportar instância única do serviço
export const consumoInternoService = new ConsumoInternoService()

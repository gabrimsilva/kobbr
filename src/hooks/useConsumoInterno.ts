/**
 * Hook customizado para gerenciar consumo interno no PDV
 * 
 * Integra com o serviço consumoInternoService para:
 * - Validar items de consumo
 * - Registrar consumo interno via RPC
 * - Obter dados de consumo para métricas
 * - Gerenciar loading e erros
 * 
 * @module hooks/useConsumoInterno
 */

import { useState } from 'react'
import { consumoInternoService, type ItemConsumo, type ConsumosPorPeriodo } from '@/services'

/**
 * Estado de resultado de um registro de consumo
 */
interface ResultadoRegistroConsumo {
  sucesso: boolean
  consumptionId?: string
  saleId?: string
  numeroVenda?: string
  totalQuantidade?: number
  erro?: string
}

/**
 * Hook customizado para gerenciar consumo interno
 * 
 * Fornece funções para:
 * - Validar items
 * - Registrar consumo
 * - Obter consumos por período
 * - Gerenciar estados de loading e erro
 * 
 * @example
 * ```tsx
 * const {
 *   registrando,
 *   erro,
 *   validarItems,
 *   registrarConsumo,
 *   obterPorPeriodo
 * } = useConsumoInterno()
 * 
 * const resultado = await registrarConsumo(items)
 * if (resultado.sucesso) {
 *   console.log('Consumo registrado:', resultado.numeroVenda)
 * }
 * ```
 */
export function useConsumoInterno() {
  const [registrando, setRegistrando] = useState(false)
  const [carregando, setCarregando] = useState(false)
  const [erro, setErro] = useState<string | null>(null)

  /**
   * Valida se os items são válidos para consumo interno
   */
  const validarItems = (items: any[]): { valido: boolean; mensagem?: string } => {
    return consumoInternoService.validarItems(items)
  }

  /**
   * Formata items do carrinho para o formato da RPC
   */
  const formatarItems = (carrinhoPDV: any[]): ItemConsumo[] => {
    return consumoInternoService.formatarItensCarrinho(carrinhoPDV)
  }

  /**
   * Registra um consumo interno
   * 
   * Executa validações e chama a RPC function registrar_consumo_interno()
   * que processa atomicamente:
   * - Criar venda interna
   * - Registrar consumo
   * - Atualizar estoque
   * - Criar movimento de estoque
   */
  const registrarConsumo = async (
    items: ItemConsumo[] | any[],
    createdBy?: string
  ): Promise<ResultadoRegistroConsumo> => {
    try {
      setRegistrando(true)
      setErro(null)

      // Validar items
      const validacao = validarItems(items)
      if (!validacao.valido) {
        const mensagem = validacao.mensagem || 'Items inválidos'
        setErro(mensagem)
        console.warn('⚠️ Validação falhou:', mensagem)
        return {
          sucesso: false,
          erro: mensagem
        }
      }

      // Se items vem do carrinho PDV, formatar
      let itemsFormatados: ItemConsumo[]
      if (items.length > 0 && items[0].produto) {
        // É carrinho PDV
        itemsFormatados = formatarItems(items)
      } else {
        // Já é ItemConsumo
        itemsFormatados = items as ItemConsumo[]
      }

      console.log('📦 [CONSUMO_INTERNER_HOOK] Registrando consumo com items:', itemsFormatados)

      // Chamar serviço
      const resposta = await consumoInternoService.registrarConsumo(itemsFormatados, createdBy)

      if (!resposta.success) {
        const mensagem = resposta.message || 'Erro ao registrar consumo'
        setErro(mensagem)
        console.error('❌ Erro ao registrar consumo:', mensagem)
        return {
          sucesso: false,
          erro: mensagem
        }
      }

      console.log('✅ Consumo registrado com sucesso:', {
        consumptionId: resposta.consumption_id,
        saleNumber: resposta.sale_number
      })

      return {
        sucesso: true,
        consumptionId: resposta.consumption_id,
        saleId: resposta.sale_id,
        numeroVenda: resposta.sale_number,
        totalQuantidade: resposta.total_quantity
      }
    } catch (error) {
      const mensagem = error instanceof Error ? error.message : 'Erro desconhecido'
      setErro(mensagem)
      console.error('❌ Erro ao registrar consumo:', error)
      return {
        sucesso: false,
        erro: mensagem
      }
    } finally {
      setRegistrando(false)
    }
  }

  /**
   * Obtém consumos internos agregados por período
   * 
   * Útil para exibir em gráficos de evolução de consumo
   */
  const obterPorPeriodo = async (
    dataInicio: Date,
    dataFim: Date,
    granularidade: 'dia' | 'semana' | 'mes' = 'dia'
  ): Promise<ConsumosPorPeriodo[]> => {
    try {
      setCarregando(true)
      setErro(null)

      console.log('📊 [CONSUMO_INTERNER_HOOK] Obtendo consumos por período:', {
        dataInicio,
        dataFim,
        granularidade
      })

      const consumos = await consumoInternoService.obterPorPeriodo(
        dataInicio,
        dataFim,
        granularidade
      )

      console.log('✅ Consumos obtidos:', consumos.length, 'períodos')
      return consumos
    } catch (error) {
      const mensagem = error instanceof Error ? error.message : 'Erro desconhecido'
      setErro(mensagem)
      console.error('❌ Erro ao obter consumos:', error)
      return []
    } finally {
      setCarregando(false)
    }
  }

  /**
   * Limpa o estado de erro
   */
  const limparErro = () => {
    setErro(null)
  }

  return {
    // Estados
    registrando,
    carregando,
    erro,

    // Funções
    validarItems,
    formatarItems,
    registrarConsumo,
    obterPorPeriodo,
    limparErro
  }
}

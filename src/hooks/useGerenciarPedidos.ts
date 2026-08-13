import { useState, useRef, useCallback } from 'react'
import { pedidoService, historicoPedidoService, pedidoDeliveryService } from '@/services'
import type { PedidoSupabase } from '@/types/supabase'
import { filtrarPedidosAtivos } from '@/utils/pedidosFiltros'
import { useError, ErrorType, ErrorSeverity } from '@/contexts/ErrorContext'
import { withRetry, RETRY_PRESETS } from '@/utils/retry'
import toast from 'react-hot-toast'

/**
 * Retorno do hook useGerenciarPedidos
 */
export interface UseGerenciarPedidosReturn {
  /** Lista de pedidos */
  pedidos: PedidoSupabase[]
  /** Indica se está carregando */
  loading: boolean
  /** Indica se há novo pedido recebido */
  novoPedidoRecebido: boolean
  /** Carregar pedidos do banco */
  carregarPedidos: (showLoading?: boolean) => Promise<void>
  /** Atualizar status de um pedido */
  atualizarStatus: (pedidoId: string, novoStatus: string) => Promise<void>
  /** Limpar lista de pedidos */
  limparPedidos: () => void
}

/**
 * Hook customizado para gerenciar pedidos
 * 
 * Gerencia o carregamento, atualização e notificação de pedidos.
 * 
 * @param onNovoPedido - Callback chamado quando há novos pedidos
 * @param notificacoesAtivas - Indica se notificações estão ativas
 * 
 * @example
 * ```tsx
 * const { pedidos, loading, carregarPedidos, atualizarStatus } = useGerenciarPedidos(
 *   (quantidade) => notificarNovoPedido(quantidade),
 *   notificacoesAtivas
 * )
 * ```
 */
export function useGerenciarPedidos(
  onNovoPedido?: (quantidade: number) => void,
  notificacoesAtivas: boolean = true
): UseGerenciarPedidosReturn {
  const [pedidos, setPedidos] = useState<PedidoSupabase[]>([])
  const [loading, setLoading] = useState(true)
  const [novoPedidoRecebido, setNovoPedidoRecebido] = useState(false)
  const pedidosAnteriores = useRef<string[]>([])
  const notificacoesAtivasRef = useRef(notificacoesAtivas)
  const onNovoPedidoRef = useRef(onNovoPedido)

  // Hook de gerenciamento de erros
  const { reportError } = useError()

  // Atualizar refs sem causar re-render
  notificacoesAtivasRef.current = notificacoesAtivas
  onNovoPedidoRef.current = onNovoPedido

  /**
   * Carrega pedidos do banco de dados com retry automático
   */
  const carregarPedidos = useCallback(async (showLoading = false) => {
    try {
      if (showLoading) setLoading(true)

      // Buscar pedidos com retry automático
      const todosPedidos = await withRetry(
        async () => {
          const result = await pedidoService.buscarTodos(100)
          if (!result) throw new Error('Nenhum dado retornado')
          return result
        },
        RETRY_PRESETS.NORMAL
      )

      const pedidosAtivos = filtrarPedidosAtivos(todosPedidos, 24)

      // Verificar se há novos pedidos
      const pedidosIds = pedidosAtivos.map(p => p.pedido_id)
      const novosIds = pedidosIds.filter(id => !pedidosAnteriores.current.includes(id))

      if (novosIds.length > 0 && pedidosAnteriores.current.length > 0) {
        setNovoPedidoRecebido(true)

        // Remover indicador após 5 segundos
        setTimeout(() => {
          setNovoPedidoRecebido(false)
        }, 5000)

        // Notificar se as notificações estão ativas
        if (notificacoesAtivasRef.current && onNovoPedidoRef.current) {
          onNovoPedidoRef.current(novosIds.length)
        }
      }

      pedidosAnteriores.current = pedidosIds
      setPedidos(pedidosAtivos)
    } catch (error) {
      reportError({
        type: ErrorType.DATABASE,
        severity: ErrorSeverity.ERROR,
        message: 'Não foi possível carregar os pedidos',
        technicalMessage: 'Falha ao buscar pedidos do banco de dados',
        originalError: error,
        retryable: true,
        action: 'Verifique sua conexão com a internet'
      })
    } finally {
      setLoading(false)
    }
  }, [reportError])

  /**
   * Atualiza o status de um pedido com retry automático
   */
  const atualizarStatus = useCallback(async (pedidoId: string, novoStatus: string) => {
    const pedidoAtual = pedidos.find(p => p.pedido_id === pedidoId)

    try {
      console.log('🎯 Iniciando atualização de status:', { pedidoId, novoStatus })
      
      // Normalizar status
      let statusFinal = novoStatus

      // 🆕 SE STATUS FOR FINALIZADO: Integrar com vendas e estoque
      if (statusFinal === 'Finalizado' && pedidoAtual) {
        console.log(`🎯 Finalizando pedido delivery: ${pedidoId}`)
        
        try {
          // Criar venda e dar baixa no estoque
          const resultado = await pedidoDeliveryService.finalizarPedidoDelivery(pedidoAtual)
          
          if (resultado.sucesso && resultado.venda) {
            toast.success(`Pedido finalizado! Venda: ${resultado.venda?.sale_number}`)
            console.log(`✅ Venda criada: ${resultado.venda?.sale_number}`)
          } else {
            // Não falhar completamente, apenas avisar
            console.warn(`⚠️ Aviso ao finalizar pedido: ${resultado.erro}`)
            toast.success(`Pedido atualizado (${resultado.erro})`)
          }
        } catch (integrationError) {
          // Não impedir a atualização de status se houver erro de integração
          console.warn(`⚠️ Erro na integração de vendas/estoque, continuando com atualização de status:`, integrationError)
          toast.success('Status atualizado (com avisos)')
        }
      }

      // Atualizar status no banco com retry
      await withRetry(
        async () => {
          await pedidoService.atualizarStatus(pedidoId, statusFinal)
        },
        RETRY_PRESETS.CRITICAL
      )

      // Adicionar ao histórico
      let statusHistorico = statusFinal
      let observacaoHistorico = `Status alterado para: ${statusFinal}`

      if (statusFinal === 'Finalizado' && pedidoAtual) {
        statusHistorico = pedidoAtual.entrega_domicilio ? 'Entregue' : 'Retirado'
        observacaoHistorico = `Status alterado para: ${statusHistorico}`
      }

      await withRetry(
        async () => {
          await historicoPedidoService.adicionarStatus(
            pedidoId,
            statusHistorico,
            observacaoHistorico
          )
        },
        RETRY_PRESETS.NORMAL
      )

      // Atualizar estado local
      // Se o status é "Finalizado", remover da lista (irá para histórico)
      // Caso contrário, atualizar o status
      if (statusFinal === 'Finalizado') {
        setPedidos(prevPedidos =>
          prevPedidos.filter(pedido => pedido.pedido_id !== pedidoId)
        )
      } else {
        setPedidos(prevPedidos =>
          prevPedidos.map(pedido =>
            pedido.pedido_id === pedidoId
              ? { ...pedido, status: statusFinal }
              : pedido
          )
        )
      }

      // Feedback visual de sucesso
      if (statusFinal === 'Finalizado') {
        toast.success(`Pedido ${pedidoAtual?.pedido_id} movido para o histórico ✅`)
      } else {
        toast.success(`Status atualizado para: ${statusFinal}`)
      }
      console.log('✅ Atualização de status concluída com sucesso')
      
    } catch (error) {
      console.error('❌ Erro ao atualizar status:', error)
      
      // Feedback visual de erro
      toast.error('Erro ao atualizar status do pedido')
      
      reportError({
        type: ErrorType.DATABASE,
        severity: ErrorSeverity.ERROR,
        message: 'Não foi possível atualizar o status do pedido',
        technicalMessage: `Falha ao atualizar status do pedido ${pedidoId} para ${novoStatus}: ${error instanceof Error ? error.message : 'Erro desconhecido'}`,
        originalError: error,
        retryable: true,
        action: 'Verifique sua conexão e tente novamente'
      })

      // Recarregar pedidos para sincronizar estado
      await carregarPedidos()
    }
  }, [pedidos, carregarPedidos, reportError])

  /**
   * Limpa a lista de pedidos
   */
  const limparPedidos = useCallback(() => {
    setPedidos([])
    pedidosAnteriores.current = []
  }, [])

  return {
    pedidos,
    loading,
    novoPedidoRecebido,
    carregarPedidos,
    atualizarStatus,
    limparPedidos
  }
}

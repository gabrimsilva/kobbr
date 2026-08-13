/**
 * Hook para arquivar automaticamente pedidos finalizados à meia-noite
 * 
 * Este hook roda uma verificação à 00:00:00 de cada dia para mover
 * pedidos com status "Finalizado" para o histórico geral.
 * 
 * Pedidos com status "Entregue" permanecem no kanban.
 */

import { useEffect, useRef } from 'react'
import { pedidoService } from '@/services'

export interface UseAutoArquivarPedidosOptions {
  /** Habilitar/desabilitar o arquivamento automático */
  enabled?: boolean
  /** Callback chamado após o arquivamento */
  onArquivamento?: (quantidade: number) => void
}

/**
 * Hook para arquivar automaticamente pedidos finalizados à meia-noite
 * 
 * @param options - Opções de configuração
 * 
 * @example
 * ```tsx
 * useAutoArquivarPedidos({
 *   enabled: true,
 *   onArquivamento: (qtd) => toast.success(`${qtd} pedidos arquivados`)
 * })
 * ```
 */
export function useAutoArquivarPedidos(options: UseAutoArquivarPedidosOptions = {}) {
  const { enabled = true, onArquivamento } = options
  const intervalRef = useRef<NodeJS.Timeout | null>(null)
  const ultimaExecucaoRef = useRef<string | null>(null)

  useEffect(() => {
    if (!enabled) {
      if (intervalRef.current) {
        clearInterval(intervalRef.current)
        intervalRef.current = null
      }
      return
    }

    /**
     * Verifica se deve executar o arquivamento
     * Executa apenas uma vez por dia, à meia-noite
     */
    const verificarEArquivar = async () => {
      const agora = new Date()
      const hora = agora.getHours()
      const minuto = agora.getMinutes()
      const dataHoje = agora.toISOString().split('T')[0] // YYYY-MM-DD

      // Executar apenas à meia-noite (00:00 até 00:05)
      if (hora === 0 && minuto < 5) {
        // Verificar se já executou hoje
        if (ultimaExecucaoRef.current === dataHoje) {
          return
        }

        try {
          console.log('🕛 Executando arquivamento automático de pedidos finalizados...')
          const quantidade = await pedidoService.moverFinalizadosParaHistorico()
          
          if (quantidade > 0) {
            console.log(`✅ ${quantidade} pedido(s) arquivado(s) automaticamente`)
            onArquivamento?.(quantidade)
          }

          ultimaExecucaoRef.current = dataHoje
        } catch (error) {
          console.error('❌ Erro no arquivamento automático:', error)
        }
      }
    }

    // Executar verificação a cada minuto
    intervalRef.current = setInterval(verificarEArquivar, 60000)

    // Executar imediatamente ao montar (caso seja meia-noite)
    verificarEArquivar()

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current)
        intervalRef.current = null
      }
    }
  }, [enabled, onArquivamento])
}

import { useState, useEffect, useRef, useCallback } from 'react'
import { supabase } from "@/services"
import { RECONNECT_DELAYS, DEBOUNCE_DELAYS, SYNC_INTERVALS } from '@/constants/timers'

/**
 * Status da conexão realtime
 */
export type RealtimeStatus = 'connected' | 'disconnected' | 'connecting' | 'error'

/**
 * Opções de configuração do hook useRealtimePedidos
 */
export interface UseRealtimePedidosOptions {
  /**
   * Habilitar auto-refresh quando offline
   * @default true
   */
  autoRefresh?: boolean
  
  /**
   * Intervalo de refresh quando online (em ms)
   * @default RECONNECT_DELAYS.REALTIME (1 minuto)
   */
  onlineRefreshInterval?: number

  /**
   * Intervalo de refresh quando offline (em ms)
   * @default SYNC_INTERVALS.PEDIDOS (10 segundos)
   */
  offlineRefreshInterval?: number

  /**
   * Tempo de debounce para mudanças (em ms)
   * @default DEBOUNCE_DELAYS.SEARCH (500ms)
   */
  debounceTime?: number

  /**
   * Tempo para tentar reconectar após erro (em ms)
   * @default RECONNECT_DELAYS.RETRY (5 segundos)
   */
  reconnectDelay?: number
}

/**
 * Retorno do hook useRealtimePedidos
 */
export interface UseRealtimePedidosReturn {
  /**
   * Status da conexão realtime
   */
  status: RealtimeStatus
  
  /**
   * Indica se está conectado ao realtime
   */
  isConnected: boolean
  
  /**
   * Data/hora da última atualização
   */
  lastUpdate: Date
  
  /**
   * Função para reconectar manualmente
   */
  reconnect: () => void
  
  /**
   * Função para desconectar
   */
  disconnect: () => void
}

/**
 * Hook customizado para gerenciar conexão realtime com pedidos
 * 
 * Gerencia a subscrição ao canal de pedidos do Supabase, incluindo:
 * - Conexão e reconexão automática
 * - Auto-refresh quando offline
 * - Debounce de mudanças
 * - Tratamento de erros
 * 
 * @param onPedidoChange - Callback chamado quando há mudanças nos pedidos
 * @param options - Opções de configuração
 * 
 * @example
 * ```tsx
 * const { isConnected, reconnect } = useRealtimePedidos(
 *   () => carregarPedidos(),
 *   { autoRefresh: true }
 * )
 * ```
 */
export function useRealtimePedidos(
  onPedidoChange: () => void | Promise<void>,
  options: UseRealtimePedidosOptions = {}
): UseRealtimePedidosReturn {
  const {
    autoRefresh = true,
    onlineRefreshInterval = RECONNECT_DELAYS.REALTIME,
    offlineRefreshInterval = SYNC_INTERVALS.PEDIDOS,
    debounceTime = DEBOUNCE_DELAYS.SEARCH,
    reconnectDelay = RECONNECT_DELAYS.RETRY
  } = options

  const [status, setStatus] = useState<RealtimeStatus>('disconnected')
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date())

  const channelRef = useRef<any>(null)
  const debounceTimeoutRef = useRef<NodeJS.Timeout | null>(null)
  const autoRefreshIntervalRef = useRef<NodeJS.Timeout | null>(null)
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null)
  const onPedidoChangeRef = useRef(onPedidoChange)

  // Flags para prevenir race conditions
  const isSubscribedRef = useRef(false)
  const isSubscribingRef = useRef(false)
  const isCleaningUpRef = useRef(false)

  // Atualizar a referência do callback sem causar re-render
  useEffect(() => {
    onPedidoChangeRef.current = onPedidoChange
  }, [onPedidoChange])

  /**
   * Limpa todos os timers e referências
   */
  const clearTimers = useCallback(() => {
    if (debounceTimeoutRef.current) {
      clearTimeout(debounceTimeoutRef.current)
      debounceTimeoutRef.current = null
    }
    
    if (autoRefreshIntervalRef.current) {
      clearInterval(autoRefreshIntervalRef.current)
      autoRefreshIntervalRef.current = null
    }
    
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current)
      reconnectTimeoutRef.current = null
    }
  }, [])

  /**
   * Configura o canal realtime do Supabase
   */
  const setupRealtimeChannel = useCallback(() => {
    // Prevenir múltiplas chamadas simultâneas
    if (isSubscribingRef.current || isCleaningUpRef.current) {
      return
    }

    isSubscribingRef.current = true
    isSubscribedRef.current = false

    try {
      // Limpar canal anterior se existir
      if (channelRef.current) {
        try {
          supabase.removeChannel(channelRef.current)
        } catch (error) {
          console.error('⚠️ Erro ao remover canal anterior:', error)
        }
        channelRef.current = null
      }

      setStatus('connecting')

      const channel = supabase
        .channel(`pedidos-realtime-${Date.now()}`)
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'pedidos'
          },
          () => {
            // Verificar se ainda estamos subscritos antes de processar
            if (!isSubscribedRef.current) {
              return
            }

            setLastUpdate(new Date())

            // Debounce para evitar múltiplas chamadas
            if (debounceTimeoutRef.current) {
              clearTimeout(debounceTimeoutRef.current)
            }

            debounceTimeoutRef.current = setTimeout(() => {
              // Verificar novamente antes de executar callback
              if (isSubscribedRef.current) {
                onPedidoChangeRef.current()
              }
            }, debounceTime)
          }
        )
        .subscribe((subscriptionStatus, err) => {
          if (err) {
            console.error('❌ Erro na subscrição realtime:', err)
            setStatus('error')
            isSubscribedRef.current = false
            isSubscribingRef.current = false
            return
          }

          // Atualizar status baseado na subscrição
          if (subscriptionStatus === 'SUBSCRIBED') {
            setStatus('connected')
            isSubscribedRef.current = true
            isSubscribingRef.current = false
          } else if (subscriptionStatus === 'CHANNEL_ERROR') {
            setStatus('error')
            isSubscribedRef.current = false
            isSubscribingRef.current = false

            // Tentar reconectar após delay
            if (reconnectTimeoutRef.current) {
              clearTimeout(reconnectTimeoutRef.current)
            }
            reconnectTimeoutRef.current = setTimeout(() => {
              if (!isCleaningUpRef.current) {
                setupRealtimeChannel()
              }
            }, reconnectDelay)
          } else if (subscriptionStatus === 'TIMED_OUT') {
            setStatus('error')
            isSubscribedRef.current = false
            isSubscribingRef.current = false

            // Tentar reconectar após delay menor
            if (reconnectTimeoutRef.current) {
              clearTimeout(reconnectTimeoutRef.current)
            }
            reconnectTimeoutRef.current = setTimeout(() => {
              if (!isCleaningUpRef.current) {
                setupRealtimeChannel()
              }
            }, 3000)
          } else if (subscriptionStatus === 'CLOSED') {
            setStatus('disconnected')
            isSubscribedRef.current = false
            isSubscribingRef.current = false
          }
        })

      channelRef.current = channel
    } catch (error) {
      console.error('❌ Erro ao configurar canal realtime:', error)
      setStatus('error')
      isSubscribedRef.current = false
      isSubscribingRef.current = false
    }
  }, [debounceTime, reconnectDelay])

  /**
   * Desconecta do canal realtime
   */
  const disconnect = useCallback(() => {
    // Prevenir múltiplas chamadas simultâneas
    if (isCleaningUpRef.current) {
      return
    }

    isCleaningUpRef.current = true

    try {
      // Limpar todos os timers
      clearTimers()

      // Marcar como não subscrito antes de remover canal
      isSubscribedRef.current = false
      isSubscribingRef.current = false

      // Remover canal apenas se existir e se estiver subscrito
      if (channelRef.current) {
        try {
          supabase.removeChannel(channelRef.current)
        } catch (error) {
          console.error('⚠️ Erro ao remover canal:', error)
        } finally {
          channelRef.current = null
        }
      }

      setStatus('disconnected')
    } catch (error) {
      console.error('❌ Erro ao desconectar:', error)
    } finally {
      isCleaningUpRef.current = false
    }
  }, [clearTimers])

  /**
   * Reconecta ao canal realtime
   */
  const reconnect = useCallback(() => {
    // Desconectar primeiro
    disconnect()

    // Aguardar um pouco antes de reconectar para evitar race condition
    setTimeout(() => {
      // Verificar se não estamos fazendo cleanup antes de reconectar
      if (!isCleaningUpRef.current) {
        setupRealtimeChannel()
      }
    }, 1000)
  }, [disconnect, setupRealtimeChannel])

  /**
   * Configura auto-refresh baseado no status da conexão
   */
  useEffect(() => {
    if (!autoRefresh) return

    // Limpar intervalo anterior
    if (autoRefreshIntervalRef.current) {
      clearInterval(autoRefreshIntervalRef.current)
    }

    // Definir intervalo baseado no status
    const interval = status === 'connected' 
      ? onlineRefreshInterval 
      : offlineRefreshInterval

    autoRefreshIntervalRef.current = setInterval(() => {
      // Só fazer refresh automático quando offline
      if (status !== 'connected') {
        onPedidoChangeRef.current()
      }
    }, interval)

    return () => {
      if (autoRefreshIntervalRef.current) {
        clearInterval(autoRefreshIntervalRef.current)
      }
    }
  }, [autoRefresh, status, onlineRefreshInterval, offlineRefreshInterval])

  /**
   * Inicializa a conexão realtime
   */
  useEffect(() => {
    setupRealtimeChannel()

    return () => {
      disconnect()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []) // Executar apenas na montagem/desmontagem

  return {
    status,
    isConnected: status === 'connected',
    lastUpdate,
    reconnect,
    disconnect
  }
}

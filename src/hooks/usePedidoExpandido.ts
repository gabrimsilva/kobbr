import { useState, useEffect } from 'react'

/**
 * Hook para gerenciar o estado de expansão de cards de pedidos
 * Persiste o estado no localStorage
 */
export function usePedidoExpandido(pedidoId: string, defaultExpanded = true) {
  // Recupera o estado salvo
  const getExpandedState = () => {
    try {
      const saved = localStorage.getItem(`pedido-expanded-${pedidoId}`)
      return saved !== null ? JSON.parse(saved) : defaultExpanded
    } catch {
      return defaultExpanded
    }
  }

  const [isExpanded, setIsExpanded] = useState(getExpandedState)

  // Salva o estado quando muda
  useEffect(() => {
    try {
      localStorage.setItem(`pedido-expanded-${pedidoId}`, JSON.stringify(isExpanded))
    } catch (error) {
      console.error('Erro ao salvar estado de expansão:', error)
    }
  }, [isExpanded, pedidoId])

  // Limpa estados antigos (executa apenas uma vez no mount)
  useEffect(() => {
    const cleanupOldStates = () => {
      try {
        const keys = Object.keys(localStorage)
        const pedidoKeys = keys.filter(key => key.startsWith('pedido-expanded-'))
        
        // Se houver mais de 100 pedidos salvos, limpa os mais antigos
        if (pedidoKeys.length > 100) {
          pedidoKeys.slice(0, 50).forEach(key => {
            localStorage.removeItem(key)
          })
        }
      } catch (error) {
        console.error('Erro ao limpar estados antigos:', error)
      }
    }

    cleanupOldStates()
  }, [])

  const toggle = () => setIsExpanded((prev: boolean) => !prev)

  return {
    isExpanded,
    setIsExpanded,
    toggle
  }
}

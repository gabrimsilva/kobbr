import { useEffect, useRef } from 'react'
import { supabase } from "@/services"
import { impressaoAutomaticaService } from '@/lib/impressaoAutomatica'

/**
 * Hook global para gerenciar impressão automática de pedidos
 * 
 * Este hook deve ser usado no componente raiz da aplicação (App.tsx)
 * para garantir que a impressão automática funcione em qualquer página
 */
export function useImpressaoAutomaticaGlobal() {
  const channelRef = useRef<any>(null)
  const pedidosProcessadosRef = useRef<Set<string>>(new Set())

  useEffect(() => {
    // Criar canal realtime para monitorar novos pedidos e atualizações
    const channel = supabase
      .channel(`impressao-automatica-${Date.now()}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'pedidos'
        },
        async (payload) => {
          const pedido = payload.new as any
          const pedidoId = pedido.pedido_id || pedido.id

          // Evitar processar o mesmo pedido múltiplas vezes
          if (pedidosProcessadosRef.current.has(pedidoId)) {
            return
          }

          // Marcar como processado
          pedidosProcessadosRef.current.add(pedidoId)

          // Limpar pedidos antigos do cache (manter apenas os últimos 50)
          if (pedidosProcessadosRef.current.size > 50) {
            const pedidosArray = Array.from(pedidosProcessadosRef.current)
            pedidosProcessadosRef.current = new Set(pedidosArray.slice(-50))
          }

          // NÃO imprimir pedidos aguardando pagamento (PIX)
          if (pedido.status === 'Aguardando pagamento') {
            return
          }

          // Tentar imprimir
          try {
            const pedidoParaImprimir = {
              ...pedido,
              criado_em: pedido.criado_em || new Date().toISOString()
            }
            
            await impressaoAutomaticaService.imprimirPedido(pedidoParaImprimir)
          } catch (error) {
            console.error('❌ Erro na impressão automática global:', error)
          }
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'pedidos'
        },
        async (payload) => {
          const pedidoAntigo = payload.old as any
          const pedidoNovo = payload.new as any
          const pedidoId = pedidoNovo.pedido_id || pedidoNovo.id

          // Já processado? Ignorar
          if (pedidosProcessadosRef.current.has(pedidoId)) {
            return
          }

          // Verificar se é um pedido PIX que foi aprovado
          // Condição 1: Status antigo era "Aguardando pagamento" e novo é "Pedido criado"
          // Condição 2 (fallback): mercado_pago_status mudou para "approved" e status é "Pedido criado"
          const statusAntigoAguardando = pedidoAntigo?.status === 'Aguardando pagamento'
          const statusNovoAprovado = pedidoNovo.status === 'Pedido criado'
          const pixAprovado = pedidoNovo.mercado_pago_status === 'approved'
          const formaPagamentoPix = pedidoNovo.forma_pagamento === 'pix'

          const deveImprimir = (
            // Condição principal: mudança de status
            (statusAntigoAguardando && statusNovoAprovado) ||
            // Fallback: PIX aprovado e status correto (caso OLD não esteja disponível)
            (formaPagamentoPix && pixAprovado && statusNovoAprovado && !pedidoAntigo?.status)
          )

          if (deveImprimir) {
            // Marcar como processado
            pedidosProcessadosRef.current.add(pedidoId)

            // Limpar pedidos antigos do cache
            if (pedidosProcessadosRef.current.size > 50) {
              const pedidosArray = Array.from(pedidosProcessadosRef.current)
              pedidosProcessadosRef.current = new Set(pedidosArray.slice(-50))
            }

            // Tentar imprimir
            try {
              const pedidoParaImprimir = {
                ...pedidoNovo,
                criado_em: pedidoNovo.criado_em || new Date().toISOString()
              }
              
              await impressaoAutomaticaService.imprimirPedido(pedidoParaImprimir)
            } catch (error) {
              console.error('❌ Erro na impressão automática após aprovação PIX:', error)
            }
          }
        }
      )
      .subscribe()

    channelRef.current = channel

    // Cleanup ao desmontar
    return () => {
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current)
        channelRef.current = null
      }
    }
  }, [])

  return null
}

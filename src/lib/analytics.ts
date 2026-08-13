/**
 * Funções auxiliares para rastreamento de eventos no Google Analytics 4
 * 
 * Este arquivo exporta funções simplificadas que usam o googleAnalytics service
 */

import { googleAnalytics } from '@/services/googleAnalyticsService'

/**
 * Rastreia visualização de página
 */
export function trackPageView(title: string, path: string) {
  googleAnalytics.trackPageView(path, title)
}

/**
 * Rastreia visualização de produto
 */
export function trackViewItem(item: {
  id: string
  nome: string
  categoria?: string
  preco: number
}) {
  googleAnalytics.trackViewItem({
    id: item.id,
    name: item.nome,
    category: item.categoria,
    price: item.preco
  })
}

/**
 * Rastreia adição ao carrinho
 */
export function trackAddToCart(item: {
  id: string
  nome: string
  preco: number
  quantidade: number
}) {
  googleAnalytics.trackAddToCart({
    id: item.id,
    name: item.nome,
    price: item.preco,
    quantity: item.quantidade
  })
}

/**
 * Rastreia compra finalizada
 */
export function trackPurchase(
  pedidoId: string,
  items: Array<{ id: string; nome: string; preco: number; quantidade: number }>,
  total: number,
  taxaEntrega: number = 0
) {
  googleAnalytics.trackPurchase(
    pedidoId,
    items.map(item => ({
      id: item.id,
      name: item.nome,
      price: item.preco,
      quantity: item.quantidade
    })),
    total,
    taxaEntrega
  )
}

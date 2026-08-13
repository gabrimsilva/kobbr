/**
 * Serviço para buscar dados do Google Analytics 4
 * 
 * Este serviço busca dados diretamente do Google Analytics via API.
 */

import { supabase } from '@/lib/supabase'

interface GAMetrics {
  users: number
  sessions: number
  pageViews: number
  addToCarts: number
  checkouts: number
  purchases: number
  revenue: number
  averageOrderValue: number
  conversionRate: number
  cartAbandonmentRate: number
}

interface GAProductView {
  productId: string
  productName: string
  category: string
  views: number
}

interface GAEvent {
  eventName: string
  eventCount: number
}

class GoogleAnalyticsDataService {
  /**
   * Verifica se o gtag está disponível e funcionando
   */
  isConnected(): boolean {
    return typeof window !== 'undefined' && typeof window.gtag === 'function'
  }

  /**
   * Busca métricas do Google Analytics via Edge Function
   */
  async getMetrics(dateRange: 'today' | 'week' | 'month' | 'all' = 'week'): Promise<GAMetrics> {
    try {
      const { data: { session } } = await supabase.auth.getSession()
      
      if (!session) {
        throw new Error('Não autenticado')
      }

      const response = await supabase.functions.invoke('get-analytics-data', {
        body: { dateRange }
      })

      if (response.error) {
        throw response.error
      }

      const data = response.data

      // Calcular métricas derivadas
      const averageOrderValue = data.purchases > 0 ? data.revenue / data.purchases : 0
      const conversionRate = data.pageViews > 0 ? (data.purchases / data.pageViews) * 100 : 0
      const cartAbandonmentRate = data.addToCarts > 0 
        ? ((data.addToCarts - data.purchases) / data.addToCarts) * 100 
        : 0

      return {
        users: data.users || 0,
        sessions: data.sessions || 0,
        pageViews: data.pageViews || 0,
        addToCarts: data.addToCarts || 0,
        checkouts: data.checkouts || 0,
        purchases: data.purchases || 0,
        revenue: data.revenue || 0,
        averageOrderValue,
        conversionRate,
        cartAbandonmentRate
      }
    } catch (error) {
      console.error('Erro ao buscar métricas:', error)
      
      // Retornar dados vazios em caso de erro
      return {
        users: 0,
        sessions: 0,
        pageViews: 0,
        addToCarts: 0,
        checkouts: 0,
        purchases: 0,
        revenue: 0,
        averageOrderValue: 0,
        conversionRate: 0,
        cartAbandonmentRate: 0
      }
    }
  }

  /**
   * Busca produtos mais vistos
   */
  async getTopProducts(limit: number = 10): Promise<GAProductView[]> {
    try {
      const { data: { session } } = await supabase.auth.getSession()
      
      if (!session) {
        throw new Error('Não autenticado')
      }

      const response = await supabase.functions.invoke('get-analytics-products', {
        body: { limit }
      })

      if (response.error) {
        throw response.error
      }

      return response.data || []
    } catch (error) {
      console.error('Erro ao buscar produtos:', error)
      return []
    }
  }

  /**
   * Busca eventos recentes
   * @param _limit - Limite de eventos (parâmetro reservado para uso futuro)
   */
  async getRecentEvents(_limit: number = 50): Promise<GAEvent[]> {
    try {
      const { data: { session } } = await supabase.auth.getSession()
      
      if (!session) {
        throw new Error('Não autenticado')
      }

      const response = await supabase.functions.invoke('get-analytics-data', {
        body: { dateRange: 'today' }
      })

      if (response.error) {
        throw response.error
      }

      return response.data?.events || []
    } catch (error) {
      console.error('Erro ao buscar eventos:', error)
      return []
    }
  }

  /**
   * Retorna a URL do Google Analytics para visualizar os dados reais
   */
  getAnalyticsUrl(): string {
    return 'https://analytics.google.com/'
  }
}

export const googleAnalyticsDataService = new GoogleAnalyticsDataService()

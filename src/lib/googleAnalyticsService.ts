/**
 * Serviço para buscar dados do Google Analytics 4 via Edge Function
 * 
 * Este serviço busca dados diretamente da Google Analytics Data API
 * através de uma Edge Function no Supabase que usa Service Account.
 */

import { supabase } from './supabase'

export interface GA4Data {
  overview: {
    activeUsers: number
    newUsers: number
    sessions: number
    screenPageViews: number
    averageSessionDuration: number
    bounceRate: number
    conversions: number
    itemsViewed: number
    itemsAddedToCart: number
    itemsPurchased: number
    itemRevenue: number
    purchaseRevenue: number
  }
  devices: Array<{
    device: string
    users: number
    percentage: number
  }>
  products: Array<{
    name: string
    views: number
    addToCart: number
    purchases: number
    revenue: number
  }>
  pages: Array<{
    page: string
    views: number
    avgTime: string
    bounceRate: string
  }>
  locations: Array<{
    city: string
    state: string
    users: number
    sessions: number
  }>
}

/**
 * Busca dados do Google Analytics 4
 * @param periodo - Período dos dados: 'hoje', '7dias' ou '30dias'
 */
export async function buscarDadosGA4(
  periodo: 'hoje' | '7dias' | '30dias' = '7dias'
): Promise<GA4Data> {
  try {
    const { data, error } = await supabase.functions.invoke('google-analytics', {
      body: { periodo }
    })

    if (error) {
      console.error('Erro ao buscar dados do GA4:', error)
      throw new Error(error.message || 'Erro ao buscar dados do Google Analytics')
    }

    if (!data) {
      throw new Error('Nenhum dado retornado do Google Analytics')
    }

    // A função retorna { success: true, data: {...} }
    if (data.success && data.data) {
      // Processar dados da resposta
      const responseData = data.data
      
      const overview = responseData.overview.rows?.[0]
      const totalUsers = responseData.devices.rows?.reduce((sum: number, row: any) => 
        sum + parseInt(row.metricValues[0].value), 0) || 1

      return {
        overview: {
          activeUsers: parseInt(overview?.metricValues[0]?.value || '0'),
          newUsers: parseInt(overview?.metricValues[6]?.value || '0'),
          sessions: parseInt(overview?.metricValues[2]?.value || '0'),
          screenPageViews: parseInt(overview?.metricValues[1]?.value || '0'),
          averageSessionDuration: parseFloat(overview?.metricValues[3]?.value || '0'),
          bounceRate: parseFloat(overview?.metricValues[4]?.value || '0'),
          conversions: parseInt(overview?.metricValues[5]?.value || '0'),
          itemsViewed: 0,
          itemsAddedToCart: 0,
          itemsPurchased: 0,
          itemRevenue: 0,
          purchaseRevenue: 0,
        },
        devices: (responseData.devices.rows || []).map((row: any) => {
          const users = parseInt(row.metricValues[0].value)
          return {
            device: row.dimensionValues[0].value,
            users,
            percentage: Math.round((users / totalUsers) * 100)
          }
        }),
        products: (responseData.products.rows || []).map((row: any) => ({
          name: row.dimensionValues[0].value,
          views: parseInt(row.metricValues[0].value || '0'),
          addToCart: parseInt(row.metricValues[1].value || '0'),
          purchases: parseInt(row.metricValues[2].value || '0'),
          revenue: parseFloat(row.metricValues[3].value || '0')
        })),
        pages: (responseData.pages.rows || []).map((row: any) => ({
          page: row.dimensionValues[0].value,
          views: parseInt(row.metricValues[0].value || '0'),
          avgTime: formatTime(parseFloat(row.metricValues[1].value || '0')),
          bounceRate: `${(parseFloat(row.metricValues[2].value || '0') * 100).toFixed(1)}%`
        })),
        locations: (responseData.locations.rows || []).map((row: any) => ({
          city: row.dimensionValues[0].value,
          state: row.dimensionValues[1].value,
          users: parseInt(row.metricValues[0].value || '0'),
          sessions: parseInt(row.metricValues[1].value || '0')
        }))
      }
    }

    return data
  } catch (error) {
    console.error('Erro ao buscar dados do GA4:', error)
    throw error
  }
}

// Função auxiliar para formatar tempo
function formatTime(seconds: number): string {
  const minutes = Math.floor(seconds / 60)
  const secs = Math.floor(seconds % 60)
  return `${minutes}m ${secs}s`
}

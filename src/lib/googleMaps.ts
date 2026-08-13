/**
 * Utilitários para integração com Google Maps API
 */

import { configuracaoService } from '@/services'

let cachedApiKey: string | null = null
let loadingPromise: Promise<void> | null = null

/**
 * Busca a API Key do Google Maps do banco de dados
 */
async function getGoogleMapsApiKey(): Promise<string> {
  // Usar cache se disponível
  if (cachedApiKey) {
    return cachedApiKey
  }

  try {
    const configs = await configuracaoService.buscarTodas()
    const apiKeyConfig = configs.find(c => c.chave === 'google_maps_api_key')
    
    if (!apiKeyConfig || !apiKeyConfig.valor) {
      throw new Error('API Key do Google Maps não configurada. Configure em Configurações > Informações Gerais.')
    }

    cachedApiKey = apiKeyConfig.valor
    return cachedApiKey
  } catch (error) {
    console.error('Erro ao buscar API Key do Google Maps:', error)
    throw error
  }
}

/**
 * Carrega o script do Google Maps API
 */
export async function loadGoogleMapsScript(): Promise<void> {
  // Se já está carregado, retornar imediatamente
  if (window.google && window.google.maps) {
    return Promise.resolve()
  }

  // Se já está carregando, retornar a promise existente
  if (loadingPromise) {
    return loadingPromise
  }

  // Criar nova promise de carregamento
  loadingPromise = new Promise(async (resolve, reject) => {
    try {
      // Verificar novamente se já está carregado (race condition)
      if (window.google && window.google.maps) {
        resolve()
        return
      }

      // Verificar se o script já existe no DOM
      const existingScript = document.querySelector('script[src*="maps.googleapis.com"]')
      if (existingScript) {
        // Script já existe, aguardar carregamento
        if (window.google && window.google.maps) {
          resolve()
        } else {
          existingScript.addEventListener('load', () => resolve())
          existingScript.addEventListener('error', reject)
        }
        return
      }

      // Buscar API Key do banco
      const apiKey = await getGoogleMapsApiKey()

      // Criar e adicionar o script (incluindo biblioteca marker para AdvancedMarkerElement)
      const script = document.createElement('script')
      script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&libraries=places,geometry,marker`
      script.async = true
      script.defer = true
      script.addEventListener('load', () => {
        resolve()
      })
      script.addEventListener('error', (error) => {
        loadingPromise = null // Reset para permitir retry
        reject(error)
      })
      document.head.appendChild(script)
    } catch (error) {
      loadingPromise = null // Reset para permitir retry
      reject(error)
    }
  })

  return loadingPromise
}

/**
 * Geocodifica um endereço para obter coordenadas
 */
export async function geocodeAddress(address: string): Promise<{ lat: number; lng: number } | null> {
  try {
    await loadGoogleMapsScript()

    const geocoder = new google.maps.Geocoder()
    const result = await geocoder.geocode({ address })

    if (result.results && result.results.length > 0) {
      const location = result.results[0].geometry.location
      return {
        lat: location.lat(),
        lng: location.lng()
      }
    }

    return null
  } catch (error) {
    console.error('Erro ao geocodificar endereço:', error)
    return null
  }
}

/**
 * Calcula a distância entre dois pontos em metros
 */
export function calculateDistance(
  point1: { lat: number; lng: number },
  point2: { lat: number; lng: number }
): number {
  const lat1 = google.maps.geometry.spherical.computeDistanceBetween(
    new google.maps.LatLng(point1.lat, point1.lng),
    new google.maps.LatLng(point2.lat, point2.lng)
  )
  return lat1
}

/**
 * Verifica se um endereço está dentro do raio de entrega
 */
export async function isAddressInDeliveryArea(
  customerAddress: string,
  storeLocation: { lat: number; lng: number },
  radiusInMeters: number
): Promise<{ inArea: boolean; distance: number | null }> {
  try {
    const customerLocation = await geocodeAddress(customerAddress)

    if (!customerLocation) {
      return { inArea: false, distance: null }
    }

    const distance = calculateDistance(storeLocation, customerLocation)
    const inArea = distance <= radiusInMeters

    return { inArea, distance }
  } catch (error) {
    console.error('Erro ao verificar área de entrega:', error)
    return { inArea: false, distance: null }
  }
}

// Tipos do Google Maps para TypeScript
declare global {
  interface Window {
    google: any
  }

  const google: any
}

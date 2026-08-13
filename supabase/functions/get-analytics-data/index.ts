import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { create } from "https://deno.land/x/djwt@v3.0.1/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/**
 * Cria um JWT para autenticação com Google APIs
 */
async function createJWT(serviceAccountEmail: string, privateKey: string) {
  const now = Math.floor(Date.now() / 1000)
  
  const payload = {
    iss: serviceAccountEmail,
    scope: 'https://www.googleapis.com/auth/analytics.readonly',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }

  // Importar chave privada
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(privateKey),
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign']
  )

  return await create({ alg: 'RS256', typ: 'JWT' }, payload, key)
}

/**
 * Converte PEM para ArrayBuffer
 */
function pemToArrayBuffer(pem: string): ArrayBuffer {
  // Limpar a chave PEM
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\\n/g, '') // Remover \n escapados
    .replace(/\n/g, '')  // Remover quebras de linha reais
    .replace(/\r/g, '')  // Remover carriage returns
    .replace(/\s/g, '')  // Remover todos os espaços
    .trim()

  try {
    const binary = atob(b64)
    const bytes = new Uint8Array(binary.length)
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i)
    }
    return bytes.buffer
  } catch (error) {
    console.error('Erro ao decodificar chave privada:', error)
    console.error('Tamanho da chave após limpeza:', b64.length)
    console.error('Primeiros 50 caracteres:', b64.substring(0, 50))
    throw new Error('Chave privada inválida. Verifique se copiou corretamente do arquivo JSON.')
  }
}

/**
 * Obtém access token do Google OAuth
 */
async function getAccessToken(serviceAccountEmail: string, privateKey: string) {
  const jwt = await createJWT(serviceAccountEmail, privateKey)

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Erro ao obter access token: ${error}`)
  }

  const data = await response.json()
  return data.access_token
}

/**
 * Faz requisição para Google Analytics Data API
 */
async function runReport(accessToken: string, propertyId: string, requestBody: any) {
  const url = `https://analyticsdata.googleapis.com/v1beta/properties/${propertyId}:runReport`

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(requestBody),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Erro na API do GA4: ${error}`)
  }

  return await response.json()
}

/**
 * Formata tempo em segundos para string legível
 */
function formatTime(seconds: number): string {
  const minutes = Math.floor(seconds / 60)
  const secs = Math.floor(seconds % 60)
  return `${minutes}m ${secs}s`
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { periodo = '7dias' } = await req.json()

    // Verificar se as variáveis de ambiente estão configuradas
    const propertyId = Deno.env.get('GA4_PROPERTY_ID')
    const serviceAccountEmail = Deno.env.get('GA4_SERVICE_ACCOUNT_EMAIL')
    const privateKey = Deno.env.get('GA4_PRIVATE_KEY')

    if (!propertyId) {
      throw new Error('GA4_PROPERTY_ID não configurado. Execute: supabase secrets set GA4_PROPERTY_ID=seu_id')
    }

    if (!serviceAccountEmail) {
      throw new Error('GA4_SERVICE_ACCOUNT_EMAIL não configurado. Execute: supabase secrets set GA4_SERVICE_ACCOUNT_EMAIL=seu_email')
    }

    if (!privateKey) {
      throw new Error('GA4_PRIVATE_KEY não configurado. Execute: supabase secrets set GA4_PRIVATE_KEY="sua_chave"')
    }

    console.log('✅ Secrets configurados')
    console.log('Property ID:', propertyId)
    console.log('Service Account:', serviceAccountEmail)
    console.log('Tamanho da chave privada:', privateKey.length)

    // Obter access token
    console.log('🔑 Obtendo access token...')
    const accessToken = await getAccessToken(serviceAccountEmail, privateKey)
    console.log('✅ Access token obtido')

    // Calcular período
    let startDate = '7daysAgo'
    if (periodo === 'hoje') {
      startDate = 'today'
    } else if (periodo === '30dias') {
      startDate = '30daysAgo'
    }

    console.log('📊 Buscando dados do GA4...')

    // 1. Buscar métricas gerais
    const overviewResponse = await runReport(accessToken, propertyId, {
      dateRanges: [{ startDate, endDate: 'today' }],
      metrics: [
        { name: 'activeUsers' },
        { name: 'newUsers' },
        { name: 'sessions' },
        { name: 'screenPageViews' },
        { name: 'averageSessionDuration' },
        { name: 'bounceRate' },
        { name: 'conversions' },
      ],
    })

    // 2. Buscar dados por dispositivo
    const deviceResponse = await runReport(accessToken, propertyId, {
      dateRanges: [{ startDate, endDate: 'today' }],
      dimensions: [{ name: 'deviceCategory' }],
      metrics: [{ name: 'activeUsers' }],
    })

    // 3. Buscar produtos mais visualizados
    const productsResponse = await runReport(accessToken, propertyId, {
      dateRanges: [{ startDate, endDate: 'today' }],
      dimensions: [{ name: 'itemName' }],
      metrics: [
        { name: 'itemsViewed' },
        { name: 'itemsAddedToCart' },
        { name: 'itemsPurchased' },
        { name: 'itemRevenue' },
      ],
      orderBys: [{ metric: { metricName: 'itemsViewed' }, desc: true }],
      limit: 20,
    })

    // 4. Buscar páginas mais visitadas
    const pagesResponse = await runReport(accessToken, propertyId, {
      dateRanges: [{ startDate, endDate: 'today' }],
      dimensions: [{ name: 'pagePath' }],
      metrics: [
        { name: 'screenPageViews' },
        { name: 'averageSessionDuration' },
        { name: 'bounceRate' },
      ],
      orderBys: [{ metric: { metricName: 'screenPageViews' }, desc: true }],
      limit: 10,
    })

    // 5. Buscar localização dos usuários
    const locationResponse = await runReport(accessToken, propertyId, {
      dateRanges: [{ startDate, endDate: 'today' }],
      dimensions: [{ name: 'city' }, { name: 'region' }],
      metrics: [{ name: 'activeUsers' }, { name: 'sessions' }],
      orderBys: [{ metric: { metricName: 'activeUsers' }, desc: true }],
      limit: 20,
    })

    console.log('✅ Dados obtidos com sucesso')

    // Processar e formatar dados
    const overview = overviewResponse.rows?.[0]
    const totalUsers = deviceResponse.rows?.reduce((sum: number, row: any) => 
      sum + parseInt(row.metricValues[0].value), 0) || 1

    const processedData = {
      overview: {
        activeUsers: parseInt(overview?.metricValues[0]?.value || '0'),
        newUsers: parseInt(overview?.metricValues[1]?.value || '0'),
        sessions: parseInt(overview?.metricValues[2]?.value || '0'),
        screenPageViews: parseInt(overview?.metricValues[3]?.value || '0'),
        averageSessionDuration: parseFloat(overview?.metricValues[4]?.value || '0'),
        bounceRate: parseFloat(overview?.metricValues[5]?.value || '0'),
        conversions: parseInt(overview?.metricValues[6]?.value || '0'),
        itemsViewed: 0,
        itemsAddedToCart: 0,
        itemsPurchased: 0,
        itemRevenue: 0,
        purchaseRevenue: 0,
      },
      devices: (deviceResponse.rows || []).map((row: any) => {
        const users = parseInt(row.metricValues[0].value)
        return {
          device: row.dimensionValues[0].value,
          users,
          percentage: Math.round((users / totalUsers) * 100)
        }
      }),
      products: (productsResponse.rows || []).map((row: any) => ({
        name: row.dimensionValues[0].value,
        views: parseInt(row.metricValues[0].value || '0'),
        addToCart: parseInt(row.metricValues[1].value || '0'),
        purchases: parseInt(row.metricValues[2].value || '0'),
        revenue: parseFloat(row.metricValues[3].value || '0')
      })),
      pages: (pagesResponse.rows || []).map((row: any) => ({
        page: row.dimensionValues[0].value,
        views: parseInt(row.metricValues[0].value || '0'),
        avgTime: formatTime(parseFloat(row.metricValues[1].value || '0')),
        bounceRate: `${(parseFloat(row.metricValues[2].value || '0') * 100).toFixed(1)}%`
      })),
      locations: (locationResponse.rows || []).map((row: any) => ({
        city: row.dimensionValues[0].value,
        state: row.dimensionValues[1].value,
        users: parseInt(row.metricValues[0].value || '0'),
        sessions: parseInt(row.metricValues[1].value || '0')
      }))
    }

    // Calcular totais de e-commerce
    processedData.overview.itemsViewed = processedData.products.reduce((sum, p) => sum + p.views, 0)
    processedData.overview.itemsAddedToCart = processedData.products.reduce((sum, p) => sum + p.addToCart, 0)
    processedData.overview.itemsPurchased = processedData.products.reduce((sum, p) => sum + p.purchases, 0)
    processedData.overview.itemRevenue = processedData.products.reduce((sum, p) => sum + p.revenue, 0)
    processedData.overview.purchaseRevenue = processedData.overview.itemRevenue

    return new Response(
      JSON.stringify(processedData),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    console.error('❌ Erro ao buscar dados do GA4:', error)

    // Retornar erro detalhado
    let errorMessage = 'Erro desconhecido'
    let errorDetails = ''

    if (error instanceof Error) {
      errorMessage = error.message
      errorDetails = error.stack || ''

      // Mensagens de erro mais amigáveis
      if (errorMessage.includes('not enabled') || errorMessage.includes('API has not been used')) {
        errorMessage = 'Google Analytics Data API não está habilitada. Acesse Google Cloud Console e habilite a API.'
      } else if (errorMessage.includes('permission') || errorMessage.includes('PERMISSION_DENIED')) {
        errorMessage = 'Service Account não tem permissão. Adicione o email no Google Analytics com permissão Viewer.'
      } else if (errorMessage.includes('not found') || errorMessage.includes('NOT_FOUND')) {
        errorMessage = 'Property ID não encontrado. Verifique se o ID está correto.'
      } else if (errorMessage.includes('UNAUTHENTICATED') || errorMessage.includes('invalid_grant')) {
        errorMessage = 'Credenciais inválidas. Verifique se a chave privada está correta e se o email da service account está correto.'
      }
    }

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
        details: errorDetails,
        timestamp: new Date().toISOString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})

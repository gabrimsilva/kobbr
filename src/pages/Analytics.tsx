import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { 
  TrendingUp, 
  Users, 
  Eye, 
  ShoppingCart, 
  MousePointerClick,
  Globe,
  Smartphone,
  Monitor,
  Clock,
  MapPin,
  Activity,
  AlertCircle,
  Download,
  HelpCircle
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { buscarDadosGA4, type GA4Data } from "@/lib/googleAnalyticsService"
import { trackPageView } from "@/lib/analytics"
import * as XLSX from 'xlsx'
import MapaBrasil from "@/components/MapaBrasil"

interface MetricCard {
  title: string
  value: string | number
  change?: string
  changeType?: 'positive' | 'negative' | 'neutral'
  icon: any
  description?: string
}

export default function Analytics() {
  const [loading, setLoading] = useState(true)
  const [periodo, setPeriodo] = useState<'hoje' | '7dias' | '30dias'>('7dias')
  const [dadosReais, setDadosReais] = useState<GA4Data | null>(null)
  const [erroIntegracao, setErroIntegracao] = useState<string | null>(null)

  useEffect(() => {
    trackPageView('Analytics', '/analytics')
    carregarDados()
  }, [periodo])

  const carregarDados = async () => {
    setLoading(true)
    setErroIntegracao(null)

    try {
      const dados = await buscarDadosGA4(periodo)
      setDadosReais(dados)
    } catch (error) {
      console.error('Erro ao carregar dados do GA4:', error)
      setErroIntegracao(error instanceof Error ? error.message : 'Erro desconhecido')
      setDadosReais(null)
    } finally {
      setLoading(false)
    }
  }

  // Usar APENAS dados reais - se não houver, arrays vazios
  const metricsOverview: MetricCard[] = dadosReais ? [
    {
      title: "Visitantes Únicos",
      value: dadosReais.overview.activeUsers.toLocaleString(),
      icon: Users,
      description: "Usuários únicos no período"
    },
    {
      title: "Visualizações de Página",
      value: dadosReais.overview.screenPageViews.toLocaleString(),
      icon: Eye,
      description: "Total de páginas visualizadas"
    },
    {
      title: "Taxa de Conversão",
      value: dadosReais.overview.activeUsers 
        ? `${((dadosReais.overview.conversions / dadosReais.overview.activeUsers) * 100).toFixed(1)}%`
        : "0%",
      icon: TrendingUp,
      description: "Conversões / Visitantes"
    },
    {
      title: "Conversões",
      value: dadosReais.overview.conversions.toLocaleString(),
      icon: ShoppingCart,
      description: "Total de conversões"
    }
  ] : []

  const engagementMetrics: MetricCard[] = dadosReais ? [
    {
      title: "Tempo Médio na Página",
      value: dadosReais.overview.averageSessionDuration 
        ? `${Math.floor(dadosReais.overview.averageSessionDuration / 60)}m ${Math.floor(dadosReais.overview.averageSessionDuration % 60)}s`
        : "0m 0s",
      icon: Clock,
      description: "Duração média da sessão"
    },
    {
      title: "Taxa de Rejeição",
      value: `${((dadosReais.overview.bounceRate ?? 0) * 100).toFixed(1)}%`,
      icon: Activity,
      description: "Usuários que saíram sem interagir"
    },
    {
      title: "Sessões",
      value: dadosReais.overview.sessions.toLocaleString(),
      icon: MousePointerClick,
      description: "Total de sessões"
    },
    {
      title: "Novos Visitantes",
      value: dadosReais.overview.activeUsers
        ? `${((dadosReais.overview.newUsers / dadosReais.overview.activeUsers) * 100).toFixed(0)}%`
        : "0%",
      icon: Users,
      description: "Porcentagem de novos usuários"
    }
  ] : []

  const deviceMetrics = dadosReais ? dadosReais.devices.map(d => ({
    device: d.device,
    users: d.users,
    percentage: d.percentage,
    icon: d.device === 'Mobile' ? Smartphone : d.device === 'Desktop' ? Monitor : Globe
  })) : []

  const topProducts = dadosReais ? dadosReais.products.map(p => ({
    name: p.name,
    views: p.views,
    addToCart: p.addToCart,
    purchases: p.purchases,
    revenue: p.revenue
  })) : []

  const topPages = dadosReais ? dadosReais.pages.map(p => ({
    page: p.page,
    views: p.views,
    avgTime: p.avgTime,
    bounceRate: p.bounceRate
  })) : []

  const topLocations = dadosReais ? dadosReais.locations.map(l => ({
    city: l.city,
    state: l.state,
    users: l.users,
    sessions: l.sessions
  })) : []

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat("pt-BR", {
      style: "currency",
      currency: "BRL"
    }).format(value)
  }

  // Traduzir nomes de estados em inglês para português
  const traduzirEstado = (state: string): string => {
    const traducoes: Record<string, string> = {
      'state of parana': 'Paraná',
      'state of paraná': 'Paraná',
      'state of sao paulo': 'São Paulo',
      'state of são paulo': 'São Paulo',
      'state of rio de janeiro': 'Rio de Janeiro',
      'state of minas gerais': 'Minas Gerais',
      'state of bahia': 'Bahia',
      'state of rio grande do sul': 'Rio Grande do Sul',
      'state of santa catarina': 'Santa Catarina',
      'state of goias': 'Goiás',
      'state of goiás': 'Goiás',
      'state of pernambuco': 'Pernambuco',
      'state of ceara': 'Ceará',
      'state of ceará': 'Ceará',
      'state of amazonas': 'Amazonas',
      'state of para': 'Pará',
      'state of pará': 'Pará',
      'state of maranhao': 'Maranhão',
      'state of maranhão': 'Maranhão',
      'state of mato grosso': 'Mato Grosso',
      'state of mato grosso do sul': 'Mato Grosso do Sul',
      'state of espirito santo': 'Espírito Santo',
      'state of espírito santo': 'Espírito Santo',
      'state of paraiba': 'Paraíba',
      'state of paraíba': 'Paraíba',
      'state of rio grande do norte': 'Rio Grande do Norte',
      'state of alagoas': 'Alagoas',
      'state of piaui': 'Piauí',
      'state of piauí': 'Piauí',
      'state of sergipe': 'Sergipe',
      'state of acre': 'Acre',
      'state of amapa': 'Amapá',
      'state of amapá': 'Amapá',
      'state of rondonia': 'Rondônia',
      'state of rondônia': 'Rondônia',
      'state of roraima': 'Roraima',
      'state of tocantins': 'Tocantins',
      'federal district': 'Distrito Federal',
      'distrito federal': 'Distrito Federal',
    }
    
    const normalizado = state.toLowerCase().trim()
    return traducoes[normalizado] || state
  }

  const exportarParaExcel = () => {
    if (!dadosReais || topProducts.length === 0) {
      alert('Não há dados para exportar')
      return
    }

    // Preparar dados para exportação
    const dadosExportacao = topProducts.map((product, index) => ({
      'Posição': index + 1,
      'Produto': product.name,
      'Visualizações': product.views,
      'Adicionados ao Carrinho': product.addToCart,
      'Compras': product.purchases,
      'Taxa de Conversão': `${((product.purchases / product.views) * 100).toFixed(1)}%`,
      'Taxa de Cliques': `${((product.addToCart / product.views) * 100).toFixed(1)}%`,
      'Receita': product.revenue,
      'Receita Formatada': formatCurrency(product.revenue)
    }))

    // Adicionar resumo
    const resumo = [
      {
        'Posição': 'RESUMO',
        'Produto': `Período: ${periodo === 'hoje' ? 'Hoje' : periodo === '7dias' ? 'Últimos 7 dias' : 'Últimos 30 dias'}`,
        'Visualizações': topProducts.reduce((sum, p) => sum + p.views, 0),
        'Adicionados ao Carrinho': topProducts.reduce((sum, p) => sum + p.addToCart, 0),
        'Compras': topProducts.reduce((sum, p) => sum + p.purchases, 0),
        'Taxa de Conversão': '',
        'Taxa de Cliques': '',
        'Receita': topProducts.reduce((sum, p) => sum + p.revenue, 0),
        'Receita Formatada': formatCurrency(topProducts.reduce((sum, p) => sum + p.revenue, 0))
      },
      {}
    ]

    const dadosCompletos = [...resumo, ...dadosExportacao]

    // Criar workbook
    const wb = XLSX.utils.book_new()
    const ws = XLSX.utils.json_to_sheet(dadosCompletos)
    ws['!cols'] = [
      { wch: 10 }, { wch: 35 }, { wch: 15 }, { wch: 25 }, { wch: 12 },
      { wch: 18 }, { wch: 18 }, { wch: 15 }, { wch: 20 }
    ]
    XLSX.utils.book_append_sheet(wb, ws, 'Performance Geral')

    // Métricas principais
    const metricas = metricsOverview.map(m => ({
      'Métrica': m.title,
      'Valor': m.value,
      'Descrição': m.description || ''
    }))
    const wsMetricas = XLSX.utils.json_to_sheet(metricas)
    wsMetricas['!cols'] = [{ wch: 30 }, { wch: 15 }, { wch: 40 }]
    XLSX.utils.book_append_sheet(wb, wsMetricas, 'Métricas Principais')

    // Dispositivos
    const dispositivos = deviceMetrics.map(d => ({
      'Dispositivo': d.device,
      'Usuários': d.users,
      'Porcentagem': `${d.percentage}%`
    }))
    const wsDispositivos = XLSX.utils.json_to_sheet(dispositivos)
    wsDispositivos['!cols'] = [{ wch: 20 }, { wch: 15 }, { wch: 15 }]
    XLSX.utils.book_append_sheet(wb, wsDispositivos, 'Dispositivos')

    // Download
    const dataAtual = new Date().toLocaleDateString('pt-BR').replace(/\//g, '-')
    XLSX.writeFile(wb, `analytics-performance-${dataAtual}.xlsx`)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
          <p className="text-muted-foreground">Carregando analytics...</p>
        </div>
      </div>
    )
  }

  // Se não houver dados reais, mostrar mensagem
  if (!dadosReais) {
    return (
      <div className="container mx-auto p-6 space-y-6">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Analytics Dashboard</h1>
            <p className="text-sm text-gray-500 mt-1">
              Análise de comportamento dos usuários e performance do site
            </p>
          </div>
        </div>

        <Card className="border-red-200 bg-red-50">
          <CardContent className="pt-6">
            <div className="flex items-start gap-3">
              <div className="flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center bg-red-100">
                <AlertCircle className="h-5 w-5 text-red-600" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold text-red-900 mb-1">
                  Integração com Google Analytics não configurada
                </h3>
                <p className="text-sm text-red-700 leading-relaxed mb-2">
                  Para visualizar dados reais do Google Analytics, você precisa configurar a integração com a <strong>Google Analytics Data API</strong>.
                </p>
                {erroIntegracao && (
                  <div className="mt-2 p-2 bg-red-100 rounded text-xs text-red-800">
                    <strong>Erro:</strong> {erroIntegracao}
                  </div>
                )}
                <a
                  href="/GOOGLE-ANALYTICS-INTEGRACAO.md"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-red-600 hover:underline mt-2 inline-block font-medium"
                >
                  📖 Ver guia de integração →
                </a>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="container mx-auto p-6 space-y-6 bg-gray-50 min-h-screen">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Analytics Dashboard</h1>
          <p className="text-sm text-gray-500 mt-1">
            Análise de comportamento dos usuários e performance do site
          </p>
        </div>

        {/* Seletor de Período */}
        <div className="flex gap-2">
          <button
            onClick={() => setPeriodo('hoje')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              periodo === 'hoje'
                ? 'bg-white text-gray-900 shadow-sm border border-gray-200'
                : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'
            }`}
          >
            Hoje
          </button>
          <button
            onClick={() => setPeriodo('7dias')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              periodo === '7dias'
                ? 'bg-white text-gray-900 shadow-sm border border-gray-200'
                : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'
            }`}
          >
            Últimos 7 dias
          </button>
          <button
            onClick={() => setPeriodo('30dias')}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              periodo === '30dias'
                ? 'bg-white text-gray-900 shadow-sm border border-gray-200'
                : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'
            }`}
          >
            Últimos 30 dias
          </button>
        </div>
      </div>

      {/* Métricas Principais */}
      {metricsOverview.length > 0 && (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {metricsOverview.map((metric, index) => (
            <Card key={index} className="bg-white border-gray-200 hover:shadow-md transition-shadow">
              <CardContent className="p-6">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-2 text-sm text-gray-500">
                    <span>{metric.title}</span>
                    <HelpCircle className="h-3.5 w-3.5" />
                  </div>
                </div>
                <div className="space-y-2">
                  <div className="text-3xl font-bold text-gray-900">{metric.value}</div>
                  <span className="text-xs text-gray-500">{metric.description}</span>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Tabela de Performance */}
      {topProducts.length > 0 && (
        <Card className="bg-white border-gray-200">
          <CardHeader className="border-b border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-lg font-semibold text-gray-900">Performance Geral</CardTitle>
                <CardDescription className="text-sm text-gray-500 mt-1">
                  Análise detalhada de performance por categoria
                </CardDescription>
              </div>
              <Button 
                variant="default" 
                size="sm" 
                className="text-sm bg-indigo-600 hover:bg-indigo-700"
                onClick={() => exportarParaExcel()}
              >
                <Download className="h-4 w-4 mr-2" />
                Exportar
              </Button>
            </div>
          </CardHeader>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Produto
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Visualizações
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Taxa de Cliques
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Adicionados
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Compras
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Taxa de Conversão
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Receita
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {topProducts.map((product, index) => (
                    <tr key={index} className="hover:bg-gray-50 transition-colors">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{product.name}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{product.views}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">
                          {((product.addToCart / product.views) * 100).toFixed(1)}%
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{product.addToCart}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{product.purchases}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">
                          {((product.purchases / product.views) * 100).toFixed(1)}%
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">{formatCurrency(product.revenue)}</div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Tabs com conteúdo adicional */}
      <Tabs defaultValue="overview" className="space-y-6">
        <TabsList className="bg-white border border-gray-200">
          <TabsTrigger value="overview">Visão Geral</TabsTrigger>
          <TabsTrigger value="products">Produtos</TabsTrigger>
          <TabsTrigger value="behavior">Comportamento</TabsTrigger>
          <TabsTrigger value="audience">Audiência</TabsTrigger>
        </TabsList>

        {/* Visão Geral */}
        <TabsContent value="overview" className="space-y-6">
          {engagementMetrics.length > 0 && (
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
              {engagementMetrics.map((metric, index) => (
                <Card key={index} className="bg-white border-gray-200">
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium text-gray-600">{metric.title}</CardTitle>
                    <metric.icon className="h-4 w-4 text-gray-400" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold text-gray-900">{metric.value}</div>
                    {metric.description && (
                      <p className="text-xs text-gray-500 mt-1">{metric.description}</p>
                    )}
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {deviceMetrics.length > 0 && (
            <Card className="bg-white border-gray-200">
              <CardHeader>
                <CardTitle className="text-lg font-semibold text-gray-900">Dispositivos</CardTitle>
                <CardDescription className="text-sm text-gray-500">
                  Distribuição de acessos por tipo de dispositivo
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {deviceMetrics.map((device, index) => (
                    <div key={index} className="flex items-center gap-4">
                      <device.icon className="h-5 w-5 text-gray-400 flex-shrink-0" />
                      <div className="flex-1">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-sm font-medium text-gray-900">{device.device}</span>
                          <span className="text-sm text-gray-500">
                            {device.users.toLocaleString()} usuários ({device.percentage}%)
                          </span>
                        </div>
                        <div className="w-full bg-gray-100 rounded-full h-2">
                          <div
                            className="bg-indigo-600 h-2 rounded-full transition-all"
                            style={{ width: `${device.percentage}%` }}
                          />
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        {/* Produtos */}
        <TabsContent value="products" className="space-y-6">
          {topProducts.length > 0 && (
            <Card className="bg-white border-gray-200">
              <CardHeader className="border-b border-gray-200">
                <CardTitle className="text-lg font-semibold text-gray-900">Produtos Mais Visualizados</CardTitle>
                <CardDescription className="text-sm text-gray-500">
                  Performance dos produtos no período selecionado
                </CardDescription>
              </CardHeader>
              <CardContent className="p-0">
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-gray-50 border-b border-gray-200">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          #
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Produto
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Visualizações
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Adicionados
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Compras
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Taxa Conversão
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Receita
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {topProducts.map((product, index) => (
                        <tr key={index} className="hover:bg-gray-50 transition-colors">
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className="text-sm font-semibold text-gray-400">#{index + 1}</span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm font-medium text-gray-900">{product.name}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm text-gray-900">{product.views.toLocaleString()}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm text-gray-900">{product.addToCart.toLocaleString()}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm text-gray-900">{product.purchases.toLocaleString()}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm text-gray-900">
                              {((product.purchases / product.views) * 100).toFixed(1)}%
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm font-medium text-gray-900">{formatCurrency(product.revenue)}</div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        {/* Comportamento */}
        <TabsContent value="behavior" className="space-y-6">
          {topPages.length > 0 && (
            <Card className="bg-white border-gray-200">
              <CardHeader className="border-b border-gray-200">
                <CardTitle className="text-lg font-semibold text-gray-900">Páginas Mais Visitadas</CardTitle>
                <CardDescription className="text-sm text-gray-500">
                  Performance das páginas do site
                </CardDescription>
              </CardHeader>
              <CardContent className="p-0">
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-gray-50 border-b border-gray-200">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          #
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Página
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Visualizações
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Tempo Médio
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Taxa de Rejeição
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {topPages.map((page, index) => (
                        <tr key={index} className="hover:bg-gray-50 transition-colors">
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className="text-sm font-semibold text-gray-400">#{index + 1}</span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm font-mono font-medium text-gray-900">{page.page}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm text-gray-900">{page.views.toLocaleString()}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm text-gray-900">{page.avgTime}</div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="text-sm text-gray-900">{page.bounceRate}</div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        {/* Audiência */}
        <TabsContent value="audience" className="space-y-6">
          {topLocations.length > 0 && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Mapa do Brasil */}
              <Card className="bg-white border-gray-200">
                <CardHeader>
                  <CardTitle className="text-lg font-semibold text-gray-900">Mapa de Acessos por Estado</CardTitle>
                  <CardDescription className="text-sm text-gray-500">
                    Distribuição geográfica dos visitantes no Brasil
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <MapaBrasil locations={topLocations} />
                </CardContent>
              </Card>

              {/* Lista de Cidades */}
              <Card className="bg-white border-gray-200">
                <CardHeader>
                  <CardTitle className="text-lg font-semibold text-gray-900">Principais Cidades</CardTitle>
                  <CardDescription className="text-sm text-gray-500">
                    Cidades com maior número de visitantes
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3 max-h-[600px] overflow-y-auto">
                    {topLocations.map((location, index) => (
                      <div key={index} className="flex items-center justify-between p-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                        <div className="flex items-center gap-3">
                          <div className="flex items-center justify-center w-8 h-8 rounded-full bg-indigo-100 text-indigo-600 font-semibold text-sm">
                            {index + 1}
                          </div>
                          <MapPin className="h-5 w-5 text-gray-400" />
                          <div>
                            <p className="font-semibold text-gray-900">{location.city}, {traduzirEstado(location.state)}</p>
                            <p className="text-sm text-gray-500">
                              {location.sessions.toLocaleString()} sessões
                            </p>
                          </div>
                        </div>
                        <div className="text-right">
                          <p className="font-semibold text-gray-900">{location.users.toLocaleString()}</p>
                          <p className="text-xs text-gray-500">usuários</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </div>
          )}
        </TabsContent>
      </Tabs>
    </div>
  )
}

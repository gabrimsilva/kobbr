# 📊 Exemplos de Uso - Google Analytics 4

Este documento contém exemplos práticos de como usar o Google Analytics 4 no sistema.

## 🎯 Rastreamento de Eventos

### 1. Visualização de Produto

```typescript
import { trackViewItem } from '@/lib/analytics'

// Quando o usuário visualiza um produto
function visualizarProduto(produto: Produto) {
  trackViewItem({
    id: produto.id,
    nome: produto.nome,
    categoria: produto.categoria?.nome,
    preco: produto.preco
  })
}
```

### 2. Adicionar ao Carrinho

```typescript
import { trackAddToCart } from '@/lib/analytics'

// Quando o usuário adiciona um produto ao carrinho
function adicionarAoCarrinho(produto: Produto, quantidade: number) {
  trackAddToCart({
    id: produto.id,
    nome: produto.nome,
    preco: produto.preco,
    quantidade: quantidade
  })
}
```

### 3. Finalizar Compra

```typescript
import { trackPurchase } from '@/lib/analytics'

// Quando o usuário finaliza uma compra
function finalizarCompra(pedido: Pedido) {
  const items = pedido.itens.map(item => ({
    id: item.produto.id,
    nome: item.produto.nome,
    preco: item.preco_unitario,
    quantidade: item.quantidade
  }))

  trackPurchase(
    pedido.id,
    items,
    pedido.valor_total,
    pedido.taxa_entrega || 0
  )
}
```

### 4. Visualização de Página

```typescript
import { trackPageView } from '@/lib/analytics'

// Quando o usuário acessa uma página
useEffect(() => {
  trackPageView('Nome da Página', '/caminho/da/pagina')
}, [])
```

## 📈 Buscar Dados do Analytics

### 1. Buscar Dados dos Últimos 7 Dias

```typescript
import { buscarDadosGA4 } from '@/lib/googleAnalyticsService'

async function carregarDados() {
  try {
    const dados = await buscarDadosGA4('7dias')
    
    console.log('Usuários ativos:', dados.overview.activeUsers)
    console.log('Visualizações:', dados.overview.screenPageViews)
    console.log('Conversões:', dados.overview.conversions)
    console.log('Receita:', dados.overview.purchaseRevenue)
  } catch (error) {
    console.error('Erro ao carregar dados:', error)
  }
}
```

### 2. Buscar Produtos Mais Vistos

```typescript
import { buscarDadosGA4 } from '@/lib/googleAnalyticsService'

async function produtosMaisVistos() {
  const dados = await buscarDadosGA4('30dias')
  
  // Top 10 produtos
  const topProdutos = dados.products.slice(0, 10)
  
  topProdutos.forEach((produto, index) => {
    console.log(`${index + 1}. ${produto.name}`)
    console.log(`   Visualizações: ${produto.views}`)
    console.log(`   Adicionados ao carrinho: ${produto.addToCart}`)
    console.log(`   Compras: ${produto.purchases}`)
    console.log(`   Receita: R$ ${produto.revenue.toFixed(2)}`)
    console.log('')
  })
}
```

### 3. Analisar Dispositivos

```typescript
import { buscarDadosGA4 } from '@/lib/googleAnalyticsService'

async function analisarDispositivos() {
  const dados = await buscarDadosGA4('7dias')
  
  dados.devices.forEach(device => {
    console.log(`${device.device}: ${device.users} usuários (${device.percentage}%)`)
  })
}
```

### 4. Páginas Mais Visitadas

```typescript
import { buscarDadosGA4 } from '@/lib/googleAnalyticsService'

async function paginasMaisVisitadas() {
  const dados = await buscarDadosGA4('30dias')
  
  dados.pages.forEach((page, index) => {
    console.log(`${index + 1}. ${page.page}`)
    console.log(`   Visualizações: ${page.views}`)
    console.log(`   Tempo médio: ${page.avgTime}`)
    console.log(`   Taxa de rejeição: ${page.bounceRate}`)
    console.log('')
  })
}
```

### 5. Localizações dos Usuários

```typescript
import { buscarDadosGA4 } from '@/lib/googleAnalyticsService'

async function localizacoesUsuarios() {
  const dados = await buscarDadosGA4('30dias')
  
  // Top 10 cidades
  const topCidades = dados.locations.slice(0, 10)
  
  topCidades.forEach((location, index) => {
    console.log(`${index + 1}. ${location.city}, ${location.state}`)
    console.log(`   Usuários: ${location.users}`)
    console.log(`   Sessões: ${location.sessions}`)
    console.log('')
  })
}
```

## 📊 Componente React Completo

```typescript
import { useState, useEffect } from 'react'
import { buscarDadosGA4, type GA4Data } from '@/lib/googleAnalyticsService'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

export default function MeuComponenteAnalytics() {
  const [dados, setDados] = useState<GA4Data | null>(null)
  const [loading, setLoading] = useState(true)
  const [periodo, setPeriodo] = useState<'hoje' | '7dias' | '30dias'>('7dias')

  useEffect(() => {
    carregarDados()
  }, [periodo])

  const carregarDados = async () => {
    setLoading(true)
    try {
      const resultado = await buscarDadosGA4(periodo)
      setDados(resultado)
    } catch (error) {
      console.error('Erro ao carregar dados:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return <div>Carregando...</div>
  }

  if (!dados) {
    return <div>Erro ao carregar dados</div>
  }

  return (
    <div className="space-y-6">
      {/* Seletor de Período */}
      <div className="flex gap-2">
        <button
          onClick={() => setPeriodo('hoje')}
          className={periodo === 'hoje' ? 'active' : ''}
        >
          Hoje
        </button>
        <button
          onClick={() => setPeriodo('7dias')}
          className={periodo === '7dias' ? 'active' : ''}
        >
          7 dias
        </button>
        <button
          onClick={() => setPeriodo('30dias')}
          className={periodo === '30dias' ? 'active' : ''}
        >
          30 dias
        </button>
      </div>

      {/* Métricas Principais */}
      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardHeader>
            <CardTitle>Usuários</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">
              {dados.overview.activeUsers.toLocaleString()}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Visualizações</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">
              {dados.overview.screenPageViews.toLocaleString()}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Conversões</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">
              {dados.overview.conversions.toLocaleString()}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Receita</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">
              R$ {dados.overview.purchaseRevenue.toFixed(2)}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Produtos Mais Vistos */}
      <Card>
        <CardHeader>
          <CardTitle>Produtos Mais Vistos</CardTitle>
        </CardHeader>
        <CardContent>
          <table className="w-full">
            <thead>
              <tr>
                <th>Produto</th>
                <th>Visualizações</th>
                <th>Compras</th>
                <th>Receita</th>
              </tr>
            </thead>
            <tbody>
              {dados.products.slice(0, 5).map((produto, index) => (
                <tr key={index}>
                  <td>{produto.name}</td>
                  <td>{produto.views}</td>
                  <td>{produto.purchases}</td>
                  <td>R$ {produto.revenue.toFixed(2)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  )
}
```

## 🔄 Integração com Hooks Existentes

### useCarrinho

```typescript
// Em src/hooks/useCarrinho.ts
import { trackAddToCart } from '@/lib/analytics'

const adicionarItem = (item: ItemCarrinho) => {
  // ... lógica existente ...
  
  // Rastrear no GA4
  trackAddToCart({
    id: item.produto.id,
    nome: item.produto.nome,
    preco: item.preco,
    quantidade: item.quantidade
  })
}
```

### useFinalizarPedido

```typescript
// Em src/hooks/useFinalizarPedido.ts
import { trackPurchase } from '@/lib/analytics'

const finalizarPedido = async () => {
  // ... lógica existente ...
  
  // Rastrear no GA4
  trackPurchase(
    pedidoId,
    items,
    total,
    taxaEntrega
  )
}
```

## 📱 Rastreamento em Páginas

### DeliveryPage

```typescript
// Em src/pages/DeliveryPage.tsx
import { useEffect } from 'react'
import { trackPageView } from '@/lib/analytics'

export default function DeliveryPage() {
  useEffect(() => {
    trackPageView('Delivery', '/delivery')
  }, [])
  
  // ... resto do componente
}
```

### ProdutoCard

```typescript
// Em src/components/ProdutoCard.tsx
import { trackViewItem } from '@/lib/analytics'

export default function ProdutoCard({ produto }: Props) {
  const handleClick = () => {
    trackViewItem({
      id: produto.id,
      nome: produto.nome,
      categoria: produto.categoria?.nome,
      preco: produto.preco
    })
    
    // ... resto da lógica
  }
  
  // ... resto do componente
}
```

## 🎨 Formatação de Dados

### Formatar Moeda

```typescript
function formatarMoeda(valor: number): string {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(valor)
}

// Uso
console.log(formatarMoeda(dados.overview.purchaseRevenue))
// Output: R$ 1.234,56
```

### Formatar Porcentagem

```typescript
function formatarPorcentagem(valor: number): string {
  return `${(valor * 100).toFixed(1)}%`
}

// Uso
console.log(formatarPorcentagem(dados.overview.bounceRate))
// Output: 45.6%
```

### Formatar Tempo

```typescript
function formatarTempo(segundos: number): string {
  const minutos = Math.floor(segundos / 60)
  const segs = Math.floor(segundos % 60)
  return `${minutos}m ${segs}s`
}

// Uso
console.log(formatarTempo(dados.overview.averageSessionDuration))
// Output: 2m 34s
```

## 📊 Cálculos Úteis

### Taxa de Conversão

```typescript
function calcularTaxaConversao(dados: GA4Data): number {
  if (dados.overview.screenPageViews === 0) return 0
  return (dados.overview.conversions / dados.overview.screenPageViews) * 100
}

// Uso
const taxaConversao = calcularTaxaConversao(dados)
console.log(`Taxa de conversão: ${taxaConversao.toFixed(2)}%`)
```

### Ticket Médio

```typescript
function calcularTicketMedio(dados: GA4Data): number {
  if (dados.overview.conversions === 0) return 0
  return dados.overview.purchaseRevenue / dados.overview.conversions
}

// Uso
const ticketMedio = calcularTicketMedio(dados)
console.log(`Ticket médio: ${formatarMoeda(ticketMedio)}`)
```

### Taxa de Abandono de Carrinho

```typescript
function calcularTaxaAbandono(dados: GA4Data): number {
  if (dados.overview.itemsAddedToCart === 0) return 0
  const abandonos = dados.overview.itemsAddedToCart - dados.overview.itemsPurchased
  return (abandonos / dados.overview.itemsAddedToCart) * 100
}

// Uso
const taxaAbandono = calcularTaxaAbandono(dados)
console.log(`Taxa de abandono: ${taxaAbandono.toFixed(1)}%`)
```

## 🚀 Dicas de Performance

### 1. Cache de Dados

```typescript
import { useState, useEffect } from 'react'

const CACHE_TIME = 5 * 60 * 1000 // 5 minutos

function useCachedAnalytics(periodo: string) {
  const [dados, setDados] = useState<GA4Data | null>(null)
  const [ultimaAtualizacao, setUltimaAtualizacao] = useState<number>(0)

  useEffect(() => {
    const agora = Date.now()
    
    // Usar cache se ainda válido
    if (dados && agora - ultimaAtualizacao < CACHE_TIME) {
      return
    }

    // Buscar novos dados
    buscarDadosGA4(periodo as any).then(resultado => {
      setDados(resultado)
      setUltimaAtualizacao(agora)
    })
  }, [periodo])

  return dados
}
```

### 2. Debounce de Eventos

```typescript
import { debounce } from 'lodash'

// Evitar enviar muitos eventos rapidamente
const trackViewItemDebounced = debounce(trackViewItem, 1000)
```

### 3. Batch de Eventos

```typescript
// Agrupar eventos e enviar em lote
const eventQueue: any[] = []

function queueEvent(event: any) {
  eventQueue.push(event)
  
  if (eventQueue.length >= 10) {
    flushEvents()
  }
}

function flushEvents() {
  // Enviar todos os eventos
  eventQueue.forEach(event => {
    // Enviar evento
  })
  
  eventQueue.length = 0
}
```

## 📚 Recursos Adicionais

- [Documentação GA4](https://developers.google.com/analytics/devguides/collection/ga4)
- [Eventos Recomendados](https://developers.google.com/analytics/devguides/collection/ga4/reference/events)
- [Métricas e Dimensões](https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema)

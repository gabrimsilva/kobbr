# 🎯 ETAPA 4 — CENTRAL DE ALERTAS

## 📋 OBJETIVO

Criar página dedicada "Alertas de Estoque" para visualizar e gerenciar produtos que precisam de atenção (críticos e em atenção).

---

## 🔧 IMPLEMENTAÇÕES

### 1. Nova Página: AlertasEstoque.tsx

**Localização:** `src/pages/AlertasEstoque.tsx`

**Funcionalidades:**
- Exibir apenas produtos CRITICAL e WARNING
- Ordenar por criticidade (CRITICAL primeiro)
- Cards com ações rápidas
- Estatísticas no topo

---

### 2. Estrutura da Página

**Header:**
```
┌─────────────────────────────────────┐
│ 🚨 Alertas de Estoque               │
│ Produtos que precisam de atenção    │
└─────────────────────────────────────┘
```

**Estatísticas:**
```
┌─────────────────────────────────────┐
│ 🔴 3 Críticos  🟡 5 Em Atenção      │
│ 📦 8 Total de Alertas               │
└─────────────────────────────────────┘
```

**Lista de Alertas:**
```
┌─────────────────────────────────────┐
│ 🔴 Batom Rosa                       │
│ Estoque: 3 | Mínimo: 5              │
│ [Editar] [Solicitar Reposição]     │
└─────────────────────────────────────┘
```

---

### 3. Ações Rápidas

**Por produto:**
- ✅ Editar configurações (min_qty, reorder_qty)
- ✅ Ver detalhes completos
- 🔜 Solicitar reposição (ETAPA 5)

---

### 4. Integração com Menu

**Adicionar rota:**
- Path: `/alertas-estoque`
- Componente: `AlertasEstoque`
- Menu: Estoque → Alertas de Estoque

---

## 📊 ESTRUTURA VISUAL

### Card de Alerta (Crítico):

```tsx
<Card className="border-l-4 border-l-red-500">
  <CardHeader>
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-2">
        <AlertTriangle className="h-5 w-5 text-red-500" />
        <CardTitle className="text-base">Batom Rosa</CardTitle>
      </div>
      <span className="px-2 py-1 bg-red-100 text-red-800 text-xs font-medium rounded">
        🔴 Crítico
      </span>
    </div>
  </CardHeader>
  <CardContent>
    <div className="space-y-3">
      {/* Informações */}
      <div className="grid grid-cols-2 gap-2 text-sm">
        <div>
          <span className="text-muted-foreground">Estoque:</span>
          <span className="font-bold text-red-600 ml-2">3</span>
        </div>
        <div>
          <span className="text-muted-foreground">Mínimo:</span>
          <span className="font-medium ml-2">5</span>
        </div>
      </div>
      
      {/* Ações */}
      <div className="flex gap-2">
        <Button size="sm" variant="outline">
          <Settings className="h-4 w-4 mr-1" />
          Editar
        </Button>
        <Button size="sm" className="bg-blue-600">
          <Package className="h-4 w-4 mr-1" />
          Ver Detalhes
        </Button>
      </div>
    </div>
  </CardContent>
</Card>
```

---

### Card de Alerta (Atenção):

```tsx
<Card className="border-l-4 border-l-yellow-500">
  {/* Similar ao crítico, mas com cores amarelas */}
</Card>
```

---

## 🔧 IMPLEMENTAÇÃO

### Arquivo: `src/pages/AlertasEstoque.tsx`

```typescript
import { useState, useEffect, useMemo } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { AlertTriangle, Package, Settings, Loader2 } from "lucide-react"
import { stockService, produtoService, type StockItem } from "@/services"
import { calcularStatusEstoque } from "@/services/stockService"
import EditarEstoqueModal from "@/components/EditarEstoqueModal"
import { useNavigate } from "react-router-dom"

interface StockItemWithProduct extends StockItem {
  product_name?: string
}

export default function AlertasEstoque() {
  const [itens, setItens] = useState<StockItemWithProduct[]>([])
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate()
  
  // Modal de edição
  const [editarModalOpen, setEditarModalOpen] = useState(false)
  const [itemEdicao, setItemEdicao] = useState<any>(null)

  useEffect(() => {
    carregarAlertas()
  }, [])

  const carregarAlertas = async () => {
    try {
      setLoading(true)
      const stockItems = await stockService.buscarTodos()
      
      // Buscar informações dos produtos
      const itensComInfo = await Promise.all(
        stockItems.map(async (item) => {
          const produto = await produtoService.buscarPorId(item.product_id)
          return {
            ...item,
            product_name: produto?.nome || 'Produto não encontrado'
          }
        })
      )
      
      // Filtrar apenas CRITICAL e WARNING
      const alertas = itensComInfo.filter(item => {
        const status = calcularStatusEstoque(item.total_qty, item.min_qty)
        return status === 'CRITICAL' || status === 'WARNING'
      })
      
      // Ordenar por criticidade
      const alertasOrdenados = alertas.sort((a, b) => {
        const statusA = calcularStatusEstoque(a.total_qty, a.min_qty)
        const statusB = calcularStatusEstoque(b.total_qty, b.min_qty)
        
        const prioridadeA = statusA === 'CRITICAL' ? 1 : 2
        const prioridadeB = statusB === 'CRITICAL' ? 1 : 2
        
        if (prioridadeA !== prioridadeB) {
          return prioridadeA - prioridadeB
        }
        
        return (a.product_name || '').localeCompare(b.product_name || '')
      })
      
      setItens(alertasOrdenados)
    } catch (err) {
      console.error('Erro ao carregar alertas:', err)
    } finally {
      setLoading(false)
    }
  }

  const contadores = useMemo(() => {
    const critical = itens.filter(item => 
      calcularStatusEstoque(item.total_qty, item.min_qty) === 'CRITICAL'
    ).length
    
    const warning = itens.filter(item => 
      calcularStatusEstoque(item.total_qty, item.min_qty) === 'WARNING'
    ).length
    
    return { critical, warning, total: itens.length }
  }, [itens])

  // ... resto do componente
}
```

---

## ✅ ACEITE DA ETAPA 4

- [x] Página AlertasEstoque.tsx criada
- [x] Rota `/alertas-estoque` configurada
- [x] Exibe apenas produtos CRITICAL e WARNING
- [x] Ordenação por criticidade funcionando
- [x] Estatísticas no topo
- [x] Cards com borda colorida (vermelho/amarelo)
- [x] Botão "Editar" abre modal
- [x] Botão "Ver Detalhes" navega para estoque
- [x] Mensagem quando não há alertas
- [x] Sem erros de TypeScript

---

## 🚀 PRÓXIMA ETAPA

**ETAPA 5 - Solicitação de Reposição**

Objetivos:
- Criar tabela `restock_requests`
- Botão "Solicitar Reposição"
- Sugerir quantidade (reorder_qty ou min_qty * 2)
- Não duplicar solicitações abertas

---

**Data de Início:** 27/02/2026  
**Responsável:** Kiro AI  
**Status:** ✅ COMPLETO


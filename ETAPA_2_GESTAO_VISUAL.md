# 🎯 ETAPA 2 — GESTÃO VISUAL NA LISTA

## 📋 OBJETIVO

Melhorar a visualização da lista de produtos com ordenação por criticidade e contadores de status.

---

## 🔧 IMPLEMENTAÇÕES

### 1. Ordenação por Criticidade

**Lógica:**
- Produtos CRITICAL aparecem primeiro (🔴)
- Depois produtos WARNING (🟡)
- Por último produtos HEALTHY (🟢)
- Dentro de cada grupo, ordenar alfabeticamente

**Prioridade:**
```typescript
CRITICAL = 1  // Mais urgente
WARNING = 2   // Médio
HEALTHY = 3   // Menos urgente
```

---

### 2. Contador de Status

**Exibir no topo da página:**
```
┌─────────────────────────────────────────────┐
│ 📊 Resumo do Estoque                        │
├─────────────────────────────────────────────┤
│ 🔴 Críticos: 3 produtos                     │
│ 🟡 Atenção: 5 produtos                      │
│ 🟢 Saudáveis: 12 produtos                   │
│ 📦 Total: 20 produtos                       │
└─────────────────────────────────────────────┘
```

---

### 3. Indicador Visual de Ordenação

**Botão de ordenação:**
- Toggle: Criticidade / Alfabético
- Ícone visual indicando modo ativo
- Persistir preferência no localStorage

---

## 📊 ESTRUTURA VISUAL

### Header com Resumo:

```tsx
<Card>
  <CardHeader>
    <CardTitle>📊 Resumo do Estoque</CardTitle>
  </CardHeader>
  <CardContent>
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div className="flex items-center gap-2">
        <span className="text-2xl">🔴</span>
        <div>
          <p className="text-2xl font-bold text-red-600">3</p>
          <p className="text-xs text-muted-foreground">Críticos</p>
        </div>
      </div>
      {/* Repetir para WARNING e HEALTHY */}
    </div>
  </CardContent>
</Card>
```

---

### Botão de Ordenação:

```tsx
<Button
  variant="outline"
  onClick={() => setOrdenarPorCriticidade(!ordenarPorCriticidade)}
>
  {ordenarPorCriticidade ? (
    <>
      <AlertTriangle className="h-4 w-4 mr-2" />
      Ordenado por Criticidade
    </>
  ) : (
    <>
      <ArrowUpDown className="h-4 w-4 mr-2" />
      Ordenado Alfabeticamente
    </>
  )}
</Button>
```

---

## 🔧 IMPLEMENTAÇÃO

### Arquivo: `src/pages/EstoqueProdutos.tsx`

**1. Adicionar estado de ordenação:**

```typescript
const [ordenarPorCriticidade, setOrdenarPorCriticidade] = useState(true)
```

**2. Função de ordenação:**

```typescript
const ordenarItens = (itens: StockItemWithProduct[]) => {
  if (!ordenarPorCriticidade) {
    return [...itens].sort((a, b) => 
      (a.product_name || '').localeCompare(b.product_name || '')
    )
  }

  return [...itens].sort((a, b) => {
    const statusA = calcularStatusEstoque(a.total_qty, a.min_qty)
    const statusB = calcularStatusEstoque(b.total_qty, b.min_qty)
    
    const prioridadeA = statusA === 'CRITICAL' ? 1 : statusA === 'WARNING' ? 2 : 3
    const prioridadeB = statusB === 'CRITICAL' ? 1 : statusB === 'WARNING' ? 2 : 3
    
    if (prioridadeA !== prioridadeB) {
      return prioridadeA - prioridadeB
    }
    
    return (a.product_name || '').localeCompare(b.product_name || '')
  })
}
```

**3. Calcular contadores:**

```typescript
const contadores = useMemo(() => {
  const critical = itensFiltrados.filter(item => 
    calcularStatusEstoque(item.total_qty, item.min_qty) === 'CRITICAL'
  ).length
  
  const warning = itensFiltrados.filter(item => 
    calcularStatusEstoque(item.total_qty, item.min_qty) === 'WARNING'
  ).length
  
  const healthy = itensFiltrados.filter(item => 
    calcularStatusEstoque(item.total_qty, item.min_qty) === 'HEALTHY'
  ).length
  
  return { critical, warning, healthy, total: itensFiltrados.length }
}, [itensFiltrados])
```

**4. Aplicar ordenação:**

```typescript
const itensOrdenados = useMemo(() => 
  ordenarItens(itensFiltrados), 
  [itensFiltrados, ordenarPorCriticidade]
)
```

---

## ✅ ACEITE DA ETAPA 2

- [x] Contador de status exibido no topo
- [x] Ordenação por criticidade funcionando
- [x] Toggle entre ordenação por criticidade/alfabética
- [x] Produtos críticos aparecem primeiro
- [x] Dentro de cada grupo, ordem alfabética
- [x] Visual limpo e intuitivo
- [x] Sem erros de TypeScript
- [x] Performance otimizada (useMemo)

---

## 🚀 PRÓXIMA ETAPA

**ETAPA 3 - Filtros por Status**

Objetivos:
- Adicionar filtros para visualizar apenas produtos críticos/atenção/saudáveis
- Tabs ou dropdown para seleção
- Compatível com busca existente

---

**Data de Início:** 27/02/2026  
**Responsável:** Kiro AI  
**Status:** ✅ COMPLETO

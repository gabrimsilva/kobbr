# 🎯 ETAPA 3 — FILTROS POR STATUS

## 📋 OBJETIVO

Adicionar filtros clicáveis para visualizar apenas produtos de um status específico (Todos, Críticos, Atenção, Saudáveis).

---

## 🔧 IMPLEMENTAÇÕES

### 1. Filtro de Status

**Opções:**
- 📦 Todos (padrão)
- 🔴 Críticos
- 🟡 Atenção
- 🟢 Saudáveis

**Comportamento:**
- Clicar em um card de resumo ativa o filtro
- Indicador visual mostra filtro ativo
- Compatível com busca existente
- Compatível com ordenação existente

---

### 2. Indicador Visual de Filtro Ativo

**Quando filtro ativo:**
- Card do filtro ativo tem borda mais grossa
- Card do filtro ativo tem sombra
- Ícone de "X" para limpar filtro
- Texto indicando filtro ativo

---

### 3. Integração com Funcionalidades Existentes

**Busca + Filtro:**
- Busca filtra por nome
- Filtro filtra por status
- Ambos funcionam juntos

**Ordenação + Filtro:**
- Ordenação continua funcionando
- Aplica-se apenas aos itens filtrados

---

## 📊 ESTRUTURA VISUAL

### Cards de Resumo (Clicáveis):

```tsx
<div 
  onClick={() => setFiltroStatus('CRITICAL')}
  className={`
    cursor-pointer transition-all
    ${filtroStatus === 'CRITICAL' 
      ? 'ring-2 ring-red-500 shadow-lg' 
      : 'hover:shadow-md'
    }
  `}
>
  {/* Conteúdo do card */}
</div>
```

---

### Indicador de Filtro Ativo:

```tsx
{filtroStatus !== 'ALL' && (
  <div className="flex items-center gap-2 p-3 bg-blue-50 border border-blue-200 rounded-lg">
    <span>Filtrando: {getFiltroLabel()}</span>
    <Button 
      size="sm" 
      variant="ghost"
      onClick={() => setFiltroStatus('ALL')}
    >
      <X className="h-4 w-4" />
      Limpar
    </Button>
  </div>
)}
```

---

## 🔧 IMPLEMENTAÇÃO

### Arquivo: `src/pages/EstoqueProdutos.tsx`

**1. Adicionar estado de filtro:**

```typescript
type FiltroStatus = 'ALL' | 'CRITICAL' | 'WARNING' | 'HEALTHY'
const [filtroStatus, setFiltroStatus] = useState<FiltroStatus>('ALL')
```

**2. Função de filtragem:**

```typescript
const aplicarFiltroStatus = (itens: StockItemWithProduct[]) => {
  if (filtroStatus === 'ALL') {
    return itens
  }
  
  return itens.filter(item => {
    const status = calcularStatusEstoque(item.total_qty, item.min_qty)
    return status === filtroStatus
  })
}
```

**3. Aplicar filtro:**

```typescript
// Primeiro filtrar por busca
const itensFiltradosPorBusca = itens.filter(item =>
  item.product_name?.toLowerCase().includes(termoBusca.toLowerCase())
)

// Depois filtrar por status
const itensFiltradosPorStatus = aplicarFiltroStatus(itensFiltradosPorBusca)

// Calcular contadores (baseado em busca, não em filtro de status)
const contadores = useMemo(() => {
  // ... usar itensFiltradosPorBusca
}, [itensFiltradosPorBusca])

// Aplicar ordenação
const itensOrdenados = useMemo(() => 
  ordenarItens(itensFiltradosPorStatus), 
  [itensFiltradosPorStatus, ordenarPorCriticidade]
)
```

**4. Tornar cards clicáveis:**

```typescript
<div 
  onClick={() => setFiltroStatus(filtroStatus === 'CRITICAL' ? 'ALL' : 'CRITICAL')}
  className={`
    flex items-center gap-3 p-3 bg-red-50 rounded-lg border border-red-200
    cursor-pointer transition-all
    ${filtroStatus === 'CRITICAL' 
      ? 'ring-2 ring-red-500 shadow-lg scale-105' 
      : 'hover:shadow-md hover:scale-102'
    }
  `}
>
  {/* Conteúdo */}
</div>
```

**5. Adicionar indicador de filtro ativo:**

```typescript
{filtroStatus !== 'ALL' && (
  <div className="flex items-center justify-between p-3 bg-blue-50 border border-blue-200 rounded-lg">
    <div className="flex items-center gap-2">
      <span className="text-sm font-medium">
        Filtrando: {getFiltroLabel(filtroStatus)}
      </span>
      <span className="text-xs text-muted-foreground">
        ({itensOrdenados.length} produtos)
      </span>
    </div>
    <Button 
      size="sm" 
      variant="ghost"
      onClick={() => setFiltroStatus('ALL')}
    >
      <X className="h-4 w-4 mr-1" />
      Limpar Filtro
    </Button>
  </div>
)}
```

---

## ✅ ACEITE DA ETAPA 3

- [x] Cards de resumo são clicáveis
- [x] Clicar em um card ativa o filtro
- [x] Clicar novamente no mesmo card desativa o filtro
- [x] Indicador visual de filtro ativo
- [x] Botão "Limpar Filtro" funcionando
- [x] Filtro compatível com busca
- [x] Filtro compatível com ordenação
- [x] Contadores sempre mostram total (não afetados pelo filtro)
- [x] Transições suaves (hover, active)
- [x] Sem erros de TypeScript

---

## 🚀 PRÓXIMA ETAPA

**ETAPA 4 - Central de Alertas**

Objetivos:
- Criar página dedicada "Alertas de Estoque"
- Exibir apenas itens críticos e em atenção
- Ações rápidas (solicitar reposição, editar)

---

**Data de Início:** 27/02/2026  
**Responsável:** Kiro AI  
**Status:** ✅ COMPLETO

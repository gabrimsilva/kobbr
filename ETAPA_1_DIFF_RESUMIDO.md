# 📊 ETAPA 1 — DIFF RESUMIDO

## ✅ STATUS: COMPLETO

---

## 🔧 ARQUIVOS MODIFICADOS

### 1. `migrations/add_min_qty_fields.sql` (CRIADO)

```sql
ALTER TABLE stock_items
ADD COLUMN IF NOT EXISTS min_qty INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS reorder_qty INT DEFAULT 0;

UPDATE stock_items
SET min_qty = 5, reorder_qty = 10
WHERE min_qty = 0;
```

**Resultado:** ✅ Executado com sucesso no Supabase

---

### 2. `src/components/EditarEstoqueModal.tsx` (CRIADO)

Modal completo para edição de `min_qty` e `reorder_qty` com:
- Validações (não negativos, reorder ≥ min)
- Preview dos alertas
- Feedback visual
- Integração com `stockService`

**Funcionalidades:**
- ✅ Editar estoque mínimo
- ✅ Editar quantidade de reposição
- ✅ Preview de quando os alertas serão acionados
- ✅ Validação de valores
- ✅ Toast de sucesso/erro

---

### 3. `src/services/stockService.ts` (MODIFICADO)

**Adicionado:**

```typescript
// Novo tipo
export type StockStatus = 'CRITICAL' | 'WARNING' | 'HEALTHY'

// Nova função
export function calcularStatusEstoque(
  total_qty: number,
  min_qty: number
): StockStatus {
  if (min_qty === 0) return 'HEALTHY'
  if (total_qty <= min_qty) return 'CRITICAL'
  if (total_qty <= min_qty * 1.3) return 'WARNING'
  return 'HEALTHY'
}

// Interface atualizada
export interface StockItem {
  // ... campos existentes
  min_qty: number        // ✅ Novo
  reorder_qty: number    // ✅ Novo
}

// Novo método
async atualizarQuantidadeReposicao(stockItemId: string, reorderQty: number): Promise<void> {
  const { error } = await supabase
    .from('stock_items')
    .update({ reorder_qty: reorderQty })
    .eq('id', stockItemId)

  if (error) {
    throw new Error(`Falha ao atualizar quantidade de reposição: ${error.message}`)
  }
}
```

---

### 4. `src/services/index.ts` (MODIFICADO)

**Antes:**
```typescript
import { stockService } from './stockService'
export { stockService }
export type { StockItem, StockVariant, StockMovement } from './stockService'
```

**Depois:**
```typescript
import { stockService, calcularStatusEstoque } from './stockService'
export { stockService, calcularStatusEstoque }
export type { StockItem, StockVariant, StockMovement, StockStatus } from './stockService'
```

---

### 5. `src/pages/EstoqueProdutos.tsx` (MODIFICADO)

#### Import atualizado:

```typescript
import { calcularStatusEstoque } from "@/services/stockService"
```

#### Função `getStatusInfo()` refatorada:

**ANTES:**
```typescript
const getStatusInfo = (item: StockItemWithProduct) => {
  if (item.total_qty === 0) {
    return { status: 'Sem estoque', cor: 'red', icon: AlertTriangle }
  }
  if (item.total_qty <= item.min_qty) {
    return { status: 'Estoque baixo', cor: 'yellow', icon: AlertTriangle }
  }
  return { status: 'Estoque OK', cor: 'green', icon: Package }
}
```

**DEPOIS:**
```typescript
const getStatusInfo = (item: StockItemWithProduct) => {
  const status = calcularStatusEstoque(item.total_qty, item.min_qty)
  
  switch (status) {
    case 'CRITICAL':
      return { 
        status: 'CRITICAL', 
        label: '🔴 Crítico', 
        cor: 'red', 
        bgClass: 'bg-red-100 border-red-200',
        textClass: 'text-red-800',
        icon: AlertTriangle 
      }
    case 'WARNING':
      return { 
        status: 'WARNING', 
        label: '🟡 Atenção', 
        cor: 'yellow', 
        bgClass: 'bg-yellow-100 border-yellow-200',
        textClass: 'text-yellow-800',
        icon: AlertTriangle 
      }
    case 'HEALTHY':
      return { 
        status: 'HEALTHY', 
        label: '🟢 Saudável', 
        cor: 'green', 
        bgClass: 'bg-green-100 border-green-200',
        textClass: 'text-green-800',
        icon: Package 
      }
  }
}
```

#### Badge de status atualizado:

**ANTES:**
```tsx
<div className={`text-xs text-${statusInfo.cor}-600 font-medium`}>
  {statusInfo.status}
</div>
```

**DEPOIS:**
```tsx
<div className={`
  inline-flex items-center justify-center w-full px-2.5 py-1.5 rounded-md text-xs font-medium border
  ${statusInfo.bgClass} ${statusInfo.textClass}
`}>
  {statusInfo.label}
</div>
```

#### Adicionada exibição de Quantidade de Reposição:

```tsx
{/* Reposição */}
<div className="flex items-center justify-between text-sm">
  <span className="text-muted-foreground">Reposição:</span>
  <span className="font-medium">{item.reorder_qty}</span>
</div>
```

#### Adicionado botão "Configurar Estoque":

```tsx
<Button
  variant="outline"
  size="sm"
  onClick={() => handleAbrirEdicaoEstoque(item)}
  className="w-full border-gray-200 text-gray-700 hover:bg-gray-50"
>
  <Settings className="h-4 w-4 mr-2" />
  Configurar Estoque
</Button>
```

#### Adicionado modal de edição:

```tsx
{itemEdicao && (
  <EditarEstoqueModal
    isOpen={editarEstoqueModalOpen}
    onClose={() => {
      setEditarEstoqueModalOpen(false)
      setItemEdicao(null)
    }}
    stockItemId={itemEdicao.stockItemId}
    productName={itemEdicao.productName}
    currentMinQty={itemEdicao.minQty}
    currentReorderQty={itemEdicao.reorderQty}
    onSaved={carregarItens}
  />
)}
```

---

## 🎨 MUDANÇAS VISUAIS

### Card de Produto:

**ANTES:**
```
┌─────────────────────────────┐
│ Batom Rosa                  │
│ Quantidade: 3               │
│ Mínimo: 5                   │
│ Status: Estoque baixo       │ ← Texto simples
└─────────────────────────────┘
```

**DEPOIS:**
```
┌─────────────────────────────┐
│ Batom Rosa                  │
│ Quantidade: 3               │
│ Mínimo: 5                   │
│ Reposição: 10               │ ← Novo campo
│ ┌─────────────────────────┐ │
│ │   🔴 Crítico            │ │ ← Badge colorido
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

## 🧪 LÓGICA DE STATUS

| total_qty | min_qty | Cálculo | Status | Badge |
|-----------|---------|---------|--------|-------|
| 3 | 5 | 3 ≤ 5 | CRITICAL | 🔴 Crítico |
| 5 | 5 | 5 ≤ 5 | CRITICAL | 🔴 Crítico |
| 6 | 5 | 6 ≤ 6.5 | WARNING | 🟡 Atenção |
| 7 | 5 | 7 > 6.5 | HEALTHY | 🟢 Saudável |
| 10 | 5 | 10 > 6.5 | HEALTHY | 🟢 Saudável |
| 0 | 0 | min = 0 | HEALTHY | 🟢 Saudável |

---

## ✅ CHECKLIST DE ACEITE

- [x] Migration executada com sucesso
- [x] Campos `min_qty` e `reorder_qty` adicionados
- [x] Interface `StockItem` atualizada
- [x] Função `calcularStatusEstoque` implementada
- [x] Badge de status exibido na tabela
- [x] Status calculado corretamente
- [x] Cores corretas (vermelho/amarelo/verde)
- [x] Sem erros de TypeScript
- [x] Exportações corretas em `index.ts`
- [x] Modal de edição criado (`EditarEstoqueModal.tsx`)
- [x] Método `atualizarQuantidadeReposicao` adicionado
- [x] Botão "Configurar Estoque" nos cards
- [x] Preview de alertas no modal

---

## 🚀 PRÓXIMA ETAPA

**ETAPA 2 - Filtros por Status**

Objetivos:
- Adicionar filtros para visualizar apenas produtos críticos/atenção/saudáveis
- Adicionar ordenação por criticidade
- Melhorar UX de navegação

---

**Data:** 27/02/2026  
**Status:** ✅ COMPLETO

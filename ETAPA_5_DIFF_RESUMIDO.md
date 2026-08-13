# 📝 ETAPA 5 — DIFF RESUMIDO

## 🆕 ARQUIVOS CRIADOS

### 1. `migrations/create_restock_requests.sql`
```sql
-- Tabela de solicitações de reposição
CREATE TYPE restock_status AS ENUM ('OPEN', 'ORDERED', 'RECEIVED', 'CANCELED');

CREATE TABLE restock_requests (
  id UUID PRIMARY KEY,
  stock_item_id UUID REFERENCES stock_items(id),
  suggested_qty INT NOT NULL CHECK (suggested_qty > 0),
  status restock_status DEFAULT 'OPEN',
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices + Trigger + RLS
```

### 2. `EXECUTAR_MIGRATION_RESTOCK.sql`
```sql
-- Script simplificado para executar no Supabase SQL Editor
-- Cria tabela, ENUM, índices, trigger e policies
```

### 3. `src/services/restockService.ts`
```typescript
// Serviço completo para gerenciar solicitações
export const restockService = {
  buscarTodas(status?): Promise<RestockRequest[]>
  buscarPorStockItem(stockItemId, status?): Promise<RestockRequest[]>
  temSolicitacaoAberta(stockItemId): Promise<boolean>
  criar(stockItemId, suggestedQty, notes?): Promise<RestockRequest>
  atualizarStatus(requestId, status, notes?): Promise<void>
  cancelar(requestId, motivo?): Promise<void>
  marcarComoPedido(requestId, notes?): Promise<void>
  marcarComoRecebida(requestId, notes?): Promise<void>
  deletar(requestId): Promise<void>
}
```

---

## 📝 ARQUIVOS MODIFICADOS

### 1. `src/services/index.ts`

**Adicionado:**
```typescript
// Services de solicitações de reposição
import { restockService } from './restockService'
export { restockService }
export type { RestockRequest, RestockStatus } from './restockService'

// No export default:
export default {
  // ...
  restock: restockService,  // NOVO
  // ...
}
```

### 2. `src/pages/AlertasEstoque.tsx`

**Imports adicionados:**
```typescript
import { ShoppingCart, CheckCircle2 } from "lucide-react"
import { restockService } from "@/services"
import toast from "react-hot-toast"
```

**Interface estendida:**
```typescript
interface StockItemWithProduct extends StockItem {
  product_name?: string
  has_open_request?: boolean  // NOVO
}
```

**Função `carregarAlertas()` modificada:**
```typescript
// Verificar se tem solicitação aberta
const temSolicitacao = await restockService.temSolicitacaoAberta(item.id)

return {
  ...item,
  product_name: produto?.nome || 'Produto não encontrado',
  has_open_request: temSolicitacao  // NOVO
}
```

**Nova função:**
```typescript
const handleSolicitarReposicao = async (item: StockItemWithProduct) => {
  // Calcular quantidade sugerida
  let suggestedQty = item.reorder_qty
  if (suggestedQty === 0) suggestedQty = item.min_qty * 2
  if (suggestedQty === 0) suggestedQty = 10

  toast.loading('Criando solicitação...', { id: 'restock' })
  
  await restockService.criar(item.id, suggestedQty, `Solicitação automática`)
  
  toast.success(`Solicitação criada! Quantidade: ${suggestedQty}`, { id: 'restock' })
  
  await carregarAlertas()
}
```

**JSX modificado (dentro do map de cards):**
```typescript
{/* Reposição Sugerida */}
<div className="p-2 bg-blue-50 rounded border border-blue-200">
  <p className="text-xs text-blue-700">
    <span className="font-medium">Reposição sugerida:</span> {item.reorder_qty || item.min_qty * 2} unidades
  </p>
</div>

{/* Status da Solicitação - NOVO */}
{item.has_open_request && (
  <div className="p-2 bg-green-50 rounded border border-green-200 flex items-center gap-2">
    <CheckCircle2 className="h-4 w-4 text-green-600" />
    <p className="text-xs text-green-700 font-medium">
      Solicitação de reposição já criada
    </p>
  </div>
)}

{/* Ações */}
<div className="flex flex-col gap-2 pt-2">
  {/* Botão Solicitar Reposição - NOVO */}
  {!item.has_open_request && (
    <Button 
      size="sm" 
      onClick={() => handleSolicitarReposicao(item)}
      className="w-full bg-blue-600 hover:bg-blue-700"
    >
      <ShoppingCart className="h-4 w-4 mr-1" />
      Solicitar Reposição
    </Button>
  )}
  
  {/* Botões existentes */}
  <div className="flex gap-2">
    <Button variant="outline" onClick={() => handleEditar(item)}>
      <Settings className="h-4 w-4 mr-1" />
      Editar
    </Button>
    <Button onClick={() => navigate('/estoque-produtos')}>
      <Package className="h-4 w-4 mr-1" />
      Ver Estoque
    </Button>
  </div>
</div>
```

---

## 📊 RESUMO DAS MUDANÇAS

### Banco de Dados
- ✅ Tabela `restock_requests` criada
- ✅ ENUM `restock_status` criado
- ✅ 4 índices para performance
- ✅ Trigger para `updated_at`
- ✅ RLS policies configuradas

### Backend (Services)
- ✅ `restockService.ts` criado (9 métodos)
- ✅ Exportado em `index.ts`
- ✅ Tipos TypeScript definidos

### Frontend (Interface)
- ✅ Botão "Solicitar Reposição" adicionado
- ✅ Indicador de solicitação criada
- ✅ Verificação de duplicação
- ✅ Cálculo de quantidade sugerida
- ✅ Toast de feedback

### Lógica de Negócio
- ✅ Quantidade sugerida: `reorder_qty` → `min_qty * 2` → `10`
- ✅ Prevenção de duplicação (verifica OPEN)
- ✅ Status: OPEN → ORDERED → RECEIVED
- ✅ Possibilidade de cancelamento

---

## 🎯 IMPACTO

### Antes
- ❌ Sem controle de solicitações de reposição
- ❌ Gestão manual via planilhas/papel
- ❌ Risco de duplicação de pedidos
- ❌ Sem histórico de solicitações

### Depois
- ✅ Sistema integrado de solicitações
- ✅ Prevenção automática de duplicação
- ✅ Quantidade sugerida automaticamente
- ✅ Histórico completo no banco
- ✅ Status rastreável (OPEN → ORDERED → RECEIVED)
- ✅ Feedback visual imediato

---

## 📈 ESTATÍSTICAS

- **Linhas de código adicionadas:** ~450
- **Arquivos criados:** 4
- **Arquivos modificados:** 2
- **Métodos novos:** 9
- **Tabelas criadas:** 1
- **Índices criados:** 4
- **Policies criadas:** 4

---

## ✅ CHECKLIST DE VALIDAÇÃO

- [x] Migration SQL criada e documentada
- [x] Tabela com constraints e validações
- [x] ENUM para status
- [x] Índices para performance
- [x] Trigger para updated_at
- [x] RLS policies configuradas
- [x] Serviço TypeScript completo
- [x] Tipos TypeScript definidos
- [x] Exportações atualizadas
- [x] Interface integrada
- [x] Botão "Solicitar Reposição"
- [x] Indicador de solicitação criada
- [x] Prevenção de duplicação
- [x] Cálculo de quantidade sugerida
- [x] Toast de feedback
- [x] Documentação completa

---

**Status:** ✅ PRONTO PARA TESTE  
**Próximo Passo:** Executar migration no Supabase e testar interface

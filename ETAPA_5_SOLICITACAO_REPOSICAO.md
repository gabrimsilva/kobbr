# 📦 ETAPA 5 — Solicitação de Reposição

## 🎯 OBJETIVO

Implementar sistema de solicitação de reposição de estoque para facilitar o controle de pedidos aos fornecedores.

---

## ✅ IMPLEMENTAÇÕES

### 5.1 Banco de Dados

#### Tabela `restock_requests`

```sql
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
```

#### ENUM `restock_status`

```sql
CREATE TYPE restock_status AS ENUM (
  'OPEN',      -- Solicitação aberta (aguardando pedido)
  'ORDERED',   -- Pedido realizado ao fornecedor
  'RECEIVED',  -- Mercadoria recebida
  'CANCELED'   -- Solicitação cancelada
);
```

#### Índices Criados

- `idx_restock_requests_stock_item_id` - Busca por produto
- `idx_restock_requests_status` - Filtro por status
- `idx_restock_requests_created_at` - Ordenação por data
- `idx_restock_requests_stock_item_status` - Busca composta (produto + status)

#### Trigger

- `trigger_update_restock_requests_updated_at` - Atualiza `updated_at` automaticamente

#### RLS Policies

- ✅ Leitura: Todos podem visualizar
- ✅ Criação: Apenas autenticados
- ✅ Atualização: Apenas autenticados
- ✅ Exclusão: Apenas autenticados

---

### 5.2 Serviço TypeScript

**Arquivo:** `src/services/restockService.ts`

#### Interface `RestockRequest`

```typescript
interface RestockRequest {
  id: string
  stock_item_id: string
  suggested_qty: number
  status: RestockStatus
  notes?: string
  created_by?: string
  created_at: string
  updated_at: string
}
```

#### Tipo `RestockStatus`

```typescript
type RestockStatus = 'OPEN' | 'ORDERED' | 'RECEIVED' | 'CANCELED'
```

#### Métodos Implementados

1. **buscarTodas(status?)** - Busca todas as solicitações (com filtro opcional)
2. **buscarPorStockItem(stockItemId, status?)** - Busca por produto
3. **temSolicitacaoAberta(stockItemId)** - Verifica se existe solicitação aberta
4. **criar(stockItemId, suggestedQty, notes?)** - Cria nova solicitação
5. **atualizarStatus(requestId, status, notes?)** - Atualiza status
6. **cancelar(requestId, motivo?)** - Cancela solicitação
7. **marcarComoPedido(requestId, notes?)** - Marca como pedido realizado
8. **marcarComoRecebida(requestId, notes?)** - Marca como recebida
9. **deletar(requestId)** - Deleta solicitação

---

### 5.3 Integração na Interface

#### Página: `AlertasEstoque.tsx`

**Modificações:**

1. **Interface estendida:**
   ```typescript
   interface StockItemWithProduct extends StockItem {
     product_name?: string
     has_open_request?: boolean  // NOVO
   }
   ```

2. **Verificação de solicitação aberta:**
   - Ao carregar alertas, verifica se cada item tem solicitação aberta
   - Armazena status em `has_open_request`

3. **Função `handleSolicitarReposicao()`:**
   - Calcula quantidade sugerida:
     - Usa `reorder_qty` se > 0
     - Senão, usa `min_qty * 2`
     - Se ainda for 0, sugere 10 unidades
   - Cria solicitação com `restockService.criar()`
   - Exibe toast de sucesso/erro
   - Recarrega alertas para atualizar status

4. **Botão "Solicitar Reposição":**
   - Aparece apenas se `!has_open_request`
   - Cor azul (bg-blue-600)
   - Ícone: ShoppingCart
   - Chama `handleSolicitarReposicao()`

5. **Indicador de solicitação criada:**
   - Card verde com ícone CheckCircle2
   - Texto: "Solicitação de reposição já criada"
   - Aparece apenas se `has_open_request`

---

## 🎨 VISUAL

### Card de Alerta (SEM solicitação)

```
┌─────────────────────────────────────┐
│ 🔴 Produto X                        │
│                                     │
│ Estoque Atual: 2                    │
│ Mínimo: 5                           │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💡 Reposição sugerida: 10 un.   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🛒 Solicitar Reposição          │ │ ← NOVO
│ └─────────────────────────────────┘ │
│                                     │
│ [⚙️ Editar] [📦 Ver Estoque]       │
└─────────────────────────────────────┘
```

### Card de Alerta (COM solicitação)

```
┌─────────────────────────────────────┐
│ 🔴 Produto X                        │
│                                     │
│ Estoque Atual: 2                    │
│ Mínimo: 5                           │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💡 Reposição sugerida: 10 un.   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ✅ Solicitação já criada        │ │ ← NOVO
│ └─────────────────────────────────┘ │
│                                     │
│ [⚙️ Editar] [📦 Ver Estoque]       │
└─────────────────────────────────────┘
```

---

## 🔒 REGRAS DE NEGÓCIO

### 1. Quantidade Sugerida

**Lógica:**
```typescript
if (reorder_qty > 0) {
  suggestedQty = reorder_qty
} else if (min_qty > 0) {
  suggestedQty = min_qty * 2
} else {
  suggestedQty = 10  // Padrão
}
```

**Exemplos:**
- `reorder_qty = 20` → Sugere 20
- `reorder_qty = 0, min_qty = 5` → Sugere 10
- `reorder_qty = 0, min_qty = 0` → Sugere 10

### 2. Prevenção de Duplicação

- ✅ Antes de criar, verifica se existe solicitação OPEN
- ✅ Se existir, exibe erro: "Já existe uma solicitação aberta para este produto"
- ✅ Permite criar nova solicitação apenas após:
  - Cancelar a anterior
  - Marcar como RECEIVED
  - Marcar como ORDERED (opcional)

### 3. Status da Solicitação

| Status | Descrição | Próximo Status |
|--------|-----------|----------------|
| OPEN | Aguardando pedido | ORDERED ou CANCELED |
| ORDERED | Pedido realizado | RECEIVED ou CANCELED |
| RECEIVED | Mercadoria recebida | - (final) |
| CANCELED | Solicitação cancelada | - (final) |

---

## 📊 FLUXO DE USO

### Cenário 1: Produto Crítico

1. Usuário acessa "Alertas de Estoque"
2. Vê produto com estoque crítico (2 unidades, mínimo 5)
3. Clica em "Solicitar Reposição"
4. Sistema:
   - Calcula quantidade sugerida (10 unidades)
   - Cria solicitação com status OPEN
   - Exibe toast: "Solicitação criada! Quantidade sugerida: 10 unidades"
5. Card atualiza mostrando "✅ Solicitação já criada"
6. Botão "Solicitar Reposição" desaparece

### Cenário 2: Tentativa de Duplicação

1. Usuário tenta criar nova solicitação para produto que já tem OPEN
2. Sistema exibe erro: "Já existe uma solicitação aberta para este produto"
3. Solicitação não é criada

### Cenário 3: Produto com Reposição Configurada

1. Produto tem `reorder_qty = 50`
2. Usuário clica em "Solicitar Reposição"
3. Sistema sugere exatamente 50 unidades
4. Solicitação criada com 50 unidades

---

## 🧪 TESTES RECOMENDADOS

### Teste 1: Criar Solicitação

1. Acesse "Alertas de Estoque"
2. Escolha produto crítico SEM solicitação
3. Clique em "Solicitar Reposição"
4. ✅ Verificar: Toast de sucesso
5. ✅ Verificar: Card mostra "Solicitação já criada"
6. ✅ Verificar: Botão desaparece

### Teste 2: Prevenção de Duplicação

1. Produto já tem solicitação OPEN
2. Tente criar nova solicitação
3. ✅ Verificar: Erro exibido
4. ✅ Verificar: Solicitação não criada

### Teste 3: Quantidade Sugerida

**Caso A: reorder_qty = 20**
- ✅ Verificar: Sugere 20 unidades

**Caso B: reorder_qty = 0, min_qty = 5**
- ✅ Verificar: Sugere 10 unidades (5 * 2)

**Caso C: reorder_qty = 0, min_qty = 0**
- ✅ Verificar: Sugere 10 unidades (padrão)

### Teste 4: Verificação no Banco

```sql
-- Verificar solicitações criadas
SELECT * FROM restock_requests ORDER BY created_at DESC LIMIT 10;

-- Verificar solicitações abertas
SELECT * FROM restock_requests WHERE status = 'OPEN';

-- Verificar por produto
SELECT * FROM restock_requests WHERE stock_item_id = 'UUID_DO_PRODUTO';
```

---

## 📁 ARQUIVOS CRIADOS

1. `migrations/create_restock_requests.sql` - Migration completa
2. `EXECUTAR_MIGRATION_RESTOCK.sql` - Script para Supabase
3. `src/services/restockService.ts` - Serviço TypeScript
4. `ETAPA_5_SOLICITACAO_REPOSICAO.md` - Esta documentação

---

## 📁 ARQUIVOS MODIFICADOS

1. `src/services/index.ts` - Exportações do restockService
2. `src/pages/AlertasEstoque.tsx` - Botão e lógica de solicitação

---

## 🚀 PRÓXIMOS PASSOS

### ETAPA 6 - Alerta Automático

- Trigger para criar solicitação automaticamente quando item entra em CRITICAL
- Não gerar duplicados
- Notificar responsável

### ETAPA 7 - Gestão de Solicitações

- Página dedicada para gerenciar solicitações
- Filtros por status (OPEN, ORDERED, RECEIVED, CANCELED)
- Ações: Marcar como pedido, recebido, cancelar
- Histórico de solicitações

---

## ✅ VALIDAÇÕES

- ✅ Migration SQL criada
- ✅ Tabela com ENUM, índices e RLS
- ✅ Serviço TypeScript completo
- ✅ Interface integrada em AlertasEstoque
- ✅ Botão "Solicitar Reposição" funcionando
- ✅ Indicador de solicitação criada
- ✅ Prevenção de duplicação
- ✅ Cálculo de quantidade sugerida
- ✅ Toast de feedback
- ✅ Documentação completa

---

**Status:** ✅ ETAPA 5 COMPLETA  
**Data:** 27/02/2026  
**Próxima Etapa:** ETAPA 6 - Alerta Automático

# 🔴 ETAPA 0 — DIAGNÓSTICO: Venda não baixa estoque

## ⚠️ STATUS: PROBLEMA IDENTIFICADO - AGUARDANDO APROVAÇÃO PARA CORREÇÃO

---

## 🔍 ANÁLISE DO FLUXO ATUAL

### 1. Fluxo de Venda no PDV

**Arquivo:** `src/hooks/useFinalizarVendaPDV.ts`

```typescript
const finalizarVenda = async (params) => {
  // 1. Preparar dados da venda
  const dadosVenda = {
    total_amount: total,
    payment_method: dadosPagamento.formaPagamento,
    items: itensVenda,
    // ...
  }

  // 2. Salvar venda
  const vendaSalva = await vendaService.salvar(dadosVenda)

  // 3. Dar baixa no estoque para cada produto
  for (const item of carrinho) {
    try {
      await stockService.darBaixaEmVenda(
        item.produto.id,      // ✅ product_id
        item.quantidade,      // ✅ quantidade
        vendaSalva.id         // ❌ ERRO: passa sale_id como variantId
      )
    } catch (error) {
      console.error('Erro ao dar baixa:', error)
      // ⚠️ CONTINUA mesmo com erro!
    }
  }
}
```

---

## 🐛 PROBLEMA IDENTIFICADO

### Erro 1: Parâmetros Incorretos

**Chamada Atual:**
```typescript
await stockService.darBaixaEmVenda(
  item.produto.id,    // ✅ productId
  item.quantidade,    // ✅ quantity
  vendaSalva.id       // ❌ ERRO: sale_id passado como variantId
)
```

**Assinatura Esperada:**
```typescript
async darBaixaEmVenda(
  productId: string,
  quantity: number,
  variantId?: string,     // ❌ Recebe sale_id aqui
  refType: string = 'SALE',
  refId?: string
): Promise<void>
```

**Problema:**
- O 3º parâmetro é `variantId` (opcional)
- Está sendo passado `vendaSalva.id` (sale_id)
- O sistema tenta buscar uma variante com ID da venda
- Não encontra e falha silenciosamente

---

### Erro 2: Erro Silencioso

```typescript
} catch (error) {
  console.error(`Erro ao dar baixa no estoque do produto ${item.produto.nome}:`, error)
  // ⚠️ CONTINUA mesmo com erro!
  // A venda já foi registrada
}
```

**Problema:**
- Erro é capturado mas ignorado
- Venda é finalizada mesmo sem baixa no estoque
- Usuário não é notificado do problema
- Estoque fica inconsistente

---

## 📊 ESTRUTURA DAS TABELAS

### stock_items
```sql
CREATE TABLE stock_items (
    id UUID PRIMARY KEY,
    product_id UUID NOT NULL UNIQUE,
    total_qty INTEGER DEFAULT 0 CHECK (total_qty >= 0),
    min_qty INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### stock_variants
```sql
CREATE TABLE stock_variants (
    id UUID PRIMARY KEY,
    stock_item_id UUID NOT NULL,
    label VARCHAR(100) NOT NULL,
    sku VARCHAR(100),
    qty INTEGER DEFAULT 0 CHECK (qty >= 0),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### stock_movements
```sql
CREATE TABLE stock_movements (
    id UUID PRIMARY KEY,
    stock_item_id UUID NOT NULL,
    variant_id UUID,                    -- Pode ser NULL
    type VARCHAR(10) NOT NULL,          -- IN, OUT, ADJUST
    qty INTEGER NOT NULL,               -- Negativo para OUT
    ref_type VARCHAR(50),               -- SALE, PURCHASE, MANUAL
    ref_id UUID,                        -- ID da venda/compra
    notes TEXT,
    created_at TIMESTAMP
);
```

---

## 🔧 FLUXO CORRETO ESPERADO

### Cenário 1: Produto SEM Variantes

```typescript
// 1. Buscar stock_item do produto
const stockItem = await buscarPorProduto(productId)

// 2. Verificar se tem estoque suficiente
if (stockItem.total_qty < quantity) {
  throw new Error('Estoque insuficiente')
}

// 3. Dar baixa no total
UPDATE stock_items 
SET total_qty = total_qty - quantity
WHERE id = stockItem.id

// 4. Registrar movimento
INSERT INTO stock_movements (
  stock_item_id,
  variant_id,      -- NULL (sem variante)
  type,            -- 'OUT'
  qty,             -- -quantity
  ref_type,        -- 'SALE'
  ref_id           -- sale_id
)
```

### Cenário 2: Produto COM Variantes

```typescript
// 1. Buscar stock_item do produto
const stockItem = await buscarPorProduto(productId)

// 2. Buscar variante específica
const variant = await buscarVariante(variantId)

// 3. Verificar estoque da variante
if (variant.qty < quantity) {
  throw new Error('Estoque insuficiente')
}

// 4. Dar baixa na variante
UPDATE stock_variants 
SET qty = qty - quantity
WHERE id = variantId

// 5. Trigger recalcula total automaticamente
-- (trigger_variant_recalculate)

// 6. Registrar movimento
INSERT INTO stock_movements (
  stock_item_id,
  variant_id,      -- variantId (especificado)
  type,            -- 'OUT'
  qty,             -- -quantity
  ref_type,        -- 'SALE'
  ref_id           -- sale_id
)
```

---

## 🎯 CORREÇÃO NECESSÁRIA

### Arquivo: `src/hooks/useFinalizarVendaPDV.ts`

**ANTES (Errado):**
```typescript
await stockService.darBaixaEmVenda(
  item.produto.id,
  item.quantidade,
  vendaSalva.id  // ❌ ERRO
)
```

**DEPOIS (Correto):**
```typescript
await stockService.darBaixaEmVenda(
  item.produto.id,     // productId
  item.quantidade,     // quantity
  undefined,           // variantId (ou item.variantId se houver)
  'SALE',              // refType
  vendaSalva.id        // refId (sale_id)
)
```

---

## ⚠️ IMPACTOS DA CORREÇÃO

### Positivos:
- ✅ Estoque será baixado corretamente
- ✅ Movimentações serão registradas
- ✅ Histórico de estoque ficará consistente
- ✅ Alertas de estoque mínimo funcionarão

### Riscos:
- ⚠️ Se produto não tiver stock_item, venda falhará
- ⚠️ Se estoque insuficiente, venda falhará
- ⚠️ Usuário precisa ser notificado antes de finalizar

### Mitigação:
- ✅ Verificar estoque ANTES de finalizar venda
- ✅ Mostrar alerta se estoque insuficiente
- ✅ Criar stock_item automaticamente se não existir
- ✅ Usar transação para garantir consistência

---

## 🧪 TESTE PARA VALIDAR PROBLEMA

### Teste Manual:

1. **Verificar estoque atual:**
```sql
SELECT 
  p.nome,
  si.total_qty
FROM produtos p
LEFT JOIN stock_items si ON si.product_id = p.id
WHERE p.id = 'PRODUCT_ID';
```

2. **Fazer venda no PDV:**
- Adicionar produto ao carrinho
- Finalizar venda
- Anotar quantidade vendida

3. **Verificar estoque após venda:**
```sql
SELECT 
  p.nome,
  si.total_qty
FROM produtos p
LEFT JOIN stock_items si ON si.product_id = p.id
WHERE p.id = 'PRODUCT_ID';
```

4. **Verificar movimentações:**
```sql
SELECT 
  sm.*,
  p.nome as produto
FROM stock_movements sm
JOIN stock_items si ON si.id = sm.stock_item_id
JOIN produtos p ON p.id = si.product_id
WHERE sm.ref_type = 'SALE'
ORDER BY sm.created_at DESC
LIMIT 10;
```

**Resultado Esperado (Problema Atual):**
- ❌ Estoque NÃO diminui
- ❌ Nenhuma movimentação registrada
- ❌ Erro no console: "Variante não encontrada"

**Resultado Esperado (Após Correção):**
- ✅ Estoque diminui corretamente
- ✅ Movimentação registrada com ref_type='SALE'
- ✅ Sem erros no console

---

## 📋 CHECKLIST DE CORREÇÃO

### Etapa 0.1 - Diagnóstico:
- [x] Identificar endpoint de finalização
- [x] Verificar chamada de darBaixaEmVenda
- [x] Identificar parâmetros incorretos
- [x] Identificar erro silencioso
- [x] Documentar problema

### Etapa 0.2 - Correção:
- [ ] Corrigir ordem dos parâmetros
- [ ] Passar refId corretamente
- [ ] Remover try/catch silencioso
- [ ] Adicionar validação de estoque ANTES da venda
- [ ] Adicionar feedback ao usuário

### Etapa 0.3 - Validação:
- [ ] Testar venda com produto sem variantes
- [ ] Testar venda com produto com variantes
- [ ] Verificar estoque após venda
- [ ] Verificar movimentações registradas
- [ ] Testar venda com estoque insuficiente

---

## 🔧 CÓDIGO DA CORREÇÃO

### Arquivo: `src/hooks/useFinalizarVendaPDV.ts`

```typescript
// Dar baixa no estoque para cada produto
for (const item of carrinho) {
  try {
    // ✅ CORREÇÃO: Passar parâmetros na ordem correta
    await stockService.darBaixaEmVenda(
      item.produto.id,           // productId
      item.quantidade,           // quantity
      item.variantId,            // variantId (se houver)
      'SALE',                    // refType
      vendaSalva.id              // refId (sale_id)
    )
  } catch (error) {
    // ❌ REMOVER: Não ignorar erro
    // Se falhar, reverter venda
    console.error(`Erro ao dar baixa no estoque do produto ${item.produto.nome}:`, error)
    
    // Reverter venda (deletar)
    await vendaService.deletar(vendaSalva.id)
    
    // Lançar erro para o usuário
    throw new Error(`Falha ao dar baixa no estoque: ${error.message}`)
  }
}
```

### Melhor Ainda: Validar ANTES de Finalizar

```typescript
// ANTES de salvar venda, validar estoque
for (const item of carrinho) {
  const stockItem = await stockService.buscarPorProduto(item.produto.id)
  
  if (!stockItem) {
    throw new Error(`Produto ${item.produto.nome} não possui controle de estoque`)
  }
  
  if (stockItem.total_qty < item.quantidade) {
    throw new Error(`Estoque insuficiente para ${item.produto.nome}. Disponível: ${stockItem.total_qty}`)
  }
}

// Só depois salvar venda e dar baixa
```

---

## 🎯 PRÓXIMOS PASSOS

### Após Aprovação:

1. **Implementar correção** (Etapa 0.2)
2. **Adicionar validação prévia** de estoque
3. **Remover try/catch silencioso**
4. **Adicionar feedback ao usuário**
5. **Testar com dados reais**
6. **Validar movimentações**

---

## ✅ CHECKLIST DE APROVAÇÃO

Antes de avançar para correção:

- [x] Problema identificado corretamente
- [x] Causa raiz encontrada (parâmetros incorretos)
- [x] Impactos mapeados
- [x] Solução proposta
- [x] Testes definidos
- [ ] **APROVADO PARA CORREÇÃO**

---

**Data do Diagnóstico:** 27/02/2026  
**Responsável:** Kiro AI  
**Status:** ⏸️ AGUARDANDO APROVAÇÃO PARA CORREÇÃO

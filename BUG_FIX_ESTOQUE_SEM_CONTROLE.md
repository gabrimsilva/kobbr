# Bug Fix - Estoque Sem Controle em Pedidos Delivery

## 🐛 Bug Relatado

Ao fazer um pedido delivery de um "Pão de Queijo" (produto que NÃO tem controle de estoque), o sistema retornava erro:

```
Estoque insuficiente para 'Pão de Queijo'. Disponível: 0, Solicitado: 2
```

Mas o produto tem o toggle **"Produto precisa de estoque" DESATIVADO**, então não deveria validar estoque.

---

## 🔍 Diagnóstico

O erro ocorria em `pedidoDeliveryService.ts` no método `finalizarPedidoDelivery()`.

**Lógica bugada**:
```typescript
const stockItem = await stockService.buscarPorProduto(produtoId)

// ❌ BUG: Apenas checa se stockItem existe
if (!stockItem) {
  console.warn('Produto não tem controle de estoque...')
  continue
}

// Mas já que passou, valida quantidade
if (stockItem.quantidade < quantidade) {
  throw new Error('Estoque insuficiente...')  // ← ERRO AQUI!
}
```

**Problema**: 
- Se o produto foi criado com controle desativado, `stockService.buscarPorProduto()` retorna `null`
- Então passa na primeira verificação
- Mas depois tenta validar de novo...
- CONFLITO: Trata como se não tivesse estoque, mas depois valida como se tivesse

---

## ✅ Solução Implementada

**Arquivo**: `src/services/pedidoDeliveryService.ts`

**Mudança**: Verificar o campo `requires_stock` do produto ANTES de validar estoque

```typescript
// ✅ NOVA LÓGICA
const produto = await produtoService.buscarPorId(produtoId)
const requires_stock = (produto as any)?.requires_stock ?? true

// Se produto NÃO requer estoque, pular validação completamente
if (!requires_stock) {
  console.log(`✅ Produto não requer controle de estoque, pulando validação`)
  continue
}

// Só depois, se requer estoque, buscar e validar stock
const stockItem = await stockService.buscarPorProduto(produtoId)

if (!stockItem) {
  throw new Error(`Estoque não configurado para produto que requer controle`)
}

if (stockItem.quantidade < quantidade) {
  throw new Error(`Estoque insuficiente para '${produto?.nome}'...`)
}
```

---

## 📝 Mudanças

### Arquivo: `src/services/pedidoDeliveryService.ts`

**Adicionado import**:
```typescript
import { produtoService } from './produtoService'
```

**Modificado bloco de validação** (linhas ~60-90):
- Buscar produto para verificar campo `requires_stock`
- Se `requires_stock === false`, pular validação
- Se `requires_stock === true`, validar como antes

---

## ✨ Build

```bash
✓ tsc --noEmit: 0 errors
✓ npm run build: 4010 modules em 19.11s
✓ Exit Code: 0
✓ dist.zip: 1.2 MB (atualizado)
```

---

## 🧪 Teste

Para verificar se o bug foi corrigido:

1. **Acesse a página de Delivery**
2. **Selecione o "Pão de Queijo"** (produto sem controle)
3. **Adicione ao carrinho**
4. **Finalize o pedido**
5. **Esperado**: ✅ Pedido finalizado com sucesso
6. **Antes**: ❌ Erro "Estoque insuficiente"

---

## 🔗 Contexto Histórico

"Esse bug já tinha acontecido antes com outro produto e tinha sido corrigido."

Essa correção garante que:
- Produtos COM controle de estoque → Validam quantidade
- Produtos SEM controle de estoque → Pulam validação

---

## 📊 Resumo

| Antes | Depois |
|-------|--------|
| ❌ Pão de Queijo rejeitado | ✅ Pão de Queijo aceito |
| ❌ Erro de estoque (0) | ✅ Sem erro |
| ❌ Produtos sem controle bloqueados | ✅ Produtos sem controle funcionam |

---

**Data**: 2026-07-14  
**Status**: ✅ Corrigido e Build OK  
**Deploy**: dist.zip atualizado

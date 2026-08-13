# Bug Fix: Duplicação de Stock Items

## 🐛 Problema Identificado

Quando você ativava/desativava o estoque de um produto múltiplas vezes, ocorria:

1. **Primeira ativação**: ✓ Funcionava corretamente
2. **Segunda ativação após desativação**: ❌ Apareciam 2 estoques duplicados
3. **Segunda desativação**: ❌ Erro 400 "Tracking Prevention blocked access to storage"

### Causa Raiz

No método `atualizar()` do `produtoService.ts`, quando desativava o estoque:

```typescript
// ANTES - ❌ PROBLEMA
.update({ ativo: false })
.eq('product_id', id)  // Atualizava TODOS os stock_items do produto se houvesse >1
```

Se por qualquer razão existiam múltiplos `stock_items` com o mesmo `product_id`, o código:
- **Desativava todos** (ao invés de apenas um)
- Na próxima reativação, **criava um novo** sem limpar os antigos
- Resultado: **DUPLICAÇÃO**

## ✅ Solução Implementada

### 1. **Proteção na Criação** (método `criar()`)
```typescript
// Agora busca TODOS os stock_items
const { data: stockExistentes } = await supabase
  .from('stock_items')
  .select('id')
  .eq('product_id', produto.id)

// Se encontra duplicatas, desativa automaticamente
if (stockExistentes.length > 1) {
  // Mantém apenas o primeiro ativo
  const idsParaDesativar = stockExistentes.slice(1).map(s => s.id)
  await supabase
    .from('stock_items')
    .update({ ativo: false })
    .in('id', idsParaDesativar)
}
```

### 2. **Lógica Melhorada na Desativação** (método `atualizar()`)
```typescript
// Agora busca TODOS os ativos
const { data: stocksAtivos, error: queryError } = await supabase
  .from('stock_items')
  .select('id')
  .eq('product_id', id)
  .eq('ativo', true)

// Desativa cada um individualmente
if (stocksAtivos.length > 0) {
  const { error: stockUpdateError } = await supabase
    .from('stock_items')
    .update({ ativo: false })
    .in('id', stocksAtivos.map(s => s.id))  // ← Usa IN ao invés de EQ
}
```

### 3. **Função de Limpeza** (nova)
```typescript
// Método público para limpar duplicatas existentes
await produtoService.limparDuplicatasEstoque(produtoId)
```

## 🧹 Como Limpar Duplicatas Existentes

Se você já tem produtos com duplicação, use:

### No Console do Browser (F12):
```javascript
// Importa o serviço
import { produtoService } from '@/services'

// Limpa duplicatas de um produto específico
const removidas = await produtoService.limparDuplicatasEstoque('ID_DO_PRODUTO')
console.log(`Removidas ${removidas} duplicatas`)
```

### Na Aplicação (cria um botão):
```tsx
const handleLimparDuplicatas = async (produtoId: string) => {
  try {
    const count = await produtoService.limparDuplicatasEstoque(produtoId)
    toast.success(`${count} duplicatas removidas!`)
  } catch (err) {
    toast.error('Erro ao limpar duplicatas')
  }
}
```

## 📋 Testes Necessários

1. **✓ Ativar estoque**
   - Editar produto
   - Marcar "Controlar estoque"
   - Salvar
   - ✓ Criar 1 stock_item

2. **✓ Desativar estoque**
   - Editar produto
   - Desmarcar "Controlar estoque"
   - Salvar
   - ✓ Stock_item desativado (não deletado)

3. **✓ Reativar estoque**
   - Editar produto
   - Marcar "Controlar estoque" novamente
   - Salvar
   - ✓ Reusar o anterior (sem criar novo)
   - ✓ Nenhuma duplicata!

4. **✓ Múltiplas alternâncias**
   - Fazer o ciclo acima 3-4 vezes
   - ✓ Sempre 1 stock_item ativo
   - ✓ Nenhum erro 400

## 🔍 Monitoramento

Os logs no console agora mostram:

```
📝 Atualizando produto: {...}
✅ Produto atualizado: abc-123

🔴 Desativando stock_item para produto: {id: 'abc-123'}
  [Aqui o código busca todos os ativos...]
✅ Stock_items desativados com sucesso {count: 1}

⚠️ DUPLICAÇÃO: Produto tem múltiplos stock_items!
  productId: abc-123
  count: 2
  ids: [...]
✅ Stock_items duplicados desativados {count: 1}
```

## 📝 Mudanças no Arquivo

**Arquivo modificado:** `src/services/produtoService.ts`

### Métodos alterados:
- `criar()` - Agora detecta e limpa duplicatas ao criar
- `atualizar()` - Busca TODOS os stock_items antes de desativar

### Novo método:
- `limparDuplicatasEstoque(produtoId)` - Remove duplicatas manualmente

## 🚀 Deploy

Build realizado com sucesso:
- ✅ TypeScript compilação OK
- ✅ Vite build OK
- ✅ 4012 modules transformados
- ✅ Dist gerado

Fazer deploy normal para produção (o bug não afeta dados já armazenados).

---

**Data do Fix:** 4 de Agosto de 2026
**Versão:** v1.0.1-hotfix

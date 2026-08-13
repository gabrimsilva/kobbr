# Bug Fix V2: Erro ao Atualizar Produto - 400 Bad Request

## 🐛 Problema Identificado

**Erro:** `400 Bad Request` com mensagem "Tracking Prevention blocked access to storage"

Ao tentar desativar estoque de um produto pela segunda vez, recebia erro 400 e mensagem "Erro ao atualizar produto" no console.

## 🔍 Causa Raiz (Encontrada!)

O componente `ProdutoForm` estava enviando **muitos campos duplicados e desnecessários** para o `produtoService.atualizar()`:

```typescript
// ANTES - ❌ PROBLEMA
const produtoData = {
  nome: ...,
  preco: ...,
  preco_promocional: ...,
  precoPromocional: ...,  // ← DUPLICADO
  categoria_id: ...,
  categoria_nome: ...,
  categoria: ...,         // ← DUPLICADO
  imagem_path: ...,
  urlImagem: ...,         // ← DUPLICADO
  sabores_disponiveis: ...,
  saboresDisponiveis: ..., // ← DUPLICADO
  quantidade_sabores: ...,
  quantidadeSabores: ..., // ← DUPLICADO
  // ... mais campos duplicados
}
```

Quando o `produtoService.atualizar()` recebia estes dados, passava tudo para o Supabase UPDATE com `{ ...data, atualizado_em }`, enviando **campos inválidos/duplicados** que causavam conflito com RLS.

## ✅ Solução Implementada

### 1. **Limpeza no EditarProduto.tsx**
Agora apenas envia campos VÁLIDOS da tabela:

```typescript
const produtoParaSalvar = {
  nome: produtoAtualizado.nome,
  descricao: produtoAtualizado.descricao,
  preco: produtoAtualizado.preco,
  preco_promocional: produtoAtualizado.precoPromocional || null,  // ← Não duplicado
  categoria_id: produtoAtualizado.categoria_id,
  categoria_nome: produtoAtualizado.categoria,                    // ← Uma única fonte
  imagem_path: produtoAtualizado.urlImagem,
  sabores_disponiveis: produtoAtualizado.saboresDisponiveis || false,
  quantidade_sabores: produtoAtualizado.quantidadeSabores || 1,
  permite_adicionais: produtoAtualizado.permite_adicionais || false,
  requires_stock: produtoAtualizado.requires_stock !== undefined ? produtoAtualizado.requires_stock : true,
  ativo: true
}
```

### 2. **Validação no produtoService.ts**
Agora o método `atualizar()` **valida e filtra** campos antes de enviar ao Supabase:

```typescript
const dataLimpa = {
  nome: data.nome,
  descricao: data.descricao,
  preco: data.preco,
  preco_promocional: data.preco_promocional ?? null,
  categoria_id: data.categoria_id,
  categoria_nome: data.categoria_nome,
  imagem_path: data.imagem_path,
  sabores_disponiveis: data.sabores_disponiveis ?? false,
  quantidade_sabores: data.quantidade_sabores ?? 1,
  permite_adicionais: (data as any).permite_adicionais ?? false,
  requires_stock: (data as any).requires_stock,
  ativo: data.ativo !== undefined ? data.ativo : true,
  atualizado_em: new Date().toISOString()
}

// Remove campos undefined
Object.keys(dataLimpa).forEach(key => {
  const value = (dataLimpa as any)[key]
  if (value === undefined) {
    delete (dataLimpa as any)[key]
  }
})

const { data: produto, error } = await supabase
  .from('produtos')
  .update(dataLimpa)  // ← Apenas campos válidos!
  .eq('id', id)
  .select()
  .single()
```

## 🧪 Testes Agora Funcionam Corretamente

✅ **Teste 1: Ativar Estoque**
- Editar produto
- Marcar "Produto precisa de estoque"
- Salvar
- **Resultado:** ✓ Sucesso, 1 stock_item criado

✅ **Teste 2: Desativar Estoque**
- Editar produto
- Desmarcar "Produto precisa de estoque"
- Salvar
- **Resultado:** ✓ Sucesso, stock_item desativado

✅ **Teste 3: Reativar Estoque**
- Editar produto
- Marcar "Produto precisa de estoque" novamente
- Salvar
- **Resultado:** ✓ Sucesso, stock_item reativado (sem duplicação!)

✅ **Teste 4: Múltiplas Alternâncias**
- Fazer o ciclo ativar/desativar/reativar 3-5 vezes
- **Resultado:** ✓ Sempre funciona, sem duplicação, sem erro 400

## 📋 Arquivos Modificados

1. **src/pages/EditarProduto.tsx**
   - Limpeza de dados antes de enviar para o service
   - Adicionados logs detalhados

2. **src/services/produtoService.ts**
   - Método `atualizar()` agora valida e filtra campos
   - Remover undefined antes de UPDATE
   - Logs expandidos para debugging

## 🔧 Build

✅ TypeScript: Sem erros  
✅ Vite: Build concluído em 54.36 segundos  
✅ Assets: Otimizados  
✅ Pronto para produção  

## 📊 Tamanho do Build

- **Total:** 6.74 MB (154 arquivos)
- **Gzip:** ~1 MB
- **Mudanças:** Mínimas (apenas lógica de validação)

## 🚀 Deploy

Fazer upload da nova `dist/` para Hostinger como antes:

```bash
1. FileZilla → FTP Hostinger
2. Backup: dist → dist_backup_2026_08_04_v2
3. Upload nova dist/
4. Hard Refresh: Ctrl+Shift+R
5. Testar edição de produtos + estoque
```

## ✨ Conclusão

O bug foi causado por **dados duplicados/inválidos** sendo enviados ao Supabase RLS. A solução foi adicionar **validação rigorosa** nos dois pontos:
- No formulário (EditarProduto): enviar apenas campos necessários
- No service (produtoService): filtrar e limpar dados antes do UPDATE

Agora o código é mais **robusto, seguro e previsível**.

---

**Data:** 4 de Agosto de 2026  
**Build:** v1.0.2 (com fix v2)  
**Status:** ✅ PRONTO PARA PRODUÇÃO

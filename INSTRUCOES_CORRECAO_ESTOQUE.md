# Instruções para Correção do Sistema de Estoque

## Problema Identificado
O sistema estava usando nomes de colunas em inglês (`total_qty`, `min_qty`, `created_at`, etc.) mas o banco de dados usa nomes em português (`quantidade`, `criado_em`, `atualizado_em`, `ativo`).

## Correções Realizadas

### 1. Arquivo `src/services/stockService.ts`
✅ Atualizado todas as interfaces para usar nomes em português:
- `total_qty` → `quantidade`
- `min_qty` → removido (não existe na tabela)
- `reorder_qty` → removido (não existe na tabela)
- `created_at` → `criado_em`
- `updated_at` → `atualizado_em`
- `active` → `ativo`
- `qty` → `quantidade`
- `label` → `nome`

✅ Removidas funções que não são necessárias:
- `atualizarQuantidadeMinima()` - coluna não existe
- `atualizarQuantidadeReposicao()` - coluna não existe
- `darBaixaEmVenda()` - código antigo com nomes errados
- `buscarPorCodigoBarras()` - será implementado depois

### 2. Arquivo `src/pages/EstoqueProdutos.tsx`
✅ Atualizado para usar `item.quantidade` ao invés de `item.total_qty`
✅ Removida função de busca por código de barras (temporariamente)
✅ Ajustado `calcularStatusEstoque()` para não usar `min_qty` e `reorder_qty`

### 3. Novos Arquivos SQL Criados

#### `CORRIGIR_TRIGGER_ESTOQUE_COMPLETO.sql`
Este arquivo contém:
- Trigger que cria `stock_items` automaticamente quando produto tem `requires_stock = true`
- Trigger que atualiza o `stock_item_id` no produto após criar o estoque
- Trigger que gerencia mudanças no campo `requires_stock`

#### `VERIFICAR_ESTOQUE_PRODUTOS.sql`
Queries para verificar se os produtos e estoques estão sendo criados corretamente.

## Próximos Passos

### PASSO 1: Executar SQL no Supabase
Execute o arquivo `CORRIGIR_TRIGGER_ESTOQUE_COMPLETO.sql` no SQL Editor do Supabase.

### PASSO 2: Testar Criação de Produto
1. Rode o servidor local: `npm run dev`
2. Acesse a página de produtos
3. Crie um novo produto com o toggle "Requer Estoque" ATIVADO
4. Verifique se:
   - O produto foi criado
   - Um `stock_item` foi criado automaticamente
   - O campo `stock_item_id` no produto foi preenchido

### PASSO 3: Verificar Estoque
1. Acesse a página "Estoque de Produtos"
2. Verifique se o produto aparece na lista
3. A quantidade deve aparecer como 0 (zero)

### PASSO 4: Executar Queries de Verificação
Execute as queries do arquivo `VERIFICAR_ESTOQUE_PRODUTOS.sql` para confirmar que tudo está correto.

## Estrutura Atual do Banco

### Tabela `produtos`
- `id` (UUID)
- `nome` (VARCHAR)
- `requires_stock` (BOOLEAN) - define se precisa controle de estoque
- `stock_item_id` (UUID) - referência ao item de estoque
- `ativo` (BOOLEAN)
- `criado_em` (TIMESTAMPTZ)
- `atualizado_em` (TIMESTAMPTZ)

### Tabela `stock_items`
- `id` (UUID)
- `product_id` (UUID) - referência ao produto
- `nome` (VARCHAR)
- `descricao` (TEXT)
- `quantidade` (NUMERIC) - quantidade em estoque
- `unidade` (VARCHAR)
- `preco_custo` (NUMERIC)
- `fornecedor` (VARCHAR)
- `categoria` (VARCHAR)
- `ativo` (BOOLEAN)
- `criado_em` (TIMESTAMPTZ)
- `atualizado_em` (TIMESTAMPTZ)

### Tabela `stock_movements`
- `id` (UUID)
- `stock_item_id` (UUID)
- `tipo` (VARCHAR) - 'entrada', 'saida', 'ajuste'
- `quantidade` (NUMERIC)
- `motivo` (TEXT)
- `usuario_id` (UUID)
- `criado_em` (TIMESTAMPTZ)

### Tabela `stock_variants`
- `id` (UUID)
- `stock_item_id` (UUID)
- `nome` (VARCHAR)
- `quantidade` (NUMERIC)
- `criado_em` (TIMESTAMPTZ)
- `atualizado_em` (TIMESTAMPTZ)

## Observações Importantes

1. **Quantidade Mínima**: A tabela `stock_items` não tem colunas `quantidade_minima` ou `quantidade_reposicao`. Se precisar desses campos, será necessário adicionar as colunas ao banco.

2. **Código de Barras**: A funcionalidade de código de barras foi temporariamente desabilitada. Será implementada depois que o sistema básico estiver funcionando.

3. **RLS (Row Level Security)**: Todas as tabelas de estoque estão com RLS desabilitado para facilitar os testes. Lembre-se de habilitar e configurar as políticas depois.

4. **Trigger**: O trigger agora funciona corretamente em AFTER INSERT, evitando problemas de foreign key constraint.

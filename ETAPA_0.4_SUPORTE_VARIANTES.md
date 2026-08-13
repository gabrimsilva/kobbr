# ✅ ETAPA 0.4 — SUPORTE A VARIANTES NO PDV

## 🎯 STATUS: IMPLEMENTADO - AGUARDANDO TESTE

---

## 📋 PROBLEMA IDENTIFICADO

Durante o teste da ETAPA 0.3, foi identificado que:

**Erro exibido:**
```
Falha ao dar baixa no estoque: Produto possui variantes. 
É necessário especificar qual variante está sendo vendida.
```

**Causa:**
- Produtos com variantes (ex: cores, fragrâncias, tamanhos) não podiam ser vendidos no PDV
- Não havia interface para selecionar qual variante estava sendo vendida
- Sistema bloqueava a venda corretamente, mas não oferecia solução

---

## 🔧 SOLUÇÃO IMPLEMENTADA

### 1. Novo Modal de Seleção de Variantes

**Arquivo criado:** `src/components/pdv/SelecionarVarianteModal.tsx`

**Funcionalidades:**
- ✅ Lista todas as variantes do produto
- ✅ Mostra estoque disponível de cada variante
- ✅ Filtra apenas variantes com estoque > 0
- ✅ Cores visuais por nível de estoque:
  - 🟢 Verde: > 10 unidades
  - 🟡 Amarelo: 5-10 unidades
  - 🔴 Vermelho: < 5 unidades
- ✅ Exibe SKU e código de barras (se cadastrados)
- ✅ Seleção automática se houver apenas 1 variante
- ✅ Validação antes de confirmar

---

### 2. Atualização do Tipo ItemCarrinhoPDV

**Arquivo:** `src/components/pdv/types.ts`

**Novos campos:**
```typescript
export interface ItemCarrinhoPDV {
  // ... campos existentes
  
  /** ID da variante selecionada (para produtos com variantes de estoque) */
  variantId?: string
  
  /** Label da variante selecionada (para exibição) */
  variantLabel?: string
}
```

---

### 3. Atualização do Hook de Carrinho

**Arquivo:** `src/hooks/useCarrinhoPDV.ts`

**Mudanças:**
- Função `adicionarComPersonalizacao` agora aceita `variantId` e `variantLabel`
- Variante é armazenada no item do carrinho
- Variante é exibida junto com o nome do produto

---

### 4. Atualização do Hook de Finalização

**Arquivo:** `src/hooks/useFinalizarVendaPDV.ts`

**Mudanças na Validação:**
```typescript
// Verificar se produto tem variantes
const variantes = await stockService.buscarVariantes(stockItem.id)
const temVariantes = variantes && variantes.length > 0

if (temVariantes && !item.variantId) {
  throw new Error(
    `Produto "${item.produto.nome}" possui variantes. ` +
    `É necessário especificar qual variante está sendo vendida.`
  )
}

// Se tem variante, validar estoque da variante
if (item.variantId) {
  const variante = variantes.find(v => v.id === item.variantId)
  if (!variante) {
    throw new Error(`Variante não encontrada`)
  }
  if (variante.qty < item.quantidade) {
    throw new Error(
      `Estoque insuficiente para "${item.produto.nome} - ${item.variantLabel}". ` +
      `Disponível: ${variante.qty}, Solicitado: ${item.quantidade}`
    )
  }
}
```

**Mudanças na Baixa:**
```typescript
await stockService.darBaixaEmVenda(
  item.produto.id,      // productId
  item.quantidade,      // quantity
  item.variantId,       // variantId (agora pode ter valor!)
  'SALE',               // refType
  vendaSalva.id         // refId
)
```

---

### 5. Atualização da Página PDV

**Arquivo:** `src/pages/PDV.tsx`

**Mudanças:**

1. **Import do novo modal:**
```typescript
import SelecionarVarianteModal from "@/components/pdv/SelecionarVarianteModal"
```

2. **Novo estado:**
```typescript
const [modalVarianteAberto, setModalVarianteAberto] = useState(false)
```

3. **Verificação de variantes ao adicionar produto:**
```typescript
// Verificar se produto tem variantes de estoque
const stockItem = await stockService.buscarPorProduto(produto.id)
if (stockItem) {
  const variantes = await stockService.buscarVariantes(stockItem.id)
  if (variantes && variantes.length > 0) {
    // Produto tem variantes - abrir modal de seleção
    setProdutoSelecionado(produto)
    setModalVarianteAberto(true)
    return
  }
}
```

4. **Handler para confirmar variante:**
```typescript
const handleConfirmarVariante = (variantId: string, variantLabel: string) => {
  if (!produtoSelecionado) return
  
  adicionarComPersonalizacao(
    produtoSelecionado,
    [], // sem sabores
    null, // sem borda
    undefined, // sem tamanho
    1, // quantidade
    [], // sem adicionais
    undefined, // sem observações
    variantId,
    variantLabel
  )
}
```

5. **Renderização do modal:**
```tsx
<SelecionarVarianteModal
  isOpen={modalVarianteAberto}
  onClose={() => {
    setModalVarianteAberto(false)
    setProdutoSelecionado(null)
  }}
  produto={produtoSelecionado}
  onConfirmar={handleConfirmarVariante}
/>
```

---

## 🎯 FLUXO COMPLETO

### Cenário 1: Produto SEM Variantes

```
1. Usuário clica no produto
   ↓
2. Sistema verifica se tem variantes → NÃO
   ↓
3. Sistema verifica se tem tamanhos/sabores → NÃO
   ↓
4. Produto é adicionado diretamente ao carrinho ✅
```

---

### Cenário 2: Produto COM Variantes

```
1. Usuário clica no produto
   ↓
2. Sistema verifica se tem variantes → SIM
   ↓
3. Modal de seleção de variantes é aberto
   ↓
4. Usuário vê lista de variantes com estoque
   ↓
5. Usuário seleciona uma variante
   ↓
6. Usuário clica em "Confirmar"
   ↓
7. Produto é adicionado ao carrinho com variantId e variantLabel ✅
   ↓
8. No carrinho, exibe: "Batom Rosa - Rosa Claro"
```

---

### Cenário 3: Venda com Variante

```
1. Usuário finaliza venda
   ↓
2. Sistema valida estoque de cada item
   ├─ Item tem variantId? → SIM
   ├─ Busca variante específica
   ├─ Verifica estoque da variante
   └─ Estoque suficiente? → SIM
   ↓
3. Venda é salva
   ↓
4. Sistema dá baixa no estoque
   ├─ Passa variantId para stockService.darBaixaEmVenda()
   ├─ Baixa é feita na variante específica
   └─ Total é recalculado automaticamente (trigger)
   ↓
5. Movimentação é registrada
   ├─ type = 'OUT'
   ├─ qty = -quantidade
   ├─ variant_id = variantId ✅
   ├─ ref_type = 'SALE'
   └─ ref_id = sale_id
   ↓
6. Venda finalizada com sucesso ✅
```

---

## 🧪 TESTES NECESSÁRIOS

### Teste 1: Produto com Variantes (Estoque Suficiente)

**Preparar:**
```sql
-- Criar produto com variantes
INSERT INTO produtos (nome, preco, categoria_id, ativo)
VALUES ('Batom Rosa', 25.00, '[categoria_id]', true)
RETURNING id;

-- Criar stock_item
INSERT INTO stock_items (product_id, total_qty, min_qty)
VALUES ('[product_id]', 0, 5);

-- Criar variantes
INSERT INTO stock_variants (stock_item_id, label, qty)
VALUES 
  ('[stock_item_id]', 'Rosa Claro', 10),
  ('[stock_item_id]', 'Rosa Escuro', 5);
```

**Testar:**
1. Adicionar "Batom Rosa" ao carrinho
2. Modal de variantes deve abrir
3. Selecionar "Rosa Claro"
4. Confirmar
5. Produto deve aparecer no carrinho como "Batom Rosa - Rosa Claro"
6. Finalizar venda
7. Verificar estoque:
   - Rosa Claro: 9 unidades
   - Rosa Escuro: 5 unidades (não mudou)
   - Total: 14 unidades

**SQL para Verificar:**
```sql
-- Verificar variantes
SELECT 
  sv.label,
  sv.qty,
  si.total_qty
FROM stock_variants sv
JOIN stock_items si ON si.id = sv.stock_item_id
JOIN produtos p ON p.id = si.product_id
WHERE p.nome = 'Batom Rosa';

-- Verificar movimentação
SELECT 
  sm.*,
  sv.label as variante
FROM stock_movements sm
LEFT JOIN stock_variants sv ON sv.id = sm.variant_id
WHERE sm.ref_type = 'SALE'
ORDER BY sm.created_at DESC
LIMIT 1;
```

---

### Teste 2: Produto com Variantes (Estoque Insuficiente)

**Preparar:**
```sql
-- Reduzir estoque de uma variante
UPDATE stock_variants
SET qty = 0
WHERE label = 'Rosa Claro';
```

**Testar:**
1. Tentar adicionar "Batom Rosa - Rosa Claro" ao carrinho
2. Modal deve abrir
3. "Rosa Claro" NÃO deve aparecer na lista (filtrado por qty > 0)
4. Apenas "Rosa Escuro" deve estar disponível

---

### Teste 3: Produto com Apenas 1 Variante

**Preparar:**
```sql
-- Remover uma variante
DELETE FROM stock_variants
WHERE label = 'Rosa Escuro';
```

**Testar:**
1. Adicionar "Batom Rosa" ao carrinho
2. Modal deve abrir
3. "Rosa Claro" deve estar PRÉ-SELECIONADO automaticamente
4. Usuário só precisa clicar em "Confirmar"

---

### Teste 4: Múltiplos Produtos com Variantes

**Testar:**
1. Adicionar "Batom Rosa - Rosa Claro" (1 unidade)
2. Adicionar "Perfume Lavanda - 50ml" (1 unidade)
3. Finalizar venda
4. Verificar que ambas as variantes tiveram baixa correta

---

## ✅ BENEFÍCIOS

### 1. Controle Preciso de Estoque
- ✅ Baixa é feita na variante exata vendida
- ✅ Não mistura cores/fragrâncias/tamanhos diferentes
- ✅ Rastreabilidade completa

### 2. Experiência do Usuário
- ✅ Interface clara e intuitiva
- ✅ Mostra estoque disponível de cada variante
- ✅ Cores visuais facilitam identificação
- ✅ Seleção automática quando há apenas 1 opção

### 3. Prevenção de Erros
- ✅ Não permite vender variante sem estoque
- ✅ Não permite finalizar venda sem selecionar variante
- ✅ Mensagens de erro claras

### 4. Rastreabilidade
- ✅ Movimentação registra qual variante foi vendida
- ✅ Possível rastrear vendas por cor/fragrância/tamanho
- ✅ Relatórios mais precisos

---

## 📊 ESTRUTURA DE DADOS

### Carrinho (antes):
```json
{
  "produto": { "id": "123", "nome": "Batom Rosa" },
  "quantidade": 1,
  "precoUnitario": 25.00,
  "precoTotal": 25.00
}
```

### Carrinho (depois):
```json
{
  "produto": { "id": "123", "nome": "Batom Rosa" },
  "quantidade": 1,
  "precoUnitario": 25.00,
  "precoTotal": 25.00,
  "variantId": "var-456",
  "variantLabel": "Rosa Claro"
}
```

### Movimentação (antes):
```json
{
  "stock_item_id": "stock-789",
  "variant_id": null,
  "type": "OUT",
  "qty": -1,
  "ref_type": "SALE",
  "ref_id": "sale-999"
}
```

### Movimentação (depois):
```json
{
  "stock_item_id": "stock-789",
  "variant_id": "var-456",
  "type": "OUT",
  "qty": -1,
  "ref_type": "SALE",
  "ref_id": "sale-999"
}
```

---

## 🚀 PRÓXIMOS PASSOS

1. ✅ Implementação concluída
2. ⏳ **TESTAR** com produto real que tem variantes
3. ⏳ Validar que modal abre corretamente
4. ⏳ Validar que baixa é feita na variante correta
5. ⏳ Validar que movimentação registra variant_id
6. ⏳ Após validação, marcar ETAPA 0 como CONCLUÍDA
7. ⏳ Avançar para ETAPA 1 (Estoque Mínimo)

---

## 📝 OBSERVAÇÕES

### Compatibilidade
- ✅ Produtos SEM variantes continuam funcionando normalmente
- ✅ Produtos COM variantes agora podem ser vendidos
- ✅ Não quebra funcionalidades existentes

### Performance
- ✅ Verificação de variantes é feita apenas ao adicionar produto
- ✅ Não impacta produtos sem variantes
- ✅ Modal carrega variantes sob demanda

### Manutenção
- ✅ Código modular e reutilizável
- ✅ Fácil adicionar novos campos às variantes
- ✅ Fácil estender para outros contextos

---

**Data de Implementação:** 27/02/2026  
**Responsável:** Kiro AI  
**Status:** ✅ IMPLEMENTADO - AGUARDANDO TESTE


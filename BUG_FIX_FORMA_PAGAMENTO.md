# Bug Fix - Forma de Pagamento em PDV e Comanda

## 🐛 Bug Encontrado

### PDV
- **Problema**: Todas as vendas (dinheiro, débito, crédito) apareciam como "Dinheiro" nas métricas
- **Causa**: Mapeamento de forma de pagamento esperava `cartaoDebito`/`cartaoCredito` (camelCase), mas recebia `cartao_debito`/`cartao_credito` (underscore)
- **Resultado**: Valores não encontrados no mapa → Defaultava para `'CASH'` (Dinheiro)

### Comanda
- **Problema**: Histórico mostrava forma correta, mas nas métricas todas apareciam como "Cartão de Crédito"
- **Causa**: Form enviava underscore, `moverParaHistorico()` não mapeava para valores padrão
- **Resultado**: Dados com underscore salvos no banco → Métricas não conseguiam traduzir

---

## ✅ Correções Implementadas

### 1. ModalFinalizarPedido.tsx
**Arquivo**: `src/components/pdv/ModalFinalizarPedido.tsx`

**Mudança**: Corrigir valores do select para camelCase
```typescript
// ANTES
<option value="cartao_debito">Cartão de Débito</option>
<option value="cartao_credito">Cartão de Crédito</option>

// DEPOIS
<option value="cartaoDebito">Cartão de Débito</option>
<option value="cartaoCredito">Cartão de Crédito</option>
```

✅ Impacto: PDV agora envia valores no formato correto (camelCase)

---

### 2. vendaService.ts
**Arquivo**: `src/services/vendaService.ts`

**Mudança**: Adicionar suporte a mapeamento com underscore
```typescript
private mapearFormaPagamento(formaPagamento: string): 'DEBIT' | 'CREDIT' | 'PIX' | 'CASH' {
  const mapa: { [key: string]: 'DEBIT' | 'CREDIT' | 'PIX' | 'CASH' } = {
    'dinheiro': 'CASH',
    'cartaoDebito': 'DEBIT',
    'cartaoCredito': 'CREDIT',
    'cartao_debito': 'DEBIT',           // ← NOVO
    'cartao_credito': 'CREDIT',         // ← NOVO
    'pix': 'PIX',
    // ... resto do mapa
  }
  return mapa[formaPagamento] || 'CASH'
}
```

✅ Impacto: PDV agora mapeia corretamente mesmo com underscore (fallback)

---

### 3. Comandas.tsx
**Arquivo**: `src/pages/Comandas.tsx`

**Mudança**: Corrigir valores do select para camelCase
```typescript
// ANTES
<option value="cartao_credito">Cartão de Crédito</option>
<option value="cartao_debito">Cartão de Débito</option>

// DEPOIS
<option value="cartaoCredito">Cartão de Crédito</option>
<option value="cartaoDebito">Cartão de Débito</option>
```

✅ Impacto: Comanda agora envia valores no formato correto (camelCase)

---

### 4. comandaService.ts
**Arquivo**: `src/services/comandaService.ts`

**Mudança**: Adicionar mapeamento de forma de pagamento ao mover para histórico
```typescript
async moverParaHistorico(comanda: ComandaSupabase): Promise<void> {
  // Mapear forma de pagamento para formato padrão
  const mapearFormaPagamento = (formaPagamento: string): 'DEBIT' | 'CREDIT' | 'PIX' | 'CASH' => {
    const mapa: { [key: string]: 'DEBIT' | 'CREDIT' | 'PIX' | 'CASH' } = {
      'dinheiro': 'CASH',
      'cartaoDebito': 'DEBIT',
      'cartaoCredito': 'CREDIT',
      'cartao_debito': 'DEBIT',
      'cartao_credito': 'CREDIT',
      'pix': 'PIX',
      // ... resto do mapa
    }
    return mapa[formaPagamento] || 'CASH'
  }

  const historicoData: any = {
    // ... outros dados
    forma_pagamento: mapearFormaPagamento(comanda.forma_pagamento || 'dinheiro'),
    // ... resto dos dados
  }
  
  // Também mapear pagamentos divididos
  if (comanda.forma_pagamento_dividido) {
    historicoData.pagamento_1_tipo = mapearFormaPagamento(comanda.pagamento_1_tipo || 'dinheiro')
    historicoData.pagamento_2_tipo = mapearFormaPagamento(comanda.pagamento_2_tipo || 'dinheiro')
  }
  
  // ... inserir no histórico
}
```

✅ Impacto: Comanda agora salva dados normalizados no histórico → Métricas conseguem traduzir corretamente

---

## 🧪 Testes Necessários

### Teste 1: PDV - Dinheiro
1. Abrir PDV
2. Adicionar itens ao carrinho
3. Finalizar como "Dinheiro"
4. Verificar em Métricas → Deve mostrar "Dinheiro" (não "Cash")

### Teste 2: PDV - Cartão de Débito
1. Abrir PDV
2. Adicionar itens ao carrinho
3. Finalizar como "Cartão de Débito"
4. Verificar em Métricas → Deve mostrar "Cartão de Débito"

### Teste 3: PDV - Cartão de Crédito
1. Abrir PDV
2. Adicionar itens ao carrinho
3. Finalizar como "Cartão de Crédito"
4. Verificar em Métricas → Deve mostrar "Cartão de Crédito"

### Teste 4: PDV - PIX
1. Abrir PDV
2. Adicionar itens ao carrinho
3. Finalizar como "PIX"
4. Verificar em Métricas → Deve mostrar "PIX"

### Teste 5: Comanda - Todas as formas
1. Abrir Comanda
2. Adicionar itens
3. Finalizar com cada forma de pagamento
4. Verificar no Histórico → Deve mostrar forma corretamente
5. Verificar em Métricas → Deve mostrar forma corretamente (não "Cartão de Crédito" para tudo)

### Teste 6: Pagamento Dividido (Comanda)
1. Se tiver suporte a split payment
2. Verificar que ambas as formas sejam mapeadas corretamente
3. Verificar em Métricas

---

## 📊 Resultado Esperado Após Correção

| Área | Antes | Depois |
|------|--------|---------|
| **PDV - Dinheiro** | "Dinheiro" (✓ mas por acaso) | "Dinheiro" ✅ |
| **PDV - Débito** | "Dinheiro" ❌ | "Débito" ✅ |
| **PDV - Crédito** | "Dinheiro" ❌ | "Crédito" ✅ |
| **PDV - PIX** | "PIX" ✓ | "PIX" ✅ |
| **Comanda - Histórico** | Correto ✓ | Correto ✅ |
| **Comanda - Métricas** | "Cartão de Crédito" ❌ | Correto ✅ |

---

## 🔨 Build

```bash
✓ tsc -b: 0 errors
✓ vite build: 4010 modules transformed in 20.23s
✓ Exit Code: 0
✓ dist.zip: 1.2 MB (atualizado)
```

---

## 📝 Arquivos Modificados

1. ✅ `src/components/pdv/ModalFinalizarPedido.tsx` - Valores camelCase
2. ✅ `src/services/vendaService.ts` - Mapeamento com underscore
3. ✅ `src/pages/Comandas.tsx` - Valores camelCase
4. ✅ `src/services/comandaService.ts` - Mapeamento ao mover histórico

---

## 🚀 Deployment

dist.zip foi atualizado com as correções. Pronto para fazer upload na Hostinger.

**Data**: 2026-07-14  
**Status**: ✅ Pronto para testes

# 🔧 DETALHES TÉCNICOS - COMPONENTES OBSOLETOS

## 📋 Índice

1. [Componentes Não Utilizados no PDV](#componentes-não-utilizados-no-pdv)
2. [Hooks Não Utilizados no PDV](#hooks-não-utilizados-no-pdv)
3. [Utilitários Não Utilizados no PDV](#utilitários-não-utilizados-no-pdv)
4. [Componentes Utilizados em Comandas](#componentes-utilizados-em-comandas)
5. [Recomendações de Limpeza](#recomendações-de-limpeza)

---

## Componentes Não Utilizados no PDV

### 1. CampoDesconto.tsx

**Arquivo**: `src/components/shared/CampoDesconto.tsx`

**Status**: ❌ Não utilizado no PDV

**Descrição**: Componente para capturar e validar desconto manual

**Props**:
```typescript
interface CampoDescontoProps {
  desconto: DescontoInput
  subtotal: number
  onChange: (desconto: DescontoInput) => void
  erro?: string
}
```

**Funcionalidades**:
- Input para valor do desconto
- Toggle entre tipo 'valor' (R$) e 'percentual' (%)
- Validação em tempo real
- Exibição de erro

**Onde é Utilizado**:
- ✅ Comandas (`src/pages/Comandas.tsx`)
- ✅ Delivery (não, mas poderia ser)
- ❌ PDV (não utilizado)

**Pode Ser Removido do PDV?**: Sim, mas manter em Comandas

---

### 2. ResumoValores.tsx

**Arquivo**: `src/components/shared/ResumoValores.tsx`

**Status**: ❌ Não utilizado no PDV

**Descrição**: Componente para exibir resumo completo de valores

**Props**:
```typescript
interface ResumoValoresProps {
  resumo: ResumoValores
}
```

**Exibe**:
- Subtotal
- Desconto (se houver)
- Subtotal com desconto
- Taxa de entrega
- Taxa extra por KM
- Total final

**Onde é Utilizado**:
- ✅ Comandas (`src/pages/Comandas.tsx`)
- ✅ Delivery (`src/components/checkout/ResumoPedido.tsx`)
- ❌ PDV (não utilizado)

**Pode Ser Removido do PDV?**: Sim, mas manter em Comandas e Delivery

---

### 3. PagamentoDividido.tsx

**Arquivo**: `src/components/PagamentoDividido.tsx`

**Status**: ❌ Não utilizado no PDV

**Descrição**: Componente para dividir pagamento entre 2 formas diferentes

**Props**:
```typescript
interface PagamentoDivididoProps {
  totalPedido: number
  onConfirm: (data: SplitPaymentData) => void
  onCancel: () => void
}
```

**Funcionalidades**:
- Seleção de 2 formas de pagamento diferentes
- Input de valores para cada forma
- Validação em tempo real
- Cálculo automático de diferença
- Formatação de moeda

**Validações**:
- Tipos devem ser diferentes
- Ambos valores > 0
- Soma dos valores = total do pedido

**Onde é Utilizado**:
- ✅ Comandas (`src/pages/Comandas.tsx`)
- ❌ PDV (não utilizado)
- ❌ Delivery (não utilizado)

**Pode Ser Removido do PDV?**: Sim, mas manter em Comandas

---

### 4. EscolherObservacoesModal.tsx

**Arquivo**: `src/components/EscolherObservacoesModal.tsx`

**Status**: ❌ Não utilizado no PDV

**Descrição**: Modal para capturar observações de um item

**Props**:
```typescript
interface EscolherObservacoesModalProps {
  isOpen: boolean
  onClose: () => void
  onConfirm: (observacoes: string) => void
  variant?: 'pdv' | 'delivery'
}
```

**Funcionalidades**:
- Textarea para observações
- Limite de caracteres
- Botões de confirmar/cancelar

**Onde é Utilizado**:
- ✅ Delivery (`src/components/checkout/`)
- ❌ PDV (não utilizado)
- ❌ Comandas (não utilizado)

**Pode Ser Removido do PDV?**: Sim, mas manter em Delivery

---

## Hooks Não Utilizados no PDV

### 1. useValidacao.ts

**Arquivo**: `src/hooks/useValidacao.ts`

**Status**: ❌ Não utilizado no PDV

**Descrição**: Hook para validações gerais

**Funções**:
- `validarEmail()`
- `validarTelefone()`
- `validarCEP()`
- `validarEndereco()`

**Onde é Utilizado**:
- ✅ Delivery (`src/components/checkout/FormularioEntrega.tsx`)
- ❌ PDV (não utilizado)
- ❌ Comandas (não utilizado)

**Pode Ser Removido do PDV?**: Sim, mas manter em Delivery

---

### 2. useBuscaCEP.ts

**Arquivo**: `src/hooks/useBuscaCEP.ts`

**Status**: ❌ Não utilizado no PDV

**Descrição**: Hook para buscar endereço por CEP

**Funções**:
- `buscarCEP(cep: string)`
- `calcularDistancia()`
- `calcularTaxaExtraKm()`

**Onde é Utilizado**:
- ✅ Delivery (`src/components/checkout/FormularioEntrega.tsx`)
- ❌ PDV (não utilizado)
- ❌ Comandas (não utilizado)

**Pode Ser Removido do PDV?**: Sim, mas manter em Delivery

---

## Utilitários Não Utilizados no PDV

### 1. descontoCalculation.ts

**Arquivo**: `src/utils/descontoCalculation.ts`

**Status**: ❌ Não utilizado no PDV

**Descrição**: Utilitários para cálculo de desconto

**Funções**:
```typescript
export function calcularDescontoEmReais(
  desconto: number,
  tipo: 'valor' | 'percentual',
  subtotal: number
): number

export function calcularResumoValores(
  subtotal: number,
  desconto: DescontoInput,
  taxa_entrega?: number,
  taxa_extra_km?: number
): ResumoValores
```

**Onde é Utilizado**:
- ✅ Comandas (`src/pages/Comandas.tsx`)
- ✅ Delivery (`src/components/checkout/`)
- ❌ PDV (não utilizado)

**Pode Ser Removido do PDV?**: Sim, mas manter em Comandas e Delivery

---

### 2. descontoValidation.ts

**Arquivo**: `src/utils/descontoValidation.ts`

**Status**: ❌ Não utilizado no PDV

**Descrição**: Validações para desconto

**Funções**:
```typescript
export function validarDesconto(
  desconto: number,
  tipo: 'valor' | 'percentual',
  subtotal: number
): { valido: boolean; erro?: string }
```

**Onde é Utilizado**:
- ✅ Comandas (`src/pages/Comandas.tsx`)
- ✅ Delivery (`src/components/checkout/`)
- ❌ PDV (não utilizado)

**Pode Ser Removido do PDV?**: Sim, mas manter em Comandas e Delivery

---

## Componentes Utilizados em Comandas

### 1. CampoDesconto.tsx

**Uso em Comandas**: ✅ Ativo

**Localização**: `src/pages/Comandas.tsx`

**Implementação**:
```typescript
<CampoDesconto
  desconto={desconto}
  subtotal={comanda.total}
  onChange={setDesconto}
  erro={erroDesconto}
/>
```

**Funcionalidade**: Permite aplicar desconto manual em comandas

---

### 2. PagamentoDividido.tsx

**Uso em Comandas**: ✅ Ativo

**Localização**: `src/pages/Comandas.tsx`

**Implementação**:
```typescript
<PagamentoDividido
  totalPedido={comanda.total}
  onConfirm={handleConfirmarPagamentoDividido}
  onCancel={handleCancelarPagamentoDividido}
/>
```

**Funcionalidade**: Permite dividir pagamento em comandas

---

### 3. ResumoValores.tsx

**Uso em Comandas**: ✅ Ativo

**Localização**: `src/pages/Comandas.tsx`

**Implementação**:
```typescript
<ResumoValoresComponent
  resumo={{
    subtotal: comanda.total,
    desconto: desconto.valor,
    tipo_desconto: desconto.tipo,
    desconto_calculado: descontoCalculado,
    subtotal_com_desconto: subtotalComDesconto,
    taxa_entrega: 0,
    taxa_extra_km: 0,
    total: totalFinal
  }}
/>
```

**Funcionalidade**: Exibe resumo de valores com desconto

---

## Recomendações de Limpeza

### 1. Remover Imports Não Utilizados no PDV

**Arquivo**: `src/pages/PDV.tsx`

**Imports a Remover**:
```typescript
// ❌ Remover se não utilizado
import { CampoDesconto } from '@/components/shared/CampoDesconto'
import { ResumoValoresComponent } from '@/components/shared/ResumoValores'
import PagamentoDividido from '@/components/PagamentoDividido'
import { EscolherObservacoesModal } from '@/components/EscolherObservacoesModal'
import { useValidacao } from '@/hooks/useValidacao'
import { useBuscaCEP } from '@/hooks/useBuscaCEP'
import { calcularDescontoEmReais } from '@/utils/descontoCalculation'
import { validarDesconto } from '@/utils/descontoValidation'
```

### 2. Simplificar ModalCliente.tsx

**Arquivo**: `src/components/pdv/ModalCliente.tsx`

**Mudanças Sugeridas**:
- Remover campos de endereço (já removidos)
- Remover validação de CEP (já removida)
- Remover busca de taxa extra KM (já removida)
- Manter apenas: nome, sobrenome, telefone, email

### 3. Simplificar ModalFinalizarPedido.tsx

**Arquivo**: `src/components/pdv/ModalFinalizarPedido.tsx`

**Mudanças Sugeridas**:
- Remover exibição de taxa extra KM (já removida)
- Manter apenas: forma de pagamento, troco
- Simplificar resumo de valores

### 4. Criar Versão Simplificada de Hooks

**Opção 1**: Manter hooks genéricos com flags
```typescript
// useFinalizarPedidoPDV.ts
export function useFinalizarPedidoPDV(simplified = true) {
  // Lógica simplificada se simplified = true
}
```

**Opção 2**: Criar hooks específicos
```typescript
// useFinalizarPedidoSimplificado.ts
export function useFinalizarPedidoSimplificado() {
  // Lógica apenas para PDV simplificado
}
```

---

## Matriz de Utilização

### Componentes

| Componente | PDV | Comandas | Delivery | Status |
|-----------|-----|----------|----------|--------|
| CampoDesconto | ❌ | ✅ | ❌ | Manter em Comandas |
| ResumoValores | ❌ | ✅ | ✅ | Manter em Comandas/Delivery |
| PagamentoDividido | ❌ | ✅ | ❌ | Manter em Comandas |
| EscolherObservacoes | ❌ | ❌ | ✅ | Manter em Delivery |
| ModalCliente | ⚠️ Simplificado | ❌ | ✅ | Manter (simplificado) |
| ModalFinalizarPedido | ⚠️ Simplificado | ❌ | ❌ | Manter (simplificado) |

### Hooks

| Hook | PDV | Comandas | Delivery | Status |
|------|-----|----------|----------|--------|
| useValidacao | ❌ | ❌ | ✅ | Manter em Delivery |
| useBuscaCEP | ❌ | ❌ | ✅ | Manter em Delivery |
| useFinalizarPedidoPDV | ✅ | ❌ | ❌ | Manter em PDV |
| useCarrinhoPDV | ✅ | ❌ | ❌ | Manter em PDV |
| useCarrinho | ❌ | ❌ | ✅ | Manter em Delivery |

### Utilitários

| Utilitário | PDV | Comandas | Delivery | Status |
|-----------|-----|----------|----------|--------|
| descontoCalculation | ❌ | ✅ | ✅ | Manter em Comandas/Delivery |
| descontoValidation | ❌ | ✅ | ✅ | Manter em Comandas/Delivery |
| calculos | ✅ | ✅ | ✅ | Manter em todos |

---

## Conclusão

### ✅ Manter

- Todos os componentes, hooks e utilitários em Comandas
- Todos os componentes, hooks e utilitários em Delivery
- Componentes simplificados no PDV (ModalCliente, ModalFinalizarPedido)

### ⚠️ Considerar Remover

- Imports não utilizados no PDV
- Lógica de desconto no PDV
- Lógica de pagamento dividido no PDV
- Lógica de CEP no PDV

### 🎯 Recomendação Final

**Não remover nenhum arquivo**, apenas:
1. Remover imports não utilizados no PDV
2. Adicionar comentários indicando que componentes não são usados no PDV
3. Manter estrutura para possível reativação futura
4. Documentar claramente quais funcionalidades estão desativadas no PDV

---

**Última Atualização**: 31/01/2026
**Versão**: 1.0
**Status**: ✅ Análise Completa

# 🔧 DETALHES TÉCNICOS - FLUXOS DE PAGAMENTO

## 📂 Estrutura de Arquivos Relevantes

### PDV
```
src/
├── pages/PDV.tsx                          # Página principal
├── hooks/
│   ├── useFinalizarPedidoPDV.ts          # Lógica de finalização
│   ├── useCarrinhoPDV.ts                 # Gerenciamento de carrinho
│   └── useValidacao.ts                   # Validações
├── components/pdv/
│   ├── ModalFinalizarPedido.tsx          # Modal de finalização
│   ├── ModalCliente.tsx                  # Dados do cliente
│   ├── CarrinhoPDV.tsx                   # Visualização carrinho
│   └── GridProdutos.tsx                  # Grade de produtos
└── services/pedidoService.ts             # Serviço de pedidos
```

### Comandas
```
src/
├── pages/Comandas.tsx                    # Página principal
├── services/comandaService.ts            # Serviço de comandas
├── components/pdv/                       # Reutiliza componentes PDV
└── lib/qzTrayService.ts                  # Impressão térmica
```

### Delivery
```
src/
├── pages/DeliveryPage.tsx                # Página principal
├── components/
│   ├── CheckoutStepByStep.tsx            # Fluxo de checkout
│   ├── checkout/
│   │   ├── TipoEntregaSelector.tsx       # Escolher tipo
│   │   ├── FormularioEntrega.tsx         # Dados entrega
│   │   ├── FormularioRetirada.tsx        # Dados retirada
│   │   ├── ResumoPedido.tsx              # Resumo valores
│   │   ├── FormasPagamento.tsx           # Formas pagamento
│   │   ├── checkoutUtils.ts              # Utilitários
│   │   └── useCheckoutLogic.ts           # Lógica checkout
│   └── CarrinhoSheet.tsx                 # Carrinho flutuante
├── hooks/
│   ├── useCarrinho.ts                    # Gerenciamento carrinho
│   ├── useCheckoutData.ts                # Dados checkout
│   └── useBuscaCEP.ts                    # Busca CEP
└── services/pedidoService.ts             # Serviço de pedidos
```

### Utilitários Compartilhados
```
src/utils/
├── calculos.ts                           # Cálculos de preço
├── descontoCalculation.ts                # Cálculos de desconto
├── descontoValidation.ts                 # Validação de desconto
└── formatacao.ts                         # Formatação de valores
```

---

## 🔍 ANÁLISE DETALHADA POR COMPONENTE

### 1. PDV - useFinalizarPedidoPDV.ts

**Responsabilidades**:
- Gerenciar estado de desconto
- Validar desconto em tempo real
- Calcular resumo de valores
- Validar pedido antes de finalizar
- Salvar pedido no banco
- Atualizar estatísticas do cliente

**Estados**:
```typescript
const [processando, setProcessando] = useState(false)
const [desconto, setDesconto] = useState<DescontoInput>({
  valor: 0,
  tipo: 'valor'
})
const [erroDesconto, setErroDesconto] = useState<string | undefined>()
```

**Funções Principais**:
```typescript
// Validar desconto em tempo real
validarDescontoEmTempoReal(subtotal: number): void

// Calcular resumo com desconto
calcularResumo(subtotal, taxaEntrega, taxaExtraKm): ResumoValores

// Validar se pedido pode ser finalizado
validarPedido(carrinho, dadosCliente): string | null

// Finalizar e salvar pedido
finalizarPedido(params: FinalizarPedidoParams): Promise<{
  sucesso: boolean
  codigoPedido?: string
  erro?: string
}>
```

**Fluxo de Finalização**:
1. Validar desconto
2. Calcular resumo com desconto
3. Gerar ID único do pedido
4. Preparar dados do pedido
5. Salvar no banco (pedidoService.salvar)
6. Buscar/criar cliente
7. Atualizar estatísticas do cliente
8. Retornar código do pedido

### 2. Comandas - comandaService.ts

**Responsabilidades**:
- CRUD de comandas
- Gerenciar status (aberta, finalizada, cancelada)
- Mover para histórico
- Salvar ou atualizar

**Métodos Principais**:
```typescript
buscarAbertaPorNumero(numeroComanda: number): Promise<ComandaSupabase | null>
buscarAbertas(): Promise<ComandaSupabase[]>
criar(comanda: {...}): Promise<ComandaSupabase>
atualizar(id: string, dados: {...}): Promise<ComandaSupabase>
finalizar(id: string, formaPagamento?: string, splitPaymentData?: {...}): Promise<ComandaSupabase>
moverParaHistorico(comanda: ComandaSupabase): Promise<void>
salvarOuAtualizar(comanda: {...}): Promise<ComandaSupabase>
```

**Fluxo de Finalização**:
1. Atualizar status para 'finalizada'
2. Registrar forma de pagamento
3. Registrar dados de pagamento dividido (se houver)
4. Mover para historico_comandas
5. Limpar comanda

### 3. Delivery - CheckoutStepByStep.tsx

**Responsabilidades**:
- Gerenciar fluxo de 2 etapas
- Validar dados de entrega
- Calcular taxas
- Finalizar pedido

**Estados**:
```typescript
const [etapaAtual, setEtapaAtual] = useState(1)
const [enderecoValido, setEnderecoValido] = useState(false)
const [validandoEndereco, setValidandoEndereco] = useState(false)
```

**Etapas**:
1. **Etapa 1**: Dados de entrega
   - Escolher tipo (entrega/retirada)
   - Preencher dados
   - Validar endereço (se entrega)
   - Calcular taxa extra km

2. **Etapa 2**: Pagamento
   - Exibir resumo
   - Selecionar forma pagamento
   - Finalizar pedido

### 4. Delivery - FormularioEntrega.tsx

**Responsabilidades**:
- Capturar dados de entrega
- Buscar endereço por CEP
- Validar endereço
- Calcular taxa extra km
- Exibir feedback de validação

**Fluxo de Validação de CEP**:
1. Usuário preenche CEP
2. Debounce de 500ms
3. Buscar endereço via API (ViaCEP)
4. Preencher campos automaticamente
5. Calcular distância até estabelecimento
6. Calcular taxa extra km
7. Exibir taxa no resumo
8. Validar se está dentro da área de entrega

---

## 💾 FLUXO DE DADOS NO BANCO

### Salvando Pedido (PDV/Delivery)

```typescript
// 1. Preparar dados
const dadosPedido = {
  pedido_id: 'pdv-xxx' ou 'pedido-xxx',
  codigo_pedido: 'XXXX',
  cliente_nome, cliente_telefone, cliente_endereco, etc,
  entrega_domicilio: boolean,
  forma_pagamento: string,
  subtotal: number,
  taxa_entrega: number,
  taxa_extra_km: number,
  desconto: number,
  tipo_desconto: 'valor' | 'percentual',
  total: number,
  itens: JSONB,
  status: string,
  // Pagamento dividido (opcional)
  forma_pagamento_dividido: boolean,
  pagamento_1_tipo?: string,
  pagamento_1_valor?: number,
  pagamento_2_tipo?: string,
  pagamento_2_valor?: number
}

// 2. Salvar
const pedidoSalvo = await pedidoService.salvar(dadosPedido)

// 3. Atualizar cliente
await clienteService.incrementarEstatisticas(cliente.id, pedidoSalvo.total)

// 4. Criar histórico
await historicoPedidoService.adicionarStatus(codigo_pedido, status, observacao)
```

### Salvando Comanda

```typescript
// 1. Preparar dados
const dadosComanda = {
  numero_comanda: 1-24,
  itens: JSONB,
  subtotal: number,
  total: number,
  desconto: number,
  tipo_desconto: 'valor' | 'percentual',
  forma_pagamento: string,
  status: 'aberta' | 'finalizada' | 'cancelada',
  // Pagamento dividido (opcional)
  forma_pagamento_dividido: boolean,
  pagamento_1_tipo?: string,
  pagamento_1_valor?: number,
  pagamento_2_tipo?: string,
  pagamento_2_valor?: number
}

// 2. Salvar ou atualizar
const comanda = await comandaService.salvarOuAtualizar(dadosComanda)

// 3. Se finalizar, mover para histórico
if (status === 'finalizada') {
  await comandaService.moverParaHistorico(comanda)
}
```

---

## 🧮 CÁLCULOS DETALHADOS

### Cálculo de Desconto (descontoCalculation.ts)

```typescript
export function calcularDescontoEmReais(
  desconto: number,
  tipo: 'valor' | 'percentual',
  subtotal: number
): number {
  if (tipo === 'valor') {
    return Number(desconto.toFixed(2))
  } else {
    const descontoCalculado = (subtotal * desconto) / 100
    return Number(descontoCalculado.toFixed(2))
  }
}

export function calcularResumoValores(
  subtotal: number,
  desconto: DescontoInput,
  taxa_entrega: number = 0,
  taxa_extra_km: number = 0
): ResumoValores {
  const desconto_calculado = calcularDescontoEmReais(
    desconto.valor,
    desconto.tipo,
    subtotal
  )
  
  const subtotal_com_desconto = subtotal - desconto_calculado
  const total = subtotal_com_desconto + taxa_entrega + taxa_extra_km

  return {
    subtotal: Number(subtotal.toFixed(2)),
    desconto: desconto.valor,
    tipo_desconto: desconto.tipo,
    desconto_calculado: Number(desconto_calculado.toFixed(2)),
    subtotal_com_desconto: Number(subtotal_com_desconto.toFixed(2)),
    taxa_entrega: Number(taxa_entrega.toFixed(2)),
    taxa_extra_km: Number(taxa_extra_km.toFixed(2)),
    total: Number(total.toFixed(2))
  }
}
```

### Cálculo de Taxa Extra KM (calculos.ts)

```typescript
export function arredondarDistanciaKm(distanciaKm: number): number {
  const parteInteira = Math.floor(distanciaKm)
  const parteDecimal = distanciaKm - parteInteira
  
  if (parteDecimal <= 0.5) {
    return parteInteira
  } else {
    return parteInteira + 1
  }
}

export function calcularTaxaExtraKm(
  distanciaMetros: number | null,
  taxaExtraAtiva: boolean,
  kmInicial: number,
  faixas: FaixaTaxaExtraKm[]
): number {
  if (!taxaExtraAtiva || !distanciaMetros) return 0
  
  const distanciaKmExata = distanciaMetros / 1000
  const distanciaKm = arredondarDistanciaKm(distanciaKmExata)
  
  if (distanciaKm < kmInicial) return 0
  
  const configuracao = faixas.find(f => f.km === distanciaKm)
  if (configuracao) return configuracao.valorExtra
  
  const faixasOrdenadas = [...faixas].sort((a, b) => b.km - a.km)
  const configuracaoMaisProxima = faixasOrdenadas.find(f => f.km <= distanciaKm)
  
  return configuracaoMaisProxima?.valorExtra || 0
}
```

### Cálculo de Preço do Item (calculos.ts)

```typescript
export function calcularPrecoItem(item: ItemCarrinho): number {
  let precoTotal = 0

  if (item.produto.categoria === 'combo' && item.produto.id.includes('-')) {
    precoTotal = item.produto.preco || 0
  } else if (item.tamanhoSelecionado) {
    precoTotal = item.tamanhoSelecionado.valor
  } else {
    precoTotal = (item.produto.precoPromocional && item.produto.precoPromocional > 0)
      ? item.produto.precoPromocional
      : item.produto.preco

    if (item.saboresSelecionados && item.saboresSelecionados.length > 0) {
      const precoSabores = item.saboresSelecionados.reduce(
        (acc, sabor) => acc + (sabor.preco || 0), 
        0
      )
      precoTotal += precoSabores
    }

    if (item.bordaSelecionada) {
      precoTotal += item.bordaSelecionada.preco || 0
    }

    if (item.adicionaisSelecionados && item.adicionaisSelecionados.length > 0) {
      const precoAdicionais = item.adicionaisSelecionados.reduce(
        (acc, adicional) => acc + (adicional.valor * adicional.quantidade), 
        0
      )
      precoTotal += precoAdicionais
    }
  }

  return precoTotal * item.quantidade
}
```

---

## ✅ VALIDAÇÕES

### Validação de Desconto (descontoValidation.ts)

```typescript
export function validarDesconto(
  desconto: number,
  tipo: 'valor' | 'percentual',
  subtotal: number
): { valido: boolean; erro?: string } {
  // Validar se desconto é negativo
  if (desconto < 0) {
    return { valido: false, erro: 'Desconto não pode ser negativo' }
  }

  // Validar desconto em valor
  if (tipo === 'valor') {
    if (desconto > subtotal) {
      return { 
        valido: false, 
        erro: `Desconto não pode ser maior que o subtotal (R$ ${subtotal.toFixed(2)})` 
      }
    }
  }

  // Validar desconto percentual
  if (tipo === 'percentual') {
    if (desconto > 100) {
      return { valido: false, erro: 'Desconto percentual não pode ser maior que 100%' }
    }
  }

  return { valido: true }
}
```

### Validação de Pagamento Dividido (PagamentoDividido.tsx)

```typescript
// Validações em tempo real
const newErrors: ValidationErrors = {}

const valor1 = parseValor(pagamento1Valor)
const valor2 = parseValor(pagamento2Valor)

// Validar campos vazios
if (!pagamento1Tipo || !pagamento2Tipo || valor1 <= 0 || valor2 <= 0) {
  newErrors.camposVazios = "Todos os campos devem ser preenchidos"
}

// Validar tipos duplicados
if (pagamento1Tipo && pagamento2Tipo && pagamento1Tipo === pagamento2Tipo) {
  newErrors.tiposDuplicados = "As formas de pagamento devem ser diferentes"
}

// Validar soma dos valores
if (valor1 > 0 && valor2 > 0) {
  const soma = valor1 + valor2
  const diferenca = Math.abs(soma - totalPedido)
  
  if (diferenca > 0.01) {
    newErrors.somaIncorreta = `A soma deve ser igual ao total (${formatarMoeda(totalPedido)})`
  }
}
```

---

## 🔐 CONSTRAINTS DO BANCO

### Pedidos

```sql
-- Desconto não pode ser negativo
CHECK (desconto >= 0)

-- Tipo de desconto deve ser válido
CHECK (tipo_desconto IN ('valor', 'percentual'))

-- Se pagamento dividido, tipos devem ser diferentes
CONSTRAINT pedidos_pagamento_tipos_diferentes CHECK (
    NOT forma_pagamento_dividido OR 
    (pagamento_1_tipo IS NOT NULL AND pagamento_2_tipo IS NOT NULL AND pagamento_1_tipo != pagamento_2_tipo)
)

-- Se pagamento dividido, valores devem ser positivos
CONSTRAINT pedidos_pagamento_valores_positivos CHECK (
    NOT forma_pagamento_dividido OR 
    (pagamento_1_valor > 0 AND pagamento_2_valor > 0)
)
```

### Comandas

Mesmas constraints que pedidos

---

## 📊 TIPOS TYPESCRIPT

### DescontoInput

```typescript
interface DescontoInput {
  valor: number
  tipo: 'valor' | 'percentual'
}
```

### ResumoValores

```typescript
interface ResumoValores {
  subtotal: number
  desconto: number
  tipo_desconto: 'valor' | 'percentual'
  desconto_calculado: number
  subtotal_com_desconto: number
  taxa_entrega: number
  taxa_extra_km: number
  total: number
}
```

### SplitPaymentData

```typescript
interface SplitPaymentData {
  formaPagamentoDividido: boolean
  pagamento1Tipo?: string
  pagamento1Valor?: number
  pagamento2Tipo?: string
  pagamento2Valor?: number
}
```

### FaixaTaxaExtraKm

```typescript
interface FaixaTaxaExtraKm {
  id?: string
  km: number
  valorExtra: number
}
```

---

## 🧪 TESTES

### Arquivo de Testes: src/__tests__/splitPayment.e2e.test.ts

**Testes Implementados**:
- ✅ Criar pedido com pagamento dividido
- ✅ Validar tipos diferentes de pagamento
- ✅ Validar soma dos valores
- ✅ Mover pedido para histórico com split payment
- ✅ Finalizar comanda com split payment
- ✅ Mover comanda para histórico com split payment
- ✅ Gerar recibo com split payment
- ✅ Análise de pagamentos por tipo

**Executar Testes**:
```bash
npm run test -- splitPayment.e2e.test.ts
```

---

## 🚀 FLUXO DE INTEGRAÇÃO

### Para Adicionar Nova Forma de Pagamento

1. **Adicionar em configuracoes**:
   ```sql
   INSERT INTO configuracoes (chave, valor, tipo, categoria)
   VALUES ('metodos_pagamento', '["dinheiro","pix","nova_forma"]', 'json', 'pagamento')
   ```

2. **Atualizar FormasPagamento.tsx**:
   ```typescript
   const getNomeFormaPagamento = (forma: string) => {
     switch (forma) {
       case 'nova_forma':
         return 'Nova Forma'
       // ...
     }
   }
   ```

3. **Atualizar checkoutUtils.ts**:
   ```typescript
   const getNomeFormaPagamento = (forma: string) => {
     switch (forma) {
       case 'nova_forma':
         return 'Nova Forma'
       // ...
     }
   }
   ```

4. **Testar em todos os fluxos** (PDV, Comandas, Delivery)

---

## 📝 NOTAS DE IMPLEMENTAÇÃO

1. **Precisão Decimal**: Sempre usar `.toFixed(2)` para valores monetários
2. **Arredondamento de KM**: Usar função `arredondarDistanciaKm()` específica
3. **Validação em Tempo Real**: Usar hooks de validação para feedback imediato
4. **Histórico**: Sempre preservar dados de taxa, desconto e pagamento no histórico
5. **Constraints**: Banco valida automaticamente regras de pagamento dividido
6. **Transações**: Usar Promise.all() para operações paralelas não críticas


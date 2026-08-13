# 📊 MAPEAMENTO COMPLETO DE FLUXOS DE PAGAMENTO

## 🎯 Visão Geral

Este documento mapeia TODOS os fluxos de pagamento do sistema, incluindo:
- **PDV** (Ponto de Venda) - Vendas no balcão
- **Comandas** - Vendas no estabelecimento (mesas)
- **Delivery** - Vendas online com entrega

---

## 1️⃣ FLUXO PDV (Ponto de Venda)

### 📍 Localização do Código
- **Página Principal**: `src/pages/PDV.tsx`
- **Hook de Finalização**: `src/hooks/useFinalizarPedidoPDV.ts`
- **Hook de Carrinho**: `src/hooks/useCarrinhoPDV.ts`
- **Componentes**: `src/components/pdv/`

### 🔄 Fluxo Completo: Adicionar Produto → Finalizar

```
1. ADICIONAR PRODUTO AO CARRINHO
   ├─ Verificar se tem tamanhos
   ├─ Verificar se tem sabores
   ├─ Verificar se permite adicionais
   └─ Abrir modal de personalização se necessário

2. GERENCIAR CARRINHO
   ├─ Adicionar/remover itens
   ├─ Modificar quantidades
   └─ Visualizar subtotal

3. DADOS DO CLIENTE
   ├─ Nome e Sobrenome
   ├─ Telefone
   ├─ Email (opcional)
   ├─ Endereço (se entrega)
   ├─ Número, Complemento, Bairro, Cidade, Estado, CEP
   └─ Tipo de entrega (domicílio ou retirada)

4. CÁLCULO DE VALORES
   ├─ Subtotal (soma dos itens)
   ├─ Taxa de Entrega (fixa)
   ├─ Taxa Extra por KM (variável por distância)
   ├─ Desconto (manual, em R$ ou %)
   └─ Total = (Subtotal - Desconto) + Taxa Entrega + Taxa Extra KM

5. FORMA DE PAGAMENTO
   ├─ Dinheiro (com opção de troco)
   ├─ Cartão Débito
   ├─ Cartão Crédito
   ├─ PIX
   ├─ Pagamento Dividido (2 formas diferentes)
   └─ Pago no Balcão (marca como aprovado)

6. FINALIZAR PEDIDO
   ├─ Validar dados do cliente
   ├─ Validar desconto
   ├─ Salvar no banco de dados
   ├─ Atualizar estatísticas do cliente
   └─ Exibir código do pedido
```

### 📋 Campos de Taxa

| Campo | Tipo | Descrição | Obrigatório | Padrão |
|-------|------|-----------|-------------|--------|
| `taxa_entrega` | NUMERIC | Taxa fixa de entrega | Sim | 0 |
| `taxa_extra_km` | DECIMAL(10,2) | Taxa adicional por km | Não | 0 |
| `entrega_domicilio` | BOOLEAN | Se é entrega ou retirada | Sim | true |

**Cálculo de Taxa Extra KM**:
- Busca distância do cliente via CEP
- Arredonda distância (≤0.5 para baixo, >0.5 para cima)
- Busca configuração de taxa para o km arredondado
- Se não encontrar exato, usa taxa do km mais próximo abaixo

### 💰 Campos de Desconto

| Campo | Tipo | Descrição | Obrigatório | Padrão |
|-------|------|-----------|-------------|--------|
| `desconto` | NUMERIC | Valor do desconto | Sim | 0 |
| `tipo_desconto` | TEXT | 'valor' (R$) ou 'percentual' (%) | Sim | 'valor' |

**Validações de Desconto**:
- Se tipo='valor': desconto não pode ser > subtotal
- Se tipo='percentual': desconto não pode ser > 100%
- Desconto não pode ser negativo
- Desconto é aplicado ANTES das taxas

### 💳 Formas de Pagamento

| Forma | Campo | Descrição |
|-------|-------|-----------|
| Dinheiro | `forma_pagamento` = 'dinheiro' | Com opção de troco |
| Débito | `forma_pagamento` = 'cartaoDebito' | Cartão de débito |
| Crédito | `forma_pagamento` = 'cartaoCredito' | Cartão de crédito |
| PIX | `forma_pagamento` = 'pix' | Transferência PIX |
| Pago | `mercado_pago_status` = 'approved' | Já pago no balcão |

### 🔀 Pagamento Dividido (PDV)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `forma_pagamento_dividido` | BOOLEAN | Ativa pagamento dividido |
| `pagamento_1_tipo` | TEXT | Tipo do 1º pagamento |
| `pagamento_1_valor` | NUMERIC(10,2) | Valor do 1º pagamento |
| `pagamento_2_tipo` | TEXT | Tipo do 2º pagamento |
| `pagamento_2_valor` | NUMERIC(10,2) | Valor do 2º pagamento |

**Validações**:
- Tipos devem ser diferentes
- Ambos valores > 0
- Soma dos valores = total do pedido
- Constraint: `pedidos_pagamento_tipos_diferentes`
- Constraint: `pedidos_pagamento_valores_positivos`

### 📊 Tabelas Envolvidas (PDV)

| Tabela | Campos Relevantes |
|--------|-------------------|
| `pedidos` | desconto, tipo_desconto, taxa_entrega, taxa_extra_km, forma_pagamento_dividido, pagamento_1_tipo, pagamento_1_valor, pagamento_2_tipo, pagamento_2_valor |
| `historico_pedidos` | desconto, tipo_desconto, forma_pagamento_dividido, pagamento_1_tipo, pagamento_1_valor, pagamento_2_tipo, pagamento_2_valor |
| `clientes` | total_pedidos, valor_total_gasto, ultimo_pedido_em |

### 🔧 Componentes Principais (PDV)

- `ModalFinalizarPedido` - Modal de finalização com desconto e pagamento
- `PagamentoDividido` - Componente para dividir pagamento
- `CampoDesconto` - Campo para inserir desconto
- `ResumoValoresComponent` - Exibe resumo com desconto

---

## 2️⃣ FLUXO COMANDAS

### 📍 Localização do Código
- **Página Principal**: `src/pages/Comandas.tsx`
- **Serviço**: `src/services/comandaService.ts`
- **Componentes**: `src/components/pdv/` (reutilizados do PDV)

### 🔄 Fluxo Completo: Adicionar Produto → Finalizar

```
1. SELECIONAR COMANDA (1-24)
   └─ Comanda pode estar aberta ou nova

2. ADICIONAR PRODUTOS À COMANDA
   ├─ Mesmo fluxo do PDV
   ├─ Verificar tamanhos, sabores, adicionais
   └─ Adicionar ao carrinho da comanda

3. GERENCIAR ITENS DA COMANDA
   ├─ Adicionar mais itens
   ├─ Remover itens
   ├─ Visualizar total
   └─ Salvar comanda (manual)

4. APLICAR DESCONTO (opcional)
   ├─ Desconto em R$ ou %
   ├─ Validar desconto
   └─ Recalcular total

5. FINALIZAR COMANDA
   ├─ Selecionar forma de pagamento
   ├─ Opção de pagamento dividido
   ├─ Imprimir comanda (opcional)
   ├─ Mover para histórico
   └─ Limpar comanda

6. IMPRESSÃO
   ├─ Gerar HTML para impressora térmica
   ├─ Usar QZ Tray se configurado
   ├─ Fallback para impressão do navegador
   └─ Exibir status de impressão
```

### 📋 Campos de Taxa

**Comandas NÃO têm taxa de entrega** (são vendas no local)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `taxa_entrega` | NUMERIC | Sempre 0 para comandas |
| `taxa_extra_km` | DECIMAL(10,2) | Sempre 0 para comandas |

### 💰 Campos de Desconto (Comandas)

| Campo | Tipo | Descrição | Obrigatório | Padrão |
|-------|------|-----------|-------------|--------|
| `desconto` | NUMERIC | Valor do desconto | Sim | 0 |
| `tipo_desconto` | TEXT | 'valor' (R$) ou 'percentual' (%) | Sim | 'valor' |

**Aplicação**:
- Desconto é aplicado ao total da comanda
- Pode ser alterado antes de finalizar
- Validações iguais ao PDV

### 💳 Formas de Pagamento (Comandas)

| Forma | Campo | Descrição |
|-------|-------|-----------|
| Dinheiro | `forma_pagamento` = 'dinheiro' | Pagamento em dinheiro |
| Débito | `forma_pagamento` = 'cartaoDebito' | Cartão de débito |
| Crédito | `forma_pagamento` = 'cartaoCredito' | Cartão de crédito |
| PIX | `forma_pagamento` = 'pix' | Transferência PIX |

### 🔀 Pagamento Dividido (Comandas)

Mesma estrutura do PDV:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `forma_pagamento_dividido` | BOOLEAN | Ativa pagamento dividido |
| `pagamento_1_tipo` | TEXT | Tipo do 1º pagamento |
| `pagamento_1_valor` | NUMERIC(10,2) | Valor do 1º pagamento |
| `pagamento_2_tipo` | TEXT | Tipo do 2º pagamento |
| `pagamento_2_valor` | NUMERIC(10,2) | Valor do 2º pagamento |

### 📊 Tabelas Envolvidas (Comandas)

| Tabela | Campos Relevantes |
|--------|-------------------|
| `comandas` | numero_comanda (1-24), desconto, tipo_desconto, forma_pagamento_dividido, pagamento_1_tipo, pagamento_1_valor, pagamento_2_tipo, pagamento_2_valor, status |
| `historico_comandas` | numero_comanda, desconto, tipo_desconto, forma_pagamento_dividido, pagamento_1_tipo, pagamento_1_valor, pagamento_2_tipo, pagamento_2_valor |

### 🔧 Componentes Principais (Comandas)

- `EscolherSaborModal` - Personalizar produtos
- `PagamentoDividido` - Dividir pagamento
- `CampoDesconto` - Aplicar desconto
- `ResumoValoresComponent` - Exibir resumo

### 🖨️ Impressão de Comandas

**Configurações de Impressão**:
- `usar_qz_tray` - Usar QZ Tray para impressora térmica
- `impressora_padrao` - Nome da impressora
- `densidade_impressao` - Densidade (1-5)
- `font_size_*` - Tamanhos de fonte

**Dados Impressos**:
- Nome do estabelecimento
- Número da comanda
- Data/hora
- Itens com personalizações
- Subtotal, desconto, total
- Forma de pagamento
- Status: "COMANDA NÃO FINALIZADA - NÃO PAGO"

---

## 3️⃣ FLUXO DELIVERY

### 📍 Localização do Código
- **Página Principal**: `src/pages/DeliveryPage.tsx`
- **Checkout**: `src/components/CheckoutStepByStep.tsx`
- **Componentes Checkout**: `src/components/checkout/`
- **Hooks**: `src/hooks/useCheckoutData.ts`, `src/hooks/useCarrinho.ts`

### 🔄 Fluxo Completo: Adicionar Produto → Checkout → Pagamento

```
ETAPA 1: SELEÇÃO DE PRODUTOS
├─ Visualizar cardápio por categoria
├─ Adicionar produtos ao carrinho
├─ Personalizar (sabores, tamanhos, adicionais)
├─ Visualizar carrinho
└─ Prosseguir para checkout

ETAPA 2: DADOS DE ENTREGA
├─ Escolher tipo de entrega
│  ├─ Entrega a domicílio
│  │  ├─ Preencher CEP
│  │  ├─ Validar endereço (busca automática)
│  │  ├─ Calcular taxa de entrega
│  │  ├─ Calcular taxa extra por km
│  │  └─ Preencher dados completos
│  └─ Retirada no local
│     └─ Preencher apenas nome e telefone
├─ Dados do cliente
│  ├─ Nome e Sobrenome
│  ├─ Telefone
│  ├─ Email (opcional)
│  └─ CPF (opcional)
└─ Validar dados

ETAPA 3: RESUMO E PAGAMENTO
├─ Exibir resumo do pedido
│  ├─ Itens com preços
│  ├─ Subtotal
│  ├─ Taxa de entrega
│  ├─ Taxa extra por km (se aplicável)
│  └─ Total
├─ Selecionar forma de pagamento
│  ├─ Dinheiro (com troco)
│  ├─ Cartão Débito
│  ├─ Cartão Crédito
│  ├─ PIX
│  ├─ PIX na Entrega
│  ├─ Cartão VR
│  ├─ Cartão VA
│  └─ Ticket Promocional
├─ Adicionar observações (opcional)
└─ Finalizar pedido

ETAPA 4: CONFIRMAÇÃO
├─ Salvar pedido no banco
├─ Atualizar estatísticas do cliente
├─ Enviar para WhatsApp
├─ Redirecionar para acompanhamento
└─ Limpar carrinho
```

### 📋 Campos de Taxa (Delivery)

| Campo | Tipo | Descrição | Obrigatório | Padrão |
|-------|------|-----------|-------------|--------|
| `taxa_entrega` | NUMERIC | Taxa fixa de entrega | Sim | 0 |
| `taxa_extra_km` | DECIMAL(10,2) | Taxa adicional por km | Não | 0 |
| `entrega_domicilio` | BOOLEAN | Se é entrega ou retirada | Sim | true |

**Cálculo de Taxa Extra KM (Delivery)**:
1. Usuário preenche CEP
2. Sistema busca coordenadas do CEP
3. Calcula distância até o estabelecimento
4. Arredonda distância (≤0.5 para baixo, >0.5 para cima)
5. Busca configuração de taxa para o km
6. Se não encontrar exato, usa taxa do km mais próximo abaixo
7. Exibe taxa extra no resumo

### 💰 Campos de Desconto (Delivery)

**Delivery NÃO tem desconto manual** (descontos são automáticos via promoções)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `desconto` | NUMERIC | Sempre 0 para delivery |
| `tipo_desconto` | TEXT | Sempre 'valor' para delivery |

### 💳 Formas de Pagamento (Delivery)

| Forma | Campo | Descrição | Configurável |
|-------|-------|-----------|--------------|
| Dinheiro | `dinheiro` | Pagamento em dinheiro | Sim |
| Débito | `cartaoDebito` | Cartão de débito | Sim |
| Crédito | `cartaoCredito` | Cartão de crédito | Sim |
| PIX | `pix` | Transferência PIX | Sim |
| PIX Entrega | `pixEntrega` | PIX na entrega | Sim |
| Cartão VR | `cartaoVR` | Vale Refeição | Sim |
| Cartão VA | `cartaoVA` | Vale Alimentação | Sim |
| Ticket | `ticketPromo` | Ticket Promocional | Sim |

**Configuração**: `metodos_pagamento` em `configuracoes`

### 🔀 Pagamento Dividido (Delivery)

**Delivery NÃO suporta pagamento dividido** (apenas uma forma de pagamento)

### 📊 Tabelas Envolvidas (Delivery)

| Tabela | Campos Relevantes |
|--------|-------------------|
| `pedidos` | desconto (sempre 0), tipo_desconto (sempre 'valor'), taxa_entrega, taxa_extra_km, forma_pagamento, entrega_domicilio |
| `historico_geral` | desconto, tipo_desconto, taxa_entrega, taxa_extra_km, forma_pagamento |
| `clientes` | total_pedidos, valor_total_gasto, ultimo_pedido_em |

### 🔧 Componentes Principais (Delivery)

- `TipoEntregaSelector` - Escolher entrega ou retirada
- `FormularioEntrega` - Dados de entrega com validação de CEP
- `FormularioRetirada` - Dados de retirada
- `ResumoPedido` - Resumo com cálculos
- `FormasPagamento` - Seleção de forma de pagamento
- `CarrinhoSheet` - Carrinho flutuante

### 📍 Validação de Endereço (Delivery)

**Componente**: `FormularioEntrega`

**Fluxo**:
1. Usuário preenche CEP
2. Sistema busca endereço via API (ViaCEP ou similar)
3. Preenche automaticamente: rua, bairro, cidade, estado
4. Calcula distância até estabelecimento
5. Calcula taxa extra por km
6. Exibe taxa no resumo
7. Valida se endereço está dentro da área de entrega

**Campos Validados**:
- CEP (formato válido)
- Endereço (não vazio)
- Número (não vazio)
- Bairro (não vazio)
- Cidade (não vazio)
- Estado (não vazio)

### 💬 Integração WhatsApp (Delivery)

**Quando**: Após finalizar pedido (exceto PIX)

**Dados Enviados**:
- Código do pedido
- Data/hora
- Dados do cliente
- Endereço de entrega
- Itens com personalizações
- Subtotal, taxa entrega, taxa extra km, total
- Forma de pagamento
- Observações
- Link de acompanhamento

**Função**: `gerarMensagemWhatsApp()` em `checkoutUtils.ts`

---

## 📊 COMPARATIVO DOS TRÊS FLUXOS

| Aspecto | PDV | Comandas | Delivery |
|--------|-----|----------|----------|
| **Taxa Entrega** | ✅ Sim | ❌ Não | ✅ Sim |
| **Taxa Extra KM** | ✅ Sim | ❌ Não | ✅ Sim |
| **Desconto Manual** | ✅ Sim | ✅ Sim | ❌ Não |
| **Pagamento Dividido** | ✅ Sim | ✅ Sim | ❌ Não |
| **Formas Pagamento** | 5 | 4 | 8 |
| **Validação CEP** | ❌ Não | ❌ Não | ✅ Sim |
| **Impressão** | ❌ Não | ✅ Sim | ❌ Não |
| **WhatsApp** | ❌ Não | ❌ Não | ✅ Sim |
| **Histórico** | ✅ Sim | ✅ Sim | ✅ Sim |

---

## 🗄️ ESTRUTURA DE DADOS UNIFICADA

### Tabela: `pedidos`

```sql
-- Campos de Taxa
taxa_entrega NUMERIC DEFAULT 0
taxa_extra_km DECIMAL(10,2) DEFAULT 0
entrega_domicilio BOOLEAN DEFAULT true

-- Campos de Desconto
desconto NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0)
tipo_desconto TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual'))

-- Campos de Pagamento Dividido
forma_pagamento_dividido BOOLEAN NOT NULL DEFAULT false
pagamento_1_tipo TEXT
pagamento_1_valor NUMERIC(10, 2)
pagamento_2_tipo TEXT
pagamento_2_valor NUMERIC(10, 2)

-- Constraints
CONSTRAINT pedidos_pagamento_tipos_diferentes CHECK (
    NOT forma_pagamento_dividido OR 
    (pagamento_1_tipo IS NOT NULL AND pagamento_2_tipo IS NOT NULL AND pagamento_1_tipo != pagamento_2_tipo)
)
CONSTRAINT pedidos_pagamento_valores_positivos CHECK (
    NOT forma_pagamento_dividido OR 
    (pagamento_1_valor > 0 AND pagamento_2_valor > 0)
)
```

### Tabela: `comandas`

```sql
-- Campos de Desconto
desconto NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0)
tipo_desconto TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual'))

-- Campos de Pagamento Dividido
forma_pagamento_dividido BOOLEAN NOT NULL DEFAULT false
pagamento_1_tipo TEXT
pagamento_1_valor NUMERIC(10, 2)
pagamento_2_tipo TEXT
pagamento_2_valor NUMERIC(10, 2)

-- Constraints (iguais aos pedidos)
```

### Tabela: `historico_pedidos` e `historico_geral`

Mesmos campos de desconto e pagamento dividido que `pedidos`

### Tabela: `historico_comandas`

Mesmos campos de desconto e pagamento dividido que `comandas`

---

## 🔄 FLUXO DE CÁLCULO DE VALORES

### Fórmula Geral

```
Total = (Subtotal - Desconto) + Taxa Entrega + Taxa Extra KM

Onde:
- Subtotal = Σ(Preço Item × Quantidade)
- Desconto = Se tipo='valor' então valor, senão (Subtotal × valor / 100)
- Taxa Entrega = Se entrega_domicilio então taxa_entrega senão 0
- Taxa Extra KM = Se entrega_domicilio então taxa_extra_km senão 0
```

### Ordem de Aplicação

1. **Calcular Subtotal**: Soma de todos os itens
2. **Aplicar Desconto**: Subtrai do subtotal
3. **Adicionar Taxas**: Soma taxa entrega + taxa extra km
4. **Resultado**: Total final

### Exemplo PDV

```
Subtotal: R$ 100,00
Desconto: R$ 10,00 (tipo='valor')
Taxa Entrega: R$ 5,00
Taxa Extra KM: R$ 2,00

Total = (100 - 10) + 5 + 2 = R$ 97,00
```

### Exemplo Delivery

```
Subtotal: R$ 150,00
Desconto: R$ 0,00 (delivery não tem desconto manual)
Taxa Entrega: R$ 8,00
Taxa Extra KM: R$ 3,00 (para 5km)

Total = (150 - 0) + 8 + 3 = R$ 161,00
```

---

## 🔧 CAMPOS OPCIONAIS/REMOVÍVEIS

### PDV

| Campo | Obrigatório | Pode Remover? | Impacto |
|-------|-------------|---------------|--------|
| `taxa_extra_km` | Não | ✅ Sim | Sem taxa por distância |
| `desconto` | Não | ✅ Sim | Sem desconto manual |
| `forma_pagamento_dividido` | Não | ✅ Sim | Sem pagamento dividido |
| `valor_troco` | Não | ✅ Sim | Sem controle de troco |

### Comandas

| Campo | Obrigatório | Pode Remover? | Impacto |
|-------|-------------|---------------|--------|
| `desconto` | Não | ✅ Sim | Sem desconto manual |
| `forma_pagamento_dividido` | Não | ✅ Sim | Sem pagamento dividido |

### Delivery

| Campo | Obrigatório | Pode Remover? | Impacto |
|-------|-------------|---------------|--------|
| `taxa_extra_km` | Não | ✅ Sim | Sem taxa por distância |
| Nenhum outro é removível | - | - | - |

---

## 📝 NOTAS IMPORTANTES

1. **Desconto é aplicado ANTES das taxas** em todos os fluxos
2. **Pagamento dividido requer 2 formas DIFERENTES** de pagamento
3. **Taxa extra KM é calculada por arredondamento especial** (≤0.5 para baixo)
4. **Delivery não suporta desconto manual** (apenas promoções automáticas)
5. **Delivery não suporta pagamento dividido** (apenas uma forma)
6. **Comandas não têm taxa de entrega** (vendas no local)
7. **Todos os valores são armazenados com precisão de 2 casas decimais**
8. **Histórico preserva todos os campos de taxa, desconto e pagamento**

---

## 🎯 PRÓXIMOS PASSOS

Para implementar mudanças nos fluxos de pagamento:

1. **Modificar Cálculos**: Editar `src/utils/calculos.ts` e `src/utils/descontoCalculation.ts`
2. **Adicionar Formas Pagamento**: Editar `src/components/checkout/FormasPagamento.tsx`
3. **Alterar Taxas**: Editar `src/hooks/useFinalizarPedidoPDV.ts` e `src/components/checkout/`
4. **Atualizar BD**: Executar migrations em `BD_20_01/`
5. **Testar**: Usar testes em `src/__tests__/splitPayment.e2e.test.ts`


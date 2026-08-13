# ✅ CHECKLIST - CAMPOS DE PAGAMENTO E TAXA

## 📋 Resumo Executivo

Este documento serve como checklist rápido para identificar e validar todos os campos relacionados a pagamento, taxa e desconto em cada fluxo.

---

## 🏪 PDV - CHECKLIST COMPLETO

### ✅ Campos de Taxa
- [ ] `taxa_entrega` - Taxa fixa de entrega (NUMERIC, padrão 0)
- [ ] `taxa_extra_km` - Taxa adicional por km (DECIMAL(10,2), padrão 0)
- [ ] `entrega_domicilio` - Tipo de entrega (BOOLEAN, padrão true)

**Onde Usar**:
- Salvar em `pedidos.taxa_entrega`
- Salvar em `pedidos.taxa_extra_km`
- Salvar em `pedidos.entrega_domicilio`
- Copiar para `historico_pedidos` e `historico_geral`

### ✅ Campos de Desconto
- [ ] `desconto` - Valor do desconto (NUMERIC, padrão 0)
- [ ] `tipo_desconto` - Tipo ('valor' ou 'percentual', padrão 'valor')

**Validações**:
- [ ] Desconto não pode ser negativo
- [ ] Se tipo='valor': desconto ≤ subtotal
- [ ] Se tipo='percentual': desconto ≤ 100%
- [ ] Desconto é aplicado ANTES das taxas

**Onde Usar**:
- Salvar em `pedidos.desconto`
- Salvar em `pedidos.tipo_desconto`
- Copiar para `historico_pedidos` e `historico_geral`

### ✅ Formas de Pagamento
- [ ] Dinheiro (com opção de troco)
- [ ] Cartão Débito
- [ ] Cartão Crédito
- [ ] PIX
- [ ] Pago no Balcão (status 'approved')

**Onde Usar**:
- Salvar em `pedidos.forma_pagamento`
- Se pago: `pedidos.mercado_pago_status = 'approved'`

### ✅ Pagamento Dividido
- [ ] `forma_pagamento_dividido` - Ativa split (BOOLEAN, padrão false)
- [ ] `pagamento_1_tipo` - Tipo do 1º pagamento (TEXT)
- [ ] `pagamento_1_valor` - Valor do 1º pagamento (NUMERIC(10,2))
- [ ] `pagamento_2_tipo` - Tipo do 2º pagamento (TEXT)
- [ ] `pagamento_2_valor` - Valor do 2º pagamento (NUMERIC(10,2))

**Validações**:
- [ ] Se ativo: ambos tipos preenchidos
- [ ] Se ativo: tipos devem ser DIFERENTES
- [ ] Se ativo: ambos valores > 0
- [ ] Se ativo: soma dos valores = total do pedido
- [ ] Constraint `pedidos_pagamento_tipos_diferentes` ativa
- [ ] Constraint `pedidos_pagamento_valores_positivos` ativa

**Onde Usar**:
- Salvar em `pedidos.forma_pagamento_dividido`
- Salvar em `pedidos.pagamento_1_tipo`
- Salvar em `pedidos.pagamento_1_valor`
- Salvar em `pedidos.pagamento_2_tipo`
- Salvar em `pedidos.pagamento_2_valor`
- Copiar para `historico_pedidos` e `historico_geral`

### ✅ Campos de Cliente
- [ ] Nome
- [ ] Sobrenome
- [ ] Telefone
- [ ] Email (opcional)
- [ ] CPF (opcional)
- [ ] Endereço (se entrega)
- [ ] Número (se entrega)
- [ ] Complemento (opcional)
- [ ] Bairro (se entrega)
- [ ] Cidade (se entrega)
- [ ] Estado (se entrega)
- [ ] CEP (se entrega)

**Onde Usar**:
- Salvar em `pedidos.cliente_*`
- Criar/atualizar em `clientes`
- Copiar para `historico_geral`

### ✅ Cálculos
- [ ] Subtotal = Σ(Preço Item × Quantidade)
- [ ] Desconto Calculado = Se tipo='valor' então valor, senão (Subtotal × valor / 100)
- [ ] Subtotal com Desconto = Subtotal - Desconto Calculado
- [ ] Total = (Subtotal - Desconto) + Taxa Entrega + Taxa Extra KM

**Onde Usar**:
- Função `calcularSubtotal()` em `useCarrinhoPDV.ts`
- Função `calcularDescontoEmReais()` em `descontoCalculation.ts`
- Função `calcularResumoValores()` em `descontoCalculation.ts`

### ✅ Componentes Envolvidos
- [ ] `ModalFinalizarPedido.tsx` - Modal de finalização
- [ ] `PagamentoDividido.tsx` - Componente de split payment
- [ ] `CampoDesconto.tsx` - Campo de desconto
- [ ] `ResumoValoresComponent.tsx` - Resumo com cálculos
- [ ] `ModalCliente.tsx` - Dados do cliente

### ✅ Hooks Envolvidos
- [ ] `useFinalizarPedidoPDV.ts` - Lógica de finalização
- [ ] `useCarrinhoPDV.ts` - Gerenciamento de carrinho
- [ ] `useValidacao.ts` - Validações

### ✅ Serviços Envolvidos
- [ ] `pedidoService.salvar()` - Salvar pedido
- [ ] `clienteService.buscarOuCriar()` - Gerenciar cliente
- [ ] `clienteService.incrementarEstatisticas()` - Atualizar stats

---

## 🍽️ COMANDAS - CHECKLIST COMPLETO

### ✅ Campos de Taxa
- [ ] **NÃO TEM** taxa_entrega (sempre 0)
- [ ] **NÃO TEM** taxa_extra_km (sempre 0)
- [ ] **NÃO TEM** entrega_domicilio (sempre local)

**Nota**: Comandas são vendas no estabelecimento, sem entrega

### ✅ Campos de Desconto
- [ ] `desconto` - Valor do desconto (NUMERIC, padrão 0)
- [ ] `tipo_desconto` - Tipo ('valor' ou 'percentual', padrão 'valor')

**Validações**:
- [ ] Desconto não pode ser negativo
- [ ] Se tipo='valor': desconto ≤ total da comanda
- [ ] Se tipo='percentual': desconto ≤ 100%
- [ ] Desconto é aplicado ao total

**Onde Usar**:
- Salvar em `comandas.desconto`
- Salvar em `comandas.tipo_desconto`
- Copiar para `historico_comandas`

### ✅ Formas de Pagamento
- [ ] Dinheiro
- [ ] Cartão Débito
- [ ] Cartão Crédito
- [ ] PIX

**Onde Usar**:
- Salvar em `comandas.forma_pagamento`

### ✅ Pagamento Dividido
- [ ] `forma_pagamento_dividido` - Ativa split (BOOLEAN, padrão false)
- [ ] `pagamento_1_tipo` - Tipo do 1º pagamento (TEXT)
- [ ] `pagamento_1_valor` - Valor do 1º pagamento (NUMERIC(10,2))
- [ ] `pagamento_2_tipo` - Tipo do 2º pagamento (TEXT)
- [ ] `pagamento_2_valor` - Valor do 2º pagamento (NUMERIC(10,2))

**Validações**:
- [ ] Se ativo: ambos tipos preenchidos
- [ ] Se ativo: tipos devem ser DIFERENTES
- [ ] Se ativo: ambos valores > 0
- [ ] Se ativo: soma dos valores = total da comanda
- [ ] Constraint `comandas_pagamento_tipos_diferentes` ativa
- [ ] Constraint `comandas_pagamento_valores_positivos` ativa

**Onde Usar**:
- Salvar em `comandas.forma_pagamento_dividido`
- Salvar em `comandas.pagamento_1_tipo`
- Salvar em `comandas.pagamento_1_valor`
- Salvar em `comandas.pagamento_2_tipo`
- Salvar em `comandas.pagamento_2_valor`
- Copiar para `historico_comandas`

### ✅ Campos de Comanda
- [ ] `numero_comanda` - Número 1-24 (INTEGER)
- [ ] `status` - 'aberta', 'finalizada', 'cancelada' (VARCHAR)
- [ ] `itens` - Array JSON com produtos
- [ ] `subtotal` - Soma dos itens (NUMERIC)
- [ ] `total` - Subtotal - desconto (NUMERIC)

**Onde Usar**:
- Salvar em `comandas`
- Copiar para `historico_comandas`

### ✅ Cálculos
- [ ] Subtotal = Σ(Preço Item × Quantidade)
- [ ] Desconto Calculado = Se tipo='valor' então valor, senão (Subtotal × valor / 100)
- [ ] Total = Subtotal - Desconto Calculado

**Nota**: Sem taxas de entrega

### ✅ Componentes Envolvidos
- [ ] `EscolherSaborModal.tsx` - Personalizar produtos
- [ ] `PagamentoDividido.tsx` - Componente de split payment
- [ ] `CampoDesconto.tsx` - Campo de desconto
- [ ] `ResumoValoresComponent.tsx` - Resumo com cálculos

### ✅ Serviços Envolvidos
- [ ] `comandaService.criar()` - Criar comanda
- [ ] `comandaService.atualizar()` - Atualizar comanda
- [ ] `comandaService.finalizar()` - Finalizar comanda
- [ ] `comandaService.moverParaHistorico()` - Mover para histórico

### ✅ Impressão
- [ ] Gerar HTML para impressora térmica
- [ ] Usar QZ Tray se configurado
- [ ] Fallback para impressão do navegador
- [ ] Incluir dados de desconto e pagamento dividido no recibo

---

## 🚚 DELIVERY - CHECKLIST COMPLETO

### ✅ Campos de Taxa
- [ ] `taxa_entrega` - Taxa fixa de entrega (NUMERIC, padrão 0)
- [ ] `taxa_extra_km` - Taxa adicional por km (DECIMAL(10,2), padrão 0)
- [ ] `entrega_domicilio` - Sempre true para delivery (BOOLEAN)

**Cálculo de Taxa Extra KM**:
- [ ] Usuário preenche CEP
- [ ] Sistema busca coordenadas
- [ ] Calcula distância até estabelecimento
- [ ] Arredonda distância (≤0.5 para baixo, >0.5 para cima)
- [ ] Busca configuração de taxa para o km
- [ ] Se não encontrar exato, usa taxa do km mais próximo abaixo
- [ ] Exibe taxa no resumo

**Onde Usar**:
- Salvar em `pedidos.taxa_entrega`
- Salvar em `pedidos.taxa_extra_km`
- Salvar em `pedidos.entrega_domicilio` (sempre true)
- Copiar para `historico_geral`

### ✅ Campos de Desconto
- [ ] **NÃO TEM** desconto manual (sempre 0)
- [ ] `desconto` - Sempre 0 (NUMERIC, padrão 0)
- [ ] `tipo_desconto` - Sempre 'valor' (TEXT, padrão 'valor')

**Nota**: Delivery não suporta desconto manual, apenas promoções automáticas

**Onde Usar**:
- Salvar em `pedidos.desconto = 0`
- Salvar em `pedidos.tipo_desconto = 'valor'`
- Copiar para `historico_geral`

### ✅ Formas de Pagamento
- [ ] Dinheiro
- [ ] Cartão Débito
- [ ] Cartão Crédito
- [ ] PIX
- [ ] PIX na Entrega
- [ ] Cartão VR (Vale Refeição)
- [ ] Cartão VA (Vale Alimentação)
- [ ] Ticket Promocional

**Configuração**: `metodos_pagamento` em `configuracoes`

**Onde Usar**:
- Salvar em `pedidos.forma_pagamento`

### ✅ Pagamento Dividido
- [ ] **NÃO SUPORTA** pagamento dividido
- [ ] `forma_pagamento_dividido` - Sempre false
- [ ] Campos de pagamento 1 e 2 - Sempre NULL

**Nota**: Delivery permite apenas uma forma de pagamento

### ✅ Campos de Cliente
- [ ] Nome
- [ ] Sobrenome
- [ ] Telefone
- [ ] Email (opcional)
- [ ] CPF (opcional)
- [ ] Endereço (obrigatório)
- [ ] Número (obrigatório)
- [ ] Complemento (opcional)
- [ ] Bairro (obrigatório)
- [ ] Cidade (obrigatório)
- [ ] Estado (obrigatório)
- [ ] CEP (obrigatório)

**Validação de CEP**:
- [ ] CEP preenchido
- [ ] CEP com formato válido
- [ ] Endereço encontrado via API
- [ ] Endereço dentro da área de entrega
- [ ] Distância calculada com sucesso

**Onde Usar**:
- Salvar em `pedidos.cliente_*`
- Criar/atualizar em `clientes`
- Copiar para `historico_geral`

### ✅ Cálculos
- [ ] Subtotal = Σ(Preço Item × Quantidade)
- [ ] Desconto Calculado = 0 (sempre)
- [ ] Subtotal com Desconto = Subtotal (sem desconto)
- [ ] Total = Subtotal + Taxa Entrega + Taxa Extra KM

**Onde Usar**:
- Função `calcularSubtotal()` em `useCarrinho.ts`
- Função `calcularTaxaEntrega()` em `checkoutUtils.ts`
- Função `calcularTotal()` em `checkoutUtils.ts`

### ✅ Componentes Envolvidos
- [ ] `CheckoutStepByStep.tsx` - Fluxo de checkout
- [ ] `TipoEntregaSelector.tsx` - Escolher tipo
- [ ] `FormularioEntrega.tsx` - Dados entrega com validação CEP
- [ ] `FormularioRetirada.tsx` - Dados retirada
- [ ] `ResumoPedido.tsx` - Resumo valores
- [ ] `FormasPagamento.tsx` - Formas pagamento
- [ ] `CarrinhoSheet.tsx` - Carrinho flutuante

### ✅ Hooks Envolvidos
- [ ] `useCarrinho.ts` - Gerenciamento carrinho
- [ ] `useCheckoutData.ts` - Dados checkout
- [ ] `useBuscaCEP.ts` - Busca CEP
- [ ] `useCheckoutLogic.ts` - Lógica checkout

### ✅ Serviços Envolvidos
- [ ] `pedidoService.salvar()` - Salvar pedido
- [ ] `clienteService.buscarOuCriar()` - Gerenciar cliente
- [ ] `clienteService.incrementarEstatisticas()` - Atualizar stats
- [ ] `historicoPedidoService.adicionarStatus()` - Criar histórico

### ✅ Integração WhatsApp
- [ ] Gerar mensagem com todos os dados
- [ ] Incluir código do pedido
- [ ] Incluir itens com personalizações
- [ ] Incluir subtotal, taxas, total
- [ ] Incluir forma de pagamento
- [ ] Incluir observações
- [ ] Incluir link de acompanhamento
- [ ] Enviar para número configurado

**Onde Usar**:
- Função `gerarMensagemWhatsApp()` em `checkoutUtils.ts`
- Função `enviarParaWhatsApp()` em `checkoutUtils.ts`

---

## 🔄 FLUXO DE DADOS - TABELAS

### Tabela: pedidos

```
✅ Campos de Taxa:
   - taxa_entrega (NUMERIC DEFAULT 0)
   - taxa_extra_km (DECIMAL(10,2) DEFAULT 0)
   - entrega_domicilio (BOOLEAN DEFAULT true)

✅ Campos de Desconto:
   - desconto (NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0))
   - tipo_desconto (TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual')))

✅ Campos de Pagamento Dividido:
   - forma_pagamento_dividido (BOOLEAN NOT NULL DEFAULT false)
   - pagamento_1_tipo (TEXT)
   - pagamento_1_valor (NUMERIC(10, 2))
   - pagamento_2_tipo (TEXT)
   - pagamento_2_valor (NUMERIC(10, 2))

✅ Constraints:
   - pedidos_pagamento_tipos_diferentes
   - pedidos_pagamento_valores_positivos
```

### Tabela: historico_pedidos

```
✅ Mesmos campos que pedidos:
   - desconto
   - tipo_desconto
   - forma_pagamento_dividido
   - pagamento_1_tipo
   - pagamento_1_valor
   - pagamento_2_tipo
   - pagamento_2_valor

✅ Constraints:
   - historico_pedidos_pagamento_tipos_diferentes
   - historico_pedidos_pagamento_valores_positivos
```

### Tabela: historico_geral

```
✅ Mesmos campos que pedidos:
   - taxa_entrega
   - taxa_extra_km
   - desconto
   - tipo_desconto
   - forma_pagamento_dividido
   - pagamento_1_tipo
   - pagamento_1_valor
   - pagamento_2_tipo
   - pagamento_2_valor

✅ Constraints:
   - historico_geral_pagamento_tipos_diferentes
   - historico_geral_pagamento_valores_positivos
```

### Tabela: comandas

```
✅ Campos de Desconto:
   - desconto (NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0))
   - tipo_desconto (TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual')))

✅ Campos de Pagamento Dividido:
   - forma_pagamento_dividido (BOOLEAN NOT NULL DEFAULT false)
   - pagamento_1_tipo (TEXT)
   - pagamento_1_valor (NUMERIC(10, 2))
   - pagamento_2_tipo (TEXT)
   - pagamento_2_valor (NUMERIC(10, 2))

✅ Constraints:
   - comandas_pagamento_tipos_diferentes
   - comandas_pagamento_valores_positivos

❌ NÃO TEM:
   - taxa_entrega
   - taxa_extra_km
   - entrega_domicilio
```

### Tabela: historico_comandas

```
✅ Mesmos campos que comandas:
   - desconto
   - tipo_desconto
   - forma_pagamento_dividido
   - pagamento_1_tipo
   - pagamento_1_valor
   - pagamento_2_tipo
   - pagamento_2_valor

✅ Constraints:
   - historico_comandas_pagamento_tipos_diferentes
   - historico_comandas_pagamento_valores_positivos

❌ NÃO TEM:
   - taxa_entrega
   - taxa_extra_km
```

---

## 🎯 CHECKLIST DE IMPLEMENTAÇÃO

### Ao Adicionar Novo Campo de Taxa/Desconto/Pagamento

- [ ] Adicionar coluna na tabela `pedidos`
- [ ] Adicionar coluna na tabela `historico_pedidos`
- [ ] Adicionar coluna na tabela `historico_geral`
- [ ] Adicionar coluna na tabela `comandas` (se aplicável)
- [ ] Adicionar coluna na tabela `historico_comandas` (se aplicável)
- [ ] Adicionar validação em `descontoValidation.ts`
- [ ] Adicionar cálculo em `descontoCalculation.ts` ou `calculos.ts`
- [ ] Atualizar componentes de UI
- [ ] Atualizar hooks de lógica
- [ ] Atualizar serviços
- [ ] Adicionar testes em `splitPayment.e2e.test.ts`
- [ ] Atualizar documentação

### Ao Modificar Cálculo de Valores

- [ ] Testar em PDV
- [ ] Testar em Comandas
- [ ] Testar em Delivery
- [ ] Verificar histórico
- [ ] Verificar impressão (Comandas)
- [ ] Verificar WhatsApp (Delivery)
- [ ] Executar testes automatizados

### Ao Adicionar Nova Forma de Pagamento

- [ ] Adicionar em `configuracoes.metodos_pagamento`
- [ ] Atualizar `FormasPagamento.tsx`
- [ ] Atualizar `checkoutUtils.ts`
- [ ] Atualizar `PagamentoDividido.tsx` (se aplicável)
- [ ] Testar em todos os fluxos
- [ ] Atualizar documentação

---

## 📊 MATRIZ DE COMPATIBILIDADE

| Recurso | PDV | Comandas | Delivery |
|---------|-----|----------|----------|
| Taxa Entrega | ✅ | ❌ | ✅ |
| Taxa Extra KM | ✅ | ❌ | ✅ |
| Desconto Manual | ✅ | ✅ | ❌ |
| Pagamento Dividido | ✅ | ✅ | ❌ |
| Validação CEP | ❌ | ❌ | ✅ |
| Impressão | ❌ | ✅ | ❌ |
| WhatsApp | ❌ | ❌ | ✅ |
| Histórico | ✅ | ✅ | ✅ |
| Múltiplas Formas | 5 | 4 | 8 |

---

## 🚨 ERROS COMUNS A EVITAR

- ❌ Esquecer de copiar campos para histórico
- ❌ Não validar desconto antes de salvar
- ❌ Não verificar soma de pagamento dividido
- ❌ Usar tipos de pagamento iguais em split payment
- ❌ Não arredondar distância corretamente para taxa extra km
- ❌ Aplicar desconto DEPOIS das taxas (ordem errada)
- ❌ Permitir desconto > subtotal
- ❌ Não usar `.toFixed(2)` para valores monetários
- ❌ Esquecer de atualizar estatísticas do cliente
- ❌ Não validar dados de entrega em delivery


# 🔍 ÍNDICE DE REFERÊNCIA RÁPIDA

## 📚 Documentos Disponíveis

1. **MAPEAMENTO_FLUXOS_PAGAMENTO.md** - Análise completa dos 3 fluxos
2. **DETALHES_TECNICOS_PAGAMENTO.md** - Implementação técnica detalhada
3. **CHECKLIST_CAMPOS_PAGAMENTO.md** - Checklist de validação
4. **RESUMO_EXECUTIVO_PAGAMENTOS.md** - Visão geral executiva
5. **INDICE_REFERENCIA_RAPIDA.md** - Este arquivo

---

## 🎯 Encontre Rapidamente

### Por Fluxo

#### PDV (Ponto de Venda)
- **Página**: `src/pages/PDV.tsx`
- **Hook Principal**: `src/hooks/useFinalizarPedidoPDV.ts`
- **Componentes**: `src/components/pdv/`
- **Serviço**: `src/services/pedidoService.ts`
- **Características**: Taxa entrega, taxa extra km, desconto manual, pagamento dividido
- **Documentação**: Ver seção "1️⃣ FLUXO PDV" em MAPEAMENTO_FLUXOS_PAGAMENTO.md

#### Comandas
- **Página**: `src/pages/Comandas.tsx`
- **Serviço**: `src/services/comandaService.ts`
- **Componentes**: Reutiliza componentes do PDV
- **Características**: Desconto manual, pagamento dividido, impressão térmica
- **Documentação**: Ver seção "2️⃣ FLUXO COMANDAS" em MAPEAMENTO_FLUXOS_PAGAMENTO.md

#### Delivery
- **Página**: `src/pages/DeliveryPage.tsx`
- **Checkout**: `src/components/CheckoutStepByStep.tsx`
- **Componentes**: `src/components/checkout/`
- **Serviço**: `src/services/pedidoService.ts`
- **Características**: Taxa entrega, taxa extra km, validação CEP, WhatsApp
- **Documentação**: Ver seção "3️⃣ FLUXO DELIVERY" em MAPEAMENTO_FLUXOS_PAGAMENTO.md

---

### Por Funcionalidade

#### Taxa de Entrega
- **Arquivo**: `src/utils/calculos.ts`
- **Função**: `calcularTaxaEntrega()`
- **Fluxos**: PDV, Delivery
- **Campo BD**: `pedidos.taxa_entrega`
- **Documentação**: Ver "Campos de Taxa" em MAPEAMENTO_FLUXOS_PAGAMENTO.md

#### Taxa Extra por KM
- **Arquivo**: `src/utils/calculos.ts`
- **Função**: `calcularTaxaExtraKm()`, `arredondarDistanciaKm()`
- **Fluxos**: PDV, Delivery
- **Campo BD**: `pedidos.taxa_extra_km`
- **Documentação**: Ver "Cálculo de Taxa Extra KM" em MAPEAMENTO_FLUXOS_PAGAMENTO.md

#### Desconto Manual
- **Arquivo**: `src/utils/descontoCalculation.ts`
- **Função**: `calcularDescontoEmReais()`, `calcularResumoValores()`
- **Fluxos**: PDV, Comandas
- **Campos BD**: `pedidos.desconto`, `pedidos.tipo_desconto`
- **Validação**: `src/utils/descontoValidation.ts`
- **Documentação**: Ver "Campos de Desconto" em MAPEAMENTO_FLUXOS_PAGAMENTO.md

#### Pagamento Dividido
- **Arquivo**: `src/components/PagamentoDividido.tsx`
- **Fluxos**: PDV, Comandas
- **Campos BD**: `forma_pagamento_dividido`, `pagamento_1_tipo`, `pagamento_1_valor`, `pagamento_2_tipo`, `pagamento_2_valor`
- **Validações**: Tipos diferentes, valores positivos, soma correta
- **Documentação**: Ver "Pagamento Dividido" em MAPEAMENTO_FLUXOS_PAGAMENTO.md

#### Validação de CEP
- **Arquivo**: `src/components/checkout/FormularioEntrega.tsx`
- **Hook**: `src/hooks/useBuscaCEP.ts`
- **Fluxo**: Delivery
- **Integração**: ViaCEP API
- **Documentação**: Ver "Validação de Endereço (Delivery)" em MAPEAMENTO_FLUXOS_PAGAMENTO.md

#### Impressão de Comandas
- **Arquivo**: `src/pages/Comandas.tsx`
- **Serviço**: `src/lib/qzTrayService.ts`
- **Função**: `imprimirComanda()`, `gerarHTMLImpressaoComanda()`
- **Fluxo**: Comandas
- **Documentação**: Ver "Impressão de Comandas" em MAPEAMENTO_FLUXOS_PAGAMENTO.md

#### Integração WhatsApp
- **Arquivo**: `src/components/checkout/checkoutUtils.ts`
- **Funções**: `gerarMensagemWhatsApp()`, `enviarParaWhatsApp()`
- **Fluxo**: Delivery
- **Documentação**: Ver "Integração WhatsApp (Delivery)" em MAPEAMENTO_FLUXOS_PAGAMENTO.md

---

### Por Tipo de Campo

#### Campos de Taxa
```
taxa_entrega (NUMERIC)
taxa_extra_km (DECIMAL(10,2))
entrega_domicilio (BOOLEAN)

Tabelas: pedidos, historico_pedidos, historico_geral
Fluxos: PDV, Delivery
Arquivo: src/utils/calculos.ts
```

#### Campos de Desconto
```
desconto (NUMERIC)
tipo_desconto (TEXT: 'valor'|'percentual')

Tabelas: pedidos, historico_pedidos, historico_geral, comandas, historico_comandas
Fluxos: PDV, Comandas
Arquivo: src/utils/descontoCalculation.ts
```

#### Campos de Pagamento Dividido
```
forma_pagamento_dividido (BOOLEAN)
pagamento_1_tipo (TEXT)
pagamento_1_valor (NUMERIC(10,2))
pagamento_2_tipo (TEXT)
pagamento_2_valor (NUMERIC(10,2))

Tabelas: pedidos, historico_pedidos, historico_geral, comandas, historico_comandas
Fluxos: PDV, Comandas
Arquivo: src/components/PagamentoDividido.tsx
```

---

### Por Arquivo

#### src/utils/calculos.ts
- `calcularPrecoItem()` - Preço de um item
- `calcularSubtotal()` - Soma de todos os itens
- `calcularTaxaEntrega()` - Taxa de entrega
- `calcularDesconto()` - Desconto percentual
- `calcularTotal()` - Total final
- `arredondarDistanciaKm()` - Arredonda distância
- `calcularTaxaExtraKm()` - Taxa por km
- `calcularTaxaEntregaTotal()` - Taxa total

#### src/utils/descontoCalculation.ts
- `calcularDescontoEmReais()` - Converte desconto para R$
- `calcularResumoValores()` - Resumo completo com desconto

#### src/utils/descontoValidation.ts
- `validarDesconto()` - Valida desconto

#### src/components/PagamentoDividido.tsx
- Componente de UI para pagamento dividido
- Validações em tempo real
- Formatação de moeda

#### src/components/checkout/checkoutUtils.ts
- `validarEtapa1()` - Validar dados de entrega
- `validarEtapa2()` - Validar forma de pagamento
- `gerarMensagemWhatsApp()` - Gerar mensagem
- `enviarParaWhatsApp()` - Enviar para WhatsApp
- `finalizarPedido()` - Finalizar pedido

#### src/hooks/useFinalizarPedidoPDV.ts
- `validarDescontoEmTempoReal()` - Validar desconto
- `calcularResumo()` - Calcular resumo
- `validarPedido()` - Validar pedido
- `finalizarPedido()` - Finalizar e salvar

#### src/services/pedidoService.ts
- `gerarCodigoUnico()` - Gerar código
- `salvar()` - Salvar pedido
- `buscarPorCodigo()` - Buscar por código
- `atualizarStatus()` - Atualizar status

#### src/services/comandaService.ts
- `buscarAbertaPorNumero()` - Buscar comanda
- `criar()` - Criar comanda
- `atualizar()` - Atualizar comanda
- `finalizar()` - Finalizar comanda
- `moverParaHistorico()` - Mover para histórico

---

### Por Tabela do Banco

#### pedidos
```
Campos de Taxa:
  - taxa_entrega
  - taxa_extra_km
  - entrega_domicilio

Campos de Desconto:
  - desconto
  - tipo_desconto

Campos de Pagamento Dividido:
  - forma_pagamento_dividido
  - pagamento_1_tipo
  - pagamento_1_valor
  - pagamento_2_tipo
  - pagamento_2_valor

Constraints:
  - pedidos_pagamento_tipos_diferentes
  - pedidos_pagamento_valores_positivos
```

#### historico_pedidos
```
Cópia de todos os campos de pedidos
Mesmas constraints
```

#### historico_geral
```
Cópia de todos os campos de pedidos
Mesmas constraints
```

#### comandas
```
Campos de Desconto:
  - desconto
  - tipo_desconto

Campos de Pagamento Dividido:
  - forma_pagamento_dividido
  - pagamento_1_tipo
  - pagamento_1_valor
  - pagamento_2_tipo
  - pagamento_2_valor

Constraints:
  - comandas_pagamento_tipos_diferentes
  - comandas_pagamento_valores_positivos

NÃO TEM:
  - taxa_entrega
  - taxa_extra_km
  - entrega_domicilio
```

#### historico_comandas
```
Cópia de todos os campos de comandas
Mesmas constraints
```

---

### Por Tipo de Validação

#### Validação de Desconto
- **Arquivo**: `src/utils/descontoValidation.ts`
- **Função**: `validarDesconto()`
- **Regras**:
  - Não pode ser negativo
  - Se valor: ≤ subtotal
  - Se percentual: ≤ 100%

#### Validação de Pagamento Dividido
- **Arquivo**: `src/components/PagamentoDividido.tsx`
- **Regras**:
  - Tipos devem ser diferentes
  - Ambos valores > 0
  - Soma = total do pedido

#### Validação de CEP
- **Arquivo**: `src/components/checkout/FormularioEntrega.tsx`
- **Regras**:
  - CEP válido
  - Endereço encontrado
  - Dentro da área de entrega

#### Validação de Pedido
- **Arquivo**: `src/hooks/useFinalizarPedidoPDV.ts`
- **Função**: `validarPedido()`
- **Regras**:
  - Carrinho não vazio
  - Dados do cliente preenchidos
  - Telefone válido

---

## 🔗 Fluxos de Integração

### Adicionar Novo Campo de Taxa
1. Adicionar coluna em `pedidos`, `historico_pedidos`, `historico_geral`
2. Atualizar `src/utils/calculos.ts`
3. Atualizar componentes de UI
4. Atualizar hooks
5. Testar em PDV e Delivery

### Adicionar Nova Forma de Pagamento
1. Adicionar em `configuracoes.metodos_pagamento`
2. Atualizar `src/components/checkout/FormasPagamento.tsx`
3. Atualizar `src/components/checkout/checkoutUtils.ts`
4. Testar em todos os fluxos

### Modificar Cálculo de Desconto
1. Editar `src/utils/descontoCalculation.ts`
2. Atualizar validação em `src/utils/descontoValidation.ts`
3. Testar em PDV e Comandas
4. Verificar histórico

### Adicionar Validação de CEP
1. Editar `src/components/checkout/FormularioEntrega.tsx`
2. Atualizar `src/hooks/useBuscaCEP.ts`
3. Testar em Delivery
4. Verificar cálculo de taxa extra km

---

## 📊 Matriz de Compatibilidade Rápida

```
                PDV    Comandas  Delivery
Taxa Entrega    ✅     ❌        ✅
Taxa Extra KM   ✅     ❌        ✅
Desconto        ✅     ✅        ❌
Split Payment   ✅     ✅        ❌
Validação CEP   ❌     ❌        ✅
Impressão       ❌     ✅        ❌
WhatsApp        ❌     ❌        ✅
Histórico       ✅     ✅        ✅
```

---

## 🚀 Atalhos Úteis

### Encontrar Função de Cálculo
```bash
grep -r "calcularTaxaExtraKm" src/
grep -r "calcularDescontoEmReais" src/
grep -r "calcularResumoValores" src/
```

### Encontrar Componente de Pagamento
```bash
grep -r "PagamentoDividido" src/
grep -r "FormasPagamento" src/
grep -r "CampoDesconto" src/
```

### Encontrar Validação
```bash
grep -r "validarDesconto" src/
grep -r "validarPedido" src/
grep -r "validarEtapa" src/
```

### Executar Testes
```bash
npm run test -- splitPayment.e2e.test.ts
npm run test -- descontoCalculation.test.ts
npm run test -- descontoValidation.test.ts
```

---

## 💡 Dicas Rápidas

### Para Entender o Fluxo PDV
1. Abrir `src/pages/PDV.tsx`
2. Procurar por `handleFinalizarPedido`
3. Seguir para `useFinalizarPedidoPDV.ts`
4. Ver função `finalizarPedido()`

### Para Entender o Fluxo Delivery
1. Abrir `src/pages/DeliveryPage.tsx`
2. Procurar por `onNavigateToCheckout`
3. Ir para `src/components/CheckoutStepByStep.tsx`
4. Ver função `handleFinalizarPedido()`

### Para Entender Cálculo de Desconto
1. Abrir `src/utils/descontoCalculation.ts`
2. Ver função `calcularDescontoEmReais()`
3. Ver função `calcularResumoValores()`
4. Verificar testes em `descontoCalculation.test.ts`

### Para Entender Pagamento Dividido
1. Abrir `src/components/PagamentoDividido.tsx`
2. Ver validações em tempo real
3. Verificar constraints no banco
4. Ver testes em `splitPayment.e2e.test.ts`

---

## 📞 Perguntas Frequentes

**P: Onde está o cálculo de taxa extra por km?**
R: `src/utils/calculos.ts` - Função `calcularTaxaExtraKm()`

**P: Como validar desconto?**
R: `src/utils/descontoValidation.ts` - Função `validarDesconto()`

**P: Onde está a lógica de pagamento dividido?**
R: `src/components/PagamentoDividido.tsx` - Validações em tempo real

**P: Como buscar CEP?**
R: `src/components/checkout/FormularioEntrega.tsx` - Integração com ViaCEP

**P: Onde está a impressão de comandas?**
R: `src/pages/Comandas.tsx` - Função `imprimirComanda()`

**P: Como enviar para WhatsApp?**
R: `src/components/checkout/checkoutUtils.ts` - Função `enviarParaWhatsApp()`

**P: Qual é a fórmula de cálculo?**
R: `Total = (Subtotal - Desconto) + Taxa Entrega + Taxa Extra KM`

**P: Como arredondar distância?**
R: `src/utils/calculos.ts` - Função `arredondarDistanciaKm()`

---

## 🎓 Recursos de Aprendizado

### Entender o Sistema
1. Ler `RESUMO_EXECUTIVO_PAGAMENTOS.md` (5 min)
2. Ler `MAPEAMENTO_FLUXOS_PAGAMENTO.md` (20 min)
3. Ler `DETALHES_TECNICOS_PAGAMENTO.md` (30 min)

### Implementar Mudança
1. Consultar `CHECKLIST_CAMPOS_PAGAMENTO.md`
2. Localizar arquivos em "Por Arquivo"
3. Seguir checklist de implementação
4. Testar em todos os fluxos

### Debugar Problema
1. Identificar qual fluxo (PDV/Comandas/Delivery)
2. Localizar arquivo principal em "Por Fluxo"
3. Procurar função relevante em "Por Funcionalidade"
4. Verificar validações em "Por Tipo de Validação"

---

**Última Atualização**: 31/01/2026  
**Versão**: 1.0  
**Status**: ✅ Completo


# 📊 RESUMO EXECUTIVO - FLUXOS DE PAGAMENTO

## 🎯 Visão Geral em 30 Segundos

O sistema possui **3 fluxos de pagamento distintos**:

1. **PDV** - Vendas no balcão com taxa de entrega, desconto manual e pagamento dividido
2. **Comandas** - Vendas no estabelecimento com desconto manual e pagamento dividido
3. **Delivery** - Vendas online com taxa de entrega, taxa extra por km e múltiplas formas de pagamento

---

## 📈 Diagrama de Fluxos

```
┌─────────────────────────────────────────────────────────────────┐
│                    SISTEMA DE PAGAMENTOS                        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│      PDV         │    │    COMANDAS      │    │    DELIVERY      │
│  (Balcão)        │    │   (Mesas)        │    │   (Online)       │
└──────────────────┘    └──────────────────┘    └──────────────────┘
        │                       │                       │
        ├─ Produto             ├─ Produto             ├─ Produto
        ├─ Quantidade          ├─ Quantidade          ├─ Quantidade
        ├─ Personalização      ├─ Personalização      ├─ Personalização
        └─ Subtotal            └─ Subtotal            └─ Subtotal
        │                       │                       │
        ├─ Taxa Entrega        ├─ (Sem Taxa)          ├─ Taxa Entrega
        ├─ Taxa Extra KM       ├─ (Sem Taxa)          ├─ Taxa Extra KM
        └─ Desconto Manual      └─ Desconto Manual     └─ (Sem Desconto)
        │                       │                       │
        ├─ Forma Pagamento     ├─ Forma Pagamento     ├─ Forma Pagamento
        ├─ Pagamento Dividido  ├─ Pagamento Dividido  └─ (Sem Split)
        └─ Dados Cliente        └─ (Sem Dados)         │
        │                       │                       ├─ Validação CEP
        ├─ Salvar Pedido       ├─ Salvar Comanda      ├─ Cálculo Taxa KM
        ├─ Atualizar Cliente   ├─ Mover Histórico     ├─ Enviar WhatsApp
        └─ Histórico            ├─ Imprimir            └─ Histórico
                                └─ Histórico
```

---

## 💰 Fórmula de Cálculo

```
┌─────────────────────────────────────────────────────────────┐
│  TOTAL = (SUBTOTAL - DESCONTO) + TAXA_ENTREGA + TAXA_EXTRA_KM │
└─────────────────────────────────────────────────────────────┘

Exemplo PDV:
  Subtotal:        R$ 100,00
  - Desconto:      R$  10,00  (10% de R$ 100)
  = Subtotal Desc: R$  90,00
  + Taxa Entrega:  R$   5,00
  + Taxa Extra KM: R$   2,00
  ─────────────────────────────
  = TOTAL:         R$  97,00

Exemplo Delivery:
  Subtotal:        R$ 150,00
  - Desconto:      R$   0,00  (sem desconto manual)
  = Subtotal Desc: R$ 150,00
  + Taxa Entrega:  R$   8,00
  + Taxa Extra KM: R$   3,00  (para 5km)
  ─────────────────────────────
  = TOTAL:         R$ 161,00
```

---

## 🗂️ Estrutura de Dados

### Campos Essenciais em Todas as Tabelas

```
┌─────────────────────────────────────────────────────────────┐
│                    TABELAS PRINCIPAIS                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  pedidos                                                   │
│  ├─ taxa_entrega (NUMERIC)                                │
│  ├─ taxa_extra_km (DECIMAL)                               │
│  ├─ desconto (NUMERIC)                                    │
│  ├─ tipo_desconto (TEXT: 'valor'|'percentual')           │
│  ├─ forma_pagamento_dividido (BOOLEAN)                    │
│  ├─ pagamento_1_tipo (TEXT)                               │
│  ├─ pagamento_1_valor (NUMERIC)                           │
│  ├─ pagamento_2_tipo (TEXT)                               │
│  └─ pagamento_2_valor (NUMERIC)                           │
│                                                             │
│  historico_pedidos (cópia de pedidos)                     │
│  historico_geral (cópia de pedidos)                       │
│                                                             │
│  comandas                                                  │
│  ├─ desconto (NUMERIC)                                    │
│  ├─ tipo_desconto (TEXT: 'valor'|'percentual')           │
│  ├─ forma_pagamento_dividido (BOOLEAN)                    │
│  ├─ pagamento_1_tipo (TEXT)                               │
│  ├─ pagamento_1_valor (NUMERIC)                           │
│  ├─ pagamento_2_tipo (TEXT)                               │
│  └─ pagamento_2_valor (NUMERIC)                           │
│                                                             │
│  historico_comandas (cópia de comandas)                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Fluxo de Dados - Visão Geral

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUXO DE DADOS                           │
└─────────────────────────────────────────────────────────────┘

1. ENTRADA
   ├─ Usuário seleciona produtos
   ├─ Personaliza (sabores, tamanhos, adicionais)
   └─ Adiciona ao carrinho

2. PROCESSAMENTO
   ├─ Calcular subtotal
   ├─ Aplicar desconto (se houver)
   ├─ Calcular taxas (se aplicável)
   ├─ Validar dados
   └─ Calcular total

3. PAGAMENTO
   ├─ Selecionar forma de pagamento
   ├─ Opção de pagamento dividido (PDV/Comandas)
   ├─ Dados do cliente (PDV/Delivery)
   └─ Observações (opcional)

4. SALVAMENTO
   ├─ Salvar em pedidos/comandas
   ├─ Atualizar cliente (se novo)
   ├─ Criar histórico
   ├─ Imprimir (Comandas)
   └─ Enviar WhatsApp (Delivery)

5. SAÍDA
   ├─ Código do pedido
   ├─ Confirmação
   └─ Acompanhamento
```

---

## 📋 Comparativo Rápido

| Aspecto | PDV | Comandas | Delivery |
|---------|-----|----------|----------|
| **Tipo** | Balcão | Mesas | Online |
| **Taxa Entrega** | ✅ Sim | ❌ Não | ✅ Sim |
| **Taxa Extra KM** | ✅ Sim | ❌ Não | ✅ Sim |
| **Desconto Manual** | ✅ Sim | ✅ Sim | ❌ Não |
| **Pagamento Dividido** | ✅ Sim | ✅ Sim | ❌ Não |
| **Formas Pagamento** | 5 | 4 | 8 |
| **Validação CEP** | ❌ Não | ❌ Não | ✅ Sim |
| **Impressão** | ❌ Não | ✅ Sim | ❌ Não |
| **WhatsApp** | ❌ Não | ❌ Não | ✅ Sim |
| **Dados Cliente** | ✅ Sim | ❌ Não | ✅ Sim |
| **Histórico** | ✅ Sim | ✅ Sim | ✅ Sim |

---

## 🎯 Casos de Uso Principais

### PDV - Caso 1: Venda com Desconto e Entrega

```
Cliente: João Silva
Produtos: 2x Pizza Grande (R$ 50 cada) = R$ 100
Desconto: 10% = R$ 10
Taxa Entrega: R$ 5
Taxa Extra KM: R$ 2 (para 5km)
Forma Pagamento: Dinheiro com troco para R$ 150

Total = (100 - 10) + 5 + 2 = R$ 97
Troco = 150 - 97 = R$ 53
```

### PDV - Caso 2: Venda com Pagamento Dividido

```
Cliente: Maria Santos
Produtos: 1x Pizza Grande (R$ 50) = R$ 50
Desconto: R$ 5 (valor fixo)
Taxa Entrega: R$ 5
Taxa Extra KM: R$ 0
Forma Pagamento: Dividido
  - PIX: R$ 25
  - Dinheiro: R$ 25

Total = (50 - 5) + 5 + 0 = R$ 50
```

### Comandas - Caso 1: Comanda com Desconto

```
Comanda: #5
Produtos: 3x Cerveja (R$ 10 cada) = R$ 30
Desconto: 15% = R$ 4,50
Forma Pagamento: Cartão Crédito

Total = 30 - 4,50 = R$ 25,50
```

### Delivery - Caso 1: Pedido com Taxa Extra KM

```
Cliente: Pedro Costa
Produtos: 1x Pizza Grande (R$ 50) = R$ 50
CEP: 01310-100 (São Paulo)
Distância: 5,2km → arredonda para 5km
Taxa Entrega: R$ 8
Taxa Extra KM: R$ 3 (para 5km)
Forma Pagamento: PIX

Total = 50 + 8 + 3 = R$ 61
```

---

## 🔐 Validações Críticas

### Desconto
```
✅ Não pode ser negativo
✅ Se tipo='valor': desconto ≤ subtotal
✅ Se tipo='percentual': desconto ≤ 100%
✅ Aplicado ANTES das taxas
```

### Pagamento Dividido
```
✅ Tipos devem ser DIFERENTES
✅ Ambos valores > 0
✅ Soma dos valores = total do pedido
✅ Ambos campos preenchidos
```

### Taxa Extra KM
```
✅ Distância arredondada (≤0.5 para baixo, >0.5 para cima)
✅ Busca configuração exata para o km
✅ Se não encontrar, usa km mais próximo abaixo
✅ Sempre ≥ 0
```

### Dados de Entrega (Delivery)
```
✅ CEP preenchido e válido
✅ Endereço encontrado via API
✅ Número preenchido
✅ Bairro preenchido
✅ Cidade preenchida
✅ Estado preenchido
```

---

## 📁 Arquivos Principais

### Lógica de Cálculo
- `src/utils/calculos.ts` - Cálculos de preço e taxa
- `src/utils/descontoCalculation.ts` - Cálculos de desconto
- `src/utils/descontoValidation.ts` - Validação de desconto

### PDV
- `src/pages/PDV.tsx` - Página principal
- `src/hooks/useFinalizarPedidoPDV.ts` - Lógica de finalização
- `src/components/pdv/ModalFinalizarPedido.tsx` - Modal de finalização

### Comandas
- `src/pages/Comandas.tsx` - Página principal
- `src/services/comandaService.ts` - Serviço de comandas

### Delivery
- `src/pages/DeliveryPage.tsx` - Página principal
- `src/components/CheckoutStepByStep.tsx` - Fluxo de checkout
- `src/components/checkout/checkoutUtils.ts` - Utilitários

### Banco de Dados
- `BD_20_01/03_tables.sql` - Definição de tabelas
- `adicionar_colunas_desconto.sql` - Migração de desconto

---

## 🚀 Próximos Passos

### Para Entender o Sistema
1. Ler `MAPEAMENTO_FLUXOS_PAGAMENTO.md` - Visão completa dos 3 fluxos
2. Ler `DETALHES_TECNICOS_PAGAMENTO.md` - Implementação técnica
3. Ler `CHECKLIST_CAMPOS_PAGAMENTO.md` - Validação de campos

### Para Modificar o Sistema
1. Identificar qual fluxo será modificado (PDV/Comandas/Delivery)
2. Localizar arquivos relevantes em "Arquivos Principais"
3. Seguir checklist em `CHECKLIST_CAMPOS_PAGAMENTO.md`
4. Testar em todos os fluxos afetados
5. Atualizar documentação

### Para Adicionar Novo Recurso
1. Verificar compatibilidade em "Comparativo Rápido"
2. Adicionar campos no banco de dados
3. Atualizar componentes de UI
4. Atualizar lógica de cálculo
5. Adicionar validações
6. Testar e documentar

---

## 📞 Suporte Rápido

### Dúvida: "Onde está o cálculo de desconto?"
→ `src/utils/descontoCalculation.ts` - Função `calcularDescontoEmReais()`

### Dúvida: "Como validar pagamento dividido?"
→ `src/components/PagamentoDividido.tsx` - Validações em tempo real

### Dúvida: "Onde está a taxa extra por km?"
→ `src/utils/calculos.ts` - Função `calcularTaxaExtraKm()`

### Dúvida: "Como buscar CEP?"
→ `src/components/checkout/FormularioEntrega.tsx` - Integração com ViaCEP

### Dúvida: "Onde está a impressão de comandas?"
→ `src/pages/Comandas.tsx` - Função `imprimirComanda()`

### Dúvida: "Como enviar para WhatsApp?"
→ `src/components/checkout/checkoutUtils.ts` - Função `enviarParaWhatsApp()`

---

## 🎓 Conceitos-Chave

### Ordem de Cálculo
```
1. Calcular Subtotal (soma dos itens)
2. Aplicar Desconto (subtrai do subtotal)
3. Adicionar Taxas (soma taxa entrega + taxa extra km)
4. Resultado = Total Final
```

### Arredondamento de KM
```
3.5km → 3km (≤0.5 arredonda para baixo)
4.6km → 5km (>0.5 arredonda para cima)
```

### Precisão Decimal
```
Sempre usar .toFixed(2) para valores monetários
Exemplo: (100 * 0.15).toFixed(2) = "15.00"
```

### Histórico
```
Todos os campos de taxa, desconto e pagamento
são copiados para as tabelas de histórico
```

---

## 📊 Estatísticas do Sistema

- **3 Fluxos** de pagamento
- **8 Formas** de pagamento (Delivery)
- **2 Tipos** de desconto (valor e percentual)
- **2 Formas** de entrega (domicílio e retirada)
- **24 Comandas** (1-24)
- **4 Tabelas** principais (pedidos, comandas, históricos)
- **9 Campos** de taxa/desconto/pagamento por tabela
- **2 Constraints** de validação por tabela

---

## ✅ Checklist Final

Antes de fazer qualquer mudança:

- [ ] Li `MAPEAMENTO_FLUXOS_PAGAMENTO.md`?
- [ ] Entendi qual fluxo será modificado?
- [ ] Identifiquei todos os arquivos afetados?
- [ ] Verifiquei compatibilidade com outros fluxos?
- [ ] Planejei testes para validar mudanças?
- [ ] Atualizei documentação?

---

**Última Atualização**: 31/01/2026  
**Versão**: 1.0  
**Status**: ✅ Completo e Validado


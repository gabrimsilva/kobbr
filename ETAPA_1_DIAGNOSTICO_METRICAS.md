# 📊 ETAPA 1 — DIAGNÓSTICO DO MÓDULO DE MÉTRICAS

## ✅ STATUS: DIAGNÓSTICO COMPLETO - AGUARDANDO APROVAÇÃO

---

## 📁 ARQUIVOS IDENTIFICADOS

### Arquivos Principais
1. **`src/pages/Metricas.tsx`** (1709 linhas)
   - Página principal do módulo de métricas
   - Contém toda a lógica de cálculo e visualização

2. **`src/components/RelatorioMetricas.tsx`**
   - Componente para geração de relatório PDF
   - Usa jsPDF e autoTable

### Tabelas do Banco Utilizadas (SISTEMA ANTIGO)
- `pedidos` - Pedidos ativos (delivery/balcão)
- `historico_geral` - Histórico de pedidos
- `historico_comandas` - Histórico de comandas (mesas)

---

## 📊 CARDS ATUAIS E O QUE REPRESENTAM

### Seção 1: Vendas Balcão (🛒)
| Card | Métrica | Fonte de Dados |
|------|---------|----------------|
| **Vendas Balcão** | `totalVendasDelivery` | Soma de `pedidos.total` + `historico_geral.total` |
| **Pedidos Balcão** | `totalPedidosDelivery` | Count de pedidos (excluindo cancelados) |
| **Ticket Médio** | `ticketMedioDelivery` | totalVendasDelivery / totalPedidosDelivery |
| **Produtos Vendidos** | Soma de quantidades | Itens dentro de `pedidos.itens[]` |

### Seção 2: Vendas Mesa (🍽️)
| Card | Métrica | Fonte de Dados |
|------|---------|----------------|
| **Vendas Mesa** | `totalVendasPresencial` | Soma de `historico_comandas.total` |
| **Atendimentos Mesa** | `totalComandasPresencial` | Count de comandas finalizadas |
| **Ticket Médio** | `ticketMedioPresencial` | totalVendasPresencial / totalComandasPresencial |
| **Total Geral** | `totalVendas` | totalVendasDelivery + totalVendasPresencial |

---

## 📈 GRÁFICOS E SUAS FONTES DE DADOS

### Aba: Vendas
| Gráfico | Tipo | Dados | Fonte |
|---------|------|-------|-------|
| **Vendas por Dia** | Linha | `vendasPorDia[]` | Agrupa pedidos e comandas por dia (dd/MM) |
| | | - `totalDelivery` | Soma diária de pedidos |
| | | - `totalComandas` | Soma diária de comandas |

### Aba: Produtos
| Gráfico | Tipo | Dados | Fonte |
|---------|------|-------|-------|
| **Produtos Mais Vendidos** | Barra Horizontal | `produtosMaisVendidos[]` | Extrai de `pedidos.itens[]` |
| | | - `nome` | Nome do produto |
| | | - `quantidade` | Soma de quantidades |
| **Faturamento por Produto** | Barra Horizontal | `produtosMaisVendidos[]` | Mesmo array, mostra `total` |

### Aba: Categorias
| Gráfico | Tipo | Dados | Fonte |
|---------|------|-------|-------|
| **Vendas por Categoria** | Pizza | `vendasPorCategoria[]` | Agrupa por `item.produto.categoria_nome` |
| **Quantidade por Categoria** | Barra | `vendasPorCategoria[]` | Mesmo array, mostra quantidade |

### Aba: Pagamento
| Gráfico | Tipo | Dados | Fonte |
|---------|------|-------|-------|
| **Formas de Pagamento - Balcão** | Barra | `formasPagamento[]` | De `pedidos.forma_pagamento` |
| | | | Suporta pagamento dividido |
| **Formas de Pagamento - Mesa** | Barra | `formasPagamentoComandas[]` | De `historico_comandas.forma_pagamento` |
| **Status dos Pedidos** | Pizza | `statusPedidos[]` | De `pedidos.status` + cancelados |

### Aba: Entrega
| Gráfico | Tipo | Dados | Fonte |
|---------|------|-------|-------|
| **Tipos de Entrega** | Pizza | `tiposEntrega[]` | Delivery vs Retirada |
| | | | Baseado em `pedidos.entrega_domicilio` |
| **Faturamento por Tipo** | Barra | `tiposEntrega[]` | Mesmo array, mostra total |
| **Top 10 Bairros** | Barra Horizontal | `locaisEntrega[]` | De `pedidos.cliente_bairro` |
| **Faturamento por Bairro** | Barra Horizontal | `locaisEntrega[]` | Mesmo array, mostra total |

### Aba: Faturamento
| Gráfico | Tipo | Dados | Fonte |
|---------|------|-------|-------|
| **Distribuição de Faturamento** | Pizza | Calculado | Mesa + Balcão Entrega + Balcão Retirada |
| **Comparativo Ticket Médio** | Barra | Calculado | Ticket médio por tipo |
| **Volume de Vendas por Tipo** | Barra | Calculado | Quantidade por tipo |

### Aba: Cancelados
| Gráfico | Tipo | Dados | Fonte |
|---------|------|-------|-------|
| **Cancelamentos por Dia** | Linha | `canceladosPorDia[]` | Pedidos com `cancelado = true` |
| | | | Filtrado por `cancelado_em` |

**Cards de Cancelamentos:**
- Total Cancelados
- Valor Total Cancelado
- Valor Total de Extornos

### Aba: Entregas
| Gráfico | Tipo | Dados | Fonte |
|---------|------|-------|-------|
| **Entregas por Dia** | Linha | `entregasPorDia[]` | Pedidos com `entrega_domicilio = true` |
| | | - `quantidade` | Count de entregas |
| | | - `valorTaxas` | Soma de `taxa_entrega` + `taxa_extra_km` |

**Cards de Entregas:**
- Total de Entregas
- Valor Total das Entregas
- Total em Taxas de Entrega

---

## 🔍 MÉTRICAS QUE VÊM DE PEDIDOS/COMANDAS/ENTREGAS

### ❌ MÉTRICAS DO SISTEMA ANTIGO (DELIVERY/COMANDAS)

#### Baseadas em Pedidos (Delivery):
- ✅ Total de vendas delivery
- ✅ Total de pedidos delivery
- ✅ Ticket médio delivery
- ✅ Produtos mais vendidos (de pedidos.itens)
- ✅ Vendas por categoria (de pedidos.itens)
- ✅ Formas de pagamento (de pedidos.forma_pagamento)
- ✅ Status dos pedidos (de pedidos.status)
- ❌ **Tipos de entrega** (Delivery vs Retirada) - baseado em `entrega_domicilio`
- ❌ **Locais de entrega** (bairros) - baseado em `cliente_bairro`
- ❌ **Cancelamentos** - baseado em `pedidos.cancelado`
- ❌ **Entregas** - baseado em `entrega_domicilio = true`
- ❌ **Taxas de entrega** - baseado em `taxa_entrega` + `taxa_extra_km`

#### Baseadas em Comandas (Mesas):
- ✅ Total de vendas presencial
- ✅ Total de comandas presencial
- ✅ Ticket médio presencial
- ✅ Formas de pagamento comandas

---

## 🎯 ARQUIVOS QUE SERÃO ALTERADOS NA ETAPA 2+

### Arquivos a Modificar:
1. ✏️ **`src/pages/Metricas.tsx`**
   - Substituir queries de `pedidos`, `historico_geral`, `historico_comandas`
   - Usar queries de `sales` (vendas do PDV)
   - Remover lógica de comandas/delivery/entregas
   - Manter estrutura de cards e gráficos

2. ✏️ **`src/components/RelatorioMetricas.tsx`**
   - Ajustar interface `MetricasResumo`
   - Remover seções de comandas/delivery do PDF
   - Adicionar seções de vendas por forma de pagamento

### Arquivos a Criar (Opcional):
- `src/services/metricasService.ts` - Centralizar lógica de cálculo de métricas

---

## 📋 MAPEAMENTO: ANTIGO → NOVO

### Dados Disponíveis na Tabela `sales`:
```typescript
interface Sale {
  id: string
  sale_number: string              // Número da venda
  total_amount: number              // Valor total ✅
  payment_method: 'DEBIT' | 'CREDIT' | 'PIX' | 'CASH'  // Forma de pagamento ✅
  needs_change: boolean             // Se precisa troco
  change_amount?: number            // Valor do troco
  sale_type: string                 // Tipo de venda (PDV, DELIVERY, etc)
  items: any[]                      // Itens da venda ✅
  notes?: string                    // Observações
  created_by?: string               // Usuário que criou
  created_at: string                // Data/hora ✅
  updated_at: string
}
```

### Mapeamento de Métricas:

| Métrica Antiga | Métrica Nova | Fonte Nova |
|----------------|--------------|------------|
| `totalVendasDelivery` | `faturamentoTotal` | `SUM(sales.total_amount)` |
| `totalPedidosDelivery` | `quantidadeVendas` | `COUNT(sales.id)` |
| `ticketMedioDelivery` | `ticketMedio` | `faturamentoTotal / quantidadeVendas` |
| `totalVendasPresencial` | ❌ REMOVER | Não existe mais (era comandas) |
| `totalComandasPresencial` | ❌ REMOVER | Não existe mais |
| `ticketMedioPresencial` | ❌ REMOVER | Não existe mais |
| `produtosMaisVendidos` | `produtosMaisVendidos` | De `sales.items[]` |
| `vendasPorDia` | `vendasPorDia` | Agrupar `sales` por dia |
| `vendasPorCategoria` | `vendasPorCategoria` | De `sales.items[]` (se tiver categoria) |
| `formasPagamento` | `faturamentoPorFormaPagamento` | Agrupar por `payment_method` |
| `formasPagamentoComandas` | ❌ REMOVER | Não existe mais |
| `statusPedidos` | ❌ REMOVER | Vendas não têm status |
| `tiposEntrega` | ❌ REMOVER | Não faz sentido para loja |
| `locaisEntrega` | ❌ REMOVER | Não faz sentido para loja |
| `totalCancelados` | ❌ REMOVER | Vendas não são canceladas |
| `totalEntregas` | ❌ REMOVER | Não faz sentido para loja |

---

## 🚨 IMPACTOS E RISCOS

### Impactos Principais:
1. **Mudança de Paradigma:**
   - Sistema antigo: Delivery (balcão) + Comandas (mesa)
   - Sistema novo: Apenas vendas no PDV (loja física)

2. **Perda de Funcionalidades:**
   - ❌ Não haverá mais separação Balcão vs Mesa
   - ❌ Não haverá métricas de entrega/delivery
   - ❌ Não haverá métricas de cancelamentos
   - ❌ Não haverá métricas de bairros/locais

3. **Simplificação:**
   - ✅ Módulo ficará mais simples e focado
   - ✅ Menos abas e gráficos
   - ✅ Mais rápido de carregar

### Riscos:
1. **Baixo Risco:**
   - Estrutura de cards e gráficos será mantida
   - Layout visual permanece similar
   - Apenas dados e legendas mudam

2. **Médio Risco:**
   - Usuários acostumados com métricas antigas podem estranhar
   - Necessário comunicar mudanças

3. **Mitigação:**
   - Fazer mudanças incrementais (etapa por etapa)
   - Testar cada etapa antes de avançar
   - Manter backup do código antigo

---

## 📊 ESTRUTURA PROPOSTA PARA O NOVO MÓDULO

### Cards Principais (Simplificados):
1. **Faturamento Total** - Soma de todas as vendas
2. **Quantidade de Vendas** - Total de vendas realizadas
3. **Ticket Médio** - Valor médio por venda
4. **Produtos Vendidos** - Total de unidades vendidas

### Abas de Gráficos (Simplificadas):
1. **Vendas** - Vendas por dia (linha)
2. **Produtos** - Produtos mais vendidos (barra)
3. **Categorias** - Vendas por categoria (pizza + barra)
4. **Pagamento** - Faturamento por forma de pagamento (barra + pizza)
5. **Faturamento** - Análise de faturamento (opcional)

### Abas a REMOVER:
- ❌ Entrega (não faz sentido)
- ❌ Cancelados (vendas não são canceladas)
- ❌ Entregas (não faz sentido)

---

## ✅ PRÓXIMOS PASSOS (APÓS APROVAÇÃO)

### ETAPA 2 - Substituir Fontes de Dados:
1. Criar queries para tabela `sales`
2. Calcular métricas básicas:
   - Faturamento total
   - Quantidade de vendas
   - Ticket médio
   - Faturamento por forma de pagamento
3. Calcular vendas por dia
4. Extrair produtos mais vendidos de `sales.items`
5. Testar com dados reais

### ETAPA 3 - Ajustar Legendas:
1. Trocar "Vendas Balcão" → "Faturamento"
2. Trocar "Pedidos Balcão" → "Vendas Realizadas"
3. Remover referências a "Mesa", "Comandas", "Delivery"
4. Ajustar títulos de gráficos

### ETAPA 4 - Remover Métricas Obsoletas:
1. Remover cards de "Vendas Mesa"
2. Remover abas "Entrega", "Cancelados", "Entregas"
3. Remover gráficos de status de pedidos
4. Remover gráficos de tipos de entrega

### ETAPA 5 - Filtros:
1. Manter filtros de período (data início/fim)
2. Adicionar filtro por forma de pagamento (opcional)
3. Adicionar filtro por tipo de venda (se existir)

### ETAPA 6 - Validação:
1. Comparar números com histórico de vendas
2. Verificar consistência de datas
3. Testar filtros

---

## 🎨 LAYOUT ATUAL (REFERÊNCIA)

### Estrutura de Cards:
```
┌─────────────────────────────────────────────────────────┐
│ 🛒 Vendas Balcão                                        │
├──────────────┬──────────────┬──────────────┬───────────┤
│ Vendas Balcão│ Pedidos      │ Ticket Médio │ Produtos  │
│ R$ X.XXX,XX  │ XXX          │ R$ XX,XX     │ XXX       │
└──────────────┴──────────────┴──────────────┴───────────┘

┌─────────────────────────────────────────────────────────┐
│ 🍽️ Vendas Mesa                                          │
├──────────────┬──────────────┬──────────────┬───────────┤
│ Vendas Mesa  │ Atendimentos │ Ticket Médio │ Total     │
│ R$ X.XXX,XX  │ XXX          │ R$ XX,XX     │ R$ X.XXX  │
└──────────────┴──────────────┴──────────────┴───────────┘
```

### Abas:
```
┌─────────────────────────────────────────────────────────┐
│ [Vendas] [Produtos] [Categorias] [Pagamento] [Entrega] │
│ [Faturamento] [Cancelados] [Entregas]                   │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 OBSERVAÇÕES IMPORTANTES

1. **Pagamento Dividido:**
   - Sistema antigo suporta pagamento dividido (2 formas)
   - Verificar se `sales` também suporta
   - Se não, simplificar para 1 forma apenas

2. **Itens da Venda:**
   - `sales.items` é JSONB
   - Verificar estrutura exata dos itens
   - Pode precisar ajustar extração de produtos/categorias

3. **Tipo de Venda:**
   - `sales.sale_type` pode ter valores como "PDV", "DELIVERY"
   - Decidir se mantém filtro por tipo ou remove

4. **Relatório PDF:**
   - Simplificar relatório para remover seções obsoletas
   - Manter apenas: Faturamento, Vendas, Produtos, Pagamento

---

## ✅ CHECKLIST DE APROVAÇÃO

Antes de avançar para ETAPA 2, confirmar:

- [ ] Entendi que o sistema mudou de delivery/comandas para loja física
- [ ] Concordo em remover métricas de entrega/cancelamento/comandas
- [ ] Concordo em simplificar o módulo para focar em vendas PDV
- [ ] Entendi que o layout será mantido, apenas dados/legendas mudam
- [ ] Estou ciente dos riscos e impactos
- [ ] Autorizo avançar para ETAPA 2 (substituir fontes de dados)

---

**Data do Diagnóstico:** 27/02/2026  
**Responsável:** Kiro AI  
**Status:** ⏸️ AGUARDANDO APROVAÇÃO PARA ETAPA 2

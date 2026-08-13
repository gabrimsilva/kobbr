# 📝 Changelog - Banco de Dados

## [1.1.0] - 22/01/2026

### ✨ Novas Funcionalidades

#### 🎁 Sistema de Descontos
Adicionado suporte completo para descontos manuais em pedidos, comandas e PDV.

**Tabelas Afetadas:**
- `pedidos`
- `historico_pedidos`
- `historico_geral`
- `comandas`
- `historico_comandas`

**Novos Campos:**
- `desconto` (NUMERIC) - Valor do desconto aplicado
- `tipo_desconto` (TEXT) - Tipo: 'valor' (R$) ou 'percentual' (%)

**Constraints:**
- `desconto >= 0` - Desconto não pode ser negativo
- `tipo_desconto IN ('valor', 'percentual')` - Apenas tipos válidos

**Exemplo de Uso:**
```sql
-- Desconto de R$ 10,00
UPDATE pedidos 
SET desconto = 10, tipo_desconto = 'valor'
WHERE pedido_id = 'abc123';

-- Desconto de 15%
UPDATE pedidos 
SET desconto = 15, tipo_desconto = 'percentual'
WHERE pedido_id = 'abc123';
```

#### 💳 Pagamento Dividido
Adicionado suporte para dividir pagamento entre duas formas diferentes.

**Tabelas Afetadas:**
- `pedidos`
- `historico_pedidos`
- `historico_geral`
- `comandas`
- `historico_comandas`

**Novos Campos:**
- `forma_pagamento_dividido` (BOOLEAN) - Indica se pagamento foi dividido
- `pagamento_1_tipo` (TEXT) - Tipo da 1ª forma (PIX, Dinheiro, Débito, Crédito)
- `pagamento_1_valor` (NUMERIC) - Valor pago com 1ª forma
- `pagamento_2_tipo` (TEXT) - Tipo da 2ª forma
- `pagamento_2_valor` (NUMERIC) - Valor pago com 2ª forma

**Constraints:**
- Tipos de pagamento devem ser diferentes
- Valores devem ser positivos quando dividido
- Ambos os tipos e valores devem estar preenchidos quando dividido

**Exemplo de Uso:**
```sql
-- Pagamento dividido: R$ 50 em PIX + R$ 30 em Dinheiro
UPDATE pedidos 
SET 
  forma_pagamento_dividido = true,
  pagamento_1_tipo = 'PIX',
  pagamento_1_valor = 50.00,
  pagamento_2_tipo = 'Dinheiro',
  pagamento_2_valor = 30.00
WHERE pedido_id = 'abc123';
```

### 🔧 Melhorias

#### Documentação
- ✅ Adicionados comentários em todas as novas colunas
- ✅ Atualizado ESTRUTURA_BANCO.md com novos campos
- ✅ Adicionadas queries úteis para descontos e pagamento dividido

#### Integridade de Dados
- ✅ Constraints para garantir valores válidos
- ✅ Defaults apropriados (desconto = 0, tipo_desconto = 'valor')
- ✅ Validações de negócio via CHECK constraints

### 📊 Impacto

**Compatibilidade:**
- ✅ Totalmente retrocompatível
- ✅ Campos com valores default
- ✅ Não quebra código existente

**Performance:**
- ✅ Índices existentes continuam funcionando
- ✅ Novos campos não impactam queries antigas
- ✅ Constraints otimizadas

**Migração:**
- ✅ Scripts idempotentes (podem ser executados múltiplas vezes)
- ✅ Não requer downtime
- ✅ Dados existentes preservados

### 🗑️ Removido

#### Migrations Antigas
Removidos arquivos de migration já incorporados ao BD_20_01:
- ❌ `20260121000000_add_desconto_fields_to_pedidos.sql`
- ❌ `20260122000000_add_split_payment_fields.sql`
- ❌ `20260122000001_add_split_payment_to_historico_geral.sql`

#### Scripts Temporários
- ❌ `atualizar_descontos_historico_existente.sql`
- ❌ `corrigir_desconto_historico.sql`
- ❌ `09_configuracoes_faltantes.sql` (incorporado ao `07_storage_and_config.sql`)

**Motivo:** Todas as mudanças foram consolidadas nos arquivos principais do BD_20_01.

---

## [1.0.0] - 20/01/2026

### 🎉 Versão Inicial

Estrutura completa do banco de dados com:
- 22 tabelas
- ~40 índices
- 10 views
- 7 funções
- Políticas RLS completas
- 3 storage buckets

---

## 📋 Resumo de Versões

| Versão | Data | Mudanças Principais |
|--------|------|---------------------|
| 1.1.0 | 22/01/2026 | Descontos + Pagamento Dividido |
| 1.0.0 | 20/01/2026 | Estrutura inicial completa |

---

**Última Atualização:** 22/01/2026  
**Versão Atual:** 1.1.0

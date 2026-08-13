# ✅ ETAPA 6 — VALIDAÇÃO E CONSISTÊNCIA

## 📋 STATUS: GUIA DE VALIDAÇÃO COMPLETO

---

## 🎯 OBJETIVO

Garantir que os números das métricas batem com o histórico de vendas e que não há inconsistências nos dados.

---

## 🧪 TESTES DE VALIDAÇÃO

### 1. VALIDAÇÃO DE FATURAMENTO TOTAL

#### Teste Manual:

**Passo 1:** Abrir página de Métricas
- Selecionar período: "Hoje"
- Anotar valor do "Faturamento Total"

**Passo 2:** Abrir página de Histórico de Vendas
- Filtrar por data: Hoje
- Somar manualmente os valores da coluna "Valor"
- Ou usar console do navegador:

```javascript
// No console do navegador (F12)
const valores = Array.from(document.querySelectorAll('[data-valor]'))
  .map(el => parseFloat(el.textContent.replace('R$', '').replace('.', '').replace(',', '.')))
const total = valores.reduce((sum, val) => sum + val, 0)
console.log('Total:', total.toLocaleString('pt-BR', {style: 'currency', currency: 'BRL'}))
```

**Resultado Esperado:**
- ✅ Valores devem ser EXATAMENTE iguais
- ❌ Se diferente, há inconsistência

---

### 2. VALIDAÇÃO DE QUANTIDADE DE VENDAS

#### Teste Manual:

**Passo 1:** Métricas
- Período: "Últimos 7 dias"
- Anotar "Quantidade de Vendas"

**Passo 2:** Histórico de Vendas
- Filtrar últimos 7 dias
- Contar linhas da tabela

**Resultado Esperado:**
- ✅ Números devem ser iguais

---

### 3. VALIDAÇÃO DE TICKET MÉDIO

#### Teste Manual:

**Passo 1:** Métricas
- Anotar: Faturamento Total e Quantidade de Vendas
- Calcular: Faturamento / Quantidade

**Passo 2:** Comparar com Ticket Médio mostrado

**Resultado Esperado:**
- ✅ Cálculo manual = Ticket Médio mostrado
- Tolerância: ±R$ 0,01 (arredondamento)

---

### 4. VALIDAÇÃO DE FORMAS DE PAGAMENTO

#### Teste SQL Direto:

```sql
-- No Supabase SQL Editor
SELECT 
  payment_method,
  COUNT(*) as quantidade,
  SUM(total_amount) as total
FROM sales
WHERE created_at >= '2026-02-20T00:00:00Z'
  AND created_at <= '2026-02-27T23:59:59Z'
GROUP BY payment_method
ORDER BY total DESC;
```

**Comparar com:**
- Gráfico "Vendas por Forma de Pagamento" nas Métricas

**Resultado Esperado:**
- ✅ Valores devem bater exatamente

---

### 5. VALIDAÇÃO DE PRODUTOS MAIS VENDIDOS

#### Teste SQL Direto:

```sql
-- Extrair produtos de todas as vendas
SELECT 
  item->>'produto'->>'nome' as produto,
  SUM((item->>'quantidade')::int) as quantidade,
  SUM((item->>'precoTotal')::numeric) as total
FROM sales,
  jsonb_array_elements(items) as item
WHERE created_at >= '2026-02-20T00:00:00Z'
  AND created_at <= '2026-02-27T23:59:59Z'
GROUP BY item->>'produto'->>'nome'
ORDER BY quantidade DESC
LIMIT 10;
```

**Comparar com:**
- Gráfico "Produtos Mais Vendidos" nas Métricas

**Resultado Esperado:**
- ✅ Top 10 produtos devem ser os mesmos
- ✅ Quantidades devem bater

---

### 6. VALIDAÇÃO DE DATAS

#### Teste de Timezone:

**Problema Comum:**
- Datas podem estar em UTC no banco
- Interface pode estar em horário local

**Verificação:**

```sql
-- Verificar timezone das vendas
SELECT 
  id,
  sale_number,
  created_at,
  created_at AT TIME ZONE 'America/Sao_Paulo' as created_at_local
FROM sales
ORDER BY created_at DESC
LIMIT 5;
```

**Teste Manual:**
- Criar venda agora no PDV
- Verificar se aparece em "Hoje" nas métricas
- Verificar se hora está correta

**Resultado Esperado:**
- ✅ Venda aparece imediatamente
- ✅ Hora está correta (horário local)

---

### 7. VALIDAÇÃO DE FILTROS

#### Teste: Filtro por Forma de Pagamento

**Passo 1:** Métricas
- Período: "Últimos 30 dias"
- Forma de Pagamento: "PIX"
- Anotar faturamento

**Passo 2:** SQL Direto

```sql
SELECT 
  COUNT(*) as quantidade,
  SUM(total_amount) as total
FROM sales
WHERE created_at >= NOW() - INTERVAL '30 days'
  AND payment_method = 'PIX';
```

**Resultado Esperado:**
- ✅ Valores devem bater

#### Teste: Filtro por Tipo de Venda

**Passo 1:** Métricas
- Período: "Últimos 7 dias"
- Tipo de Venda: "PDV"
- Anotar quantidade

**Passo 2:** SQL Direto

```sql
SELECT COUNT(*) 
FROM sales
WHERE created_at >= NOW() - INTERVAL '7 days'
  AND sale_type = 'PDV';
```

**Resultado Esperado:**
- ✅ Valores devem bater

---

### 8. VALIDAÇÃO DE CATEGORIAS

#### Teste SQL:

```sql
-- Vendas por categoria
SELECT 
  item->'produto'->>'categoria' as categoria,
  SUM((item->>'quantidade')::int) as quantidade,
  SUM((item->>'precoTotal')::numeric) as total
FROM sales,
  jsonb_array_elements(items) as item
WHERE created_at >= '2026-02-20T00:00:00Z'
  AND created_at <= '2026-02-27T23:59:59Z'
GROUP BY item->'produto'->>'categoria'
ORDER BY total DESC;
```

**Comparar com:**
- Gráfico "Faturamento por Categoria"

**Resultado Esperado:**
- ✅ Categorias e valores devem bater

---

## 🔍 VERIFICAÇÕES AUTOMÁTICAS

### Script de Validação (JavaScript)

Adicionar no console do navegador na página de Métricas:

```javascript
// Validação automática de consistência
async function validarMetricas() {
  console.log('🔍 Iniciando validação de métricas...\n')
  
  // 1. Buscar dados do Supabase
  const { data: vendas, error } = await supabase
    .from('sales')
    .select('*')
    .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
  
  if (error) {
    console.error('❌ Erro ao buscar vendas:', error)
    return
  }
  
  // 2. Calcular métricas manualmente
  const faturamento = vendas.reduce((sum, v) => sum + parseFloat(v.total_amount), 0)
  const quantidade = vendas.length
  const ticketMedio = quantidade > 0 ? faturamento / quantidade : 0
  
  console.log('📊 Métricas Calculadas:')
  console.log(`Faturamento: R$ ${faturamento.toFixed(2)}`)
  console.log(`Quantidade: ${quantidade}`)
  console.log(`Ticket Médio: R$ ${ticketMedio.toFixed(2)}`)
  
  // 3. Comparar com valores na tela
  const faturamentoTela = parseFloat(
    document.querySelector('[data-metrica="faturamento"]')?.textContent
      .replace('R$', '').replace('.', '').replace(',', '.') || '0'
  )
  
  const quantidadeTela = parseInt(
    document.querySelector('[data-metrica="quantidade"]')?.textContent || '0'
  )
  
  console.log('\n📺 Valores na Tela:')
  console.log(`Faturamento: R$ ${faturamentoTela.toFixed(2)}`)
  console.log(`Quantidade: ${quantidadeTela}`)
  
  // 4. Validar
  const faturamentoOk = Math.abs(faturamento - faturamentoTela) < 0.01
  const quantidadeOk = quantidade === quantidadeTela
  
  console.log('\n✅ Validação:')
  console.log(`Faturamento: ${faturamentoOk ? '✅ OK' : '❌ ERRO'}`)
  console.log(`Quantidade: ${quantidadeOk ? '✅ OK' : '❌ ERRO'}`)
  
  if (faturamentoOk && quantidadeOk) {
    console.log('\n🎉 Todas as validações passaram!')
  } else {
    console.log('\n⚠️ Há inconsistências nos dados!')
  }
}

// Executar validação
validarMetricas()
```

---

## 🐛 PROBLEMAS COMUNS E SOLUÇÕES

### Problema 1: Faturamento não bate

**Possíveis Causas:**
1. Filtros de período não estão sendo aplicados corretamente
2. Timezone incorreto (UTC vs Local)
3. Vendas duplicadas no banco

**Solução:**
```typescript
// Verificar se startOfDay e endOfDay estão corretos
const inicio = startOfDay(dataInicio).toISOString()
const fim = endOfDay(dataFim).toISOString()

console.log('Período:', inicio, 'até', fim)
```

---

### Problema 2: Produtos não aparecem

**Possíveis Causas:**
1. Estrutura de `items` diferente do esperado
2. Produtos sem nome
3. JSON malformado

**Solução:**
```typescript
// Adicionar logs para debug
vendasData.forEach(venda => {
  console.log('Venda:', venda.sale_number)
  console.log('Items:', venda.items)
  
  const itens = Array.isArray(venda.items) ? venda.items : []
  itens.forEach((item: any) => {
    console.log('  - Produto:', item.produto?.nome || 'SEM NOME')
    console.log('  - Quantidade:', item.quantidade)
  })
})
```

---

### Problema 3: Categorias "Sem categoria"

**Possíveis Causas:**
1. Produtos não têm categoria definida
2. Campo categoria vazio ou null

**Solução:**
```sql
-- Verificar produtos sem categoria
SELECT 
  item->'produto'->>'nome' as produto,
  item->'produto'->>'categoria' as categoria
FROM sales,
  jsonb_array_elements(items) as item
WHERE item->'produto'->>'categoria' IS NULL
   OR item->'produto'->>'categoria' = ''
LIMIT 10;
```

**Correção:**
- Adicionar categoria aos produtos no cadastro
- Ou aceitar "Sem categoria" como válido

---

### Problema 4: Datas erradas

**Possíveis Causas:**
1. Timezone do servidor diferente do cliente
2. `startOfDay`/`endOfDay` não aplicados

**Solução:**
```typescript
// Garantir que datas incluem dia completo
import { startOfDay, endOfDay } from "date-fns"

const inicio = startOfDay(dataInicio) // 00:00:00
const fim = endOfDay(dataFim)         // 23:59:59
```

---

### Problema 5: Filtros não funcionam

**Possíveis Causas:**
1. Query não está sendo reconstruída
2. Valores de filtro incorretos
3. useEffect não detecta mudanças

**Solução:**
```typescript
// Verificar se useEffect tem todas as dependências
useEffect(() => {
  console.log('Recarregando com filtros:', {
    dataInicio,
    dataFim,
    filtroFormaPagamento,
    filtroTipoVenda
  })
  carregarMetricas()
}, [dataInicio, dataFim, filtroFormaPagamento, filtroTipoVenda])
```

---

## 📊 CHECKLIST DE VALIDAÇÃO COMPLETO

### Validações Básicas:
- [ ] Faturamento total bate com histórico de vendas
- [ ] Quantidade de vendas bate com histórico
- [ ] Ticket médio está correto (faturamento / quantidade)
- [ ] Produtos vendidos (unidades) está correto

### Validações de Gráficos:
- [ ] Faturamento diário bate com soma por dia
- [ ] Produtos mais vendidos estão corretos
- [ ] Faturamento por produto está correto
- [ ] Faturamento por categoria está correto
- [ ] Volume por categoria está correto
- [ ] Formas de pagamento batem com banco

### Validações de Filtros:
- [ ] Filtro de período funciona corretamente
- [ ] Filtro por forma de pagamento funciona
- [ ] Filtro por tipo de venda funciona
- [ ] Combinação de filtros funciona
- [ ] Limpar filtros restaura valores corretos

### Validações de Datas:
- [ ] Venda criada agora aparece em "Hoje"
- [ ] Hora da venda está correta (timezone)
- [ ] Período "Últimos 7 dias" inclui hoje
- [ ] Data início/fim incluem dia completo

### Validações de Performance:
- [ ] Carregamento < 1 segundo (até 100 vendas)
- [ ] Carregamento < 3 segundos (até 1000 vendas)
- [ ] Filtros aplicam rapidamente
- [ ] Gráficos renderizam sem lag

### Validações de UX:
- [ ] Loading state aparece durante carregamento
- [ ] Mensagem de erro se falhar
- [ ] Badge "Filtros ativos" aparece corretamente
- [ ] Botão "Limpar filtros" funciona
- [ ] Responsivo em mobile
- [ ] Responsivo em tablet
- [ ] Responsivo em desktop

### Validações de PDF:
- [ ] PDF é gerado corretamente
- [ ] Valores no PDF batem com interface
- [ ] Todas as seções aparecem
- [ ] Formatação está correta

---

## 🔧 FERRAMENTAS DE DEBUG

### 1. Console Logs Estratégicos

Adicionar temporariamente no código:

```typescript
const carregarMetricas = async () => {
  try {
    setLoading(true)
    
    console.log('🔍 Carregando métricas...')
    console.log('Período:', dataInicio, 'até', dataFim)
    console.log('Filtros:', { filtroFormaPagamento, filtroTipoVenda })
    
    const inicio = startOfDay(dataInicio).toISOString()
    const fim = endOfDay(dataFim).toISOString()
    
    console.log('Query período:', inicio, 'até', fim)
    
    // ... resto do código
    
    console.log('✅ Vendas carregadas:', vendasData.length)
    console.log('💰 Faturamento:', faturamentoTotal)
    console.log('📊 Quantidade:', quantidadeVendas)
    
  } catch (error) {
    console.error('❌ Erro:', error)
  }
}
```

---

### 2. React DevTools

**Verificar Estados:**
1. Abrir React DevTools (F12 → Components)
2. Selecionar componente `Metricas`
3. Ver valores de:
   - `metricas`
   - `dataInicio`
   - `dataFim`
   - `filtroFormaPagamento`
   - `filtroTipoVenda`

---

### 3. Network Tab

**Verificar Queries:**
1. Abrir DevTools (F12 → Network)
2. Filtrar por "supabase"
3. Ver requests para tabela `sales`
4. Verificar parâmetros da query

---

## 📈 MÉTRICAS DE QUALIDADE

### Critérios de Aceitação:

| Métrica | Critério | Status |
|---------|----------|--------|
| **Precisão** | 100% dos valores batem | ⏳ Testar |
| **Performance** | < 1s para 100 vendas | ⏳ Testar |
| **Responsividade** | Funciona em mobile | ⏳ Testar |
| **Filtros** | Todos funcionam | ⏳ Testar |
| **PDF** | Gera corretamente | ⏳ Testar |

---

## 🎯 PLANO DE TESTES

### Fase 1: Testes Unitários (Manual)
**Duração:** 30 minutos

1. ✅ Criar 5 vendas de teste
2. ✅ Verificar se aparecem nas métricas
3. ✅ Verificar valores calculados
4. ✅ Testar cada filtro individualmente

### Fase 2: Testes de Integração
**Duração:** 1 hora

1. ✅ Testar com dados reais (se disponível)
2. ✅ Comparar com histórico de vendas
3. ✅ Validar todos os gráficos
4. ✅ Testar combinações de filtros

### Fase 3: Testes de Performance
**Duração:** 30 minutos

1. ✅ Testar com 100 vendas
2. ✅ Testar com 1000 vendas (se possível)
3. ✅ Medir tempo de carregamento
4. ✅ Verificar uso de memória

### Fase 4: Testes de UX
**Duração:** 30 minutos

1. ✅ Testar em mobile (Chrome DevTools)
2. ✅ Testar em tablet
3. ✅ Testar em desktop
4. ✅ Verificar acessibilidade básica

---

## ✅ APROVAÇÃO FINAL

### Checklist de Aprovação:

- [ ] Todos os testes de validação passaram
- [ ] Não há inconsistências nos dados
- [ ] Performance está adequada
- [ ] Interface é responsiva
- [ ] Filtros funcionam corretamente
- [ ] PDF é gerado corretamente
- [ ] Não há erros no console
- [ ] Código está limpo e documentado

### Assinaturas:

- [ ] **Desenvolvedor:** Código implementado e testado
- [ ] **QA:** Testes de validação executados
- [ ] **Product Owner:** Funcionalidades aprovadas
- [ ] **Usuário Final:** Interface aprovada

---

## 🎉 CONCLUSÃO

Após completar todas as validações desta etapa:

1. ✅ Módulo de métricas está funcionando corretamente
2. ✅ Dados são precisos e consistentes
3. ✅ Performance é adequada
4. ✅ Interface é intuitiva e responsiva
5. ✅ Filtros permitem análises detalhadas

**O módulo está pronto para produção!** 🚀

---

**Data da Validação:** 27/02/2026  
**Responsável:** Kiro AI  
**Status:** ✅ GUIA DE VALIDAÇÃO COMPLETO

# 🧪 ETAPA 0.3 — TESTES DA CORREÇÃO DE BAIXA DE ESTOQUE

## 🎯 STATUS: AGUARDANDO EXECUÇÃO DOS TESTES

---

## 📋 OBJETIVO

Validar que a correção implementada na ETAPA 0.2 está funcionando corretamente:
- ✅ Venda dá baixa no estoque
- ✅ Movimentação é registrada
- ✅ Venda é bloqueada quando estoque insuficiente
- ✅ Mensagens de erro são claras

---

## 🔧 PRÉ-REQUISITOS

### 1. Servidor Rodando
```bash
npm run dev
```
- Servidor deve estar em: http://localhost:5173

### 2. Produtos com Estoque Configurado

Execute no Supabase SQL Editor:

```sql
-- Verificar produtos com estoque
SELECT 
  p.id,
  p.nome,
  p.preco,
  si.total_qty as estoque_atual,
  si.min_qty as estoque_minimo
FROM produtos p
LEFT JOIN stock_items si ON si.product_id = p.id
WHERE p.ativo = true
ORDER BY p.nome;
```

**Se não houver produtos com estoque:**

```sql
-- Criar estoque para produtos existentes
INSERT INTO stock_items (product_id, total_qty, min_qty)
SELECT 
  id,
  10,  -- Quantidade inicial
  2    -- Estoque mínimo
FROM produtos
WHERE ativo = true
  AND id NOT IN (SELECT product_id FROM stock_items)
ON CONFLICT (product_id) DO NOTHING;
```

---

## 🧪 BATERIA DE TESTES

### ✅ TESTE 1: Venda Normal (Estoque Suficiente)

**Objetivo:** Verificar que venda baixa estoque corretamente

**Passos:**

1. **Preparar Produto:**
```sql
-- Escolher um produto e garantir estoque
UPDATE stock_items si
SET total_qty = 10
FROM produtos p
WHERE si.product_id = p.id
  AND p.nome LIKE '%Batom%'  -- Ajuste o nome
RETURNING 
  p.nome,
  si.total_qty as estoque_antes;
```

2. **Anotar Valores:**
- Nome do produto: _______________
- Estoque antes: _______________
- Quantidade a vender: 2 unidades

3. **Realizar Venda no PDV:**
- Acessar: http://localhost:5173/pdv
- Adicionar produto ao carrinho (2 unidades)
- Finalizar venda
- Escolher forma de pagamento
- Confirmar

4. **Verificar Resultado:**

```sql
-- Verificar estoque após venda
SELECT 
  p.nome,
  si.total_qty as estoque_depois
FROM produtos p
JOIN stock_items si ON si.product_id = p.id
WHERE p.nome LIKE '%Batom%';  -- Ajuste o nome

-- Verificar movimentação registrada
SELECT 
  sm.id,
  sm.type,
  sm.qty,
  sm.ref_type,
  sm.ref_id,
  sm.created_at,
  p.nome as produto
FROM stock_movements sm
JOIN stock_items si ON si.id = sm.stock_item_id
JOIN produtos p ON p.id = si.product_id
WHERE sm.ref_type = 'SALE'
ORDER BY sm.created_at DESC
LIMIT 1;

-- Verificar venda salva
SELECT 
  s.id,
  s.sale_number,
  s.total_amount,
  s.payment_method,
  s.created_at
FROM sales s
ORDER BY s.created_at DESC
LIMIT 1;
```

**Resultado Esperado:**
- ✅ Venda finalizada com sucesso
- ✅ Estoque diminuiu de 10 para 8
- ✅ Movimentação registrada:
  - `type = 'OUT'`
  - `qty = -2`
  - `ref_type = 'SALE'`
  - `ref_id = [sale_id]`
- ✅ Venda salva na tabela `sales`

**Status:** [ ] PASSOU [ ] FALHOU

---

### ❌ TESTE 2: Estoque Insuficiente

**Objetivo:** Verificar que venda é bloqueada quando estoque insuficiente

**Passos:**

1. **Preparar Produto:**
```sql
-- Reduzir estoque para 1 unidade
UPDATE stock_items si
SET total_qty = 1
FROM produtos p
WHERE si.product_id = p.id
  AND p.nome LIKE '%Perfume%'  -- Ajuste o nome
RETURNING 
  p.nome,
  si.total_qty as estoque_antes;
```

2. **Anotar Valores:**
- Nome do produto: _______________
- Estoque antes: 1 unidade
- Quantidade a vender: 3 unidades

3. **Tentar Venda no PDV:**
- Acessar: http://localhost:5173/pdv
- Adicionar produto ao carrinho (3 unidades)
- Finalizar venda
- Escolher forma de pagamento
- Confirmar

4. **Verificar Resultado:**

```sql
-- Verificar que estoque NÃO mudou
SELECT 
  p.nome,
  si.total_qty as estoque_depois
FROM produtos p
JOIN stock_items si ON si.product_id = p.id
WHERE p.nome LIKE '%Perfume%';  -- Ajuste o nome

-- Verificar que NÃO há movimentação nova
SELECT COUNT(*) as movimentacoes_recentes
FROM stock_movements
WHERE created_at > NOW() - INTERVAL '1 minute';
```

**Resultado Esperado:**
- ❌ Venda NÃO finalizada
- ✅ Mensagem de erro exibida: "Estoque insuficiente para [Produto]. Disponível: 1, Solicitado: 3"
- ✅ Estoque permanece em 1 unidade
- ✅ Nenhuma movimentação registrada
- ✅ Nenhuma venda salva

**Status:** [ ] PASSOU [ ] FALHOU

---

### ⚠️ TESTE 3: Produto Sem Controle de Estoque

**Objetivo:** Verificar comportamento quando produto não tem stock_item

**Passos:**

1. **Preparar Produto:**
```sql
-- Criar produto sem estoque (ou remover estoque temporariamente)
INSERT INTO produtos (nome, preco, categoria, ativo)
VALUES ('Serviço de Maquiagem', 50.00, 'Serviços', true)
ON CONFLICT DO NOTHING
RETURNING id, nome;

-- Garantir que NÃO tem stock_item
DELETE FROM stock_items
WHERE product_id IN (
  SELECT id FROM produtos WHERE nome = 'Serviço de Maquiagem'
);
```

2. **Tentar Venda no PDV:**
- Acessar: http://localhost:5173/pdv
- Adicionar "Serviço de Maquiagem" ao carrinho
- Finalizar venda
- Escolher forma de pagamento
- Confirmar

3. **Verificar Resultado:**

```sql
-- Verificar que produto não tem estoque
SELECT 
  p.nome,
  si.id as stock_item_id
FROM produtos p
LEFT JOIN stock_items si ON si.product_id = p.id
WHERE p.nome = 'Serviço de Maquiagem';
```

**Resultado Esperado:**
- ❌ Venda NÃO finalizada
- ✅ Mensagem de erro: "Produto 'Serviço de Maquiagem' não possui controle de estoque configurado"
- ✅ Nenhuma venda salva

**Status:** [ ] PASSOU [ ] FALHOU

---

### 🔄 TESTE 4: Múltiplos Produtos (Todos com Estoque)

**Objetivo:** Verificar baixa em múltiplos produtos

**Passos:**

1. **Preparar Produtos:**
```sql
-- Garantir estoque em 2 produtos
UPDATE stock_items si
SET total_qty = 10
FROM produtos p
WHERE si.product_id = p.id
  AND p.nome IN ('Batom Rosa', 'Perfume Lavanda')  -- Ajuste os nomes
RETURNING p.nome, si.total_qty;
```

2. **Realizar Venda no PDV:**
- Adicionar Batom Rosa (2 unidades)
- Adicionar Perfume Lavanda (1 unidade)
- Finalizar venda

3. **Verificar Resultado:**

```sql
-- Verificar estoque de ambos
SELECT 
  p.nome,
  si.total_qty as estoque_depois
FROM produtos p
JOIN stock_items si ON si.product_id = p.id
WHERE p.nome IN ('Batom Rosa', 'Perfume Lavanda')
ORDER BY p.nome;

-- Verificar movimentações (deve ter 2)
SELECT 
  p.nome,
  sm.type,
  sm.qty,
  sm.ref_type,
  sm.ref_id
FROM stock_movements sm
JOIN stock_items si ON si.id = sm.stock_item_id
JOIN produtos p ON p.id = si.product_id
WHERE sm.created_at > NOW() - INTERVAL '1 minute'
ORDER BY sm.created_at DESC;
```

**Resultado Esperado:**
- ✅ Venda finalizada
- ✅ Batom: estoque diminuiu de 10 para 8
- ✅ Perfume: estoque diminuiu de 10 para 9
- ✅ 2 movimentações registradas (uma para cada produto)
- ✅ Ambas com mesmo `ref_id` (sale_id)

**Status:** [ ] PASSOU [ ] FALHOU

---

### ⚠️ TESTE 5: Múltiplos Produtos (Um Sem Estoque)

**Objetivo:** Verificar que venda é bloqueada se UM produto não tem estoque

**Passos:**

1. **Preparar Produtos:**
```sql
-- Produto 1: Com estoque
UPDATE stock_items si
SET total_qty = 10
FROM produtos p
WHERE si.product_id = p.id
  AND p.nome LIKE '%Batom%'
RETURNING p.nome, si.total_qty;

-- Produto 2: SEM estoque
UPDATE stock_items si
SET total_qty = 0
FROM produtos p
WHERE si.product_id = p.id
  AND p.nome LIKE '%Perfume%'
RETURNING p.nome, si.total_qty;
```

2. **Tentar Venda no PDV:**
- Adicionar Batom (1 unidade) - TEM estoque
- Adicionar Perfume (1 unidade) - NÃO TEM estoque
- Finalizar venda

3. **Verificar Resultado:**

```sql
-- Verificar que NENHUM estoque mudou
SELECT 
  p.nome,
  si.total_qty as estoque_depois
FROM produtos p
JOIN stock_items si ON si.product_id = p.id
WHERE p.nome IN (
  SELECT nome FROM produtos WHERE nome LIKE '%Batom%' OR nome LIKE '%Perfume%'
)
ORDER BY p.nome;

-- Verificar que NÃO há movimentações novas
SELECT COUNT(*) as movimentacoes_recentes
FROM stock_movements
WHERE created_at > NOW() - INTERVAL '1 minute';
```

**Resultado Esperado:**
- ❌ Venda NÃO finalizada
- ✅ Mensagem de erro: "Estoque insuficiente para [Perfume]. Disponível: 0, Solicitado: 1"
- ✅ Batom: estoque permanece em 10 (não foi alterado)
- ✅ Perfume: estoque permanece em 0
- ✅ Nenhuma movimentação registrada
- ✅ Nenhuma venda salva

**Status:** [ ] PASSOU [ ] FALHOU

---

## 📊 RESUMO DOS TESTES

| Teste | Descrição | Status | Observações |
|-------|-----------|--------|-------------|
| 1 | Venda normal | [ ] | Estoque suficiente |
| 2 | Estoque insuficiente | [ ] | Deve bloquear |
| 3 | Sem stock_item | [ ] | Deve bloquear |
| 4 | Múltiplos produtos OK | [ ] | Todos com estoque |
| 5 | Múltiplos produtos (1 sem) | [ ] | Deve bloquear tudo |

---

## 🐛 PROBLEMAS ENCONTRADOS

### Problema 1:
**Descrição:** _______________________________________________
**Teste:** _______________________________________________
**Comportamento Esperado:** _______________________________________________
**Comportamento Observado:** _______________________________________________

### Problema 2:
**Descrição:** _______________________________________________
**Teste:** _______________________________________________
**Comportamento Esperado:** _______________________________________________
**Comportamento Observado:** _______________________________________________

---

## ✅ CRITÉRIOS DE ACEITAÇÃO

Para considerar a ETAPA 0.3 concluída, TODOS os testes devem passar:

- [ ] TESTE 1: Venda normal baixa estoque corretamente
- [ ] TESTE 2: Venda bloqueada quando estoque insuficiente
- [ ] TESTE 3: Venda bloqueada quando produto sem stock_item
- [ ] TESTE 4: Múltiplos produtos baixam estoque corretamente
- [ ] TESTE 5: Venda bloqueada se UM produto sem estoque
- [ ] Movimentações registradas com `ref_type = 'SALE'`
- [ ] Movimentações têm `ref_id` correto (sale_id)
- [ ] Mensagens de erro são claras e úteis
- [ ] Nenhum erro no console do navegador
- [ ] Nenhum erro no console do servidor

---

## 🚀 APÓS APROVAÇÃO DOS TESTES

Quando TODOS os testes passarem:

1. ✅ Marcar ETAPA 0 como CONCLUÍDA
2. ✅ Documentar resultados
3. ✅ Avançar para ETAPA 1: Estoque Mínimo e Classificação Visual

---

## 📝 NOTAS IMPORTANTES

### Console do Navegador
- Abrir DevTools (F12)
- Verificar aba Console
- Não deve haver erros durante venda

### Console do Servidor
- Verificar terminal onde `npm run dev` está rodando
- Não deve haver erros durante venda

### Supabase
- Verificar logs no Supabase Dashboard
- Verificar se queries estão sendo executadas

---

**Data de Criação:** 27/02/2026  
**Responsável:** Kiro AI  
**Status:** 🧪 AGUARDANDO EXECUÇÃO DOS TESTES


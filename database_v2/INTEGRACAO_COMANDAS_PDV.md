# Integração Comandas ↔ Pedidos ↔ PDV

## ✅ IMPLEMENTADO

### 1. Campo `comanda_id` em `pedidos`
**Arquivo**: `pedidos.sql`

```sql
comanda_id UUID REFERENCES comandas(id) ON DELETE SET NULL
```

**Vinculação Bidirecional**:
- `pedidos.comanda_id` → `comandas.id`
- `comandas.pedido_id` → `pedidos.id`

**Benefícios**:
- ✅ Rastreabilidade completa: qual comanda gerou qual pedido
- ✅ Relatórios precisos de vendas por mesa
- ✅ Auditoria de operações locais
- ✅ Histórico preservado mesmo após fechamento

**Índice criado**:
```sql
CREATE INDEX idx_pedidos_comanda ON pedidos(comanda_id);
```

---

## 📋 FLUXO COMPLETO: COMANDA → PEDIDO → PDV

### Cenário 1: Comanda Simples (sem divisão)

```
1. Garçom abre comanda na Mesa 5
   └─ comandas.status = 'aberta'

2. Adiciona itens (pizza, bebida)
   └─ comanda_itens (com status de preparo)

3. Cliente pede conta
   └─ comandas.status = 'aguardando_pagamento'

4. Sistema converte comanda → pedido
   ├─ Cria pedido (tipo_entrega='local')
   ├─ pedidos.comanda_id = comandas.id
   ├─ comandas.pedido_id = pedidos.id
   └─ Snapshot de todos os itens

5. Pagamento no PDV
   ├─ Cria pedido_pagamentos
   ├─ pedido_pagamentos.caixa_id = pdv_caixas.id (aberto)
   └─ Vinculação explícita para auditoria

6. Fecha comanda
   └─ comandas.status = 'fechada'
```

### Cenário 2: Divisão de Conta

```
1. Mesa 5 com 4 pessoas pede para dividir

2. Sistema cria divisões
   ├─ comanda_divisoes (divisão 1, 2, 3, 4)
   └─ Distribui itens entre divisões

3. Cada divisão vira um pedido separado
   ├─ Pedido 1: comanda_id = Mesa 5, valor = R$ 45
   ├─ Pedido 2: comanda_id = Mesa 5, valor = R$ 38
   ├─ Pedido 3: comanda_id = Mesa 5, valor = R$ 52
   └─ Pedido 4: comanda_id = Mesa 5, valor = R$ 40

4. Pagamentos separados no PDV
   └─ Cada pedido tem seu pedido_pagamentos.caixa_id

5. Fecha comanda quando todas divisões pagas
```

---

## 🔄 INTEGRAÇÃO COM PDV

### Múltiplas Formas de Pagamento

**Já implementado em `pdv.sql`**:

```sql
tipo_pagamento TEXT DEFAULT 'dinheiro' CHECK (tipo_pagamento IN (
    'dinheiro', 'pix', 'cartao', 'transferencia'
))
```

### Regra Importante: Dinheiro vs Outras Formas

**DINHEIRO**:
- ✅ Entra na diferença física (quebra de caixa)
- ✅ Contado no fechamento
- ✅ Sangria/suprimento afetam o caixa físico

**PIX / CARTÃO / TRANSFERÊNCIA**:
- ✅ Entram no relatório de vendas
- ❌ NÃO entram na diferença física
- ℹ️ Apenas para controle gerencial

### View `pdv_caixas_resumo`

Separa automaticamente:
```sql
total_dinheiro           -- Entra na diferença
total_outras_formas      -- Apenas relatório
total_pix                -- Detalhamento
total_cartao             -- Detalhamento
```

---

## 🔐 VALIDAÇÕES IMPLEMENTADAS

### 1. Caixa Aberto para Pedidos Locais

**Trigger**: `validar_caixa_aberto_pedido_local()`

```sql
-- Bloqueia criação de pedido local sem caixa aberto
IF NEW.tipo_entrega = 'local' THEN
    -- Verifica se existe caixa aberto
    -- Se não existe, RAISE EXCEPTION
END IF;
```

**Camadas de Validação**:
1. ✅ Backend (obrigatória)
2. ✅ Banco de dados (trigger - camada extra)

### 2. Adicionar Itens Apenas em Comanda Aberta

**Validação Backend** (obrigatória):
```typescript
if (comanda.status !== 'aberta') {
  throw new Error('Não é possível adicionar itens. Comanda não está aberta.');
}
```

**Regra**:
- ✅ `status = 'aberta'`: PODE adicionar itens
- ❌ `status = 'aguardando_pagamento'`: NÃO PODE (conta já pedida)
- ❌ `status = 'fechada'`: NÃO PODE (finalizada)
- ❌ `status = 'cancelada'`: NÃO PODE (cancelada)

### 3. Valor Total Calculado (Nunca Salvo)

**REGRA DE OURO**: NUNCA salvar `valor_total` na tabela `comandas`

```sql
-- ✅ SEMPRE calcular a partir dos itens
SELECT SUM(ci.valor_total) 
FROM comanda_itens ci
WHERE ci.comanda_id = ? AND ci.status != 'cancelado'
```

**Por quê?**
- Itens são a fonte da verdade
- Evita inconsistências
- Itens cancelados não entram no total
- Facilita auditoria

### 4. Divisão de Conta - Validação de Quantidade

**Validação Backend** (obrigatória):

Somatório de `comanda_divisao_itens.quantidade` por `comanda_item_id` NÃO PODE ultrapassar `comanda_itens.quantidade`

```typescript
// Exemplo de erro:
Pizza: quantidade = 1
Divisão 1: 0.6
Divisão 2: 0.5
Total: 1.1 ❌ ERRO! Ultrapassa 1.0

// Exemplo correto:
Pizza: quantidade = 1
Divisão 1: 0.5
Divisão 2: 0.5
Total: 1.0 ✅ OK
```

### 5. Cancelamento de Comanda

**Fluxo completo** (backend):
1. Marcar TODOS os itens como `status='cancelado'`
2. Gerar pedido com `status='cancelado'`
3. Fechar comanda com `status='cancelada'`
4. Vincular `pedido_id`

### 6. Uma Comanda Aberta por Mesa

**Índice único parcial**:
```sql
CREATE UNIQUE INDEX idx_comandas_mesa_aberta 
    ON comandas(mesa_id) 
    WHERE status = 'aberta' AND deleted_at IS NULL;
```

### 7. Um Caixa Aberto por Loja

**Índice único parcial**:
```sql
CREATE UNIQUE INDEX idx_pdv_caixas_loja_aberto 
    ON pdv_caixas(loja_id) 
    WHERE status = 'aberto';
```

---

## 📊 VIEWS ÚTEIS

### Comandas com Pedidos
```sql
SELECT 
    c.numero_comanda,
    c.mesa_id,
    c.status AS comanda_status,
    p.codigo_pedido,
    p.total AS pedido_total,
    p.status AS pedido_status
FROM comandas c
LEFT JOIN pedidos p ON c.id = p.comanda_id
WHERE c.deleted_at IS NULL;
```

### Pedidos Locais com Caixa
```sql
SELECT 
    p.codigo_pedido,
    p.total,
    pp.tipo_pagamento,
    pp.valor,
    pc.aberto_em AS caixa_aberto_em,
    pc.fechado_em AS caixa_fechado_em
FROM pedidos p
INNER JOIN pedido_pagamentos pp ON p.id = pp.pedido_id
LEFT JOIN pdv_caixas pc ON pp.caixa_id = pc.id
WHERE p.tipo_entrega = 'local'
ORDER BY p.created_at DESC;
```

### Relatório de Vendas por Mesa
```sql
SELECT 
    m.numero_mesa,
    COUNT(DISTINCT c.id) AS total_comandas,
    COUNT(DISTINCT p.id) AS total_pedidos,
    SUM(p.total) AS total_vendido
FROM comandas_mesas m
LEFT JOIN comandas c ON m.id = c.mesa_id
LEFT JOIN pedidos p ON c.id = p.comanda_id
WHERE c.deleted_at IS NULL
  AND p.status NOT IN ('cancelado', 'rejeitado')
GROUP BY m.numero_mesa
ORDER BY total_vendido DESC;
```

---

## 🎯 PRÓXIMOS MÓDULOS

Conforme o resumo do projeto, ainda faltam:

1. **configuracoes** - Configurações do sistema
2. **historico_pedidos** - Auditoria de mudanças em pedidos
3. **historico_comandas** - Auditoria de mudanças em comandas
4. **historico_pdv** - Auditoria de operações do PDV

---

## 📝 NOTAS IMPORTANTES

### Soft Delete
- ✅ Comandas têm `deleted_at` para correções operacionais
- ✅ Mantém consistência com resto do banco
- ✅ Histórico preservado

### Número de Comanda
- ✅ Gerado pelo backend por loja
- ✅ `UNIQUE(loja_id, numero_comanda)`
- ✅ Evita "vazamento" entre lojas

### Valor Total da Comanda
- ⚠️ NUNCA salvar na tabela comandas
- ✅ SEMPRE calcular a partir dos itens não cancelados
- ✅ Fórmula: `SUM(ci.valor_total) WHERE ci.status != 'cancelado'`
- ✅ Views já fazem isso corretamente

### Adicionar Itens
- ✅ PODE adicionar enquanto `status = 'aberta'`
- ❌ NÃO PODE adicionar após `status = 'aguardando_pagamento'`
- ⚠️ Validação obrigatória no backend

### Cancelamento
- ✅ Comanda cancelada TAMBÉM vira pedido
- ✅ Todos os itens devem ser marcados como cancelados
- ✅ Mantém histórico completo
- ✅ Motivo obrigatório

### Divisão de Conta
- ✅ Quantidade pode ser parcial (NUMERIC)
- ⚠️ Somatório NÃO PODE ultrapassar quantidade original
- ⚠️ Validação obrigatória no backend

### Auditoria
- ✅ Vinculação explícita via `caixa_id`
- ✅ Permite relatórios precisos
- ✅ Evita erro se pedido for ajustado depois

---

## ✨ BENEFÍCIOS DA INTEGRAÇÃO

1. **Rastreabilidade Total**
   - Comanda → Pedido → Pagamento → Caixa
   - Histórico completo preservado

2. **Relatórios Precisos**
   - Vendas por mesa
   - Vendas por caixa
   - Vendas por forma de pagamento

3. **Auditoria Confiável**
   - Quem abriu/fechou comanda
   - Quem abriu/fechou caixa
   - Quem realizou pagamento

4. **Flexibilidade**
   - Divisão de conta
   - Múltiplas formas de pagamento
   - Sangria/suprimento em qualquer forma

5. **Segurança**
   - Validações em múltiplas camadas
   - Índices únicos previnem duplicação
   - Soft delete preserva histórico

---

## 📖 DOCUMENTAÇÃO ADICIONAL

Para detalhes completos sobre validações do backend, consulte:

**[REGRAS_VALIDACAO_BACKEND.md](./REGRAS_VALIDACAO_BACKEND.md)**

Este documento contém:
- ✅ Regras críticas obrigatórias
- ✅ Exemplos de código TypeScript
- ✅ Validações de comandas, PDV e estoque
- ✅ Testes recomendados
- ✅ Prevenção de race conditions
- ✅ Fluxos completos de integração

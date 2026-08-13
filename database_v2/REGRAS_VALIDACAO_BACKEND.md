# Regras de Validação - Backend

## 🎯 REGRAS CRÍTICAS (OBRIGATÓRIAS)

Estas validações DEVEM ser implementadas no backend. O banco de dados não as garante.

---

## 📋 COMANDAS

### 1. Adicionar Itens à Comanda

**REGRA**: Só pode adicionar itens se `status = 'aberta'`

```typescript
// ✅ CORRETO
async function adicionarItemComanda(comandaId: string, item: Item) {
  const comanda = await getComanda(comandaId);
  
  if (comanda.status !== 'aberta') {
    throw new Error('Não é possível adicionar itens. Comanda não está aberta.');
  }
  
  // Prosseguir com adição
}
```

**Motivos**:
- `aguardando_pagamento`: Conta já foi pedida, não pode alterar
- `fechada`: Comanda finalizada, não pode alterar
- `cancelada`: Comanda cancelada, não pode alterar

**Exceção**: Nenhuma. Regra é absoluta.

---

### 2. Valor Total da Comanda

**REGRA DE OURO**: NUNCA salvar `valor_total` na tabela `comandas`

```typescript
// ❌ ERRADO
UPDATE comandas SET valor_total = 150.00 WHERE id = ?

// ✅ CORRETO - Sempre calcular
SELECT 
  c.id,
  c.numero_comanda,
  SUM(ci.valor_total) FILTER (WHERE ci.status != 'cancelado') AS valor_total
FROM comandas c
LEFT JOIN comanda_itens ci ON c.id = ci.comanda_id
WHERE c.id = ?
GROUP BY c.id;
```

**Por quê?**
- Itens são a fonte da verdade
- Evita inconsistências
- Itens cancelados não entram no total
- Facilita auditoria

**Implementação**:
```typescript
async function getValorTotalComanda(comandaId: string): Promise<number> {
  const result = await db.query(`
    SELECT COALESCE(SUM(valor_total), 0) AS total
    FROM comanda_itens
    WHERE comanda_id = $1 AND status != 'cancelado'
  `, [comandaId]);
  
  return result.rows[0].total;
}
```

---

### 3. Cancelamento de Comanda

**REGRA**: Ao cancelar comanda, cancelar TODOS os itens

```typescript
async function cancelarComanda(
  comandaId: string, 
  motivo: string, 
  usuarioId: string
) {
  await db.transaction(async (trx) => {
    // 1. Cancelar todos os itens
    await trx.query(`
      UPDATE comanda_itens
      SET status = 'cancelado'
      WHERE comanda_id = $1 AND status != 'cancelado'
    `, [comandaId]);
    
    // 2. Gerar pedido cancelado (snapshot)
    const pedidoId = await criarPedidoCancelado(comandaId, trx);
    
    // 3. Cancelar comanda
    await trx.query(`
      UPDATE comandas
      SET 
        status = 'cancelada',
        cancelada_por = $2,
        cancelada_em = NOW(),
        motivo_cancelamento = $3,
        pedido_id = $4
      WHERE id = $1
    `, [comandaId, usuarioId, motivo, pedidoId]);
  });
}
```

**Fluxo completo**:
1. Marcar itens como `cancelado`
2. Gerar pedido com `status='cancelado'`
3. Fechar comanda com `status='cancelada'`
4. Vincular `pedido_id`

---

### 4. Divisão de Conta - Validação de Quantidade

**REGRA**: Somatório das quantidades NÃO PODE ultrapassar quantidade original

```typescript
async function validarDivisaoItens(
  comandaId: string, 
  divisoes: Divisao[]
): Promise<void> {
  // Buscar itens da comanda
  const itens = await getItensComanda(comandaId);
  
  // Para cada item, validar somatório
  for (const item of itens) {
    const totalDividido = divisoes
      .flatMap(d => d.itens)
      .filter(di => di.comanda_item_id === item.id)
      .reduce((sum, di) => sum + di.quantidade, 0);
    
    if (totalDividido > item.quantidade) {
      throw new Error(
        `Item "${item.nome}": quantidade dividida (${totalDividido}) ` +
        `ultrapassa quantidade original (${item.quantidade})`
      );
    }
    
    // Opcional: Validar se soma exata (não sobra)
    if (totalDividido < item.quantidade) {
      console.warn(
        `Item "${item.nome}": quantidade dividida (${totalDividido}) ` +
        `é menor que original (${item.quantidade}). Sobra: ${item.quantidade - totalDividido}`
      );
    }
  }
}
```

**Exemplo de erro**:
```
Pizza Calabresa: quantidade = 1
Divisão 1: 0.6
Divisão 2: 0.5
Total: 1.1 ❌ ERRO! Ultrapassa 1.0
```

**Exemplo correto**:
```
Pizza Calabresa: quantidade = 1
Divisão 1: 0.5
Divisão 2: 0.5
Total: 1.0 ✅ OK
```

---

## 💰 PDV (CAIXA)

### 5. Pedido Local Requer Caixa Aberto

**REGRA**: Pedidos `tipo_entrega='local'` só podem ser criados com caixa aberto

```typescript
async function criarPedidoLocal(pedido: Pedido): Promise<string> {
  // Verificar se existe caixa aberto
  const caixaAberto = await db.query(`
    SELECT id FROM pdv_caixas
    WHERE loja_id = $1 AND status = 'aberto'
    LIMIT 1
  `, [pedido.loja_id]);
  
  if (!caixaAberto.rows.length) {
    throw new Error(
      'Não é possível criar pedido local sem caixa aberto. ' +
      'Abra o caixa primeiro.'
    );
  }
  
  // Prosseguir com criação
  const pedidoId = await inserirPedido(pedido);
  
  // Vincular pagamento ao caixa
  await inserirPagamento({
    pedido_id: pedidoId,
    caixa_id: caixaAberto.rows[0].id,
    // ... outros campos
  });
  
  return pedidoId;
}
```

**Camadas de validação**:
1. ✅ Backend (obrigatória) - Esta função
2. ✅ Banco de dados (trigger) - Camada extra de segurança

**Nota**: O trigger `validar_caixa_aberto_pedido_local()` já existe no banco como backup.

---

### 6. Cálculo de Valor Esperado no Fechamento

**REGRA**: Valor esperado = abertura + vendas_dinheiro - sangrias_dinheiro + suprimentos_dinheiro

```typescript
async function calcularValorEsperado(caixaId: string): Promise<number> {
  const result = await db.query(`
    SELECT 
      c.valor_abertura,
      
      -- Vendas em DINHEIRO (entra na diferença física)
      COALESCE(SUM(pp.valor) FILTER (
        WHERE pp.tipo_pagamento = 'dinheiro' 
        AND pp.caixa_id = c.id
      ), 0) AS vendas_dinheiro,
      
      -- Sangrias em DINHEIRO (sai do caixa)
      COALESCE(SUM(m.valor) FILTER (
        WHERE m.tipo = 'sangria' 
        AND m.tipo_pagamento = 'dinheiro'
      ), 0) AS sangrias_dinheiro,
      
      -- Suprimentos em DINHEIRO (entra no caixa)
      COALESCE(SUM(m.valor) FILTER (
        WHERE m.tipo = 'suprimento' 
        AND m.tipo_pagamento = 'dinheiro'
      ), 0) AS suprimentos_dinheiro
      
    FROM pdv_caixas c
    LEFT JOIN pedido_pagamentos pp ON pp.caixa_id = c.id
    LEFT JOIN pdv_movimentacoes_caixa m ON m.caixa_id = c.id
    WHERE c.id = $1
    GROUP BY c.id, c.valor_abertura
  `, [caixaId]);
  
  const { valor_abertura, vendas_dinheiro, sangrias_dinheiro, suprimentos_dinheiro } = result.rows[0];
  
  return valor_abertura + vendas_dinheiro - sangrias_dinheiro + suprimentos_dinheiro;
}
```

**IMPORTANTE**:
- ✅ Dinheiro: entra na diferença física
- ❌ PIX/Cartão: NÃO entra na diferença (apenas relatório)

**Uso**:
```typescript
async function fecharCaixa(caixaId: string, valorContado: number) {
  const valorEsperado = await calcularValorEsperado(caixaId);
  const diferenca = valorContado - valorEsperado;
  
  await db.query(`
    UPDATE pdv_caixas
    SET 
      status = 'fechado',
      valor_fechamento = $2,
      valor_esperado = $3,
      fechado_em = NOW()
    WHERE id = $1
  `, [caixaId, valorContado, valorEsperado]);
  
  // Trigger calcula diferenca automaticamente
}
```

---

## 📦 ESTOQUE

### 7. Movimentação com SELECT FOR UPDATE

**REGRA**: Usar lock para evitar race conditions

```typescript
async function criarMovimentacao(
  itemId: string,
  tipo: string,
  quantidade: number,
  motivo: string
) {
  await db.transaction(async (trx) => {
    // 1. Lock na leitura (previne race condition)
    const item = await trx.query(`
      SELECT quantidade_atual
      FROM itens_estoque
      WHERE id = $1
      FOR UPDATE
    `, [itemId]);
    
    const quantidadeAnterior = item.rows[0].quantidade_atual;
    
    // 2. Calcular nova quantidade
    const quantidadeNova = tipo.startsWith('entrada')
      ? quantidadeAnterior + quantidade
      : quantidadeAnterior - quantidade;
    
    // 3. Validar quantidade não negativa
    if (quantidadeNova < 0) {
      throw new Error('Estoque insuficiente');
    }
    
    // 4. Inserir movimentação
    await trx.query(`
      INSERT INTO estoque_movimentacoes (
        item_estoque_id, tipo_movimentacao, quantidade,
        quantidade_anterior, quantidade_nova, motivo, realizado_por
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, [itemId, tipo, quantidade, quantidadeAnterior, quantidadeNova, motivo, userId]);
    
    // Trigger atualiza quantidade_atual automaticamente
  });
}
```

**Por quê SELECT FOR UPDATE?**
- Previne race conditions
- Garante atomicidade
- Evita sobrescrever movimentações simultâneas

**Exemplo de problema sem lock**:
```
Thread A: lê quantidade = 10
Thread B: lê quantidade = 10
Thread A: calcula nova = 10 - 5 = 5
Thread B: calcula nova = 10 - 3 = 7
Thread A: salva 5 ❌
Thread B: salva 7 ❌ (sobrescreveu A)
Resultado: Perdeu 5 unidades!
```

---

### 8. Nunca Editar quantidade_atual Diretamente

**REGRA**: SEMPRE criar movimentação

```typescript
// ❌ ERRADO
UPDATE itens_estoque SET quantidade_atual = 50 WHERE id = ?

// ✅ CORRETO
await criarMovimentacao(
  itemId,
  'entrada_ajuste', // ou 'saida_ajuste'
  quantidadeDiferenca,
  'Ajuste de inventário'
);
```

**Exceção**: Nenhuma. Mesmo inventário inicial deve criar movimentação.

---

## 🔄 INTEGRAÇÃO COMANDA → PEDIDO → ESTOQUE

### 9. Consumo Automático de Estoque

**REGRA**: Ao aprovar pedido, consumir ingredientes automaticamente

```typescript
async function aprovarPedido(pedidoId: string) {
  await db.transaction(async (trx) => {
    // 1. Buscar itens do pedido
    const itens = await getPedidoItens(pedidoId, trx);
    
    // 2. Para cada item, calcular consumo
    for (const item of itens) {
      if (item.tipo_item === 'produto') {
        // Buscar ingredientes do produto
        const ingredientes = await trx.query(`
          SELECT 
            pi.item_estoque_id,
            pi.quantidade_por_unidade,
            pi.unidade_medida
          FROM produto_ingredientes pi
          WHERE pi.produto_id = $1
            AND (pi.tamanho_id = $2 OR pi.tamanho_id IS NULL)
            AND pi.ativo = true
        `, [item.produto_id, item.tamanho_id]);
        
        // Criar movimentação para cada ingrediente
        for (const ing of ingredientes.rows) {
          const quantidadeTotal = ing.quantidade_por_unidade * item.quantidade;
          
          await criarMovimentacao(
            ing.item_estoque_id,
            'saida_consumo',
            quantidadeTotal,
            `Consumo do pedido ${pedidoId}`,
            trx,
            pedidoId // vincula com pedido
          );
        }
      }
    }
    
    // 3. Atualizar status do pedido
    await trx.query(`
      UPDATE pedidos
      SET status = 'confirmado', confirmado_em = NOW()
      WHERE id = $1
    `, [pedidoId]);
  });
}
```

---

## 📊 RESUMO DE VALIDAÇÕES

| # | Validação | Onde | Crítica |
|---|-----------|------|---------|
| 1 | Adicionar item só se comanda aberta | Backend | ✅ Sim |
| 2 | Valor total calculado (não salvo) | Backend | ✅ Sim |
| 3 | Cancelar comanda = cancelar itens | Backend | ✅ Sim |
| 4 | Divisão: somatório ≤ quantidade | Backend | ✅ Sim |
| 5 | Pedido local requer caixa aberto | Backend + Trigger | ✅ Sim |
| 6 | Valor esperado só conta dinheiro | Backend | ✅ Sim |
| 7 | Movimentação com SELECT FOR UPDATE | Backend | ✅ Sim |
| 8 | Nunca editar quantidade_atual | Backend | ✅ Sim |
| 9 | Consumo automático de estoque | Backend | ⚠️ Opcional |

---

## 🧪 TESTES RECOMENDADOS

### Teste 1: Adicionar Item em Comanda Fechada
```typescript
test('não deve adicionar item em comanda fechada', async () => {
  const comanda = await criarComanda();
  await fecharComanda(comanda.id);
  
  await expect(
    adicionarItemComanda(comanda.id, item)
  ).rejects.toThrow('Comanda não está aberta');
});
```

### Teste 2: Divisão Ultrapassando Quantidade
```typescript
test('não deve permitir divisão que ultrapassa quantidade', async () => {
  const comanda = await criarComandaComItens([
    { nome: 'Pizza', quantidade: 1 }
  ]);
  
  const divisoes = [
    { itens: [{ comanda_item_id: item.id, quantidade: 0.6 }] },
    { itens: [{ comanda_item_id: item.id, quantidade: 0.5 }] }
  ];
  
  await expect(
    validarDivisaoItens(comanda.id, divisoes)
  ).rejects.toThrow('ultrapassa quantidade original');
});
```

### Teste 3: Race Condition em Estoque
```typescript
test('deve prevenir race condition em movimentação', async () => {
  const item = await criarItemEstoque({ quantidade_atual: 10 });
  
  // Simular 2 movimentações simultâneas
  await Promise.all([
    criarMovimentacao(item.id, 'saida_consumo', 5, 'Teste 1'),
    criarMovimentacao(item.id, 'saida_consumo', 3, 'Teste 2')
  ]);
  
  const resultado = await getItemEstoque(item.id);
  expect(resultado.quantidade_atual).toBe(2); // 10 - 5 - 3 = 2
});
```

---

**Última atualização**: 25/01/2026
**Versão**: 1.0

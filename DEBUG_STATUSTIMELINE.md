# Debug - StatusTimeline Não Aparecendo

## 📋 Problema
A página de confirmação (ProcessandoPedido) não está exibindo o acompanhamento de status em tempo real após o checkout.

A imagem mostra:
- ✅ Pedido confirmado (verde)
- ✅ Total e informações aparecem
- ❌ **Mas o "Acompanhe seu Pedido" (StatusTimeline) não é visível**

---

## 🔍 Como Diagnosticar

### Passo 1: Abra o Console do Navegador
1. Faça um pedido de delivery normalmente
2. Na página de confirmação, pressione **F12** (DevTools)
3. Vá para a aba **"Console"**

### Passo 2: Procure pelos Logs
Você deve ver logs como:

```
✅ [ProcessandoPedido] Histórico carregado: Array(1)
  0: {id: "...", pedido_id: "...", status: "Pedido criado", observacao: "..."}
  
StatusTimeline renderizado: 
  {historicoLength: 1, historicoItems: Array(1), pedidoId: "...", ...}
```

### Passo 3: Verifique os Dados

Procure por estes logs específicos:

#### ✅ Se ver isto, tudo OK:
```
✅ [ProcessandoPedido] Histórico carregado: Array(1)
StatusTimeline renderizado: {historicoLength: 1, ...}
```

#### ❌ Se ver isto, há problema:
```
✅ [ProcessandoPedido] Histórico carregado: Array(0)  ← HISTÓRICO VAZIO!
```

#### ❌ Se ver isto, erro na busca:
```
Erro ao carregar histórico: Error: ...
```

---

## 🐛 Possíveis Problemas e Soluções

### Problema 1: Histórico Vazio
**Log**: `historicoLength: 0`

**Causa possível**: 
- Tabela `historico_pedidos` não foi preenchida
- Formato do `codigo_pedido` está diferente

**Solução**:
1. Verifique no Supabase Studio
2. Tabela: `historico_pedidos`
3. Procure pelo `codigo_pedido` do seu pedido
4. Verifique se existe algum registro

### Problema 2: Erro de Permissão
**Log**: `Error: "..." (Falha ao buscar histórico)`

**Causa possível**:
- RLS (Row Level Security) bloqueando acesso
- Usuário sem permissão

**Solução**:
1. Verifique RLS policies na tabela `historico_pedidos`
2. Certifique que o `estabelecimento_id` está correto

### Problema 3: Realtime Não Conectando
**Sintoma**: Timeline não atualiza quando status muda

**Verificação**:
1. DevTools → Network → Filtre por "realtime" ou "websocket"
2. Procure por conexões WebSocket ativas
3. Se não houver, realtime não conectou

---

## 🧪 Teste Manual

### Teste 1: Verificar Histórico no Banco
```sql
SELECT * FROM historico_pedidos 
WHERE pedido_id = 'seu-codigo-aqui'
ORDER BY criado_em DESC;
```

### Teste 2: Criar Status Manualmente
```sql
INSERT INTO historico_pedidos (
  pedido_id,
  status,
  observacao,
  estabelecimento_id,
  criado_em
) VALUES (
  'seu-codigo-aqui',
  'Preparando',
  'Preparação iniciada',
  'seu-estab-id',
  NOW()
);
```

Depois atualize a página - deve aparecer nova linha na timeline.

### Teste 3: Ver Se Realtime Está Escutando
Abra DevTools e rode:
```javascript
// No console do navegador
localStorage.getItem('sb-realtime-debug'); // Check if debug logs estão ativados
```

---

## 📊 Estrutura Esperada

### Componente ProcessandoPedido
```
ProcessandoPedido
  ├─ carregarHistorico() ← Busca dados
  ├─ historico: HistoricoPedidoSupabase[] ← Estado
  └─ <StatusTimeline historico={historico} /> ← Renderiza
```

### StatusTimeline Esperado
```
Card
  ├─ Header
  │  ├─ Título: "Acompanhe seu Pedido"
  │  └─ Status Realtime (ponto verde/animado)
  └─ Content
     ├─ Se vazio: "Nenhuma atualização de status ainda"
     └─ Se com dados: Timeline com status históricos
```

---

## 📝 Arquivo de Logs Adicionados

Os seguintes arquivos foram modificados com logs de debug:

1. **src/pages/ProcessandoPedido.tsx**
   - Log ao buscar histórico
   - Log ao criar primeiro status
   - Log de erro

2. **src/components/StatusTimeline.tsx**
   - Log ao renderizar
   - Exibe length do histórico
   - Exibe IDs para comparação

---

## 🚀 Próximas Etapas

Após executar os testes acima:

1. **Copie os logs** do console
2. **Abra o Supabase Studio**
3. **Verifique a tabela `historico_pedidos`**
4. **Compare dados**

Com essas informações, vamos conseguir identificar exatamente onde está o problema.

---

## 💡 Dicas

- **F12** para abrir DevTools
- **Ctrl+Shift+Delete** para limpar cache
- **Atualizar página** após fazer um novo pedido (às vezes cache atrapalha)
- **Incógnito** é útil para testar sem cache

---

**Status**: Build com logs adicionados  
**Data**: 2026-07-14  
**Próximo Passo**: Testar e coletar logs

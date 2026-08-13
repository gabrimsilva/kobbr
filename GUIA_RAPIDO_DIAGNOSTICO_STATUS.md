# Guia Rápido: Diagnosticar Erro ao Mudar Status do Pedido

## 🚨 Problema
Ao arrastar um pedido no Kanban para mudar o status, o pedido não muda de coluna e não há feedback visual.

## 🔍 Passo 1: Verificar Erro no Console do Navegador

1. Abra o DevTools (F12)
2. Vá na aba **Console**
3. Tente mudar o status de um pedido
4. Procure por mensagens de erro em vermelho

### O que procurar:

```
❌ Erro ao atualizar status do pedido
❌ Erro detalhado ao atualizar status: { ... }
❌ Falha ao atualizar status: ...
```

## 🔍 Passo 2: Verificar Requisições HTTP

1. No DevTools, vá na aba **Network** (Rede)
2. Filtre por "pedidos" ou "supabase"
3. Tente mudar o status novamente
4. Procure por requisições com status de erro:
   - 🔴 400 Bad Request
   - 🔴 401 Unauthorized
   - 🔴 403 Forbidden
   - 🔴 406 Not Acceptable
   - 🔴 409 Conflict
   - 🔴 500 Internal Server Error

5. Clique na requisição com erro
6. Veja a aba **Response** para ver a mensagem de erro

## 🔍 Passo 3: Verificar Logs Detalhados

Com as correções aplicadas, você verá logs mais detalhados:

```
🎯 Iniciando atualização de status: { pedidoId: "...", novoStatus: "..." }
🔄 Atualizando status do pedido: { ... }
📤 Dados do update: { status: "...", atualizado_em: "..." }
📥 Resposta do Supabase: { sucesso: true/false, ... }
```

Se houver erro, verá:

```
❌ Erro detalhado ao atualizar status: {
  message: "...",
  details: "...",
  hint: "...",
  code: "..."
}
```

## 🔧 Passo 4: Executar Script de Correção no Banco

1. Acesse o Supabase Dashboard
2. Vá em **SQL Editor**
3. Abra o arquivo `CORRIGIR_ERRO_STATUS_PEDIDO.sql`
4. Execute o script completo
5. Verifique os resultados de cada seção

### Principais verificações do script:

- ✅ Estrutura da tabela está correta?
- ✅ Trigger `atualizado_em` existe?
- ✅ Políticas RLS estão corretas?
- ✅ Há pedidos com status inválido?

## 🎯 Erros Comuns e Soluções

### Erro 1: "new row violates check constraint"

**Causa**: Status inválido ou constraint bloqueando

**Solução**:
```sql
-- Verificar constraint
SELECT pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname = 'pedidos_status_valido';

-- Se necessário, remover e recriar
ALTER TABLE pedidos DROP CONSTRAINT IF EXISTS pedidos_status_valido;
```

### Erro 2: "permission denied for table pedidos"

**Causa**: Políticas RLS bloqueando atualização

**Solução**:
```sql
-- Verificar políticas
SELECT * FROM pg_policies WHERE tablename = 'pedidos';

-- Recriar política de UPDATE
DROP POLICY IF EXISTS "Permitir atualização pública pedidos" ON pedidos;
CREATE POLICY "Permitir atualização pública pedidos" 
ON pedidos FOR UPDATE USING (true) WITH CHECK (true);
```

### Erro 3: "column 'atualizado_em' cannot be null"

**Causa**: Campo obrigatório não está sendo preenchido

**Solução**: Já corrigido no código! O campo agora é preenchido explicitamente:
```typescript
const updateData = {
  status: novoStatus,
  atualizado_em: new Date().toISOString() // ✅ Adicionado
}
```

### Erro 4: Timeout / Network Error

**Causa**: Conexão lenta ou instável

**Solução**:
- Verificar conexão com internet
- Verificar status do Supabase: https://status.supabase.com
- Aguardar alguns segundos e tentar novamente

### Erro 5: "Pedido não encontrado"

**Causa**: `pedido_id` não existe na tabela

**Solução**:
```sql
-- Verificar se o pedido existe
SELECT * FROM pedidos WHERE pedido_id = 'ID_DO_PEDIDO';

-- Verificar se há duplicatas
SELECT pedido_id, COUNT(*) 
FROM pedidos 
GROUP BY pedido_id 
HAVING COUNT(*) > 1;
```

## 📊 Passo 5: Testar Manualmente no Banco

Execute no SQL Editor:

```sql
-- 1. Buscar um pedido
SELECT pedido_id, status FROM pedidos LIMIT 1;

-- 2. Tentar atualizar (substitua o ID)
UPDATE pedidos 
SET status = 'Preparando', atualizado_em = now()
WHERE pedido_id = 'SEU_PEDIDO_ID';

-- 3. Verificar se funcionou
SELECT pedido_id, status, atualizado_em 
FROM pedidos 
WHERE pedido_id = 'SEU_PEDIDO_ID';
```

Se funcionar no SQL mas não no frontend, o problema é no código JavaScript/TypeScript.

Se não funcionar no SQL, o problema é no banco de dados (constraints, triggers, RLS).

## ✅ Checklist Final

- [ ] Logs detalhados aparecem no console?
- [ ] Requisição HTTP aparece na aba Network?
- [ ] Qual o código de status HTTP? (200, 400, 500, etc)
- [ ] Qual a mensagem de erro exata?
- [ ] O script SQL foi executado sem erros?
- [ ] O teste manual no SQL funcionou?
- [ ] O usuário está autenticado?
- [ ] As variáveis de ambiente estão corretas?

## 🆘 Se Nada Funcionar

1. **Desabilitar RLS temporariamente** (apenas para teste):
```sql
ALTER TABLE pedidos DISABLE ROW LEVEL SECURITY;
-- Testar
-- Depois reabilitar:
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
```

2. **Verificar logs do Supabase**:
   - Dashboard → Logs → API Logs
   - Procurar por erros relacionados a "pedidos"

3. **Limpar cache do navegador**:
   - Ctrl + Shift + Delete
   - Limpar cache e cookies
   - Recarregar página (Ctrl + F5)

4. **Testar em modo anônimo**:
   - Abrir navegador em modo anônimo
   - Fazer login novamente
   - Testar atualização de status

## 📞 Informações para Suporte

Se precisar de ajuda, tenha em mãos:

- Mensagem de erro completa do console
- Código de status HTTP da requisição
- Resultado do script SQL de diagnóstico
- Versão do navegador
- Se funciona em desenvolvimento mas não em produção

## 🎉 Melhorias Aplicadas

✅ Logs detalhados em cada etapa
✅ Feedback visual com toast de sucesso/erro
✅ Campo `atualizado_em` preenchido explicitamente
✅ Tratamento de erro melhorado
✅ Script SQL de diagnóstico completo
✅ Documentação detalhada do problema

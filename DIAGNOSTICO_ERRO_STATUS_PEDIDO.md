# Diagnóstico: Erro ao Mudar Status do Pedido em Produção

## 🔍 Problema Identificado

Ao tentar mudar o status de um pedido no Kanban (página Pedidos), o sistema apresenta erro em produção. O pedido não muda de coluna e não há feedback visual do erro.

## 📊 Análise do Código

### 1. Fluxo de Atualização de Status

O fluxo de atualização acontece em:

```
Pedidos.tsx (handleDragEnd) 
  → useGerenciarPedidos.atualizarStatus()
    → pedidoService.atualizarStatus()
      → supabase.from('pedidos').update()
```

### 2. Código Atual (useGerenciarPedidos.ts)

```typescript
const atualizarStatus = async (pedidoId: string, novoStatus: string) => {
  // ...
  await pedidoService.atualizarStatus(pedidoId, statusFinal)
  // ...
}
```

### 3. Políticas RLS Atuais

As políticas RLS para a tabela `pedidos` estão configuradas como:

```sql
CREATE POLICY "Permitir atualização pública pedidos" 
ON public.pedidos 
FOR UPDATE 
USING (true) 
WITH CHECK (true);
```

✅ As políticas RLS estão corretas e permitem atualização.

## 🐛 Possíveis Causas do Erro

### 1. **Erro de Conexão/Timeout**
- A requisição pode estar falhando por timeout
- Conexão instável com o Supabase em produção

### 2. **Erro Silencioso no Frontend**
- O erro está sendo capturado mas não exibido ao usuário
- O `reportError` pode não estar mostrando toast/notificação

### 3. **Trigger ou Constraint Falhando**
- Algum trigger na tabela pode estar falhando
- Constraint de validação pode estar bloqueando

### 4. **Campo Obrigatório Faltando**
- O update pode estar tentando setar um campo NULL que não permite

### 5. **Problema com o Campo `atualizado_em`**
- O comentário no código diz "atualizado automaticamente pelo trigger"
- Se o trigger não existir ou falhar, pode causar erro

## 🔧 Soluções Propostas

### Solução 1: Adicionar Logging Detalhado (Imediato)

Modificar o `pedidoService.atualizarStatus()` para logar mais informações:

```typescript
async atualizarStatus(pedidoId: string, novoStatus: string, observacoes?: string): Promise<PedidoSupabase> {
  console.log('🔄 Atualizando status:', { pedidoId, novoStatus, observacoes })
  
  const updateData: any = {
    status: novoStatus,
    atualizado_em: new Date().toISOString() // ⚠️ Adicionar explicitamente
  }

  if (observacoes) {
    updateData.observacoes = observacoes
  }

  console.log('📤 Dados do update:', updateData)

  const { data, error } = await supabase
    .from('pedidos')
    .update(updateData)
    .eq('pedido_id', pedidoId)
    .select()
    .single()

  console.log('📥 Resposta do Supabase:', { data, error })

  if (error) {
    console.error('❌ Erro detalhado:', {
      message: error.message,
      details: error.details,
      hint: error.hint,
      code: error.code
    })
    throw new Error(`Falha ao atualizar status: ${error.message}`)
  }

  if (!data) {
    throw new Error('Pedido não encontrado')
  }

  return data
}
```

### Solução 2: Melhorar Feedback de Erro no Frontend

Modificar `useGerenciarPedidos.ts` para mostrar toast:

```typescript
import toast from 'react-hot-toast'

const atualizarStatus = async (pedidoId: string, novoStatus: string) => {
  try {
    // ... código existente ...
  } catch (error) {
    // Mostrar erro visual ao usuário
    toast.error('Erro ao atualizar status do pedido')
    
    console.error('❌ Erro completo:', error)
    
    reportError({
      type: ErrorType.DATABASE,
      severity: ErrorSeverity.ERROR,
      message: 'Não foi possível atualizar o status do pedido',
      technicalMessage: `Falha ao atualizar status: ${error instanceof Error ? error.message : 'Erro desconhecido'}`,
      originalError: error,
      retryable: true,
      action: 'Verifique sua conexão e tente novamente'
    })

    // Recarregar pedidos para sincronizar estado
    await carregarPedidos()
  }
}
```

### Solução 3: Verificar Trigger `atualizado_em`

Verificar se existe o trigger para atualizar `atualizado_em` automaticamente:

```sql
-- Verificar se o trigger existe
SELECT * FROM pg_trigger 
WHERE tgname LIKE '%pedidos%';

-- Se não existir, criar:
CREATE OR REPLACE FUNCTION update_atualizado_em()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_pedidos_atualizado_em
    BEFORE UPDATE ON public.pedidos
    FOR EACH ROW
    EXECUTE FUNCTION update_atualizado_em();
```

### Solução 4: Adicionar Validação de Status

Adicionar validação no banco para garantir que apenas status válidos sejam aceitos:

```sql
ALTER TABLE public.pedidos 
ADD CONSTRAINT pedidos_status_valido 
CHECK (status IN (
  'Pedido criado',
  'Aguardando pagamento',
  'Preparando',
  'Liberado',
  'Pronto para retirada',
  'Saiu para entrega',
  'Finalizado',
  'Entregue',
  'Retirado',
  'Cancelado'
));
```

### Solução 5: Adicionar Timeout e Retry

O código já usa `withRetry`, mas podemos melhorar:

```typescript
// Aumentar timeout para produção
const { data, error } = await supabase
  .from('pedidos')
  .update(updateData)
  .eq('pedido_id', pedidoId)
  .select()
  .single()
  .abortSignal(AbortSignal.timeout(10000)) // 10 segundos
```

## 📋 Checklist de Verificação

Para diagnosticar o problema em produção:

- [ ] Abrir DevTools (F12) e verificar aba Console
- [ ] Verificar aba Network para ver requisições falhando
- [ ] Procurar por erros 400, 401, 403, 406, 409, 500
- [ ] Verificar se há mensagens de erro do Supabase
- [ ] Testar com diferentes status (Preparando → Liberado → Finalizado)
- [ ] Verificar se o erro acontece com todos os pedidos ou apenas alguns
- [ ] Verificar se o usuário está autenticado corretamente
- [ ] Verificar se as variáveis de ambiente estão corretas em produção

## 🚀 Próximos Passos

1. **Imediato**: Adicionar logs detalhados no código (Solução 1)
2. **Curto prazo**: Melhorar feedback visual de erros (Solução 2)
3. **Médio prazo**: Verificar e corrigir triggers (Solução 3)
4. **Longo prazo**: Adicionar validações e constraints (Solução 4)

## 📝 Informações Adicionais

### Estrutura da Tabela Pedidos

- Campo `status`: TEXT (sem constraint de valores válidos)
- Campo `atualizado_em`: TIMESTAMPTZ DEFAULT now()
- Políticas RLS: Permitem UPDATE público

### Possíveis Erros Comuns

1. **406 Not Acceptable**: Formato de resposta não aceito
2. **409 Conflict**: Violação de constraint ou RLS
3. **500 Internal Server Error**: Erro no trigger ou função do banco
4. **Network Error**: Timeout ou conexão perdida

## 🔗 Arquivos Relacionados

- `src/hooks/useGerenciarPedidos.ts` - Hook de gerenciamento
- `src/services/pedidoService.ts` - Serviço de pedidos
- `src/pages/Pedidos.tsx` - Página do Kanban
- `BD_20_01 Novo banco - atual/03_tables.sql` - Estrutura da tabela
- `BD_20_01 Novo banco - atual/06_rls_policies.sql` - Políticas RLS

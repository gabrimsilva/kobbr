# Requirements: Acompanhamento em Tempo Real Pós-Checkout

## Objetivo
Adicionar a funcionalidade de **acompanhamento de pedido em tempo real** (timeline com histórico) na página de confirmação do pedido (ProcessandoPedido), logo após o cliente fazer o checkout. O cliente verá o status do seu pedido sendo atualizado automaticamente via Realtime do Supabase.

## Contexto Atual
- Existe página `AcompanhamentoPedidos.tsx` ("Meus Pedidos") com acompanhamento completo do pedido
- Existe página `ProcessandoPedido.tsx` (confirmação pós-checkout) que já mostra informações do pedido
- `ProcessandoPedido` JÁ TEM o código de Realtime e carregamento do histórico, mas não exibe a timeline de status

## Escopo da Implementação
- ✅ NÃO modificar a página "Meus Pedidos" (`AcompanhamentoPedidos.tsx`)
- ✅ Extrair o componente de "Timeline de Status" de `AcompanhamentoPedidos`
- ✅ Reutilizar esse componente em `ProcessandoPedido`
- ✅ Manter a mesma visual e comportamento em tempo real
- ✅ Melhorar a legibilidade: tornar a seção "Acompanhe seu Pedido" mais visível na tela de confirmação

## Especificação Técnica

### Componente: StatusTimeline (Novo)
**Localização**: `src/components/StatusTimeline.tsx`

**Responsabilidades**:
- Receber array de `HistoricoPedidoSupabase[]`
- Renderizar timeline visual com ícones e cores por status
- Exibir hora de cada atualização
- Mostrar observações do status
- Indicador de atualização em tempo real (animação)
- Status disponível: "Pedido criado", "Preparando", "Liberado", "Finalizado", etc.

**Props**:
```typescript
interface StatusTimelineProps {
  historico: HistoricoPedidoSupabase[];
  atualizandoRealtime?: boolean;
  ultimaAtualizacao?: Date;
  pedido?: PedidoSupabase; // Para converter "Liberado" → "Saiu para entrega"
}
```

**Cores e Ícones**:
- "Pedido criado" → Azul (indigo) + Ícone Package
- "Preparando" → Laranja + Ícone ChefHat
- "Liberado" → Verde + Ícone CheckCircle (ou Truck se delivery)
- "Finalizado"/"Entregue" → Verde escuro + Ícone CheckCircle
- "Cancelado" → Vermelho + Ícone X

### Integração em ProcessandoPedido.tsx

**O que já existe**:
✅ Estados `historico`, `atualizandoRealtime`, `ultimaAtualizacao`
✅ Hook useEffect com configuração de Realtime
✅ Funções `carregarHistorico()` e `carregarPedido()`

**O que precisa ser feito**:
- Substituir a seção "Acompanhe seu Pedido" (CardHeader + CardContent) por `<StatusTimeline />`
- Remover o código de renderização da timeline da página para o novo componente
- Passar props necessárias para o componente

### Localização Visual em ProcessandoPedido

**Ordem atual de cards**:
1. Status Hero (já muito bom)
2. **[INSERIR StatusTimeline AQUI]** ← Em destaque
3. Itens do Pedido
4. Sidebar (Seus Dados, Endereço, Pagamento)

**Layout Responsivo**:
- Desktop: StatusTimeline ocupa lg:col-span-2 (coluna principal)
- Mobile: StatusTimeline aparece em destaque após o hero

---

## Acceptance Criteria

### 1. Componente StatusTimeline Criado
- ✅ Arquivo `src/components/StatusTimeline.tsx` existe
- ✅ Componente recebe e exibe historico corretamente
- ✅ Timeline renderiza com cores e ícones corretos
- ✅ Indicador de atualização em tempo real (ponto verde animado) funciona

### 2. Integração em ProcessandoPedido
- ✅ Card de "Acompanhe seu Pedido" substituído por `<StatusTimeline />`
- ✅ Comportamento em tempo real mantido (updates via Realtime)
- ✅ Visual idêntico ao que existia
- ✅ Mensagem de atualização mantida (com timestamp)

### 3. Funcionalidade Após Checkout
- ✅ Cliente vê timeline imediatamente após confirmar pedido
- ✅ Timeline se atualiza em tempo real conforme muda o status
- ✅ Se não há histórico ainda (primeiro carregamento), exibe "Pedido criado"
- ✅ Timeline exibe hora exata de cada atualização

### 4. Sem Efeitos Colaterais
- ✅ Página "Meus Pedidos" continua funcionando normalmente
- ✅ Nenhuma mudança em `AcompanhamentoPedidos.tsx`
- ✅ Nenhuma mudança em serviços ou tipos

### 5. Performance
- ✅ Componente re-renderiza corretamente ao receber novos dados
- ✅ Sem memory leaks em useEffect
- ✅ Animação smooth da atualização em tempo real

---

## Exemplos de Estado

### Imediatamente após checkout
```
1. Pedido criado - 14:32 - "Pedido recebido pelo sistema"
```

### Após 5 minutos (em preparação)
```
1. Pedido criado - 14:32 - "Pedido recebido pelo sistema"
2. Preparando - 14:37 - "Seu pedido está em preparo"
```

### Pedido pronto para entrega
```
1. Pedido criado - 14:32 - "Pedido recebido pelo sistema"
2. Preparando - 14:37 - "Seu pedido está em preparo"
3. Saiu para entrega - 15:02 - "Seu pedido saiu para entrega"
```

### Pedido entregue
```
1. Pedido criado - 14:32 - "Pedido recebido pelo sistema"
2. Preparando - 14:37 - "Seu pedido está em preparo"
3. Saiu para entrega - 15:02 - "Seu pedido saiu para entrega"
4. Entregue - 15:25 - "Pedido entregue com sucesso!"
```

---

## Decisões de Design

### Por que extrair um componente?
- Reutilização: mesmo visual em "Meus Pedidos" e "Confirmação"
- Manutenção: mudança em uma timeline atualiza em ambas
- Legibilidade: ProcessandoPedido fica menos inchado

### Por que manter "Meus Pedidos" igual?
- Compatibilidade: nenhuma mudança de comportamento
- Opção 1: Manter código duplicado em AcompanhamentoPedidos (para não quebrar)
- Opção 2: Usar novo componente em AcompanhamentoPedidos também (future enhancement)

---

## Referências
- `src/pages/AcompanhamentoPedidos.tsx` - Linha 450+: renderização da timeline
- `src/pages/ProcessandoPedido.tsx` - Linha 330+: seção que será substituída
- `src/types/supabase.ts` - Tipos `HistoricoPedidoSupabase`, `PedidoSupabase`

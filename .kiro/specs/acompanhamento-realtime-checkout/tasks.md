# Implementation Tasks: Acompanhamento em Tempo Real Pós-Checkout

## Task 1: Criar Componente StatusTimeline

**Objetivo**: Extrair a lógica de renderização da timeline de status em um componente reutilizável.

**Descrição**:
Criar novo componente `src/components/StatusTimeline.tsx` que recebe um array de históricos e renderiza a timeline visual com cores, ícones e animações.

**Acceptance Criteria**:
- [ ] Arquivo criado em `src/components/StatusTimeline.tsx`
- [ ] Interface `StatusTimelineProps` definida com props necessárias
- [ ] Timeline renderiza corretamente com histórico reverso (mais recente por último, mas visualmente no final)
- [ ] Cada item exibe:
  - [ ] Ícone colorido (Package, ChefHat, CheckCircle, Truck, etc.)
  - [ ] Nome do status com formatação (ex: "Liberado" → "Saiu para entrega" se delivery)
  - [ ] Hora exata (HH:mm)
  - [ ] Observação do status (se houver)
- [ ] Cores corretas para cada status:
  - [ ] Criado: bg-indigo-500
  - [ ] Preparando: bg-orange-500
  - [ ] Liberado: bg-green-500 (ou bg-purple-500 se delivery)
  - [ ] Finalizado/Entregue: bg-green-600
- [ ] Indicador de atualização em tempo real:
  - [ ] Ponto verde piscando quando `atualizandoRealtime === true`
  - [ ] Timestamp: "Atualizado 14:32"
- [ ] Teste: renderiza com historico vazio (mostra mensagem ou placeholder)
- [ ] Teste: renderiza com múltiplos itens

**Componentes a Usar**:
- `Card`, `CardHeader`, `CardTitle`, `CardContent` do shadcn/ui
- Icons: `Package`, `ChefHat`, `CheckCircle`, `Truck`, `Clock` (lucide-react)
- Função auxiliar: `getStatusColor()`, `getStatusIcon()`, `getStatusExibicao()` (extrair de ProcessandoPedido)

**Tempo Estimado**: 2 horas

**Código Base** (copiar de ProcessandoPedido.tsx linhas 330-380):
```tsx
// src/components/StatusTimeline.tsx
import { Package, ChefHat, CheckCircle, Truck, Clock } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import type { HistoricoPedidoSupabase, PedidoSupabase } from "@/services"

interface StatusTimelineProps {
  historico: HistoricoPedidoSupabase[]
  atualizandoRealtime?: boolean
  ultimaAtualizacao?: Date
  pedido?: PedidoSupabase
}

export default function StatusTimeline({
  historico,
  atualizandoRealtime = false,
  ultimaAtualizacao = new Date(),
  pedido
}: StatusTimelineProps) {
  // ... implementação
}
```

---

## Task 2: Extrair Funções Auxiliares para Formatar Status

**Objetivo**: Reutilizar as funções `getStatusColor()`, `getStatusIcon()`, `getStatusExibicao()` criando um utils file.

**Descrição**:
Criar arquivo `src/utils/statusFormatacao.ts` com funções de formatação de status, para que possam ser usadas em ProcessandoPedido e StatusTimeline.

**Acceptance Criteria**:
- [ ] Arquivo criado em `src/utils/statusFormatacao.ts`
- [ ] Função `getStatusColor(status: string): string` exportada
  - [ ] Retorna classe Tailwind do tipo "bg-indigo-500"
  - [ ] Considera tipo de pedido para "Liberado" (delivery vs retirada)
- [ ] Função `getStatusIcon(status: string): JSX.Element` exportada
  - [ ] Retorna ícone correto
  - [ ] Usa lucide-react icons
- [ ] Função `getStatusExibicao(status: string, entregaDomicilio?: boolean): string` exportada
  - [ ] Converte "Liberado" → "Saiu para entrega" ou "Pronto para retirada"
  - [ ] Converte "Finalizado" → "Entregue" ou "Retirado"
- [ ] Função `formatarHora(dataISO: string): string` exportada
  - [ ] Formata hora em "HH:mm"
- [ ] Teste: funções retornam valores corretos

**Tempo Estimado**: 1 hora

---

## Task 3: Integrar StatusTimeline em ProcessandoPedido

**Objetivo**: Substituir a seção "Acompanhe seu Pedido" (Card com renderização inline) pelo novo componente.

**Descrição**:
Modificar `src/pages/ProcessandoPedido.tsx` para usar o novo `StatusTimeline` component no lugar do código inline de renderização.

**Arquivo**: `src/pages/ProcessandoPedido.tsx`

**Mudanças**:
- [ ] Importar `StatusTimeline` no topo do arquivo
- [ ] Remover função `getStatusColor()` e substituir pelo import de utils
- [ ] Remover função `getStatusIcon()` e substituir pelo import de utils
- [ ] Remover função `getStatusExibicao()` (será do utils ou do componente)
- [ ] Remover função `formatarHora()` e substituir pelo import de utils
- [ ] Localizar Card de "Acompanhe seu Pedido" (linha ~330)
- [ ] Substituir por: `<StatusTimeline historico={historico} atualizandoRealtime={atualizandoRealtime} ultimaAtualizacao={ultimaAtualizacao} pedido={pedido} />`
- [ ] Testar: página carrega, timeline aparece, atualiza em tempo real

**Antes** (linhas 330-380 aproximadamente):
```tsx
<Card>
  <CardHeader>
    <div className="flex items-center justify-between">
      <CardTitle className="flex items-center gap-2">
        <Package className="h-5 w-5 text-red-600" />
        Acompanhe seu Pedido
      </CardTitle>
      <div className="flex items-center gap-2 text-xs text-gray-500">
        <div className={`w-2 h-2 rounded-full ${atualizandoRealtime ? 'bg-indigo-500 animate-pulse' : 'bg-green-500'}`}></div>
        <span>Atualizado {ultimaAtualizacao.toLocaleTimeString(...)}</span>
      </div>
    </div>
  </CardHeader>
  <CardContent>
    {/* ... renderização do histórico */}
  </CardContent>
</Card>
```

**Depois** (uma linha):
```tsx
<StatusTimeline 
  historico={historico} 
  atualizandoRealtime={atualizandoRealtime} 
  ultimaAtualizacao={ultimaAtualizacao} 
  pedido={pedido} 
/>
```

**Tempo Estimado**: 1.5 horas

---

## Task 4: Testes Unitários do StatusTimeline

**Objetivo**: Validar que o componente renderiza corretamente em diferentes cenários.

**Descrição**:
Criar testes para o novo componente `StatusTimeline` cobrindo:
- Renderização com dados válidos
- Estados de atualização em tempo real
- Diferentes statuses
- Histórico vazio

**Arquivo**: `src/components/__tests__/StatusTimeline.test.tsx`

**Acceptance Criteria**:
- [ ] Teste: renderiza com histórico vazio
- [ ] Teste: renderiza com um item no histórico
- [ ] Teste: renderiza com múltiplos itens
- [ ] Teste: exibe ícone correto para cada status
- [ ] Teste: exibe cor correta para cada status
- [ ] Teste: indicador de atualização pisca quando `atualizandoRealtime === true`
- [ ] Teste: exibe timestamp correto
- [ ] Teste: converte "Liberado" para "Saiu para entrega" quando delivery
- [ ] Coverage > 80%

**Framework**: Vitest + React Testing Library (padrão do projeto)

**Tempo Estimado**: 2 horas

---

## Task 5: Testes Visuais e Fumaça (Smoke Test)

**Objetivo**: Validar funcionamento end-to-end da funcionalidade.

**Descrição**:
Testes manuais para garantir que:
1. Cliente faz checkout e vê timeline na página de confirmação
2. Timeline atualiza em tempo real quando o status muda
3. Comportamento é igual em "Meus Pedidos" (compatibilidade)

**Acceptance Criteria**:
- [ ] Teste 1: Após checkout, página de confirmação exibe timeline com "Pedido criado"
- [ ] Teste 2: Mudar status do pedido no banco (ex: UPDATE pedidos SET status='Preparando'), verificar se timeline atualiza em <2s
- [ ] Teste 3: Verificar cores e ícones aparecem corretamente
- [ ] Teste 4: Abrir "Meus Pedidos" e verificar que está funcionando normalmente
- [ ] Teste 5: Mobile responsivo - timeline aparece bem formatada em smartphone
- [ ] Teste 6: Múltiplos abas abertas - verificar que Realtime funciona em todas

**Steps**:
1. Build: `npm run build`
2. Abrir em dev: `npm run dev`
3. Fazer checkout de um pedido
4. Verificar timeline na confirmação
5. Ir para "Meus Pedidos" → verificar compatibilidade
6. Alterar status manualmente no Supabase → verificar atualização

**Tempo Estimado**: 1.5 hora

---

## Task 6: Build e Verificação Final

**Objetivo**: Garantir que não há erros de compilação ou warnings.

**Descrição**:
Rodar build do projeto e verificar se há erros.

**Acceptance Criteria**:
- [ ] Build executa sem erros: `npm run build`
- [ ] Nenhum warning referente aos novos componentes/utils
- [ ] Build size não aumentou significativamente (< 5KB)
- [ ] TypeScript: sem erros de type

**Tempo Estimado**: 30 minutos

---

## Dependency Graph

```
Task 1 (StatusTimeline) 
  ↓
Task 2 (utils) 
  ↓
Task 3 (integração em ProcessandoPedido)
  ↓
Task 4 (testes)
  ↓
Task 5 (smoke tests)
  ↓
Task 6 (build final)
```

---

## Summary

| Task | Descrição | Tempo | Dependências |
|------|-----------|-------|--------------|
| 1 | Criar StatusTimeline | 2h | Nenhuma |
| 2 | Utils de formatação | 1h | Nenhuma |
| 3 | Integrar em ProcessandoPedido | 1.5h | Task 1, 2 |
| 4 | Testes unitários | 2h | Task 1 |
| 5 | Smoke tests manuais | 1.5h | Task 3 |
| 6 | Build final | 0.5h | Task 3, 4, 5 |
| | **TOTAL** | **~8.5h** | |

---

## Notas Importantes

- ✅ **NÃO modificar** `AcompanhamentoPedidos.tsx` (manter compatibilidade)
- ✅ **Manter** o mesmo visual e comportamento
- ✅ **Realtime** já está funcionando em ProcessandoPedido (apenas reorganizar renderização)
- ✅ **Mobile-first**: testar em smartphone
- ✅ **Performance**: componente deve ser leve (<100 lines)

---

## Próximas Melhorias (Future)

Após esta feature ser concluída, considerar:
- Refatorar `AcompanhamentoPedidos` para usar `StatusTimeline` também
- Adicionar animações mais suaves nas transições de status
- Adicionar notificações push quando status muda
- Adicionar foto do estabelecimento em cada status

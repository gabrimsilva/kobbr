# ✅ ETAPA 6 - Impressão Automática no Kanban + Visualização de Cupom

## STATUS: CONCLUÍDA

## Objetivo
Implementar impressão automática quando pedido delivery é criado e adicionar botões de visualizar/imprimir cupom no Kanban de acompanhamento.

---

## Implementações Realizadas

### 1. ✅ Impressão Automática ao Criar Pedido
- **Arquivo**: `src/hooks/useFinalizarPedido.ts`
- **Modificações**:
  - Adicionados imports: `configuracaoService`, `receiptService`, `printJobService`
  - Após salvar pedido e criar histórico:
    - Busca configuração `impressao_automatica_pedidos`
    - Se ativa, gera cupom do pedido com `receiptService.generateOrderReceipt()`
    - Cria print job com `printJobService.create()`
    - Tenta imprimir automaticamente com `printJobService.print()`
    - Se falhar, apenas loga aviso (não quebra criação do pedido)

### 2. ✅ Botões de Visualizar e Imprimir no Kanban
- **Arquivo**: `src/pages/AcompanhamentoPedidos.tsx`
- **Modificações**:
  - Adicionados imports: `Eye`, `Printer`, `VisualizarCupomModal`, `printJobService`, `toast`
  - Novos estados:
    - `cupomModalAberto` - Controla modal de visualização
    - `pedidoSelecionado` - Pedido sendo visualizado
    - `imprimindo` - ID do pedido sendo impresso (loading)
  - Nova função `handleVisualizarCupom()`:
    - Abre modal com cupom do pedido
  - Nova função `handleImprimirCupom()`:
    - Chama `printJobService.print()`
    - Mostra toast de sucesso/erro
    - Gerencia estado de loading
  - Adicionados botões na coluna 4 (Data e Hora):
    - Botão "Ver Cupom" com ícone de olho
    - Botão "Imprimir" com ícone de impressora
  - Modal `VisualizarCupomModal` renderizado no final

---

## Como Funciona

### Fluxo de Impressão Automática (Criação de Pedido)

1. **Cliente finaliza pedido no site delivery**
2. Hook `useFinalizarPedido` salva pedido no banco
3. Após salvar com sucesso:
   - Busca configuração `impressao_automatica_pedidos`
   - Se ativa:
     - Gera HTML do cupom
     - Cria print job
     - Tenta imprimir via QZ Tray ou navegador
4. Se impressão falhar, pedido continua normalmente (não bloqueia)

### Fluxo de Visualização/Impressão Manual (Kanban)

1. **Usuário acessa Acompanhamento de Pedidos**
2. Vê lista de pedidos com filtros
3. Em cada card de pedido:
   - Botão "Ver Cupom":
     - Abre modal com prévia do cupom
     - Permite imprimir ou baixar PDF
   - Botão "Imprimir":
     - Imprime diretamente (QZ Tray ou navegador)
     - Mostra feedback de sucesso/erro

---

## Arquivos Modificados

### 1. `src/hooks/useFinalizarPedido.ts`
**Imports adicionados:**
```typescript
import { configuracaoService } from '@/services'
import { receiptService } from '@/services/receiptService'
import { printJobService } from '@/services/printJobService'
```

**Código adicionado após criar histórico:**
```typescript
// IMPRESSÃO AUTOMÁTICA DO PEDIDO (se configurado)
try {
  const configImpressaoAuto = await configuracaoService.buscarPorChave('impressao_automatica_pedidos')
  const impressaoAutomaticaAtiva = configImpressaoAuto?.valor === 'true'

  if (impressaoAutomaticaAtiva) {
    const cupomHTML = await receiptService.generateOrderReceipt(pedidoSalvo.id)
    await printJobService.create({
      refType: 'ORDER',
      refId: pedidoSalvo.id,
      receiptHtml: cupomHTML
    })
    await printJobService.print(pedidoSalvo.id, 'ORDER')
  }
} catch (errorImpressao) {
  console.warn('Aviso: Falha na impressão automática do pedido, mas pedido foi criado com sucesso:', errorImpressao)
}
```

### 2. `src/pages/AcompanhamentoPedidos.tsx`
**Imports adicionados:**
```typescript
import { Eye, Printer } from "lucide-react"
import { printJobService } from "@/services/printJobService"
import { VisualizarCupomModal } from "@/components/VisualizarCupomModal"
import toast from "react-hot-toast"
```

**Estados adicionados:**
```typescript
const [cupomModalAberto, setCupomModalAberto] = useState(false)
const [pedidoSelecionado, setPedidoSelecionado] = useState<PedidoSupabase | null>(null)
const [imprimindo, setImprimindo] = useState<string | null>(null)
```

**Funções adicionadas:**
```typescript
const handleVisualizarCupom = (pedido: PedidoSupabase) => {
  setPedidoSelecionado(pedido)
  setCupomModalAberto(true)
}

const handleImprimirCupom = async (pedido: PedidoSupabase) => {
  try {
    setImprimindo(pedido.id)
    const resultado = await printJobService.print(pedido.id, 'ORDER')
    
    if (resultado.success) {
      if (resultado.method === 'qz') {
        toast.success('Cupom enviado para impressora!')
      } else {
        toast.success('Abrindo janela de impressão...')
      }
    } else {
      toast.error(resultado.error || 'Erro ao imprimir cupom')
    }
  } catch (error) {
    toast.error('Erro ao imprimir cupom')
  } finally {
    setImprimindo(null)
  }
}
```

**Botões adicionados no card:**
```tsx
<div className="flex gap-2 mt-3">
  <Button
    variant="outline"
    size="sm"
    onClick={() => handleVisualizarCupom(pedido)}
    className="flex items-center gap-1"
  >
    <Eye className="h-4 w-4" />
    Ver Cupom
  </Button>
  <Button
    variant="outline"
    size="sm"
    onClick={() => handleImprimirCupom(pedido)}
    disabled={imprimindo === pedido.id}
    className="flex items-center gap-1"
  >
    <Printer className="h-4 w-4" />
    {imprimindo === pedido.id ? 'Imprimindo...' : 'Imprimir'}
  </Button>
</div>
```

**Modal adicionado:**
```tsx
{pedidoSelecionado && (
  <VisualizarCupomModal
    open={cupomModalAberto}
    onClose={() => {
      setCupomModalAberto(false)
      setPedidoSelecionado(null)
    }}
    refType="ORDER"
    refId={pedidoSelecionado.id}
  />
)}
```

---

## Configuração

### Para ativar impressão automática de pedidos:
1. Ir em **Configurações → Impressora**
2. Ativar toggle **"Impressão Automática de Pedidos"**
3. (Opcional) Configurar QZ Tray para impressão silenciosa
4. Salvar configurações

### Comportamento:
- **Com QZ Tray**: Imprime automaticamente na impressora configurada
- **Sem QZ Tray**: Abre janela de impressão do navegador
- **Se falhar**: Pedido é criado normalmente, apenas loga aviso

---

## Testes Realizados

### ✅ Impressão Automática
- [x] Pedido criado com impressão automática ativa → Imprime
- [x] Pedido criado com impressão automática desativa → Não imprime
- [x] Falha na impressão → Pedido criado normalmente
- [x] QZ Tray configurado → Impressão silenciosa
- [x] QZ Tray não configurado → Janela de impressão

### ✅ Botões no Kanban
- [x] Botão "Ver Cupom" abre modal com prévia
- [x] Botão "Imprimir" imprime cupom
- [x] Loading durante impressão
- [x] Toast de sucesso/erro
- [x] Modal fecha corretamente

---

## Diferenças entre PDV e Delivery

| Aspecto | PDV | Delivery |
|---------|-----|----------|
| **Momento da impressão** | Ao finalizar venda | Ao criar pedido |
| **Configuração** | `impressao_automatica_pdv` | `impressao_automatica_pedidos` |
| **Tipo de cupom** | Cupom fiscal (venda) | Cupom de pedido |
| **Ref Type** | `SALE` | `ORDER` |
| **Hook** | `useFinalizarVendaPDV` | `useFinalizarPedido` |
| **Visualização** | Histórico de Vendas | Acompanhamento de Pedidos |

---

## Próximos Passos

### ETAPA 7 - Organizar Menu de Configurações
- Reorganizar submenus por grupos lógicos
- Criar seções: Loja, Aparência, Impressora, Delivery, Pagamentos
- Remover termos antigos do sistema
- Melhorar navegação entre seções

### ETAPA 8 - Ajustes Finais de Tema Cosméticos
- Aplicar paleta rosa/nude/lilás consistente em todo sistema
- Remover últimas referências a "comanda/pizza/sabor"
- Ajustar iconografia e bordas para tema feminino
- Revisar textos e labels

---

## Observações Importantes

1. **Impressão não bloqueia pedido**: Se falhar, pedido é criado normalmente
2. **Configuração independente**: PDV e Delivery têm toggles separados
3. **Cupom salvo no banco**: HTML é salvo em `receipt_html` para reimpressões
4. **Fallback automático**: Se QZ Tray falhar, usa impressão do navegador
5. **Feedback visual**: Toasts informam sucesso/erro da impressão

---

## Conclusão

A ETAPA 6 está completa. O sistema agora possui:
- ✅ Impressão automática ao criar pedido delivery (opcional)
- ✅ Botões de visualizar e imprimir cupom no Kanban
- ✅ Modal de visualização de cupom
- ✅ Feedback visual com toasts
- ✅ Loading durante impressão
- ✅ Integração completa com QZ Tray

O fluxo de pedidos delivery está completo, desde a criação até a impressão automática.

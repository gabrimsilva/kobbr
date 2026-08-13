# 🔴 DangerButton Component

Componente de botão especializado para ações destrutivas e perigosas no sistema.

## 📦 Localização

```
src/components/ui/danger-button.tsx
```

## 🎯 Propósito

O `DangerButton` é um wrapper do componente `Button` que fornece:
- Estilo visual consistente para ações destrutivas
- Loading state automático com spinner
- Semântica clara no código
- Manutenção centralizada

## 🚀 Uso Básico

```tsx
import { DangerButton } from "@/components/ui/danger-button"

// Exemplo simples
<DangerButton onClick={handleDelete}>
  Excluir
</DangerButton>

// Com loading state
<DangerButton loading={isDeleting} onClick={handleDelete}>
  Excluir
</DangerButton>

// Com ícone
<DangerButton onClick={handleClear}>
  <Trash2 className="h-4 w-4 mr-2" />
  Limpar
</DangerButton>
```

## 📋 Props

Herda todas as props do componente `Button`, mais:

| Prop | Tipo | Padrão | Descrição |
|------|------|--------|-----------|
| `loading` | `boolean` | `false` | Mostra spinner e desabilita o botão |
| `variant` | `string` | `"destructive"` | Variante visual do botão |
| `size` | `string` | `"default"` | Tamanho do botão |
| `disabled` | `boolean` | `false` | Desabilita o botão |
| `className` | `string` | - | Classes CSS adicionais |
| `asChild` | `boolean` | `false` | Renderiza como componente filho |

## 🎨 Variantes

### Destructive (padrão)
Fundo vermelho sólido - para ações críticas e irreversíveis.

```tsx
<DangerButton>Excluir Tudo</DangerButton>
<DangerButton variant="destructive">Cancelar Pedido</DangerButton>
```

### Outline
Borda vermelha - para ações destrutivas menos críticas.

```tsx
<DangerButton variant="outline">
  <X className="h-4 w-4 mr-2" />
  Limpar Filtros
</DangerButton>
```

### Ghost
Transparente com hover vermelho - para ações discretas.

```tsx
<DangerButton variant="ghost" size="sm">
  <Trash2 className="h-4 w-4" />
</DangerButton>
```

## 📏 Tamanhos

```tsx
// Small
<DangerButton size="sm">Excluir</DangerButton>

// Default
<DangerButton>Excluir</DangerButton>

// Large
<DangerButton size="lg">Excluir</DangerButton>

// Icon only
<DangerButton size="icon">
  <Trash2 className="h-4 w-4" />
</DangerButton>
```

## ⚡ Loading State

O loading state é automático e não requer código adicional:

```tsx
// ❌ Antes (código manual)
<Button
  variant="destructive"
  disabled={isDeleting}
  onClick={handleDelete}
>
  {isDeleting && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
  Excluir
</Button>

// ✅ Depois (automático)
<DangerButton
  loading={isDeleting}
  onClick={handleDelete}
>
  Excluir
</DangerButton>
```

## 🎯 Quando Usar

### ✅ Use DangerButton para:

1. **Ações Destrutivas sem Confirmação**
   ```tsx
   <DangerButton onClick={limparCarrinho}>
     Limpar Carrinho
   </DangerButton>
   ```

2. **Botões de Confirmação em Dialogs Destrutivos**
   ```tsx
   <AlertDialog>
     <AlertDialogContent>
       <AlertDialogTitle>Confirmar Exclusão?</AlertDialogTitle>
       <AlertDialogFooter>
         <AlertDialogCancel>Cancelar</AlertDialogCancel>
         <DangerButton onClick={confirmarExclusao}>
           Confirmar
         </DangerButton>
       </AlertDialogFooter>
     </AlertDialogContent>
   </AlertDialog>
   ```

3. **Ações que Descartam Trabalho do Usuário**
   ```tsx
   <DangerButton variant="outline" onClick={limparFiltros}>
     <X className="h-4 w-4 mr-2" />
     Limpar Filtros
   </DangerButton>
   ```

4. **Operações Irreversíveis**
   ```tsx
   <DangerButton loading={zerando} onClick={zerarPedidos}>
     <History className="h-4 w-4 mr-2" />
     Zerar Pedidos
   </DangerButton>
   ```

### ❌ NÃO use DangerButton para:

1. **Ações com ConfirmDeleteDialog**
   - Já estão protegidas por confirmação
   - Use Button normal

2. **Navegação entre Páginas**
   - Não é uma ação destrutiva
   - Use Button ou Link

3. **Fechar Modais**
   - Ação reversível
   - Use Button variant="outline"

4. **Cancelar Formulários**
   - Use Button variant="outline" ou SecondaryButton
   - Não é tecnicamente "perigoso"

## 📚 Exemplos Reais

### 1. Zerar Pedidos (Kanban)
```tsx
<DangerButton
  size="sm"
  onClick={onZerarPedidos}
  loading={carregando}
  disabled={totalPedidos === 0}
>
  <History className="h-4 w-4 mr-2" />
  Zerar Pedidos
</DangerButton>
```

### 2. Limpar Carrinho (PDV)
```tsx
<DangerButton
  variant="ghost"
  size="sm"
  onClick={onLimparCarrinho}
>
  <Trash2 className="h-4 w-4" />
</DangerButton>
```

### 3. Cancelar Pedido (Dialog)
```tsx
<DangerButton
  onClick={handleConfirmarCancelamento}
  loading={processando}
>
  Confirmar Cancelamento
</DangerButton>
```

### 4. Limpar Imagens Órfãs
```tsx
<DangerButton
  variant="outline"
  onClick={handleLimparImagensOrfas}
  loading={limpandoImagens}
  className="text-orange-600 border-orange-200 hover:bg-orange-50"
>
  <Trash2 className="h-4 w-4 mr-2" />
  Limpar Imagens Órfãs
</DangerButton>
```

### 5. Limpar Chat IA
```tsx
<DangerButton
  variant="outline"
  size="sm"
  onClick={limparChat}
  loading={enviando}
>
  <Trash2 className="h-4 w-4 mr-2" />
  Limpar
</DangerButton>
```

## 🔄 Migração

### De Button para DangerButton

```tsx
// ❌ Antes
<Button
  variant="destructive"
  onClick={handleDelete}
  disabled={loading}
  className="bg-red-600 hover:bg-red-700"
>
  {loading ? (
    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
  ) : (
    <Trash2 className="h-4 w-4 mr-2" />
  )}
  Excluir
</Button>

// ✅ Depois
<DangerButton
  onClick={handleDelete}
  loading={loading}
>
  <Trash2 className="h-4 w-4 mr-2" />
  Excluir
</DangerButton>
```

### De AlertDialogAction para DangerButton

```tsx
// ❌ Antes
<AlertDialogAction 
  onClick={handleConfirm}
  className="bg-red-600 hover:bg-red-700"
>
  Confirmar
</AlertDialogAction>

// ✅ Depois
<DangerButton onClick={handleConfirm}>
  Confirmar
</DangerButton>
```

## 🧪 Testes

```tsx
import { render, screen } from '@testing-library/react'
import { DangerButton } from './danger-button'
import userEvent from '@testing-library/user-event'

test('renderiza e responde a cliques', async () => {
  const handleClick = vi.fn()
  const user = userEvent.setup()
  
  render(<DangerButton onClick={handleClick}>Excluir</DangerButton>)
  
  const button = screen.getByRole('button', { name: /excluir/i })
  await user.click(button)
  
  expect(handleClick).toHaveBeenCalledTimes(1)
})

test('mostra loading state', () => {
  render(<DangerButton loading>Excluindo...</DangerButton>)
  
  const button = screen.getByRole('button')
  expect(button).toBeDisabled()
  expect(document.querySelector('.animate-spin')).toBeInTheDocument()
})
```

## 🎨 Customização

```tsx
// Classes CSS customizadas
<DangerButton className="w-full">
  Excluir Tudo
</DangerButton>

// Estilos inline (evite se possível)
<DangerButton style={{ minWidth: '200px' }}>
  Excluir
</DangerButton>

// Combinando com outras props
<DangerButton
  variant="outline"
  size="sm"
  loading={isDeleting}
  className="text-orange-600 border-orange-200"
>
  <Trash2 className="h-4 w-4 mr-2" />
  Limpar
</DangerButton>
```

## 🔗 Componentes Relacionados

- `ActionButton` - Para ações positivas/primárias
- `Button` - Componente base
- `ConfirmDeleteDialog` - Para exclusões com confirmação

## 📖 Referências

- [Análise Completa](../../../ANALISE_DANGERBUTTON.md)
- [Guia de Implementação](../../../IMPLEMENTACAO_DANGERBUTTON.md)
- [Testes](`./__tests__/danger-button.test.tsx`)
- [Storybook](./danger-button.stories.tsx)

---

**Criado em:** 19/01/2025  
**Versão:** 1.0

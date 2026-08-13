# 🎨 Design System - Sistema de Delivery

> Documentação completa do Design System utilizado no sistema de delivery e gestão de pedidos.

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Fundamentos](#-fundamentos)
3. [Componentes](#-componentes)
4. [Padrões de Uso](#-padrões-de-uso)
5. [Customização](#-customização)

---

## 🎯 Visão Geral

Este Design System é baseado no **shadcn/ui** com estilo **New York**, utilizando:

- **Framework CSS**: Tailwind CSS v4
- **Biblioteca de Ícones**: Lucide React
- **Fonte**: Poppins (Google Fonts)
- **Tema Base**: Neutral
- **Variáveis CSS**: Habilitadas (CSS Variables)
- **Animações**: tw-animate-css

---

## 🎨 Fundamentos

### Paleta de Cores

#### Modo Claro (Light Mode)

```css
/* Cores Base */
--background: oklch(1 0 0)              /* Branco puro */
--foreground: oklch(0.145 0 0)          /* Preto escuro */
--card: oklch(1 0 0)                    /* Branco */
--card-foreground: oklch(0.145 0 0)     /* Preto escuro */

/* Cores Primárias (Admin) */
--primary: oklch(0.15 0.05 250)         /* Slate 900 - Botões principais */
--primary-foreground: oklch(0.985 0 0)  /* Branco */

/* Cores Secundárias */
--secondary: oklch(0.97 0 0)            /* Cinza claro */
--secondary-foreground: oklch(61.647% 0.25062 29.013) /* Preto */

/* Cores Destrutivas */
--destructive: oklch(0.577 0.245 27.325) /* Vermelho */

/* Bordas e Inputs */
--border: oklch(0.922 0 0)              /* Cinza claro */
--input: oklch(0.922 0 0)               /* Cinza claro */
--ring: oklch(0.708 0 0)                /* Cinza médio */
```

#### Modo Escuro (Dark Mode)

```css
/* Cores Base */
--background: oklch(0.145 0 0)          /* Preto escuro */
--foreground: oklch(0.985 0 0)          /* Branco */
--card: oklch(0.205 0 0)                /* Cinza escuro */
--card-foreground: oklch(0.985 0 0)     /* Branco */

/* Cores Primárias */
--primary: oklch(0.922 0 0)             /* Cinza claro */
--primary-foreground: oklch(0.205 0 0)  /* Cinza escuro */

/* Cores Destrutivas */
--destructive: oklch(0.704 0.191 22.216) /* Vermelho claro */
```

### Cores Semânticas Customizadas

#### Admin (Sistema Administrativo)

```css
/* Botões */
--admin-btn-primary-bg: var(--primary)
--admin-btn-primary-fg: var(--primary-foreground)
--admin-btn-destructive-bg: var(--destructive)

/* Sidebar */
--admin-sidebar-bg: oklch(0.15 0.05 250)           /* Slate 900 */
--admin-sidebar-text: oklch(0.8 0 0)               /* Cinza claro */
--admin-sidebar-active-bg: oklch(58.499% 0.22793 259.311) /* Azul */
--admin-sidebar-hover-bg: oklch(58.499% 0.22793 259.311)  /* Azul */
--admin-sidebar-border: oklch(0.15 0.05 250)       /* Slate 900 */
```

#### Preços

```css
/* Admin */
--price-color: oklch(0.15 0.05 250)                /* Slate 900 */

/* Cliente/Delivery */
--price-color-cliente: oklch(61.647% 0.25062 29.013) /* Preto */
```

### Cores de Gráficos (Charts)

```css
--chart-1: oklch(0.646 0.222 41.116)   /* Laranja */
--chart-2: oklch(0.6 0.118 184.704)    /* Ciano */
--chart-3: oklch(0.398 0.07 227.392)   /* Azul escuro */
--chart-4: oklch(0.828 0.189 84.429)   /* Amarelo */
--chart-5: oklch(0.769 0.188 70.08)    /* Amarelo claro */
```

### Tipografia

```css
/* Fonte Principal */
font-family: 'Poppins', sans-serif;

/* Tamanhos de Texto (Tailwind) */
text-xs    /* 0.75rem - 12px */
text-sm    /* 0.875rem - 14px */
text-base  /* 1rem - 16px */
text-lg    /* 1.125rem - 18px */
text-xl    /* 1.25rem - 20px */
text-2xl   /* 1.5rem - 24px */
```

### Espaçamento e Border Radius

```css
/* Border Radius */
--radius: 0.625rem                     /* 10px - Base */
--radius-sm: calc(var(--radius) - 4px) /* 6px */
--radius-md: calc(var(--radius) - 2px) /* 8px */
--radius-lg: var(--radius)             /* 10px */
--radius-xl: calc(var(--radius) + 4px) /* 14px */
```

### Sombras

```css
/* Sombras Padrão (Tailwind) */
shadow-xs  /* Sombra extra pequena */
shadow-sm  /* Sombra pequena */
shadow     /* Sombra média */
shadow-md  /* Sombra média-grande */
shadow-lg  /* Sombra grande */
shadow-xl  /* Sombra extra grande */
```

---

## 🧩 Componentes

### Componentes shadcn/ui (22 componentes)

#### 1. Alert Dialog
**Uso**: Diálogos de confirmação e alertas críticos

```tsx
import { AlertDialog, AlertDialogAction, AlertDialogCancel } from "@/components/ui/alert-dialog"

<AlertDialog>
  <AlertDialogTrigger>Excluir</AlertDialogTrigger>
  <AlertDialogContent>
    <AlertDialogTitle>Confirmar exclusão?</AlertDialogTitle>
    <AlertDialogDescription>Esta ação não pode ser desfeita.</AlertDialogDescription>
    <AlertDialogFooter>
      <AlertDialogCancel>Cancelar</AlertDialogCancel>
      <AlertDialogAction>Confirmar</AlertDialogAction>
    </AlertDialogFooter>
  </AlertDialogContent>
</AlertDialog>
```

#### 2. Badge
**Uso**: Status, categorias, tags

**Variantes**: `default`, `secondary`, `destructive`, `outline`

```tsx
import { Badge } from "@/components/ui/badge"

<Badge variant="default">Ativo</Badge>
<Badge variant="destructive">Cancelado</Badge>
<Badge variant="outline">Pendente</Badge>
```

#### 3. Button
**Uso**: Ações primárias e secundárias

**Variantes**: `default`, `destructive`, `outline`, `secondary`, `ghost`, `link`

**Tamanhos**: `default`, `sm`, `lg`, `icon`

```tsx
import { Button } from "@/components/ui/button"

<Button variant="default">Salvar</Button>
<Button variant="destructive">Excluir</Button>
<Button variant="outline" size="sm">Editar</Button>
<Button variant="ghost" size="icon"><Icon /></Button>
```

#### 4. Calendar
**Uso**: Seleção de datas

```tsx
import { Calendar } from "@/components/ui/calendar"

<Calendar
  mode="single"
  selected={date}
  onSelect={setDate}
/>
```

#### 5. Card
**Uso**: Containers de conteúdo

```tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card"

<Card>
  <CardHeader>
    <CardTitle>Título</CardTitle>
    <CardDescription>Descrição</CardDescription>
  </CardHeader>
  <CardContent>Conteúdo</CardContent>
  <CardFooter>Rodapé</CardFooter>
</Card>
```

#### 6. Chart
**Uso**: Gráficos e visualizações de dados

```tsx
import { ChartContainer, ChartTooltip } from "@/components/ui/chart"
```

#### 7. Checkbox
**Uso**: Seleção múltipla

```tsx
import { Checkbox } from "@/components/ui/checkbox"

<Checkbox checked={checked} onCheckedChange={setChecked} />
```

#### 8. Dialog
**Uso**: Modais e diálogos

```tsx
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"

<Dialog open={open} onOpenChange={setOpen}>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Título</DialogTitle>
    </DialogHeader>
    {/* Conteúdo */}
  </DialogContent>
</Dialog>
```

#### 9. Input
**Uso**: Campos de entrada de texto

```tsx
import { Input } from "@/components/ui/input"

<Input type="text" placeholder="Digite aqui..." />
<Input type="email" placeholder="email@exemplo.com" />
<Input type="number" placeholder="0" />
```

#### 10. Label
**Uso**: Rótulos de formulários

```tsx
import { Label } from "@/components/ui/label"

<Label htmlFor="nome">Nome</Label>
<Input id="nome" />
```

#### 11. Popover
**Uso**: Menus contextuais e tooltips interativos

```tsx
import { Popover, PopoverTrigger, PopoverContent } from "@/components/ui/popover"

<Popover>
  <PopoverTrigger>Abrir</PopoverTrigger>
  <PopoverContent>Conteúdo</PopoverContent>
</Popover>
```

#### 12. Scroll Area
**Uso**: Áreas de rolagem customizadas

```tsx
import { ScrollArea } from "@/components/ui/scroll-area"

<ScrollArea className="h-[400px]">
  {/* Conteúdo longo */}
</ScrollArea>
```

#### 13. Select
**Uso**: Seleção de opções (dropdown)

```tsx
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from "@/components/ui/select"

<Select value={value} onValueChange={setValue}>
  <SelectTrigger>
    <SelectValue placeholder="Selecione..." />
  </SelectTrigger>
  <SelectContent>
    <SelectItem value="1">Opção 1</SelectItem>
    <SelectItem value="2">Opção 2</SelectItem>
  </SelectContent>
</Select>
```

#### 14. Separator
**Uso**: Divisores visuais

```tsx
import { Separator } from "@/components/ui/separator"

<Separator />
<Separator orientation="vertical" />
```

#### 15. Sheet
**Uso**: Painéis laterais deslizantes (mobile menu, carrinho)

```tsx
import { Sheet, SheetTrigger, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet"

<Sheet>
  <SheetTrigger>Abrir</SheetTrigger>
  <SheetContent side="right">
    <SheetHeader>
      <SheetTitle>Título</SheetTitle>
    </SheetHeader>
    {/* Conteúdo */}
  </SheetContent>
</Sheet>
```

#### 16. Sidebar
**Uso**: Navegação lateral do admin

```tsx
import { Sidebar, SidebarContent, SidebarGroup, SidebarMenuItem } from "@/components/ui/sidebar"
```

#### 17. Skeleton
**Uso**: Placeholders de carregamento

```tsx
import { Skeleton } from "@/components/ui/skeleton"

<Skeleton className="h-12 w-full" />
<Skeleton className="h-4 w-[250px]" />
```

#### 18. Switch
**Uso**: Toggle on/off

```tsx
import { Switch } from "@/components/ui/switch"

<Switch checked={enabled} onCheckedChange={setEnabled} />
```

#### 19. Table
**Uso**: Tabelas de dados

```tsx
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table"

<Table>
  <TableHeader>
    <TableRow>
      <TableHead>Nome</TableHead>
      <TableHead>Status</TableHead>
    </TableRow>
  </TableHeader>
  <TableBody>
    <TableRow>
      <TableCell>Item 1</TableCell>
      <TableCell>Ativo</TableCell>
    </TableRow>
  </TableBody>
</Table>
```

#### 20. Tabs
**Uso**: Navegação por abas

```tsx
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs"

<Tabs defaultValue="tab1">
  <TabsList>
    <TabsTrigger value="tab1">Aba 1</TabsTrigger>
    <TabsTrigger value="tab2">Aba 2</TabsTrigger>
  </TabsList>
  <TabsContent value="tab1">Conteúdo 1</TabsContent>
  <TabsContent value="tab2">Conteúdo 2</TabsContent>
</Tabs>
```

#### 21. Textarea
**Uso**: Campos de texto multilinha

```tsx
import { Textarea } from "@/components/ui/textarea"

<Textarea placeholder="Digite sua mensagem..." rows={4} />
```

#### 22. Tooltip
**Uso**: Dicas de ferramentas

```tsx
import { Tooltip, TooltipTrigger, TooltipContent, TooltipProvider } from "@/components/ui/tooltip"

<TooltipProvider>
  <Tooltip>
    <TooltipTrigger>Hover aqui</TooltipTrigger>
    <TooltipContent>Dica útil</TooltipContent>
  </Tooltip>
</TooltipProvider>
```

---

### Componentes Customizados (5 componentes)

#### 1. Action Button
**Uso**: Botões de ação com estados específicos

```tsx
import { ActionButton } from "@/components/ui/action-button"

<ActionButton>Ação Rápida</ActionButton>
```

#### 2. Danger Button
**Uso**: Botões para ações destrutivas com confirmação

```tsx
import { DangerButton } from "@/components/ui/danger-button"

<DangerButton onConfirm={handleDelete}>
  Excluir Permanentemente
</DangerButton>
```

**Documentação**: Ver `src/components/ui/DANGER_BUTTON_README.md`

#### 3. Loading Button
**Uso**: Botões com estado de carregamento

```tsx
import { LoadingButton } from "@/components/ui/loading-button"

<LoadingButton loading={isLoading} onClick={handleSubmit}>
  Salvar
</LoadingButton>
```

#### 4. Status Indicator
**Uso**: Indicadores visuais de status

```tsx
import { StatusIndicator } from "@/components/ui/status-indicator"

<StatusIndicator status="online" />
<StatusIndicator status="offline" />
<StatusIndicator status="busy" />
```

#### 5. Stepper
**Uso**: Wizard de múltiplos passos

```tsx
import { Stepper, Step } from "@/components/ui/stepper"

<Stepper currentStep={currentStep}>
  <Step>Passo 1</Step>
  <Step>Passo 2</Step>
  <Step>Passo 3</Step>
</Stepper>
```

---

## 📐 Padrões de Uso

### Layout Responsivo

```tsx
/* Mobile First */
<div className="flex flex-col md:flex-row gap-4">
  <div className="w-full md:w-1/2">Coluna 1</div>
  <div className="w-full md:w-1/2">Coluna 2</div>
</div>

/* Breakpoints Tailwind */
sm: 640px   /* Tablet pequeno */
md: 768px   /* Tablet */
lg: 1024px  /* Desktop */
xl: 1280px  /* Desktop grande */
2xl: 1536px /* Desktop extra grande */
```

### Grid System

```tsx
/* Grid Responsivo */
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
</div>
```

### Formulários

```tsx
<form className="space-y-4">
  <div className="space-y-2">
    <Label htmlFor="nome">Nome</Label>
    <Input id="nome" placeholder="Digite seu nome" />
  </div>
  
  <div className="space-y-2">
    <Label htmlFor="email">E-mail</Label>
    <Input id="email" type="email" placeholder="seu@email.com" />
  </div>
  
  <div className="flex gap-2">
    <Button type="submit">Salvar</Button>
    <Button type="button" variant="outline">Cancelar</Button>
  </div>
</form>
```

### Cards de Produto

```tsx
<Card>
  <CardHeader>
    <img src={produto.imagem} alt={produto.nome} className="rounded-lg" />
  </CardHeader>
  <CardContent>
    <CardTitle>{produto.nome}</CardTitle>
    <CardDescription>{produto.descricao}</CardDescription>
    <p className="text-lg font-bold text-[var(--price-color-cliente)]">
      R$ {produto.preco.toFixed(2)}
    </p>
  </CardContent>
  <CardFooter>
    <Button className="w-full">Adicionar ao Carrinho</Button>
  </CardFooter>
</Card>
```

### Status de Pedidos

```tsx
const statusConfig = {
  pendente: { variant: "outline", label: "Pendente" },
  preparando: { variant: "default", label: "Preparando" },
  pronto: { variant: "secondary", label: "Pronto" },
  entregue: { variant: "default", label: "Entregue" },
  cancelado: { variant: "destructive", label: "Cancelado" }
}

<Badge variant={statusConfig[pedido.status].variant}>
  {statusConfig[pedido.status].label}
</Badge>
```

### Scrollbar Customizada

```tsx
/* Scrollbar padrão do body */
body {
  scrollbar-width: thin;
  scrollbar-color: rgb(203 213 225) rgb(241 245 249);
}

/* Scrollbar da sidebar */
<div className="scrollbar-thin scrollbar-thumb-slate-700 scrollbar-track-slate-900">
  {/* Conteúdo */}
</div>

/* Esconder scrollbar */
<div className="scrollbar-hide">
  {/* Conteúdo */}
</div>
```

### Truncar Texto

```tsx
/* 1 linha */
<p className="line-clamp-1">Texto longo que será truncado...</p>

/* 2 linhas */
<p className="line-clamp-2">Texto longo que será truncado...</p>

/* 3 linhas */
<p className="line-clamp-3">Texto longo que será truncado...</p>
```

---

## 🎨 Customização

### Como Alterar Cores Globalmente

1. **Abra o arquivo**: `src/index.css`

2. **Localize a variável CSS** que deseja alterar:

```css
:root {
  /* Exemplo: Alterar cor primária dos botões admin */
  --primary: oklch(0.15 0.05 250); /* Valor atual: Slate 900 */
}
```

3. **Modifique o valor** usando o formato `oklch()`:

```css
:root {
  /* Novo valor: Azul */
  --primary: oklch(0.488 0.243 264.376);
}
```

### Variáveis Disponíveis para Customização

#### Admin
```css
--admin-btn-primary-bg        /* Botões principais */
--admin-btn-destructive-bg    /* Botões de excluir */
--admin-sidebar-bg            /* Fundo da sidebar */
--admin-sidebar-active-bg     /* Item ativo na sidebar */
--admin-sidebar-hover-bg      /* Hover na sidebar */
```

#### Cliente/Delivery
```css
--price-color-cliente         /* Cor dos preços */
--background                  /* Fundo da página */
--foreground                  /* Cor do texto */
```

### Background Patterns

O sistema suporta padrões de fundo customizados:

```css
/* Pattern Hideout */
body.bg-pattern-hideout {
  background: linear-gradient(45deg, rgba(255, 107, 107, 0.08) 25%, transparent 25%);
}

/* Pattern I Like Food */
body.bg-pattern-i-like-food {
  background-image: url("/patterns/i-like-food.svg");
}
```

**Patterns disponíveis**:
- `hideout.svg`
- `i-like-food.svg`
- `bubbles.svg`
- `overlapping-circles.svg`

### Adicionar Novo Componente shadcn/ui

```bash
# Instalar novo componente
npx shadcn@latest add [nome-do-componente]

# Exemplos:
npx shadcn@latest add dropdown-menu
npx shadcn@latest add toast
npx shadcn@latest add command
```

### Criar Variante Customizada de Botão

```tsx
// Em src/components/ui/button.tsx
const buttonVariants = cva(
  "...",
  {
    variants: {
      variant: {
        // ... variantes existentes
        success: "bg-green-600 text-white hover:bg-green-700",
        warning: "bg-yellow-600 text-white hover:bg-yellow-700",
      },
    },
  }
)

// Uso
<Button variant="success">Confirmar</Button>
<Button variant="warning">Atenção</Button>
```

---

## 📱 Responsividade

### Breakpoints

| Breakpoint | Tamanho | Uso |
|------------|---------|-----|
| `sm` | 640px | Tablet pequeno |
| `md` | 768px | Tablet |
| `lg` | 1024px | Desktop |
| `xl` | 1280px | Desktop grande |
| `2xl` | 1536px | Desktop extra grande |

### Exemplos de Uso

```tsx
/* Ocultar em mobile */
<div className="hidden md:block">Visível apenas em desktop</div>

/* Mostrar apenas em mobile */
<div className="block md:hidden">Visível apenas em mobile</div>

/* Tamanhos responsivos */
<div className="text-sm md:text-base lg:text-lg">Texto responsivo</div>

/* Padding responsivo */
<div className="p-4 md:p-6 lg:p-8">Container</div>

/* Grid responsivo */
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
  {/* Items */}
</div>
```

---

## 🔧 Utilitários

### Classes Utilitárias Customizadas

```css
/* Truncar texto */
.line-clamp-1  /* 1 linha */
.line-clamp-2  /* 2 linhas */
.line-clamp-3  /* 3 linhas */

/* Scrollbar */
.scrollbar-hide  /* Esconder scrollbar */
.scrollbar-thin  /* Scrollbar fina */
```

### Animações

O sistema utiliza `tw-animate-css` para animações:

```tsx
<div className="animate-fade-in">Fade In</div>
<div className="animate-slide-up">Slide Up</div>
<div className="animate-bounce">Bounce</div>
```

---

## 📚 Recursos Adicionais

### Documentação Oficial

- [shadcn/ui](https://ui.shadcn.com/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Radix UI](https://www.radix-ui.com/)
- [Lucide Icons](https://lucide.dev/)

### Arquivos de Referência

- `src/index.css` - Variáveis CSS e estilos globais
- `components.json` - Configuração do shadcn/ui
- `src/components/ui/` - Componentes UI
- `src/lib/utils.ts` - Utilitários (função `cn()`)

---

## 🎯 Boas Práticas

1. **Use variáveis CSS** para cores ao invés de valores hardcoded
2. **Prefira componentes shadcn/ui** antes de criar customizados
3. **Mantenha consistência** nas variantes de componentes
4. **Use classes utilitárias** do Tailwind para espaçamento e layout
5. **Teste responsividade** em todos os breakpoints
6. **Documente** componentes customizados criados
7. **Siga o padrão** de nomenclatura de classes do Tailwind
8. **Use `cn()`** para combinar classes condicionalmente

```tsx
import { cn } from "@/lib/utils"

<div className={cn(
  "base-classes",
  condition && "conditional-classes",
  className
)}>
  {/* Conteúdo */}
</div>
```

---

**Última atualização**: Janeiro 2026  
**Versão do Design System**: 1.0  
**Mantido por**: Equipe de Desenvolvimento

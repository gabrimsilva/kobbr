# 🔧 ETAPA 5 — Adição do Menu "Alertas de Estoque"

## 🎯 PROBLEMA

O usuário não conseguia acessar a página de Alertas de Estoque porque não havia um link no menu lateral.

## ✅ SOLUÇÃO

Adicionado submenu "Alertas de Estoque" dentro do menu "Estoque de Produtos".

---

## 📝 MODIFICAÇÃO

**Arquivo:** `src/components/layout/AppLayout.tsx`

### Antes:
```typescript
{
  title: "Estoque de Produtos",
  icon: Warehouse,
  id: "estoque-produtos",
  submenu: [
    {
      title: "Histórico de Movimentações",
      icon: History,
      id: "historico-movimentacoes"
    }
  ]
}
```

### Depois:
```typescript
{
  title: "Estoque de Produtos",
  icon: Warehouse,
  id: "estoque-produtos",
  submenu: [
    {
      title: "Alertas de Estoque",  // NOVO
      icon: Bell,                    // NOVO
      id: "alertas-estoque"          // NOVO
    },
    {
      title: "Histórico de Movimentações",
      icon: History,
      id: "historico-movimentacoes"
    }
  ]
}
```

### Permissões:
```typescript
if (item.id === 'estoque-produtos') {
  if (subitem.id === 'alertas-estoque') {
    return permissoes.podeAcessarEstoque  // Mesma permissão do Estoque
  }
  if (subitem.id === 'historico-movimentacoes') {
    return permissoes.podeAcessarEstoque
  }
}
```

---

## 🎨 VISUAL NO MENU

```
📦 Estoque de Produtos  ▼
   🔔 Alertas de Estoque        ← NOVO
   📜 Histórico de Movimentações
```

---

## 🧪 COMO TESTAR

1. **Recarregar a página** (F5 ou Ctrl+R)
2. **Clicar em "Estoque de Produtos"** no menu lateral
3. **Verificar submenu expandido** com 2 opções:
   - 🔔 Alertas de Estoque (NOVO)
   - 📜 Histórico de Movimentações
4. **Clicar em "Alertas de Estoque"**
5. **Verificar navegação** para `/sistema/alertas-estoque`
6. **Verificar página carregada** com:
   - Card de resumo (Críticos, Atenção, Total)
   - Lista de produtos com alertas
   - Botão "🛒 Solicitar Reposição"

---

## ✅ VALIDAÇÕES

- [x] Submenu adicionado
- [x] Ícone Bell configurado
- [x] Permissão vinculada ao estoque
- [x] Rota configurada corretamente
- [x] Sem erros de TypeScript

---

**Status:** ✅ COMPLETO  
**Tempo:** 5 minutos  
**Impacto:** Acesso facilitado aos Alertas de Estoque

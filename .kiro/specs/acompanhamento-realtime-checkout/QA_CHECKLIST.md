# QA Checklist - StatusTimeline Smoke Tests

## Objetivo
Validar funcionalidade end-to-end do acompanhamento em tempo real na página de confirmação de pedido.

---

## Pre-requisitos
- [ ] npm run dev está rodando (ou build disponível)
- [ ] Browser aberto (Chrome/Firefox/Safari)
- [ ] Acesso ao Supabase Studio para atualizar status
- [ ] Pelo menos 1 pedido pronto para testar

---

## Testes de Funcionalidade

### Test 1: Timeline Renderiza Após Checkout
**Steps**:
1. Abrir aplicação em dev mode
2. Navegar até página de delivery/cardápio
3. Adicionar produtos ao carrinho
4. Fazer checkout completo
5. Verificar página de confirmação (ProcessandoPedido)

**Expected Result**:
- [ ] Timeline "Acompanhe seu Pedido" aparece abaixo do card verde de confirmação
- [ ] Primeira entrada de status mostra "Pedido criado"
- [ ] Hora está formatada em HH:mm
- [ ] Indicador de realtime (ponto verde) está presente
- [ ] Texto "Atualizado XX:XX" aparece ao lado do indicador

**Status**: ⬜ Not Tested

---

### Test 2: Timeline Exibe Histórico Correto
**Steps**:
1. Na página de confirmação, observar a timeline
2. Verificar se todos os statuses aparecem em ordem cronológica (mais recente no final)

**Expected Result**:
- [ ] Cada status em história é exibido
- [ ] Ordem é da mais antiga para mais recente (de cima para baixo)
- [ ] Cores estão corretas:
  - [ ] Criado: Azul (indigo)
  - [ ] Preparando: Laranja
  - [ ] Liberado/Entrega: Roxo
  - [ ] Finalizado: Verde escuro
- [ ] Ícones correspondentes aparecem

**Status**: ⬜ Not Tested

---

### Test 3: Realtime Update - Status Muda Dinâmicamente
**Steps**:
1. Manter página de confirmação aberta
2. Abrir Supabase Studio em outra aba
3. Ir para tabela `historico_pedidos`
4. Encontrar o pedido do teste
5. Adicionar novo registro com status "Preparando"
6. Voltar para página de confirmação e observar

**Expected Result**:
- [ ] Indicador começa a piscar (amarelo com animação)
- [ ] Texto muda para "Atualizando..."
- [ ] Após 1-2 segundos, novo status aparece na timeline
- [ ] Indicador volta a ficar verde
- [ ] Texto volta a "Atualizado XX:XX"
- [ ] Timeline exibe "Preparando" com observação

**Status**: ⬜ Not Tested

---

### Test 4: Conversão de Status - Delivery vs Retirada
**Steps - Delivery**:
1. Criar pedido com "Entrega Domicílio = true"
2. Atualizar status para "Liberado" via Supabase
3. Observar timeline

**Expected Result**:
- [ ] Status exibe "Saiu para entrega" (não "Liberado")
- [ ] Ícone é Truck (caminhão)
- [ ] Cor é Roxo (purple-500)

**Steps - Retirada**:
1. Criar pedido com "Entrega Domicílio = false"
2. Atualizar status para "Liberado" via Supabase
3. Observar timeline

**Expected Result**:
- [ ] Status exibe "Pronto para retirada" (não "Liberado")
- [ ] Ícone é CheckCircle
- [ ] Cor é Verde (green-500)

**Status**: ⬜ Not Tested

---

### Test 5: Múltiplas Atualizações de Status
**Steps**:
1. Manter página aberta
2. Adicionar vários status em sequência (via Supabase):
   - Pedido criado → Preparando → Liberado → Finalizado
3. Observar cada atualização na timeline

**Expected Result**:
- [ ] Cada novo status aparece em tempo real
- [ ] Ordem cronológica mantida
- [ ] Todas as cores e ícones corretos
- [ ] Timeline cresce com cada novo status
- [ ] Performance aceitável (< 2s por atualização)

**Status**: ⬜ Not Tested

---

### Test 6: "Meus Pedidos" Continua Funcionando
**Steps**:
1. Navegar até página "Meus Pedidos"
2. Buscar pelo número de telefone
3. Verificar se timeline de acompanhamento exibe

**Expected Result**:
- [ ] Página carrega sem erros
- [ ] Timeline exibe com mesmo visual que em ProcessandoPedido
- [ ] Comportamento em tempo real funciona igual

**Status**: ⬜ Not Tested

---

## Testes de Responsividade

### Test 7: Mobile - Smartphone
**Device**: iPhone 12 / 375px width

**Steps**:
1. Abrir aplicação em dev tools com mobile view
2. Fazer checkout completo
3. Observar página de confirmação

**Expected Result**:
- [ ] Timeline aparece completamente visível
- [ ] Cards não overflow da tela
- [ ] Texto legível (nenhum truncamento ruim)
- [ ] Ícones visíveis
- [ ] Horários formatados corretamente
- [ ] Scroll vertical funciona se necessário

**Status**: ⬜ Not Tested

---

### Test 8: Tablet - iPad
**Device**: iPad Pro / 768px width

**Steps**:
1. Testar em tablet mode
2. Verificar layout

**Expected Result**:
- [ ] Layout adapta bem
- [ ] 2 colunas se aplicável
- [ ] Cards bem distribuídos
- [ ] Sem elementos sobrepostos

**Status**: ⬜ Not Tested

---

### Test 9: Desktop - Navegadores Diferentes

**Chrome**:
- [ ] Timeline renderiza
- [ ] Animação de realtime funciona
- [ ] Performance aceitável

**Firefox**:
- [ ] Timeline renderiza
- [ ] Animação de realtime funciona
- [ ] Performance aceitável

**Safari**:
- [ ] Timeline renderiza
- [ ] Animação de realtime funciona
- [ ] Performance aceitável

**Status**: ⬜ Not Tested

---

## Testes de Segurança/Isolamento

### Test 10: RLS Isolamento
**Steps**:
1. Logar com User A (estabelecimento 1)
2. Anotar URL do pedido (ex: /pedido-123)
3. Logar com User B (estabelecimento 2)
4. Tentar acessar URL do pedido de User A
5. Observar timeline

**Expected Result**:
- [ ] User B não consegue ver dados do pedido de User A
- [ ] Página mostra "Pedido não encontrado" ou similar
- [ ] Sem vazamento de informações

**Status**: ⬜ Not Tested

---

## Testes de Performance

### Test 11: Carregamento Inicial
**Steps**:
1. Ir para página de confirmação
2. Medir tempo até timeline aparecer

**Expected Result**:
- [ ] Timeline renderiza em < 2 segundos
- [ ] Sem layout shifts visíveis
- [ ] Componente não causa freeze de página

**Status**: ⬜ Not Tested

---

### Test 12: Atualização em Tempo Real - Performance
**Steps**:
1. Manter página aberta por 5 minutos
2. Fazer 10+ atualizações de status
3. Observar performance

**Expected Result**:
- [ ] Cada atualização < 1 segundo
- [ ] Sem memory leaks
- [ ] Página continua responsiva
- [ ] Sem lags ou travamentos

**Status**: ⬜ Not Tested

---

## Testes de Edge Cases

### Test 13: Histórico Vazio
**Steps**:
1. Simular situação onde não há histórico
2. Verificar renderização

**Expected Result**:
- [ ] Mensagem "Nenhuma atualização de status ainda" aparece
- [ ] Componente não quebra
- [ ] Layout mantém espaço correto

**Status**: ⬜ Not Tested

---

### Test 14: Status Não Reconhecido
**Steps**:
1. Via Supabase, adicionar status com valor inválido (ex: "Status Novo")
2. Verificar timeline

**Expected Result**:
- [ ] Status exibe como escrito (fallback)
- [ ] Ícone padrão (Clock)
- [ ] Cor padrão (gray)
- [ ] Sem erro no console

**Status**: ⬜ Not Tested

---

### Test 15: Observação Muito Longa
**Steps**:
1. Adicionar observação com 500+ caracteres
2. Verificar timeline

**Expected Result**:
- [ ] Texto não transborda
- [ ] Word-wrap funciona
- [ ] Legibilidade mantida

**Status**: ⬜ Not Tested

---

## Testes de Integração

### Test 16: Compatibilidade com Outras Páginas
**Steps**:
1. Ir para ProcessandoPedido
2. Verificar StatusTimeline
3. Ir para AcompanhamentoPedidos
4. Verificar se timeline exibe corretamente

**Expected Result**:
- [ ] Ambas as páginas funcionam
- [ ] Sem conflito de estilos
- [ ] Sem erro de imports

**Status**: ⬜ Not Tested

---

## Checklist Final

- [ ] Todos os testes de funcionalidade passam
- [ ] Responsividade OK em mobile/tablet/desktop
- [ ] Performance aceitável
- [ ] Nenhum erro no console
- [ ] Build sem warnings
- [ ] Compatibilidade com browsers OK
- [ ] RLS funciona corretamente
- [ ] Sem regressões em "Meus Pedidos"

---

## Notas / Bugs Encontrados

```
[Escrever aqui qualquer problema encontrado]
```

---

## Aprovação Final

| Testador | Data | Status |
|----------|------|--------|
| [Nome] | [Data] | ⬜ Não Testado |

---

## Instruções para Executar Smoke Tests

### Setup
```bash
# Terminal 1: Dev Server
npm run dev

# Terminal 2: Supabase Studio (em outra aba do navegador)
# Ir em: supabase.com → seu projeto → Editor de SQL
```

### Fluxo de Teste
1. Abrir http://localhost:5173
2. Fazer checkout de um pedido
3. Manter página aberta
4. Em outra aba, abrir Supabase Studio
5. Na tabela `historico_pedidos`, adicionar registros com status diferentes
6. Voltar à página de confirmação e observar atualizações em tempo real
7. Testar em diferentes resoluções (DevTools)

---

**Última Atualização**: 2026-07-14
**Versão**: 1.0

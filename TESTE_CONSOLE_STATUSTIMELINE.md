# Script de Teste no Console do Navegador

## Como Usar

1. Faça um pedido de delivery
2. Na página de confirmação, pressione **F12**
3. Vá para a aba **"Console"**
4. **Cole o script abaixo** e execute

---

## Script de Diagnóstico Completo

```javascript
// ============================================
// SCRIPT DE DIAGNÓSTICO - StatusTimeline
// ============================================

console.log('🔍 === INICIANDO DIAGNÓSTICO ===');

// 1. Verificar se está na página correta
console.log('📄 Página atual:', window.location.href);
console.log('🌐 Host:', window.location.host);

// 2. Verificar React DevTools / Estado
console.log('📦 Procurando by componentes...');

// 3. Verificar localStorage
const pedidoLocal = localStorage.getItem('pedido');
console.log('💾 Pedido em localStorage:', pedidoLocal ? 'SIM' : 'NÃO');

// 4. Verificar Supabase connection
console.log('🔗 Testando conexão Supabase...');

// 5. Executar busca simulada
(async () => {
  try {
    console.log('⏳ Buscando histórico via fetch...');
    
    // Tenta buscar pelo código do pedido na URL
    const url = new URL(window.location);
    const codigoPedido = url.searchParams.get('pedido') || 'teste';
    
    console.log('📋 Código pedido procurado:', codigoPedido);
    
    // Simula busca na API
    const response = await fetch('/api/historico', {
      method: 'POST',
      body: JSON.stringify({ pedido_id: codigoPedido }),
      headers: { 'Content-Type': 'application/json' }
    }).catch(e => {
      console.log('ℹ️ API não encontrada (esperado):', e.message);
      return null;
    });
    
    if (response) {
      const data = await response.json();
      console.log('✅ Resposta API:', data);
    }
    
  } catch (error) {
    console.error('❌ Erro no teste:', error);
  }
})();

// 6. Listar todos os elementos do StatusTimeline
setTimeout(() => {
  const timeline = document.querySelector('[class*="status"]');
  console.log('🎨 Elementos com "status":', timeline ? 'ENCONTRADO' : 'NÃO ENCONTRADO');
  
  const card = document.querySelector('[class*="Card"]');
  console.log('🎨 Elementos com "Card":', card ? 'ENCONTRADO' : 'NÃO ENCONTRADO');
  
  // Procura por texto específico
  const texto = Array.from(document.querySelectorAll('*')).find(el => 
    el.textContent?.includes('Acompanhe seu Pedido')
  );
  console.log('📝 "Acompanhe seu Pedido" visível:', texto ? 'SIM' : 'NÃO');
  
}, 1000);

console.log('✅ === DIAGNÓSTICO COMPLETO ===');
```

---

## Script Simplificado (Rápido)

Se o anterior tiver muita informação, use este:

```javascript
// Verificar se StatusTimeline existe
const haStatusTimeline = document.body.innerHTML.includes('Acompanhe seu Pedido');
console.log('Timeline Visível:', haStatusTimeline ? '✅ SIM' : '❌ NÃO');

// Mostrar todos os cards
const cards = document.querySelectorAll('[class*="Card"]');
console.log('Cards encontrados:', cards.length);
cards.forEach((card, i) => {
  console.log(`Card ${i}:`, card.querySelector('[class*="Title"]')?.textContent);
});
```

---

## Script para Verificar React State (Avançado)

Se você tiver React DevTools instalado:

```javascript
// Buscar o React Fiber root
const root = document.querySelector('#root')?._reactRoot;
console.log('React Root:', root);

// Procurar componentes
let fiber = root?._internalRoot?.current;
while (fiber) {
  if (fiber.elementType?.name === 'StatusTimeline') {
    console.log('✅ StatusTimeline encontrado!');
    console.log('Props:', fiber.memoizedProps);
    console.log('State:', fiber.memoizedState);
    break;
  }
  fiber = fiber.child || fiber.sibling || fiber.return;
}
```

---

## O Que Procurar Nos Logs

### ✅ Sinais Positivos
- `✅ [ProcessandoPedido] Histórico carregado: Array(1)`
- `StatusTimeline renderizado: {historicoLength: 1}`
- Elemento `"Acompanhe seu Pedido"` aparecendo na página

### ❌ Sinais Negativos  
- `historicoLength: 0` (histórico vazio)
- `Error: "Falha ao buscar histórico"`
- Elemento não encontrado no DOM

### ⚠️ Sinais de Aviso
- Muito tempo carregando (> 5 segundos)
- Realtime não conectando (sem WebSocket)
- Dados com ID diferente que esperado

---

## Próximo Passo

**Após coletar os logs, compare com:**
- Supabase Studio → Tabela `historico_pedidos`
- Procure pelo `codigo_pedido` do seu pedido
- Verifique se tem registros

Se não houver registros, o problema está na **inserção** do histórico, não na exibição.

Se houver registros mas não aparecer, o problema está na **busca** ou **renderização**.

---

**Dúvidas?** Verifique DEBUG_STATUSTIMELINE.md para mais detalhes.

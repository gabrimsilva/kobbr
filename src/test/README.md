# 🧪 Testes Automatizados - Sistema de Delivery

Este diretório contém os testes automatizados do sistema de delivery.

## 📦 Ferramentas Utilizadas

- **Vitest** - Framework de testes (Vite-native, rápido e moderno)
- **@testing-library/react** - Testes de componentes React
- **@testing-library/jest-dom** - Matchers customizados para DOM
- **@testing-library/user-event** - Simulação de eventos de usuário
- **jsdom** - Ambiente DOM para testes

## 🚀 Comandos Disponíveis

```bash
# Rodar testes em modo watch (desenvolvimento)
npm test

# Rodar testes uma vez (CI/CD)
npm run test:run

# Rodar testes com UI interativa
npm run test:ui

# Rodar testes com cobertura
npm run test:coverage
```

## 📁 Estrutura de Testes

```
src/
├── test/
│   ├── setup.ts           # Configuração global de testes
│   └── README.md          # Este arquivo
├── utils/
│   ├── sanitizacao.ts
│   ├── sanitizacao.test.ts  # Testes de sanitização
│   ├── calculos.ts
│   └── calculos.test.ts     # Testes de cálculos
└── hooks/
    ├── useCarrinho.ts
    └── useCarrinho.test.ts  # Testes do hook de carrinho (próximo)
```

## ✅ Cobertura Atual

### Módulos Testados

1. **utils/sanitizacao.ts** - 27 testes ✅
   - sanitizeInput
   - sanitizeRichText
   - sanitizeObject
   - sanitizeCheckoutData
   - sanitizeCartItems
   - sanitizePhone, sanitizeCPF, sanitizeCEP, sanitizeEmail
   - escapeHtml, normalizeWhitespace
   - limitStringLength, sanitizeFreeText

2. **utils/calculos.ts** - 7 testes ✅
   - calcularSubtotal
   - calcularTotal

### Próximos Testes (Backlog)

- [ ] hooks/useCarrinho.ts
- [ ] hooks/useFinalizarPedido.ts
- [ ] hooks/useGerenciarPedidos.ts
- [ ] hooks/useRealtimePedidos.ts
- [ ] components/delivery/ProdutoCard.tsx
- [ ] pages/DeliveryPage.tsx

## 🎯 Metas de Cobertura

- **Linhas:** 70%
- **Funções:** 70%
- **Branches:** 70%
- **Statements:** 70%

**Cobertura atual:** ~15% (34 testes)

## 📝 Escrevendo Testes

### Exemplo de Teste de Função

```typescript
import { describe, it, expect } from 'vitest'
import { minhaFuncao } from './meuModulo'

describe('Meu Módulo', () => {
  describe('minhaFuncao', () => {
    it('deve fazer algo esperado', () => {
      const resultado = minhaFuncao('input')
      expect(resultado).toBe('output esperado')
    })

    it('deve lidar com casos extremos', () => {
      expect(minhaFuncao(null)).toBe('')
      expect(minhaFuncao(undefined)).toBe('')
    })
  })
})
```

### Exemplo de Teste de Hook

```typescript
import { renderHook, act } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { useMeuHook } from './useMeuHook'

describe('useMeuHook', () => {
  it('deve inicializar com valor padrão', () => {
    const { result } = renderHook(() => useMeuHook())
    expect(result.current.valor).toBe(0)
  })

  it('deve atualizar valor ao chamar função', () => {
    const { result } = renderHook(() => useMeuHook())

    act(() => {
      result.current.incrementar()
    })

    expect(result.current.valor).toBe(1)
  })
})
```

### Exemplo de Teste de Componente

```typescript
import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { MeuComponente } from './MeuComponente'

describe('MeuComponente', () => {
  it('deve renderizar texto corretamente', () => {
    render(<MeuComponente texto="Olá Mundo" />)
    expect(screen.getByText('Olá Mundo')).toBeInTheDocument()
  })

  it('deve chamar callback ao clicar', async () => {
    const onClick = vi.fn()
    render(<MeuComponente onClick={onClick} />)

    const botao = screen.getByRole('button')
    await userEvent.click(botao)

    expect(onClick).toHaveBeenCalledTimes(1)
  })
})
```

## 🔧 Configuração

### vitest.config.ts

Configuração principal do Vitest:

```typescript
export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      thresholds: {
        lines: 70,
        functions: 70,
        branches: 70,
        statements: 70
      }
    }
  }
})
```

### src/test/setup.ts

Setup global executado antes de todos os testes:

- Importa matchers do jest-dom
- Configura cleanup automático
- Mocka localStorage/sessionStorage
- Mocka window.matchMedia
- Mocka IntersectionObserver/ResizeObserver

## 🐛 Debugging de Testes

### Rodar testes específicos

```bash
# Rodar apenas um arquivo
npm test -- src/utils/sanitizacao.test.ts

# Rodar apenas testes que contenham "sanitize" no nome
npm test -- -t sanitize

# Rodar em modo watch para um arquivo específico
npm test -- src/utils/calculos.test.ts --watch
```

### Ver output detalhado

```bash
# Modo verbose
npm test -- --reporter=verbose

# UI interativa (recomendado para debugging)
npm run test:ui
```

### Debug com breakpoints

```typescript
import { describe, it, expect } from 'vitest'

describe('Debug Test', () => {
  it('deve parar no debugger', () => {
    const valor = minhaFuncao()
    debugger // Chrome DevTools vai parar aqui
    expect(valor).toBe(esperado)
  })
})
```

## 📚 Boas Práticas

### 1. Testes Independentes

❌ **Ruim:**
```typescript
let carrinho = []

it('deve adicionar item', () => {
  carrinho.push(item)
  expect(carrinho.length).toBe(1)
})

it('deve remover item', () => {
  carrinho.pop() // Depende do teste anterior!
  expect(carrinho.length).toBe(0)
})
```

✅ **Bom:**
```typescript
it('deve adicionar item', () => {
  const carrinho = []
  carrinho.push(item)
  expect(carrinho.length).toBe(1)
})

it('deve remover item', () => {
  const carrinho = [item]
  carrinho.pop()
  expect(carrinho.length).toBe(0)
})
```

### 2. Arrange-Act-Assert (AAA)

```typescript
it('deve calcular total com desconto', () => {
  // Arrange - preparar dados
  const carrinho = [{ preco: 100, quantidade: 2 }]
  const desconto = 10

  // Act - executar ação
  const total = calcularTotal(carrinho, desconto)

  // Assert - verificar resultado
  expect(total).toBe(180)
})
```

### 3. Nomes Descritivos

❌ **Ruim:**
```typescript
it('teste 1', () => { ... })
it('funciona', () => { ... })
```

✅ **Bom:**
```typescript
it('deve calcular subtotal de múltiplos itens', () => { ... })
it('deve retornar 0 para carrinho vazio', () => { ... })
```

### 4. Testar Casos Extremos

```typescript
describe('sanitizeInput', () => {
  it('deve funcionar com input normal', () => {
    expect(sanitizeInput('texto')).toBe('texto')
  })

  // Casos extremos
  it('deve lidar com null', () => {
    expect(sanitizeInput(null)).toBe('')
  })

  it('deve lidar com undefined', () => {
    expect(sanitizeInput(undefined)).toBe('')
  })

  it('deve lidar com string vazia', () => {
    expect(sanitizeInput('')).toBe('')
  })

  it('deve lidar com XSS', () => {
    expect(sanitizeInput('<script>alert("xss")</script>'))
      .not.toContain('<script>')
  })
})
```

## 🎓 Recursos de Aprendizado

- [Vitest Documentation](https://vitest.dev/)
- [Testing Library](https://testing-library.com/docs/react-testing-library/intro/)
- [Test-Driven Development (TDD)](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530)

## 🤝 Contribuindo

Ao adicionar novos recursos:

1. Escreva testes ANTES de implementar (TDD)
2. Garanta que todos os testes passem
3. Mantenha cobertura acima de 70%
4. Siga as boas práticas acima

## 📊 CI/CD

Os testes rodam automaticamente no CI/CD:

```yaml
# .github/workflows/test.yml
- name: Run tests
  run: npm run test:run

- name: Check coverage
  run: npm run test:coverage
```

---

**Última atualização:** 2026-01-10
**Testes implementados:** 34
**Cobertura:** ~15%

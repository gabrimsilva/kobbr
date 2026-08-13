# 🔐 Guia de Segurança - Sistema de Delivery

## ⚠️ IMPORTANTE: Credenciais Expostas

Se você está lendo este documento porque o repositório foi clonado ou as credenciais foram expostas, siga este guia imediatamente.

---

## 🚨 Ação Imediata Necessária

### 1. Rotacionar Chaves do Supabase

As credenciais atuais do Supabase foram expostas e devem ser rotacionadas:

**Passos para rotacionar:**

1. Acesse o [Dashboard do Supabase](https://app.supabase.com)
2. Vá para o seu projeto
3. Acesse: **Settings** > **API**
4. Role até **Project API keys**
5. Clique em **Regenerate** para a chave `anon (public)`
6. Copie a nova chave

⚠️ **ATENÇÃO:** Ao regenerar a chave, todos os aplicativos usando a chave antiga pararão de funcionar até serem atualizados.

### 2. Atualizar Credenciais Localmente

Após gerar novas chaves:

1. Abra o arquivo `.env` (não commite este arquivo!)
2. Substitua as credenciais antigas pelas novas:

```env
VITE_SUPABASE_URL=https://seu-novo-projeto.supabase.co
VITE_SUPABASE_ANON_KEY=sua_nova_chave_anonima
```

3. Reinicie o servidor de desenvolvimento: `npm run dev`

### 3. Verificar .gitignore

Confirme que o arquivo `.env` está listado no `.gitignore`:

```bash
# Verificar se .env está no .gitignore
cat .gitignore | grep .env
```

Deve retornar:
```
.env
.env.local
.env.production
```

---

## 🛡️ Práticas de Segurança para Desenvolvedores

### Variáveis de Ambiente

#### ✅ CORRETO - Usar variáveis de ambiente

```typescript
// Correto
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY
```

#### ❌ ERRADO - Hardcoded no código

```typescript
// NUNCA faça isso!
const supabaseUrl = "https://voqbxnneptqsoxcymnln.supabase.co"
const supabaseKey = "eyJhbGciOiJIUzI1NiIs..."
```

### Arquivos Sensíveis

**NUNCA commite:**
- `.env` (credenciais locais)
- `*.pem` (certificados)
- `*private*key*` (chaves privadas)
- Arquivos com tokens ou senhas

**SEMPRE commite:**
- `.env.example` (template sem credenciais)
- `.gitignore` (lista de arquivos a ignorar)

### Checklist Antes de Commitar

```bash
# 1. Verificar se há credenciais expostas
git diff | grep -i "password\|token\|secret\|key"

# 2. Verificar arquivos staged
git status

# 3. Se .env aparecer, REMOVA imediatamente
git reset HEAD .env

# 4. Se já foi commitado, use git-filter-repo ou BFG Cleaner
```

---

## 🔒 Níveis de Acesso no Supabase

### Chave Anônima (anon key)
- **Uso:** Frontend, aplicações públicas
- **Permissões:** Limitadas por Row Level Security (RLS)
- **Exposição:** Pode ser exposta no código do cliente
- **Proteção:** RLS policies no banco de dados

### Chave de Serviço (service_role key)
- **Uso:** Backend, scripts administrativos, edge functions
- **Permissões:** ACESSO TOTAL ao banco
- **Exposição:** NUNCA exponha esta chave
- **Armazenamento:** Apenas em variáveis de ambiente do servidor

⚠️ **CRÍTICO:** A service_role key bypassa todas as políticas RLS!

---

## 🛠️ Configuração para Produção

### Variáveis de Ambiente em Produção

Configure as variáveis de ambiente diretamente na plataforma de hospedagem:

#### Vercel
1. Acesse: **Settings** > **Environment Variables**
2. Adicione:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
3. Escolha ambiente: Production / Preview / Development

#### Netlify
1. Acesse: **Site Settings** > **Build & Deploy** > **Environment**
2. Adicione as variáveis
3. Redeploy o site

#### Render / Railway / Heroku
Similar aos acima, cada plataforma tem sua seção de Environment Variables.

---

## 🔍 Auditoria de Segurança

### Verificar Exposição de Credenciais

```bash
# Buscar por possíveis credenciais no código
grep -r "supabase.co" src/
grep -r "eyJhbGciOiJI" src/
grep -r "password\|secret\|token" src/

# Buscar no histórico do Git (se suspeitar de exposição)
git log --all --full-history --source -- '*env*'
```

### Remover Credenciais do Histórico do Git

Se credenciais foram commitadas:

```bash
# Opção 1: BFG Repo Cleaner (mais rápido)
bfg --replace-text passwords.txt

# Opção 2: git-filter-repo
git filter-repo --path .env --invert-paths

# Após limpar, force push (CUIDADO!)
git push origin --force --all
```

⚠️ **AVISO:** Force push reescreve o histórico. Coordene com a equipe!

---

## 📋 Checklist de Segurança

Antes de fazer deploy:

- [ ] Arquivo `.env` está no `.gitignore`
- [ ] `.env.example` não contém credenciais reais
- [ ] Variáveis de ambiente configuradas na plataforma de hospedagem
- [ ] Chaves do Supabase foram rotacionadas (se expostas)
- [ ] RLS policies estão ativas em todas as tabelas
- [ ] Não há `console.log` com dados sensíveis
- [ ] Inputs estão sendo sanitizados (ver TAREFAS_MELHORIAS.md #2)
- [ ] HTTPS está ativo em produção
- [ ] Headers de segurança configurados (CSP, HSTS, etc.)

---

## 🆘 Incidente de Segurança

Se você descobriu uma vulnerabilidade ou exposição de credenciais:

1. **NÃO ENTRE EM PÂNICO**
2. Documente o que foi exposto e quando
3. Rotacione TODAS as credenciais imediatamente
4. Verifique logs de acesso do Supabase
5. Notifique a equipe
6. Siga o procedimento de limpeza do Git (se necessário)
7. Monitore atividades suspeitas por 30 dias

---

## 📚 Recursos Adicionais

- [Supabase Security Best Practices](https://supabase.com/docs/guides/auth/row-level-security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Git Secrets Scanner](https://github.com/trufflesecurity/trufflehog)
- [BFG Repo Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)

---

**Última atualização:** 2026-01-10
**Próxima revisão:** Trimestral

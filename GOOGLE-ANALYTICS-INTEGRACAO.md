# 📊 Guia Completo de Instalação - Google Analytics 4

Este guia detalha como replicar a integração do Google Analytics 4 neste sistema, onde as credenciais ficam no `.env` e os dados são buscados diretamente da API do Google Analytics.

---

## 📋 Visão Geral da Arquitetura

O sistema utiliza:
- **Frontend**: Rastreamento de eventos com `gtag.js`
- **Backend**: Edge Function no Supabase que busca dados da Google Analytics Data API
- **Autenticação**: Service Account do Google Cloud com JWT
- **Segurança**: Credenciais armazenadas em variáveis de ambiente

---

## 🚀 Passo a Passo Completo

### 1️⃣ Criar Conta Google Analytics 4

1. Acesse [Google Analytics](https://analytics.google.com/)
2. Clique em **Admin** (engrenagem no canto inferior esquerdo)
3. Clique em **+ Create Property**
4. Preencha:
   - **Property name**: Nome do seu sistema (ex: "Sistema Pizzaria")
   - **Timezone**: Brazil (GMT-03:00)
   - **Currency**: Brazilian Real (R$)
5. Clique em **Next** e configure os detalhes do negócio
6. Aceite os termos e clique em **Create**
7. Configure o **Data Stream**:
   - Selecione **Web**
   - URL do site: seu domínio
   - Nome do stream: "Website"
8. **IMPORTANTE**: Copie o **Measurement ID** (formato: `G-XXXXXXXXXX`)

### 2️⃣ Adicionar Google Analytics no Frontend

Edite o arquivo `index.html` e substitua o Measurement ID existente pelo seu:

```html
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

**Substitua `G-XXXXXXXXXX` pelo seu Measurement ID.**

### 3️⃣ Criar Projeto no Google Cloud

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Clique em **Select a project** → **NEW PROJECT**
3. Preencha:
   - **Project name**: `analytics-api-pizzaria` (ou outro nome)
   - **Organization**: Deixe em branco se não tiver
4. Clique em **CREATE**
5. Aguarde a criação e selecione o projeto

### 4️⃣ Habilitar Google Analytics Data API

1. No menu lateral, vá em **APIs & Services** → **Library**
2. Busque por: `Google Analytics Data API`
3. Clique na API
4. Clique em **ENABLE**
5. Aguarde a ativação (pode levar alguns segundos)

### 5️⃣ Criar Service Account

1. No menu lateral, vá em **IAM & Admin** → **Service Accounts**
2. Clique em **+ CREATE SERVICE ACCOUNT**
3. Preencha:
   - **Service account name**: `analytics-api-service`
   - **Service account ID**: `analytics-api-service` (gerado automaticamente)
   - **Description**: `Service account para acessar Google Analytics Data API`
4. Clique em **CREATE AND CONTINUE**
5. **Pule a etapa de permissões** (clique em **CONTINUE**)
6. Clique em **DONE**

### 6️⃣ Gerar Chave JSON da Service Account

1. Na lista de Service Accounts, clique na conta `analytics-api-service`
2. Vá na aba **KEYS**
3. Clique em **ADD KEY** → **Create new key**
4. Selecione **JSON**
5. Clique em **CREATE**
6. Um arquivo JSON será baixado automaticamente

**⚠️ IMPORTANTE**: Guarde este arquivo em local seguro! Ele contém credenciais sensíveis.

O arquivo JSON terá esta estrutura:
```json
{
  "type": "service_account",
  "project_id": "seu-projeto-123456",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBg...\n-----END PRIVATE KEY-----\n",
  "client_email": "analytics-api-service@seu-projeto-123456.iam.gserviceaccount.com",
  "client_id": "123456789",
  ...
}
```

### 7️⃣ Dar Acesso à Service Account no Google Analytics

1. Volte ao [Google Analytics](https://analytics.google.com/)
2. Clique em **Admin** (engrenagem)
3. Na coluna **Property**, clique em **Property Access Management**
4. Clique em **+** (Add users) no canto superior direito
5. Cole o **email da service account** (campo `client_email` do JSON):
   ```
   analytics-api-service@seu-projeto-123456.iam.gserviceaccount.com
   ```
6. Selecione a permissão **Viewer** (apenas leitura)
7. **Desmarque** a opção "Notify new users by email"
8. Clique em **Add**

### 8️⃣ Obter o Property ID

1. No Google Analytics, vá em **Admin**
2. Na coluna **Property**, clique em **Property Settings**
3. Copie o **PROPERTY ID** (número, ex: `123456789`)

---

## 💻 Configuração no Sistema

### 9️⃣ Configurar Secrets no Supabase

Você precisa adicionar as credenciais como secrets no Supabase para a Edge Function funcionar.

#### Via Supabase CLI (Recomendado)

```bash
# 1. Instalar Supabase CLI (se ainda não tiver)
npm install -g supabase

# 2. Fazer login
supabase login

# 3. Vincular ao projeto
supabase link --project-ref SEU_PROJECT_REF

# 4. Adicionar secrets
supabase secrets set GA4_PROPERTY_ID=123456789

supabase secrets set GA4_SERVICE_ACCOUNT_EMAIL=analytics-api-service@seu-projeto-123456.iam.gserviceaccount.com

supabase secrets set GA4_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBg...
-----END PRIVATE KEY-----"
```

**Dica**: Para o `GA4_PRIVATE_KEY`, você pode criar um arquivo temporário:

```bash
# Criar arquivo com a chave
echo "-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBg...
-----END PRIVATE KEY-----" > temp_key.txt

# Adicionar como secret
supabase secrets set GA4_PRIVATE_KEY="$(cat temp_key.txt)"

# Deletar arquivo temporário
rm temp_key.txt
```

#### Via Dashboard do Supabase

1. Acesse [Supabase Dashboard](https://supabase.com/dashboard)
2. Selecione seu projeto
3. Vá em **Project Settings** → **Edge Functions**
4. Na seção **Secrets**, adicione:
   - `GA4_PROPERTY_ID`
   - `GA4_SERVICE_ACCOUNT_EMAIL`
   - `GA4_PRIVATE_KEY`

### 🔟 Deploy da Edge Function

A Edge Function já existe em `supabase/functions/get-analytics-data/index.ts`.

Para fazer o deploy:

```bash
# Deploy da função
supabase functions deploy get-analytics-data

# Verificar se foi deployada
supabase functions list
```

### 1️⃣1️⃣ Testar a Integração

Você pode testar a Edge Function diretamente:

```bash
# Testar localmente (se tiver secrets configurados)
supabase functions serve get-analytics-data

# Ou testar a função deployada
curl -X POST \
  'https://SEU_PROJECT_REF.supabase.co/functions/v1/get-analytics-data' \
  -H 'Authorization: Bearer SEU_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"periodo":"7dias"}'
```

---

## 📁 Estrutura de Arquivos

O sistema possui todos os arquivos necessários:

```
├── index.html                              # Script do GA4
├── .env                                    # Credenciais locais (não commitar!)
├── src/
│   ├── lib/
│   │   ├── analytics.ts                   # Funções de rastreamento
│   │   └── googleAnalyticsService.ts      # Service para buscar dados
│   ├── components/
│   │   └── MapaBrasil.tsx                 # Mapa visual do Brasil
│   └── pages/
│       └── Analytics.tsx                  # Página de analytics
└── supabase/
    └── functions/
        └── get-analytics-data/
            └── index.ts                   # Edge Function
```

---

## 🎯 Como Usar no Sistema

### Rastrear Eventos (Frontend)

```typescript
import { trackViewItem, trackAddToCart, trackPurchase } from '@/lib/analytics'

// Visualização de produto
trackViewItem({
  id: produto.id,
  nome: produto.nome,
  categoria: produto.categoria,
  preco: produto.preco
})

// Adicionar ao carrinho
trackAddToCart({
  id: produto.id,
  nome: produto.nome,
  preco: produto.preco,
  quantidade: 1
})

// Finalizar compra
trackPurchase(
  pedidoId,
  carrinho,
  total,
  taxaEntrega
)
```

### Buscar Dados (Frontend)

```typescript
import { buscarDadosGA4 } from '@/lib/googleAnalyticsService'

// Buscar dados dos últimos 7 dias
const dados = await buscarDadosGA4('7dias')

console.log('Usuários ativos:', dados.overview.activeUsers)
console.log('Visualizações:', dados.overview.screenPageViews)
console.log('Produtos mais vistos:', dados.products)
```

---

## 🔒 Segurança

### ✅ Boas Práticas

- ✅ Credenciais apenas no backend (Edge Function)
- ✅ Variáveis de ambiente para dados sensíveis
- ✅ Service Account com permissão mínima (Viewer)
- ✅ Arquivo JSON no `.gitignore`
- ✅ CORS configurado na Edge Function

### ❌ Nunca Faça

- ❌ Commitar o arquivo JSON no Git
- ❌ Expor credenciais no frontend
- ❌ Compartilhar a chave privada
- ❌ Dar permissões além de Viewer

---

## 🐛 Troubleshooting

### Erro: "API has not been used"
**Solução**: Habilite a Google Analytics Data API no Google Cloud Console (passo 4)

### Erro: "PERMISSION_DENIED"
**Solução**: Adicione o email da service account no Google Analytics com permissão Viewer (passo 7)

### Erro: "Property not found"
**Solução**: Verifique se o Property ID está correto (passo 8)

### Erro: "Invalid credentials" ou "UNAUTHENTICATED"
**Solução**: 
- Verifique se copiou corretamente a chave privada
- Certifique-se de que manteve as quebras de linha (`\n`)
- Verifique se o email da service account está correto

### Erro: "Chave privada inválida"
**Solução**:
- Abra o arquivo JSON baixado
- Copie o campo `private_key` EXATAMENTE como está
- Inclua as aspas duplas ao redor
- Exemplo: `"-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"`

### Dados não aparecem no GA4
**Solução**:
- Aguarde 24-48h após configurar para dados aparecerem
- Verifique se o Measurement ID está correto no `index.html`
- Teste se eventos estão sendo enviados (abra DevTools → Network → filtre por "collect")

### Edge Function retorna erro 500
**Solução**:
- Verifique os logs: `supabase functions logs get-analytics-data`
- Confirme que os secrets estão configurados
- Teste localmente: `supabase functions serve get-analytics-data`

---

## ✅ Checklist de Instalação

Use este checklist para garantir que tudo foi configurado:

- [ ] Conta Google Analytics 4 criada
- [ ] Measurement ID copiado e adicionado no `index.html`
- [ ] Projeto criado no Google Cloud Console
- [ ] Google Analytics Data API habilitada
- [ ] Service Account criada
- [ ] Arquivo JSON da service account baixado
- [ ] Email da service account adicionado no GA4 com permissão Viewer
- [ ] Property ID copiado
- [ ] Secrets configurados no Supabase
- [ ] Edge Function deployada
- [ ] Integração testada e funcionando

---

## 🎉 Pronto!

Agora seu sistema está integrado com o Google Analytics 4 e você pode:

1. **Rastrear eventos** de usuários em tempo real
2. **Visualizar métricas** na página de Analytics do sistema
3. **Analisar comportamento** dos clientes
4. **Otimizar conversões** com base em dados reais

Se tiver dúvidas, consulte a documentação oficial ou os logs da Edge Function.

---

## 📚 Documentação Oficial

- [Google Analytics 4](https://support.google.com/analytics/answer/10089681)
- [Google Analytics Data API](https://developers.google.com/analytics/devguides/reporting/data/v1)
- [Métricas e Dimensões](https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema)
- [Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

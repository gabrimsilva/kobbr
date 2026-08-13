# ✅ Checklist de Configuração - Google Analytics 4

Use este checklist para acompanhar o progresso da configuração.

## 📊 Google Analytics 4

- [ ] **Conta GA4 criada**
  - Acesse: https://analytics.google.com/
  - Admin → Create Property
  
- [ ] **Measurement ID obtido**
  - Formato: `G-XXXXXXXXXX`
  - Localização: Admin → Data Streams → Web Stream
  
- [ ] **Measurement ID adicionado no código**
  - Arquivo: `index.html` (linha 48)
  - Substitua `G-HFF0GZQ9QP` pelo seu ID

## ☁️ Google Cloud

- [ ] **Projeto criado**
  - Acesse: https://console.cloud.google.com/
  - New Project → Nome: `analytics-api-pizzaria`
  
- [ ] **Google Analytics Data API habilitada**
  - APIs & Services → Library
  - Busque: "Google Analytics Data API"
  - Clique em ENABLE
  
- [ ] **Service Account criada**
  - IAM & Admin → Service Accounts
  - Create Service Account
  - Nome: `analytics-api-service`
  
- [ ] **Chave JSON baixada**
  - Service Account → Keys → Add Key → JSON
  - Arquivo salvo em local seguro
  - ⚠️ NÃO commitar no Git!

## 🔐 Permissões

- [ ] **Service Account adicionada no GA4**
  - GA4 → Admin → Property Access Management
  - Add users → Cole o `client_email` do JSON
  - Permissão: **Viewer**
  - Desmarque "Notify by email"

## 📝 Dados Coletados

- [ ] **Property ID obtido**
  - GA4 → Admin → Property Settings
  - Copie o número (ex: `123456789`)

- [ ] **Email da Service Account copiado**
  - Do arquivo JSON: campo `client_email`
  - Formato: `analytics-api-service@projeto.iam.gserviceaccount.com`

- [ ] **Chave privada copiada**
  - Do arquivo JSON: campo `private_key`
  - Mantém as quebras de linha (`\n`)

## 🚀 Supabase

- [ ] **Supabase CLI instalado**
  ```bash
  npm install -g supabase
  ```

- [ ] **Login no Supabase**
  ```bash
  supabase login
  ```

- [ ] **Projeto vinculado**
  ```bash
  supabase link --project-ref SEU_PROJECT_REF
  ```

- [ ] **Secrets configurados**
  ```bash
  supabase secrets set GA4_PROPERTY_ID=123456789
  supabase secrets set GA4_SERVICE_ACCOUNT_EMAIL=email@projeto.iam.gserviceaccount.com
  supabase secrets set GA4_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
  ```

- [ ] **Edge Function deployada**
  ```bash
  supabase functions deploy get-analytics-data
  ```

## 🧪 Testes

- [ ] **Teste local**
  ```bash
  supabase functions serve get-analytics-data
  ```

- [ ] **Teste em produção**
  - Acesse: `/sistema/analytics`
  - Verifique se os dados aparecem

- [ ] **Eventos sendo rastreados**
  - Abra DevTools → Network
  - Filtre por "collect"
  - Navegue pelo site e veja eventos sendo enviados

## 📊 Validação Final

- [ ] **Dados aparecem no GA4**
  - Aguarde 24-48h após configurar
  - GA4 → Reports → Realtime

- [ ] **Página Analytics funciona**
  - Acesse `/sistema/analytics`
  - Selecione período: Hoje, 7 dias, 30 dias
  - Verifique métricas, produtos, páginas, localizações

- [ ] **Exportação funciona**
  - Na página Analytics, clique em "Exportar"
  - Arquivo Excel deve ser baixado

## 🎉 Conclusão

Se todos os itens estão marcados, sua integração está completa!

## 📚 Documentação

- **Guia Completo**: `GOOGLE-ANALYTICS-INTEGRACAO.md`
- **Resumo Rápido**: `docs/GOOGLE_ANALYTICS_RESUMO.md`
- **Edge Function**: `supabase/functions/get-analytics-data/README.md`

## 🆘 Problemas?

Consulte a seção **Troubleshooting** no guia completo ou execute:

```bash
# Windows
.\scripts\test-analytics.ps1

# Linux/Mac
./scripts/test-analytics.sh
```

## 📞 Logs

Ver logs da Edge Function:
```bash
supabase functions logs get-analytics-data
```

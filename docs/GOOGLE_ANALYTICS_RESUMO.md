# 📊 Google Analytics 4 - Resumo Rápido

## ⚡ Configuração Rápida

### 1. Google Analytics
1. Crie uma propriedade GA4 em https://analytics.google.com/
2. Copie o **Measurement ID** (G-XXXXXXXXXX)
3. Substitua no `index.html` (linha 48)

### 2. Google Cloud
1. Crie projeto em https://console.cloud.google.com/
2. Habilite **Google Analytics Data API**
3. Crie **Service Account** → Baixe JSON
4. Copie do JSON:
   - `client_email`
   - `private_key`

### 3. Dar Acesso
1. No GA4 → Admin → Property Access Management
2. Adicione o `client_email` com permissão **Viewer**

### 4. Obter Property ID
1. No GA4 → Admin → Property Settings
2. Copie o **Property ID** (número)

### 5. Configurar Supabase Secrets

```bash
supabase secrets set GA4_PROPERTY_ID=123456789
supabase secrets set GA4_SERVICE_ACCOUNT_EMAIL=analytics-api-service@projeto.iam.gserviceaccount.com
supabase secrets set GA4_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----"
```

### 6. Deploy Edge Function

```bash
supabase functions deploy get-analytics-data
```

## 🎯 Pronto!

Acesse `/sistema/analytics` para ver os dados.

## 📖 Guia Completo

Veja `GOOGLE-ANALYTICS-INTEGRACAO.md` para instruções detalhadas.

## 🔧 Troubleshooting

- **Erro de permissão**: Adicione service account no GA4
- **Erro de API**: Habilite Google Analytics Data API
- **Sem dados**: Aguarde 24-48h após configurar
- **Erro 500**: Verifique secrets no Supabase

## 📞 Suporte

Logs da Edge Function:
```bash
supabase functions logs get-analytics-data
```

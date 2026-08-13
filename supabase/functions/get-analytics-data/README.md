# Edge Function: get-analytics-data

Esta Edge Function busca dados do Google Analytics 4 via Google Analytics Data API.

## 📋 Pré-requisitos

1. Google Analytics 4 configurado
2. Service Account criada no Google Cloud
3. Service Account com acesso Viewer no GA4
4. Secrets configurados no Supabase

## 🔐 Secrets Necessários

```bash
GA4_PROPERTY_ID=123456789
GA4_SERVICE_ACCOUNT_EMAIL=analytics-api-service@projeto.iam.gserviceaccount.com
GA4_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

## 🚀 Deploy

```bash
# Deploy da função
supabase functions deploy get-analytics-data

# Verificar deploy
supabase functions list
```

## 🧪 Testar

### Localmente

```bash
# Servir localmente (precisa dos secrets configurados)
supabase functions serve get-analytics-data

# Em outro terminal, fazer requisição
curl -X POST \
  'http://localhost:54321/functions/v1/get-analytics-data' \
  -H 'Authorization: Bearer SEU_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"periodo":"7dias"}'
```

### Em Produção

```bash
curl -X POST \
  'https://SEU_PROJECT_REF.supabase.co/functions/v1/get-analytics-data' \
  -H 'Authorization: Bearer SEU_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"periodo":"7dias"}'
```

## 📊 Parâmetros

- `periodo`: `'hoje'` | `'7dias'` | `'30dias'`

## 📤 Resposta

```json
{
  "overview": {
    "activeUsers": 1234,
    "newUsers": 567,
    "sessions": 2345,
    "screenPageViews": 5678,
    "averageSessionDuration": 123.45,
    "bounceRate": 0.45,
    "conversions": 89,
    "itemsViewed": 456,
    "itemsAddedToCart": 123,
    "itemsPurchased": 45,
    "itemRevenue": 1234.56,
    "purchaseRevenue": 2345.67
  },
  "devices": [
    {
      "device": "mobile",
      "users": 800,
      "percentage": 65
    }
  ],
  "products": [
    {
      "name": "Pizza Margherita",
      "views": 234,
      "addToCart": 89,
      "purchases": 45,
      "revenue": 567.89
    }
  ],
  "pages": [
    {
      "page": "/",
      "views": 1234,
      "avgTime": "2m 34s",
      "bounceRate": "45.6%"
    }
  ],
  "locations": [
    {
      "city": "São Paulo",
      "state": "State of São Paulo",
      "users": 456,
      "sessions": 789
    }
  ]
}
```

## 🐛 Troubleshooting

### Erro: "Credenciais do Google Analytics não configuradas"
**Solução**: Configure os secrets GA4_PROPERTY_ID, GA4_SERVICE_ACCOUNT_EMAIL e GA4_PRIVATE_KEY

### Erro: "Erro ao obter access token"
**Solução**: 
- Verifique se a chave privada está correta (com `\n` para quebras de linha)
- Verifique se o email da service account está correto

### Erro: "PERMISSION_DENIED"
**Solução**: Adicione o email da service account no Google Analytics com permissão Viewer

### Ver Logs

```bash
supabase functions logs get-analytics-data
```

## 📚 Documentação

- [Google Analytics Data API](https://developers.google.com/analytics/devguides/reporting/data/v1)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

# Guia de Instalação e Configuração do Sistema de Pizzaria

Este guia apresenta o passo a passo completo para configurar o sistema de gerenciamento de pizzaria, incluindo banco de dados, pagamentos e integração com APIs.

---

## 📋 Pré-requisitos

- Conta no [Supabase](https://supabase.com)
- Conta no [Mercado Pago Developers](https://www.mercadopago.com.br/developers/panel/app)
- Conta no [Google Cloud Console](https://console.cloud.google.com)
- Editor de código (VS Code recomendado)
- Node.js instalado

---

## 🗄️ Parte 1: Configuração do Banco de Dados (Supabase)

### 1. Preparação do Projeto
1. Descompacte o arquivo ZIP do sistema para sua área de trabalho
2. Abra a pasta do projeto no VS Code ou editor de sua preferência
3. Localize o arquivo `BANCO-COMPLETO-PIZZARIA.sql` na raiz do projeto e copie todo o seu conteúdo

### 2. Criação do Projeto no Supabase
1. Acesse [supabase.com](https://supabase.com) e crie uma conta (caso não tenha)
2. Crie um novo projeto e aguarde a inicialização
3. No menu lateral, acesse **SQL Editor**
4. Cole todo o conteúdo do arquivo `BANCO-COMPLETO-PIZZARIA.sql`
5. Clique em **RUN** e aguarde a criação de todas as tabelas

### 3. Configuração de Autenticação
1. No menu lateral, acesse **Authentication** → **Providers**
2. Desabilite a opção **Confirm email** (para facilitar o cadastro inicial)
3. Ainda em **Authentication**, vá em **Users** → **Add user**
4. Crie o primeiro usuário administrador do sistema

### 4. Obtenção das Credenciais
1. Acesse **Project Settings** → **API**
2. Copie a **Project URL** e salve em um bloco de notas
3. Localize e copie a **anon public** key (em "Project API keys")
4. Salve ambas as credenciais - você precisará delas no próximo passo

### 5. Configuração do Arquivo .env
1. No VS Code, localize o arquivo `.env` na raiz do projeto
2. Substitua as credenciais de exemplo pelas suas credenciais oficiais:
   ```
   VITE_SUPABASE_URL=sua_project_url_aqui
   VITE_SUPABASE_ANON_KEY=sua_anon_key_aqui
   ```

### 6. Deploy das Edge Functions
1. No VS Code, localize a pasta `supabase/functions` - ela contém 5 Edge Functions
2. No Supabase, acesse **Edge Functions** no menu lateral
3. Clique em **Deploy a new Function** (canto superior direito)
4. Escolha a opção **Via Editor**
5. Para cada função, copie o código do VS Code e cole no editor do Supabase
6. **Importante:** Use exatamente o mesmo nome da função que está no código

#### Configuração JWT das Edge Functions:
- `cancelar-pedidos-expirados` → **JWT DESATIVADO**
- `check-payment-status` → **JWT ATIVADO**
- `create-pix-payment` → **JWT DESATIVADO**
- `mercadopago-webhook` → **JWT DESATIVADO**
- `zerar-pedidos` → **JWT DESATIVADO**

✅ **Checkpoint:** Neste momento seu banco de dados está criado e vinculado ao sistema!

---

## 💳 Parte 2: Configuração do Mercado Pago

### 7. Criação da Aplicação
1. Acesse [Mercado Pago Developers](https://www.mercadopago.com.br/developers/panel/app)
2. Crie uma nova aplicação e dê um nome descritivo
3. Selecione a opção **Pagamento Online**
4. Escolha **Checkout transparente** e continue
5. Selecione **API de Pagamentos** e finalize a criação

### 8. Configuração das Credenciais
1. No menu lateral, acesse **Credenciais de produção**
2. Preencha os dados solicitados
3. Copie o **Access Token** gerado
4. No sistema, vá até a aba **Pagamentos**
5. Cole o Access Token no campo **"Access Token do Mercado Pago"** e salve

### 9. Configuração do Webhook
1. No Mercado Pago, clique em **WEBHOOKS**
2. Acesse a aba **Produção** (não use o modo de teste)
3. Ative as seguintes opções:
   - ✅ Pagamentos
   - ✅ Alertas de fraude
   - ✅ Card Updater
   - ✅ Order
   - ✅ Contestações
   - ✅ Reclamações

4. Para obter a URL do webhook:
   - Volte ao Supabase → **Edge Functions**
   - Acesse a função `mercadopago-webhook`
   - Clique em **Details** e copie o **Endpoint URL**
   - Cole esta URL no campo de webhook do Mercado Pago

5. Após salvar, será gerada uma **Assinatura Secreta**
6. Copie esta assinatura e cole no sistema em **"Assinatura Secreta do Webhook"** (aba Pagamentos)

✅ **Checkpoint:** Integração com Mercado Pago concluída!

---

## 🗺️ Parte 3: Configuração do Google Maps API

### 10. Criação e Configuração da API Key
1. Acesse [Google Cloud Console](https://console.cloud.google.com/google/maps-apis)
2. Crie uma conta ou faça login
3. Selecione ou crie um projeto
4. No menu, acesse **APIs e Serviços** → **Biblioteca**

### 11. Ativação das APIs Necessárias
Ative as seguintes APIs:
- **Maps JavaScript API**
- **Geocoding API**

### 12. Geração da Chave de API
1. Acesse **Credenciais** no menu lateral
2. Clique em **Criar Credenciais** → **Chave de API**
3. Copie a chave gerada
4. No sistema, vá até **Informações Gerais**
5. Cole a chave no campo **"API Key do Google Maps"** e salve

✅ **Checkpoint:** Integração com Google Maps concluída!

---

## 🚀 Finalização

Parabéns! Seu sistema está completamente configurado com:
- ✅ Banco de dados Supabase operacional
- ✅ Edge Functions deployadas
- ✅ Integração com Mercado Pago ativa
- ✅ Google Maps API configurada
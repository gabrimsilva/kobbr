# 🍕 Sistema de Delivery e Gestão

Sistema completo de delivery e gestão para estabelecimentos alimentícios, desenvolvido com React + TypeScript + Vite e Supabase.

## ✨ Funcionalidades

### Área do Cliente
- 📱 Cardápio digital responsivo
- 🛒 Carrinho de compras
- 🍕 Personalização de produtos (sabores, bordas, adicionais)
- 📍 Validação de área de entrega com taxa extra por distância
- 💳 **Pagamento via PIX com QR Code** (integração Mercado Pago)
- ⏱️ Timer de expiração PIX (10 minutos)
- 📦 Acompanhamento de pedido em tempo real
- ⭐ Sistema de avaliações

### Sistema Administrativo
- 📊 Dashboard com métricas
- 📋 Kanban de pedidos (drag & drop)
- 💳 PDV para vendas presenciais com validação de área
- 🎫 Sistema de comandas
- 📈 Relatórios e gráficos
- 🖨️ Impressão térmica automática
- ⏰ Gestão de pedidos PIX aguardando pagamento
- 🧹 Limpeza automática de pedidos expirados
- ⚙️ Configurações completas

## 🚀 Começando

### Pré-requisitos
- Node.js 18+
- Conta no Supabase

### Instalação

```bash
# Clonar repositório
git clone <url-do-repositorio>

# Instalar dependências
npm install

# Configurar variáveis de ambiente
cp .env.example .env
# Editar .env com suas credenciais do Supabase

# Executar em desenvolvimento
npm run dev
```

### Configuração do Banco de Dados

Execute o arquivo `BANCO-COMPLETO-PIZZARIA.sql` no SQL Editor do Supabase.

### Edge Functions

Deploy das edge functions necessárias:

```bash
# Criar pagamento PIX
supabase functions deploy create-pix-payment

# Verificar status do pagamento
supabase functions deploy check-payment-status

# Webhook do Mercado Pago
supabase functions deploy mercadopago-webhook

# Zerar pedidos (mover para histórico)
supabase functions deploy zerar-pedidos

# Cancelar pedidos PIX expirados
supabase functions deploy cancelar-pedidos-expirados
```

## 📖 Documentação

Consulte o arquivo **[DOCUMENTACAO.md](./DOCUMENTACAO.md)** para documentação completa do sistema, incluindo:
- Sistema de Pagamento PIX
- Taxa Extra por Distância (KM)
- Edge Functions
- Impressão Térmica
- Configurações
- Troubleshooting

## 🛠️ Scripts

```bash
npm run dev      # Servidor de desenvolvimento
npm run build    # Build de produção
npm run preview  # Preview do build
npm run lint     # Verificação de código
```

## 🏗️ Tecnologias

- **Frontend**: React 19, TypeScript, Vite
- **Estilização**: Tailwind CSS 4, Radix UI
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Realtime)
- **Gráficos**: Recharts
- **Impressão**: QZ Tray
- **Mapas**: Google Maps API

## 📁 Estrutura

```
src/
├── components/     # Componentes reutilizáveis
├── contexts/       # Contextos React
├── hooks/          # Hooks customizados
├── lib/            # Serviços e utilitários
├── pages/          # Páginas da aplicação
├── types/          # Definições de tipos
└── utils/          # Funções utilitárias
```

## 🔐 Variáveis de Ambiente

```env
# Supabase
VITE_SUPABASE_URL=sua_url_supabase
VITE_SUPABASE_ANON_KEY=sua_chave_anonima

# Mercado Pago (para pagamento PIX)
VITE_MERCADO_PAGO_PUBLIC_KEY=sua_public_key_mercado_pago
```

### Configuração do Pagamento PIX

Para configurar o pagamento via PIX:
1. Acesse **Configurações > Formas de Pagamento** no sistema
2. Ative o PIX e insira seu Access Token do Mercado Pago
3. Configure o webhook no painel do Mercado Pago (URL: `https://[seu-projeto].supabase.co/functions/v1/mercadopago-webhook`)

Consulte a seção "Sistema de Pagamento PIX" em [DOCUMENTACAO.md](./DOCUMENTACAO.md) para detalhes completos.

### Taxa Extra por Distância

Para configurar a taxa extra por km:
1. Acesse **Configurações > Entregas por KM** no sistema
2. Ative a funcionalidade
3. Configure o km inicial e os valores por km

Consulte a seção "Taxa Extra por Distância (KM)" em [DOCUMENTACAO.md](./DOCUMENTACAO.md) para detalhes completos.

## 📄 Licença

Este projeto é privado e de uso exclusivo.


## 👥 Gerenciamento de Usuários

O sistema possui dois tipos de usuários com diferentes níveis de acesso:

### Administradores (Tabela: `profile`)
- **Acesso**: Total ao sistema
- **Cadastro**: Direto no banco de dados (sem interface)
- **Documentação**: [ADMINISTRADORES.md](./ADMINISTRADORES.md)
- **Guia de Criação**: [CRIAR_PRIMEIRO_ADMIN.md](./CRIAR_PRIMEIRO_ADMIN.md)

### Funcionários (Tabela: `funcionarios`)
- **Acesso**: Baseado em função e permissões
- **Funções**: Atendente, Garçom, Entregador
- **Cadastro**: Via interface do sistema
- **Documentação**: [PERMISSOES_ACESSO.md](./PERMISSOES_ACESSO.md)

## 📚 Documentação Adicional

- [Segurança](./SEGURANCA.md) - Práticas de segurança implementadas
- [Segurança CSRF](./SEGURANCA_CSRF.md) - Proteção contra CSRF
- [Permissões de Acesso](./PERMISSOES_ACESSO.md) - Sistema de permissões
- [Guia de Teste de Permissões](./GUIA_TESTE_PERMISSOES.md) - Como testar permissões
- [Analytics](./RESUMO_ANALYTICS.md) - Sistema de analytics
- [Storage IA](./STORAGE_BUCKET_IA_UPLOADS.md) - Configuração de uploads com IA

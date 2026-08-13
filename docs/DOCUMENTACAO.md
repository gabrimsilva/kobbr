# Sistema de Delivery e Gestão - Documentação Completa

## Visão Geral

Sistema completo de delivery e gestão para estabelecimentos alimentícios (pizzarias, restaurantes, lanchonetes), desenvolvido com React + TypeScript + Vite e Supabase como backend.

## Tecnologias Utilizadas

- **Frontend**: React 19, TypeScript, Vite
- **Estilização**: Tailwind CSS 4, Radix UI, Lucide Icons
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Realtime)
- **Gráficos**: Recharts
- **Impressão**: QZ Tray (impressoras térmicas)
- **Mapas**: Google Maps API
- **PDF**: jsPDF + jspdf-autotable
- **Drag & Drop**: @hello-pangea/dnd

---

## Estrutura do Projeto

```
src/
├── components/          # Componentes reutilizáveis
│   ├── checkout/        # Componentes do checkout
│   ├── configuracoes/   # Componentes de configurações
│   ├── delivery/        # Componentes do delivery
│   ├── layout/          # Layout e navegação
│   ├── modals/          # Modais diversos
│   ├── pdv/             # Componentes do PDV
│   ├── pedidos/         # Componentes de pedidos (Kanban)
│   └── ui/              # Componentes UI base (shadcn)
├── contexts/            # Contextos React
├── hooks/               # Hooks customizados
├── lib/                 # Serviços e utilitários
├── pages/               # Páginas da aplicação
│   └── configuracoes/   # Páginas de configurações
├── types/               # Definições de tipos
└── utils/               # Funções utilitárias
```

---

## Módulos do Sistema

### 1. Área do Cliente (Delivery Online)

**Rota**: `/`

Cardápio digital para clientes realizarem pedidos online.

**Funcionalidades**:
- Visualização de produtos por categoria
- Filtro e busca de produtos
- Carrinho de compras
- Personalização de produtos (sabores, bordas, adicionais)
- Combos e promoções
- Status da loja (aberta/fechada)

### 2. Checkout

**Rota**: `/checkout`

Processo de finalização do pedido.

**Funcionalidades**:
- Dados do cliente (nome, telefone, email)
- Tipo de entrega (delivery ou retirada)
- Endereço de entrega com validação de área
- **Cálculo automático de taxa extra por distância (km)**
- Formas de pagamento configuráveis
- Cálculo automático de taxa de entrega
- Resumo do pedido com todas as taxas

### 3. Pagamento PIX

**Rota**: `/pagamento-pix/:pedidoId`

Página de pagamento via PIX com QR Code do Mercado Pago.

**Funcionalidades**:
- QR Code para pagamento
- Código PIX Copia e Cola
- Timer de expiração (10 minutos)
- Verificação automática de pagamento (polling a cada 3 segundos)
- Cancelamento automático ao expirar
- Redirecionamento após aprovação

### 4. Acompanhamento de Pedido

**Rota**: `/meu-pedido/:pedidoId`

Página para cliente acompanhar status do pedido em tempo real.

### 5. Meus Pedidos

**Rota**: `/meus-pedidos`

Consulta de pedidos anteriores pelo telefone do cliente.

### 6. Avaliações

**Rota**: `/avaliar`

Sistema de avaliação do estabelecimento com estrelas e badges.

---

## Sistema Administrativo

**Rota**: `/sistema` (requer autenticação)

### Dashboard

Visão geral com métricas:
- Pedidos pendentes
- Pedidos finalizados (Delivery e Comandas)
- Produtos cadastrados
- Avaliação média
- Produtos favoritos (excluindo cancelados)
- Filtros por período

### Aguardando Pagamento

**Rota**: `/sistema/aguardando-pagamento`

Gestão de pedidos PIX aguardando confirmação de pagamento.

**Funcionalidades**:
- Lista de pedidos aguardando há X minutos
- Verificação manual de status do pagamento no Mercado Pago
- Botão "Limpar Expirados" para cancelar pedidos com mais de 10 minutos
- Atualização automática a cada 10 segundos
- Detalhes completos do pedido em modal
- Busca por nome, telefone ou ID do pedido

### Pedidos (Kanban)

Gerenciamento de pedidos em formato Kanban com colunas de status:
- Pedido criado
- Confirmado
- Preparando
- Pronto
- Saiu para entrega
- Entregue/Retirado

**Funcionalidades**:
- Drag & drop entre colunas
- Atualização em tempo real (Supabase Realtime)
- Impressão de pedidos
- Cancelamento com motivo e extorno
- Busca e filtros

### Histórico

Consulta de pedidos finalizados e cancelados com filtros por período.

### PDV (Ponto de Venda)

Sistema de vendas presenciais com:
- Seleção rápida de produtos
- Personalização completa
- **Validação de área de entrega com taxa extra por km**
- Busca automática de cliente por telefone
- Consulta de CEP automática
- Múltiplas formas de pagamento
- Impressão de comprovante

### Comandas

Sistema de comandas para atendimento em mesas:
- 20 comandas numeradas
- Adição de produtos com personalização
- Finalização com forma de pagamento
- Histórico de comandas

### Métricas

Relatórios e gráficos detalhados:
- Vendas por período (Delivery e Comandas)
- Produtos mais vendidos
- Vendas por categoria
- Formas de pagamento
- Status dos pedidos (incluindo cancelados)
- Tipos de entrega
- Locais de entrega
- Cancelamentos (total, valor, motivos)
- Exportação em PDF

### Produtos

Cadastro e gerenciamento de produtos:
- Nome, descrição, preço
- Categoria
- Imagem (upload para Supabase Storage)
- Preço promocional
- Sabores disponíveis
- Tamanhos com preços diferentes
- Status ativo/inativo

### Categorias

Gerenciamento de categorias com opções:
- Tem sabores
- Tem bordas
- Tem tamanhos
- Tem adicionais

### Sabores

Cadastro de sabores por categoria:
- Sabores normais e premium
- Valor adicional para premium
- Categorias de sabor (tradicional, especiais, nobres, doces)

### Adicionais

Extras por categoria com nome e valor.

### Estoque

Controle básico de estoque:
- Nome, descrição, validade
- Quantidade atual e mínima
- Alertas de estoque baixo

### Funcionários

Cadastro de funcionários:
- Funções: Atendente, Garçom, Entregador
- Criação de conta de acesso ao sistema

---

## Configurações

### Gerais
- Nome do estabelecimento
- Telefone, email
- Endereço completo
- Logo e favicon

### Entrega
- Taxa de entrega base
- **Taxa extra por distância (km)**
  - Ativar/desativar funcionalidade
  - Km inicial para cobrar taxa extra
  - Configuração de valores por km específico
  - Arredondamento especial (≤0.5 baixo, >0.5 cima)
- Tempo estimado
- Área de entrega (raio em metros)
- Mapa interativo com Google Maps
- Validação automática de endereço

### Horário de Funcionamento
- Horários por dia da semana
- Status aberto/fechado automático

### Formas de Pagamento
- Ativar/desativar formas de pagamento
- Dinheiro, Cartão Crédito/Débito, PIX, VR, VA

### Checkout
- Campos obrigatórios
- Mensagens personalizadas

### Visuais
- Cores do tema
- Personalização visual

### Notificações
- Integração com WhatsApp
- Notificações de novos pedidos

### Impressão
- Configuração do QZ Tray
- Impressora padrão
- Densidade de impressão
- Impressão automática de pedidos

### SEO e Compartilhamento
- Meta tags para Google
- Open Graph (Facebook, WhatsApp)
- Twitter Cards
- Dados estruturados (Schema.org)

---

## Banco de Dados (Supabase)

### Tabelas Principais

| Tabela | Descrição |
|--------|-----------|
| `categorias` | Categorias de produtos |
| `produtos` | Produtos do cardápio |
| `sabores` | Sabores disponíveis |
| `adicionais` | Adicionais por categoria |
| `tamanhos` | Tamanhos de produtos |
| `combos` | Combos promocionais |
| `pedidos` | Pedidos ativos (inclui campos PIX e taxa_extra_km) |
| `historico_geral` | Pedidos finalizados (inclui taxa_extra_km) |
| `comandas` | Comandas ativas |
| `historico_comandas` | Comandas finalizadas |
| `funcionarios` | Funcionários cadastrados |
| `estoque` | Itens do estoque |
| `avaliacoes` | Avaliações de clientes |
| `configuracoes` | Configurações do sistema |
| `seo_config` | Configurações de SEO |
| `clientes` | Dados de clientes |

### Campos de Cancelamento (pedidos/historico_geral)

- `cancelado` (boolean)
- `motivo_cancelamento` (text)
- `requer_extorno` (boolean)
- `valor_extorno` (numeric)
- `forma_pagamento_extorno` (text)
- `cancelado_em` (timestamp)
- `cancelado_por` (uuid)

### Campos de Pagamento PIX (pedidos)

- `mercado_pago_payment_id` (text) - ID do pagamento no Mercado Pago
- `mercado_pago_status` (text) - Status: pending, approved, rejected, etc
- `mercado_pago_date_approved` (timestamp) - Data de aprovação

### Campo de Taxa Extra (pedidos/historico_geral)

- `taxa_extra_km` (decimal) - Taxa extra cobrada por distância em km

---

## Edge Functions (Supabase)

O sistema utiliza 5 edge functions para funcionalidades específicas:

### 1. create-pix-payment
**Função**: Criar pagamento PIX no Mercado Pago  
**Autenticação**: Requer JWT (verify_jwt: true)  
**Uso**: Chamada durante o checkout quando cliente escolhe PIX

**Funcionalidades**:
- Cria pagamento no Mercado Pago
- Gera QR Code e código Copia e Cola
- Salva payment_id no pedido
- Inclui verificação de segurança (não cria novo PIX se pedido já pago)

### 2. check-payment-status
**Função**: Verificar status de pagamento PIX  
**Autenticação**: Requer JWT (verify_jwt: true)  
**Uso**: Polling automático e verificação manual

**Funcionalidades**:
- Consulta status no Mercado Pago
- Retorna dados do QR Code se ainda pendente
- Usado para recuperar pagamentos existentes

### 3. mercadopago-webhook
**Função**: Receber notificações do Mercado Pago  
**Autenticação**: Pública (verify_jwt: false)  
**Uso**: Webhook configurado no Mercado Pago

**Funcionalidades**:
- Recebe notificações de mudança de status
- Atualiza pedido automaticamente
- Valida assinatura (se configurada)
- Adiciona ao histórico

### 4. zerar-pedidos
**Função**: Mover pedidos para histórico geral  
**Autenticação**: Requer JWT (verify_jwt: true)  
**Uso**: Botão "Zerar Pedidos" no sistema

**Funcionalidades**:
- Move todos os pedidos ativos para histórico_geral
- Atualiza status para "Finalizado"
- Copia todos os campos incluindo taxa_extra_km
- Limpa tabela de pedidos

### 5. cancelar-pedidos-expirados
**Função**: Cancelar pedidos PIX com mais de 10 minutos  
**Autenticação**: Pública (verify_jwt: false)  
**Uso**: Botão "Limpar Expirados" em Aguardando Pagamento

**Funcionalidades**:
- Busca pedidos PIX aguardando há mais de 10 minutos
- Cancela automaticamente
- Adiciona motivo de cancelamento
- Registra no histórico

**Deploy**:
```bash
supabase functions deploy create-pix-payment
supabase functions deploy check-payment-status
supabase functions deploy mercadopago-webhook
supabase functions deploy zerar-pedidos
supabase functions deploy cancelar-pedidos-expirados
```

---

## Impressão Térmica (QZ Tray)

### Requisitos
- QZ Tray instalado no computador
- Certificado digital configurado
- Impressora térmica conectada

### Configuração
1. Instalar QZ Tray
2. Configurar certificado (ver pasta `QZ Tray Demo Cert`)
3. Ativar "Usar QZ Tray" nas configurações
4. Selecionar impressora padrão
5. Ativar impressão automática (opcional)

### Formato da Impressão
- Dados do estabelecimento
- Código do pedido
- Dados do cliente
- Itens com detalhes
- Valores (subtotal, taxa de entrega, **taxa extra por km**, total)
- Forma de pagamento e status
- Data/hora

---

## Taxa Extra por Distância (KM)

### Conceito
Sistema que cobra uma taxa adicional baseada na distância entre o estabelecimento e o endereço de entrega do cliente.

### Configuração
1. Acesse **Configurações > Entregas por KM**
2. Ative a funcionalidade
3. Defina o km inicial (ex: 5km - não cobra extra até 5km)
4. Configure valores por km específico:
   - 3km = R$ 2,00
   - 4km = R$ 3,00
   - 5km = R$ 4,00
   - etc.

### Regras de Arredondamento
- Distância ≤ 0.5 km: arredonda para baixo (3.5km → 3km)
- Distância > 0.5 km: arredonda para cima (4.6km → 5km)

### Funcionamento
1. Cliente preenche endereço no checkout ou PDV
2. Sistema calcula distância via Google Maps
3. Aplica arredondamento
4. Busca valor configurado para aquele km
5. Se não encontrar, usa o valor do km mais próximo abaixo
6. Adiciona ao total do pedido

### Exibição
A taxa extra é mostrada separadamente em:
- Checkout (resumo do pedido)
- PDV (modal de cliente e resumo)
- Kanban (card do pedido)
- Histórico
- Impressão térmica
- Mensagem WhatsApp
- Página "Meu Pedido"

### Banco de Dados
- Campo `taxa_extra_km` nas tabelas `pedidos` e `historico_geral`
- Configurações em `configuracoes`:
  - `taxa_extra_km_ativa` (boolean)
  - `taxa_extra_km_inicial` (número)
  - `taxa_extra_km_faixas` (JSON array)

---

## Área de Entrega (Google Maps)

### Configuração
1. Preencher endereço do estabelecimento
2. Ajustar raio de entrega no mapa
3. Salvar configurações

### Validação
- Automática durante checkout
- Calcula distância entre loja e cliente
- Bloqueia pedidos fora da área
- Fail-safe: permite pedido se API falhar

---

## Variáveis de Ambiente

```env
VITE_SUPABASE_URL=sua_url_supabase
VITE_SUPABASE_ANON_KEY=sua_chave_anonima
VITE_APP_NAME=Nome do Estabelecimento
VITE_APP_VERSION=1.0.0
```

---

## Scripts Disponíveis

```bash
npm run dev      # Servidor de desenvolvimento
npm run build    # Build de produção
npm run preview  # Preview do build
npm run lint     # Verificação de código
```

---

## Arquivos SQL

| Arquivo | Descrição |
|---------|-----------|
| `BANCO-COMPLETO-PIZZARIA.sql` | **Setup completo atualizado** (usar este) |

**Recomendação**: Use `BANCO-COMPLETO-PIZZARIA.sql` para novos projetos, pois inclui:
- Todas as tabelas e índices
- Campos de pagamento PIX
- Campo taxa_extra_km
- Configurações de taxa extra
- Políticas RLS
- Storage buckets
- Documentação das edge functions

---

## Sistema de Pagamento PIX

### Fluxo Completo

1. **Cliente escolhe PIX no checkout**
   - Sistema cria pedido com status "Aguardando pagamento"
   - Chama edge function `create-pix-payment`
   - Mercado Pago gera QR Code e código Copia e Cola

2. **Página de Pagamento**
   - Exibe QR Code e código para copiar
   - Timer de 10 minutos (600 segundos)
   - Polling a cada 3 segundos para verificar status
   - Botão para verificar status manualmente

3. **Cliente paga via PIX**
   - Mercado Pago detecta pagamento
   - Envia notificação via webhook
   - Edge function `mercadopago-webhook` atualiza pedido
   - Status muda para "Pedido criado"

4. **Redirecionamento**
   - Cliente é redirecionado para `/meu-pedido/:pedidoId`
   - Pode acompanhar preparação e entrega

### Expiração (10 minutos)

**Cancelamento Automático no Frontend**:
- Timer na página de pagamento
- Ao expirar, cancela pedido automaticamente
- Exibe mensagem de tempo expirado

**Limpeza Manual (Admin)**:
- Página "Aguardando Pagamento"
- Botão "Limpar Expirados"
- Cancela pedidos com mais de 10 minutos
- Edge function `cancelar-pedidos-expirados`

### Segurança

**Verificações Implementadas**:
1. Não cria novo PIX se pedido já foi pago
2. Não cria novo PIX se status diferente de "Aguardando pagamento"
3. Validação de assinatura no webhook (opcional)
4. Idempotência nas requisições ao Mercado Pago

### Configuração

**Variáveis Necessárias**:
- `mercado_pago_access_token` - Access Token do Mercado Pago
- `mercado_pago_webhook_secret` - Secret para validar webhook (opcional)

**Webhook URL**:
```
https://[seu-projeto].supabase.co/functions/v1/mercadopago-webhook
```

Configure no painel do Mercado Pago em:
- Suas integrações > Webhooks > Adicionar webhook

**Tópicos do Webhook**:
- `payment` (obrigatório)



---

## Fluxos Principais

### Fluxo de Pedido (Delivery)
```
Cliente acessa cardápio → Adiciona produtos → Checkout → 
Preenche dados → Confirma pedido → Acompanha status
```

### Fluxo de Pedido (Kanban)
```
Pedido criado → Confirmado → Preparando → Pronto → 
Saiu para entrega → Entregue → Histórico
```

### Fluxo de Comanda
```
Seleciona comanda → Adiciona produtos → Finaliza → 
Seleciona pagamento → Histórico
```

### Fluxo de Cancelamento
```
Clica cancelar → Informa motivo → Define extorno → 
Confirma → Pedido marcado como cancelado
```

---

## Métricas e Relatórios

### Pedidos Cancelados
- Não contabilizados em vendas
- Não contabilizados em produtos favoritos
- Exibidos no gráfico de status
- Aba específica em Métricas

### Relatório PDF
- Resumo de vendas
- Produtos mais vendidos
- Formas de pagamento
- Cancelamentos

---

## Responsividade

O sistema é totalmente responsivo:
- **Desktop**: Layout completo com sidebar
- **Mobile**: Menu hambúrguer, cards adaptados
- **Modais**: Fullscreen em mobile

---

## Segurança

- Autenticação via Supabase Auth
- Row Level Security (RLS) em todas as tabelas
- Rotas protegidas no frontend
- Validação de dados no backend

---

---

## Suporte

Para dúvidas ou problemas:
1. Verificar logs do console do navegador
2. Verificar logs do Supabase (Edge Functions)
3. Verificar logs do Mercado Pago (para PIX)
4. Consultar documentação das APIs utilizadas
5. Verificar configurações no banco de dados (tabela `configuracoes`)

### Troubleshooting Comum

**PIX não gera QR Code**:
- Verificar se Access Token está configurado
- Verificar logs da edge function `create-pix-payment`
- Verificar se pedido já foi pago

**Impressão não funciona**:
- Verificar se QZ Tray está rodando
- Verificar certificado digital
- Testar impressão manual primeiro
- Verificar nome da impressora nas configurações

**Taxa extra não aparece**:
- Verificar se funcionalidade está ativa
- Verificar se km inicial está configurado
- Verificar se há valores configurados para os km
- Verificar se endereço está completo

**Pedidos não atualizam**:
- Verificar conexão com Supabase
- Verificar se Realtime está ativo
- Verificar políticas RLS
- Recarregar página

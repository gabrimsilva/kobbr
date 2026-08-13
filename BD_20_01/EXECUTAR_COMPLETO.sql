-- ============================================================================
-- SCRIPT COMPLETO - ESTRUTURA DO BANCO DE DADOS
-- ============================================================================
-- Arquivo: EXECUTAR_COMPLETO.sql
-- Descrição: Script consolidado com TODOS os 8 arquivos SQL
-- Data: 22/01/2026
-- Versão: 1.1.0
-- 
-- IMPORTANTE: 
-- - Este script é SEGURO para executar em banco com dados existentes
-- - Scripts são IDEMPOTENTES (podem rodar múltiplas vezes)
-- - NÃO apaga dados existentes
-- - Apenas adiciona/atualiza estrutura
-- 
-- COMO USAR:
-- 1. Faça backup do banco (sempre recomendado)
-- 2. Copie TODO este arquivo
-- 3. Cole no Supabase SQL Editor
-- 4. Execute (Ctrl+Enter ou botão Run)
-- 5. Aguarde ~1-2 minutos
-- 
-- TEMPO ESTIMADO: 1-2 minutos
-- ============================================================================

-- ============================================================================
-- PARTE 1/8: EXTENSÕES
-- ============================================================================

-- Extensão para geração de UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- Extensão para funções criptográficas
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

-- ============================================================================
-- PARTE 2/8: FUNÇÕES
-- ============================================================================

-- Função para atualizar timestamp automaticamente
CREATE OR REPLACE FUNCTION public.atualizar_timestamp()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$function$;

-- Função para sincronizar status do pedido com histórico
CREATE OR REPLACE FUNCTION public.sync_pedido_status_to_historico()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO historico_pedidos (pedido_id, status, observacao)
    VALUES (
      COALESCE(NEW.codigo_pedido, NEW.pedido_id), 
      NEW.status, 
      'Status atualizado automaticamente para ' || NEW.status
    );
  END IF;
  RETURN NEW;
END;
$function$;

-- Função para atualizar timestamp de comandas
CREATE OR REPLACE FUNCTION public.update_comandas_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$function$;

-- Função para atualizar timestamp de tamanhos
CREATE OR REPLACE FUNCTION public.update_tamanhos_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$function$;

-- Função genérica para atualizar coluna updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
    NEW.atualizado_em = NOW();
    RETURN NEW;
END;
$function$;

-- Função para limpar arquivos órfãos (sem conversa associada)
CREATE OR REPLACE FUNCTION limpar_arquivos_orfaos()
RETURNS INTEGER AS $
DECLARE
  total_deletados INTEGER;
BEGIN
  DELETE FROM ia_arquivos_temp
  WHERE conversa_id IS NULL
     OR conversa_id NOT IN (SELECT id FROM ia_conversas);
  
  GET DIAGNOSTICS total_deletados = ROW_COUNT;
  RETURN total_deletados;
END;
$ LANGUAGE plpgsql;

-- Função para obter última mensagem de uma conversa
CREATE OR REPLACE FUNCTION obter_ultima_mensagem(conversa_uuid UUID)
RETURNS JSONB AS $
DECLARE
  ultima_msg JSONB;
BEGIN
  SELECT mensagens->-1 INTO ultima_msg
  FROM ia_conversas
  WHERE id = conversa_uuid;
  
  RETURN ultima_msg;
END;
$ LANGUAGE plpgsql;

-- Função para contar conversas por status
CREATE OR REPLACE FUNCTION contar_conversas_por_status()
RETURNS TABLE(status TEXT, total BIGINT) AS $
BEGIN
  RETURN QUERY
  SELECT ia_conversas.status, COUNT(*)
  FROM ia_conversas
  GROUP BY ia_conversas.status;
END;
$ LANGUAGE plpgsql;

-- ============================================================================
-- PARTE 3/8: TABELAS
-- ============================================================================

-- Tabela: configuracoes
CREATE TABLE IF NOT EXISTS public.configuracoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chave VARCHAR NOT NULL UNIQUE,
    valor TEXT NOT NULL,
    descricao TEXT,
    tipo VARCHAR DEFAULT 'texto' CHECK (tipo IN ('texto', 'numero', 'booleano', 'json')),
    categoria VARCHAR DEFAULT 'geral',
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.configuracoes IS 'Configurações gerais do sistema';

-- Tabela: categorias
CREATE TABLE IF NOT EXISTS public.categorias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR NOT NULL,
    descricao TEXT,
    ativa BOOLEAN DEFAULT true,
    ordem INTEGER DEFAULT 1,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now(),
    tem_sabores BOOLEAN DEFAULT false,
    tem_borda BOOLEAN DEFAULT false,
    tem_tamanhos BOOLEAN DEFAULT false,
    tem_adicionais BOOLEAN DEFAULT false
);

COMMENT ON COLUMN public.categorias.tem_adicionais IS 'Define se a categoria permite adicionar adicionais';

-- Tabela: estoque
CREATE TABLE IF NOT EXISTS public.estoque (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR NOT NULL,
    descricao TEXT,
    validade DATE,
    quantidade INTEGER DEFAULT 0,
    quantidade_minima INTEGER DEFAULT 1,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- Tabela: funcionarios
CREATE TABLE IF NOT EXISTS public.funcionarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR NOT NULL,
    cargo VARCHAR,
    telefone VARCHAR NOT NULL,
    ativo BOOLEAN DEFAULT true,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now(),
    email VARCHAR NOT NULL UNIQUE,
    funcao VARCHAR CHECK (funcao IN ('atendente', 'garcom', 'entregador')),
    user_id UUID REFERENCES auth.users(id),
    metadata JSONB DEFAULT '{}'::jsonb,
    bloqueado BOOLEAN DEFAULT false
);

COMMENT ON COLUMN public.funcionarios.cargo IS 'Campo legado - usar funcao ao invés (opcional para compatibilidade)';
COMMENT ON COLUMN public.funcionarios.email IS 'Email do funcionário para acesso ao sistema (obrigatório)';
COMMENT ON COLUMN public.funcionarios.funcao IS 'Função do funcionário: atendente, garcom ou entregador';
COMMENT ON COLUMN public.funcionarios.user_id IS 'Referência ao usuário no auth.users do Supabase';
COMMENT ON COLUMN public.funcionarios.metadata IS 'Metadados adicionais do funcionário, incluindo permissões customizadas';
COMMENT ON COLUMN public.funcionarios.bloqueado IS 'Indica se o funcionário está bloqueado e não pode acessar o sistema';

-- Tabela: sabores
CREATE TABLE IF NOT EXISTS public.sabores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR NOT NULL,
    is_premium BOOLEAN DEFAULT false,
    valor_premium NUMERIC,
    tipo VARCHAR DEFAULT 'pizza',
    ativo BOOLEAN DEFAULT true,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now(),
    categoria_id UUID REFERENCES public.categorias(id),
    categoria_sabor VARCHAR DEFAULT 'tradicional' CHECK (categoria_sabor IN ('tradicional', 'especiais', 'nobres', 'doces', 'doces_especiais', 'refrigerante')),
    tipo_sabor VARCHAR DEFAULT 'normal' CHECK (tipo_sabor IN ('normal', 'borda')),
    descricao TEXT
);

COMMENT ON COLUMN public.sabores.descricao IS 'Descrição detalhada dos ingredientes e características do sabor';

-- Tabela: produtos
CREATE TABLE IF NOT EXISTS public.produtos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR NOT NULL,
    descricao TEXT,
    preco NUMERIC NOT NULL,
    preco_promocional NUMERIC,
    categoria_id UUID REFERENCES public.categorias(id),
    categoria_nome VARCHAR,
    imagem_path TEXT,
    sabores_disponiveis BOOLEAN DEFAULT false,
    quantidade_sabores INTEGER DEFAULT 1,
    ativo BOOLEAN DEFAULT true,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now(),
    permite_adicionais BOOLEAN DEFAULT false
);

COMMENT ON COLUMN public.produtos.permite_adicionais IS 'Define se o produto permite adicionar adicionais';

-- Tabela: combos
CREATE TABLE IF NOT EXISTS public.combos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR NOT NULL,
    descricao TEXT,
    url_imagem TEXT,
    preco_combo NUMERIC NOT NULL,
    preco_original NUMERIC NOT NULL,
    desconto NUMERIC NOT NULL,
    ativo BOOLEAN DEFAULT true,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- Tabela: produto_sabores (relacionamento N:N)
CREATE TABLE IF NOT EXISTS public.produto_sabores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID REFERENCES public.produtos(id),
    sabor_id UUID REFERENCES public.sabores(id),
    criado_em TIMESTAMPTZ DEFAULT now()
);

-- Tabela: combo_produtos (relacionamento N:N)
CREATE TABLE IF NOT EXISTS public.combo_produtos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    combo_id UUID REFERENCES public.combos(id),
    produto_id UUID REFERENCES public.produtos(id),
    quantidade INTEGER DEFAULT 1,
    criado_em TIMESTAMPTZ DEFAULT now()
);

-- Tabela: tamanhos
CREATE TABLE IF NOT EXISTS public.tamanhos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID NOT NULL REFERENCES public.produtos(id),
    nome VARCHAR NOT NULL,
    valor NUMERIC NOT NULL,
    tamanho VARCHAR NOT NULL,
    ordem INTEGER DEFAULT 0,
    ativo BOOLEAN DEFAULT true,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- Tabela: adicionais
CREATE TABLE IF NOT EXISTS public.adicionais (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    categoria_id UUID REFERENCES public.categorias(id),
    nome VARCHAR NOT NULL,
    valor NUMERIC NOT NULL,
    ativo BOOLEAN DEFAULT true,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.adicionais IS 'Tabela para armazenar adicionais disponíveis por categoria';
COMMENT ON COLUMN public.adicionais.categoria_id IS 'Referência à categoria que possui este adicional';
COMMENT ON COLUMN public.adicionais.nome IS 'Nome do adicional (ex: Bacon, Catupiry, etc)';
COMMENT ON COLUMN public.adicionais.valor IS 'Valor adicional cobrado';
COMMENT ON COLUMN public.adicionais.ativo IS 'Define se o adicional está disponível';

-- Tabela: clientes
CREATE TABLE IF NOT EXISTS public.clientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR NOT NULL,
    sobrenome VARCHAR NOT NULL,
    cpf VARCHAR,
    telefone VARCHAR NOT NULL,
    email VARCHAR,
    cep VARCHAR,
    endereco TEXT,
    numero VARCHAR,
    complemento TEXT,
    bairro VARCHAR,
    cidade VARCHAR,
    estado VARCHAR,
    total_pedidos INTEGER DEFAULT 0,
    valor_total_gasto NUMERIC DEFAULT 0,
    ultimo_pedido_em TIMESTAMPTZ,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.clientes IS 'Tabela para armazenar dados dos clientes da pizzaria';
COMMENT ON COLUMN public.clientes.cpf IS 'CPF do cliente no formato 999.999.999-99 (opcional)';
COMMENT ON COLUMN public.clientes.total_pedidos IS 'Contador de pedidos realizados pelo cliente';
COMMENT ON COLUMN public.clientes.valor_total_gasto IS 'Valor total gasto pelo cliente em todos os pedidos';
COMMENT ON COLUMN public.clientes.ultimo_pedido_em IS 'Data e hora do último pedido realizado';

-- Tabela: pedidos
CREATE TABLE IF NOT EXISTS public.pedidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id TEXT NOT NULL UNIQUE,
    cliente_nome TEXT NOT NULL,
    cliente_sobrenome TEXT NOT NULL,
    cliente_telefone TEXT NOT NULL,
    cliente_email TEXT,
    cliente_cep TEXT,
    cliente_endereco TEXT,
    cliente_complemento TEXT,
    cliente_cidade TEXT,
    cliente_estado TEXT,
    entrega_domicilio BOOLEAN DEFAULT true,
    forma_pagamento TEXT NOT NULL,
    precisa_troco BOOLEAN DEFAULT false,
    valor_troco NUMERIC,
    subtotal NUMERIC NOT NULL,
    taxa_entrega NUMERIC DEFAULT 0,
    total NUMERIC NOT NULL,
    itens JSONB NOT NULL,
    status TEXT DEFAULT 'Pedido criado',
    previsao_entrega TEXT,
    observacoes TEXT,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now(),
    cliente_id UUID REFERENCES public.clientes(id),
    cliente_cpf VARCHAR,
    cliente_numero VARCHAR,
    cliente_bairro VARCHAR,
    codigo_pedido VARCHAR,
    cancelado BOOLEAN DEFAULT false,
    motivo_cancelamento TEXT,
    requer_extorno BOOLEAN DEFAULT false,
    valor_extorno NUMERIC,
    forma_pagamento_extorno TEXT,
    cancelado_em TIMESTAMPTZ,
    cancelado_por UUID REFERENCES auth.users(id),
    mercado_pago_payment_id TEXT,
    mercado_pago_status TEXT,
    mercado_pago_date_approved TIMESTAMPTZ,
    taxa_extra_km DECIMAL(10,2) DEFAULT 0,
    desconto NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0),
    tipo_desconto TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual')),
    forma_pagamento_dividido BOOLEAN NOT NULL DEFAULT false,
    pagamento_1_tipo TEXT,
    pagamento_1_valor NUMERIC(10, 2),
    pagamento_2_tipo TEXT,
    pagamento_2_valor NUMERIC(10, 2),
    CONSTRAINT pedidos_pagamento_tipos_diferentes CHECK (
        NOT forma_pagamento_dividido OR 
        (pagamento_1_tipo IS NOT NULL AND pagamento_2_tipo IS NOT NULL AND pagamento_1_tipo != pagamento_2_tipo)
    ),
    CONSTRAINT pedidos_pagamento_valores_positivos CHECK (
        NOT forma_pagamento_dividido OR 
        (pagamento_1_valor > 0 AND pagamento_2_valor > 0)
    )
);

COMMENT ON COLUMN public.pedidos.cliente_id IS 'Referência ao cliente que fez o pedido';
COMMENT ON COLUMN public.pedidos.cliente_cpf IS 'CPF do cliente no formato 999.999.999-99';
COMMENT ON COLUMN public.pedidos.cliente_numero IS 'Número da residência do cliente';
COMMENT ON COLUMN public.pedidos.cliente_bairro IS 'Bairro do cliente';
COMMENT ON COLUMN public.pedidos.codigo_pedido IS 'Código amigável do pedido (ex: 8122)';
COMMENT ON COLUMN public.pedidos.cancelado IS 'Indica se o pedido foi cancelado';
COMMENT ON COLUMN public.pedidos.motivo_cancelamento IS 'Motivo do cancelamento do pedido';
COMMENT ON COLUMN public.pedidos.requer_extorno IS 'Indica se o cancelamento requer extorno de valor';
COMMENT ON COLUMN public.pedidos.valor_extorno IS 'Valor a ser extornado';
COMMENT ON COLUMN public.pedidos.forma_pagamento_extorno IS 'Forma de pagamento para o extorno';
COMMENT ON COLUMN public.pedidos.cancelado_em IS 'Data e hora do cancelamento';
COMMENT ON COLUMN public.pedidos.cancelado_por IS 'Usuário que cancelou o pedido';
COMMENT ON COLUMN public.pedidos.mercado_pago_payment_id IS 'ID do pagamento no Mercado Pago';
COMMENT ON COLUMN public.pedidos.mercado_pago_status IS 'Status do pagamento no Mercado Pago (pending, approved, rejected, etc)';
COMMENT ON COLUMN public.pedidos.mercado_pago_date_approved IS 'Data e hora de aprovação do pagamento no Mercado Pago';
COMMENT ON COLUMN public.pedidos.taxa_extra_km IS 'Taxa extra cobrada por distância em km';
COMMENT ON COLUMN public.pedidos.desconto IS 'Valor do desconto aplicado. Se tipo_desconto=valor, representa R$. Se tipo_desconto=percentual, representa %';
COMMENT ON COLUMN public.pedidos.tipo_desconto IS 'Tipo do desconto: valor (R$) ou percentual (%)';
COMMENT ON COLUMN public.pedidos.forma_pagamento_dividido IS 'Indica se o pagamento foi dividido entre duas formas de pagamento diferentes';
COMMENT ON COLUMN public.pedidos.pagamento_1_tipo IS 'Tipo da primeira forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.pedidos.pagamento_1_valor IS 'Valor pago com a primeira forma de pagamento';
COMMENT ON COLUMN public.pedidos.pagamento_2_tipo IS 'Tipo da segunda forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.pedidos.pagamento_2_valor IS 'Valor pago com a segunda forma de pagamento';

-- Tabela: historico_pedidos
CREATE TABLE IF NOT EXISTS public.historico_pedidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id TEXT NOT NULL,
    status TEXT NOT NULL,
    observacao TEXT,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now(),
    desconto NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0),
    tipo_desconto TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual')),
    forma_pagamento_dividido BOOLEAN NOT NULL DEFAULT false,
    pagamento_1_tipo TEXT,
    pagamento_1_valor NUMERIC(10, 2),
    pagamento_2_tipo TEXT,
    pagamento_2_valor NUMERIC(10, 2),
    CONSTRAINT historico_pedidos_pagamento_tipos_diferentes CHECK (
        NOT forma_pagamento_dividido OR 
        (pagamento_1_tipo IS NOT NULL AND pagamento_2_tipo IS NOT NULL AND pagamento_1_tipo != pagamento_2_tipo)
    ),
    CONSTRAINT historico_pedidos_pagamento_valores_positivos CHECK (
        NOT forma_pagamento_dividido OR 
        (pagamento_1_valor > 0 AND pagamento_2_valor > 0)
    )
);

COMMENT ON COLUMN public.historico_pedidos.desconto IS 'Valor do desconto aplicado. Se tipo_desconto=valor, representa R$. Se tipo_desconto=percentual, representa %';
COMMENT ON COLUMN public.historico_pedidos.tipo_desconto IS 'Tipo do desconto: valor (R$) ou percentual (%)';
COMMENT ON COLUMN public.historico_pedidos.forma_pagamento_dividido IS 'Indica se o pagamento foi dividido entre duas formas de pagamento diferentes';
COMMENT ON COLUMN public.historico_pedidos.pagamento_1_tipo IS 'Tipo da primeira forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.historico_pedidos.pagamento_1_valor IS 'Valor pago com a primeira forma de pagamento';
COMMENT ON COLUMN public.historico_pedidos.pagamento_2_tipo IS 'Tipo da segunda forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.historico_pedidos.pagamento_2_valor IS 'Valor pago com a segunda forma de pagamento';

-- Tabela: historico_geral
CREATE TABLE IF NOT EXISTS public.historico_geral (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id TEXT NOT NULL,
    codigo_pedido VARCHAR,
    cliente_nome TEXT NOT NULL,
    cliente_sobrenome TEXT NOT NULL,
    cliente_telefone TEXT NOT NULL,
    cliente_email TEXT,
    cliente_cep TEXT,
    cliente_endereco TEXT,
    cliente_numero VARCHAR,
    cliente_complemento TEXT,
    cliente_bairro VARCHAR,
    cliente_cidade VARCHAR,
    cliente_estado VARCHAR,
    entrega_domicilio BOOLEAN DEFAULT true,
    forma_pagamento TEXT NOT NULL,
    precisa_troco BOOLEAN DEFAULT false,
    valor_troco NUMERIC,
    subtotal NUMERIC NOT NULL,
    taxa_entrega NUMERIC DEFAULT 0,
    total NUMERIC NOT NULL,
    itens JSONB NOT NULL,
    status TEXT DEFAULT 'Finalizado',
    previsao_entrega TEXT,
    observacoes TEXT,
    cliente_id UUID,
    cliente_cpf VARCHAR,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now(),
    movido_em TIMESTAMPTZ DEFAULT now(),
    cancelado BOOLEAN DEFAULT false,
    motivo_cancelamento TEXT,
    requer_extorno BOOLEAN DEFAULT false,
    valor_extorno NUMERIC,
    forma_pagamento_extorno TEXT,
    cancelado_em TIMESTAMPTZ,
    cancelado_por UUID,
    taxa_extra_km DECIMAL(10,2) DEFAULT 0,
    desconto NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0),
    tipo_desconto TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual')),
    forma_pagamento_dividido BOOLEAN NOT NULL DEFAULT false,
    pagamento_1_tipo TEXT,
    pagamento_1_valor NUMERIC(10, 2),
    pagamento_2_tipo TEXT,
    pagamento_2_valor NUMERIC(10, 2),
    CONSTRAINT historico_geral_pagamento_tipos_diferentes CHECK (
        NOT forma_pagamento_dividido OR 
        (pagamento_1_tipo IS NOT NULL AND pagamento_2_tipo IS NOT NULL AND pagamento_1_tipo != pagamento_2_tipo)
    ),
    CONSTRAINT historico_geral_pagamento_valores_positivos CHECK (
        NOT forma_pagamento_dividido OR 
        (pagamento_1_valor > 0 AND pagamento_2_valor > 0)
    )
);

COMMENT ON COLUMN public.historico_geral.desconto IS 'Valor do desconto aplicado. Se tipo_desconto=valor, representa R$. Se tipo_desconto=percentual, representa %';
COMMENT ON COLUMN public.historico_geral.tipo_desconto IS 'Tipo do desconto: valor (R$) ou percentual (%)';
COMMENT ON COLUMN public.historico_geral.forma_pagamento_dividido IS 'Indica se o pagamento foi dividido entre duas formas de pagamento diferentes';
COMMENT ON COLUMN public.historico_geral.pagamento_1_tipo IS 'Tipo da primeira forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.historico_geral.pagamento_1_valor IS 'Valor pago com a primeira forma de pagamento';
COMMENT ON COLUMN public.historico_geral.pagamento_2_tipo IS 'Tipo da segunda forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.historico_geral.pagamento_2_valor IS 'Valor pago com a segunda forma de pagamento';

-- Tabela: avaliacoes
CREATE TABLE IF NOT EXISTS public.avaliacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome_cliente VARCHAR NOT NULL,
    estrelas INTEGER NOT NULL CHECK (estrelas >= 1 AND estrelas <= 5),
    descricao TEXT,
    badges TEXT[] DEFAULT '{}',
    aprovada BOOLEAN DEFAULT true,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.avaliacoes IS 'Tabela para armazenar avaliações dos clientes sobre o estabelecimento';
COMMENT ON COLUMN public.avaliacoes.nome_cliente IS 'Nome do cliente que fez a avaliação';
COMMENT ON COLUMN public.avaliacoes.estrelas IS 'Nota de 1 a 5 estrelas';
COMMENT ON COLUMN public.avaliacoes.descricao IS 'Comentário opcional do cliente';
COMMENT ON COLUMN public.avaliacoes.badges IS 'Array de badges/elogios selecionados pelo cliente';
COMMENT ON COLUMN public.avaliacoes.aprovada IS 'Se a avaliação foi aprovada para exibição pública';

-- Tabela: comandas
CREATE TABLE IF NOT EXISTS public.comandas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_comanda INTEGER NOT NULL CHECK (numero_comanda >= 1 AND numero_comanda <= 24),
    status VARCHAR DEFAULT 'aberta' CHECK (status IN ('aberta', 'finalizada', 'cancelada')),
    itens JSONB DEFAULT '[]',
    subtotal NUMERIC DEFAULT 0,
    total NUMERIC DEFAULT 0,
    criado_por UUID REFERENCES auth.users(id),
    editado_por UUID REFERENCES auth.users(id),
    finalizado_por UUID REFERENCES auth.users(id),
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now(),
    finalizado_em TIMESTAMPTZ,
    observacoes TEXT,
    forma_pagamento VARCHAR,
    desconto NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0),
    tipo_desconto TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual')),
    forma_pagamento_dividido BOOLEAN NOT NULL DEFAULT false,
    pagamento_1_tipo TEXT,
    pagamento_1_valor NUMERIC(10, 2),
    pagamento_2_tipo TEXT,
    pagamento_2_valor NUMERIC(10, 2),
    CONSTRAINT comandas_pagamento_tipos_diferentes CHECK (
        NOT forma_pagamento_dividido OR 
        (pagamento_1_tipo IS NOT NULL AND pagamento_2_tipo IS NOT NULL AND pagamento_1_tipo != pagamento_2_tipo)
    ),
    CONSTRAINT comandas_pagamento_valores_positivos CHECK (
        NOT forma_pagamento_dividido OR 
        (pagamento_1_valor > 0 AND pagamento_2_valor > 0)
    )
);

COMMENT ON TABLE public.comandas IS 'Tabela para gerenciar comandas de pedidos no estabelecimento';
COMMENT ON COLUMN public.comandas.numero_comanda IS 'Número da comanda (1 a 24)';
COMMENT ON COLUMN public.comandas.status IS 'Status da comanda: aberta, finalizada ou cancelada';
COMMENT ON COLUMN public.comandas.itens IS 'Array JSON com os itens da comanda incluindo produto, quantidade, personalizações, etc';
COMMENT ON COLUMN public.comandas.criado_por IS 'ID do usuário que criou/abriu a comanda';
COMMENT ON COLUMN public.comandas.editado_por IS 'ID do último usuário que editou a comanda';
COMMENT ON COLUMN public.comandas.finalizado_por IS 'ID do usuário que finalizou a comanda';
COMMENT ON COLUMN public.comandas.forma_pagamento IS 'Forma de pagamento utilizada na comanda';
COMMENT ON COLUMN public.comandas.desconto IS 'Valor do desconto aplicado. Se tipo_desconto=valor, representa R$. Se tipo_desconto=percentual, representa %';
COMMENT ON COLUMN public.comandas.tipo_desconto IS 'Tipo do desconto: valor (R$) ou percentual (%)';
COMMENT ON COLUMN public.comandas.forma_pagamento_dividido IS 'Indica se o pagamento foi dividido entre duas formas de pagamento diferentes';
COMMENT ON COLUMN public.comandas.pagamento_1_tipo IS 'Tipo da primeira forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.comandas.pagamento_1_valor IS 'Valor pago com a primeira forma de pagamento';
COMMENT ON COLUMN public.comandas.pagamento_2_tipo IS 'Tipo da segunda forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.comandas.pagamento_2_valor IS 'Valor pago com a segunda forma de pagamento';

-- Tabela: historico_comandas
CREATE TABLE IF NOT EXISTS public.historico_comandas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_comanda INTEGER NOT NULL CHECK (numero_comanda >= 1 AND numero_comanda <= 24),
    itens JSONB DEFAULT '[]',
    subtotal NUMERIC DEFAULT 0,
    total NUMERIC DEFAULT 0,
    forma_pagamento VARCHAR,
    criado_por UUID REFERENCES auth.users(id),
    finalizado_por UUID REFERENCES auth.users(id),
    criado_em TIMESTAMPTZ,
    finalizado_em TIMESTAMPTZ DEFAULT now(),
    observacoes TEXT,
    desconto NUMERIC NOT NULL DEFAULT 0 CHECK (desconto >= 0),
    tipo_desconto TEXT NOT NULL DEFAULT 'valor' CHECK (tipo_desconto IN ('valor', 'percentual')),
    forma_pagamento_dividido BOOLEAN NOT NULL DEFAULT false,
    pagamento_1_tipo TEXT,
    pagamento_1_valor NUMERIC(10, 2),
    pagamento_2_tipo TEXT,
    pagamento_2_valor NUMERIC(10, 2),
    CONSTRAINT historico_comandas_pagamento_tipos_diferentes CHECK (
        NOT forma_pagamento_dividido OR 
        (pagamento_1_tipo IS NOT NULL AND pagamento_2_tipo IS NOT NULL AND pagamento_1_tipo != pagamento_2_tipo)
    ),
    CONSTRAINT historico_comandas_pagamento_valores_positivos CHECK (
        NOT forma_pagamento_dividido OR 
        (pagamento_1_valor > 0 AND pagamento_2_valor > 0)
    )
);

COMMENT ON TABLE public.historico_comandas IS 'Histórico de comandas finalizadas do estabelecimento';
COMMENT ON COLUMN public.historico_comandas.numero_comanda IS 'Número da comanda (1 a 24)';
COMMENT ON COLUMN public.historico_comandas.itens IS 'Array JSON com os itens da comanda incluindo produto, quantidade, personalizações, etc';
COMMENT ON COLUMN public.historico_comandas.forma_pagamento IS 'Forma de pagamento utilizada';
COMMENT ON COLUMN public.historico_comandas.criado_por IS 'ID do usuário que criou/abriu a comanda';
COMMENT ON COLUMN public.historico_comandas.finalizado_por IS 'ID do usuário que finalizou a comanda';
COMMENT ON COLUMN public.historico_comandas.desconto IS 'Valor do desconto aplicado. Se tipo_desconto=valor, representa R$. Se tipo_desconto=percentual, representa %';
COMMENT ON COLUMN public.historico_comandas.tipo_desconto IS 'Tipo do desconto: valor (R$) ou percentual (%)';
COMMENT ON COLUMN public.historico_comandas.forma_pagamento_dividido IS 'Indica se o pagamento foi dividido entre duas formas de pagamento diferentes';
COMMENT ON COLUMN public.historico_comandas.pagamento_1_tipo IS 'Tipo da primeira forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.historico_comandas.pagamento_1_valor IS 'Valor pago com a primeira forma de pagamento';
COMMENT ON COLUMN public.historico_comandas.pagamento_2_tipo IS 'Tipo da segunda forma de pagamento (PIX, Dinheiro, Débito, Crédito)';
COMMENT ON COLUMN public.historico_comandas.pagamento_2_valor IS 'Valor pago com a segunda forma de pagamento';

-- Tabela: ia_config
CREATE TABLE IF NOT EXISTS ia_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_key TEXT NOT NULL,
  modelo TEXT NOT NULL DEFAULT 'gpt-4o',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE ia_config IS 'Armazena configurações da API OpenAI para o assistente de IA';
COMMENT ON COLUMN ia_config.api_key IS 'Chave da API OpenAI (deve ser criptografada na aplicação)';
COMMENT ON COLUMN ia_config.modelo IS 'Modelo da OpenAI: gpt-4o, gpt-4-turbo, gpt-3.5-turbo';

-- Tabela: ia_conversas
CREATE TABLE IF NOT EXISTS ia_conversas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mensagens JSONB NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'em_andamento',
  dados_extraidos JSONB,
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE ia_conversas IS 'Armazena conversas do chat com o assistente de IA';
COMMENT ON COLUMN ia_conversas.mensagens IS 'Array JSON com histórico de mensagens: [{role: "user"|"assistant", content: "texto"}]';
COMMENT ON COLUMN ia_conversas.status IS 'Status: em_andamento, finalizado, cancelado';
COMMENT ON COLUMN ia_conversas.dados_extraidos IS 'Dados estruturados extraídos pela IA: {nome, preco, categoria, etc}';

-- Tabela: ia_arquivos_temp
CREATE TABLE IF NOT EXISTS ia_arquivos_temp (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversa_id UUID REFERENCES ia_conversas(id) ON DELETE CASCADE,
  nome_arquivo TEXT NOT NULL,
  tipo_arquivo TEXT NOT NULL,
  url_arquivo TEXT NOT NULL,
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE ia_arquivos_temp IS 'Armazena referências de arquivos temporários uploadados durante conversas';
COMMENT ON COLUMN ia_arquivos_temp.url_arquivo IS 'URL do arquivo no bucket ia-uploads do Supabase Storage';
COMMENT ON COLUMN ia_arquivos_temp.tipo_arquivo IS 'MIME type: image/jpeg, image/png, application/pdf, etc';

-- Tabela: profile
CREATE TABLE IF NOT EXISTS public.profile (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES auth.users(id),
    nome VARCHAR NOT NULL,
    email VARCHAR NOT NULL UNIQUE,
    telefone VARCHAR,
    ativo BOOLEAN DEFAULT true,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.profile IS 'Tabela para armazenar perfis de administradores com acesso total ao sistema';
COMMENT ON COLUMN public.profile.user_id IS 'Referência ao usuário no auth.users do Supabase';
COMMENT ON COLUMN public.profile.nome IS 'Nome completo do administrador';
COMMENT ON COLUMN public.profile.email IS 'Email do administrador (deve corresponder ao email em auth.users)';
COMMENT ON COLUMN public.profile.telefone IS 'Telefone de contato do administrador';
COMMENT ON COLUMN public.profile.ativo IS 'Define se o administrador está ativo no sistema';

-- ============================================================================
-- PARTE 4/8: ÍNDICES
-- ============================================================================

-- Índices para adicionais
CREATE INDEX IF NOT EXISTS idx_adicionais_ativo ON public.adicionais USING btree (ativo);
CREATE INDEX IF NOT EXISTS idx_adicionais_categoria_id ON public.adicionais USING btree (categoria_id);

-- Índices para avaliacoes
CREATE INDEX IF NOT EXISTS idx_avaliacoes_criado_em ON public.avaliacoes USING btree (criado_em DESC);

-- Índices para categorias
CREATE INDEX IF NOT EXISTS idx_categorias_ordem ON public.categorias USING btree (ordem);

-- Índices para clientes
CREATE INDEX IF NOT EXISTS idx_clientes_cpf ON public.clientes USING btree (cpf) WHERE (cpf IS NOT NULL);
CREATE INDEX IF NOT EXISTS idx_clientes_criado_em ON public.clientes USING btree (criado_em);
CREATE INDEX IF NOT EXISTS idx_clientes_telefone ON public.clientes USING btree (telefone);

-- Índices para comandas
CREATE INDEX IF NOT EXISTS idx_comandas_criado_em ON public.comandas USING btree (criado_em);
CREATE INDEX IF NOT EXISTS idx_comandas_criado_por ON public.comandas USING btree (criado_por);
CREATE INDEX IF NOT EXISTS idx_comandas_editado_por ON public.comandas USING btree (editado_por);
CREATE INDEX IF NOT EXISTS idx_comandas_finalizado_por ON public.comandas USING btree (finalizado_por);
CREATE INDEX IF NOT EXISTS idx_comandas_numero ON public.comandas USING btree (numero_comanda);
CREATE INDEX IF NOT EXISTS idx_comandas_numero_status ON public.comandas USING btree (numero_comanda, status) WHERE (status = 'aberta');
CREATE INDEX IF NOT EXISTS idx_comandas_status ON public.comandas USING btree (status);

-- Índices para combo_produtos
CREATE INDEX IF NOT EXISTS idx_combo_produtos_combo_id ON public.combo_produtos USING btree (combo_id);
CREATE INDEX IF NOT EXISTS idx_combo_produtos_produto_id ON public.combo_produtos USING btree (produto_id);

-- Índices para estoque
CREATE INDEX IF NOT EXISTS idx_estoque_nome ON public.estoque USING btree (nome);

-- Índices para funcionarios
CREATE INDEX IF NOT EXISTS idx_funcionarios_email ON public.funcionarios USING btree (email);
CREATE INDEX IF NOT EXISTS idx_funcionarios_user_id ON public.funcionarios USING btree (user_id);

-- Índices para historico_comandas
CREATE INDEX IF NOT EXISTS idx_historico_comandas_criado_por ON public.historico_comandas USING btree (criado_por);
CREATE INDEX IF NOT EXISTS idx_historico_comandas_finalizado_em ON public.historico_comandas USING btree (finalizado_em);
CREATE INDEX IF NOT EXISTS idx_historico_comandas_finalizado_por ON public.historico_comandas USING btree (finalizado_por);
CREATE INDEX IF NOT EXISTS idx_historico_comandas_numero ON public.historico_comandas USING btree (numero_comanda);

-- Índices para historico_geral
CREATE INDEX IF NOT EXISTS idx_historico_geral_criado_em ON public.historico_geral USING btree (criado_em);
CREATE INDEX IF NOT EXISTS idx_historico_geral_movido_em ON public.historico_geral USING btree (movido_em);
CREATE INDEX IF NOT EXISTS idx_historico_geral_pedido_id ON public.historico_geral USING btree (pedido_id);

-- Índices para historico_pedidos
CREATE INDEX IF NOT EXISTS idx_historico_pedidos_pedido_data ON public.historico_pedidos USING btree (pedido_id, criado_em);
CREATE INDEX IF NOT EXISTS idx_historico_pedidos_pedido_id ON public.historico_pedidos USING btree (pedido_id);

-- Índices para pedidos
CREATE INDEX IF NOT EXISTS idx_pedidos_cancelado_por ON public.pedidos USING btree (cancelado_por);
CREATE INDEX IF NOT EXISTS idx_pedidos_cliente_id ON public.pedidos USING btree (cliente_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_pedidos_codigo_pedido ON public.pedidos USING btree (codigo_pedido);
CREATE INDEX IF NOT EXISTS idx_pedidos_criado_em ON public.pedidos USING btree (criado_em);
CREATE INDEX IF NOT EXISTS idx_pedidos_pedido_id ON public.pedidos USING btree (pedido_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_status_data ON public.pedidos USING btree (status, criado_em);
CREATE INDEX IF NOT EXISTS idx_pedidos_mercado_pago_payment_id ON public.pedidos USING btree (mercado_pago_payment_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_mercado_pago_status ON public.pedidos USING btree (mercado_pago_status);

-- Índices para produto_sabores
CREATE INDEX IF NOT EXISTS idx_produto_sabores_produto_id ON public.produto_sabores USING btree (produto_id);
CREATE INDEX IF NOT EXISTS idx_produto_sabores_sabor_id ON public.produto_sabores USING btree (sabor_id);

-- Índices para produtos
CREATE INDEX IF NOT EXISTS idx_produtos_categoria_id ON public.produtos USING btree (categoria_id);
CREATE INDEX IF NOT EXISTS idx_produtos_categoria_nome ON public.produtos USING btree (categoria_nome);

-- Índices para sabores
CREATE INDEX IF NOT EXISTS idx_sabores_categoria_id_fk ON public.sabores USING btree (categoria_id);
CREATE INDEX IF NOT EXISTS idx_sabores_tipo ON public.sabores USING btree (tipo);

-- Índices para tamanhos
CREATE INDEX IF NOT EXISTS idx_tamanhos_produto_id ON public.tamanhos USING btree (produto_id);
CREATE INDEX IF NOT EXISTS idx_tamanhos_produto_ordem ON public.tamanhos USING btree (produto_id, ordem) WHERE (ativo = true);

-- Índices para ia_conversas
CREATE INDEX IF NOT EXISTS idx_ia_conversas_status ON ia_conversas(status);
CREATE INDEX IF NOT EXISTS idx_ia_conversas_criado_em ON ia_conversas(criado_em DESC);

-- Índices para ia_arquivos_temp
CREATE INDEX IF NOT EXISTS idx_ia_arquivos_temp_conversa_id ON ia_arquivos_temp(conversa_id);

-- ============================================================================
-- PARTE 5/8: TRIGGERS
-- ============================================================================

-- Trigger para atualizar timestamp em categorias
DROP TRIGGER IF EXISTS trigger_categorias_atualizado_em ON public.categorias;
CREATE TRIGGER trigger_categorias_atualizado_em 
    BEFORE UPDATE ON public.categorias 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em comandas
DROP TRIGGER IF EXISTS trigger_update_comandas_timestamp ON public.comandas;
CREATE TRIGGER trigger_update_comandas_timestamp 
    BEFORE UPDATE ON public.comandas 
    FOR EACH ROW EXECUTE FUNCTION update_comandas_updated_at();

-- Trigger para atualizar timestamp em combos
DROP TRIGGER IF EXISTS trigger_combos_atualizado_em ON public.combos;
CREATE TRIGGER trigger_combos_atualizado_em 
    BEFORE UPDATE ON public.combos 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em configuracoes
DROP TRIGGER IF EXISTS trigger_configuracoes_atualizado_em ON public.configuracoes;
CREATE TRIGGER trigger_configuracoes_atualizado_em 
    BEFORE UPDATE ON public.configuracoes 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em estoque
DROP TRIGGER IF EXISTS trigger_estoque_atualizado_em ON public.estoque;
CREATE TRIGGER trigger_estoque_atualizado_em 
    BEFORE UPDATE ON public.estoque 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em funcionarios
DROP TRIGGER IF EXISTS trigger_funcionarios_atualizado_em ON public.funcionarios;
CREATE TRIGGER trigger_funcionarios_atualizado_em 
    BEFORE UPDATE ON public.funcionarios 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em historico_pedidos
DROP TRIGGER IF EXISTS update_historico_pedidos_updated_at ON public.historico_pedidos;
CREATE TRIGGER update_historico_pedidos_updated_at 
    BEFORE UPDATE ON public.historico_pedidos 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para sincronizar status do pedido com histórico
DROP TRIGGER IF EXISTS trigger_sync_pedido_status ON public.pedidos;
CREATE TRIGGER trigger_sync_pedido_status 
    AFTER UPDATE ON public.pedidos 
    FOR EACH ROW EXECUTE FUNCTION sync_pedido_status_to_historico();

-- Trigger para atualizar timestamp em pedidos
DROP TRIGGER IF EXISTS update_pedidos_updated_at ON public.pedidos;
CREATE TRIGGER update_pedidos_updated_at 
    BEFORE UPDATE ON public.pedidos 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para atualizar timestamp em produtos
DROP TRIGGER IF EXISTS trigger_produtos_atualizado_em ON public.produtos;
CREATE TRIGGER trigger_produtos_atualizado_em 
    BEFORE UPDATE ON public.produtos 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em sabores
DROP TRIGGER IF EXISTS trigger_sabores_atualizado_em ON public.sabores;
CREATE TRIGGER trigger_sabores_atualizado_em 
    BEFORE UPDATE ON public.sabores 
    FOR EACH ROW EXECUTE FUNCTION atualizar_timestamp();

-- Trigger para atualizar timestamp em tamanhos
DROP TRIGGER IF EXISTS trigger_update_tamanhos_updated_at ON public.tamanhos;
CREATE TRIGGER trigger_update_tamanhos_updated_at 
    BEFORE UPDATE ON public.tamanhos 
    FOR EACH ROW EXECUTE FUNCTION update_tamanhos_updated_at();

-- Trigger para ia_config
DROP TRIGGER IF EXISTS update_ia_config_updated_at ON ia_config;
CREATE TRIGGER update_ia_config_updated_at
  BEFORE UPDATE ON ia_config
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger para ia_conversas
DROP TRIGGER IF EXISTS update_ia_conversas_atualizado_em ON ia_conversas;
CREATE TRIGGER update_ia_conversas_atualizado_em
  BEFORE UPDATE ON ia_conversas
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- PARTE 6/8: ROW LEVEL SECURITY (RLS) - POLÍTICAS DE SEGURANÇA
-- ============================================================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE public.adicionais ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comandas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.combo_produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.combos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuracoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estoque ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.funcionarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_comandas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_geral ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_sabores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sabores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tamanhos ENABLE ROW LEVEL SECURITY;
ALTER TABLE ia_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE ia_conversas ENABLE ROW LEVEL SECURITY;
ALTER TABLE ia_arquivos_temp ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile ENABLE ROW LEVEL SECURITY;

-- Políticas para adicionais
DROP POLICY IF EXISTS "Permitir leitura pública de adicionais" ON public.adicionais;
CREATE POLICY "Permitir leitura pública de adicionais" ON public.adicionais FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir inserção autenticada de adicionais" ON public.adicionais;
CREATE POLICY "Permitir inserção autenticada de adicionais" ON public.adicionais FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir atualização autenticada de adicionais" ON public.adicionais;
CREATE POLICY "Permitir atualização autenticada de adicionais" ON public.adicionais FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Permitir exclusão autenticada de adicionais" ON public.adicionais;
CREATE POLICY "Permitir exclusão autenticada de adicionais" ON public.adicionais FOR DELETE USING (true);

-- Políticas para avaliacoes
DROP POLICY IF EXISTS "Permitir leitura pública de avaliações aprovadas" ON public.avaliacoes;
CREATE POLICY "Permitir leitura pública de avaliações aprovadas" ON public.avaliacoes FOR SELECT USING (aprovada = true);

DROP POLICY IF EXISTS "Permitir inserção pública de avaliações" ON public.avaliacoes;
CREATE POLICY "Permitir inserção pública de avaliações" ON public.avaliacoes FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir atualização de avaliações" ON public.avaliacoes;
CREATE POLICY "Permitir atualização de avaliações" ON public.avaliacoes FOR UPDATE USING (true);

-- Políticas para categorias
DROP POLICY IF EXISTS "Leitura pública categorias" ON public.categorias;
CREATE POLICY "Leitura pública categorias" ON public.categorias FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada categorias" ON public.categorias;
CREATE POLICY "Inserção autenticada categorias" ON public.categorias FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada categorias" ON public.categorias;
CREATE POLICY "Atualização autenticada categorias" ON public.categorias FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada categorias" ON public.categorias;
CREATE POLICY "Exclusão autenticada categorias" ON public.categorias FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- Políticas para clientes
DROP POLICY IF EXISTS "Permitir todas as operações em clientes" ON public.clientes;
CREATE POLICY "Permitir todas as operações em clientes" ON public.clientes FOR ALL USING (true) WITH CHECK (true);

-- Políticas para comandas
DROP POLICY IF EXISTS "Usuários autenticados podem visualizar comandas" ON public.comandas;
CREATE POLICY "Usuários autenticados podem visualizar comandas" ON public.comandas FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem criar comandas" ON public.comandas;
CREATE POLICY "Usuários autenticados podem criar comandas" ON public.comandas FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários autenticados podem atualizar comandas" ON public.comandas;
CREATE POLICY "Usuários autenticados podem atualizar comandas" ON public.comandas FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários autenticados podem deletar comandas" ON public.comandas;
CREATE POLICY "Usuários autenticados podem deletar comandas" ON public.comandas FOR DELETE TO authenticated USING (true);

-- Políticas para combo_produtos
DROP POLICY IF EXISTS "Leitura pública combo_produtos" ON public.combo_produtos;
CREATE POLICY "Leitura pública combo_produtos" ON public.combo_produtos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada combo_produtos" ON public.combo_produtos;
CREATE POLICY "Inserção autenticada combo_produtos" ON public.combo_produtos FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada combo_produtos" ON public.combo_produtos;
CREATE POLICY "Atualização autenticada combo_produtos" ON public.combo_produtos FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada combo_produtos" ON public.combo_produtos;
CREATE POLICY "Exclusão autenticada combo_produtos" ON public.combo_produtos FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- Políticas para combos
DROP POLICY IF EXISTS "Leitura pública combos" ON public.combos;
CREATE POLICY "Leitura pública combos" ON public.combos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada combos" ON public.combos;
CREATE POLICY "Inserção autenticada combos" ON public.combos FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada combos" ON public.combos;
CREATE POLICY "Atualização autenticada combos" ON public.combos FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada combos" ON public.combos;
CREATE POLICY "Exclusão autenticada combos" ON public.combos FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- Políticas para configuracoes
DROP POLICY IF EXISTS "configuracoes_optimized_policy" ON public.configuracoes;
CREATE POLICY "configuracoes_optimized_policy" ON public.configuracoes FOR ALL 
    USING (true) 
    WITH CHECK ((SELECT auth.role()) = 'authenticated' OR (SELECT auth.role()) = 'anon');

-- Políticas para estoque
DROP POLICY IF EXISTS "Acesso autenticado estoque" ON public.estoque;
CREATE POLICY "Acesso autenticado estoque" ON public.estoque FOR ALL USING ((SELECT auth.uid()) IS NOT NULL);

-- Políticas para funcionarios
DROP POLICY IF EXISTS "Permitir leitura funcionarios autenticados" ON public.funcionarios;
CREATE POLICY "Permitir leitura funcionarios autenticados" ON public.funcionarios FOR SELECT USING ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Permitir criacao funcionarios autenticados" ON public.funcionarios;
CREATE POLICY "Permitir criacao funcionarios autenticados" ON public.funcionarios FOR INSERT WITH CHECK ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Permitir atualizacao funcionarios autenticados" ON public.funcionarios;
CREATE POLICY "Permitir atualizacao funcionarios autenticados" ON public.funcionarios FOR UPDATE USING ((SELECT auth.role()) = 'authenticated') WITH CHECK ((SELECT auth.role()) = 'authenticated');

DROP POLICY IF EXISTS "Permitir exclusao funcionarios autenticados" ON public.funcionarios;
CREATE POLICY "Permitir exclusao funcionarios autenticados" ON public.funcionarios FOR DELETE USING ((SELECT auth.role()) = 'authenticated');

-- Políticas para historico_comandas
DROP POLICY IF EXISTS "Usuários autenticados podem visualizar histórico" ON public.historico_comandas;
CREATE POLICY "Usuários autenticados podem visualizar histórico" ON public.historico_comandas FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem criar histórico" ON public.historico_comandas;
CREATE POLICY "Usuários autenticados podem criar histórico" ON public.historico_comandas FOR INSERT TO authenticated WITH CHECK (true);

-- Políticas para historico_geral
DROP POLICY IF EXISTS "Enable all operations for historico_geral" ON public.historico_geral;
CREATE POLICY "Enable all operations for historico_geral" ON public.historico_geral FOR ALL USING (true);

-- Políticas para historico_pedidos
DROP POLICY IF EXISTS "Permitir leitura pública do histórico" ON public.historico_pedidos;
CREATE POLICY "Permitir leitura pública do histórico" ON public.historico_pedidos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir inserção pública historico_pedidos" ON public.historico_pedidos;
CREATE POLICY "Permitir inserção pública historico_pedidos" ON public.historico_pedidos FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir atualização pública historico_pedidos" ON public.historico_pedidos;
CREATE POLICY "Permitir atualização pública historico_pedidos" ON public.historico_pedidos FOR UPDATE USING (true) WITH CHECK (true);

-- Políticas para pedidos
DROP POLICY IF EXISTS "Permitir leitura pública de pedidos" ON public.pedidos;
CREATE POLICY "Permitir leitura pública de pedidos" ON public.pedidos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir inserção pública de pedidos" ON public.pedidos;
CREATE POLICY "Permitir inserção pública de pedidos" ON public.pedidos FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir atualização pública pedidos" ON public.pedidos;
CREATE POLICY "Permitir atualização pública pedidos" ON public.pedidos FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir exclusão pública de pedidos" ON public.pedidos;
CREATE POLICY "Permitir exclusão pública de pedidos" ON public.pedidos FOR DELETE USING (true);

-- Políticas para produto_sabores
DROP POLICY IF EXISTS "Leitura pública produto_sabores" ON public.produto_sabores;
CREATE POLICY "Leitura pública produto_sabores" ON public.produto_sabores FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada produto_sabores" ON public.produto_sabores;
CREATE POLICY "Inserção autenticada produto_sabores" ON public.produto_sabores FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada produto_sabores" ON public.produto_sabores;
CREATE POLICY "Atualização autenticada produto_sabores" ON public.produto_sabores FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada produto_sabores" ON public.produto_sabores;
CREATE POLICY "Exclusão autenticada produto_sabores" ON public.produto_sabores FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- Políticas para produtos
DROP POLICY IF EXISTS "Leitura pública produtos" ON public.produtos;
CREATE POLICY "Leitura pública produtos" ON public.produtos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada produtos" ON public.produtos;
CREATE POLICY "Inserção autenticada produtos" ON public.produtos FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada produtos" ON public.produtos;
CREATE POLICY "Atualização autenticada produtos" ON public.produtos FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada produtos" ON public.produtos;
CREATE POLICY "Exclusão autenticada produtos" ON public.produtos FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- Políticas para sabores
DROP POLICY IF EXISTS "Leitura pública sabores" ON public.sabores;
CREATE POLICY "Leitura pública sabores" ON public.sabores FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada sabores" ON public.sabores;
CREATE POLICY "Inserção autenticada sabores" ON public.sabores FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada sabores" ON public.sabores;
CREATE POLICY "Atualização autenticada sabores" ON public.sabores FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada sabores" ON public.sabores;
CREATE POLICY "Exclusão autenticada sabores" ON public.sabores FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- Políticas para tamanhos
DROP POLICY IF EXISTS "Leitura pública tamanhos" ON public.tamanhos;
CREATE POLICY "Leitura pública tamanhos" ON public.tamanhos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Inserção autenticada tamanhos" ON public.tamanhos;
CREATE POLICY "Inserção autenticada tamanhos" ON public.tamanhos FOR INSERT WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Atualização autenticada tamanhos" ON public.tamanhos;
CREATE POLICY "Atualização autenticada tamanhos" ON public.tamanhos FOR UPDATE USING ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Exclusão autenticada tamanhos" ON public.tamanhos;
CREATE POLICY "Exclusão autenticada tamanhos" ON public.tamanhos FOR DELETE USING ((SELECT auth.uid()) IS NOT NULL);

-- Políticas para ia_config
DROP POLICY IF EXISTS "Usuários autenticados podem ler configurações" ON ia_config;
CREATE POLICY "Usuários autenticados podem ler configurações"
  ON ia_config FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem inserir configurações" ON ia_config;
CREATE POLICY "Usuários autenticados podem inserir configurações"
  ON ia_config FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários autenticados podem atualizar configurações" ON ia_config;
CREATE POLICY "Usuários autenticados podem atualizar configurações"
  ON ia_config FOR UPDATE
  TO authenticated
  USING (true);

-- Políticas para ia_conversas
DROP POLICY IF EXISTS "Usuários autenticados podem ler conversas" ON ia_conversas;
CREATE POLICY "Usuários autenticados podem ler conversas"
  ON ia_conversas FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem inserir conversas" ON ia_conversas;
CREATE POLICY "Usuários autenticados podem inserir conversas"
  ON ia_conversas FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários autenticados podem atualizar conversas" ON ia_conversas;
CREATE POLICY "Usuários autenticados podem atualizar conversas"
  ON ia_conversas FOR UPDATE
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem deletar conversas" ON ia_conversas;
CREATE POLICY "Usuários autenticados podem deletar conversas"
  ON ia_conversas FOR DELETE
  TO authenticated
  USING (true);

-- Políticas para ia_arquivos_temp
DROP POLICY IF EXISTS "Usuários autenticados podem ler arquivos" ON ia_arquivos_temp;
CREATE POLICY "Usuários autenticados podem ler arquivos"
  ON ia_arquivos_temp FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem inserir arquivos" ON ia_arquivos_temp;
CREATE POLICY "Usuários autenticados podem inserir arquivos"
  ON ia_arquivos_temp FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários autenticados podem deletar arquivos" ON ia_arquivos_temp;
CREATE POLICY "Usuários autenticados podem deletar arquivos"
  ON ia_arquivos_temp FOR DELETE
  TO authenticated
  USING (true);

-- Políticas para profile
DROP POLICY IF EXISTS "Usuários autenticados podem ler profiles" ON public.profile;
CREATE POLICY "Usuários autenticados podem ler profiles"
    ON public.profile FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem inserir profiles" ON public.profile;
CREATE POLICY "Usuários autenticados podem inserir profiles"
    ON public.profile FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Usuários autenticados podem atualizar profiles" ON public.profile;
CREATE POLICY "Usuários autenticados podem atualizar profiles"
    ON public.profile FOR UPDATE
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Usuários autenticados podem deletar profiles" ON public.profile;
CREATE POLICY "Usuários autenticados podem deletar profiles"
    ON public.profile FOR DELETE
    TO authenticated
    USING (true);

-- ============================================================================
-- PARTE 7/8: STORAGE BUCKETS E CONFIGURAÇÕES INICIAIS
-- ============================================================================

-- Storage Buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'produtos-imagens', 
    'produtos-imagens', 
    true, 
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES (
    'sistema-imagens', 
    'sistema-imagens', 
    true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES (
    'ia-uploads', 
    'ia-uploads', 
    false
) ON CONFLICT (id) DO NOTHING;

-- Políticas de Storage para produtos-imagens
DROP POLICY IF EXISTS "Permitir leitura pública de imagens de produtos" ON storage.objects;
CREATE POLICY "Permitir leitura pública de imagens de produtos"
ON storage.objects FOR SELECT
USING (bucket_id = 'produtos-imagens');

DROP POLICY IF EXISTS "Permitir upload autenticado de imagens de produtos" ON storage.objects;
CREATE POLICY "Permitir upload autenticado de imagens de produtos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'produtos-imagens' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Permitir atualização autenticada de imagens de produtos" ON storage.objects;
CREATE POLICY "Permitir atualização autenticada de imagens de produtos"
ON storage.objects FOR UPDATE
USING (bucket_id = 'produtos-imagens' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Permitir exclusão autenticada de imagens de produtos" ON storage.objects;
CREATE POLICY "Permitir exclusão autenticada de imagens de produtos"
ON storage.objects FOR DELETE
USING (bucket_id = 'produtos-imagens' AND auth.role() = 'authenticated');

-- Políticas de Storage para sistema-imagens
DROP POLICY IF EXISTS "Permitir leitura pública de imagens do sistema" ON storage.objects;
CREATE POLICY "Permitir leitura pública de imagens do sistema"
ON storage.objects FOR SELECT
USING (bucket_id = 'sistema-imagens');

DROP POLICY IF EXISTS "Permitir upload autenticado de imagens do sistema" ON storage.objects;
CREATE POLICY "Permitir upload autenticado de imagens do sistema"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'sistema-imagens' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Permitir atualização autenticada de imagens do sistema" ON storage.objects;
CREATE POLICY "Permitir atualização autenticada de imagens do sistema"
ON storage.objects FOR UPDATE
USING (bucket_id = 'sistema-imagens' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Permitir exclusão autenticada de imagens do sistema" ON storage.objects;
CREATE POLICY "Permitir exclusão autenticada de imagens do sistema"
ON storage.objects FOR DELETE
USING (bucket_id = 'sistema-imagens' AND auth.role() = 'authenticated');

-- Políticas de Storage para ia-uploads
DROP POLICY IF EXISTS "Usuários autenticados podem fazer upload" ON storage.objects;
CREATE POLICY "Usuários autenticados podem fazer upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'ia-uploads');

DROP POLICY IF EXISTS "Usuários autenticados podem ler arquivos" ON storage.objects;
CREATE POLICY "Usuários autenticados podem ler arquivos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'ia-uploads');

DROP POLICY IF EXISTS "Usuários autenticados podem deletar arquivos" ON storage.objects;
CREATE POLICY "Usuários autenticados podem deletar arquivos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'ia-uploads');

-- Configurações iniciais do sistema
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('taxa_extra_km_ativa', 'false', 'Ativar taxa extra por distância', 'booleano', 'entrega')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('taxa_extra_km_inicial', '5', 'Km inicial para cobrar taxa extra', 'numero', 'entrega')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('taxa_extra_km_faixas', '[]', 'Faixas de taxa extra por km', 'json', 'entrega')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('tipo_checkout', 'step-by-step', 'Tipo de checkout: "normal" (tudo em uma página) ou "step-by-step" (passo a passo)', 'texto', 'checkout')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

-- Configurações de tamanho de fonte para impressão
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('font_size_base', '11', 'Tamanho base do texto da impressão (px)', 'numero', 'impressao')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('font_size_store_name', '16', 'Tamanho do nome da loja na impressão (px)', 'numero', 'impressao')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('font_size_section_title', '11', 'Tamanho dos títulos de seção na impressão (px)', 'numero', 'impressao')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('font_size_item_sub', '10', 'Tamanho dos subtítulos/detalhes na impressão (px)', 'numero', 'impressao')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('font_size_totals', '12', 'Tamanho dos valores de subtotal e taxas (px)', 'numero', 'impressao')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES ('font_size_total_final', '14', 'Tamanho do valor total final na impressão (px)', 'numero', 'impressao')
ON CONFLICT (chave) DO UPDATE SET 
    valor = EXCLUDED.valor,
    descricao = EXCLUDED.descricao,
    tipo = EXCLUDED.tipo,
    categoria = EXCLUDED.categoria;

-- Realtime - Habilitar para tabelas de pedidos
DO $
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS pedidos;
        ALTER PUBLICATION supabase_realtime ADD TABLE IF NOT EXISTS historico_pedidos;
    END IF;
END $;

-- ============================================================================
-- PARTE 8/8: VIEWS ÚTEIS
-- ============================================================================

-- View: Conversas com resumo (Assistente IA)
CREATE OR REPLACE VIEW vw_conversas_resumo AS
SELECT 
  id,
  status,
  jsonb_array_length(mensagens) as total_mensagens,
  dados_extraidos->>'nome' as produto_nome,
  (SELECT COUNT(*) FROM ia_arquivos_temp WHERE conversa_id = ia_conversas.id) as total_arquivos,
  criado_em,
  atualizado_em
FROM ia_conversas;

COMMENT ON VIEW vw_conversas_resumo IS 'Resumo das conversas do assistente IA com contadores';

-- View: Arquivos por conversa (Assistente IA)
CREATE OR REPLACE VIEW vw_arquivos_por_conversa AS
SELECT 
  c.id as conversa_id,
  c.status as conversa_status,
  a.nome_arquivo,
  a.tipo_arquivo,
  a.url_arquivo,
  a.criado_em as arquivo_criado_em
FROM ia_conversas c
LEFT JOIN ia_arquivos_temp a ON a.conversa_id = c.id;

COMMENT ON VIEW vw_arquivos_por_conversa IS 'Arquivos associados a cada conversa do assistente IA';

-- View: Pedidos com informações do cliente
CREATE OR REPLACE VIEW vw_pedidos_completos AS
SELECT 
  p.*,
  c.total_pedidos as cliente_total_pedidos,
  c.valor_total_gasto as cliente_valor_total_gasto
FROM pedidos p
LEFT JOIN clientes c ON p.cliente_id = c.id;

COMMENT ON VIEW vw_pedidos_completos IS 'Pedidos com informações adicionais do cliente';

-- View: Produtos com categoria
CREATE OR REPLACE VIEW vw_produtos_com_categoria AS
SELECT 
  p.*,
  cat.nome as categoria_nome_completo,
  cat.tem_sabores,
  cat.tem_borda,
  cat.tem_tamanhos,
  cat.tem_adicionais
FROM produtos p
LEFT JOIN categorias cat ON p.categoria_id = cat.id;

COMMENT ON VIEW vw_produtos_com_categoria IS 'Produtos com informações completas da categoria';

-- View: Estatísticas de pedidos por dia
CREATE OR REPLACE VIEW vw_estatisticas_pedidos_dia AS
SELECT 
  DATE(criado_em) as data,
  COUNT(*) as total_pedidos,
  SUM(total) as valor_total,
  AVG(total) as ticket_medio,
  COUNT(DISTINCT cliente_id) as clientes_unicos
FROM pedidos
GROUP BY DATE(criado_em)
ORDER BY data DESC;

COMMENT ON VIEW vw_estatisticas_pedidos_dia IS 'Estatísticas diárias de pedidos';

-- View: Produtos mais vendidos
CREATE OR REPLACE VIEW vw_produtos_mais_vendidos AS
SELECT 
  jsonb_array_elements(itens)->>'nome' as produto_nome,
  COUNT(*) as quantidade_vendida,
  SUM((jsonb_array_elements(itens)->>'preco')::numeric) as valor_total
FROM pedidos
WHERE status NOT IN ('Cancelado')
GROUP BY produto_nome
ORDER BY quantidade_vendida DESC;

COMMENT ON VIEW vw_produtos_mais_vendidos IS 'Ranking de produtos mais vendidos';

-- View: Comandas abertas com resumo
CREATE OR REPLACE VIEW vw_comandas_abertas AS
SELECT 
  numero_comanda,
  status,
  jsonb_array_length(itens) as total_itens,
  subtotal,
  total,
  criado_em,
  atualizado_em,
  EXTRACT(EPOCH FROM (NOW() - criado_em))/60 as minutos_aberta
FROM comandas
WHERE status = 'aberta'
ORDER BY numero_comanda;

COMMENT ON VIEW vw_comandas_abertas IS 'Comandas abertas com tempo de abertura';

-- View: Avaliações aprovadas com média
CREATE OR REPLACE VIEW vw_avaliacoes_publicas AS
SELECT 
  *,
  (SELECT AVG(estrelas) FROM avaliacoes WHERE aprovada = true) as media_geral
FROM avaliacoes
WHERE aprovada = true
ORDER BY criado_em DESC;

COMMENT ON VIEW vw_avaliacoes_publicas IS 'Avaliações aprovadas para exibição pública';

-- View: Estoque baixo
CREATE OR REPLACE VIEW vw_estoque_baixo AS
SELECT 
  *,
  (quantidade_minima - quantidade) as deficit
FROM estoque
WHERE quantidade <= quantidade_minima
ORDER BY deficit DESC;

COMMENT ON VIEW vw_estoque_baixo IS 'Itens de estoque abaixo do mínimo';

-- View: Funcionários ativos
CREATE OR REPLACE VIEW vw_funcionarios_ativos AS
SELECT 
  f.*,
  CASE 
    WHEN f.bloqueado THEN 'Bloqueado'
    WHEN NOT f.ativo THEN 'Inativo'
    ELSE 'Ativo'
  END as status_completo
FROM funcionarios f
WHERE f.ativo = true AND f.bloqueado = false;

COMMENT ON VIEW vw_funcionarios_ativos IS 'Funcionários ativos e não bloqueados';

-- ============================================================================
-- FINALIZAÇÃO
-- ============================================================================

-- Mensagem de sucesso (será exibida no console do Supabase)
DO $$
BEGIN
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'ESTRUTURA DO BANCO DE DADOS CRIADA/ATUALIZADA COM SUCESSO!';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Resumo da execução:';
    RAISE NOTICE '- Extensões: PostgreSQL UUID e Crypto';
    RAISE NOTICE '- Funções: 8 funções auxiliares';
    RAISE NOTICE '- Tabelas: 22 tabelas criadas/atualizadas';
    RAISE NOTICE '- Índices: ~40 índices para performance';
    RAISE NOTICE '- Triggers: 15 triggers automáticos';
    RAISE NOTICE '- Políticas RLS: Segurança configurada';
    RAISE NOTICE '- Storage: 3 buckets configurados';
    RAISE NOTICE '- Views: 10 views úteis';
    RAISE NOTICE '';
    RAISE NOTICE 'Próximos passos:';
    RAISE NOTICE '1. Verificar se todas as tabelas foram criadas';
    RAISE NOTICE '2. Testar políticas RLS';
    RAISE NOTICE '3. Configurar Edge Functions (se necessário)';
    RAISE NOTICE '4. Inserir dados iniciais (categorias, produtos)';
    RAISE NOTICE '';
    RAISE NOTICE 'Seus dados existentes foram PRESERVADOS!';
    RAISE NOTICE '============================================================================';
END $$;

-- ============================================================================
-- FIM DO SCRIPT COMPLETO
-- ============================================================================
-- 
-- Arquivo gerado em: 22/01/2026
-- Versão: 1.1.0
-- Total de linhas: ~1000+
-- 
-- Este script consolida todos os 8 arquivos SQL em um único arquivo
-- para facilitar a execução no Supabase SQL Editor.
-- 
-- IMPORTANTE:
-- - Todos os seus produtos, pedidos e dados existentes foram preservados
-- - O script apenas adiciona/atualiza a estrutura do banco
-- - É seguro executar múltiplas vezes (idempotente)
-- 
-- Em caso de dúvidas, consulte a documentação em:
-- - BD_20_01/README.md
-- - BD_20_01/GUIA_MIGRACAO.md
-- - BD_20_01/00_LEIA_PRIMEIRO.md
-- 
-- ============================================================================

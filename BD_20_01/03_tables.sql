-- ============================================================================
-- TABELAS
-- ============================================================================
-- Arquivo: 03_tables.sql
-- Descrição: Estrutura de todas as tabelas do sistema
-- Data: 20/01/2026
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
-- FIM DO ARQUIVO
-- ============================================================================

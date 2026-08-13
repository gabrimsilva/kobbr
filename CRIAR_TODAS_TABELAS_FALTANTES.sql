-- ============================================================================
-- CRIAR TODAS AS TABELAS FALTANTES - CASA DO PAI
-- Baseado nas tabelas do Custa10
-- ============================================================================

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
    desconto NUMERIC DEFAULT 0,
    tipo_desconto TEXT DEFAULT 'valor',
    forma_pagamento_dividido BOOLEAN DEFAULT false,
    pagamento_1_tipo TEXT,
    pagamento_1_valor NUMERIC,
    pagamento_2_tipo TEXT,
    pagamento_2_valor NUMERIC
);

-- Tabela: combo_produtos
CREATE TABLE IF NOT EXISTS public.combo_produtos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    combo_id UUID REFERENCES public.combos(id),
    produto_id UUID REFERENCES public.produtos(id),
    quantidade INTEGER DEFAULT 1,
    criado_em TIMESTAMPTZ DEFAULT now()
);

-- Tabela: estoque (se não existir)
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

-- Tabela: historico_comandas
CREATE TABLE IF NOT EXISTS public.historico_comandas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_comanda INTEGER NOT NULL,
    itens JSONB DEFAULT '[]',
    subtotal NUMERIC DEFAULT 0,
    total NUMERIC DEFAULT 0,
    forma_pagamento VARCHAR,
    criado_por UUID REFERENCES auth.users(id),
    finalizado_por UUID REFERENCES auth.users(id),
    criado_em TIMESTAMPTZ,
    finalizado_em TIMESTAMPTZ DEFAULT now(),
    observacoes TEXT,
    desconto NUMERIC DEFAULT 0,
    tipo_desconto TEXT DEFAULT 'valor'
);

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
    desconto NUMERIC DEFAULT 0
);

-- Tabela: historico_pedidos
CREATE TABLE IF NOT EXISTS public.historico_pedidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id TEXT NOT NULL,
    status TEXT NOT NULL,
    observacao TEXT,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now(),
    desconto NUMERIC DEFAULT 0
);

-- Tabela: ia_arquivos_temp
CREATE TABLE IF NOT EXISTS public.ia_arquivos_temp (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversa_id UUID,
    nome_arquivo TEXT NOT NULL,
    tipo_arquivo TEXT NOT NULL,
    url_arquivo TEXT NOT NULL,
    criado_em TIMESTAMPTZ DEFAULT now()
);

-- Tabela: ia_config
CREATE TABLE IF NOT EXISTS public.ia_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    api_key TEXT NOT NULL,
    modelo TEXT NOT NULL DEFAULT 'gpt-4o',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabela: ia_conversas
CREATE TABLE IF NOT EXISTS public.ia_conversas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mensagens JSONB NOT NULL DEFAULT '[]',
    status TEXT NOT NULL DEFAULT 'em_andamento',
    dados_extraidos JSONB,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- Tabela: print_jobs
CREATE TABLE IF NOT EXISTS public.print_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id TEXT,
    tipo VARCHAR NOT NULL,
    status VARCHAR DEFAULT 'pending',
    dados JSONB NOT NULL,
    criado_em TIMESTAMPTZ DEFAULT now(),
    processado_em TIMESTAMPTZ
);

-- Tabela: sabores (CRIAR ANTES de produto_sabores)
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
    categoria_sabor VARCHAR DEFAULT 'tradicional',
    tipo_sabor VARCHAR DEFAULT 'normal',
    descricao TEXT
);

-- Tabela: produto_sabores (CRIAR DEPOIS de sabores)
CREATE TABLE IF NOT EXISTS public.produto_sabores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID REFERENCES public.produtos(id),
    sabor_id UUID REFERENCES public.sabores(id),
    criado_em TIMESTAMPTZ DEFAULT now()
);

-- Tabela: sales
CREATE TABLE IF NOT EXISTS public.sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id TEXT,
    total NUMERIC NOT NULL,
    forma_pagamento TEXT,
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

-- Desabilitar RLS em todas as tabelas novas
ALTER TABLE public.adicionais DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.avaliacoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.comandas DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.combo_produtos DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.estoque DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_comandas DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_geral DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_pedidos DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.ia_arquivos_temp DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.ia_config DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.ia_conversas DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.print_jobs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.produto_sabores DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sabores DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tamanhos DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PRONTO! Todas as tabelas essenciais foram criadas
-- ============================================================================

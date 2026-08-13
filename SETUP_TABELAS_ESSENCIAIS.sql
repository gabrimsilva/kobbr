-- ============================================================================
-- TABELAS ESSENCIAIS - CASA DO PAI
-- Execute após o SETUP_MINIMO
-- ============================================================================

-- TABELA: configuracoes
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

-- TABELA: categorias
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

-- TABELA: produtos
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

-- TABELA: clientes
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

-- TABELA: pedidos
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
    codigo_pedido VARCHAR,
    cancelado BOOLEAN DEFAULT false
);

-- HABILITAR RLS
ALTER TABLE public.configuracoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS RLS (permitir tudo para usuários autenticados)
CREATE POLICY "Permitir tudo para autenticados" ON public.configuracoes FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Permitir tudo para autenticados" ON public.categorias FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Permitir tudo para autenticados" ON public.produtos FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Permitir tudo para autenticados" ON public.clientes FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Permitir tudo para autenticados" ON public.pedidos FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- INSERIR CONFIGURAÇÕES INICIAIS
INSERT INTO configuracoes (chave, valor, descricao, tipo, categoria)
VALUES 
  ('nome_estabelecimento', 'Casa do Pai', 'Nome do estabelecimento', 'texto', 'geral'),
  ('telefone', '(00) 0000-0000', 'Telefone de contato', 'texto', 'geral'),
  ('endereco', 'Rua Exemplo, 123', 'Endereço do estabelecimento', 'texto', 'geral'),
  ('taxa_entrega', '5.00', 'Taxa de entrega padrão', 'numero', 'delivery'),
  ('tempo_preparo', '30', 'Tempo médio de preparo em minutos', 'numero', 'delivery')
ON CONFLICT (chave) DO UPDATE SET
  valor = EXCLUDED.valor,
  descricao = EXCLUDED.descricao;

-- ============================================================================
-- PRONTO! Agora o sistema deve funcionar corretamente
-- ============================================================================

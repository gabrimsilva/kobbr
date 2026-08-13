-- ============================================================================
-- CORRIGIR TABELA STOCK_ITEMS COMPLETAMENTE
-- ============================================================================

-- Verificar se a tabela existe e recriar com todas as colunas necessárias
DROP TABLE IF EXISTS public.stock_items CASCADE;

CREATE TABLE public.stock_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR NOT NULL,
    descricao TEXT,
    quantidade NUMERIC DEFAULT 0,
    unidade VARCHAR DEFAULT 'un',
    preco_custo NUMERIC,
    fornecedor VARCHAR,
    categoria VARCHAR,
    ativo BOOLEAN DEFAULT true,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- Desabilitar RLS
ALTER TABLE public.stock_items DISABLE ROW LEVEL SECURITY;

-- Recriar tabelas dependentes se necessário
DROP TABLE IF EXISTS public.stock_movements CASCADE;
DROP TABLE IF EXISTS public.stock_variants CASCADE;
DROP TABLE IF EXISTS public.restock_requests CASCADE;

CREATE TABLE public.stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_item_id UUID REFERENCES public.stock_items(id) ON DELETE CASCADE,
    tipo VARCHAR NOT NULL CHECK (tipo IN ('entrada', 'saida', 'ajuste')),
    quantidade NUMERIC NOT NULL,
    motivo TEXT,
    usuario_id UUID REFERENCES auth.users(id),
    criado_em TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.stock_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_item_id UUID REFERENCES public.stock_items(id) ON DELETE CASCADE,
    nome VARCHAR NOT NULL,
    quantidade NUMERIC DEFAULT 0,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.restock_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_item_id UUID REFERENCES public.stock_items(id) ON DELETE CASCADE,
    quantidade_solicitada NUMERIC NOT NULL,
    status VARCHAR DEFAULT 'pendente' CHECK (status IN ('pendente', 'aprovado', 'rejeitado', 'concluido')),
    solicitado_por UUID REFERENCES auth.users(id),
    observacoes TEXT,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- Desabilitar RLS em todas
ALTER TABLE public.stock_movements DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_variants DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.restock_requests DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PRONTO! Tabelas de estoque recriadas corretamente
-- ============================================================================

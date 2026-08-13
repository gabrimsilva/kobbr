-- ============================================================================
-- CRIAR TABELAS DE ESTOQUE E VENDAS
-- ============================================================================

-- Tabela: stock_items (itens de estoque)
CREATE TABLE IF NOT EXISTS public.stock_items (
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

-- Tabela: stock_movements (movimentações de estoque)
CREATE TABLE IF NOT EXISTS public.stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_item_id UUID REFERENCES public.stock_items(id),
    tipo VARCHAR NOT NULL CHECK (tipo IN ('entrada', 'saida', 'ajuste')),
    quantidade NUMERIC NOT NULL,
    motivo TEXT,
    usuario_id UUID REFERENCES auth.users(id),
    criado_em TIMESTAMPTZ DEFAULT now()
);

-- Tabela: stock_variants (variantes de estoque)
CREATE TABLE IF NOT EXISTS public.stock_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_item_id UUID REFERENCES public.stock_items(id),
    nome VARCHAR NOT NULL,
    quantidade NUMERIC DEFAULT 0,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- Tabela: restock_requests (solicitações de reposição)
CREATE TABLE IF NOT EXISTS public.restock_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stock_item_id UUID REFERENCES public.stock_items(id),
    quantidade_solicitada NUMERIC NOT NULL,
    status VARCHAR DEFAULT 'pendente' CHECK (status IN ('pendente', 'aprovado', 'rejeitado', 'concluido')),
    solicitado_por UUID REFERENCES auth.users(id),
    observacoes TEXT,
    criado_em TIMESTAMPTZ DEFAULT now(),
    atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- Adicionar coluna created_at na tabela sales se não existir
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();

-- Desabilitar RLS
ALTER TABLE public.stock_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_variants DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.restock_requests DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PRONTO! Tabelas de estoque criadas
-- ============================================================================

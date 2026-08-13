-- ============================================================================
-- CRIAR TABELA COMBOS
-- ============================================================================

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

-- Desabilitar RLS temporariamente
ALTER TABLE public.combos DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PRONTO! Tabela combos criada
-- ============================================================================

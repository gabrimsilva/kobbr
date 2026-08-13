-- ============================================================================
-- SETUP MÍNIMO - CASA DO PAI
-- Execute este script no SQL Editor do Supabase
-- ============================================================================

-- 1. EXTENSÕES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

-- 2. TABELA PROFILE (para login de administradores)
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

-- 3. TABELA FUNCIONARIOS (para login de funcionários)
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

-- 4. HABILITAR RLS
ALTER TABLE public.profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.funcionarios ENABLE ROW LEVEL SECURITY;

-- 5. POLÍTICAS RLS PARA PROFILE
CREATE POLICY "Admins podem ver todos os profiles"
ON public.profile FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Admins podem inserir profiles"
ON public.profile FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Admins podem atualizar profiles"
ON public.profile FOR UPDATE
TO authenticated
USING (true);

-- 6. POLÍTICAS RLS PARA FUNCIONARIOS
CREATE POLICY "Funcionários podem ver todos"
ON public.funcionarios FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Funcionários podem ser inseridos"
ON public.funcionarios FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Funcionários podem ser atualizados"
ON public.funcionarios FOR UPDATE
TO authenticated
USING (true);

-- ============================================================================
-- PRONTO! Agora você precisa:
-- 1. Criar um usuário em Authentication > Users
-- 2. Inserir o perfil com o comando abaixo (substitua os valores):
--
-- INSERT INTO profile (user_id, nome, email, ativo)
-- VALUES (
--   'UUID_DO_USUARIO_CRIADO',
--   'Administrador',
--   'admin@casadopai.com',
--   true
-- );
-- ============================================================================

-- ============================================================================
-- MULTI-ESTABELECIMENTO: TABELAS BASE
-- ============================================================================
-- Arquivo: 09_estabelecimentos.sql
-- Descrição: Cria as tabelas base da camada multi-estabelecimento (multi-tenant):
--            estabelecimentos, usuarios_estabelecimento e logs_auditoria.
-- Ordem de execução: APÓS 03_tables.sql (depende de auth.users / public.profile).
-- Requisitos: 1.1, 2.1, 2.2, 2.3, 9.1, 9.3
-- Data: 20/01/2026
-- ============================================================================
-- NOTA: As funções de apoio à RLS (fn_is_admin_geral / fn_estabelecimentos_do_usuario)
--       e as políticas RLS destas tabelas são definidas posteriormente
--       (tarefas 2.2 e 4.2). Este arquivo prioriza a definição correta das TABELAS.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Tabela: estabelecimentos (Req 1)
-- Unidade operacional independente (prédio/filial) que atua como inquilino.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.estabelecimentos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(100) NOT NULL,
    slug VARCHAR(60) NOT NULL,              -- identificador de rota pública (ex: 'cic', 'boqueirao')
    descricao VARCHAR(500),
    cor_tema VARCHAR(9) NOT NULL,           -- hex #RRGGBB (ou #RRGGBBAA)
    ativo BOOLEAN NOT NULL DEFAULT true,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT estabelecimentos_nome_unico UNIQUE (nome),
    CONSTRAINT estabelecimentos_slug_unico UNIQUE (slug)
);

COMMENT ON TABLE public.estabelecimentos IS 'Estabelecimentos (prédios/filiais) que atuam como inquilinos (tenants) independentes';
COMMENT ON COLUMN public.estabelecimentos.nome IS 'Nome do estabelecimento (1 a 100 caracteres, único)';
COMMENT ON COLUMN public.estabelecimentos.slug IS 'Identificador único de rota pública (ex: cic, boqueirao) usado nos fluxos públicos por slug';
COMMENT ON COLUMN public.estabelecimentos.descricao IS 'Descrição do estabelecimento (máx. 500 caracteres)';
COMMENT ON COLUMN public.estabelecimentos.cor_tema IS 'Cor de tema em formato hex (#RRGGBB) aplicada à identidade visual do estabelecimento';
COMMENT ON COLUMN public.estabelecimentos.ativo IS 'Indica se o estabelecimento está ativo e pode ser selecionado como atual';
COMMENT ON COLUMN public.estabelecimentos.criado_em IS 'Data e hora de criação do estabelecimento';

-- ----------------------------------------------------------------------------
-- Tabela: usuarios_estabelecimento (Req 2, 4)
-- Vínculo entre usuário (auth.users), perfil de autorização e estabelecimento.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.usuarios_estabelecimento (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    nome VARCHAR(120) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    perfil VARCHAR(30) NOT NULL CHECK (perfil IN
        ('administrador_geral','administrador_estabelecimento','operador')),
    estabelecimento_id UUID REFERENCES public.estabelecimentos(id),
    ativo BOOLEAN NOT NULL DEFAULT true,
    ultimo_estabelecimento_id UUID REFERENCES public.estabelecimentos(id),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Perfis não-globais exigem estabelecimento vinculado (Req 2.3)
    CONSTRAINT usuario_estab_vinculo CHECK (
        perfil = 'administrador_geral' OR estabelecimento_id IS NOT NULL
    )
);

COMMENT ON TABLE public.usuarios_estabelecimento IS 'Vínculo usuário/perfil/estabelecimento — fonte de verdade de autorização multi-tenant';
COMMENT ON COLUMN public.usuarios_estabelecimento.user_id IS 'Referência única ao usuário no auth.users do Supabase';
COMMENT ON COLUMN public.usuarios_estabelecimento.nome IS 'Nome do usuário (1 a 120 caracteres)';
COMMENT ON COLUMN public.usuarios_estabelecimento.email IS 'Email do usuário (único, formato de email válido)';
COMMENT ON COLUMN public.usuarios_estabelecimento.perfil IS 'Perfil de autorização: administrador_geral, administrador_estabelecimento ou operador';
COMMENT ON COLUMN public.usuarios_estabelecimento.estabelecimento_id IS 'Estabelecimento vinculado; NULL apenas para administrador_geral (acesso a todos)';
COMMENT ON COLUMN public.usuarios_estabelecimento.ativo IS 'Indica se o usuário está ativo; usuários inativos têm acesso negado';
COMMENT ON COLUMN public.usuarios_estabelecimento.ultimo_estabelecimento_id IS 'Último estabelecimento utilizado, restaurado no início da sessão (admin geral)';
COMMENT ON COLUMN public.usuarios_estabelecimento.criado_em IS 'Data e hora de criação do vínculo';
COMMENT ON CONSTRAINT usuario_estab_vinculo ON public.usuarios_estabelecimento IS 'Perfis administrador_estabelecimento e operador exigem estabelecimento_id obrigatório (Req 2.3)';

-- ----------------------------------------------------------------------------
-- Tabela: logs_auditoria (Req 9)
-- Histórico imutável (append-only) de ações relevantes por estabelecimento.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.logs_auditoria (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES auth.users(id),
    estabelecimento_id UUID REFERENCES public.estabelecimentos(id),
    acao VARCHAR(80) NOT NULL,
    descricao VARCHAR(500) NOT NULL,
    metadata JSONB,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.logs_auditoria IS 'Registro de auditoria append-only e imutável das ações operacionais relevantes (Req 9)';
COMMENT ON COLUMN public.logs_auditoria.usuario_id IS 'Usuário que executou a ação (auth.users)';
COMMENT ON COLUMN public.logs_auditoria.estabelecimento_id IS 'Estabelecimento em que a ação ocorreu';
COMMENT ON COLUMN public.logs_auditoria.acao IS 'Identificador curto da ação (ex: produto.atualizar, estabelecimento.trocar)';
COMMENT ON COLUMN public.logs_auditoria.descricao IS 'Descrição legível da ação (máx. 500 caracteres)';
COMMENT ON COLUMN public.logs_auditoria.metadata IS 'Dados adicionais estruturados da ação (origem/destino, IDs, etc.)';
COMMENT ON COLUMN public.logs_auditoria.criado_em IS 'Data e hora da ação com precisão de segundos';

-- Índice para consulta de auditoria por estabelecimento em ordem cronológica decrescente (Req 9.4)
CREATE INDEX IF NOT EXISTS idx_logs_auditoria_estab_data
    ON public.logs_auditoria (estabelecimento_id, criado_em DESC);

-- ----------------------------------------------------------------------------
-- RLS (a refinar na 2.2 / 4.2)
-- ----------------------------------------------------------------------------
-- As políticas de Row Level Security destas três tabelas dependem das funções
-- SECURITY DEFINER fn_is_admin_geral() e fn_estabelecimentos_do_usuario(),
-- criadas na tarefa 2.2. As políticas por tenant (e a natureza append-only/
-- imutável de logs_auditoria) são definidas nas tarefas 2.2 e 4.2.
-- Este arquivo intencionalmente NÃO habilita RLS nem cria políticas, para não
-- depender de funções ainda inexistentes nem bloquear a migração de dados.
-- ============================================================================
-- FIM DO ARQUIVO
-- ============================================================================

-- ============================================================================
-- ESTRUTURA DE BANCO DE DADOS - PROFILES E PERMISSÕES
-- ============================================================================
-- Sistema de perfis, cargos e permissões dinâmicas
-- Arquitetura: Perfil → Cargo → Permissões (sem hardcode)
-- ============================================================================
-- IMPORTANTE: Sistema de LOJA ÚNICA (não multi-tenant)
-- ============================================================================

-- ============================================================================
-- HIERARQUIA DE ACESSO (IMPORTANTE - LEIA ANTES DE USAR)
-- ============================================================================
-- 
-- 🟣 SUPER_ADMIN
--   - Acesso global ao sistema
--   - Cria admins
--   - Vê tudo, faz tudo
--   - NÃO depende de permissões (bypass total)
-- 
-- 🔵 ADMIN (Gerente da pizzaria)
--   - Acesso total do sistema
--   - Cria funcionários
--   - Cria cargos
--   - Define permissões
--   - NÃO cria outros admins
-- 
-- 🟢 FUNCIONARIO
--   - Acesso limitado
--   - Tudo depende do cargo
--   - Cargo define permissões
--   - Exemplos: Entregador, Atendente, Garçom, Cozinheiro
-- 
-- ⚪ CLIENTE
--   - Loga no sistema
--   - Vê histórico
--   - Faz pedidos
--   - Cria avaliações
--   - NÃO tem cargo
-- 
-- 👻 GUEST (Não logado)
--   - Faz pedido sem login
--   - Informa nome + telefone
--   - Pedido salva snapshot
--   - Depois pode criar conta e associar pedidos
-- 
-- ============================================================================

-- ============================================================================
-- TABELA: cargos
-- ============================================================================
-- Cargos dinâmicos do sistema
-- Exemplos: Entregador, Atendente, Garçom, Cozinheiro, Gerente
-- IMPORTANTE: Criada ANTES de profiles para permitir FK
CREATE TABLE cargos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    nome TEXT NOT NULL UNIQUE, -- Ex: Entregador, Atendente, Garçom
    descricao TEXT,
    cor TEXT, -- Cor hex para identificação visual (#FF5733)
    
    -- Ordenação
    ordem_exibicao INTEGER DEFAULT 0,
    
    -- Status
    ativo BOOLEAN DEFAULT true,
    
    -- Auditoria
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_cargos_ativo ON cargos(ativo);
CREATE INDEX idx_cargos_nome ON cargos(nome);

-- ============================================================================
-- TABELA: profiles
-- ============================================================================
-- Perfis de usuários (vinculado ao auth.users do Supabase)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Dados pessoais
    nome TEXT NOT NULL,
    sobrenome TEXT,
    cpf TEXT UNIQUE,
    telefone TEXT,
    data_nascimento DATE,
    
    -- Foto de perfil
    avatar_url TEXT,
    
    -- Papel principal (hierarquia)
    role_principal TEXT NOT NULL DEFAULT 'cliente' CHECK (role_principal IN (
        'super_admin', 'admin', 'funcionario', 'cliente'
    )),
    
    -- Cargo (apenas para funcionarios)
    cargo_id UUID REFERENCES cargos(id) ON DELETE SET NULL,
    
    -- Status
    ativo BOOLEAN DEFAULT true,
    bloqueado BOOLEAN DEFAULT false,
    motivo_bloqueio TEXT,
    bloqueado_em TIMESTAMP WITH TIME ZONE,
    bloqueado_por UUID REFERENCES auth.users(id),
    
    -- Preferências
    notificacoes_email BOOLEAN DEFAULT true,
    notificacoes_sms BOOLEAN DEFAULT false,
    notificacoes_push BOOLEAN DEFAULT true,
    
    -- Auditoria
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Validação: apenas funcionario tem cargo
    CHECK (
        role_principal = 'funcionario' OR cargo_id IS NULL
    )
);

-- Índices para performance
CREATE INDEX idx_profiles_role ON profiles(role_principal);
CREATE INDEX idx_profiles_cargo ON profiles(cargo_id);
CREATE INDEX idx_profiles_ativo ON profiles(ativo);
CREATE INDEX idx_profiles_bloqueado ON profiles(bloqueado);
CREATE INDEX idx_profiles_cpf ON profiles(cpf);
CREATE INDEX idx_profiles_telefone ON profiles(telefone);

-- Índice composto para consultas comuns
CREATE INDEX idx_profiles_role_ativo ON profiles(role_principal, ativo);

-- ============================================================================
-- TABELA: permissoes
-- ============================================================================
-- Permissões disponíveis no sistema (cadastro global)
-- Define o que pode ser feito (não quem pode fazer)
CREATE TABLE permissoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Código único da permissão (usado no código)
    codigo TEXT UNIQUE NOT NULL, -- Ex: pedido.ver, pedido.criar, produto.editar
    
    -- Informações
    nome TEXT NOT NULL, -- Ex: Ver Pedidos, Criar Pedidos
    descricao TEXT,
    
    -- Categoria (para organização na UI)
    categoria TEXT CHECK (categoria IN (
        'pedidos', 'produtos', 'combos', 'avaliacoes', 'usuarios', 
        'relatorios', 'configuracoes', 'estoque', 'financeiro', 'pdv', 'comandas'
    )),
    
    -- Nível de risco (para alertas na UI)
    nivel_risco TEXT DEFAULT 'baixo' CHECK (nivel_risco IN ('baixo', 'medio', 'alto', 'critico')),
    
    -- Ordenação
    ordem_exibicao INTEGER DEFAULT 0,
    
    -- Status
    ativa BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_permissoes_codigo ON permissoes(codigo);
CREATE INDEX idx_permissoes_categoria ON permissoes(categoria);
CREATE INDEX idx_permissoes_ativa ON permissoes(ativa);

-- ============================================================================
-- TABELA: cargos_permissoes
-- ============================================================================
-- Relaciona cargos com permissões (define o que cada cargo pode fazer)
CREATE TABLE cargos_permissoes (
    cargo_id UUID NOT NULL REFERENCES cargos(id) ON DELETE CASCADE,
    permissao_id UUID NOT NULL REFERENCES permissoes(id) ON DELETE CASCADE,
    
    -- Metadados
    concedido_por UUID REFERENCES auth.users(id),
    concedido_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    PRIMARY KEY (cargo_id, permissao_id)
);

-- Índices para performance
CREATE INDEX idx_cargos_permissoes_cargo ON cargos_permissoes(cargo_id);
CREATE INDEX idx_cargos_permissoes_permissao ON cargos_permissoes(permissao_id);

-- ============================================================================
-- TABELA: profile_permissoes
-- ============================================================================
-- Permissões extras por usuário (override individual)
-- Permite grant ou deny de permissões específicas, sobrescrevendo o cargo
-- Exemplo: "esse funcionário pode cancelar pedido, mas o cargo dele não"
CREATE TABLE profile_permissoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    permissao_id UUID NOT NULL REFERENCES permissoes(id) ON DELETE CASCADE,
    
    -- Tipo de override
    tipo TEXT NOT NULL CHECK (tipo IN ('grant', 'deny')),
    
    -- Auditoria
    concedido_por UUID REFERENCES auth.users(id),
    motivo TEXT, -- Justificativa do override
    concedido_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evita duplicação
    UNIQUE(profile_id, permissao_id)
);

-- Índices para performance
CREATE INDEX idx_profile_permissoes_profile ON profile_permissoes(profile_id);
CREATE INDEX idx_profile_permissoes_permissao ON profile_permissoes(permissao_id);
CREATE INDEX idx_profile_permissoes_tipo ON profile_permissoes(tipo);

-- ============================================================================
-- TABELA: profile_cargos_historico
-- ============================================================================
-- Histórico de mudanças de cargo (auditoria completa)
-- Rastreia quando um funcionário mudou de cargo e quem fez a mudança
CREATE TABLE profile_cargos_historico (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    cargo_id UUID REFERENCES cargos(id) ON DELETE SET NULL,
    
    -- Snapshot do cargo (preserva se cargo for deletado)
    cargo_nome TEXT NOT NULL,
    
    -- Período
    atribuido_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    removido_em TIMESTAMP WITH TIME ZONE,
    
    -- Auditoria
    atribuido_por UUID REFERENCES auth.users(id),
    removido_por UUID REFERENCES auth.users(id),
    motivo_atribuicao TEXT,
    motivo_remocao TEXT
);

-- Índices para performance
CREATE INDEX idx_profile_cargos_historico_profile ON profile_cargos_historico(profile_id);
CREATE INDEX idx_profile_cargos_historico_cargo ON profile_cargos_historico(cargo_id);
CREATE INDEX idx_profile_cargos_historico_atribuido ON profile_cargos_historico(atribuido_em DESC);
CREATE INDEX idx_profile_cargos_historico_ativo ON profile_cargos_historico(profile_id, removido_em) WHERE removido_em IS NULL;

-- ============================================================================
-- TABELA: profile_enderecos
-- ============================================================================
-- Endereços salvos dos clientes (para delivery)
CREATE TABLE profile_enderecos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Identificação
    apelido TEXT, -- Ex: Casa, Trabalho, Casa da Mãe
    
    -- Endereço
    cep TEXT NOT NULL,
    endereco TEXT NOT NULL,
    numero TEXT NOT NULL,
    complemento TEXT,
    bairro TEXT NOT NULL,
    cidade TEXT NOT NULL,
    estado TEXT NOT NULL,
    referencia TEXT,
    
    -- Geolocalização
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    
    -- Flags
    endereco_principal BOOLEAN DEFAULT false,
    
    -- Soft delete (consistência com resto do banco)
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_profile_enderecos_profile ON profile_enderecos(profile_id);
CREATE INDEX idx_profile_enderecos_principal ON profile_enderecos(endereco_principal);
CREATE INDEX idx_profile_enderecos_deleted_at ON profile_enderecos(deleted_at);

-- ============================================================================
-- TRIGGERS PARA ATUALIZAR updated_at
-- ============================================================================

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cargos_updated_at
    BEFORE UPDATE ON cargos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_permissoes_updated_at
    BEFORE UPDATE ON permissoes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profile_enderecos_updated_at
    BEFORE UPDATE ON profile_enderecos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER: Registrar mudança de cargo no histórico
-- ============================================================================

CREATE OR REPLACE FUNCTION registrar_mudanca_cargo()
RETURNS TRIGGER AS $$
DECLARE
    v_cargo_nome TEXT;
    v_motivo TEXT;
BEGIN
    -- Se cargo mudou (INSERT com cargo ou UPDATE mudando cargo)
    IF (TG_OP = 'INSERT' AND NEW.cargo_id IS NOT NULL) OR 
       (TG_OP = 'UPDATE' AND OLD.cargo_id IS DISTINCT FROM NEW.cargo_id) THEN
        
        -- Finaliza cargo anterior (se houver)
        IF TG_OP = 'UPDATE' AND OLD.cargo_id IS NOT NULL THEN
            UPDATE profile_cargos_historico
            SET removido_em = NOW(),
                removido_por = NEW.updated_by,
                motivo_remocao = CASE 
                    WHEN NEW.cargo_id IS NULL THEN 'Cargo removido'
                    ELSE 'Mudança de cargo'
                END
            WHERE profile_id = OLD.id
              AND cargo_id = OLD.cargo_id
              AND removido_em IS NULL;
        END IF;
        
        -- Registra novo cargo (se não for NULL)
        IF NEW.cargo_id IS NOT NULL THEN
            -- Busca nome do cargo
            SELECT nome INTO v_cargo_nome
            FROM cargos
            WHERE id = NEW.cargo_id;
            
            -- Define motivo padrão baseado na operação
            IF TG_OP = 'INSERT' THEN
                v_motivo := 'Atribuição inicial';
            ELSE
                v_motivo := 'Mudança de cargo';
            END IF;
            
            -- Insere no histórico
            INSERT INTO profile_cargos_historico (
                profile_id,
                cargo_id,
                cargo_nome,
                atribuido_por,
                motivo_atribuicao
            ) VALUES (
                NEW.id,
                NEW.cargo_id,
                v_cargo_nome,
                COALESCE(NEW.updated_by, NEW.created_by),
                v_motivo
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_registrar_mudanca_cargo
    AFTER INSERT OR UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION registrar_mudanca_cargo();

-- ============================================================================
-- TRIGGER: Validação de apenas um endereço principal
-- ============================================================================

CREATE OR REPLACE FUNCTION validar_endereco_principal()
RETURNS TRIGGER AS $$
BEGIN
    -- Se está marcando como principal, desmarca os outros (apenas não deletados)
    IF NEW.endereco_principal = true THEN
        UPDATE profile_enderecos
        SET endereco_principal = false
        WHERE profile_id = NEW.profile_id
          AND id != NEW.id
          AND deleted_at IS NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_endereco_principal
    BEFORE INSERT OR UPDATE ON profile_enderecos
    FOR EACH ROW
    WHEN (NEW.endereco_principal = true)
    EXECUTE FUNCTION validar_endereco_principal();

-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View de funcionários com cargos e permissões (incluindo overrides)
CREATE OR REPLACE VIEW funcionarios_completo AS
SELECT 
    p.id,
    p.nome,
    p.sobrenome,
    p.telefone,
    p.ativo,
    p.bloqueado,
    c.id AS cargo_id,
    c.nome AS cargo_nome,
    c.cor AS cargo_cor,
    -- Permissões do cargo
    ARRAY_AGG(DISTINCT perm.codigo ORDER BY perm.codigo) FILTER (WHERE perm.codigo IS NOT NULL) AS permissoes_cargo,
    -- Permissões grant (adicionadas individualmente)
    ARRAY_AGG(DISTINCT perm_grant.codigo ORDER BY perm_grant.codigo) FILTER (WHERE perm_grant.codigo IS NOT NULL) AS permissoes_grant,
    -- Permissões deny (removidas individualmente)
    ARRAY_AGG(DISTINCT perm_deny.codigo ORDER BY perm_deny.codigo) FILTER (WHERE perm_deny.codigo IS NOT NULL) AS permissoes_deny
FROM profiles p
LEFT JOIN cargos c ON p.cargo_id = c.id
LEFT JOIN cargos_permissoes cp ON c.id = cp.cargo_id
LEFT JOIN permissoes perm ON cp.permissao_id = perm.id AND perm.ativa = true
LEFT JOIN profile_permissoes pp_grant ON p.id = pp_grant.profile_id AND pp_grant.tipo = 'grant'
LEFT JOIN permissoes perm_grant ON pp_grant.permissao_id = perm_grant.id AND perm_grant.ativa = true
LEFT JOIN profile_permissoes pp_deny ON p.id = pp_deny.profile_id AND pp_deny.tipo = 'deny'
LEFT JOIN permissoes perm_deny ON pp_deny.permissao_id = perm_deny.id AND perm_deny.ativa = true
WHERE p.role_principal = 'funcionario'
GROUP BY p.id, p.nome, p.sobrenome, p.telefone, p.ativo, p.bloqueado, c.id, c.nome, c.cor
ORDER BY p.nome;

-- View de cargos com contagem de funcionários
CREATE OR REPLACE VIEW cargos_resumo AS
SELECT 
    c.*,
    COUNT(p.id) AS total_funcionarios,
    COUNT(p.id) FILTER (WHERE p.ativo = true) AS total_ativos,
    COUNT(DISTINCT cp.permissao_id) AS total_permissoes
FROM cargos c
LEFT JOIN profiles p ON c.id = p.cargo_id
LEFT JOIN cargos_permissoes cp ON c.id = cp.cargo_id
WHERE c.ativo = true
GROUP BY c.id
ORDER BY c.ordem_exibicao, c.nome;

-- View de permissões por categoria
CREATE OR REPLACE VIEW permissoes_por_categoria AS
SELECT 
    categoria,
    COUNT(*) AS total_permissoes,
    ARRAY_AGG(codigo ORDER BY ordem_exibicao) AS codigos,
    ARRAY_AGG(nome ORDER BY ordem_exibicao) AS nomes
FROM permissoes
WHERE ativa = true
GROUP BY categoria
ORDER BY categoria;

-- ============================================================================
-- COMENTÁRIOS (DOCUMENTAÇÃO)
-- ============================================================================

COMMENT ON TABLE profiles IS 'Perfis de usuários vinculados ao auth.users do Supabase. Sistema de loja única. IMPORTANTE: Guest (não logado) NÃO tem profile - dados vão direto no snapshot do pedido';
COMMENT ON TABLE cargos IS 'Cargos dinâmicos do sistema (Entregador, Atendente, etc). Sistema de loja única';
COMMENT ON TABLE permissoes IS 'Permissões disponíveis no sistema (cadastro global)';
COMMENT ON TABLE cargos_permissoes IS 'Relaciona cargos com permissões (define o que cada cargo pode fazer)';
COMMENT ON TABLE profile_permissoes IS 'Permissões extras por usuário (override individual). Permite grant (adicionar) ou deny (remover) permissões específicas, sobrescrevendo o cargo';
COMMENT ON TABLE profile_cargos_historico IS 'Histórico de mudanças de cargo para auditoria completa. Registra quando funcionário mudou de cargo e quem fez a mudança';
COMMENT ON TABLE profile_enderecos IS 'Endereços salvos dos clientes para delivery';

COMMENT ON COLUMN profiles.role_principal IS 'Papel hierárquico: super_admin (bypass total), admin (permissões implícitas), funcionario (usa cargo+permissões), cliente (permissões fixas no backend)';
COMMENT ON COLUMN profiles.cargo_id IS 'Cargo do funcionário (apenas para role=funcionario). Admin e cliente NÃO devem ter cargo';
COMMENT ON COLUMN profiles.bloqueado IS 'Se true, usuário não pode acessar o sistema';

COMMENT ON COLUMN profile_enderecos.deleted_at IS 'Soft delete: preserva histórico de pedidos antigos. Cliente pode "remover" endereço sem quebrar pedidos';

COMMENT ON COLUMN cargos.nome IS 'Nome do cargo (ex: Entregador, Atendente, Garçom)';
COMMENT ON COLUMN cargos.cor IS 'Cor hex para identificação visual do cargo na UI';

COMMENT ON COLUMN permissoes.codigo IS 'Código único usado no código (ex: pedido.ver, produto.editar)';
COMMENT ON COLUMN permissoes.categoria IS 'Categoria para organização na UI';
COMMENT ON COLUMN permissoes.nivel_risco IS 'Nível de risco da permissão (baixo, medio, alto, critico)';

COMMENT ON COLUMN profile_permissoes.tipo IS 'Tipo de override: grant (adiciona permissão) ou deny (remove permissão, PREVALECE sobre cargo)';
COMMENT ON COLUMN profile_permissoes.motivo IS 'Justificativa do override (ex: "Gerente autorizou cancelamento de pedidos")';

COMMENT ON COLUMN profile_cargos_historico.cargo_nome IS 'Snapshot do nome do cargo (preserva histórico se cargo for deletado)';
COMMENT ON COLUMN profile_cargos_historico.removido_em IS 'Data/hora em que o cargo foi removido. NULL = cargo atual';

COMMENT ON VIEW funcionarios_completo IS 'View com funcionários, cargos e permissões (incluindo overrides grant/deny). IMPORTANTE: Apenas para visualização. Decisão final de permissões SEMPRE no backend com regra: deny > grant > cargo';
COMMENT ON VIEW cargos_resumo IS 'View com cargos e estatísticas (total de funcionários e permissões)';
COMMENT ON VIEW permissoes_por_categoria IS 'View com permissões agrupadas por categoria';

COMMENT ON FUNCTION registrar_mudanca_cargo IS 'Trigger que registra automaticamente mudanças de cargo no histórico para auditoria';

-- ============================================================================
-- REGRAS DE PERMISSÕES (IMPORTANTE - PARA O BACKEND)
-- ============================================================================
-- 
-- ORDEM DE DECISÃO DE PERMISSÕES:
-- 
-- 1. super_admin → BYPASS TOTAL (nem consulta permissões)
--    - Acesso global ao sistema
--    - Não precisa de cargo ou permissões
-- 
-- 2. admin → PERMISSÕES IMPLÍCITAS (acesso total)
--    - Não precisa de cargo
--    - Não precisa de permissões explícitas
--    - Acesso total ao sistema
-- 
-- 3. profile_permissoes tipo='deny' → PREVALECE SOBRE TUDO
--    - Remove permissão mesmo que cargo tenha
--    - Exemplo: "esse funcionário NÃO pode cancelar pedido"
-- 
-- 4. profile_permissoes tipo='grant' → ADICIONA PERMISSÃO
--    - Adiciona permissão mesmo que cargo não tenha
--    - Exemplo: "esse funcionário pode cancelar pedido, mas o cargo dele não"
-- 
-- 5. cargos_permissoes (permissões do cargo)
--    - Apenas para role='funcionario'
--    - Define permissões padrão do cargo
-- 
-- 6. cliente → PERMISSÕES FIXAS NO BACKEND
--    - Ver próprios pedidos
--    - Criar avaliações
--    - Editar próprio perfil
--    - NÃO usa cargo ou permissões do banco
-- 
-- IMPORTANTE: A view funcionarios_completo é para VISUALIZAÇÃO apenas.
-- A decisão final SEMPRE deve ser no backend seguindo a ordem acima.
-- 
-- ============================================================================

-- ============================================================================
-- DADOS INICIAIS: PERMISSÕES PADRÃO
-- ============================================================================

INSERT INTO permissoes (codigo, nome, descricao, categoria, nivel_risco, ordem_exibicao) VALUES
-- Pedidos
('pedido.ver', 'Ver Pedidos', 'Visualizar lista de pedidos', 'pedidos', 'baixo', 1),
('pedido.criar', 'Criar Pedidos', 'Criar novos pedidos', 'pedidos', 'baixo', 2),
('pedido.atualizar_status', 'Atualizar Status', 'Mudar status do pedido', 'pedidos', 'medio', 3),
('pedido.cancelar', 'Cancelar Pedidos', 'Cancelar pedidos', 'pedidos', 'alto', 4),
('pedido.editar', 'Editar Pedidos', 'Editar dados do pedido', 'pedidos', 'alto', 5),

-- Produtos
('produto.ver', 'Ver Produtos', 'Visualizar catálogo de produtos', 'produtos', 'baixo', 10),
('produto.criar', 'Criar Produtos', 'Adicionar novos produtos', 'produtos', 'medio', 11),
('produto.editar', 'Editar Produtos', 'Modificar produtos existentes', 'produtos', 'medio', 12),
('produto.deletar', 'Deletar Produtos', 'Remover produtos', 'produtos', 'alto', 13),

-- Combos
('combo.ver', 'Ver Combos', 'Visualizar combos', 'combos', 'baixo', 20),
('combo.criar', 'Criar Combos', 'Adicionar novos combos', 'combos', 'medio', 21),
('combo.editar', 'Editar Combos', 'Modificar combos existentes', 'combos', 'medio', 22),
('combo.deletar', 'Deletar Combos', 'Remover combos', 'combos', 'alto', 23),

-- Avaliações
('avaliacao.ver', 'Ver Avaliações', 'Visualizar avaliações', 'avaliacoes', 'baixo', 30),
('avaliacao.moderar', 'Moderar Avaliações', 'Aprovar/rejeitar avaliações', 'avaliacoes', 'medio', 31),
('avaliacao.responder', 'Responder Avaliações', 'Responder avaliações de clientes', 'avaliacoes', 'baixo', 32),

-- Usuários
('usuario.ver', 'Ver Usuários', 'Visualizar lista de usuários', 'usuarios', 'baixo', 40),
('usuario.criar', 'Criar Usuários', 'Adicionar novos usuários', 'usuarios', 'alto', 41),
('usuario.editar', 'Editar Usuários', 'Modificar dados de usuários', 'usuarios', 'alto', 42),
('usuario.bloquear', 'Bloquear Usuários', 'Bloquear/desbloquear usuários', 'usuarios', 'critico', 43),
('usuario.gerenciar_permissoes', 'Gerenciar Permissões', 'Atribuir permissões a cargos', 'usuarios', 'critico', 44),

-- Relatórios
('relatorio.ver', 'Ver Relatórios', 'Acessar relatórios gerenciais', 'relatorios', 'baixo', 50),
('relatorio.exportar', 'Exportar Relatórios', 'Exportar relatórios (PDF, Excel)', 'relatorios', 'medio', 51),

-- Configurações
('configuracao.ver', 'Ver Configurações', 'Visualizar configurações', 'configuracoes', 'baixo', 60),
('configuracao.editar', 'Editar Configurações', 'Modificar configurações do sistema', 'configuracoes', 'critico', 61),

-- Estoque
('estoque.ver', 'Ver Estoque', 'Visualizar estoque', 'estoque', 'baixo', 70),
('estoque.editar', 'Editar Estoque', 'Modificar quantidades em estoque', 'estoque', 'medio', 71),

-- Financeiro
('financeiro.ver', 'Ver Financeiro', 'Visualizar dados financeiros', 'financeiro', 'medio', 80),
('financeiro.editar', 'Editar Financeiro', 'Modificar dados financeiros', 'financeiro', 'critico', 81),

-- PDV
('pdv.acessar', 'Acessar PDV', 'Usar sistema de PDV', 'pdv', 'baixo', 90),
('pdv.abrir_fechar_caixa', 'Abrir/Fechar Caixa', 'Abrir e fechar caixa', 'pdv', 'alto', 91),
('pdv.sangria', 'Fazer Sangria', 'Realizar sangria de caixa', 'pdv', 'alto', 92),

-- Comandas
('comanda.ver', 'Ver Comandas', 'Visualizar comandas', 'comandas', 'baixo', 100),
('comanda.criar', 'Criar Comandas', 'Abrir novas comandas', 'comandas', 'baixo', 101),
('comanda.adicionar_item', 'Adicionar Item', 'Adicionar itens à comanda', 'comandas', 'baixo', 102),
('comanda.cancelar_item', 'Cancelar Item', 'Cancelar itens da comanda', 'comandas', 'medio', 103),
('comanda.fechar', 'Fechar Comanda', 'Fechar e finalizar comanda', 'comandas', 'medio', 104),
('comanda.cancelar', 'Cancelar Comanda', 'Cancelar comanda completa', 'comandas', 'alto', 105);

-- ============================================================================
-- DADOS DE EXEMPLO (OPCIONAL - COMENTADO)
-- ============================================================================

/*
-- Exemplo de cargo
INSERT INTO cargos (nome, descricao, cor)
VALUES 
    ('Entregador', 'Responsável por entregar pedidos', '#4ECDC4'),
    ('Atendente', 'Atendimento ao cliente e recepção de pedidos', '#FF6B6B'),
    ('Garçom', 'Atendimento de mesas e comandas', '#95E1D3'),
    ('Cozinheiro', 'Preparo de alimentos', '#F38181');

-- Exemplo de permissões para o cargo Entregador
INSERT INTO cargos_permissoes (cargo_id, permissao_id)
SELECT 
    (SELECT id FROM cargos WHERE nome = 'Entregador' LIMIT 1),
    id
FROM permissoes
WHERE codigo IN ('pedido.ver', 'pedido.atualizar_status');

-- Exemplo de permissões para o cargo Atendente
INSERT INTO cargos_permissoes (cargo_id, permissao_id)
SELECT 
    (SELECT id FROM cargos WHERE nome = 'Atendente' LIMIT 1),
    id
FROM permissoes
WHERE codigo IN ('pedido.ver', 'pedido.criar', 'pedido.atualizar_status', 'produto.ver', 'combo.ver');

-- Exemplo de permissões para o cargo Garçom
INSERT INTO cargos_permissoes (cargo_id, permissao_id)
SELECT 
    (SELECT id FROM cargos WHERE nome = 'Garçom' LIMIT 1),
    id
FROM permissoes
WHERE codigo IN ('comanda.ver', 'comanda.criar', 'comanda.adicionar_item', 'comanda.fechar', 'produto.ver');
*/

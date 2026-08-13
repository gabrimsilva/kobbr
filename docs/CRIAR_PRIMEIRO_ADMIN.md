# Como Criar o Primeiro Administrador

## Problema

Para criar um administrador, você precisa ser um administrador (devido às políticas RLS). Mas como criar o primeiro?

## Solução

Existem duas abordagens para criar o primeiro administrador:

## Opção 1: Via Dashboard do Supabase (Recomendado)

### Passo 1: Criar o usuário no Auth

1. Acesse o Dashboard do Supabase
2. Vá em **Authentication** > **Users**
3. Clique em **Add User**
4. Preencha:
   - Email: `admin@seudominio.com`
   - Password: `senha_forte_aqui`
   - Auto Confirm User: ✅ (marque esta opção)
5. Clique em **Create User**
6. **Copie o UUID do usuário criado** (você vai precisar dele)

### Passo 2: Criar o perfil de administrador

1. No Dashboard do Supabase, vá em **SQL Editor**
2. Execute o seguinte SQL:

```sql
-- Desabilitar RLS temporariamente para inserir o primeiro admin
ALTER TABLE public.profile DISABLE ROW LEVEL SECURITY;

-- Inserir o primeiro administrador
-- IMPORTANTE: Substitua o UUID e os dados pelos seus
INSERT INTO public.profile (user_id, nome, email, telefone, ativo)
VALUES (
  '81d7bc34-c290-4fc3-9c57-eb8ef4e43987',  -- Cole aqui o UUID do usuário criado
  'Alexandre ADM',
  'alexandre.winchesterr@gmail.com',      -- Mesmo email usado no auth
  '(41) 99750-1818',           -- Seu telefone
  true
);

-- Reabilitar RLS
ALTER TABLE public.profile ENABLE ROW LEVEL SECURITY;

-- Verificar se foi criado corretamente
SELECT 
  p.id,
  p.nome,
  p.email,
  p.ativo,
  u.email as email_auth
FROM public.profile p
JOIN auth.users u ON p.user_id = u.id;
```

### Passo 3: Testar o login

1. Acesse a página de login do sistema
2. Use o email e senha criados
3. Você agora é um administrador!

## Opção 2: Via SQL Direto (Avançado)

Se você tem acesso direto ao banco de dados PostgreSQL:

```sql
-- 1. Criar usuário no auth (requer extensão pgcrypto)
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  confirmation_token,
  raw_app_meta_data,
  raw_user_meta_data
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'admin@seudominio.com',
  crypt('sua_senha_forte', gen_salt('bf')),  -- Senha criptografada
  now(),
  now(),
  now(),
  '',
  '{"provider":"email","providers":["email"]}',
  '{}'
) RETURNING id;

-- 2. Copie o UUID retornado e use no próximo comando

-- 3. Desabilitar RLS temporariamente
ALTER TABLE public.profile DISABLE ROW LEVEL SECURITY;

-- 4. Criar perfil de administrador
INSERT INTO public.profile (user_id, nome, email, telefone, ativo)
VALUES (
  'UUID_RETORNADO_ACIMA',
  'Seu Nome Completo',
  'admin@seudominio.com',
  '(11) 98765-4321',
  true
);

-- 5. Reabilitar RLS
ALTER TABLE public.profile ENABLE ROW LEVEL SECURITY;
```

## Opção 3: Via Supabase CLI

Se você tem o Supabase CLI instalado:

```bash
# 1. Criar usuário via CLI
supabase auth create-user admin@seudominio.com --password sua_senha_forte

# 2. Obter o UUID do usuário
supabase db query "SELECT id FROM auth.users WHERE email = 'admin@seudominio.com'"

# 3. Criar perfil (substitua o UUID)
supabase db query "
ALTER TABLE public.profile DISABLE ROW LEVEL SECURITY;

INSERT INTO public.profile (user_id, nome, email, telefone, ativo)
VALUES (
  'UUID_DO_USUARIO',
  'Seu Nome Completo',
  'admin@seudominio.com',
  '(11) 98765-4321',
  true
);

ALTER TABLE public.profile ENABLE ROW LEVEL SECURITY;
"
```

## Verificação

Após criar o primeiro administrador, verifique se está tudo correto:

```sql
-- Verificar usuário no auth
SELECT id, email, email_confirmed_at, created_at
FROM auth.users
WHERE email = 'admin@seudominio.com';

-- Verificar perfil
SELECT id, user_id, nome, email, ativo, criado_em
FROM public.profile
WHERE email = 'admin@seudominio.com';

-- Verificar se o user_id corresponde
SELECT 
  u.id as auth_user_id,
  u.email as auth_email,
  p.id as profile_id,
  p.user_id as profile_user_id,
  p.nome,
  p.ativo
FROM auth.users u
LEFT JOIN public.profile p ON u.id = p.user_id
WHERE u.email = 'admin@seudominio.com';
```

## Criando Administradores Adicionais

Depois que o primeiro administrador estiver criado e logado, você pode criar novos administradores normalmente:

```sql
-- Como administrador logado, você pode criar outros admins
-- sem precisar desabilitar o RLS

-- 1. Criar usuário no Dashboard do Supabase (Authentication > Users)

-- 2. Inserir perfil (agora funciona porque você é admin)
INSERT INTO public.profile (user_id, nome, email, telefone, ativo)
VALUES (
  'UUID_DO_NOVO_USUARIO',
  'Nome do Novo Admin',
  'novoadmin@seudominio.com',
  '(11) 99999-9999',
  true
);
```

## Troubleshooting

### Erro: "new row violates row-level security policy"

Você tentou inserir sem desabilitar o RLS. Execute:

```sql
ALTER TABLE public.profile DISABLE ROW LEVEL SECURITY;
-- Faça o INSERT aqui
ALTER TABLE public.profile ENABLE ROW LEVEL SECURITY;
```

### Erro: "duplicate key value violates unique constraint"

O email ou user_id já existe. Verifique:

```sql
SELECT * FROM public.profile WHERE email = 'admin@seudominio.com';
SELECT * FROM auth.users WHERE email = 'admin@seudominio.com';
```

### Não consigo fazer login

1. Verifique se o email foi confirmado:
```sql
UPDATE auth.users 
SET email_confirmed_at = now() 
WHERE email = 'admin@seudominio.com';
```

2. Verifique se o perfil está ativo:
```sql
UPDATE public.profile 
SET ativo = true 
WHERE email = 'admin@seudominio.com';
```

## Segurança

⚠️ **IMPORTANTE**: 

1. Sempre reabilite o RLS após criar o primeiro admin
2. Use senhas fortes para contas de administrador
3. Não compartilhe credenciais de administrador
4. Considere usar autenticação de dois fatores (2FA) se disponível
5. Mantenha um registro de todos os administradores do sistema

## Próximos Passos

Após criar o primeiro administrador:

1. Faça login no sistema
2. Teste o acesso às funcionalidades
3. Crie outros administradores se necessário
4. Configure as permissões dos funcionários
5. Documente quem são os administradores do sistema

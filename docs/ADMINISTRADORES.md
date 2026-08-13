# Gerenciamento de Administradores

## Visão Geral

A tabela `profile` foi criada para gerenciar usuários administradores do sistema. Diferente dos funcionários (que possuem níveis de acesso e permissões específicas), os administradores têm **acesso total** ao sistema.

## Características

- **Acesso Total**: Administradores têm permissão completa em todas as funcionalidades
- **Sem Interface**: O cadastro é feito diretamente no banco de dados (não há tela no sistema)
- **Segurança**: Utiliza RLS (Row Level Security) do Supabase
- **Vinculação**: Cada perfil está vinculado a um usuário do `auth.users`

## Estrutura da Tabela

```sql
CREATE TABLE public.profile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) UNIQUE NOT NULL,
  nome VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  telefone VARCHAR(20),
  ativo BOOLEAN DEFAULT true,
  criado_em TIMESTAMPTZ DEFAULT now(),
  atualizado_em TIMESTAMPTZ DEFAULT now()
);
```

## Como Criar um Administrador

### Passo 1: Criar usuário no Auth

Primeiro, crie o usuário na tabela `auth.users` do Supabase:

```sql
-- Opção 1: Via Dashboard do Supabase
-- Vá em Authentication > Users > Add User

-- Opção 2: Via SQL (requer privilégios de admin)
-- Nota: Normalmente feito via Dashboard
```

### Passo 2: Criar perfil de administrador

Após criar o usuário no auth, vincule-o à tabela `profile`:

```sql
-- Substitua os valores conforme necessário
INSERT INTO public.profile (user_id, nome, email, telefone, ativo)
VALUES (
  'UUID_DO_USUARIO_AUTH',  -- UUID do usuário criado no auth.users
  'Nome do Administrador',
  'admin@exemplo.com',
  '(11) 98765-4321',
  true
);
```

### Exemplo Completo

```sql
-- 1. Primeiro, obtenha o UUID do usuário criado no auth
SELECT id, email FROM auth.users WHERE email = 'admin@exemplo.com';

-- 2. Use o UUID retornado para criar o perfil
INSERT INTO public.profile (user_id, nome, email, telefone, ativo)
VALUES (
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',  -- UUID obtido acima
  'João Silva',
  'admin@exemplo.com',
  '(11) 98765-4321',
  true
);
```

## Gerenciamento via SQL

### Listar todos os administradores

```sql
SELECT 
  p.id,
  p.nome,
  p.email,
  p.telefone,
  p.ativo,
  p.criado_em,
  u.email as email_auth
FROM public.profile p
JOIN auth.users u ON p.user_id = u.id
ORDER BY p.nome;
```

### Desativar um administrador

```sql
UPDATE public.profile
SET ativo = false
WHERE email = 'admin@exemplo.com';
```

### Reativar um administrador

```sql
UPDATE public.profile
SET ativo = true
WHERE email = 'admin@exemplo.com';
```

### Atualizar dados de um administrador

```sql
UPDATE public.profile
SET 
  nome = 'Novo Nome',
  telefone = '(11) 99999-9999'
WHERE email = 'admin@exemplo.com';
```

### Deletar um administrador

```sql
-- Isso também remove o usuário do auth.users devido ao ON DELETE CASCADE
DELETE FROM public.profile
WHERE email = 'admin@exemplo.com';
```

## Uso no Código

### Verificar se usuário é admin

```typescript
import { authService } from '@/services';

const isAdmin = await authService.isAdmin();
if (isAdmin) {
  // Usuário é administrador
}
```

### Usar o hook useProfile

```typescript
import { useProfile } from '@/hooks';

function MeuComponente() {
  const { profile, isAdmin, loading } = useProfile();

  if (loading) return <div>Carregando...</div>;
  
  if (!isAdmin) {
    return <div>Acesso negado</div>;
  }

  return (
    <div>
      <h1>Bem-vindo, {profile?.nome}</h1>
      <p>Email: {profile?.email}</p>
    </div>
  );
}
```

### Usar o profileService diretamente

```typescript
import { profileService } from '@/services';

// Buscar perfil do usuário logado
const profile = await profileService.getProfile();

// Verificar se é admin
const isAdmin = await profileService.isAdmin();

// Listar todos os perfis (apenas para admins)
const allProfiles = await profileService.getAllProfiles();

// Atualizar perfil
await profileService.updateProfile(profileId, {
  nome: 'Novo Nome',
  telefone: '(11) 99999-9999'
});

// Desativar perfil
await profileService.deactivateProfile(profileId);

// Ativar perfil
await profileService.activateProfile(profileId);
```

## Diferenças entre Administradores e Funcionários

| Característica | Administradores (profile) | Funcionários (funcionarios) |
|----------------|---------------------------|----------------------------|
| Acesso | Total ao sistema | Baseado em função/permissões |
| Cadastro | Direto no banco de dados | Interface no sistema |
| Tabela | `profile` | `funcionarios` |
| Funções | Não aplicável | atendente, garcom, entregador |
| Permissões | Todas | Customizáveis por função |

## Políticas de Segurança (RLS)

As seguintes políticas estão ativas na tabela `profile`:

### Políticas de SELECT (Visualização)
1. **Usuários podem ver seu próprio perfil**: Qualquer usuário autenticado pode consultar seu próprio perfil
2. **Administradores podem ver todos os perfis**: Administradores ativos podem visualizar todos os perfis

### Políticas de UPDATE (Atualização)
3. **Usuários podem atualizar seu próprio perfil**: Usuários podem atualizar apenas seu próprio perfil
4. **Administradores podem atualizar qualquer perfil**: Administradores ativos podem atualizar qualquer perfil

### Políticas de INSERT (Inserção)
5. **Administradores podem inserir perfis**: Apenas administradores ativos podem criar novos perfis

### Políticas de DELETE (Exclusão)
6. **Administradores podem deletar perfis**: Apenas administradores ativos podem deletar perfis

**Nota Importante**: A primeira política de SELECT permite que qualquer usuário autenticado veja seu próprio perfil, evitando loops infinitos ao verificar se o usuário é administrador.

## Boas Práticas

1. **Primeiro Admin**: O primeiro administrador deve ser criado manualmente via SQL
2. **Emails Únicos**: Certifique-se de que o email é único tanto no `auth.users` quanto no `profile`
3. **Senhas Fortes**: Use senhas fortes para contas de administrador
4. **Auditoria**: Mantenha registro de quem são os administradores ativos
5. **Desativação**: Prefira desativar (`ativo = false`) ao invés de deletar
6. **Backup**: Sempre faça backup antes de modificar perfis de administradores

## Troubleshooting

### Erro: "new row violates row-level security policy"

Isso ocorre quando você tenta inserir um perfil sem ser um administrador. Para o primeiro admin, você precisa desabilitar temporariamente o RLS ou usar privilégios de superusuário.

### Erro: "duplicate key value violates unique constraint"

O email ou user_id já existe. Verifique se o usuário já tem um perfil criado.

### Não consigo fazer login como admin

1. Verifique se o usuário existe no `auth.users`
2. Verifique se o perfil existe no `profile` e está vinculado ao `user_id` correto
3. Verifique se o campo `ativo` está como `true`

## Migração

A migration foi criada em: `supabase/migrations/YYYYMMDD_create_profile_table.sql`

Para aplicar em outro ambiente:

```bash
# Via Supabase CLI
supabase db push

# Ou via MCP (já aplicado)
# A migration já foi aplicada no projeto atual
```

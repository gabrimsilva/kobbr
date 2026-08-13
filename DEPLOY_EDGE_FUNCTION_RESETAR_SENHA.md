# Deploy da Edge Function: resetar-senha-usuario

## 📋 Resumo

A funcionalidade de **reset de senha** foi implementada e requer o deploy de uma Edge Function no Supabase.

## ✅ O que foi implementado

### Frontend (`src/pages/Usuarios.tsx`)
- ✅ Botão **KeyRound** (chave azul) para resetar senha
- ✅ Modal de reset com validação de senha (mínimo 6 caracteres)
- ✅ Confirmação de senha (digitar duas vezes)
- ✅ Validações em tempo real no formulário
- ✅ Registro em auditoria após reset

### Backend (`src/services/usuarioService.ts`)
- ✅ Método `resetarSenha(id: string, novaSenha: string)`
- ✅ Validação de senha mínima de 6 caracteres
- ✅ Chamada para Edge Function com user_id

### Edge Function (`supabase/functions/resetar-senha-usuario/index.ts`)
- ✅ Autenticação via JWT
- ✅ Validação de permissões (apenas Admin Geral e Admin de Estabelecimento)
- ✅ Admin de Estabelecimento só pode resetar senha do próprio estabelecimento
- ✅ Reset de senha via `auth.admin.updateUserById()` com service role

## 🚀 Como fazer o deploy da Edge Function

### Pré-requisitos
1. Supabase CLI instalado: `npm install -g supabase`
2. Login no Supabase: `supabase login`
3. Link com o projeto: `supabase link --project-ref SEU_PROJECT_REF`

### Comando de deploy

```bash
supabase functions deploy resetar-senha-usuario
```

### Configuração necessária no Supabase Dashboard

A Edge Function precisa das seguintes variáveis de ambiente (já configuradas automaticamente pelo Supabase):
- `SUPABASE_URL` - URL do projeto
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key (admin)

## 🎯 Permissões

| Perfil | Pode resetar senha? | Escopo |
|--------|---------------------|--------|
| **Admin Geral** | ✅ Sim | Todos os estabelecimentos |
| **Admin de Estabelecimento** | ✅ Sim | Apenas do próprio estabelecimento |
| **Operador** | ❌ Não | Sem permissão |

## 🔒 Segurança

1. **Service Role**: A Edge Function usa a service role key que tem acesso administrativo ao Auth
2. **Validação de permissões**: Verifica o perfil do usuário logado
3. **Validação de estabelecimento**: Admin de Estabelecimento só pode resetar do próprio prédio
4. **Validação de senha**: Mínimo 6 caracteres, confirmação obrigatória
5. **Auditoria**: Todos os resets são registrados com usuário, data e horário

## 📝 Uso no sistema

1. Acesse **Configurações > Usuários**
2. Clique no botão **chave azul** (🔑) na linha do usuário
3. Digite a nova senha (mínimo 6 caracteres)
4. Confirme a senha
5. Clique em **Resetar senha**
6. A operação é registrada em auditoria

## 🔍 Verificação

Após o deploy, teste:

```bash
# Verificar se a função foi deployed
supabase functions list

# Ver logs em tempo real
supabase functions logs resetar-senha-usuario
```

## ⚠️ Importante

- O usuário **não** é notificado por email sobre o reset de senha
- A senha é alterada imediatamente
- O usuário deve ser informado manualmente da nova senha
- Considere implementar envio de email para notificação futura

## 🛠️ Troubleshooting

### Erro: "Edge Function não encontrada"
- Verifique se fez o deploy: `supabase functions deploy resetar-senha-usuario`

### Erro: "Apenas administradores podem resetar senhas"
- Verifique o perfil do usuário logado em `usuarios_estabelecimento`

### Erro: "Você só pode resetar senhas de usuários do seu estabelecimento"
- Admin de Estabelecimento tentou resetar senha de outro estabelecimento

## 📦 Arquivos modificados

- ✅ `src/pages/Usuarios.tsx` - Interface e modal
- ✅ `src/services/usuarioService.ts` - Método resetarSenha
- ✅ `supabase/functions/resetar-senha-usuario/index.ts` - Edge Function (NOVO)

## ⏭️ Próximos passos (opcional)

1. Implementar envio de email com nova senha
2. Permitir que usuário resete própria senha
3. Adicionar força da senha (fraca/média/forte)
4. Implementar reset via email (forgot password)

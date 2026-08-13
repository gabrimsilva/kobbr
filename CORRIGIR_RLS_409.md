# Corrigir Erro 409 Conflict - Row Level Security (RLS)

## Problema
O erro 409 Conflict indica que as políticas de Row Level Security (RLS) do Supabase estão bloqueando operações.

## Solução

### 1. Acessar o Supabase Dashboard
1. Acesse https://supabase.com/dashboard
2. Selecione seu projeto
3. Vá em **Authentication** > **Policies**

### 2. Verificar Tabelas Principais

Para cada tabela abaixo, você precisa ter políticas que permitam:
- SELECT (leitura)
- INSERT (criação)
- UPDATE (atualização)
- DELETE (exclusão)

#### Tabelas críticas:
- `profile` (perfil do administrador)
- `funcionarios` (funcionários)
- `produtos` (produtos)
- `categorias` (categorias)
- `pedidos` (pedidos)
- `sales` (vendas PDV)
- `comandas` (comandas)
- `configuracoes` (configurações do sistema)
- `stock_items` (estoque)
- `stock_variants` (variantes de estoque)

### 3. Política Temporária (Para Teste)

Se você quiser testar rapidamente, pode **TEMPORARIAMENTE** desabilitar o RLS:

```sql
-- ATENÇÃO: Use apenas para teste! Não deixe assim em produção!

-- Desabilitar RLS temporariamente
ALTER TABLE profile DISABLE ROW LEVEL SECURITY;
ALTER TABLE funcionarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE produtos DISABLE ROW LEVEL SECURITY;
ALTER TABLE categorias DISABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos DISABLE ROW LEVEL SECURITY;
ALTER TABLE sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE comandas DISABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE stock_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE stock_variants DISABLE ROW LEVEL SECURITY;
```

### 4. Política Correta (Recomendado)

Execute este SQL no Supabase SQL Editor para criar políticas corretas:

```sql
-- Política para profile (administradores)
CREATE POLICY "Admins podem fazer tudo" ON profile
  FOR ALL
  USING (auth.uid() = user_id);

-- Política para funcionarios
CREATE POLICY "Funcionarios autenticados podem ler" ON funcionarios
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins podem gerenciar funcionarios" ON funcionarios
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profile
      WHERE profile.user_id = auth.uid()
      AND profile.ativo = true
    )
  );

-- Política para produtos (todos autenticados podem ler)
CREATE POLICY "Todos podem ler produtos" ON produtos
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins podem gerenciar produtos" ON produtos
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profile
      WHERE profile.user_id = auth.uid()
      AND profile.ativo = true
    )
  );

-- Política para categorias
CREATE POLICY "Todos podem ler categorias" ON categorias
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins podem gerenciar categorias" ON categorias
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profile
      WHERE profile.user_id = auth.uid()
      AND profile.ativo = true
    )
  );

-- Política para pedidos
CREATE POLICY "Todos podem ler pedidos" ON pedidos
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Todos podem criar pedidos" ON pedidos
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admins podem gerenciar pedidos" ON pedidos
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profile
      WHERE profile.user_id = auth.uid()
      AND profile.ativo = true
    )
  );

-- Política para sales (vendas PDV)
CREATE POLICY "Todos podem ler vendas" ON sales
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Todos podem criar vendas" ON sales
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admins podem gerenciar vendas" ON sales
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profile
      WHERE profile.user_id = auth.uid()
      AND profile.ativo = true
    )
  );

-- Política para comandas
CREATE POLICY "Todos podem ler comandas" ON comandas
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Todos podem criar comandas" ON comandas
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admins podem gerenciar comandas" ON comandas
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profile
      WHERE profile.user_id = auth.uid()
      AND profile.ativo = true
    )
  );

-- Política para configuracoes
CREATE POLICY "Todos podem ler configuracoes" ON configuracoes
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins podem gerenciar configuracoes" ON configuracoes
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profile
      WHERE profile.user_id = auth.uid()
      AND profile.ativo = true
    )
  );

-- Política para stock_items
CREATE POLICY "Todos podem ler estoque" ON stock_items
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins podem gerenciar estoque" ON stock_items
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profile
      WHERE profile.user_id = auth.uid()
      AND profile.ativo = true
    )
  );

-- Política para stock_variants
CREATE POLICY "Todos podem ler variantes" ON stock_variants
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins podem gerenciar variantes" ON stock_variants
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profile
      WHERE profile.user_id = auth.uid()
      AND profile.ativo = true
    )
  );
```

### 5. Verificar se Funcionou

Após aplicar as políticas:
1. Faça logout do sistema
2. Limpe o cache do navegador (Ctrl+Shift+Delete)
3. Faça login novamente
4. Teste as operações

### 6. Se Ainda Não Funcionar

Verifique no console do navegador (F12) qual tabela específica está dando erro 409 e ajuste a política dessa tabela.

## Observação Importante

As políticas RLS são essenciais para segurança. Não deixe as tabelas sem RLS em produção!

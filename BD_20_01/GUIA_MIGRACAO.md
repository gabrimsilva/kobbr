# 🔄 Guia de Migração - Banco de Dados

## 📋 Pré-requisitos

Antes de executar a migração, verifique:

- [ ] Backup completo do banco atual
- [ ] Acesso ao Supabase Dashboard ou psql
- [ ] Permissões de administrador no banco
- [ ] PostgreSQL 17+ (verificar versão)

## ⚠️ IMPORTANTE - Leia Antes de Executar

### ✅ Seguro para Executar
- ✅ Scripts são **idempotentes** (podem rodar múltiplas vezes)
- ✅ Usa `CREATE IF NOT EXISTS` para evitar erros
- ✅ Usa `ON CONFLICT` para inserções seguras
- ✅ **NÃO apaga dados existentes**
- ✅ Apenas adiciona/atualiza estrutura

### ⚙️ O que os Scripts Fazem
- Criam tabelas que não existem
- Adicionam colunas faltantes (se necessário)
- Atualizam políticas RLS
- Criam/atualiza índices
- Configura triggers
- Cria views úteis

### ❌ O que os Scripts NÃO Fazem
- ❌ Não deletam tabelas
- ❌ Não removem colunas
- ❌ Não apagam dados
- ❌ Não alteram tipos de dados existentes

## 🚀 Método 1: Execução Completa (Recomendado)

### Via Supabase SQL Editor

1. **Acesse o SQL Editor**
   - Vá para seu projeto no Supabase
   - Clique em "SQL Editor" no menu lateral

2. **Execute o Script Master**
   ```sql
   -- Copie e cole TODO o conteúdo de 00_EXECUTAR_TUDO.sql
   -- Clique em "Run" ou pressione Ctrl+Enter
   ```

3. **Aguarde a Execução**
   - O processo leva ~30-60 segundos
   - Verifique se há erros no console

4. **Verifique o Resultado**
   ```sql
   -- Verificar tabelas criadas
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public'
   ORDER BY table_name;
   
   -- Deve retornar 24 tabelas
   ```

### Via psql (Linha de Comando)

```bash
# 1. Conectar ao banco
psql -h db.seu-projeto.supabase.co -U postgres -d postgres

# 2. Executar script master
\i BD_20_01/00_EXECUTAR_TUDO.sql

# 3. Verificar execução
\dt public.*
```

## 🔧 Método 2: Execução Arquivo por Arquivo

Se preferir controle total, execute na ordem:

### 1. Extensões
```sql
\i BD_20_01/01_extensions.sql
```
**Tempo:** ~1 segundo  
**Verifica:** `SELECT * FROM pg_extension;`

### 2. Funções
```sql
\i BD_20_01/02_functions.sql
```
**Tempo:** ~2 segundos  
**Verifica:** `\df public.*`

### 3. Tabelas
```sql
\i BD_20_01/03_tables.sql
```
**Tempo:** ~10 segundos  
**Verifica:** `\dt public.*`

### 4. Índices
```sql
\i BD_20_01/04_indexes.sql
```
**Tempo:** ~5 segundos  
**Verifica:** `\di public.*`

### 5. Triggers
```sql
\i BD_20_01/05_triggers.sql
```
**Tempo:** ~3 segundos  
**Verifica:** `SELECT * FROM information_schema.triggers;`

### 6. Políticas RLS
```sql
\i BD_20_01/06_rls_policies.sql
```
**Tempo:** ~10 segundos  
**Verifica:** `SELECT * FROM pg_policies;`

### 7. Storage e Config
```sql
\i BD_20_01/07_storage_and_config.sql
```
**Tempo:** ~5 segundos  
**Verifica:** `SELECT * FROM storage.buckets;`

### 8. Views
```sql
\i BD_20_01/08_views.sql
```
**Tempo:** ~2 segundos  
**Verifica:** `\dv public.*`

## ✅ Checklist Pós-Migração

### 1. Verificar Tabelas
```sql
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public';
-- Deve retornar 22
```

### 2. Verificar Índices
```sql
SELECT COUNT(*) FROM pg_indexes 
WHERE schemaname = 'public';
-- Deve retornar ~40+
```

### 3. Verificar RLS
```sql
SELECT tablename, COUNT(*) as policies
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename;
-- Todas as tabelas devem ter políticas
```

### 4. Verificar Storage Buckets
```sql
SELECT * FROM storage.buckets;
-- Deve retornar 3 buckets:
-- - produtos-imagens
-- - sistema-imagens
-- - ia-uploads
```

### 5. Verificar Views
```sql
SELECT COUNT(*) FROM information_schema.views 
WHERE table_schema = 'public';
-- Deve retornar 10
```

### 6. Verificar Funções
```sql
SELECT COUNT(*) FROM pg_proc 
WHERE pronamespace = 'public'::regnamespace;
-- Deve retornar 7+
```

## 🔍 Troubleshooting

### Erro: "permission denied"
**Solução:** Use o usuário `postgres` ou um usuário com privilégios de superusuário

### Erro: "relation already exists"
**Solução:** Normal! Os scripts são idempotentes. Continue a execução.

### Erro: "column already exists"
**Solução:** Normal! O script detecta e ignora. Continue.

### Erro: "policy already exists"
**Solução:** Os scripts fazem DROP antes de CREATE. Se persistir, execute:
```sql
-- Remover todas as políticas de uma tabela
DROP POLICY IF EXISTS "nome_da_policy" ON nome_tabela;
```

### Erro: "function does not exist"
**Solução:** Execute o arquivo `02_functions.sql` novamente

## 📊 Comparação: Antes vs Depois

### Tabelas Novas (se não existiam)
- `ia_config` - Configurações do assistente IA
- `ia_conversas` - Conversas com IA
- `ia_arquivos_temp` - Arquivos temporários
- `profile` - Perfis de administradores

### Colunas Novas em Tabelas Existentes
- `pedidos.mercado_pago_date_approved` - Data de aprovação MP
- `pedidos.taxa_extra_km` - Taxa por distância
- `funcionarios.metadata` - Metadados JSON
- `funcionarios.bloqueado` - Flag de bloqueio
- `sabores.descricao` - Descrição do sabor

### Índices Novos
- Índices para Mercado Pago
- Índices para IA
- Índices para Google Analytics

## 🔄 Rollback (Se Necessário)

Se algo der errado, você pode:

### 1. Restaurar Backup
```bash
# Restaurar do backup
pg_restore -h db.seu-projeto.supabase.co -U postgres -d postgres backup.dump
```

### 2. Remover Tabelas Novas (Cuidado!)
```sql
-- APENAS se você quiser remover as tabelas de IA
DROP TABLE IF EXISTS ia_arquivos_temp CASCADE;
DROP TABLE IF EXISTS ia_conversas CASCADE;
DROP TABLE IF EXISTS ia_config CASCADE;
```

## 📞 Suporte

Se encontrar problemas:

1. Verifique os logs de erro
2. Confirme a versão do PostgreSQL
3. Verifique permissões do usuário
4. Consulte a documentação do Supabase

## 🎯 Próximos Passos

Após a migração bem-sucedida:

1. ✅ Testar login de administrador
2. ✅ Testar criação de pedido
3. ✅ Verificar políticas RLS
4. ✅ Testar upload de imagens
5. ✅ Configurar Edge Functions (se necessário)
6. ✅ Inserir dados iniciais (categorias, produtos)

---

**Tempo Total Estimado:** 5-10 minutos  
**Dificuldade:** Baixa  
**Risco:** Muito Baixo (scripts idempotentes)  
**Requer Downtime:** Não

# Migrações - Consumo Interno (Phase 1: Database & Backend)

## Visão Geral

Este diretório contém 4 migrações SQL que implementam a infraestrutura de banco de dados para a feature **Consumo Interno** no PDV.

### Ordem de Execução (IMPORTANTE)

As migrações **devem ser executadas em ordem**:

1. `01_create_internal_consumptions_table.sql` - Task 1.1
2. `02_rls_policies_internal_consumptions.sql` - Task 1.2
3. `03_rpc_registrar_consumo_interno.sql` - Task 1.3
4. `04_rpc_obter_consumos_por_periodo.sql` - Task 1.4

---

## Detalhes de Cada Migração

### 1️⃣ Migration 01 - Criar Tabelas (Task 1.1)

**Arquivo**: `01_create_internal_consumptions_table.sql`

**O que faz**:
- Adiciona coluna `is_internal_consumption` em `sales` (marca vendas internas)
- Cria tabela `internal_consumptions` com 8 colunas obrigatórias
- Cria índices de performance para queries de período
- Habilita RLS (políticas base temporárias)

**Dependências**: 
- Tabelas `sales`, `estabelecimentos`, `auth.users` já existem

**Critérios de Sucesso**:
- ✅ Tabela `internal_consumptions` criada
- ✅ Coluna `is_internal_consumption` em `sales`
- ✅ Índices (estabelecimento_id, data) criados
- ✅ RLS habilitado
- ✅ Sem erros de execução

---

### 2️⃣ Migration 02 - RLS Policies (Task 1.2)

**Arquivo**: `02_rls_policies_internal_consumptions.sql`

**O que faz**:
- Substitui políticas RLS com isolamento por `estabelecimento_id`
- SELECT: usuário vê apenas consumos de seu estabelecimento
- INSERT: usuário só pode inserir em seu estabelecimento
- UPDATE: desabilitado (consumos são imutáveis)
- DELETE: desabilitado (consumos são imutáveis)
- Cria função helper `validar_acesso_consumo_interno()`

**Dependências**: 
- Migration 01 (tabela `internal_consumptions`)
- Função `public.get_current_estabelecimento_id()` (do projeto multi-tenant)

**Critérios de Sucesso**:
- ✅ Políticas RLS aplicadas corretamente
- ✅ Usuário de EST-A não vê consumos de EST-B
- ✅ Função helper criada e funcional
- ✅ Sem erros de execução

---

### 3️⃣ Migration 03 - RPC registrar_consumo_interno() (Task 1.3)

**Arquivo**: `03_rpc_registrar_consumo_interno.sql`

**O que faz**:
- Cria RPC function `registrar_consumo_interno()`
- Processa de forma **ATÔMICA**:
  1. Cria venda interna (sem cliente, sem pagamento)
  2. Registra consumo em `internal_consumptions`
  3. Decrementa estoque em `stock_items`
  4. Cria movimento de estoque em `stock_movements`
- Validações completas (stock insuficiente, estabelecimento inválido, etc)
- Tratamento de erros com rollback automático

**Dependências**: 
- Migrations 01-02
- Tabelas: `sales`, `internal_consumptions`, `stock_items`, `stock_movements`, `estabelecimentos`

**Exemplo de Uso**:
```sql
SELECT public.registrar_consumo_interno(
    p_estabelecimento_id := '550e8400-e29b-41d4-a716-446655440000'::uuid,
    p_items := '[
        {
            "product_id": "550e8400-e29b-41d4-a716-446655440001",
            "product_name": "Pizza Margherita",
            "quantity": 2,
            "unit_price": 25.00
        }
    ]'::jsonb,
    p_created_by := NULL
);
```

**Retorno de Sucesso**:
```json
{
  "success": true,
  "consumption_id": "550e8400-e29b-41d4-a716-446655440002",
  "sale_id": "550e8400-e29b-41d4-a716-446655440003",
  "sale_number": "INT-2026-01-26-10-30-45-...",
  "total_quantity": 2,
  "message": "Consumo interno registrado com sucesso"
}
```

**Critérios de Sucesso**:
- ✅ RPC criada e exposição como endpoint Supabase
- ✅ Consumo registrado com sucesso
- ✅ Stock decrementado corretamente
- ✅ Movimento de estoque criado
- ✅ Erro se stock insuficiente (com mensagem clara)
- ✅ Transação atômica (rollback se qualquer etapa falhar)

---

### 4️⃣ Migration 04 - RPC obter_consumos_por_periodo() (Task 1.4)

**Arquivo**: `04_rpc_obter_consumos_por_periodo.sql`

**O que faz**:
- Cria RPC function `obter_consumos_por_periodo()`
- Retorna dados agregados de consumos internos por período
- Suporta 3 granularidades: diária, semanal, mensal
- Performance < 500ms com 1000+ registros (otimizado com índice)

**Dependências**: 
- Migrations 01-02
- Tabela: `internal_consumptions` com índice de performance

**Exemplo de Uso**:
```sql
SELECT * FROM public.obter_consumos_por_periodo(
    p_estabelecimento_id := '550e8400-e29b-41d4-a716-446655440000'::uuid,
    p_data_inicio := '2026-01-01'::date,
    p_data_fim := '2026-01-26'::date,
    p_granularidade := 'dia'
);
```

**Retorno Esperado (Granularidade Diária)**:
```
periodo    | total_unidades | total_transacoes | media_unidades_transacao
-----------|----------------|------------------|------------------------
2026-01-20 | 45             | 5                | 9.00
2026-01-21 | 32             | 4                | 8.00
2026-01-22 | 18             | 2                | 9.00
```

**Critérios de Sucesso**:
- ✅ RPC criada e acessível
- ✅ Granularidade diária: retorna dados agrupados por data
- ✅ Granularidade semanal: retorna dados agrupados por semana
- ✅ Granularidade mensal: retorna dados agrupados por mês
- ✅ Performance < 500ms com 1000+ registros
- ✅ Retorna array vazio se nenhum dado no período
- ✅ RLS aplicada (usuário só vê dados de seu estabelecimento)

---

## Como Executar as Migrações

### Opção 1: Via Supabase CLI (Recomendado)

```bash
# Navegar para o diretório do projeto
cd c:\Users\gmsilva\Desktop\SISTEMAS\_RODANDO\casa_do_pai

# Executar cada migration em ordem
supabase db push
```

### Opção 2: Via Editor SQL do Supabase Dashboard

1. Abrir [Supabase Dashboard](https://app.supabase.com)
2. Ir para **SQL Editor**
3. Colar o conteúdo de cada arquivo SQL em ordem
4. Executar e verificar resultado
5. Repetir para próxima migration

### Opção 3: Via DBeaver / pgAdmin

1. Conectar ao banco de dados PostgreSQL do Supabase
2. Abrir cada arquivo SQL
3. Executar e verificar resultado
4. Repetir para próxima migration

---

## Verificação Pós-Migração

Após executar todas as 4 migrations, verificar:

```sql
-- 1. Verificar tabelas criadas
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('internal_consumptions', 'sales') 
AND table_schema = 'public';

-- 2. Verificar colunas em sales
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'sales' AND column_name = 'is_internal_consumption';

-- 3. Verificar índices
SELECT indexname FROM pg_indexes 
WHERE tablename = 'internal_consumptions';

-- 4. Verificar RLS está habilitado
SELECT tablename, rowsecurity FROM pg_tables 
WHERE tablename = 'internal_consumptions' AND schemaname = 'public';

-- 5. Verificar RPC functions existem
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE 'registrar_%' OR routine_name LIKE 'obter_%';
```

---

## Troubleshooting

### Erro: "Função get_current_estabelecimento_id() não existe"

**Solução**: A função helper é do projeto multi-tenant. Verificar:
1. Se as migrações multi-tenant foram executadas (`09b_funcoes_rls.sql`)
2. Se a função está no schema `public`

```sql
SELECT * FROM information_schema.routines 
WHERE routine_name = 'get_current_estabelecimento_id';
```

### Erro: "Coluna estabelecimento_id não existe em estabelecimentos"

**Solução**: Verificar se a tabela `estabelecimentos` foi criada corretamente em `BD_20_01 Novo banco - atual/09_estabelecimentos.sql`

### Erro: "Transação automaticamente revertida" ao chamar registrar_consumo_interno()

**Solução**: Verificar:
1. Stock suficiente: `SELECT * FROM stock_items WHERE product_id = '...'`
2. Estabelecimento correto: `SELECT id FROM estabelecimentos`
3. Estrutura de `p_items` (deve ser JSONB array com product_id, quantity)

### Erro: RLS Policy rejeitando INSERT

**Solução**: Verificar contexto de estabelecimento:
```sql
SELECT public.get_current_estabelecimento_id();
```

Se retornar NULL, o usuário não tem estabelecimento vinculado.

---

## Próximos Passos

Após essas 4 migrações (Phase 1), prosseguir com:

- **Phase 2**: Implementar UI no frontend (checkbox PDV, lógica, validações)
- **Phase 3**: Adicionar métricas (card, gráfico, integração)
- **Phase 4**: Testes e deploy para produção

---

## Arquivos Relacionados

- `.kiro/specs/consumo-interno/tasks.md` - Especificação completa
- `.kiro/specs/consumo-interno/tests/` - Testes de integração
- `BD_20_01 Novo banco - atual/` - Schema canônico (referência)
- `supabase/functions/` - Edge Functions (se necessário)

---

**Última atualização**: 26/01/2026
**Status**: ✅ Phase 1 (Database) - Pronta para execução

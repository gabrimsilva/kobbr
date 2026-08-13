# 🧾 Migração: Sistema de Cupom Fiscal e Impressão

## 📋 Descrição

Esta migração adiciona suporte completo para geração e impressão de cupons fiscais (recibos) para vendas PDV e pedidos delivery.

## 🗄️ Mudanças no Banco de Dados

### 1. Nova Tabela: `print_jobs`

Gerencia jobs de impressão com rastreamento de status e tentativas.

**Campos:**
- `id` (UUID) - Identificador único
- `ref_type` (VARCHAR) - Tipo: 'SALE' ou 'ORDER'
- `ref_id` (UUID) - ID da venda ou pedido
- `printer_name` (VARCHAR) - Nome da impressora
- `status` (VARCHAR) - Status: PENDING, SENT, PRINTED, FAILED, CANCELED
- `attempts` (INT) - Número de tentativas
- `error_message` (TEXT) - Mensagem de erro
- `created_at` (TIMESTAMP) - Data de criação
- `updated_at` (TIMESTAMP) - Data de atualização

### 2. Tabela `sales` (Modificada)

**Novos campos:**
- `receipt_html` (TEXT) - HTML do cupom fiscal
- `printed_at` (TIMESTAMP) - Data da primeira impressão

### 3. Tabela `pedidos` (Modificada)

**Novos campos:**
- `receipt_html` (TEXT) - HTML do cupom/recibo
- `printed_at` (TIMESTAMP) - Data da primeira impressão

## 🚀 Como Executar

### Opção 1: Supabase SQL Editor (Recomendado)

1. Acesse o Supabase Dashboard
2. Vá em SQL Editor
3. Copie e cole o conteúdo de cada arquivo na ordem:
   - `01_criar_tabela_print_jobs.sql`
   - `02_adicionar_campos_cupom_sales.sql`
   - `03_adicionar_campos_cupom_pedidos.sql`
4. Execute cada script

### Opção 2: Script Único

Execute o arquivo `00_EXECUTAR_MIGRACAO_CUPOM_FISCAL.sql` que executa todos os scripts na ordem correta.

### Opção 3: Via psql (Terminal)

```bash
psql -h [HOST] -U [USER] -d [DATABASE] -f 00_EXECUTAR_MIGRACAO_CUPOM_FISCAL.sql
```

## ✅ Validação

Após executar a migração, valide com:

```sql
-- Verificar se tabela print_jobs existe
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'print_jobs'
);

-- Verificar campos em sales
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'sales' 
  AND column_name IN ('receipt_html', 'printed_at');

-- Verificar campos em pedidos
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'pedidos' 
  AND column_name IN ('receipt_html', 'printed_at');
```

## 🔄 Rollback (Reverter)

Se necessário reverter as mudanças:

```sql
-- Remover tabela print_jobs
DROP TABLE IF EXISTS print_jobs CASCADE;

-- Remover campos de sales
ALTER TABLE sales DROP COLUMN IF EXISTS receipt_html;
ALTER TABLE sales DROP COLUMN IF EXISTS printed_at;

-- Remover campos de pedidos
ALTER TABLE pedidos DROP COLUMN IF EXISTS receipt_html;
ALTER TABLE pedidos DROP COLUMN IF EXISTS printed_at;
```

## 📊 Impacto

- ✅ Não afeta dados existentes
- ✅ Não quebra funcionalidades atuais
- ✅ Adiciona apenas novos campos (nullable)
- ✅ Performance otimizada com índices

## 🎯 Próximos Passos

Após executar esta migração:
1. Implementar serviço de geração de cupom (ETAPA 2)
2. Criar interface de visualização (ETAPA 3)
3. Implementar impressão automática (ETAPA 4)

---

**Data:** 28/02/2026  
**Versão:** 1.0.0  
**Status:** ✅ Pronto para execução

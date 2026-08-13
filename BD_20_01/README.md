# Estrutura do Banco de Dados - Sistema Pizzaria Delivery
**Data de Criação:** 20/01/2026  
**Versão:** 1.0

## 📋 Descrição

Esta pasta contém a estrutura completa e atualizada do banco de dados do sistema de pizzaria delivery, organizada em arquivos SQL modulares para facilitar manutenção e execução.

## 📁 Estrutura dos Arquivos

```
BD_20_01/
├── 00_EXECUTAR_TUDO.sql      # Script master (executa todos os arquivos)
├── 01_extensions.sql          # Extensões do PostgreSQL
├── 02_functions.sql           # Funções auxiliares
├── 03_tables.sql              # Estrutura de todas as tabelas
├── 04_indexes.sql             # Índices para performance
├── 05_triggers.sql            # Triggers automáticos
├── 06_rls_policies.sql        # Políticas de segurança RLS
├── 07_storage_and_config.sql  # Storage buckets e configurações
├── 08_views.sql               # Views úteis para consultas
└── README.md                  # Este arquivo
```

## 🚀 Como Executar

### Opção 1: Executar Tudo de Uma Vez (Recomendado)

```bash
# Via psql (linha de comando)
psql -h db.seu-projeto.supabase.co -U postgres -d postgres -f 00_EXECUTAR_TUDO.sql

# Ou via Supabase SQL Editor
# Copie e cole o conteúdo de 00_EXECUTAR_TUDO.sql no editor SQL do Supabase
```

### Opção 2: Executar Arquivo por Arquivo

Execute os arquivos na seguinte ordem:

1. `01_extensions.sql` - Extensões necessárias
2. `02_functions.sql` - Funções auxiliares
3. `03_tables.sql` - Criação das tabelas
4. `04_indexes.sql` - Índices de performance
5. `05_triggers.sql` - Triggers automáticos
6. `06_rls_policies.sql` - Políticas de segurança
7. `07_storage_and_config.sql` - Storage e configurações
8. `08_views.sql` - Views úteis

### Opção 3: Via Supabase Dashboard

1. Acesse o Supabase Dashboard
2. Vá em **SQL Editor**
3. Copie e cole o conteúdo de cada arquivo na ordem acima
4. Execute cada script

## ⚠️ Importante

### Scripts Idempotentes
Todos os scripts são **idempotentes**, ou seja, podem ser executados múltiplas vezes sem causar erros. Eles usam:
- `CREATE IF NOT EXISTS` para tabelas, índices e funções
- `DROP POLICY IF EXISTS` seguido de `CREATE POLICY` para políticas RLS
- `ON CONFLICT DO UPDATE` ou `ON CONFLICT DO NOTHING` para inserções

### Execução em Banco Existente
✅ **SEGURO** - Pode ser executado em um banco de dados existente  
✅ **NÃO SOBRESCREVE DADOS** - Apenas atualiza estrutura  
✅ **ATUALIZA ESTRUTURA** - Adiciona novas colunas e tabelas se necessário

## 📊 Tabelas Incluídas

### Principais
- `configuracoes` - Configurações do sistema
- `categorias` - Categorias de produtos
- `produtos` - Produtos disponíveis
- `sabores` - Sabores de pizzas
- `combos` - Combos promocionais
- `pedidos` - Pedidos ativos
- `clientes` - Cadastro de clientes

### Histórico
- `historico_pedidos` - Histórico de status dos pedidos
- `historico_geral` - Pedidos finalizados
- `historico_comandas` - Comandas finalizadas

### Auxiliares
- `tamanhos` - Tamanhos de produtos
- `adicionais` - Adicionais disponíveis
- `estoque` - Controle de estoque
- `funcionarios` - Funcionários do sistema
- `comandas` - Comandas ativas (PDV)
- `avaliacoes` - Avaliações de clientes

### Integrações
- `ia_config` - Configurações do assistente IA
- `ia_conversas` - Conversas com IA
- `ia_arquivos_temp` - Arquivos temporários da IA
- `profile` - Perfis de administradores

## 🔐 Segurança (RLS)

Todas as tabelas possuem **Row Level Security (RLS)** habilitado com políticas apropriadas:
- Leitura pública para dados de produtos e cardápio
- Autenticação necessária para operações administrativas
- Políticas específicas para cada tipo de usuário

## 💾 Storage Buckets

Três buckets são criados automaticamente:
1. **produtos-imagens** - Imagens de produtos (público, 5MB max)
2. **sistema-imagens** - Imagens do sistema (público)
3. **ia-uploads** - Uploads do assistente IA (privado)

## 🔄 Realtime

As seguintes tabelas têm **Realtime** habilitado:
- `pedidos` - Para atualizações em tempo real
- `historico_pedidos` - Para tracking de status

## 👁️ Views Disponíveis

Views criadas para facilitar consultas:
- `vw_conversas_resumo` - Resumo das conversas do assistente IA
- `vw_arquivos_por_conversa` - Arquivos por conversa
- `vw_pedidos_completos` - Pedidos com dados do cliente
- `vw_produtos_com_categoria` - Produtos com categoria completa
- `vw_estatisticas_pedidos_dia` - Estatísticas diárias
- `vw_produtos_mais_vendidos` - Ranking de produtos
- `vw_comandas_abertas` - Comandas abertas com tempo
- `vw_avaliacoes_publicas` - Avaliações aprovadas
- `vw_estoque_baixo` - Itens com estoque baixo
- `vw_funcionarios_ativos` - Funcionários ativos

## 📝 Configurações Iniciais

O script cria automaticamente:
- Configurações de taxa extra por km
- Configuração de tipo de checkout

## 🛠️ Manutenção

### Adicionar Nova Tabela
1. Adicione a estrutura em `03_tables.sql`
2. Adicione índices em `04_indexes.sql` (se necessário)
3. Adicione triggers em `05_triggers.sql` (se necessário)
4. Adicione políticas RLS em `06_rls_policies.sql`

### Adicionar Nova Coluna
1. Use `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` em `03_tables.sql`
2. Adicione índice se necessário em `04_indexes.sql`

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique os logs de execução
2. Confirme que está usando PostgreSQL 17+
3. Verifique se o usuário tem permissões adequadas

## 🔄 Histórico de Versões

### v1.0 (20/01/2026)
- Estrutura inicial completa
- Todas as tabelas do sistema
- Políticas RLS configuradas
- Storage buckets configurados
- Integração com IA e Google Analytics

---

**Desenvolvido para:** Sistema de Pizzaria Delivery  
**Banco de Dados:** PostgreSQL 17+ (Supabase)  
**Última Atualização:** 20/01/2026

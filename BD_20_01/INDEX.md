# 📑 Índice de Documentação - BD_20_01

## 🎯 Comece Aqui

1. **[00_LEIA_PRIMEIRO.md](00_LEIA_PRIMEIRO.md)** ⭐
   - Resumo executivo
   - Início rápido em 3 passos
   - Visão geral do projeto

## 📚 Documentação

### Guias de Uso
2. **[README.md](README.md)**
   - Documentação completa
   - Como executar os scripts
   - Estrutura dos arquivos
   - Configurações e segurança

3. **[GUIA_MIGRACAO.md](GUIA_MIGRACAO.md)**
   - Passo a passo detalhado
   - Checklist pré-migração
   - Troubleshooting
   - Rollback (se necessário)

### Referência Técnica
4. **[ESTRUTURA_BANCO.md](ESTRUTURA_BANCO.md)**
   - Diagrama de relacionamentos
   - Tabelas por categoria
   - Campos importantes
   - Índices e performance
   - Queries úteis

5. **[CHANGELOG.md](CHANGELOG.md)** 🆕
   - Histórico de mudanças
   - Novas funcionalidades
   - Versões do banco

6. **Este arquivo (INDEX.md)**
   - Navegação rápida
   - Índice de todos os arquivos

## 🗂️ Scripts SQL

### Script Master
- **[00_EXECUTAR_TUDO.sql](00_EXECUTAR_TUDO.sql)**
  - Executa todos os scripts na ordem correta
  - **Recomendado para primeira execução**

### Scripts Individuais (Execute nesta ordem)
1. **[01_extensions.sql](01_extensions.sql)**
   - Extensões PostgreSQL (uuid-ossp, pgcrypto)
   
2. **[02_functions.sql](02_functions.sql)**
   - 7 funções auxiliares
   - Triggers de timestamp
   - Funções de limpeza
   
3. **[03_tables.sql](03_tables.sql)**
   - 24 tabelas do sistema
   - Estrutura completa
   - Comentários em todas as colunas
   
4. **[04_indexes.sql](04_indexes.sql)**
   - ~40 índices
   - Otimização de performance
   - Índices compostos
   
5. **[05_triggers.sql](05_triggers.sql)**
   - Triggers automáticos
   - Atualização de timestamps
   - Sincronização de dados
   
6. **[06_rls_policies.sql](06_rls_policies.sql)**
   - Políticas de segurança RLS
   - Controle de acesso
   - Permissões por tabela
   
7. **[07_storage_and_config.sql](07_storage_and_config.sql)**
   - 3 storage buckets
   - Configurações iniciais
   - Realtime habilitado
   
8. **[08_views.sql](08_views.sql)**
   - 10 views úteis
   - Relatórios e consultas
   - Agregações pré-calculadas

## 📊 Estrutura por Tipo

### 📖 Documentação (Markdown)
```
00_LEIA_PRIMEIRO.md    → Início rápido
README.md              → Documentação completa
GUIA_MIGRACAO.md       → Passo a passo
ESTRUTURA_BANCO.md     → Referência técnica
CHANGELOG.md           → Histórico de mudanças 🆕
INDEX.md               → Este arquivo
```

### 💾 Scripts SQL
```
00_EXECUTAR_TUDO.sql   → Master (executa todos)
01_extensions.sql      → Extensões
02_functions.sql       → Funções
03_tables.sql          → Tabelas
04_indexes.sql         → Índices
05_triggers.sql        → Triggers
06_rls_policies.sql    → Segurança RLS
07_storage_and_config.sql → Storage + Configurações
08_views.sql           → Views
```

## 🎯 Fluxo de Trabalho Recomendado

### Para Primeira Execução
```
1. Leia: 00_LEIA_PRIMEIRO.md
2. Leia: GUIA_MIGRACAO.md
3. Execute: 00_EXECUTAR_TUDO.sql
4. Verifique: Checklist no GUIA_MIGRACAO.md
```

### Para Consulta Rápida
```
1. Estrutura: ESTRUTURA_BANCO.md
2. Tabelas: 03_tables.sql
3. Views: 08_views.sql
```

### Para Manutenção
```
1. Adicionar tabela: 03_tables.sql
2. Adicionar índice: 04_indexes.sql
3. Adicionar trigger: 05_triggers.sql
4. Adicionar política: 06_rls_policies.sql
```

## 📈 Estatísticas

### Documentação
- **Total de Arquivos:** 13
- **Documentos Markdown:** 6
- **Scripts SQL:** 8 (incluindo master)
- **Tamanho Total:** ~110 KB

### Banco de Dados
- **Tabelas:** 22
- **Índices:** ~40
- **Views:** 10
- **Funções:** 7
- **Triggers:** 15+
- **Políticas RLS:** 60+

## 🔍 Busca Rápida

### Procurando por...

**Tabelas?**
→ [03_tables.sql](03_tables.sql) ou [ESTRUTURA_BANCO.md](ESTRUTURA_BANCO.md)

**Índices?**
→ [04_indexes.sql](04_indexes.sql)

**Segurança/RLS?**
→ [06_rls_policies.sql](06_rls_policies.sql)

**Views/Relatórios?**
→ [08_views.sql](08_views.sql)

**Como executar?**
→ [GUIA_MIGRACAO.md](GUIA_MIGRACAO.md)

**Problemas?**
→ [GUIA_MIGRACAO.md](GUIA_MIGRACAO.md) (seção Troubleshooting)

**Estrutura geral?**
→ [ESTRUTURA_BANCO.md](ESTRUTURA_BANCO.md)

## 🎓 Para Diferentes Perfis

### 👨‍💼 Gerente de Projeto
1. [00_LEIA_PRIMEIRO.md](00_LEIA_PRIMEIRO.md) - Visão geral
2. [ESTRUTURA_BANCO.md](ESTRUTURA_BANCO.md) - Entender o sistema

### 👨‍💻 Desenvolvedor
1. [README.md](README.md) - Documentação completa
2. [03_tables.sql](03_tables.sql) - Estrutura de dados
3. [08_views.sql](08_views.sql) - Queries úteis

### 🔧 DBA/DevOps
1. [GUIA_MIGRACAO.md](GUIA_MIGRACAO.md) - Execução
2. [04_indexes.sql](04_indexes.sql) - Performance
3. [06_rls_policies.sql](06_rls_policies.sql) - Segurança

### 🎨 Designer/UX
1. [ESTRUTURA_BANCO.md](ESTRUTURA_BANCO.md) - Entender dados
2. [08_views.sql](08_views.sql) - Relatórios disponíveis

## 📞 Suporte

### Ordem de Consulta
1. Este INDEX.md (navegação)
2. 00_LEIA_PRIMEIRO.md (resumo)
3. README.md (documentação)
4. GUIA_MIGRACAO.md (execução)
5. ESTRUTURA_BANCO.md (referência)

---

**Versão:** 1.1.0  
**Data:** 22/01/2026  
**Status:** ✅ Completo e pronto para uso  
**Última Atualização:** Adicionados campos de desconto e pagamento dividido

**Dica:** Marque este arquivo nos favoritos para acesso rápido! ⭐

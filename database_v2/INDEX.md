# 📑 Índice Completo - Database V2

## 🎯 Início Rápido

**Novo no projeto?** Comece aqui:
1. 📖 Leia [`README.md`](./README.md) - Visão geral e instruções
2. 📊 Leia [`STATUS_PROJETO.md`](./STATUS_PROJETO.md) - Status completo
3. 🔗 Leia [`INTEGRACAO_COMANDAS_PDV.md`](./INTEGRACAO_COMANDAS_PDV.md) - Fluxos principais

**Desenvolvedor Backend?** Vá direto para:
- 🔐 [`REGRAS_VALIDACAO_BACKEND.md`](./REGRAS_VALIDACAO_BACKEND.md) - Validações obrigatórias

**Quer ver mudanças recentes?**
- 📝 [`CHANGELOG_AJUSTES_FINAIS.md`](./CHANGELOG_AJUSTES_FINAIS.md) - Últimas alterações

---

## 📁 Arquivos por Categoria

### 🔧 Scripts SQL (Ordem de Execução)

Execute nesta ordem para criar o banco:

| # | Arquivo | Descrição | Tabelas | Status |
|---|---------|-----------|---------|--------|
| 0 | [`futuro_banco_sql.sql`](./futuro_banco_sql.sql) | Estrutura base | 8+ | ✅ |
| 1 | [`profiles.sql`](./profiles.sql) | Usuários e permissões | 6 | ✅ |
| 2 | [`produtos_pedidos.sql`](./produtos_pedidos.sql) | Produtos e cardápio | 10+ | ✅ |
| 3 | [`combos.sql`](./combos.sql) | Combos personalizáveis | 4 | ✅ |
| 4 | [`pedidos.sql`](./pedidos.sql) | Sistema de pedidos | 10 | ✅ |
| 5 | [`estoque.sql`](./estoque.sql) | Controle de estoque | 4 | ✅ |
| 6 | [`pdv.sql`](./pdv.sql) | Ponto de venda | 2 | ✅ |
| 7 | [`comandas.sql`](./comandas.sql) | Sistema de comandas | 8 | ✅ |
| 8 | [`historico_pedidos.sql`](./historico_pedidos.sql) | Histórico de pedidos | 1 | ✅ |
| 9 | [`historico_comandas.sql`](./historico_comandas.sql) | Histórico de comandas | 1 | ✅ |
| 10 | [`historico_pdv.sql`](./historico_pdv.sql) | Histórico de PDV | 1 | ✅ |
| 11 | [`configuracoes.sql`](./configuracoes.sql) | Sistema de configurações | 1 | ✅ |

**Total**: 51+ tabelas, 42+ views, 22+ triggers

---

### 📚 Documentação

| Arquivo | Tipo | Descrição | Para Quem |
|---------|------|-----------|-----------|
| [`README.md`](./README.md) | Geral | Visão geral e instruções | Todos |
| [`INDEX.md`](./INDEX.md) | Navegação | Este arquivo (índice) | Todos |
| [`STATUS_PROJETO.md`](./STATUS_PROJETO.md) | Status | Status completo do projeto | Gerentes, Devs |
| [`INTEGRACAO_COMANDAS_PDV.md`](./INTEGRACAO_COMANDAS_PDV.md) | Técnica | Integração completa | Devs Backend |
| [`REGRAS_VALIDACAO_BACKEND.md`](./REGRAS_VALIDACAO_BACKEND.md) | Técnica | Validações obrigatórias | Devs Backend |
| [`CHANGELOG_AJUSTES_FINAIS.md`](./CHANGELOG_AJUSTES_FINAIS.md) | Histórico | Últimas alterações | Todos |

---

## 🗺️ Mapa de Navegação

### Por Objetivo

#### 🎯 Quero entender o projeto
```
README.md → STATUS_PROJETO.md → INTEGRACAO_COMANDAS_PDV.md
```

#### 💻 Quero implementar o backend
```
REGRAS_VALIDACAO_BACKEND.md → profiles.sql → produtos_pedidos.sql → ...
```

#### 🔍 Quero entender uma funcionalidade específica
- **Comandas**: `comandas.sql` + `INTEGRACAO_COMANDAS_PDV.md`
- **PDV**: `pdv.sql` + `INTEGRACAO_COMANDAS_PDV.md`
- **Estoque**: `estoque.sql` + `REGRAS_VALIDACAO_BACKEND.md` (seção 7-8)
- **Pedidos**: `pedidos.sql` + `INTEGRACAO_COMANDAS_PDV.md`
- **Permissões**: `profiles.sql`

#### 📊 Quero ver relatórios/views
Cada arquivo SQL tem seção "VIEWS ÚTEIS" no final:
- `comandas.sql` → Views de mesas e comandas
- `pdv.sql` → Views de caixa e movimentações
- `estoque.sql` → Views de alertas e valor total
- `pedidos.sql` → Views de pedidos ativos e resumo

#### 🔐 Quero implementar validações
```
REGRAS_VALIDACAO_BACKEND.md → Seção específica → Implementar
```

---

## 📖 Guias por Persona

### 👨‍💼 Gerente de Projeto

**Leia primeiro**:
1. `README.md` - Visão geral
2. `STATUS_PROJETO.md` - Status e estatísticas
3. `CHANGELOG_AJUSTES_FINAIS.md` - Mudanças recentes

**Foco**:
- Módulos concluídos vs pendentes
- Estatísticas (40+ tabelas, 25+ views)
- Roadmap (Fase 3 pendente)

---

### 👨‍💻 Desenvolvedor Backend

**Leia primeiro**:
1. `REGRAS_VALIDACAO_BACKEND.md` - **CRÍTICO**
2. `INTEGRACAO_COMANDAS_PDV.md` - Fluxos
3. Arquivos SQL na ordem de execução

**Foco**:
- 9 regras críticas obrigatórias
- Exemplos de código TypeScript
- Prevenção de race conditions
- Testes recomendados

**Validações críticas**:
1. ✅ Adicionar item só se comanda aberta
2. ✅ Valor total calculado (não salvo)
3. ✅ Cancelar comanda = cancelar itens
4. ✅ Divisão: somatório ≤ quantidade
5. ✅ Pedido local requer caixa aberto
6. ✅ Valor esperado só conta dinheiro
7. ✅ Movimentação com SELECT FOR UPDATE
8. ✅ Nunca editar quantidade_atual

---

### 👨‍💻 Desenvolvedor Frontend

**Leia primeiro**:
1. `README.md` - Visão geral
2. `INTEGRACAO_COMANDAS_PDV.md` - Fluxos de UI
3. `STATUS_PROJETO.md` - Funcionalidades

**Foco**:
- Fluxos de tela (Comanda → Pedido → PDV)
- Status e semântica (aberta, aguardando_pagamento, fechada)
- Validações de UI (bloquear adicionar item se não aberta)

**Regras de UX**:
- Comanda aberta: PODE adicionar itens
- Comanda aguardando_pagamento: NÃO PODE adicionar
- Divisão de conta: validar somatório
- PDV: separar dinheiro de outras formas

---

### 🗄️ DBA (Database Administrator)

**Leia primeiro**:
1. `README.md` - Instruções de instalação
2. Arquivos SQL na ordem
3. `STATUS_PROJETO.md` - Estatísticas

**Foco**:
- Ordem de execução dos scripts
- Índices (100+)
- Triggers (15+)
- Views (25+)
- Backup e manutenção

**Comandos úteis**:
```sql
-- Verificar instalação
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' ORDER BY table_name;

-- Otimizar
VACUUM ANALYZE;

-- Monitorar índices
SELECT * FROM pg_stat_user_indexes WHERE idx_scan = 0;
```

---

### 🧪 QA (Quality Assurance)

**Leia primeiro**:
1. `REGRAS_VALIDACAO_BACKEND.md` - Seção "Testes"
2. `INTEGRACAO_COMANDAS_PDV.md` - Fluxos
3. `STATUS_PROJETO.md` - Funcionalidades

**Foco**:
- Testes recomendados (3 principais)
- Fluxos completos (Comanda → Pedido → PDV)
- Casos de erro (adicionar item em comanda fechada)
- Race conditions (estoque)

**Testes críticos**:
1. Adicionar item em comanda fechada (deve falhar)
2. Divisão ultrapassando quantidade (deve falhar)
3. Race condition em estoque (deve prevenir)
4. Pedido local sem caixa (deve falhar)
5. Cancelamento de comanda (deve cancelar itens)

---

## 🔍 Busca Rápida

### Por Funcionalidade

| Funcionalidade | Arquivo SQL | Documentação |
|----------------|-------------|--------------|
| Usuários e permissões | `profiles.sql` | `STATUS_PROJETO.md` |
| Produtos e cardápio | `produtos_pedidos.sql` | `README.md` |
| Combos | `combos.sql` | `README.md` |
| Pedidos | `pedidos.sql` | `INTEGRACAO_COMANDAS_PDV.md` |
| Estoque | `estoque.sql` | `REGRAS_VALIDACAO_BACKEND.md` |
| PDV (Caixa) | `pdv.sql` | `INTEGRACAO_COMANDAS_PDV.md` |
| Comandas (Mesas) | `comandas.sql` | `INTEGRACAO_COMANDAS_PDV.md` |
| Configurações | `configuracoes.sql` | `STATUS_PROJETO.md` |

### Por Conceito

| Conceito | Onde Encontrar |
|----------|----------------|
| Snapshot imutável | `pedidos.sql` (comentários) |
| Soft delete | Todos os SQLs |
| TEXT + CHECK vs ENUM | `README.md` (Filosofias) |
| Índices únicos parciais | `comandas.sql`, `pdv.sql` |
| SELECT FOR UPDATE | `REGRAS_VALIDACAO_BACKEND.md` (seção 7) |
| Vinculação bidirecional | `INTEGRACAO_COMANDAS_PDV.md` |
| Múltiplas formas de pagamento | `pdv.sql` + `INTEGRACAO_COMANDAS_PDV.md` |

### Por Tabela

| Tabela | Arquivo | Linha Aprox. |
|--------|---------|--------------|
| profiles | `profiles.sql` | 50 |
| cargos | `profiles.sql` | 150 |
| permissoes | `profiles.sql` | 250 |
| produtos | `produtos_pedidos.sql` | 100 |
| combos | `combos.sql` | 50 |
| pedidos | `pedidos.sql` | 70 |
| pedido_itens | `pedidos.sql` | 180 |
| itens_estoque | `estoque.sql` | 50 |
| estoque_movimentacoes | `estoque.sql` | 200 |
| pdv_caixas | `pdv.sql` | 50 |
| comandas | `comandas.sql` | 100 |
| comanda_itens | `comandas.sql` | 150 |
| configuracoes | `configuracoes.sql` | 50 |

---

## 📊 Estatísticas Rápidas

### Arquivos
- **SQL**: 11 arquivos
- **Documentação**: 6 arquivos (incluindo este)
- **Total**: 17 arquivos

### Código
- **Tabelas**: 51+
- **Views**: 42+
- **Triggers**: 22+
- **Índices**: 126+
- **Linhas SQL**: ~8500
- **Linhas Doc**: ~3000

### Status
- **Fase 1**: ✅ Concluída (Estrutura base)
- **Fase 2**: ✅ Concluída (Integrações)
- **Fase 3**: ✅ Concluída (Histórico e auditoria)
- **Fase 4**: 📅 Futuro (Otimizações)

---

## 🔗 Links Rápidos

### Documentação Externa
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Supabase Docs](https://supabase.com/docs)
- [SQL Style Guide](https://www.sqlstyle.guide/)

### Ferramentas Recomendadas
- [pgAdmin](https://www.pgadmin.org/) - GUI para PostgreSQL
- [DBeaver](https://dbeaver.io/) - Cliente SQL universal
- [TablePlus](https://tableplus.com/) - Cliente SQL moderno

---

## 💡 Dicas

### Para Desenvolvedores
1. **Sempre leia os comentários inline** nos arquivos SQL
2. **Use as views** ao invés de queries complexas
3. **Siga as validações** em `REGRAS_VALIDACAO_BACKEND.md`
4. **Teste race conditions** especialmente em estoque

### Para DBAs
1. **Execute VACUUM ANALYZE** regularmente
2. **Monitore índices não utilizados**
3. **Faça backup antes de migrations**
4. **Use transações** para operações críticas

### Para QA
1. **Teste fluxos completos** (Comanda → Pedido → PDV)
2. **Valide casos de erro** (adicionar item em comanda fechada)
3. **Teste concorrência** (2 usuários movimentando mesmo item)
4. **Verifique soft delete** (dados não devem sumir)

---

## 🆘 Troubleshooting

### Erro ao executar SQL
**Problema**: Erro de sintaxe ou tabela não existe  
**Solução**: Verifique ordem de execução (profiles → produtos → combos → pedidos → estoque → pdv → comandas)

### Performance lenta
**Problema**: Queries lentas  
**Solução**: Execute `VACUUM ANALYZE` e verifique índices

### Dados inconsistentes
**Problema**: Valores não batem  
**Solução**: Verifique se seguiu validações em `REGRAS_VALIDACAO_BACKEND.md`

### Race condition
**Problema**: Estoque negativo ou valores errados  
**Solução**: Use `SELECT FOR UPDATE` (veja seção 7 de `REGRAS_VALIDACAO_BACKEND.md`)

---

## 📞 Suporte

### Dúvidas sobre Estrutura
1. Consulte comentários inline nos arquivos SQL
2. Leia `INTEGRACAO_COMANDAS_PDV.md`
3. Verifique views para exemplos

### Dúvidas sobre Validações
1. Consulte `REGRAS_VALIDACAO_BACKEND.md`
2. Veja exemplos de código TypeScript
3. Execute testes recomendados

### Dúvidas sobre Projeto
1. Leia `STATUS_PROJETO.md`
2. Consulte `CHANGELOG_AJUSTES_FINAIS.md`
3. Veja `README.md`

---

**Última atualização**: 25/01/2026  
**Versão**: 2.0  
**Mantenedor**: [Seu Nome]

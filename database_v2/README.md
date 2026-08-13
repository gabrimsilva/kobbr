# 🗄️ Database V2 - Sistema de Delivery Completo

## 📋 Visão Geral

Esta pasta contém a estrutura completa do banco de dados reestruturado para o sistema de delivery/pizzaria, incluindo suporte para:

- 🍕 Delivery e retirada
- 🏪 PDV (Ponto de Venda)
- 🍽️ Comandas (mesas)
- 📦 Controle de estoque
- 👥 Gestão de usuários e permissões
- 💰 Múltiplas formas de pagamento
- 📊 Relatórios e auditoria

---

## 📁 Estrutura de Arquivos

### 🔧 Arquivos SQL (Ordem de Execução)

Execute os arquivos SQL nesta ordem para criar o banco de dados:

0. **`futuro_banco_sql.sql`** - Estrutura base
   - Categorias e configurações
   - Tipos de sabor, sabores, bordas
   - Adicionais e tamanhos
   - Hierarquia de regras

1. **`profiles.sql`** - Sistema de usuários e permissões
   - Profiles, cargos, permissões
   - Histórico de mudanças
   - Endereços de clientes

2. **`produtos_pedidos.sql`** - Produtos e cardápio
   - Produtos, categorias, tamanhos
   - Sabores, bordas, adicionais
   - Soft delete em tudo

3. **`combos.sql`** - Combos personalizáveis
   - Combos com produtos
   - Regras de personalização
   - Preço como fonte da verdade

4. **`pedidos.sql`** - Sistema de pedidos
   - Pedidos (delivery, retirada, local)
   - Snapshot imutável
   - Integração com Mercado Pago
   - **Campo `comanda_id`** para integração

5. **`estoque.sql`** - Controle de estoque
   - Itens de estoque
   - Movimentações rastreáveis
   - Alertas automáticos
   - Integração com produtos (receitas)

6. **`pdv.sql`** - Ponto de venda
   - Controle de caixa
   - Sangria e suprimento
   - Múltiplas formas de pagamento
   - Diferença física (quebra de caixa)

7. **`comandas.sql`** - Sistema de comandas (mesas)
   - Mínimo 24 mesas
   - Status de preparo
   - Divisão de conta
   - **Comanda SEMPRE vira pedido**

8. **`historico_pedidos.sql`** - Histórico de pedidos
   - Auditoria completa de mudanças
   - Timeline de eventos
   - Análise de performance

9. **`historico_comandas.sql`** - Histórico de comandas
   - Rastreabilidade de operações
   - Performance por garçom
   - Análise de cancelamentos

10. **`historico_pdv.sql`** - Histórico de PDV
    - Auditoria financeira completa
    - Operações de caixa
    - Flags de segurança

11. **`configuracoes.sql`** - Sistema de configurações
    - Configurações chave-valor flexíveis
    - Tipos: texto, numero, booleano, json
    - Categorias organizadas
    - Funções helper para obtenção
    - Validação de tipo automática

---

### 📚 Documentação

#### Documentos Principais

- **`README.md`** - Este arquivo (índice geral)
- **`STATUS_PROJETO.md`** - Visão geral do projeto
- **`INTEGRACAO_COMANDAS_PDV.md`** - Integração completa
- **`REGRAS_VALIDACAO_BACKEND.md`** - Validações obrigatórias
- **`CHANGELOG_AJUSTES_FINAIS.md`** - Últimas alterações

#### Guia de Leitura

1. **Começando**: Leia `STATUS_PROJETO.md` para visão geral
2. **Integração**: Leia `INTEGRACAO_COMANDAS_PDV.md` para fluxos
3. **Desenvolvimento**: Leia `REGRAS_VALIDACAO_BACKEND.md` para validações
4. **Histórico**: Leia `CHANGELOG_AJUSTES_FINAIS.md` para mudanças

---

## 🚀 Como Usar

### 1. Criar Banco de Dados

```sql
-- No Supabase ou PostgreSQL
CREATE DATABASE delivery_system;
```

### 2. Executar Scripts SQL

Execute os arquivos na ordem listada acima:

```bash
# Exemplo usando psql
psql -d delivery_system -f profiles.sql
psql -d delivery_system -f produtos_pedidos.sql
psql -d delivery_system -f combos.sql
psql -d delivery_system -f pedidos.sql
psql -d delivery_system -f estoque.sql
psql -d delivery_system -f pdv.sql
psql -d delivery_system -f comandas.sql
```

### 3. Verificar Instalação

```sql
-- Verificar tabelas criadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Deve retornar 40+ tabelas
```

### 4. Dados Iniciais (Opcional)

Cada arquivo SQL contém exemplos comentados no final. Descomente e execute conforme necessário.

---

## 📊 Estatísticas

- **Tabelas**: 51+
- **Views**: 42+
- **Triggers**: 22+
- **Índices**: 126+
- **Linhas de código**: 8500+
- **Linhas de documentação**: 3000+

---

## 🎯 Funcionalidades Principais

### ✅ Implementado

1. **Profiles e Permissões**
   - Super admin, admin, funcionário, cliente
   - Cargos dinâmicos por loja
   - Permissões granulares

2. **Produtos e Cardápio**
   - Produtos com tamanhos e sabores
   - Bordas e adicionais
   - Combos personalizáveis

3. **Pedidos**
   - Delivery, retirada e local
   - Snapshot imutável
   - Pagamento único ou dividido
   - Integração com Mercado Pago

4. **Estoque**
   - Controle de ingredientes
   - Movimentações rastreáveis
   - Alertas automáticos
   - Integração com produtos

5. **PDV**
   - Controle de caixa único por loja
   - Sangria e suprimento
   - Múltiplas formas de pagamento
   - Diferença física

6. **Comandas**
   - Mínimo 24 mesas
   - Status de preparo
   - Divisão de conta
   - Integração com pedidos

7. **Histórico de Pedidos**
   - Auditoria completa
   - Timeline de eventos
   - Análise de performance
   - Tempo médio por status

8. **Histórico de Comandas**
   - Rastreabilidade total
   - Performance por garçom
   - Análise de cancelamentos
   - Tempo de atendimento

9. **Histórico de PDV**
   - Auditoria financeira
   - Operações de caixa
   - Flags de segurança
   - Revisão de operações

10. **Configurações**
   - Sistema chave-valor flexível
   - Tipos: texto, numero, booleano, json
   - Categorias organizadas
   - Funções helper
   - Validação automática

---

## 🔗 Integrações

### Comandas ↔ Pedidos ↔ PDV

```
┌─────────────┐
│  COMANDAS   │
│  (Mesas)    │
└──────┬──────┘
       │
       │ comanda_id
       ↓
┌─────────────┐
│   PEDIDOS   │
│ (tipo=local)│
└──────┬──────┘
       │
       │ caixa_id
       ↓
┌─────────────┐
│     PDV     │
│   (Caixa)   │
└─────────────┘
```

**Vinculação Bidirecional**:
- `pedidos.comanda_id` → `comandas.id`
- `comandas.pedido_id` → `pedidos.id`
- `pedido_pagamentos.caixa_id` → `pdv_caixas.id`

---

## 🔐 Validações Críticas

### Backend (Obrigatórias)

1. ✅ Adicionar item só se comanda aberta
2. ✅ Valor total calculado (não salvo)
3. ✅ Cancelar comanda = cancelar itens
4. ✅ Divisão: somatório ≤ quantidade
5. ✅ Pedido local requer caixa aberto
6. ✅ Valor esperado só conta dinheiro
7. ✅ Movimentação com SELECT FOR UPDATE
8. ✅ Nunca editar quantidade_atual
9. ⚠️ Consumo automático de estoque (opcional)

**Detalhes**: Consulte `REGRAS_VALIDACAO_BACKEND.md`

---

## 🎓 Filosofias do Projeto

### 1. Snapshot Imutável
Pedidos são fotografias do momento da compra. Valores não mudam retroativamente.

### 2. Soft Delete Everywhere
Nada é deletado permanentemente. Histórico preservado para auditoria.

### 3. TEXT + CHECK vs ENUM
Flexibilidade para SaaS. Valores centralizados no backend.

### 4. Índices Únicos Parciais
Melhor que triggers para prevenir duplicação. Atomicidade garantida.

### 5. Concurrency Control
SELECT FOR UPDATE para movimentações. Race conditions prevenidas.

### 6. Validações em Camadas
Backend (obrigatória) + Banco (trigger - extra). Segurança reforçada.

### 7. Vinculação Explícita
`caixa_id` em pagamentos. Auditoria precisa.

### 8. Múltiplas Formas de Pagamento
Dinheiro (diferença física) vs PIX/Cartão (apenas relatório).

---

## 📖 Exemplos de Uso

### Criar Comanda

```sql
-- 1. Abrir comanda
INSERT INTO comandas (loja_id, mesa_id, aberta_por)
VALUES (?, ?, ?);

-- 2. Adicionar item
INSERT INTO comanda_itens (comanda_id, tipo_item, produto_id, ...)
VALUES (?, 'produto', ?, ...);

-- 3. Pedir conta
UPDATE comandas SET status = 'aguardando_pagamento' WHERE id = ?;

-- 4. Converter para pedido
-- (Backend faz snapshot e cria pedido)

-- 5. Fechar comanda
UPDATE comandas SET status = 'fechada', pedido_id = ? WHERE id = ?;
```

### Abrir Caixa

```sql
-- 1. Abrir caixa
INSERT INTO pdv_caixas (loja_id, aberto_por, valor_abertura)
VALUES (?, ?, 100.00);

-- 2. Registrar venda
-- (Pedido local com caixa_id)

-- 3. Fazer sangria
INSERT INTO pdv_movimentacoes_caixa (caixa_id, tipo, valor, motivo)
VALUES (?, 'sangria', 200.00, 'Segurança');

-- 4. Fechar caixa
UPDATE pdv_caixas 
SET status = 'fechado', 
    valor_fechamento = 495.00,
    valor_esperado = 500.00
WHERE id = ?;
-- Trigger calcula diferenca = -5.00
```

### Movimentar Estoque

```sql
-- SEMPRE usar transação com lock
BEGIN;

-- 1. Lock na leitura
SELECT quantidade_atual FROM itens_estoque WHERE id = ? FOR UPDATE;

-- 2. Calcular nova quantidade (no backend)

-- 3. Inserir movimentação
INSERT INTO estoque_movimentacoes (
  item_estoque_id, tipo_movimentacao, quantidade,
  quantidade_anterior, quantidade_nova, motivo
) VALUES (?, 'entrada_compra', 50, 0, 50, 'Compra inicial');

COMMIT;
-- Trigger atualiza quantidade_atual automaticamente
```

---

## 🧪 Testes Recomendados

1. **Adicionar item em comanda fechada** (deve falhar)
2. **Divisão ultrapassando quantidade** (deve falhar)
3. **Race condition em estoque** (deve prevenir)
4. **Pedido local sem caixa** (deve falhar)
5. **Cancelamento de comanda** (deve cancelar itens)

**Detalhes**: Consulte `REGRAS_VALIDACAO_BACKEND.md`

---

## 🔧 Manutenção

### Backup

```bash
# Backup completo
pg_dump -d delivery_system -f backup_$(date +%Y%m%d).sql

# Backup apenas estrutura
pg_dump -d delivery_system -s -f schema_$(date +%Y%m%d).sql
```

### Vacuum e Analyze

```sql
-- Otimizar performance
VACUUM ANALYZE;

-- Por tabela específica
VACUUM ANALYZE pedidos;
```

### Monitorar Índices

```sql
-- Índices não utilizados
SELECT * FROM pg_stat_user_indexes WHERE idx_scan = 0;

-- Tabelas sem índices
SELECT * FROM pg_stat_user_tables WHERE idx_scan = 0;
```

---

## 📞 Suporte

### Dúvidas sobre Estrutura
1. Consulte comentários inline nos arquivos SQL
2. Leia `INTEGRACAO_COMANDAS_PDV.md` para fluxos
3. Verifique views para exemplos de consultas
4. Analise triggers para regras de negócio

### Dúvidas sobre Validações
1. Consulte `REGRAS_VALIDACAO_BACKEND.md`
2. Veja exemplos de código TypeScript
3. Execute testes recomendados

### Dúvidas sobre Projeto
1. Leia `STATUS_PROJETO.md` para visão geral
2. Consulte `CHANGELOG_AJUSTES_FINAIS.md` para mudanças

---

## 🚀 Roadmap

### Fase 1: Estrutura Base ✅
- [x] Profiles e permissões
- [x] Produtos e cardápio
- [x] Pedidos
- [x] Estoque
- [x] PDV
- [x] Comandas

### Fase 2: Integrações ✅
- [x] Comandas → Pedidos
- [x] Pedidos → PDV
- [x] Produtos → Estoque
- [x] Validações de integridade

### Fase 3: Histórico e Auditoria ✅
- [x] Configurações do sistema
- [x] Histórico de pedidos
- [x] Histórico de comandas
- [x] Histórico de PDV

### Fase 4: Otimizações Futuras 📅
- [ ] Controle de estoque por lote
- [ ] Categorias dinâmicas
- [ ] Consumo automático
- [ ] Previsão de compras (ML)
- [ ] Integração com fornecedores

---

## 📄 Licença

Este projeto é proprietário. Todos os direitos reservados.

---

## 👥 Contribuidores

- **Desenvolvedor Principal**: [Seu Nome]
- **Revisão Técnica**: Sênior
- **Data de Criação**: Janeiro 2026
- **Versão**: 2.0

---

**Última atualização**: 25/01/2026  
**Status**: Fase 3 concluída ✅ | Fase 4 pendente 📅

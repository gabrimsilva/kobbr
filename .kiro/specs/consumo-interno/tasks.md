# Implementation Tasks: Consumo Interno no PDV

## Overview

Este documento descreve as tarefas de implementação para a funcionalidade "Consumo Interno" no PDV. As tarefas estão ordenadas seguindo a sequência lógica de implementação: primeiro banco de dados, depois backend RPC, depois frontend UI, e finalmente métricas.

**Estimated Total Effort**: ~40 horas (5 dias de desenvolvimento)
**Tech Stack**: React 19, TypeScript, Supabase PostgreSQL, RLS policies, recharts

---

## Phase 1: Database & Backend Infrastructure

### Task 1.1: Create Migration - Add internal_consumptions Table and is_internal_consumption Column

**Requirement Links**: Requirement 3, Requirement 8

**Description**: 
Criar migration SQL que adiciona a tabela `internal_consumptions` com todas as colunas necessárias, índices de performance, e a coluna `is_internal_consumption` na tabela `sales`.

**Acceptance Criteria**:
- [x] Tabela `internal_consumptions` criada com todas as 8 colunas obrigatórias (id, estabelecimento_id, sale_id, consumed_at, total_quantity, items_json, created_by, created_at)
- [x] Coluna `is_internal_consumption` adicionada em `sales` com default false
- [x] Índice criado em (estabelecimento_id, consumed_at DESC)
- [x] Índice criado em (sale_id) para FK relationship
- [x] Foreign keys configuradas corretamente (estabelecimento_id → establishments, sale_id → sales)
- [x] UNIQUE constraint em sale_id (cada venda tem no máximo 1 registro de consumo)
- [x] Migration é idempotente e reversível
- [x] Execução de migration com sucesso em database de teste

**Implementation Notes**:
- Use migration pattern: `supabase migration new add_internal_consumptions`
- File location: `.kiro/specs/consumo-interno/migrations/` (criar diretório se não existir)
- Use Supabase timestamp format: `CURRENT_TIMESTAMP` para defaults
- JSONB column para items com validação de schema (usar CHECK constraint se necessário)

**Dependencies**: Nenhuma - primeira tarefa

**Estimated Time**: 2 horas

---

### Task 1.2: Create RLS Policies for internal_consumptions Table

**Requirement Links**: Requirement 3, Requirement 6

**Description**:
Criar RLS policies que isolam `internal_consumptions` por estabelecimento, garantindo que usuários só acessem dados de seu estabelecimento.

**Acceptance Criteria**:
- [x] RLS ativada em `internal_consumptions` (ALTER TABLE ENABLE ROW LEVEL SECURITY)
- [x] Policy de SELECT que filtra por estabelecimento_id = get_current_estabelecimento_id()
- [x] Policy de INSERT que valida usuário tem acesso ao estabelecimento
- [x] Policy de UPDATE desabilitada (consumos são imutáveis)
- [x] Policy de DELETE desabilitada (consumos são imutáveis)
- [x] Teste de isolamento: usuário de estabelecimento A não consegue ver dados de B
- [x] Teste de INSERT: inserção sem estabelecimento_id válido é rejeitada

**Implementation Notes**:
- Assumir função helper `get_current_estabelecimento_id()` existe (do projeto multi-tenant existente)
- Usar função `auth.uid()` para validar usuário
- Criar policies em migration separada (Task 1.1 cria tabela, Task 1.2 cria policies)

**Dependencies**: Task 1.1 (tabela deve existir)

**Estimated Time**: 1.5 horas

---

### Task 1.3: Create RPC Function - registrar_consumo_interno()

**Requirement Links**: Requirement 2, Requirement 6

**Description**:
Implementar função RPC `registrar_consumo_interno()` que processa consumo interno de forma atômica: cria venda, registra consumo, atualiza estoque, cria movimento de estoque.

**Acceptance Criteria**:
- [x] RPC function criada com assinatura: `registrar_consumo_interno(p_estabelecimento_id UUID, p_items JSONB, p_created_by UUID DEFAULT NULL)`
- [x] Função retorna JSON com campos: `{ success: boolean, consumption_id: UUID, sale_id: UUID, message: string }`
- [x] Transação atômica: INSERT sales, INSERT internal_consumptions, UPDATE stock_items, INSERT stock_movements
- [x] Validação: estabelecimento_id existe
- [x] Validação: items array não está vazio
- [x] Validação: cada item tem product_id e quantidade válidas
- [x] Validação: stock_items suficiente para cada item (raise exception se insuficiente)
- [x] created_by defaulta para auth.uid() se não fornecido
- [x] Função protegida por RLS (acesso só para usuário do estabelecimento)
- [x] Teste de sucesso: consumo registrado corretamente
- [x] Teste de falha: erro descritivo se stock insuficiente

**Implementation Notes**:
- Usar BEGIN ... EXCEPTION ... END para tratamento de transação
- Retornar valores via RETURN JSON
- Log de erro detalhado para debugging
- Validar que p_items é JSON array válido antes de processar

**Dependencies**: Task 1.1 (tabelas devem existir), Task 1.2 (RLS policies)

**Estimated Time**: 3 horas

---

### Task 1.4: Create RPC Function - obter_consumos_por_periodo()

**Requirement Links**: Requirement 7

**Description**:
Implementar função RPC `obter_consumos_por_periodo()` que recupera dados agregados de consumos internos por período para gráficos de evolução.

**Acceptance Criteria**:
- [x] RPC function criada com assinatura: `obter_consumos_por_periodo(p_estabelecimento_id UUID, p_data_inicio DATE, p_data_fim DATE, p_granularidade VARCHAR DEFAULT 'dia')`
- [x] Função retorna array de objetos com campos: periodo, total_unidades, total_transacoes, media_unidades_transacao
- [x] Granularidades suportadas: 'dia', 'semana', 'mes'
- [x] Performance < 500ms com 1000+ registros (validar com EXPLAIN ANALYZE)
- [x] Retorna array vazio [] se não há dados (não erro)
- [x] Filtro de estabelecimento_id automático via RLS
- [x] Data_inicio e data_fim são inclusivos (BETWEEN syntax)
- [x] Teste com granularidade dia para 30 dias
- [x] Teste com granularidade semana para 1 ano
- [x] Teste com granularidade mes para 1 ano

**Implementation Notes**:
- Usar DATE_TRUNC ou TO_CHAR para agrupar por granularidade
- Usar agregação SUM(total_quantity), COUNT(*), AVG(total_quantity/transacoes)
- Ordenar resultado por periodo ASC
- Considerar cache de queries se necessário (Supabase Realtime)

**Dependencies**: Task 1.1 (tabela internal_consumptions), Task 1.2 (RLS)

**Estimated Time**: 2.5 horas

---

## Phase 2: Frontend UI - PDV Modal

### Task 2.1: Add "Consumo Interno" Checkbox to PDV Payment Modal

**Requirement Links**: Requirement 1

**Description**:
Adicionar checkbox "Consumo Interno" no modal de finalização de venda do PDV com lógica de habilitação/desabilitação de campos.

**Acceptance Criteria**:
- [~] Checkbox "Consumo Interno" adicionado no modal com label clara em português
- [~] Checkbox posicionado visualmente perto de informações de venda (não em seção de pagamento)
- [~] Checkbox começa desmarcado por padrão
- [~] Quando marcado: campos de cliente e forma_pagamento são desabilitados (disabled = true)
- [~] Quando marcado: total_amount é zerado visualmente (exibe "R$ 0,00")
- [~] Quando desmarcado: campos de cliente e forma_pagamento são reabilitados
- [~] Quando desmarcado: total_amount volta ao valor calculado normal
- [~] Usuário tenta preencher cliente em consumo interno: campo não permite (disabled)
- [~] Botão "Finalizar" desabilitado se: consumo_interno marcado E carrinho vazio (com tooltip)
- [~] Mensagem de validação exibida quando tenta preencher campo desabilitado
- [~] Estilo visual claro diferenciando estado "Consumo Interno" ativo vs inativo

**Implementation Notes**:
- Arquivo principal: `src/components/delivery/PagamentoPix.tsx` (ou similar modal de pagamento)
- Usar React state hook: `const [consumoInterno, setConsumoInterno] = useState(false)`
- Usar TailwindCSS para styling de disabled state
- Validação no handler de submit: `if (consumoInterno) { total = 0; cliente = null; }`

**Dependencies**: Nenhuma - trabalho puramente frontend

**Estimated Time**: 1.5 horas

---

### Task 2.2: Implement Consumo Interno Logic in PDV Service

**Requirement Links**: Requirement 2

**Description**:
Implementar lógica no serviço de PDV que chama RPC `registrar_consumo_interno()` quando checkbox está marcado, em vez de fluxo normal de venda.

**Acceptance Criteria**:
- [~] Função `finalizarVendaConsumoInterno()` criada que chama RPC registrar_consumo_interno()
- [~] Dados passados para RPC: establecimento_id, items (com product_id, quantidade, preco_unitario)
- [~] Se RPC retorna sucesso: mensagem toast "Consumo Interno registrado com sucesso"
- [~] Se RPC retorna erro (ex: stock insuficiente): mensagem toast com detalhe do erro
- [~] Carrinho limpo após sucesso
- [~] Modal fechado após sucesso
- [~] Validação: não permite finalizar se items vazio mesmo em consumo interno
- [~] Teste de integração: RPC chamado com parâmetros corretos
- [~] Teste de erro: erro do RPC é capturado e exibido ao usuário

**Implementation Notes**:
- Arquivo: `src/services/vendaPDVService.ts` (ou similar)
- Integração com Supabase client: `const { data, error } = await supabase.rpc('registrar_consumo_interno', {...})`
- Reutilizar padrão existente de error handling no projeto
- Console logs para debugging: `console.log('CONSUMO_INTERNO_SUBMIT', { items, establecimento_id })`

**Dependencies**: Task 1.3 (RPC function), Task 2.1 (UI checkbox)

**Estimated Time**: 2 horas

---

### Task 2.3: Add Validations and Error Handling to PDV Modal

**Requirement Links**: Requirement 1, Requirement 2

**Description**:
Adicionar validações completas no modal PDV para garantir que fluxo consumo interno só procede quando válido.

**Acceptance Criteria**:
- [~] Validação: consumo_interno marcado EXIGE items não vazio
- [~] Validação: consumo_interno marcado FORÇA total_amount = 0 (nunca permitir > 0)
- [~] Validação: consumo_interno marcado FORÇA cliente = null (campo desabilitado)
- [~] Validação: consumo_interno marcado FORÇA forma_pagamento = null (campo desabilitado)
- [~] Mensagem de erro clara se tenta finalizar sem cumprir validações
- [~] Testes unitários para cada validação (usar Jest/Vitest)
- [~] Testes de integração: fluxo completo consumo interno com validações

**Implementation Notes**:
- Usar função auxiliar: `validateConsumoInterno(carrinhoItems, total, cliente, pagamento)` que retorna boolean + mensagem
- Aplicar validação ANTES de chamar RPC (frontend validation)
- Re-validar no backend (RPC valida novamente - nunca confiar só no frontend)

**Dependencies**: Task 2.1, Task 2.2

**Estimated Time**: 1.5 horas

---

## Phase 3: Frontend Metrics

### Task 3.1: Create Card Component - Total Unidades Consumo Interno

**Requirement Links**: Requirement 4

**Description**:
Criar novo card na página de Métricas mostrando total de unidades consumidas internamente com período selecionável.

**Acceptance Criteria**:
- [~] Card adicionado na página Métricas com título "Consumo Interno - Total"
- [~] Card exibe número total de unidades consumidas (grande, bem visível)
- [~] Card exibe variação em relação ao período anterior (ex: "+15%" com seta para cima)
- [~] Card inclui seletor de período: "Último Mês", "Últimos 3 Meses", "Últimos 6 Meses", "Ano"
- [~] Quando período muda: card atualiza em < 2 segundos
- [~] Se período sem dados: exibe "Nenhum consumo registrado neste período"
- [~] Card posicionado na mesma seção de cards existentes (não separado)
- [~] Estilo consistente com cards existentes (usar shadcn/ui Card component)
- [~] Indicador visual de status (neutral, normal, alto) baseado em valor
- [~] Responsivo em mobile, tablet, desktop

**Implementation Notes**:
- Arquivo: `src/pages/Metricas.tsx` (ou arquivo de componente separado)
- Usar componente Card do shadcn/ui
- Estado: `const [periodoCard, setPeriodoCard] = useState('1mes')`
- Chamada RPC: `obter_consumos_por_periodo(estabelecimento_id, dataInicio, dataFim, 'dia')`
- Cálculo de variação: compara total do período vs período anterior mesmo tamanho

**Dependencies**: Task 1.4 (RPC obter_consumos_por_periodo)

**Estimated Time**: 2.5 horas

---

### Task 3.2: Create LineChart - Consumo Interno Evolution Temporal

**Requirement Links**: Requirement 5

**Description**:
Criar gráfico de linha (recharts) mostrando evolução diária/semanal/mensal de consumos internos na página Métricas.

**Acceptance Criteria**:
- [~] Gráfico LineChart criado usando recharts library
- [~] Eixo X representa tempo (data/período), Eixo Y representa quantidade
- [~] Seletor de granularidade: Diária, Semanal, Mensal
- [~] Seletor de período: até 1 ano de histórico
- [~] Tooltip ao passar mouse: exibe Data, Quantidade Unidades, Quantidade Transações
- [~] Legenda colorida exibida
- [~] Gráfico responsivo (adapta a width do container)
- [~] Se período sem dados: exibe "Sem dados para o período selecionado"
- [~] Cores consistentes com tema do estabelecimento (CSS variables)
- [~] Loading skeleton enquanto dados carregam
- [~] Performance: renderiza em < 1 segundo mesmo com 12 meses de dados

**Implementation Notes**:
- Arquivo: `src/pages/Metricas.tsx` (ou componente separado)
- Usar recharts: `LineChart`, `Line`, `XAxis`, `YAxis`, `CartesianGrid`, `Tooltip`, `Legend`
- Dados vêm de RPC `obter_consumos_por_periodo()` com granularidade selecionada
- Transformar dados RPC em formato recharts: `[{ periodo: '2026-01-15', total_unidades: 10, total_transacoes: 2 }, ...]`
- Estado: `const [granularidade, setGranularidade] = useState('dia')`

**Dependencies**: Task 1.4 (RPC obter_consumos_por_periodo), Task 3.1 (Card para contexto de métricas)

**Estimated Time**: 2.5 horas

---

### Task 3.3: Integrate Metrics UI with Backend RPC Calls

**Requirement Links**: Requirement 4, Requirement 5, Requirement 7

**Description**:
Integrar chamadas RPC nas páginas de métricas, com tratamento de loading, erro, e cache.

**Acceptance Criteria**:
- [~] Hook customizado `useConsumoInternoMetrics()` criado para centralizar lógica
- [~] Hook executa RPC `obter_consumos_por_periodo()` baseado em período/granularidade
- [~] Hook gerencia loading state (exibe skeleton enquanto carrega)
- [~] Hook gerencia erro state (exibe mensagem de erro se RPC falha)
- [~] Hook implementa cache simples (evita chamar RPC se parâmetros iguais em < 30s)
- [~] Card renderiza dados do hook corretamente
- [~] LineChart renderiza dados do hook corretamente
- [~] Testes: hook chamado com período correto
- [~] Testes: erro é capturado e estado de erro é atualizado

**Implementation Notes**:
- Arquivo: `src/hooks/useConsumoInternoMetrics.ts` (novo)
- Usar `useEffect` para chamar RPC quando dependências mudam
- Usar `useState` para gerenciar loading, error, data
- Pattern similar a hooks existentes no projeto (ex: `useCarrinho.ts`)

**Dependencies**: Task 1.4 (RPC), Task 3.1 (Card), Task 3.2 (LineChart)

**Estimated Time**: 2 horas

---

## Phase 4: Testing & Validation

### Task 4.1: Write Unit Tests for Validation Functions

**Requirement Links**: Validation Properties

**Description**:
Escrever testes unitários para validações de consumo interno (atomicity, consistency, stock accuracy).

**Acceptance Criteria**:
- [~] Testes para `validateConsumoInterno()` function
- [~] Teste: consumo_interno marcado + carrinho vazio deve falhar
- [~] Teste: consumo_interno marcado + total > 0 deve falhar
- [~] Teste: consumo_interno marcado + cliente preenchido deve falhar
- [~] Teste: consumo_interno marcado + carrinho com itens deve passar
- [~] Testes para cálculo de estoque: verifica que quantidade decrementada = quantidade consumida
- [~] Testes para cálculo de variação percentual no card
- [~] Coverage > 80% para funções testadas

**Implementation Notes**:
- Framework: Jest ou Vitest (verifica qual está em uso no projeto)
- Arquivo: `src/services/__tests__/vendaPDVService.test.ts` (ou similar)
- Mock de supabase.rpc() para testes sem chamar backend real

**Dependencies**: Task 2.1, Task 2.2, Task 2.3

**Estimated Time**: 2 horas

---

### Task 4.2: Write Integration Tests for RPC Functions

**Requirement Links**: Requirement 6, Requirement 7

**Description**:
Escrever testes de integração que testam RPC functions direto contra database (usar Supabase branch ou test database).

**Acceptance Criteria**:
- [~] Teste de `registrar_consumo_interno()` com dados válidos: registra consumo com sucesso
- [~] Teste de `registrar_consumo_interno()` com stock insuficiente: retorna erro específico
- [~] Teste de `registrar_consumo_interno()` com estabelecimento inválido: retorna erro
- [~] Teste de `obter_consumos_por_periodo()` com período válido: retorna dados corretos
- [~] Teste de `obter_consumos_por_periodo()` com período sem dados: retorna array vazio
- [~] Teste de isolamento RLS: user A não consegue ver consumos de estabelecimento B
- [~] Teste de atomicity: se falha no meio, nada é persistido (rollback)

**Implementation Notes**:
- Usar Supabase CLI para criar test database ou branch
- Framework: Jest com @supabase/supabase-js client
- Setup/teardown: criar dados de teste, limpar após teste
- Arquivo: `.kiro/specs/consumo-interno/tests/rpc_integration_test.sql`

**Dependencies**: Task 1.1-1.4 (RPC functions)

**Estimated Time**: 3 horas

---

### Task 4.3: Manual Testing & QA

**Requirement Links**: Todas

**Description**:
Testes manuais completos do fluxo de consumo interno end-to-end.

**Acceptance Criteria**:
- [~] Teste manual: marcar checkbox, vê fields desabilitados
- [~] Teste manual: adicionar 3 itens, finalizar consumo, vê toast sucesso
- [~] Teste manual: estoque decrementado corretamente após consumo
- [~] Teste manual: consumo aparece em card de métricas em < 2s
- [~] Teste manual: gráfico mostra ponto novo de consumo
- [~] Teste manual: trocar período no card, gráfico atualiza
- [~] Teste manual: trocar granularidade no gráfico, dados atualizam
- [~] Teste de segurança: usuário A não consegue ver consumos de estabelecimento B
- [~] Teste de erro: consumo sem stock, vê mensagem de erro clara
- [~] Performance: page load < 3s, gráfico renderiza < 1s

**Implementation Notes**:
- Criar checklist em arquivo separado: `.kiro/specs/consumo-interno/QA_CHECKLIST.md`
- Testar em browsers: Chrome, Firefox, Safari
- Testar em responsivos: mobile (iPhone), tablet (iPad), desktop

**Dependencies**: Todas as tarefas anteriores

**Estimated Time**: 2.5 horas

---

### Task 4.4: Deploy to Production and Monitor

**Requirement Links**: Todas

**Description**:
Deploy da feature para produção em Hostinger e monitoramento inicial de erros.

**Acceptance Criteria**:
- [~] Migrations executadas em produção com sucesso
- [~] RPC functions disponíveis e funcionais em produção
- [~] Frontend build otimizado e uploaded para Hostinger
- [~] Feature testada em produção com dados reais
- [~] Console de logs monitorado por erros (use browser DevTools)
- [~] Performance de métricas monitorada (page load, RPC latency)
- [~] Suporta fallback se RPC indisponível (graceful degradation)
- [~] Documentação de rollback preparada se necessário

**Implementation Notes**:
- Build: `npm run build`
- Upload para Hostinger via FTP
- Usar browser DevTools: Performance tab e Network tab
- Console logs: `console.log('CONSUMO_INTERNO_DEPLOY', { success, data })`

**Dependencies**: Todas as tarefas anteriores

**Estimated Time**: 1.5 horas

---

## Summary

| Phase | Task | Estimated Time | Dependencies |
|-------|------|-----------------|--------------|
| 1.1 | Migration: Tables & Indexes | 2h | None |
| 1.2 | RLS Policies | 1.5h | 1.1 |
| 1.3 | RPC: registrar_consumo_interno | 3h | 1.1, 1.2 |
| 1.4 | RPC: obter_consumos_por_periodo | 2.5h | 1.1, 1.2 |
| 2.1 | UI: Checkbox | 1.5h | None |
| 2.2 | PDV Service Logic | 2h | 1.3, 2.1 |
| 2.3 | Validations & Error Handling | 1.5h | 2.1, 2.2 |
| 3.1 | Card Metrics | 2.5h | 1.4 |
| 3.2 | LineChart Evolution | 2.5h | 1.4, 3.1 |
| 3.3 | Metrics Integration | 2h | 1.4, 3.1, 3.2 |
| 4.1 | Unit Tests | 2h | 2.1, 2.2, 2.3 |
| 4.2 | Integration Tests | 3h | 1.1-1.4 |
| 4.3 | Manual QA | 2.5h | All |
| 4.4 | Production Deploy | 1.5h | All |
| | **TOTAL** | **~40 hours** | |

---

## Next Steps

1. Review e aprovação deste documento de tasks
2. Iniciar com Task 1.1 (Migration) após aprovação
3. Cada task concluída deve passar por code review
4. Após cada fase, atualizar status de task em `.config.kiro`

## Files to Be Created/Modified

### New Files
- `.kiro/specs/consumo-interno/migrations/` (directory with SQL migrations)
- `src/hooks/useConsumoInternoMetrics.ts`
- `.kiro/specs/consumo-interno/tests/` (directory with integration tests)
- `.kiro/specs/consumo-interno/QA_CHECKLIST.md`

### Modified Files
- `src/components/delivery/PagamentoPix.tsx` (add checkbox)
- `src/services/vendaPDVService.ts` (add consumo interno logic)
- `src/pages/Metricas.tsx` (add card and chart)
- Database schema (migrations)

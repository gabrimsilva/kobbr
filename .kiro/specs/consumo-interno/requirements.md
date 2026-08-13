# Requirements Document: Consumo Interno no PDV

## Introduction

Esta especificação descreve a funcionalidade "Consumo Interno" que permite registrar e rastrear produtos consumidos internamente pela instituição através do PDV, sem gerar cobrança ao cliente. O sistema faz a baixa de estoque normalmente (como uma venda) e mantém registros separados para auditoria e análise de evolução temporal.

A solução será implementada sobre a stack existente do projeto:
- **Frontend**: React 19, Vite, TypeScript, TailwindCSS v4, react-router-dom v7, shadcn/ui, recharts
- **Backend/Dados**: Supabase (PostgreSQL) com Row Level Security (RLS)

O isolamento de dados multi-tenant será mantido através da coluna `estabelecimento_id` em todas as tabelas envolvidas, com políticas RLS no PostgreSQL para garantir segurança.

## Glossary

- **Consumo Interno**: Saída de produtos da instituição sem cobrança, destinada ao uso interno (consumo da igreja).
- **PDV**: Ponto de Venda (Sistema de vendas diretas).
- **Tabela internal_consumptions**: Tabela de auditoria que rastreia todos os consumos internos com detalhes desnormalizados para análise.
- **Card de Métricas**: Componente visual que exibe a quantidade total de unidades consumidas internamente em período específico.
- **Gráfico de Evolução**: Visualização temporal (linha ou barras) mostrando evolução de consumos internos ao longo do tempo.
- **Estabelecimento_Atual**: O estabelecimento selecionado na sessão, que determina quais consumos são visualizados.
- **RLS Policy**: Política de Row Level Security que filtra dados por estabelecimento.

## Requirements

### Requirement 1: Interface de Checkbox "Consumo Interno" no Modal PDV

**User Story:** Como operador do PDV, quero marcar uma venda como "Consumo Interno" para registrar produtos que serão consumidos internamente sem cobrança.

#### Acceptance Criteria

1. THE modal de finalização de venda no PDV SHALL incluir um checkbox com label "Consumo Interno" posicionado na seção de informações de venda.
2. WHEN o operador marca o checkbox "Consumo Interno", THEN o campo total_amount SHALL ser automaticamente zerado (R$ 0,00) e os campos de cliente e forma de pagamento SHALL ser desabilitados visualmente.
3. WHEN o operador marca o checkbox "Consumo Interno", THEN o sistema SHALL impedir que campos obrigatórios de cliente e pagamento sejam preenchidos, exibindo mensagem: "Campo desabilitado para Consumo Interno".
4. IF o checkbox "Consumo Interno" está marcado E o carrinho está vazio, THEN o botão "Finalizar Venda" SHALL permanecer desabilitado com tooltip: "Adicione itens ao carrinho".
5. WHEN o operador desmarca o checkbox "Consumo Interno", THEN os campos de cliente e forma de pagamento SHALL ser reabilitados e o total_amount SHALL retornar ao cálculo normal (soma dos valores dos itens).
6. THE checkbox "Consumo Interno" SHALL estar desmarcado por padrão.
7. THE interface SHALL validar que NOT (consumo_interno = true AND total_amount > 0), garantindo que "Consumo Interno" SEMPRE implica total_amount = 0.

### Requirement 2: Fluxo de Finalização com Consumo Interno

**User Story:** Como sistema, quero processar vendas marcadas como "Consumo Interno" com segurança, garantindo registro de auditoria e baixa de estoque.

#### Acceptance Criteria

1. WHEN o operador clica "Finalizar Venda" com checkbox "Consumo Interno" marcado, THE sistema SHALL executar as seguintes operações em transação única:
   - INSERT novo registro na tabela `sales` com `is_internal_consumption = true` e `total_amount = 0`
   - INSERT novo registro na tabela `internal_consumptions` com detalhes de data, itens e quantidades
   - DECREMENT quantidade de cada item no estoque (tabela `stock_items`)
   - INSERT registros de movimento no `stock_movements` com tipo 'saida' e motivo 'consumo_interno'
2. IF qualquer operação na transação falhar, THEN o sistema SHALL reverter TODAS as operações (rollback) e exibir mensagem de erro específica ao operador.
3. WHEN a transação é concluída com sucesso, THE sistema SHALL exibir mensagem de confirmação: "Consumo Interno registrado com sucesso" e limpar o carrinho.
4. THE tabela `sales` SHALL conter coluna boolean `is_internal_consumption` (default false) para rastreamento de consumos internos.
5. THE tabela `internal_consumptions` SHALL armazenar items_json em formato JSONB com detalhes: product_id, product_name, quantidade, preco_unitario.
6. ALL registros em `internal_consumptions` SHALL conter `estabelecimento_id` para isolamento multi-tenant via RLS.

### Requirement 3: Tabela internal_consumptions com RLS

**User Story:** Como administrador de segurança, quero garantir que dados de consumo interno sejam isolados por estabelecimento e protegidos contra acesso não autorizado.

#### Acceptance Criteria

1. THE tabela `internal_consumptions` SHALL conter as seguintes colunas obrigatórias:
   - `id` (UUID, chave primária)
   - `estabelecimento_id` (UUID, chave estrangeira para `establishments`, NOT NULL)
   - `sale_id` (UUID, chave estrangeira para `sales`, NOT NULL, UNIQUE)
   - `consumed_at` (TIMESTAMP, NOT NULL, default CURRENT_TIMESTAMP)
   - `total_quantity` (INTEGER, NOT NULL, >= 0)
   - `items_json` (JSONB, NOT NULL, formato: `[{product_id, product_name, quantidade, preco_unitario}]`)
   - `created_by` (UUID, chave estrangeira para `auth.users`)
   - `created_at` (TIMESTAMP, NOT NULL, default CURRENT_TIMESTAMP)

2. THE sistema SHALL criar RLS policy na tabela `internal_consumptions` que:
   - ALLOW SELECT/INSERT/UPDATE/DELETE ONLY IF estabelecimento_id = get_current_estabelecimento_id()
   - RESTRICT acesso a usuários sem perfil autorizado (apenas Admin_Geral e Admin_Estabelecimento)

3. INDEX SHALL be created on `(estabelecimento_id, consumed_at DESC)` para otimizar queries de gráficos temporal.

4. IF um usuário tenta acessar `internal_consumptions` de estabelecimento diferente do seu, THEN a RLS policy SHALL bloquear com erro "authorization".

### Requirement 4: Card de Métricas - Total de Unidades Consumidas

**User Story:** Como gerente, quero visualizar em um card na página de métricas a quantidade total de produtos consumidos internamente para acompanhamento.

#### Acceptance Criteria

1. THE página de Métricas SHALL exibir um novo card com título "Consumo Interno - Total" mostrando:
   - Número total de unidades consumidas internamente no período selecionado (padrão: último mês)
   - Visualização de variação em relação ao período anterior (comparação percentual e tendência com seta)
   - Indicador visual de status (normal/alto/crítico) baseado em threshold configurável

2. THE card SHALL incluir seletor de período (Último Mês, Últimos 3 Meses, Últimos 6 Meses, Ano) para permitir filtro temporal.

3. WHEN o usuário seleciona um período diferente, THE card SHALL atualizar a visualização em até 2 segundos com novo total.

4. IF não há dados de consumo interno no período selecionado, THE card SHALL exibir "Nenhum consumo registrado neste período" com indicador visual neutral.

5. THE card SHALL ser posicionado na seção de Métricas junto aos cards existentes (não em seção separada).

6. THE card SHALL estar acessível ONLY para usuários com permissão de visualizar métricas (Admin_Geral, Admin_Estabelecimento, Operador com permissão específica).

### Requirement 5: Gráfico de Evolução Temporal - Consumo Interno

**User Story:** Como gerente, quero visualizar um gráfico de evolução temporal de consumos internos para identificar padrões e tendências.

#### Acceptance Criteria

1. THE página de Métricas SHALL incluir novo gráfico de linha (LineChart via recharts) mostrando evolução diária ou semanal de consumos internos.

2. THE gráfico SHALL permitir seleção de granularidade: Diária, Semanal, Mensal para período de até 1 ano.

3. THE eixo Y SHALL representar "Quantidade Total (unidades)" e eixo X SHALL representar "Data/Período".

4. WHEN o usuário passa mouse sobre ponto do gráfico, THEN SHALL exibir tooltip com: Data, Quantidade de Unidades, Quantidade de Transações.

5. THE gráfico SHALL exibir legenda colorida e seja responsivo (adaptar a tamanho da tela).

6. IF não há dados no período selecionado, THE gráfico SHALL exibir mensagem "Sem dados para o período selecionado".

7. THE gráfico SHALL usar cores consistentes com tema do estabelecimento (via variáveis CSS).

### Requirement 6: Backend RPC Function - registrar_consumo_interno

**User Story:** Como camada de aplicação, quero executar uma função RPC confiável que registra consumo interno com validações de negócio.

#### Acceptance Criteria

1. THE Supabase RPC function `registrar_consumo_interno()` SHALL aceitar parâmetros:
   - `p_estabelecimento_id` (UUID)
   - `p_items` (JSONB array com product_id, quantidade, preco_unitario)
   - `p_created_by` (UUID, opcional - default = current_user_id())

2. THE função SHALL executar em transação única:
   - Validar que estabelecimento_id existe e user tem acesso
   - Validar que cada item possui product_id e quantidade válidas
   - INSERT venda na tabela `sales` com is_internal_consumption=true, total_amount=0
   - INSERT registro em `internal_consumptions` com items_json desnormalizado
   - DECREMENT estoque de cada item
   - INSERT movimentos em `stock_movements` com tipo='saida', motivo='consumo_interno'

3. IF qualquer validação falha, THE função SHALL rejeitar (rollback) e retornar erro descritivo.

4. ON sucesso, THE função SHALL retornar: `{ success: true, consumption_id: UUID, sale_id: UUID, message: "..." }`

5. THE função SHALL ser protegida por RLS e validar que usuário está vinculado ao estabelecimento.

### Requirement 7: Backend RPC Function - obter_consumos_por_periodo

**User Story:** Como camada de gráficos, quero recuperar dados agregados de consumos internos para visualização com performance otimizada.

#### Acceptance Criteria

1. THE Supabase RPC function `obter_consumos_por_periodo()` SHALL aceitar parâmetros:
   - `p_estabelecimento_id` (UUID)
   - `p_data_inicio` (DATE)
   - `p_data_fim` (DATE)
   - `p_granularidade` ('dia' | 'semana' | 'mes', default 'dia')

2. THE função SHALL retornar array de objetos com campos:
   - `periodo` (VARCHAR: '2026-01-15' ou '2026-W03' ou '2026-01')
   - `total_unidades` (INTEGER)
   - `total_transacoes` (INTEGER)
   - `media_unidades_transacao` (NUMERIC, 2 casas decimais)

3. THE função SHALL filtrar dados por `estabelecimento_id` via RLS automaticamente.

4. THE função SHALL executar com performance < 500ms mesmo com milhares de registros (usar índices apropriados).

5. IF não há dados no período, THE função SHALL retornar array vazio [] (não erro).

6. THE função SHALL ser otimizada para leitura (SELECT) com índice em (estabelecimento_id, consumed_at).

### Requirement 8: Migrations e Data Consistency

**User Story:** Como DevOps, quero aplicar migrations seguras e versionadas para criar tabelas e colunas necessárias.

#### Acceptance Criteria

1. THE migration SHALL criar tabela `internal_consumptions` com estrutura definida em Requirement 3.

2. THE migration SHALL adicionar coluna `is_internal_consumption` (BOOLEAN, default false) na tabela `sales`.

3. THE migration SHALL criar índices conforme Requirement 3 e Requirement 7.

4. THE migration SHALL ser idempotente e segura (usar IF NOT EXISTS, rollback em caso de erro).

5. THE migration SHALL ser versionada e documentada (file naming: YYYYMMDD_hhmmss_descricao.sql).

6. THE migration SHALL ser testável e incluir validações de integridade referencial.

## Validation Properties

### Correctness Properties

1. **Atomicity**: Venda + Consumo + Estoque = sempre em transação, nunca parcial.
2. **Isolation**: Consumos de um estabelecimento NUNCA aparecem em outro via RLS.
3. **Consistency**: total_amount SEMPRE = 0 quando is_internal_consumption = true.
4. **Auditability**: created_by e consumed_at são sempre registrados e imutáveis.
5. **Referential Integrity**: sale_id em internal_consumptions SEMPRE refere sale válida.
6. **Stock Accuracy**: Estoque decrementado em consumo interno EXATAMENTE igual aos itens processados.
7. **Non-Repudiation**: Registro de consumo inclui user_id, timestamp e dados imutáveis para auditoria.

## Non-Functional Requirements

### Performance

- Card de métricas deve atualizar em < 2 segundos para período de até 1 ano
- Gráfico deve renderizar em < 1 segundo mesmo com dados de 12 meses
- RPC functions devem executar em < 500ms
- Índices sobre (estabelecimento_id, consumed_at DESC) obrigatórios

### Security

- RLS policies obrigatórias em todas as tabelas
- Usuário deve ter permissão específica para visualizar métricas de consumo
- Dados de consumo NUNCA devem incluir informações sensíveis de cliente
- Transações devem usar prepared statements (Supabase RLS automático)

### Usability

- Interface de checkbox intuitiva e visualmente clara
- Feedback imediato ao selecionar/desselecionar
- Validações com mensagens em português claro
- Confirmação visual antes de finalizar consumo interno

### Compatibility

- Frontend: React 19 + TypeScript
- Tabelas com estabelecimento_id compatíveis com RLS existente
- Migrations reversíveis (down migration para rollback)
- Sem breaking changes em APIs existentes

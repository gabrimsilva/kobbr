# Requirements Document

## Introduction

Esta especificação descreve a transformação do sistema de gestão existente (atualmente de inquilino único) em uma solução **multi-estabelecimento** (multi-tenant), permitindo que uma mesma instalação da aplicação atenda múltiplos prédios/filiais de uma igreja garantindo **isolamento completo** das operações entre eles.

Cada Estabelecimento funciona como uma unidade independente. Estoque, pedidos, vendas do PDV, delivery, comandas, funcionários, produtos, clientes, avaliações, métricas/analytics e configurações **não são compartilhados** entre estabelecimentos. O único recurso compartilhado é a própria aplicação (código e infraestrutura).

A solução será implementada sobre a stack real do projeto:

- **Frontend**: React 19, Vite, TypeScript, TailwindCSS v4, react-router-dom v7, shadcn/ui (Radix), recharts, react-hot-toast. Estado de aplicação via React Context API (`src/contexts/`).
- **Backend/Dados**: Supabase (PostgreSQL 17) com Row Level Security (RLS), Supabase Auth, Supabase Storage e Edge Functions. Não há servidor Express.

O isolamento de dados será garantido por uma coluna `estabelecimento_id` em todas as tabelas de domínio do inquilino, somada a políticas de RLS no PostgreSQL que filtram cada consulta pelo estabelecimento vinculado ao usuário autenticado. A camada de isolamento server-side (RLS) é a fonte de verdade da segurança; o filtro no frontend é uma camada de conveniência e experiência, não a barreira de segurança. A troca de estabelecimento no frontend será controlada por um Provedor de Contexto React, e a identidade visual por estabelecimento será aplicada via variáveis CSS / Theme Provider.

As funcionalidades existentes devem ser preservadas e os fluxos atuais não devem ser alterados; a camada multi-estabelecimento e a hierarquia de perfis são adicionadas sobre o sistema atual, incluindo a migração dos dados já existentes para um estabelecimento padrão.

## Glossary

- **Sistema**: A aplicação de gestão como um todo, incluindo frontend React e backend Supabase.
- **Estabelecimento**: Unidade operacional independente (prédio/filial) que atua como inquilino (tenant). Cada Estabelecimento possui identificador único, nome, descrição, cor de tema, indicador de ativo e data de criação.
- **Estabelecimento_Atual**: O Estabelecimento selecionado na sessão do usuário, cujo contexto determina quais dados são exibidos e onde novos lançamentos são gravados.
- **Estabelecimento_Padrao**: O Estabelecimento criado durante a migração para receber a vinculação de todos os registros e usuários pré-existentes.
- **Usuario**: Pessoa autenticada via Supabase Auth que acessa o Sistema. Cada Usuario possui um Perfil e, quando aplicável, um Estabelecimento vinculado.
- **Perfil**: Nível de autorização do Usuario. Os três valores válidos são Administrador_Geral, Administrador_de_Estabelecimento e Operador.
- **Administrador_Geral**: Perfil que visualiza e opera todos os Estabelecimentos, troca entre eles, cadastra Usuarios, cadastra Estabelecimentos e altera configurações globais.
- **Administrador_de_Estabelecimento**: Perfil que opera somente o Estabelecimento vinculado, gerencia Usuarios e configurações locais desse Estabelecimento e não visualiza outros Estabelecimentos.
- **Operador**: Perfil que usa as funções operacionais somente dentro do Estabelecimento vinculado, sem trocar de Estabelecimento, cadastrar Usuarios ou alterar configurações globais.
- **Gestor_de_Estabelecimentos**: Componente responsável pelo cadastro e manutenção dos Estabelecimentos.
- **Gestor_de_Usuarios**: Componente responsável pelo cadastro e manutenção de Usuarios, seus Perfis e vínculos com Estabelecimentos.
- **Provedor_de_Contexto**: Componente React (Context Provider) que mantém o Estabelecimento_Atual e o propaga para a aplicação.
- **Seletor_de_Estabelecimento**: Controle de interface no cabeçalho que permite ao Usuario autorizado escolher o Estabelecimento_Atual.
- **Camada_de_Isolamento**: Conjunto de políticas RLS do PostgreSQL e funções auxiliares que restringem cada consulta aos dados do Estabelecimento vinculado ao Usuario autenticado.
- **Provedor_de_Tema**: Componente que aplica a identidade visual (cor) do Estabelecimento_Atual por meio de variáveis CSS.
- **Indicador_de_Estabelecimento**: Elemento de interface permanente no cabeçalho que exibe o Estabelecimento_Atual com a cor correspondente.
- **Registro_de_Auditoria**: Mecanismo que armazena o histórico de ações relevantes contendo Usuario, data, hora, Estabelecimento e ação executada.
- **Tabela_de_Dominio**: Qualquer tabela que armazena dados operacionais pertencentes a um Estabelecimento (por exemplo: produtos, categorias, sabores, tamanhos, adicionais, combos, produto_sabores, combo_produtos, pedidos, historico_pedidos, historico_geral, clientes, comandas, historico_comandas, funcionarios, estoque, avaliacoes, configuracoes, ia_config, ia_conversas, ia_arquivos_temp).

## Requirements

### Requirement 1: Cadastro de Estabelecimentos

**User Story:** Como Administrador Geral, quero cadastrar e manter os estabelecimentos, para que cada prédio/filial exista como unidade independente no sistema.

#### Acceptance Criteria

1. THE Sistema SHALL manter uma entidade Estabelecimento com os atributos identificador único, nome com 1 a 100 caracteres, descrição com no máximo 500 caracteres, cor de tema, indicador de ativo e data de criação.
2. WHEN um Administrador_Geral submete um novo Estabelecimento com nome de 1 a 100 caracteres e cor de tema em formato válido preenchidos, THE Gestor_de_Estabelecimentos SHALL persistir o Estabelecimento com indicador de ativo igual a verdadeiro e data de criação igual ao instante do cadastro em até 3 segundos.
3. IF um Administrador_Geral submete um Estabelecimento com nome ausente, com nome fora do intervalo de 1 a 100 caracteres, ou com cor de tema ausente ou em formato inválido, THEN THE Gestor_de_Estabelecimentos SHALL rejeitar o cadastro, preservar os dados informados e exibir mensagem indicando o campo obrigatório ausente ou inválido.
4. WHEN um Administrador_Geral edita os atributos de um Estabelecimento existente, THE Gestor_de_Estabelecimentos SHALL persistir as alterações sem afetar os dados de domínio vinculados a esse Estabelecimento.
5. WHEN um Administrador_Geral define o indicador de ativo de um Estabelecimento como falso, THE Gestor_de_Estabelecimentos SHALL impedir a seleção desse Estabelecimento como Estabelecimento_Atual mantendo seus dados históricos preservados.
6. WHERE o Usuario autenticado possui Perfil diferente de Administrador_Geral, THE Gestor_de_Estabelecimentos SHALL impedir operações de cadastro, edição e desativação de Estabelecimentos.
7. IF um Administrador_Geral submete um Estabelecimento com nome idêntico ao de um Estabelecimento já existente, THEN THE Gestor_de_Estabelecimentos SHALL rejeitar o cadastro, preservar os dados informados e exibir mensagem indicando duplicidade de nome.
8. IF a persistência do cadastro ou da edição de um Estabelecimento falha, THEN THE Gestor_de_Estabelecimentos SHALL manter o estado anterior do Estabelecimento inalterado, preservar os dados informados e exibir mensagem indicando a falha na operação.

### Requirement 2: Modelo de Usuários e Perfis

**User Story:** Como Administrador Geral, quero gerenciar usuários com perfis e vínculo a estabelecimento, para que cada pessoa tenha acesso adequado ao seu prédio.

#### Acceptance Criteria

1. THE Sistema SHALL manter para cada Usuario os atributos nome (texto de 1 a 120 caracteres, obrigatório), email (texto de 5 a 255 caracteres em formato de endereço de email válido, obrigatório e único), indicador de ativo (valor booleano verdadeiro ou falso, padrão verdadeiro), Perfil (obrigatório) e Estabelecimento vinculado.
2. THE Sistema SHALL restringir o atributo Perfil exclusivamente aos valores Administrador_Geral, Administrador_de_Estabelecimento e Operador, rejeitando qualquer outro valor.
3. WHEN um Administrador_Geral cadastra um Usuario com Perfil Administrador_de_Estabelecimento ou Operador, THE Gestor_de_Usuarios SHALL exigir exatamente um Estabelecimento vinculado e SHALL rejeitar o cadastro caso o Estabelecimento esteja ausente, exibindo mensagem indicando que o vínculo é obrigatório.
4. WHERE um Usuario possui Perfil Administrador_Geral, THE Gestor_de_Usuarios SHALL permitir o cadastro sem Estabelecimento vinculado, tratando o Usuario como autorizado em todos os Estabelecimentos.
5. WHEN um Administrador_Geral cadastra um Usuario com email válido e ainda não existente, THE Gestor_de_Usuarios SHALL criar a credencial de autenticação correspondente no Supabase Auth associada ao email informado em até 5 segundos.
6. IF um Administrador_Geral submete um Usuario com email já cadastrado, THEN THE Gestor_de_Usuarios SHALL rejeitar o cadastro, SHALL não criar credencial no Supabase Auth, SHALL não persistir o Usuario e SHALL exibir mensagem indicando email duplicado.
7. WHILE o indicador de ativo de um Usuario for falso, THE Sistema SHALL negar a autenticação desse Usuario, exibindo mensagem indicando que o acesso está desativado.
8. WHERE o Usuario autenticado possui Perfil Administrador_de_Estabelecimento, THE Gestor_de_Usuarios SHALL permitir o gerenciamento somente de Usuarios vinculados ao próprio Estabelecimento e SHALL impedir a atribuição do Perfil Administrador_Geral, exibindo mensagem indicando operação não permitida.
9. WHERE o Usuario autenticado possui Perfil Operador, THE Gestor_de_Usuarios SHALL impedir o acesso às funções de cadastro e edição de Usuarios, exibindo mensagem indicando acesso negado.
10. IF um Administrador_Geral submete um Usuario com email em formato inválido ou com nome fora do intervalo de 1 a 120 caracteres, THEN THE Gestor_de_Usuarios SHALL rejeitar o cadastro, SHALL não persistir o Usuario e SHALL exibir mensagem indicando o campo inválido.
11. IF a criação da credencial no Supabase Auth falhar durante o cadastro de um Usuario, THEN THE Gestor_de_Usuarios SHALL reverter o cadastro sem persistir o Usuario e SHALL exibir mensagem indicando falha na criação da credencial.

### Requirement 3: Seleção e Troca de Estabelecimento

**User Story:** Como Administrador Geral, quero trocar de estabelecimento pelo seletor no cabeçalho, para que eu opere o prédio desejado sem reautenticar.

#### Acceptance Criteria

1. WHERE o Usuario autenticado possui Perfil Administrador_Geral, THE Seletor_de_Estabelecimento SHALL exibir a lista de Estabelecimentos com status ativo, ordenada por nome em ordem alfabética crescente, em até 2 segundos após a abertura do seletor.
2. WHERE o Usuario autenticado possui Perfil Administrador_Geral, IF não existir nenhum Estabelecimento com status ativo, THEN THE Seletor_de_Estabelecimento SHALL exibir uma mensagem indicando ausência de estabelecimentos disponíveis e SHALL manter o seletor sem opções selecionáveis.
3. WHERE o Usuario autenticado possui Perfil Administrador_de_Estabelecimento ou Operador, THE Seletor_de_Estabelecimento SHALL apresentar somente o Estabelecimento vinculado ao Usuario em modo somente leitura, SHALL impedir a seleção de qualquer outro Estabelecimento e SHALL exibir indicação de que a troca não é permitida.
4. WHEN um Administrador_Geral seleciona um Estabelecimento na lista do Seletor_de_Estabelecimento, THE Provedor_de_Contexto SHALL definir o Estabelecimento selecionado como Estabelecimento_Atual e SHALL indicar visualmente o Estabelecimento_Atual no cabeçalho.
5. WHEN o Estabelecimento_Atual é alterado, THE Sistema SHALL recarregar os dados exibidos (dashboard, produtos, estoque, vendas, PDV, delivery, comandas e analytics) aplicando o filtro do novo Estabelecimento_Atual, em até 5 segundos.
6. IF o recarregamento dos dados após a alteração do Estabelecimento_Atual falhar, THEN THE Sistema SHALL exibir uma indicação de erro informando que os dados não puderam ser carregados, SHALL manter o Estabelecimento_Atual previamente selecionado e SHALL disponibilizar uma ação para nova tentativa.
7. WHEN o Estabelecimento_Atual é alterado, THE Provedor_de_Tema SHALL aplicar a cor de tema configurada para o novo Estabelecimento_Atual em até 1 segundo.
8. WHEN o Estabelecimento_Atual é alterado, THE Sistema SHALL manter a sessão autenticada do Usuario sem exigir nova autenticação.

### Requirement 4: Persistência do Último Estabelecimento

**User Story:** Como usuário, quero que o sistema lembre o último estabelecimento usado, para que eu retome o trabalho no contexto correto ao entrar novamente.

#### Acceptance Criteria

1. WHEN um Administrador_Geral altera o Estabelecimento_Atual, THE Sistema SHALL persistir, em até 2 segundos, o identificador do Estabelecimento selecionado como último Estabelecimento utilizado do Usuario.
2. IF a persistência do último Estabelecimento utilizado falhar, THEN THE Sistema SHALL manter o Estabelecimento_Atual da sessão corrente sem alterar o valor previamente registrado e SHALL exibir uma indicação de erro informando que a preferência não foi salva.
3. WHEN um Administrador_Geral inicia uma nova sessão autenticada e existe um último Estabelecimento utilizado registrado e ativo para esse Usuario, THE Sistema SHALL definir esse Estabelecimento como Estabelecimento_Atual antes de exibir dados de domínio.
4. IF, no início da sessão de um Administrador_Geral, o último Estabelecimento utilizado registrado estiver inativo, inexistente ou não houver registro, THEN THE Sistema SHALL exibir uma lista somente de Estabelecimentos ativos e SHALL exigir a seleção de um Estabelecimento ativo antes de exibir qualquer dado de domínio.
5. WHEN um Usuario com Perfil Administrador_de_Estabelecimento ou Operador inicia uma sessão autenticada, THE Sistema SHALL definir como Estabelecimento_Atual o único Estabelecimento ativo vinculado ao Usuario antes de exibir dados de domínio.
6. IF um Usuario com Perfil Administrador_de_Estabelecimento ou Operador não possuir nenhum Estabelecimento ativo vinculado no início da sessão, THEN THE Sistema SHALL bloquear o acesso aos dados de domínio e SHALL exibir uma indicação informando a ausência de Estabelecimento ativo vinculado.

### Requirement 5: Isolamento de Dados entre Estabelecimentos

**User Story:** Como responsável pela operação, quero que cada estabelecimento veja somente os próprios dados, para que não ocorra vazamento ou mistura de informações entre prédios.

#### Acceptance Criteria

1. THE Sistema SHALL manter em cada Tabela_de_Dominio uma coluna estabelecimento_id, definida como NOT NULL, que referencia o identificador de um Estabelecimento existente.
2. WHEN um registro é criado em uma Tabela_de_Dominio e o Estabelecimento_Atual está definido na sessão autenticada, THE Sistema SHALL atribuir ao campo estabelecimento_id o identificador do Estabelecimento_Atual.
3. WHEN uma consulta de leitura é executada sobre uma Tabela_de_Dominio, THE Camada_de_Isolamento SHALL retornar somente os registros cujo estabelecimento_id corresponde a um Estabelecimento ao qual o Usuario autenticado está autorizado, retornando conjunto vazio quando nenhum registro corresponde.
4. WHEN uma operação de escrita, atualização ou exclusão é executada sobre uma Tabela_de_Dominio, THE Camada_de_Isolamento SHALL permitir a operação somente sobre registros cujo estabelecimento_id corresponde a um Estabelecimento ao qual o Usuario autenticado está autorizado.
5. WHERE o Usuario autenticado possui Perfil Administrador_de_Estabelecimento ou Operador, THE Camada_de_Isolamento SHALL restringir o acesso aos registros cujo estabelecimento_id é igual ao Estabelecimento vinculado ao Usuario.
6. THE Camada_de_Isolamento SHALL aplicar a restrição de estabelecimento_id no PostgreSQL via Row Level Security, de modo que a restrição seja aplicada independentemente de qualquer filtro enviado pelo frontend, inclusive quando nenhum filtro de estabelecimento_id é informado pela requisição.
7. IF uma requisição tenta ler, escrever, atualizar ou excluir registros de um Estabelecimento ao qual o Usuario autenticado não está autorizado, THEN THE Camada_de_Isolamento SHALL negar a operação sobre esses registros, não retornando os dados nem persistindo a alteração e indicando ao solicitante uma falha de autorização, sem expor a existência dos registros não autorizados.
8. IF um registro é criado em uma Tabela_de_Dominio e o Estabelecimento_Atual não está definido na sessão autenticada, THEN THE Sistema SHALL rejeitar a criação, não persistir o registro e indicar ao solicitante uma falha por ausência de estabelecimento.
9. IF a sessão autenticada não possui nenhum Estabelecimento autorizado associado, THEN THE Camada_de_Isolamento SHALL negar o acesso, retornando conjunto vazio em leituras e bloqueando operações de escrita, atualização e exclusão.
10. THE Sistema SHALL atualizar as views existentes para expor a coluna estabelecimento_id e respeitar a restrição da Camada_de_Isolamento.
11. THE Sistema SHALL atualizar as funções de banco existentes para considerar o estabelecimento_id nos resultados e nas operações que executam.

### Requirement 6: Identidade Visual por Estabelecimento

**User Story:** Como usuário, quero que a interface mude de cor conforme o estabelecimento, para que eu identifique visualmente em qual prédio estou operando.

#### Acceptance Criteria

1. WHILE houver um Estabelecimento_Atual definido na sessão, THE Provedor_de_Tema SHALL aplicar a cor de tema do Estabelecimento_Atual, de forma simultânea e consistente, a todos os seguintes elementos de interface: cor principal, barra lateral, botões, cards, destaques, badges, gráficos e links ativos.
2. WHEN o Estabelecimento_Atual é alterado, THE Provedor_de_Tema SHALL atualizar a cor de tema aplicada em até 500 milissegundos e sem recarregar a página do navegador.
3. THE Provedor_de_Tema SHALL aplicar a cor de tema por meio de variáveis CSS controladas pelo Provedor_de_Contexto.
4. WHEN a aplicação é carregada com um Estabelecimento_Atual definido, THE Provedor_de_Tema SHALL aplicar a cor de tema correspondente antes da exibição dos dados de domínio.
5. IF o Estabelecimento_Atual não possui cor de tema definida ou possui cor de tema em formato inválido, THEN THE Provedor_de_Tema SHALL aplicar uma cor de tema padrão aos elementos de interface e SHALL exibir uma indicação visual de que o tema padrão está em uso.
6. WHILE não houver um Estabelecimento_Atual definido na sessão, THE Provedor_de_Tema SHALL aplicar a cor de tema padrão a todos os elementos de interface listados no critério 1.

### Requirement 7: Indicador Visual Permanente

**User Story:** Como usuário, quero ver de forma permanente o estabelecimento atual no topo, para que eu evite lançamentos no estabelecimento errado.

#### Acceptance Criteria

1. WHILE houver um Estabelecimento_Atual definido na sessão, THE Indicador_de_Estabelecimento SHALL exibir o nome do Estabelecimento_Atual no cabeçalho fixo, mantendo-o visível em todas as telas durante a navegação.
2. WHILE houver um Estabelecimento_Atual definido na sessão, THE Indicador_de_Estabelecimento SHALL exibir o nome do Estabelecimento_Atual utilizando a cor de tema correspondente ao Estabelecimento_Atual.
3. WHEN o Estabelecimento_Atual é alterado, THE Indicador_de_Estabelecimento SHALL atualizar o nome exibido para o do novo Estabelecimento_Atual em até 1 segundo.
4. WHEN o Estabelecimento_Atual é alterado, THE Indicador_de_Estabelecimento SHALL atualizar a cor exibida para a cor de tema do novo Estabelecimento_Atual em até 1 segundo.
5. IF não houver um Estabelecimento_Atual definido na sessão, THEN THE Indicador_de_Estabelecimento SHALL exibir no cabeçalho uma indicação de que nenhum estabelecimento está selecionado.

### Requirement 8: Dashboard e Métricas por Estabelecimento

**User Story:** Como gestor, quero que o dashboard mostre apenas os números do estabelecimento atual, para que as métricas reflitam a operação do prédio selecionado.

#### Acceptance Criteria

1. WHEN o dashboard é carregado, THE Sistema SHALL calcular e exibir, em até 3 segundos, os cards pedidos em andamento, entregas finalizadas, vendas do PDV, produtos cadastrados, avaliação média (em escala de 0 a 5, arredondada a 1 casa decimal) e os 5 produtos mais vendidos (ordenados de forma decrescente por quantidade vendida), considerando somente registros cujo estabelecimento_id é igual ao Estabelecimento_Atual.
2. WHEN as telas de analytics e métricas são carregadas, THE Sistema SHALL calcular e exibir os indicadores, em até 3 segundos, considerando somente registros cujo estabelecimento_id é igual ao Estabelecimento_Atual.
3. WHEN o Estabelecimento_Atual é alterado, THE Sistema SHALL recalcular e reexibir os cards do dashboard e os indicadores de analytics para o novo Estabelecimento_Atual em até 3 segundos, substituindo integralmente os valores anteriores.
4. IF o Estabelecimento_Atual não está definido no momento do carregamento do dashboard ou das telas de analytics, THEN THE Sistema SHALL exibir uma indicação solicitando a seleção de um estabelecimento e SHALL omitir o cálculo dos cards e indicadores.
5. WHEN o cálculo de um card ou indicador não retorna nenhum registro para o Estabelecimento_Atual, THE Sistema SHALL exibir o valor zero para indicadores numéricos e uma lista vazia para os produtos mais vendidos, sem apresentar erro.
6. IF a consulta de dados para qualquer card ou indicador falha, THEN THE Sistema SHALL exibir uma indicação de erro identificando o card ou indicador afetado e SHALL preservar os últimos valores exibidos com sucesso.

### Requirement 9: Auditoria de Ações

**User Story:** Como administrador, quero um histórico das ações realizadas, para que eu saiba quem fez o quê, quando e em qual estabelecimento.

#### Acceptance Criteria

1. WHEN um Usuario executa uma ação operacional relevante (cadastro, alteração, exclusão, venda, finalização ou cancelamento), THE Registro_de_Auditoria SHALL armazenar, em até 5 segundos após a conclusão da ação, o identificador do Usuario, a data e a hora da ação com precisão de segundos, o Estabelecimento e uma descrição da ação executada com no máximo 500 caracteres.
2. WHEN um Administrador_Geral altera o Estabelecimento_Atual, THE Registro_de_Auditoria SHALL armazenar um registro contendo o identificador do Usuario, a data e a hora da alteração com precisão de segundos, o Estabelecimento de origem e o Estabelecimento de destino.
3. THE Registro_de_Auditoria SHALL armazenar cada registro com o estabelecimento_id correspondente ao Estabelecimento em que a ação ocorreu.
4. WHEN um Administrador_Geral consulta o Registro_de_Auditoria, THE Sistema SHALL exibir os registros dos Estabelecimentos aos quais o Usuario está autorizado em ordem cronológica decrescente, em páginas de no máximo 50 registros por página.
5. WHERE o Usuario autenticado possui Perfil Administrador_de_Estabelecimento, THE Registro_de_Auditoria SHALL exibir somente os registros do Estabelecimento vinculado ao Usuario.
6. THE Registro_de_Auditoria SHALL impedir qualquer alteração ou exclusão de registros já armazenados, mantendo cada registro inalterado após sua criação.
7. IF o armazenamento de um registro no Registro_de_Auditoria falha, THEN THE Sistema SHALL preservar o resultado da ação operacional executada e registrar a falha com indicação do erro ocorrido.
8. IF um Usuario sem Perfil Administrador_Geral ou Administrador_de_Estabelecimento tenta consultar o Registro_de_Auditoria, THEN THE Sistema SHALL negar o acesso e exibir uma indicação de não autorização.

### Requirement 10: Migração de Dados Existentes

**User Story:** Como responsável pela implantação, quero migrar os dados atuais para um estabelecimento padrão, para que o sistema continue funcionando após a adoção do multi-estabelecimento.

#### Acceptance Criteria

1. WHEN a migração multi-estabelecimento é executada e nenhum Estabelecimento_Padrao existe, THE Sistema SHALL criar exatamente um Estabelecimento_Padrao com identificador único e com indicador de ativo igual a verdadeiro.
2. IF a migração multi-estabelecimento é executada e um Estabelecimento_Padrao já existe, THEN THE Sistema SHALL reutilizar o Estabelecimento_Padrao existente sem criar registro duplicado.
3. WHEN a migração multi-estabelecimento é executada, THE Sistema SHALL atribuir, em uma única transação atômica, o identificador do Estabelecimento_Padrao ao campo estabelecimento_id de todos os registros pré-existentes nas Tabelas_de_Dominio cujo estabelecimento_id esteja vazio.
4. WHEN a atribuição descrita no critério 3 é concluída, THE Sistema SHALL verificar que a quantidade de registros com estabelecimento_id preenchido é igual à quantidade total de registros pré-existentes nas Tabelas_de_Dominio.
5. WHEN a migração multi-estabelecimento é executada, THE Sistema SHALL vincular cada Usuario pré-existente ao Estabelecimento_Padrao, preservando administradores existentes como Administrador_Geral.
6. THE Sistema SHALL definir a coluna estabelecimento_id como obrigatória nas Tabelas_de_Dominio somente após a verificação descrita no critério 4 confirmar que todos os registros pré-existentes possuem estabelecimento_id preenchido.
7. IF a migração multi-estabelecimento é interrompida ou falha antes de concluir a atribuição de estabelecimento_id em qualquer registro, THEN THE Sistema SHALL reverter todas as alterações da transação, preservar os dados originais sem aplicar a restrição de obrigatoriedade da coluna e retornar indicação de erro informando o motivo da falha.

### Requirement 11: Compatibilidade com Funcionalidades Existentes

**User Story:** Como usuário atual do sistema, quero que todas as funcionalidades atuais continuem funcionando, para que a adoção do multi-estabelecimento não interrompa a operação.

#### Acceptance Criteria

1. THE Sistema SHALL manter executáveis os fluxos existentes de produtos, estoque, pedidos, delivery, PDV, comandas, clientes, avaliações e configurações, restritos aos dados do Estabelecimento_Atual, sem exigir etapas adicionais além da seleção de Estabelecimento.
2. WHEN uma funcionalidade existente é executada com um Estabelecimento_Atual definido, THE Sistema SHALL produzir resultados observáveis (telas, listagens e respostas de operação) idênticos aos do mesmo fluxo antes da introdução do multi-estabelecimento, limitados aos registros cujo identificador de Estabelecimento corresponde ao Estabelecimento_Atual.
3. THE Sistema SHALL manter disponíveis as integrações existentes do Supabase (Auth, Storage e Edge Functions), mantendo acessíveis todas as operações dessas integrações que existiam antes do multi-estabelecimento.
4. WHEN uma rota ou tela de domínio existente é acessada sem um Estabelecimento_Atual definido, THE Sistema SHALL solicitar a seleção de um Estabelecimento e não exibir dados de domínio até que a seleção seja concluída.
5. IF um usuário sem nenhum Estabelecimento vinculado acessa uma rota ou tela de domínio, THEN THE Sistema SHALL exibir uma indicação de que não há Estabelecimento disponível, impedir a exibição de dados de domínio e preservar a sessão de autenticação do usuário.

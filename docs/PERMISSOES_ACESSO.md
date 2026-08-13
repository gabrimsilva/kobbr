# Sistema de Permissões de Acesso

## Visão Geral

O sistema implementa controle de acesso baseado em funções (RBAC - Role-Based Access Control) para funcionários. Cada funcionário tem uma função que determina quais áreas do sistema administrativo ele pode acessar.

## Funções e Níveis de Acesso

### 1. Entregador
**Nível de Acesso:** Nenhum acesso à área administrativa

- ❌ Não pode acessar o sistema administrativo
- ✅ Pode fazer login (para futuras funcionalidades de app de entrega)

### 2. Garçom
**Nível de Acesso:** Apenas Comandas

- ✅ Comandas (gerenciar comandas ativas)
- ❌ Histórico de Comandas
- ❌ Todas as outras áreas administrativas

**Casos de Uso:**
- Abrir novas comandas
- Adicionar itens às comandas
- Visualizar comandas abertas
- Editar comandas em andamento

### 3. Atendente
**Nível de Acesso:** Comandas, Pedidos e PDV

- ✅ Comandas (gerenciar comandas ativas)
- ✅ Histórico de Comandas
- ✅ Pedidos (gerenciar pedidos online)
- ✅ Histórico de Pedidos
- ✅ Aguardando Pagamento
- ✅ PDV (Ponto de Venda)
- ❌ Outras áreas administrativas (Produtos, Estoque, Configurações, etc.)

**Casos de Uso:**
- Todas as funcionalidades de Garçom
- Gerenciar pedidos online (delivery)
- Operar o PDV para vendas no balcão
- Consultar histórico de pedidos e comandas
- Acompanhar pagamentos pendentes

## Implementação Técnica

### Banco de Dados

#### Tabela `funcionarios`
```sql
CREATE TABLE funcionarios (
  id UUID PRIMARY KEY,
  nome VARCHAR NOT NULL,
  funcao VARCHAR NOT NULL CHECK (funcao IN ('atendente', 'garcom', 'entregador')),
  email VARCHAR UNIQUE NOT NULL,
  telefone VARCHAR NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  ativo BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}'::jsonb,
  criado_em TIMESTAMPTZ DEFAULT now(),
  atualizado_em TIMESTAMPTZ DEFAULT now()
);
```

#### Funções SQL
```sql
-- Obter função do usuário logado
CREATE FUNCTION get_user_funcao() RETURNS TEXT;

-- Verificar permissão
CREATE FUNCTION check_user_permission(required_roles TEXT[]) RETURNS BOOLEAN;
```

### Frontend

#### Hook `usePermissoes`
```typescript
import { usePermissoes } from '@/hooks/usePermissoes'

function MyComponent() {
  const { permissoes, podeAcessarPagina } = usePermissoes()
  
  // Verificar permissão específica
  if (permissoes.podeAcessarPedidos) {
    // Mostrar conteúdo
  }
  
  // Verificar acesso a uma página
  if (podeAcessarPagina('pedidos')) {
    // Permitir navegação
  }
}
```

#### Propriedades de Permissões
```typescript
interface Permissoes {
  funcao: 'atendente' | 'garcom' | 'entregador' | null
  podeAcessarDashboard: boolean
  podeAcessarPedidos: boolean
  podeAcessarHistorico: boolean
  podeAcessarAguardandoPagamento: boolean
  podeAcessarPDV: boolean
  podeAcessarComandas: boolean
  podeAcessarHistoricoComandas: boolean
  podeAcessarProdutos: boolean
  podeAcessarCategorias: boolean
  podeAcessarSabores: boolean
  podeAcessarAdicionais: boolean
  podeAcessarEstoque: boolean
  podeAcessarFuncionarios: boolean
  podeAcessarConfiguracoes: boolean
  podeAcessarMetricas: boolean
  podeAcessarAnalytics: boolean
  podeAcessarEntregasPorKm: boolean
}
```

## Fluxo de Autenticação e Autorização

1. **Login:** Funcionário faz login com email e senha
2. **Autenticação:** Sistema verifica credenciais no Supabase Auth
3. **Identificação:** Sistema busca registro do funcionário pela `user_id`
4. **Autorização:** Sistema carrega permissões baseadas na `funcao`
5. **Navegação:** Menu e rotas são filtrados conforme permissões
6. **Proteção:** Tentativas de acesso não autorizado são bloqueadas

## Segurança

### Proteção em Múltiplas Camadas

1. **Frontend:**
   - Menu filtrado por permissões
   - Rotas protegidas com verificação
   - Redirecionamento automático se sem permissão

2. **Backend (Supabase):**
   - RLS (Row Level Security) nas tabelas
   - Funções SQL para verificação de permissões
   - Políticas de acesso baseadas em `user_id`

### Mensagens de Erro

Quando um usuário tenta acessar uma área sem permissão:
- Mensagem clara de "Acesso Negado"
- Informação sobre o nível de acesso atual
- Explicação das permissões da função

## Gerenciamento de Funcionários

### Cadastro
1. Acessar "Funcionários" no menu administrativo
2. Clicar em "Novo Funcionário"
3. Preencher dados:
   - Nome completo
   - Telefone
   - Email (único)
   - Função (Atendente, Garçom ou Entregador)
   - Senha (mínimo 6 caracteres)
4. Sistema cria conta no Supabase Auth automaticamente

### Edição
- Dados pessoais podem ser alterados
- Email não pode ser alterado após cadastro
- Função pode ser alterada (atualiza permissões imediatamente)

### Exclusão
- Remove registro do funcionário
- Mantém conta no Auth (para auditoria)
- Pedidos/comandas anteriores mantêm referência

## Boas Práticas

### Para Administradores
1. Atribuir função correta ao cadastrar funcionário
2. Revisar periodicamente as permissões
3. Desativar contas de funcionários inativos
4. Usar emails corporativos quando possível

### Para Desenvolvedores
1. Sempre verificar permissões antes de renderizar conteúdo sensível
2. Usar `podeAcessarPagina()` para validar navegação
3. Implementar verificações no backend também (RLS)
4. Testar com diferentes níveis de acesso

## Futuras Expansões

### Possíveis Melhorias
- [ ] Permissões customizadas por funcionário (campo `metadata`)
- [ ] Logs de acesso e auditoria
- [ ] Permissões temporárias (horário específico)
- [ ] Hierarquia de funções (supervisor, gerente)
- [ ] Aprovação de ações sensíveis
- [ ] Notificações de tentativas de acesso não autorizado

### Integração com App de Entrega
- [ ] Entregadores acessam app mobile
- [ ] Visualizam pedidos atribuídos
- [ ] Atualizam status de entrega
- [ ] Navegação GPS integrada

## Troubleshooting

### Funcionário não consegue acessar área esperada
1. Verificar função atribuída no cadastro
2. Confirmar que está logado com email correto
3. Limpar cache do navegador
4. Fazer logout e login novamente

### Menu não atualiza após mudança de função
1. Fazer logout
2. Fazer login novamente
3. Permissões são carregadas no login

### Erro ao criar funcionário
1. Verificar se email já está em uso
2. Confirmar senha com mínimo 6 caracteres
3. Verificar conexão com Supabase
4. Consultar logs do navegador (F12)

## Suporte

Para dúvidas ou problemas:
1. Consultar esta documentação
2. Verificar logs do sistema
3. Contatar administrador do sistema

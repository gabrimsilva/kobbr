/**
 * Tipos compartilhados para componentes de pedidos
 * @module components/pedidos/types
 */

/**
 * Representa um pedido completo
 */
export interface Pedido {
  /** ID único do pedido */
  id: string
  /** Número sequencial do pedido */
  numero: number
  /** Dados do cliente */
  cliente: Cliente
  /** Itens do pedido */
  itens: ItemPedido[]
  /** Status atual do pedido */
  status: StatusPedido
  /** Tipo de entrega */
  tipo: 'delivery' | 'retirada' | 'local'
  /** Forma de pagamento */
  formaPagamento: string
  /** Subtotal dos itens */
  subtotal: number
  /** Taxa de entrega */
  taxaEntrega: number
  /** Total do pedido */
  total: number
  /** Observações adicionais */
  observacoes?: string
  /** Data/hora de criação */
  created_at: string
  /** Data/hora da última atualização */
  updated_at: string
  /** Tempo estimado de preparo em minutos */
  tempo_preparo?: number
  /** Horário previsto de entrega */
  horario_entrega?: string
}

/**
 * Dados do cliente do pedido
 */
export interface Cliente {
  /** Nome do cliente */
  nome: string
  /** Sobrenome do cliente */
  sobrenome?: string
  /** Telefone de contato */
  telefone: string
  /** Email do cliente */
  email?: string
  /** Logradouro (rua, avenida, etc) */
  endereco?: string
  /** Número da residência */
  numero?: string
  /** Complemento (apto, bloco, etc) */
  complemento?: string
  /** Bairro */
  bairro?: string
  /** Cidade */
  cidade?: string
  /** Estado (UF) */
  estado?: string
  /** CEP */
  cep?: string
}

/**
 * Representa um item dentro de um pedido
 */
export interface ItemPedido {
  /** Dados básicos do produto */
  produto: {
    /** ID do produto */
    id: string
    /** Nome do produto */
    nome: string
    /** Preço unitário */
    preco: number
  }
  /** Quantidade do item */
  quantidade: number
  /** Sabores selecionados (para pizzas) */
  saboresSelecionados?: Array<{
    /** ID do sabor */
    id: string
    /** Nome do sabor */
    nome: string
  }>
  /** Borda selecionada (para pizzas) */
  bordaSelecionada?: {
    /** ID da borda */
    id: string
    /** Nome da borda */
    nome: string
    /** Preço adicional */
    preco: number
  }
  /** Tamanho selecionado (para pizzas) */
  tamanhoSelecionado?: {
    /** ID do tamanho */
    id: string
    /** Nome do tamanho */
    nome: string
  }
  /** Observações do item */
  observacoes?: string
}

/**
 * Status possíveis de um pedido
 */
export type StatusPedido = 
  | 'pendente' 
  | 'em_preparo' 
  | 'pronto' 
  | 'saiu_entrega' 
  | 'entregue' 
  | 'cancelado'

/**
 * Configuração de uma coluna do Kanban
 */
export interface ColunaConfig {
  /** ID da coluna (corresponde ao status) */
  id: StatusPedido
  /** Título exibido na coluna */
  titulo: string
  /** Cor da coluna (classe CSS) */
  cor: string
  /** Ícone da coluna (opcional) */
  icone?: string
}

/**
 * Status da conexão realtime
 */
export interface StatusConexao {
  /** Estado da conexão */
  status: 'online' | 'offline' | 'connecting'
  /** Data/hora da última atualização */
  ultimaAtualizacao?: Date
}

/**
 * Props do componente BarraBuscaPedidos
 */
export interface BarraBuscaProps {
  /** Texto da busca atual */
  busca: string
  /** Callback quando a busca muda */
  onBuscaChange: (busca: string) => void
  /** Placeholder do campo de busca */
  placeholder?: string
}

/**
 * Props do componente HeaderPedidos
 */
export interface HeaderPedidosProps {
  /** Status da conexão realtime */
  statusConexao: StatusConexao
  /** Callback para zerar todos os pedidos */
  onZerarPedidos: () => void
  /** Callback para atualizar pedidos manualmente */
  onAtualizarPedidos: () => void
  /** Callback para reconectar ao realtime */
  onReconectar: () => void
}

/**
 * Props do componente IndicadorConexao
 */
export interface IndicadorConexaoProps {
  /** Estado da conexão */
  status: 'online' | 'offline' | 'connecting'
  /** Data/hora da última atualização */
  ultimaAtualizacao?: Date
  /** Callback para reconectar (opcional) */
  onReconectar?: () => void
}

/**
 * Props do componente ColunaKanban
 */
export interface ColunaKanbanProps {
  /** Configuração da coluna */
  coluna: ColunaConfig
  /** Pedidos a serem exibidos na coluna */
  pedidos: Pedido[]
  /** Callback quando um pedido é movido para outro status */
  onMoverPedido: (pedidoId: string, novoStatus: StatusPedido) => void
}

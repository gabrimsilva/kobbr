/**
 * Tipos compartilhados para componentes de configurações
 * @module components/configuracoes/types
 */

/**
 * Representa o horário de funcionamento de um dia da semana
 */
export interface HorarioFuncionamento {
  /** Nome do dia da semana */
  dia: string
  /** Horário de abertura (formato HH:mm) */
  abertura: string
  /** Horário de fechamento (formato HH:mm) */
  fechamento: string
  /** Indica se o estabelecimento está fechado neste dia */
  fechado: boolean
}

/**
 * Configurações gerais da pizzaria/estabelecimento
 */
export interface ConfiguracoesPizzaria {
  /** ID único da configuração */
  id?: string
  /** Nome do estabelecimento */
  nome: string
  /** Endereço completo */
  endereco: string
  /** Telefone principal */
  telefone: string
  /** WhatsApp para contato */
  whatsapp: string
  /** Perfil do Instagram (opcional) */
  instagram?: string
  /** Página do Facebook (opcional) */
  facebook?: string
  /** Email de contato (opcional) */
  email?: string
  /** Horários de funcionamento por dia da semana */
  horarios: HorarioFuncionamento[]
  /** Indica se trabalha em feriados */
  trabalhaFeriados: boolean
  /** Formas de pagamento aceitas */
  formasPagamento: FormasPagamento
  /** URL da logo (opcional) */
  logoUrl?: string
  /** URL do banner (opcional) */
  bannerUrl?: string
  /** URL do pattern de fundo (opcional) */
  patternUrl?: string
  /** Indica se notificação sonora está ativa */
  notificacaoSonora: boolean
  /** Volume da notificação (0-100) */
  volumeNotificacao: number
  /** Nome do arquivo de som da notificação */
  somNotificacao: string
  /** Taxa de entrega em reais (opcional) */
  taxaEntrega?: number
  /** Tempo médio de entrega em minutos (opcional) */
  tempoMedioEntrega?: number
}

/**
 * Formas de pagamento aceitas pelo estabelecimento
 */
export interface FormasPagamento {
  /** Aceita pagamento em dinheiro */
  dinheiro: boolean
  /** Aceita pagamento via PIX */
  pix: boolean
  /** Aceita cartão de crédito */
  cartaoCredito: boolean
  /** Aceita cartão de débito */
  cartaoDebito: boolean
  /** Aceita vale refeição */
  valeRefeicao: boolean
}

/**
 * Props do componente ConfiguracoesVisuais
 */
export interface ConfiguracoesVisuaisProps {
  /** URL da logo atual */
  logoUrl?: string
  /** URL do banner atual */
  bannerUrl?: string
  /** URL do pattern de fundo atual */
  patternUrl?: string
  /** Callback quando a logo é alterada */
  onLogoChange: (url: string) => void
  /** Callback quando o banner é alterado */
  onBannerChange: (url: string) => void
  /** Callback quando o pattern é alterado */
  onPatternChange: (url: string) => void
}

/**
 * Props do componente ConfiguracoesNotificacao
 */
export interface ConfiguracoesNotificacaoProps {
  /** Indica se notificação sonora está ativa */
  notificacaoSonora: boolean
  /** Volume da notificação (0-100) */
  volumeNotificacao: number
  /** Nome do arquivo de som selecionado */
  somNotificacao: string
  /** Callback quando notificação é ativada/desativada */
  onNotificacaoChange: (enabled: boolean) => void
  /** Callback quando o volume é alterado */
  onVolumeChange: (volume: number) => void
  /** Callback quando o som é alterado */
  onSomChange: (som: string) => void
}

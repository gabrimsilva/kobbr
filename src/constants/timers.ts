/**
 * Constantes de Tempo e Delays
 *
 * Centralizadas para facilitar ajustes e manutenção.
 * Todos os valores em milissegundos.
 *
 * @module constants/timers
 */

/**
 * Delays de reconexão e retry
 */
export const RECONNECT_DELAYS = {
  /** Delay para reconexão do realtime (1 minuto) */
  REALTIME: 60000,

  /** Delay entre tentativas de retry (5 segundos) */
  RETRY: 5000,

  /** Delay curto para retry rápido (2 segundos) */
  RETRY_FAST: 2000,

  /** Delay para reconexão após erro crítico (30 segundos) */
  RETRY_CRITICAL: 30000
} as const

/**
 * Intervalos de sincronização
 */
export const SYNC_INTERVALS = {
  /** Intervalo de sincronização de pedidos (10 segundos) */
  PEDIDOS: 10000,

  /** Intervalo de sincronização de estoque (30 segundos) */
  ESTOQUE: 30000,

  /** Intervalo de atualização de status (5 segundos) */
  STATUS: 5000,

  /** Intervalo de heartbeat da conexão (60 segundos) */
  HEARTBEAT: 60000
} as const

/**
 * Delays de debounce para inputs
 */
export const DEBOUNCE_DELAYS = {
  /** Debounce para busca de texto (500ms) */
  SEARCH: 500,

  /** Debounce para validação de formulário (300ms) */
  FORM_VALIDATION: 300,

  /** Debounce para busca de CEP (800ms) */
  CEP_SEARCH: 800,

  /** Debounce para auto-save (1 segundo) */
  AUTO_SAVE: 1000,

  /** Debounce para resize de janela (250ms) */
  WINDOW_RESIZE: 250
} as const

/**
 * Timeouts de operações
 */
export const OPERATION_TIMEOUTS = {
  /** Timeout para requisições de API (30 segundos) */
  API_REQUEST: 30000,

  /** Timeout para upload de imagem (60 segundos) */
  IMAGE_UPLOAD: 60000,

  /** Timeout para autenticação (15 segundos) */
  AUTH: 15000,

  /** Timeout para busca de endereço (10 segundos) */
  ADDRESS_LOOKUP: 10000
} as const

/**
 * Durações de animações e transições
 */
export const ANIMATION_DURATIONS = {
  /** Animação curta (150ms) */
  SHORT: 150,

  /** Animação média (300ms) */
  MEDIUM: 300,

  /** Animação longa (500ms) */
  LONG: 500,

  /** Fade in/out (200ms) */
  FADE: 200,

  /** Slide (250ms) */
  SLIDE: 250
} as const

/**
 * Durações de notificações
 */
export const NOTIFICATION_DURATIONS = {
  /** Notificação de sucesso (3 segundos) */
  SUCCESS: 3000,

  /** Notificação de erro (5 segundos) */
  ERROR: 5000,

  /** Notificação de aviso (4 segundos) */
  WARNING: 4000,

  /** Notificação de informação (3 segundos) */
  INFO: 3000,

  /** Notificação persistente (não fecha automaticamente) */
  PERSISTENT: Infinity
} as const

/**
 * Durações de cache
 */
export const CACHE_DURATIONS = {
  /** Cache de configurações (5 minutos) */
  CONFIGURACOES: 5 * 60 * 1000,

  /** Cache de categorias (10 minutos) */
  CATEGORIAS: 10 * 60 * 1000,

  /** Cache de produtos (2 minutos) */
  PRODUTOS: 2 * 60 * 1000,

  /** Cache de combos (5 minutos) */
  COMBOS: 5 * 60 * 1000,

  /** Cache de usuário (1 hora) */
  USUARIO: 60 * 60 * 1000,

  /** Cache curto para dados voláteis (30 segundos) */
  SHORT: 30 * 1000
} as const

/**
 * Limites de tempo para ações do usuário
 */
export const USER_ACTION_LIMITS = {
  /** Tempo máximo para editar pedido (5 minutos) */
  EDIT_PEDIDO: 5 * 60 * 1000,

  /** Tempo de sessão inativa antes de logout (30 minutos) */
  SESSION_TIMEOUT: 30 * 60 * 1000,

  /** Tempo para confirmar ação crítica (10 segundos) */
  CONFIRM_ACTION: 10 * 1000
} as const

/**
 * Delays para polling
 */
export const POLLING_INTERVALS = {
  /** Polling rápido para atualizações em tempo real (3 segundos) */
  FAST: 3000,

  /** Polling normal (10 segundos) */
  NORMAL: 10000,

  /** Polling lento para dados menos voláteis (30 segundos) */
  SLOW: 30000,

  /** Polling muito lento (1 minuto) */
  VERY_SLOW: 60000
} as const

/**
 * Helper: Converte segundos para milissegundos
 */
export const seconds = (s: number): number => s * 1000

/**
 * Helper: Converte minutos para milissegundos
 */
export const minutes = (m: number): number => m * 60 * 1000

/**
 * Helper: Converte horas para milissegundos
 */
export const hours = (h: number): number => h * 60 * 60 * 1000

/**
 * Exportar tudo como namespace default
 */
export default {
  RECONNECT_DELAYS,
  SYNC_INTERVALS,
  DEBOUNCE_DELAYS,
  OPERATION_TIMEOUTS,
  ANIMATION_DURATIONS,
  NOTIFICATION_DURATIONS,
  CACHE_DURATIONS,
  USER_ACTION_LIMITS,
  POLLING_INTERVALS,
  // Helpers
  seconds,
  minutes,
  hours
}

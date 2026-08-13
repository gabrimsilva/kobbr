/**
 * Constantes Centralizadas do Sistema
 *
 * Ponto de entrada único para todas as constantes do projeto.
 *
 * @module constants
 */

// Re-exportar tudo de timers
export * from './timers'
export { default as TIMERS } from './timers'

// Re-exportar tudo de limits
export * from './limits'
export { default as LIMITS } from './limits'

/**
 * Exemplo de uso:
 *
 * ```typescript
 * // Importar constantes específicas
 * import { DEBOUNCE_DELAYS, STRING_LIMITS } from '@/constants'
 *
 * // Ou importar namespaces completos
 * import { TIMERS, LIMITS } from '@/constants'
 *
 * // Usar constantes
 * const delay = DEBOUNCE_DELAYS.SEARCH
 * const maxLength = STRING_LIMITS.NOME_MAX
 * ```
 */

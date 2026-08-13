/**
 * Utilitários para retry automático de operações assíncronas
 *
 * Implementa estratégias de retry com backoff exponencial para
 * operações que podem falhar temporariamente (rede, API, etc.)
 */

/**
 * Configuração para retry automático
 */
export interface RetryOptions {
  /** Número máximo de tentativas (padrão: 3) */
  maxAttempts?: number
  /** Delay inicial em ms (padrão: 1000) */
  initialDelay?: number
  /** Fator de multiplicação do delay a cada tentativa (padrão: 2) */
  backoffMultiplier?: number
  /** Delay máximo em ms (padrão: 10000) */
  maxDelay?: number
  /** Função para determinar se deve tentar novamente baseado no erro */
  shouldRetry?: (error: unknown) => boolean
  /** Callback executado antes de cada retry */
  onRetry?: (attempt: number, error: unknown) => void
}

/**
 * Determina se um erro é relacionado à rede
 */
function isNetworkError(error: unknown): boolean {
  if (error instanceof Error) {
    const message = error.message.toLowerCase()
    return (
      message.includes('network') ||
      message.includes('fetch') ||
      message.includes('timeout') ||
      message.includes('connection') ||
      message.includes('econnrefused') ||
      message.includes('enotfound')
    )
  }

  // Erro do Supabase relacionado à rede
  if (typeof error === 'object' && error !== null) {
    const err = error as { message?: string; code?: string; status?: number }
    if (err.code === 'PGRST301' || err.status === 503 || err.status === 502) {
      return true
    }
  }

  return false
}

/**
 * Aguarda um determinado tempo
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

/**
 * Calcula o delay com backoff exponencial
 */
function calculateDelay(
  attempt: number,
  initialDelay: number,
  backoffMultiplier: number,
  maxDelay: number
): number {
  const delay = initialDelay * Math.pow(backoffMultiplier, attempt - 1)
  return Math.min(delay, maxDelay)
}

/**
 * Executa uma função assíncrona com retry automático
 *
 * @template T Tipo de retorno da função
 * @param fn Função assíncrona a ser executada
 * @param options Opções de configuração do retry
 * @returns Promise com o resultado da função
 * @throws Lança o último erro se todas as tentativas falharem
 *
 * @example
 * ```typescript
 * const data = await withRetry(
 *   async () => {
 *     const result = await supabase.from('pedidos').select('*')
 *     if (result.error) throw result.error
 *     return result.data
 *   },
 *   {
 *     maxAttempts: 3,
 *     initialDelay: 1000,
 *     onRetry: (attempt, error) => {
 *       console.log(`Tentativa ${attempt} falhou:`, error)
 *     }
 *   }
 * )
 * ```
 */
export async function withRetry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> {
  const {
    maxAttempts = 3,
    initialDelay = 1000,
    backoffMultiplier = 2,
    maxDelay = 10000,
    shouldRetry = isNetworkError,
    onRetry
  } = options

  let lastError: unknown

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn()
    } catch (error) {
      lastError = error

      // Se é a última tentativa, lança o erro
      if (attempt === maxAttempts) {
        break
      }

      // Verifica se deve tentar novamente
      if (!shouldRetry(error)) {
        throw error
      }

      // Callback antes do retry
      if (onRetry) {
        onRetry(attempt, error)
      }

      // Aguarda com backoff exponencial
      const delay = calculateDelay(attempt, initialDelay, backoffMultiplier, maxDelay)
      console.warn(
        `[Retry] Tentativa ${attempt}/${maxAttempts} falhou. Tentando novamente em ${delay}ms...`,
        error
      )
      await sleep(delay)
    }
  }

  // Se chegou aqui, todas as tentativas falharam
  throw lastError
}

/**
 * Cria uma versão com retry de uma função assíncrona
 *
 * @template T Tipo dos argumentos da função
 * @template R Tipo de retorno da função
 * @param fn Função assíncrona a ser envolvida
 * @param options Opções de configuração do retry
 * @returns Nova função com retry automático
 *
 * @example
 * ```typescript
 * const buscarPedidosComRetry = withRetryWrapper(
 *   async (status: string) => {
 *     const result = await supabase
 *       .from('pedidos')
 *       .select('*')
 *       .eq('status', status)
 *     if (result.error) throw result.error
 *     return result.data
 *   },
 *   { maxAttempts: 3 }
 * )
 *
 * // Uso
 * const pedidos = await buscarPedidosComRetry('pendente')
 * ```
 */
export function withRetryWrapper<T extends unknown[], R>(
  fn: (...args: T) => Promise<R>,
  options: RetryOptions = {}
): (...args: T) => Promise<R> {
  return async (...args: T) => {
    return withRetry(() => fn(...args), options)
  }
}

/**
 * Executa múltiplas operações em paralelo com retry individual
 *
 * Similar a Promise.all, mas com retry automático para cada operação
 *
 * @param operations Array de funções assíncronas
 * @param options Opções de retry aplicadas a todas as operações
 * @returns Promise com array dos resultados
 *
 * @example
 * ```typescript
 * const [pedidos, produtos, categorias] = await retryAll([
 *   async () => supabase.from('pedidos').select('*'),
 *   async () => supabase.from('produtos').select('*'),
 *   async () => supabase.from('categorias').select('*')
 * ], { maxAttempts: 2 })
 * ```
 */
export async function retryAll<T extends unknown[]>(
  operations: { [K in keyof T]: () => Promise<T[K]> },
  options: RetryOptions = {}
): Promise<T> {
  return Promise.all(
    operations.map((op) => withRetry(op, options))
  ) as Promise<T>
}

/**
 * Configurações padrão para diferentes tipos de operação
 */
export const RETRY_PRESETS = {
  /** Para operações críticas que precisam de alta confiabilidade */
  CRITICAL: {
    maxAttempts: 5,
    initialDelay: 1000,
    backoffMultiplier: 2,
    maxDelay: 15000
  } as RetryOptions,

  /** Para operações normais */
  NORMAL: {
    maxAttempts: 3,
    initialDelay: 1000,
    backoffMultiplier: 2,
    maxDelay: 10000
  } as RetryOptions,

  /** Para operações rápidas que não devem demorar muito */
  FAST: {
    maxAttempts: 2,
    initialDelay: 500,
    backoffMultiplier: 2,
    maxDelay: 2000
  } as RetryOptions,

  /** Para operações que podem ser tentadas muitas vezes */
  PERSISTENT: {
    maxAttempts: 10,
    initialDelay: 2000,
    backoffMultiplier: 1.5,
    maxDelay: 30000
  } as RetryOptions
}

/**
 * Sistema de Logging Estruturado
 *
 * Substitui console.log com um sistema profissional de logging
 * que controla níveis de log baseado no ambiente.
 *
 * @module utils/logger
 */

/**
 * Níveis de log disponíveis
 */
export const LogLevel = {
  DEBUG: 0,
  INFO: 1,
  WARN: 2,
  ERROR: 3,
  NONE: 4
} as const

export type LogLevel = typeof LogLevel[keyof typeof LogLevel]

/**
 * Configuração do logger
 */
interface LoggerConfig {
  /** Nível mínimo de log a ser exibido */
  level: LogLevel
  /** Se deve incluir timestamp */
  includeTimestamp: boolean
  /** Se deve incluir stack trace em erros */
  includeStackTrace: boolean
  /** Prefixo para todas as mensagens */
  prefix?: string
  /** Se deve enviar logs para servidor (futuro) */
  sendToServer: boolean
}

/**
 * Configuração padrão baseada no ambiente
 */
const defaultConfig: LoggerConfig = {
  level: import.meta.env.DEV ? LogLevel.DEBUG : LogLevel.ERROR,
  includeTimestamp: import.meta.env.DEV,
  includeStackTrace: import.meta.env.DEV,
  prefix: '[App]',
  sendToServer: import.meta.env.PROD
}

/**
 * Configuração atual do logger
 */
let config: LoggerConfig = { ...defaultConfig }

/**
 * Mapeamento de níveis para cores no console
 */
const levelColors: Record<LogLevel, string> = {
  [LogLevel.DEBUG]: '#6B7280', // gray
  [LogLevel.INFO]: '#3B82F6',  // blue
  [LogLevel.WARN]: '#F59E0B',  // yellow
  [LogLevel.ERROR]: '#EF4444', // red
  [LogLevel.NONE]: '#000000'
}

/**
 * Mapeamento de níveis para nomes
 */
const levelNames: Record<LogLevel, string> = {
  [LogLevel.DEBUG]: 'DEBUG',
  [LogLevel.INFO]: 'INFO',
  [LogLevel.WARN]: 'WARN',
  [LogLevel.ERROR]: 'ERROR',
  [LogLevel.NONE]: 'NONE'
}

/**
 * Formata mensagem de log com timestamp e nível
 */
function formatMessage(level: LogLevel, category: string, message: string): string {
  const parts: string[] = []

  if (config.prefix) {
    parts.push(config.prefix)
  }

  if (config.includeTimestamp) {
    const now = new Date()
    const time = now.toLocaleTimeString('pt-BR', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      fractionalSecondDigits: 3
    })
    parts.push(`[${time}]`)
  }

  parts.push(`[${levelNames[level]}]`)

  if (category) {
    parts.push(`[${category}]`)
  }

  parts.push(message)

  return parts.join(' ')
}

/**
 * Envia log para servidor (implementação futura)
 */
async function sendLogToServer(
  level: LogLevel,
  category: string,
  message: string,
  data?: any
): Promise<void> {
  if (!config.sendToServer || level < LogLevel.ERROR) {
    return
  }

  // TODO: Implementar envio para servidor de logs (ex: Sentry, LogRocket)
  // Por enquanto, apenas armazena localmente para debug
  try {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level: levelNames[level],
      category,
      message,
      data,
      userAgent: navigator.userAgent,
      url: window.location.href
    }

    // Armazenar últimos 50 logs em localStorage para debug
    const logs = JSON.parse(localStorage.getItem('app-logs') || '[]')
    logs.push(logEntry)
    if (logs.length > 50) {
      logs.shift()
    }
    localStorage.setItem('app-logs', JSON.stringify(logs))
  } catch (error) {
    // Falha silenciosa no logging para não quebrar o app
  }
}

/**
 * Classe Logger principal
 */
class Logger {
  /**
   * Log de debug - apenas em desenvolvimento
   */
  debug(category: string, message: string, ...args: any[]): void {
    if (config.level <= LogLevel.DEBUG) {
      const formatted = formatMessage(LogLevel.DEBUG, category, message)
      console.debug(
        `%c${formatted}`,
        `color: ${levelColors[LogLevel.DEBUG]}`,
        ...args
      )
    }
  }

  /**
   * Log de informação
   */
  info(category: string, message: string, ...args: any[]): void {
    if (config.level <= LogLevel.INFO) {
      const formatted = formatMessage(LogLevel.INFO, category, message)
      console.info(
        `%c${formatted}`,
        `color: ${levelColors[LogLevel.INFO]}`,
        ...args
      )
    }
  }

  /**
   * Log de aviso
   */
  warn(category: string, message: string, ...args: any[]): void {
    if (config.level <= LogLevel.WARN) {
      const formatted = formatMessage(LogLevel.WARN, category, message)
      console.warn(
        `%c${formatted}`,
        `color: ${levelColors[LogLevel.WARN]}`,
        ...args
      )
      sendLogToServer(LogLevel.WARN, category, message, args)
    }
  }

  /**
   * Log de erro
   */
  error(category: string, message: string, error?: Error | any, ...args: any[]): void {
    if (config.level <= LogLevel.ERROR) {
      const formatted = formatMessage(LogLevel.ERROR, category, message)

      if (config.includeStackTrace && error instanceof Error) {
        console.error(
          `%c${formatted}`,
          `color: ${levelColors[LogLevel.ERROR]}`,
          '\n',
          error.stack || error,
          ...args
        )
      } else {
        console.error(
          `%c${formatted}`,
          `color: ${levelColors[LogLevel.ERROR]}`,
          error,
          ...args
        )
      }

      sendLogToServer(LogLevel.ERROR, category, message, { error, args })
    }
  }

  /**
   * Log de performance/timing
   */
  time(label: string): void {
    if (import.meta.env.DEV) {
      console.time(`⏱️ ${label}`)
    }
  }

  /**
   * Finaliza log de performance
   */
  timeEnd(label: string): void {
    if (import.meta.env.DEV) {
      console.timeEnd(`⏱️ ${label}`)
    }
  }

  /**
   * Agrupa logs relacionados
   */
  group(label: string): void {
    if (import.meta.env.DEV) {
      console.group(label)
    }
  }

  /**
   * Finaliza grupo de logs
   */
  groupEnd(): void {
    if (import.meta.env.DEV) {
      console.groupEnd()
    }
  }

  /**
   * Log de tabela (útil para arrays/objetos)
   */
  table(data: any): void {
    if (import.meta.env.DEV) {
      console.table(data)
    }
  }

  /**
   * Atualiza configuração do logger
   */
  configure(newConfig: Partial<LoggerConfig>): void {
    config = { ...config, ...newConfig }
  }

  /**
   * Obtém configuração atual
   */
  getConfig(): LoggerConfig {
    return { ...config }
  }

  /**
   * Obtém logs armazenados localmente
   */
  getStoredLogs(): any[] {
    try {
      return JSON.parse(localStorage.getItem('app-logs') || '[]')
    } catch {
      return []
    }
  }

  /**
   * Limpa logs armazenados
   */
  clearStoredLogs(): void {
    localStorage.removeItem('app-logs')
  }
}

/**
 * Instância singleton do logger
 */
export const logger = new Logger()

/**
 * Alias para categorias comuns
 */
export const log = {
  /**
   * Logs de autenticação
   */
  auth: {
    debug: (msg: string, ...args: any[]) => logger.debug('AUTH', msg, ...args),
    info: (msg: string, ...args: any[]) => logger.info('AUTH', msg, ...args),
    warn: (msg: string, ...args: any[]) => logger.warn('AUTH', msg, ...args),
    error: (msg: string, error?: any, ...args: any[]) => logger.error('AUTH', msg, error, ...args)
  },

  /**
   * Logs de API/requisições
   */
  api: {
    debug: (msg: string, ...args: any[]) => logger.debug('API', msg, ...args),
    info: (msg: string, ...args: any[]) => logger.info('API', msg, ...args),
    warn: (msg: string, ...args: any[]) => logger.warn('API', msg, ...args),
    error: (msg: string, error?: any, ...args: any[]) => logger.error('API', msg, error, ...args)
  },

  /**
   * Logs de UI/componentes
   */
  ui: {
    debug: (msg: string, ...args: any[]) => logger.debug('UI', msg, ...args),
    info: (msg: string, ...args: any[]) => logger.info('UI', msg, ...args),
    warn: (msg: string, ...args: any[]) => logger.warn('UI', msg, ...args),
    error: (msg: string, error?: any, ...args: any[]) => logger.error('UI', msg, error, ...args)
  },

  /**
   * Logs de segurança
   */
  security: {
    debug: (msg: string, ...args: any[]) => logger.debug('SECURITY', msg, ...args),
    info: (msg: string, ...args: any[]) => logger.info('SECURITY', msg, ...args),
    warn: (msg: string, ...args: any[]) => logger.warn('SECURITY', msg, ...args),
    error: (msg: string, error?: any, ...args: any[]) => logger.error('SECURITY', msg, error, ...args)
  },

  /**
   * Logs de dados/banco
   */
  data: {
    debug: (msg: string, ...args: any[]) => logger.debug('DATA', msg, ...args),
    info: (msg: string, ...args: any[]) => logger.info('DATA', msg, ...args),
    warn: (msg: string, ...args: any[]) => logger.warn('DATA', msg, ...args),
    error: (msg: string, error?: any, ...args: any[]) => logger.error('DATA', msg, error, ...args)
  },

  /**
   * Logs de performance
   */
  perf: {
    debug: (msg: string, ...args: any[]) => logger.debug('PERF', msg, ...args),
    info: (msg: string, ...args: any[]) => logger.info('PERF', msg, ...args),
    time: (label: string) => logger.time(label),
    timeEnd: (label: string) => logger.timeEnd(label)
  }
}

/**
 * Exportar logger como default
 */
export default logger

/**
 * Em desenvolvimento, expor logger globalmente para debug no console
 */
if (import.meta.env.DEV) {
  ;(window as any).logger = logger
  ;(window as any).log = log
}

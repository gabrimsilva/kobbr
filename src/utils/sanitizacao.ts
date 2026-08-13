/**
 * Utilitários para sanitização de inputs
 *
 * Este módulo fornece funções para limpar e sanitizar dados de entrada
 * do usuário, prevenindo ataques XSS e injeção de código malicioso.
 */

import DOMPurify from 'isomorphic-dompurify'

/**
 * Configuração padrão do DOMPurify
 * Remove tags perigosas mas mantém formatação básica se necessário
 */
const DEFAULT_CONFIG = {
  ALLOWED_TAGS: [], // Não permitir nenhuma tag HTML por padrão
  ALLOWED_ATTR: [], // Não permitir nenhum atributo por padrão
  KEEP_CONTENT: true, // Manter conteúdo mesmo removendo tags
  ALLOW_DATA_ATTR: false,
  ALLOW_UNKNOWN_PROTOCOLS: false,
  SAFE_FOR_TEMPLATES: true
}

/**
 * Configuração para texto rico (se necessário em algumas áreas)
 * Permite formatação básica segura
 */
const RICH_TEXT_CONFIG = {
  ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'br'], // Apenas formatação básica
  ALLOWED_ATTR: [],
  KEEP_CONTENT: true,
  ALLOW_DATA_ATTR: false,
  ALLOW_UNKNOWN_PROTOCOLS: false,
  SAFE_FOR_TEMPLATES: true
}

/**
 * Sanitiza uma string removendo todo HTML/JavaScript
 *
 * @param input - String a ser sanitizada
 * @returns String limpa e segura
 *
 * @example
 * ```typescript
 * const unsafe = '<script>alert("xss")</script>Olá'
 * const safe = sanitizeInput(unsafe) // Retorna: 'Olá'
 * ```
 */
export function sanitizeInput(input: string | null | undefined): string {
  if (!input || typeof input !== 'string') {
    return ''
  }

  const sanitized = DOMPurify.sanitize(input, DEFAULT_CONFIG)
  return String(sanitized).trim()
}

/**
 * Sanitiza texto permitindo formatação básica (bold, italic)
 * Use apenas em áreas onde formatação é necessária e confiável
 *
 * @param input - String a ser sanitizada
 * @returns String limpa com formatação básica permitida
 *
 * @example
 * ```typescript
 * const text = '<b>Importante</b><script>alert("xss")</script>'
 * const safe = sanitizeRichText(text) // Retorna: '<b>Importante</b>'
 * ```
 */
export function sanitizeRichText(input: string | null | undefined): string {
  if (!input || typeof input !== 'string') {
    return ''
  }

  const sanitized = DOMPurify.sanitize(input, RICH_TEXT_CONFIG)
  return String(sanitized).trim()
}

/**
 * Sanitiza um objeto, limpando todas as propriedades string recursivamente
 *
 * @param obj - Objeto a ser sanitizado
 * @returns Novo objeto com todas as strings sanitizadas
 *
 * @example
 * ```typescript
 * const data = {
 *   nome: '<script>alert("xss")</script>João',
 *   observacao: 'Sem <b>cebola</b>'
 * }
 * const safe = sanitizeObject(data)
 * // Retorna: { nome: 'João', observacao: 'Sem cebola' }
 * ```
 */
export function sanitizeObject<T extends Record<string, any>>(obj: T): T {
  if (!obj || typeof obj !== 'object') {
    return obj
  }

  const sanitized = { ...obj }

  for (const key in sanitized) {
    const value = sanitized[key]

    if (typeof value === 'string') {
      (sanitized[key] as any) = sanitizeInput(value)
    } else if (Array.isArray(value)) {
      (sanitized[key] as any) = value.map((item: any) =>
        typeof item === 'string' ? sanitizeInput(item) : item
      )
    } else if (typeof value === 'object' && value !== null) {
      sanitized[key] = sanitizeObject(value)
    }
  }

  return sanitized
}

/**
 * Sanitiza dados de formulário de pedido/checkout
 *
 * @param formData - Dados do formulário
 * @returns Dados sanitizados
 */
export function sanitizeCheckoutData(formData: {
  cliente_nome?: string
  cliente_sobrenome?: string
  cliente_telefone?: string
  cliente_email?: string
  cliente_cpf?: string
  cliente_endereco?: string
  cliente_numero?: string
  cliente_complemento?: string
  cliente_bairro?: string
  cliente_cidade?: string
  cliente_estado?: string
  cliente_cep?: string
  observacoes?: string
  [key: string]: any
}) {
  return {
    ...formData,
    cliente_nome: sanitizeInput(formData.cliente_nome),
    cliente_sobrenome: sanitizeInput(formData.cliente_sobrenome),
    cliente_telefone: sanitizeInput(formData.cliente_telefone),
    cliente_email: sanitizeInput(formData.cliente_email),
    cliente_cpf: sanitizeInput(formData.cliente_cpf),
    cliente_endereco: sanitizeInput(formData.cliente_endereco),
    cliente_numero: sanitizeInput(formData.cliente_numero),
    cliente_complemento: sanitizeInput(formData.cliente_complemento),
    cliente_bairro: sanitizeInput(formData.cliente_bairro),
    cliente_cidade: sanitizeInput(formData.cliente_cidade),
    cliente_estado: sanitizeInput(formData.cliente_estado),
    cliente_cep: sanitizeInput(formData.cliente_cep),
    observacoes: sanitizeInput(formData.observacoes)
  }
}

/**
 * Sanitiza itens do carrinho, especialmente observações
 *
 * @param items - Array de itens do carrinho
 * @returns Array de itens sanitizados
 */
export function sanitizeCartItems(items: any[]): any[] {
  if (!Array.isArray(items)) {
    return []
  }

  return items.map(item => ({
    ...item,
    observacoes: item.observacoes ? sanitizeFreeText(item.observacoes, 300) : undefined,
    nome: sanitizeInput(item.nome),
    descricao: item.descricao ? sanitizeInput(item.descricao) : undefined,
    // Adicionar categoria do produto para histórico e relatórios
    produto: {
      ...item.produto,
      categoria: item.produto?.categoria || item.produto?.categoria_nome || 'Sem categoria',
      categoria_nome: item.produto?.categoria_nome || item.produto?.categoria || 'Sem categoria'
    },
    // Sanitizar sabores se existirem
    saboresSelecionados: item.saboresSelecionados?.map((sabor: any) => ({
      ...sabor,
      nome: sanitizeInput(sabor.nome),
      observacoes: sabor.observacoes ? sanitizeFreeText(sabor.observacoes, 300) : undefined
    })),
    sabores: item.sabores?.map((sabor: any) => ({
      ...sabor,
      nome: sanitizeInput(sabor.nome),
      observacoes: sabor.observacoes ? sanitizeFreeText(sabor.observacoes, 300) : undefined
    })),
    // Sanitizar adicionais se existirem
    adicionaisSelecionados: item.adicionaisSelecionados?.map((adicional: any) => ({
      ...adicional,
      nome: sanitizeInput(adicional.nome)
    })),
    adicionais: item.adicionais?.map((adicional: any) => ({
      ...adicional,
      nome: sanitizeInput(adicional.nome)
    }))
  }))
}

/**
 * Valida e sanitiza número de telefone
 * Remove caracteres especiais mas mantém números
 *
 * @param phone - Número de telefone
 * @returns Telefone sanitizado (apenas números)
 */
export function sanitizePhone(phone: string | null | undefined): string {
  if (!phone || typeof phone !== 'string') {
    return ''
  }

  // Primeiro sanitiza para remover código malicioso
  const sanitized = sanitizeInput(phone)

  // Depois remove tudo exceto números
  return sanitized.replace(/\D/g, '')
}

/**
 * Valida e sanitiza CPF
 * Remove caracteres especiais mas mantém números
 *
 * @param cpf - CPF
 * @returns CPF sanitizado (apenas números)
 */
export function sanitizeCPF(cpf: string | null | undefined): string {
  if (!cpf || typeof cpf !== 'string') {
    return ''
  }

  // Primeiro sanitiza para remover código malicioso
  const sanitized = sanitizeInput(cpf)

  // Depois remove tudo exceto números
  return sanitized.replace(/\D/g, '')
}

/**
 * Valida e sanitiza CEP
 * Remove caracteres especiais mas mantém números
 *
 * @param cep - CEP
 * @returns CEP sanitizado (apenas números)
 */
export function sanitizeCEP(cep: string | null | undefined): string {
  if (!cep || typeof cep !== 'string') {
    return ''
  }

  // Primeiro sanitiza para remover código malicioso
  const sanitized = sanitizeInput(cep)

  // Depois remove tudo exceto números
  return sanitized.replace(/\D/g, '')
}

/**
 * Sanitiza email básico (remove HTML mas mantém estrutura de email)
 *
 * @param email - Email
 * @returns Email sanitizado
 */
export function sanitizeEmail(email: string | null | undefined): string {
  if (!email || typeof email !== 'string') {
    return ''
  }

  // Sanitiza removendo HTML/scripts
  const sanitized = sanitizeInput(email)

  // Remove espaços em branco
  return sanitized.toLowerCase().trim()
}

/**
 * Escape HTML entities para prevenir XSS ao renderizar
 * Use esta função quando for exibir dados do usuário no HTML
 *
 * @param text - Texto a ser escapado
 * @returns Texto com entities escapadas
 *
 * @example
 * ```typescript
 * const userInput = '<script>alert("xss")</script>'
 * const safe = escapeHtml(userInput)
 * // Retorna: '&lt;script&gt;alert("xss")&lt;/script&gt;'
 * ```
 */
export function escapeHtml(text: string): string {
  const div = document.createElement('div')
  div.textContent = text
  return div.innerHTML
}

/**
 * Remove espaços extras e normaliza espaços em branco
 *
 * @param text - Texto a ser normalizado
 * @returns Texto normalizado
 */
export function normalizeWhitespace(text: string | null | undefined): string {
  if (!text || typeof text !== 'string') {
    return ''
  }

  return text
    .replace(/\s+/g, ' ') // Substitui múltiplos espaços por um único
    .trim() // Remove espaços do início e fim
}

/**
 * Limita o tamanho de uma string para prevenir ataques de buffer
 *
 * @param text - Texto a ser limitado
 * @param maxLength - Tamanho máximo (padrão: 1000)
 * @returns Texto truncado se necessário
 */
export function limitStringLength(
  text: string | null | undefined,
  maxLength: number = 1000
): string {
  if (!text || typeof text !== 'string') {
    return ''
  }

  if (text.length <= maxLength) {
    return text
  }

  return text.substring(0, maxLength)
}

/**
 * Sanitização completa: remove HTML, normaliza espaços e limita tamanho
 * Use para campos de texto livre como observações
 *
 * @param text - Texto a ser sanitizado
 * @param maxLength - Tamanho máximo
 * @returns Texto completamente sanitizado
 */
export function sanitizeFreeText(
  text: string | null | undefined,
  maxLength: number = 500
): string {
  if (!text || typeof text !== 'string') {
    return ''
  }

  // 1. Remove HTML/JavaScript
  let clean = sanitizeInput(text)

  // 2. Normaliza espaços
  clean = normalizeWhitespace(clean)

  // 3. Limita tamanho
  clean = limitStringLength(clean, maxLength)

  return clean
}

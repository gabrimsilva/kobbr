/**
 * Constantes de Limites e Valores Máximos/Mínimos
 *
 * Centraliza todos os limites numéricos do sistema.
 *
 * @module constants/limits
 */

/**
 * Limites de texto e strings
 */
export const STRING_LIMITS = {
  /** Tamanho máximo de nome de produto/categoria */
  NOME_MAX: 100,

  /** Tamanho mínimo de nome */
  NOME_MIN: 2,

  /** Tamanho máximo de descrição */
  DESCRICAO_MAX: 500,

  /** Tamanho máximo de observação em pedido */
  OBSERVACAO_PEDIDO_MAX: 500,

  /** Tamanho máximo de observação em item */
  OBSERVACAO_ITEM_MAX: 200,

  /** Tamanho máximo de endereço */
  ENDERECO_MAX: 200,

  /** Tamanho máximo de complemento */
  COMPLEMENTO_MAX: 100
} as const

/**
 * Limites de valores monetários
 */
export const PRICE_LIMITS = {
  /** Preço mínimo de produto (R$ 0.01) */
  MIN: 0.01,

  /** Preço máximo de produto (R$ 9999.99) */
  MAX: 9999.99,

  /** Taxa de entrega mínima (R$ 0) */
  TAXA_ENTREGA_MIN: 0,

  /** Taxa de entrega máxima (R$ 100) */
  TAXA_ENTREGA_MAX: 100,

  /** Valor mínimo de pedido padrão (R$ 15) */
  PEDIDO_MIN_DEFAULT: 15,

  /** Valor máximo de pedido (R$ 99999.99) */
  PEDIDO_MAX: 99999.99
} as const

/**
 * Limites de quantidades
 */
export const QUANTITY_LIMITS = {
  /** Quantidade mínima de item no carrinho */
  MIN: 1,

  /** Quantidade máxima de item no carrinho */
  MAX: 99,

  /** Quantidade máxima de sabores em pizza */
  SABORES_MAX: 4,

  /** Quantidade máxima de produtos em combo */
  COMBO_PRODUTOS_MAX: 10,

  /** Quantidade máxima de adicionais por item */
  ADICIONAIS_MAX: 20
} as const

/**
 * Limites de arquivo/upload
 */
export const FILE_LIMITS = {
  /** Tamanho máximo de imagem (5MB) */
  IMAGE_MAX_SIZE: 5 * 1024 * 1024,

  /** Largura máxima de imagem (pixels) */
  IMAGE_MAX_WIDTH: 2048,

  /** Altura máxima de imagem (pixels) */
  IMAGE_MAX_HEIGHT: 2048,

  /** Formatos de imagem permitidos */
  IMAGE_FORMATS: ['image/jpeg', 'image/png', 'image/webp'] as const
} as const

/**
 * Limites de listagem/paginação
 */
export const PAGINATION_LIMITS = {
  /** Número de itens por página (padrão) */
  DEFAULT: 50,

  /** Número mínimo de itens por página */
  MIN: 10,

  /** Número máximo de itens por página */
  MAX: 100,

  /** Limite para busca de pedidos */
  PEDIDOS: 50,

  /** Limite para histórico */
  HISTORICO: 100
} as const

/**
 * Limites de distância (em km)
 */
export const DISTANCE_LIMITS = {
  /** Distância mínima para entrega (0 km) */
  MIN: 0,

  /** Distância máxima para entrega (50 km) */
  MAX: 50,

  /** Distância padrão para taxa fixa (5 km) */
  TAXA_FIXA_MAX: 5,

  /** Incremento de distância para cálculo de taxa (1 km) */
  INCREMENT: 1
} as const

/**
 * Limites de tempo (em minutos)
 */
export const TIME_LIMITS = {
  /** Tempo mínimo de preparo (10 min) */
  PREPARO_MIN: 10,

  /** Tempo máximo de preparo (120 min) */
  PREPARO_MAX: 120,

  /** Tempo mínimo de entrega (15 min) */
  ENTREGA_MIN: 15,

  /** Tempo máximo de entrega (180 min) */
  ENTREGA_MAX: 180,

  /** Tempo de retirada mínimo (10 min) */
  RETIRADA_MIN: 10,

  /** Tempo de retirada máximo (60 min) */
  RETIRADA_MAX: 60
} as const

/**
 * Limites de estoque
 */
export const STOCK_LIMITS = {
  /** Estoque mínimo (0) */
  MIN: 0,

  /** Estoque máximo (9999) */
  MAX: 9999,

  /** Nível de alerta de estoque baixo (10 unidades) */
  LOW_STOCK_THRESHOLD: 10,

  /** Nível crítico de estoque (5 unidades) */
  CRITICAL_STOCK_THRESHOLD: 5
} as const

/**
 * Limites de desconto
 */
export const DISCOUNT_LIMITS = {
  /** Desconto mínimo (0%) */
  MIN_PERCENT: 0,

  /** Desconto máximo (100%) */
  MAX_PERCENT: 100,

  /** Desconto típico em combo (10%) */
  COMBO_DEFAULT: 10
} as const

/**
 * Limites de telefone e contato
 */
export const CONTACT_LIMITS = {
  /** Tamanho do DDD */
  DDD_LENGTH: 2,

  /** Tamanho mínimo de telefone (10 dígitos) */
  TELEFONE_MIN: 10,

  /** Tamanho máximo de telefone (11 dígitos) */
  TELEFONE_MAX: 11,

  /** Tamanho do CPF */
  CPF_LENGTH: 11,

  /** Tamanho do CEP */
  CEP_LENGTH: 8
} as const

/**
 * Valores padrão
 */
export const DEFAULTS = {
  /** Taxa de entrega padrão quando não configurada */
  TAXA_ENTREGA: 5.00,

  /** Valor mínimo de pedido quando não configurado */
  VALOR_MINIMO: 15.00,

  /** Tempo de preparo padrão (minutos) */
  TEMPO_PREPARO: 45,

  /** Tempo de retirada padrão (minutos) */
  TEMPO_RETIRADA: 20,

  /** Quantidade inicial de sabores em pizza */
  QUANTIDADE_SABORES: 2,

  /** Porcentagem de desconto padrão em combo */
  DESCONTO_COMBO: 10
} as const

/**
 * Exportar tudo como namespace default
 */
export default {
  STRING_LIMITS,
  PRICE_LIMITS,
  QUANTITY_LIMITS,
  FILE_LIMITS,
  PAGINATION_LIMITS,
  DISTANCE_LIMITS,
  TIME_LIMITS,
  STOCK_LIMITS,
  DISCOUNT_LIMITS,
  CONTACT_LIMITS,
  DEFAULTS
}

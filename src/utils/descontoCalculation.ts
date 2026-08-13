/**
 * Funções de cálculo de desconto para pedidos do PDV e Comandas
 * 
 * Este módulo implementa a lógica de cálculo de descontos manuais,
 * suportando descontos em valor absoluto (R$) e percentual (%).
 * 
 * @module descontoCalculation
 */

import type { DescontoInput, ResumoValores } from '@/types/supabase'

/**
 * Calcula o valor do desconto em reais
 * 
 * Converte o desconto informado (que pode ser em R$ ou %) para um valor
 * absoluto em reais, baseado no subtotal do pedido.
 * 
 * @param desconto - Valor do desconto (R$ ou %)
 * @param tipo - Tipo do desconto ('valor' ou 'percentual')
 * @param subtotal - Subtotal do pedido antes do desconto
 * @returns Valor do desconto em reais com precisão de 2 casas decimais
 * 
 * @example
 * // Desconto em valor
 * calcularDescontoEmReais(10, 'valor', 100) // retorna 10.00
 * 
 * @example
 * // Desconto percentual
 * calcularDescontoEmReais(15, 'percentual', 100) // retorna 15.00
 */
export function calcularDescontoEmReais(
  desconto: number,
  tipo: 'valor' | 'percentual',
  subtotal: number
): number {
  if (tipo === 'valor') {
    // Desconto em valor: retorna o valor diretamente
    return Number(desconto.toFixed(2))
  } else {
    // Desconto percentual: calcula (subtotal × percentual ÷ 100)
    const descontoCalculado = (subtotal * desconto) / 100
    return Number(descontoCalculado.toFixed(2))
  }
}

/**
 * Calcula o resumo completo de valores do pedido com desconto
 * 
 * Aplica o desconto ao subtotal e adiciona as taxas para calcular o total final.
 * A ordem de aplicação é: subtotal → desconto → taxas → total
 * 
 * Fórmula: total = (subtotal - desconto_calculado) + taxa_entrega + taxa_extra_km
 * 
 * @param subtotal - Subtotal do pedido (soma dos itens)
 * @param desconto - Objeto com valor e tipo do desconto
 * @param taxa_entrega - Taxa de entrega (padrão: 0)
 * @param taxa_extra_km - Taxa extra por km (padrão: 0)
 * @returns Objeto ResumoValores com todos os valores calculados
 * 
 * @example
 * // Pedido com desconto em valor
 * calcularResumoValores(100, { valor: 10, tipo: 'valor' }, 5, 2)
 * // retorna: {
 * //   subtotal: 100.00,
 * //   desconto: 10,
 * //   tipo_desconto: 'valor',
 * //   desconto_calculado: 10.00,
 * //   subtotal_com_desconto: 90.00,
 * //   taxa_entrega: 5.00,
 * //   taxa_extra_km: 2.00,
 * //   total: 97.00
 * // }
 * 
 * @example
 * // Pedido com desconto percentual
 * calcularResumoValores(100, { valor: 15, tipo: 'percentual' }, 5, 0)
 * // retorna: {
 * //   subtotal: 100.00,
 * //   desconto: 15,
 * //   tipo_desconto: 'percentual',
 * //   desconto_calculado: 15.00,
 * //   subtotal_com_desconto: 85.00,
 * //   taxa_entrega: 5.00,
 * //   taxa_extra_km: 0.00,
 * //   total: 90.00
 * // }
 */
export function calcularResumoValores(
  subtotal: number,
  desconto: DescontoInput,
  taxa_entrega: number = 0,
  taxa_extra_km: number = 0
): ResumoValores {
  // Calcula o desconto em reais
  const desconto_calculado = calcularDescontoEmReais(
    desconto.valor,
    desconto.tipo,
    subtotal
  )
  
  // Aplica o desconto ao subtotal
  const subtotal_com_desconto = subtotal - desconto_calculado
  
  // Calcula o total final: (subtotal - desconto) + taxas
  const total = subtotal_com_desconto + taxa_entrega + taxa_extra_km

  // Retorna todos os valores com precisão de 2 casas decimais
  return {
    subtotal: Number(subtotal.toFixed(2)),
    desconto: desconto.valor,
    tipo_desconto: desconto.tipo,
    desconto_calculado: Number(desconto_calculado.toFixed(2)),
    subtotal_com_desconto: Number(subtotal_com_desconto.toFixed(2)),
    taxa_entrega: Number(taxa_entrega.toFixed(2)),
    taxa_extra_km: Number(taxa_extra_km.toFixed(2)),
    total: Number(total.toFixed(2))
  }
}

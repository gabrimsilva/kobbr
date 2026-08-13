/**
 * Testes para cálculo de desconto
 * Feature: desconto-manual-pdv-comandas
 */

import { describe, it, expect } from 'vitest'
import { calcularDescontoEmReais, calcularResumoValores } from './descontoCalculation'
import type { DescontoInput } from '@/types/supabase'

describe('Cálculo de Desconto', () => {
  describe('calcularDescontoEmReais', () => {
    describe('Desconto em Valor', () => {
      it('deve retornar o valor do desconto diretamente', () => {
        const resultado = calcularDescontoEmReais(10, 'valor', 100)
        
        expect(resultado).toBe(10.00)
      })

      it('deve manter precisão de 2 casas decimais', () => {
        const resultado = calcularDescontoEmReais(10.567, 'valor', 100)
        
        expect(resultado).toBe(10.57)
      })

      it('deve retornar zero para desconto zero', () => {
        const resultado = calcularDescontoEmReais(0, 'valor', 100)
        
        expect(resultado).toBe(0)
      })
    })

    describe('Desconto Percentual', () => {
      it('deve calcular desconto percentual corretamente', () => {
        const resultado = calcularDescontoEmReais(10, 'percentual', 100)
        
        expect(resultado).toBe(10.00)
      })

      it('deve calcular 50% de desconto', () => {
        const resultado = calcularDescontoEmReais(50, 'percentual', 100)
        
        expect(resultado).toBe(50.00)
      })

      it('deve calcular 15% de desconto', () => {
        const resultado = calcularDescontoEmReais(15, 'percentual', 100)
        
        expect(resultado).toBe(15.00)
      })

      it('deve calcular desconto percentual com subtotal decimal', () => {
        const resultado = calcularDescontoEmReais(20, 'percentual', 75.50)
        
        expect(resultado).toBe(15.10)
      })

      it('deve manter precisão de 2 casas decimais', () => {
        const resultado = calcularDescontoEmReais(33.33, 'percentual', 100)
        
        expect(resultado).toBe(33.33)
      })

      it('deve retornar zero para desconto percentual zero', () => {
        const resultado = calcularDescontoEmReais(0, 'percentual', 100)
        
        expect(resultado).toBe(0)
      })
    })
  })

  describe('calcularResumoValores', () => {
    describe('Desconto em Valor', () => {
      it('deve calcular resumo com desconto R$ 10 em subtotal R$ 100', () => {
        const desconto: DescontoInput = { valor: 10, tipo: 'valor' }
        const resultado = calcularResumoValores(100, desconto, 0, 0)
        
        expect(resultado.subtotal).toBe(100.00)
        expect(resultado.desconto).toBe(10)
        expect(resultado.tipo_desconto).toBe('valor')
        expect(resultado.desconto_calculado).toBe(10.00)
        expect(resultado.subtotal_com_desconto).toBe(90.00)
        expect(resultado.total).toBe(90.00)
      })

      it('deve aplicar desconto antes das taxas', () => {
        const desconto: DescontoInput = { valor: 10, tipo: 'valor' }
        const resultado = calcularResumoValores(100, desconto, 5, 2)
        
        expect(resultado.subtotal).toBe(100.00)
        expect(resultado.desconto_calculado).toBe(10.00)
        expect(resultado.subtotal_com_desconto).toBe(90.00)
        expect(resultado.taxa_entrega).toBe(5.00)
        expect(resultado.taxa_extra_km).toBe(2.00)
        expect(resultado.total).toBe(97.00) // (100 - 10) + 5 + 2
      })
    })

    describe('Desconto Percentual', () => {
      it('deve calcular resumo com desconto 10% em subtotal R$ 100', () => {
        const desconto: DescontoInput = { valor: 10, tipo: 'percentual' }
        const resultado = calcularResumoValores(100, desconto, 0, 0)
        
        expect(resultado.subtotal).toBe(100.00)
        expect(resultado.desconto).toBe(10)
        expect(resultado.tipo_desconto).toBe('percentual')
        expect(resultado.desconto_calculado).toBe(10.00)
        expect(resultado.subtotal_com_desconto).toBe(90.00)
        expect(resultado.total).toBe(90.00)
      })

      it('deve calcular resumo com desconto 15% e taxas', () => {
        const desconto: DescontoInput = { valor: 15, tipo: 'percentual' }
        const resultado = calcularResumoValores(100, desconto, 5, 0)
        
        expect(resultado.subtotal).toBe(100.00)
        expect(resultado.desconto_calculado).toBe(15.00)
        expect(resultado.subtotal_com_desconto).toBe(85.00)
        expect(resultado.taxa_entrega).toBe(5.00)
        expect(resultado.total).toBe(90.00) // (100 - 15) + 5
      })
    })

    describe('Desconto Zero', () => {
      it('não deve afetar o total quando desconto é zero', () => {
        const desconto: DescontoInput = { valor: 0, tipo: 'valor' }
        const resultado = calcularResumoValores(100, desconto, 5, 2)
        
        expect(resultado.subtotal).toBe(100.00)
        expect(resultado.desconto_calculado).toBe(0)
        expect(resultado.subtotal_com_desconto).toBe(100.00)
        expect(resultado.total).toBe(107.00) // 100 + 5 + 2
      })
    })

    describe('Precisão Decimal', () => {
      it('deve manter precisão de 2 casas decimais em todos os valores', () => {
        const desconto: DescontoInput = { valor: 33.33, tipo: 'percentual' }
        const resultado = calcularResumoValores(99.99, desconto, 7.77, 3.33)
        
        // Verificar que todos os valores têm exatamente 2 casas decimais
        expect(resultado.subtotal.toFixed(2)).toBe('99.99')
        expect(resultado.desconto_calculado.toFixed(2)).toBe('33.33')
        expect(resultado.subtotal_com_desconto.toFixed(2)).toBe('66.66')
        expect(resultado.taxa_entrega.toFixed(2)).toBe('7.77')
        expect(resultado.taxa_extra_km.toFixed(2)).toBe('3.33')
        expect(resultado.total.toFixed(2)).toBe('77.76')
      })
    })

    describe('Fórmula Completa', () => {
      it('deve seguir a fórmula: total = (subtotal - desconto) + taxa_entrega + taxa_extra_km', () => {
        const desconto: DescontoInput = { valor: 25, tipo: 'valor' }
        const resultado = calcularResumoValores(150, desconto, 10, 5)
        
        const totalEsperado = (150 - 25) + 10 + 5
        expect(resultado.total).toBe(totalEsperado)
        expect(resultado.total).toBe(140.00)
      })

      it('deve calcular corretamente com desconto percentual e taxas', () => {
        const desconto: DescontoInput = { valor: 20, tipo: 'percentual' }
        const resultado = calcularResumoValores(200, desconto, 15, 8)
        
        const descontoCalculado = (200 * 20) / 100 // 40
        const totalEsperado = (200 - descontoCalculado) + 15 + 8 // 183
        expect(resultado.total).toBe(totalEsperado)
        expect(resultado.total).toBe(183.00)
      })
    })

    describe('Valores Padrão', () => {
      it('deve usar taxas padrão zero quando não informadas', () => {
        const desconto: DescontoInput = { valor: 10, tipo: 'valor' }
        const resultado = calcularResumoValores(100, desconto)
        
        expect(resultado.taxa_entrega).toBe(0)
        expect(resultado.taxa_extra_km).toBe(0)
        expect(resultado.total).toBe(90.00)
      })
    })
  })
})

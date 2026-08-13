/**
 * Testes para validação de desconto
 * Feature: desconto-manual-pdv-comandas
 */

import { describe, it, expect } from 'vitest'
import { validarDesconto } from './descontoValidation'

describe('Validação de Desconto', () => {
  describe('Descontos Negativos', () => {
    it('deve rejeitar desconto negativo em valor', () => {
      const resultado = validarDesconto(-10, 'valor', 100)
      
      expect(resultado.valido).toBe(false)
      expect(resultado.erro).toBe('O desconto não pode ser negativo')
    })

    it('deve rejeitar desconto negativo percentual', () => {
      const resultado = validarDesconto(-5, 'percentual', 100)
      
      expect(resultado.valido).toBe(false)
      expect(resultado.erro).toBe('O desconto não pode ser negativo')
    })
  })

  describe('Desconto em Valor', () => {
    it('deve aceitar desconto válido menor que subtotal', () => {
      const resultado = validarDesconto(10, 'valor', 50)
      
      expect(resultado.valido).toBe(true)
      expect(resultado.erro).toBeUndefined()
    })

    it('deve aceitar desconto igual ao subtotal', () => {
      const resultado = validarDesconto(50, 'valor', 50)
      
      expect(resultado.valido).toBe(true)
      expect(resultado.erro).toBeUndefined()
    })

    it('deve rejeitar desconto maior que subtotal', () => {
      const resultado = validarDesconto(100, 'valor', 50)
      
      expect(resultado.valido).toBe(false)
      expect(resultado.erro).toBe('O desconto não pode ser maior que o subtotal (R$ 50.00)')
    })

    it('deve aceitar desconto zero', () => {
      const resultado = validarDesconto(0, 'valor', 100)
      
      expect(resultado.valido).toBe(true)
      expect(resultado.erro).toBeUndefined()
    })
  })

  describe('Desconto Percentual', () => {
    it('deve aceitar desconto percentual válido', () => {
      const resultado = validarDesconto(50, 'percentual', 100)
      
      expect(resultado.valido).toBe(true)
      expect(resultado.erro).toBeUndefined()
    })

    it('deve aceitar desconto percentual de 100%', () => {
      const resultado = validarDesconto(100, 'percentual', 100)
      
      expect(resultado.valido).toBe(true)
      expect(resultado.erro).toBeUndefined()
    })

    it('deve rejeitar desconto percentual acima de 100%', () => {
      const resultado = validarDesconto(101, 'percentual', 100)
      
      expect(resultado.valido).toBe(false)
      expect(resultado.erro).toBe('O desconto percentual não pode ser maior que 100%')
    })

    it('deve aceitar desconto percentual zero', () => {
      const resultado = validarDesconto(0, 'percentual', 100)
      
      expect(resultado.valido).toBe(true)
      expect(resultado.erro).toBeUndefined()
    })
  })

  describe('Mensagens de Erro', () => {
    it('deve incluir valor do subtotal na mensagem de erro quando desconto em valor é maior', () => {
      const resultado = validarDesconto(150, 'valor', 75.50)
      
      expect(resultado.valido).toBe(false)
      expect(resultado.erro).toContain('75.50')
      expect(resultado.erro).toContain('R$')
    })

    it('deve retornar mensagem de erro não-vazia para validação falha', () => {
      const resultado = validarDesconto(-1, 'valor', 100)
      
      expect(resultado.valido).toBe(false)
      expect(resultado.erro).toBeDefined()
      expect(resultado.erro!.length).toBeGreaterThan(0)
    })
  })
})

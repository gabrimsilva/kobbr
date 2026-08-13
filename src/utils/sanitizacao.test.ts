/**
 * Testes para módulo de sanitização
 */

import { describe, it, expect } from 'vitest'
import {
  sanitizeInput,
  sanitizeRichText,
  sanitizeObject,
  sanitizeCheckoutData,
  sanitizeCartItems,
  sanitizePhone,
  sanitizeCPF,
  sanitizeCEP,
  sanitizeEmail,
  escapeHtml,
  normalizeWhitespace,
  limitStringLength,
  sanitizeFreeText
} from './sanitizacao'

describe('Sanitização de Inputs', () => {
  describe('sanitizeInput', () => {
    it('deve remover tags HTML', () => {
      const input = '<script>alert("xss")</script>Olá'
      const result = sanitizeInput(input)
      expect(result).toBe('Olá')
    })

    it('deve remover tags de imagem com onerror', () => {
      const input = '<img src=x onerror="alert(\'xss\')">Texto'
      const result = sanitizeInput(input)
      expect(result).toBe('Texto')
    })

    it('deve remover eventos inline', () => {
      const input = '<div onclick="alert(\'xss\')">Clique</div>'
      const result = sanitizeInput(input)
      expect(result).toBe('Clique')
    })

    it('deve retornar string vazia para null', () => {
      expect(sanitizeInput(null)).toBe('')
    })

    it('deve retornar string vazia para undefined', () => {
      expect(sanitizeInput(undefined)).toBe('')
    })

    it('deve fazer trim de espaços', () => {
      expect(sanitizeInput('  teste  ')).toBe('teste')
    })
  })

  describe('sanitizeRichText', () => {
    it('deve permitir tags básicas de formatação', () => {
      const input = '<b>Negrito</b> e <i>itálico</i>'
      const result = sanitizeRichText(input)
      expect(result).toContain('<b>Negrito</b>')
      expect(result).toContain('<i>itálico</i>')
    })

    it('deve remover scripts mesmo com formatação', () => {
      const input = '<b>Importante</b><script>alert("xss")</script>'
      const result = sanitizeRichText(input)
      expect(result).toBe('<b>Importante</b>')
    })
  })

  describe('sanitizeObject', () => {
    it('deve sanitizar todas as strings de um objeto', () => {
      const obj = {
        nome: '<script>alert("xss")</script>João',
        idade: 25,
        observacao: 'Sem <b>cebola</b>'
      }
      const result = sanitizeObject(obj)
      expect(result.nome).toBe('João')
      expect(result.idade).toBe(25)
      expect(result.observacao).toBe('Sem cebola')
    })

    it('deve sanitizar objetos aninhados', () => {
      const obj = {
        cliente: {
          nome: '<script>xss</script>Maria'
        }
      }
      const result = sanitizeObject(obj)
      expect(result.cliente.nome).toBe('Maria')
    })

    it('deve sanitizar arrays de strings', () => {
      const obj = {
        items: ['<script>xss</script>Item 1', 'Item 2']
      }
      const result = sanitizeObject(obj)
      expect(result.items[0]).toBe('Item 1')
      expect(result.items[1]).toBe('Item 2')
    })
  })

  describe('sanitizeCheckoutData', () => {
    it('deve sanitizar todos os campos do checkout', () => {
      const data = {
        cliente_nome: '<script>xss</script>João',
        cliente_sobrenome: 'Silva<b>',
        cliente_telefone: '11999999999',
        cliente_email: 'joao@test.com<script>',
        cliente_endereco: 'Rua <b>Principal</b>',
        observacoes: 'Sem <script>alert("xss")</script> cebola'
      }

      const result = sanitizeCheckoutData(data)

      expect(result.cliente_nome).toBe('João')
      expect(result.cliente_sobrenome).toBe('Silva')
      expect(result.cliente_email).toBe('joao@test.com')
      expect(result.cliente_endereco).toBe('Rua Principal')
      expect(result.observacoes).toBe('Sem  cebola')
    })
  })

  describe('sanitizeCartItems', () => {
    it('deve sanitizar observações dos itens', () => {
      const items = [
        {
          nome: 'Pizza<script>',
          observacoes: 'Sem <b>cebola</b>',
          sabores: [
            { nome: 'Calabresa<script>', observacoes: 'Extra <b>queijo</b>' }
          ]
        }
      ]

      const result = sanitizeCartItems(items)

      expect(result[0].nome).toBe('Pizza')
      expect(result[0].observacoes).toBe('Sem cebola')
      expect(result[0].sabores[0].nome).toBe('Calabresa')
      expect(result[0].sabores[0].observacoes).toBe('Extra queijo')
    })
  })

  describe('sanitizePhone', () => {
    it('deve manter apenas números', () => {
      expect(sanitizePhone('(11) 99999-9999')).toBe('11999999999')
    })

    it('deve remover scripts', () => {
      expect(sanitizePhone('<script>alert("xss")</script>11999999999')).toBe('11999999999')
    })

    it('deve retornar string vazia para null', () => {
      expect(sanitizePhone(null)).toBe('')
    })
  })

  describe('sanitizeCPF', () => {
    it('deve manter apenas números', () => {
      expect(sanitizeCPF('123.456.789-00')).toBe('12345678900')
    })

    it('deve remover scripts', () => {
      expect(sanitizeCPF('<script>xss</script>12345678900')).toBe('12345678900')
    })
  })

  describe('sanitizeCEP', () => {
    it('deve manter apenas números', () => {
      expect(sanitizeCEP('12345-678')).toBe('12345678')
    })
  })

  describe('sanitizeEmail', () => {
    it('deve normalizar email', () => {
      expect(sanitizeEmail('  TESTE@EMAIL.COM  ')).toBe('teste@email.com')
    })

    it('deve remover scripts', () => {
      expect(sanitizeEmail('test@email.com<script>xss</script>')).toBe('test@email.com')
    })
  })

  describe('escapeHtml', () => {
    it('deve escapar entidades HTML', () => {
      const result = escapeHtml('<script>alert("xss")</script>')
      expect(result).toContain('&lt;')
      expect(result).toContain('&gt;')
    })
  })

  describe('normalizeWhitespace', () => {
    it('deve remover múltiplos espaços', () => {
      expect(normalizeWhitespace('João    Silva')).toBe('João Silva')
    })

    it('deve fazer trim', () => {
      expect(normalizeWhitespace('  teste  ')).toBe('teste')
    })
  })

  describe('limitStringLength', () => {
    it('deve truncar string longa', () => {
      const long = 'a'.repeat(2000)
      const result = limitStringLength(long, 100)
      expect(result.length).toBe(100)
    })

    it('deve manter string curta', () => {
      const short = 'teste'
      const result = limitStringLength(short, 100)
      expect(result).toBe('teste')
    })
  })

  describe('sanitizeFreeText', () => {
    it('deve aplicar todas as sanitizações', () => {
      const input = '  <script>xss</script>Texto   com   espaços  ' + 'a'.repeat(1000)
      const result = sanitizeFreeText(input, 50)

      expect(result).not.toContain('<script>')
      expect(result.length).toBeLessThanOrEqual(50)
      expect(result.startsWith(' ')).toBe(false)
      expect(result.endsWith(' ')).toBe(false)
    })
  })
})

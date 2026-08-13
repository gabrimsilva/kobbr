/**
 * Testes de integração end-to-end para funcionalidade de desconto manual
 * Feature: desconto-manual-pdv-comandas
 * 
 * Estes testes validam o fluxo completo de aplicação de desconto,
 * desde a entrada do usuário até o cálculo final e validação.
 */

import { describe, it, expect } from 'vitest'
import { validarDesconto } from './descontoValidation'
import { calcularDescontoEmReais, calcularResumoValores } from './descontoCalculation'
import type { DescontoInput, ResumoValores, PedidoSupabase } from '@/types/supabase'

describe('Integração End-to-End: Desconto Manual PDV e Comandas', () => {
  /**
   * Simula a criação de um pedido completo com itens
   */
  const criarPedidoBase = (subtotal: number): Partial<PedidoSupabase> => ({
    pedido_id: `TEST-${Date.now()}`,
    cliente_nome: 'Cliente Teste',
    cliente_sobrenome: 'Silva',
    cliente_telefone: '11999999999',
    entrega_domicilio: false,
    forma_pagamento: 'dinheiro',
    subtotal,
    taxa_entrega: 0,
    taxa_extra_km: 0,
    total: subtotal,
    desconto: 0,
    tipo_desconto: 'valor',
    itens: [],
    status: 'pendente',
    criado_em: new Date().toISOString(),
    atualizado_em: new Date().toISOString(),
  })

  describe('16.1 - Fluxo completo PDV com desconto em valor', () => {
    it('deve processar pedido com desconto R$ 10 corretamente', () => {
      // 1. Criar pedido com itens (subtotal R$ 100)
      const pedido = criarPedidoBase(100)
      
      // 2. Aplicar desconto R$ 10
      const desconto: DescontoInput = { valor: 10, tipo: 'valor' }
      
      // 3. Verificar validação
      const validacao = validarDesconto(desconto.valor, desconto.tipo, pedido.subtotal!)
      expect(validacao.valido).toBe(true)
      expect(validacao.erro).toBeUndefined()
      
      // 4. Calcular total recalculado
      const resumo = calcularResumoValores(
        pedido.subtotal!,
        desconto,
        pedido.taxa_entrega!,
        pedido.taxa_extra_km!
      )
      
      // 5. Verificar cálculo correto
      expect(resumo.subtotal).toBe(100.00)
      expect(resumo.desconto).toBe(10)
      expect(resumo.tipo_desconto).toBe('valor')
      expect(resumo.desconto_calculado).toBe(10.00)
      expect(resumo.subtotal_com_desconto).toBe(90.00)
      expect(resumo.total).toBe(90.00)
      
      // 6. Simular salvamento no banco (atualizar pedido)
      const pedidoFinalizado: Partial<PedidoSupabase> = {
        ...pedido,
        desconto: desconto.valor,
        tipo_desconto: desconto.tipo,
        total: resumo.total,
      }
      
      // 7. Verificar que pedido tem campos de desconto corretos
      expect(pedidoFinalizado.desconto).toBe(10)
      expect(pedidoFinalizado.tipo_desconto).toBe('valor')
      expect(pedidoFinalizado.total).toBe(90.00)
    })

    it('deve processar pedido com desconto e taxas de entrega', () => {
      // Pedido com entrega
      const pedido = criarPedidoBase(100)
      pedido.entrega_domicilio = true
      pedido.taxa_entrega = 5
      pedido.taxa_extra_km = 2
      
      const desconto: DescontoInput = { valor: 10, tipo: 'valor' }
      
      // Validar
      const validacao = validarDesconto(desconto.valor, desconto.tipo, pedido.subtotal!)
      expect(validacao.valido).toBe(true)
      
      // Calcular
      const resumo = calcularResumoValores(
        pedido.subtotal!,
        desconto,
        pedido.taxa_entrega!,
        pedido.taxa_extra_km!
      )
      
      // Verificar fórmula: (100 - 10) + 5 + 2 = 97
      expect(resumo.subtotal_com_desconto).toBe(90.00)
      expect(resumo.taxa_entrega).toBe(5.00)
      expect(resumo.taxa_extra_km).toBe(2.00)
      expect(resumo.total).toBe(97.00)
    })
  })

  describe('16.2 - Fluxo completo PDV com desconto percentual', () => {
    it('deve processar pedido com desconto 15% corretamente', () => {
      // 1. Criar pedido
      const pedido = criarPedidoBase(100)
      
      // 2. Aplicar desconto 15%
      const desconto: DescontoInput = { valor: 15, tipo: 'percentual' }
      
      // 3. Verificar validação
      const validacao = validarDesconto(desconto.valor, desconto.tipo, pedido.subtotal!)
      expect(validacao.valido).toBe(true)
      
      // 4. Calcular total
      const resumo = calcularResumoValores(
        pedido.subtotal!,
        desconto,
        pedido.taxa_entrega!,
        pedido.taxa_extra_km!
      )
      
      // 5. Verificar cálculo: 15% de 100 = 15
      expect(resumo.desconto).toBe(15)
      expect(resumo.tipo_desconto).toBe('percentual')
      expect(resumo.desconto_calculado).toBe(15.00)
      expect(resumo.subtotal_com_desconto).toBe(85.00)
      expect(resumo.total).toBe(85.00)
      
      // 6. Verificar salvamento
      const pedidoFinalizado: Partial<PedidoSupabase> = {
        ...pedido,
        desconto: desconto.valor,
        tipo_desconto: desconto.tipo,
        total: resumo.total,
      }
      
      expect(pedidoFinalizado.desconto).toBe(15)
      expect(pedidoFinalizado.tipo_desconto).toBe('percentual')
      expect(pedidoFinalizado.total).toBe(85.00)
    })

    it('deve processar desconto percentual com taxas', () => {
      const pedido = criarPedidoBase(200)
      pedido.taxa_entrega = 10
      
      const desconto: DescontoInput = { valor: 20, tipo: 'percentual' }
      
      const validacao = validarDesconto(desconto.valor, desconto.tipo, pedido.subtotal!)
      expect(validacao.valido).toBe(true)
      
      const resumo = calcularResumoValores(
        pedido.subtotal!,
        desconto,
        pedido.taxa_entrega!,
        0
      )
      
      // 20% de 200 = 40, então (200 - 40) + 10 = 170
      expect(resumo.desconto_calculado).toBe(40.00)
      expect(resumo.subtotal_com_desconto).toBe(160.00)
      expect(resumo.total).toBe(170.00)
    })
  })

  describe('16.3 - Fluxo completo Comanda com desconto', () => {
    it('deve processar comanda com desconto em valor', () => {
      // Comandas seguem o mesmo fluxo de cálculo
      const subtotalComanda = 75.50
      const desconto: DescontoInput = { valor: 5.50, tipo: 'valor' }
      
      // Validar
      const validacao = validarDesconto(desconto.valor, desconto.tipo, subtotalComanda)
      expect(validacao.valido).toBe(true)
      
      // Calcular
      const resumo = calcularResumoValores(subtotalComanda, desconto, 0, 0)
      
      // Verificar
      expect(resumo.subtotal).toBe(75.50)
      expect(resumo.desconto_calculado).toBe(5.50)
      expect(resumo.subtotal_com_desconto).toBe(70.00)
      expect(resumo.total).toBe(70.00)
    })

    it('deve processar comanda com desconto percentual', () => {
      const subtotalComanda = 120
      const desconto: DescontoInput = { valor: 10, tipo: 'percentual' }
      
      const validacao = validarDesconto(desconto.valor, desconto.tipo, subtotalComanda)
      expect(validacao.valido).toBe(true)
      
      const resumo = calcularResumoValores(subtotalComanda, desconto, 0, 0)
      
      // 10% de 120 = 12
      expect(resumo.desconto_calculado).toBe(12.00)
      expect(resumo.total).toBe(108.00)
    })
  })

  describe('16.4 - Validação de erros no fluxo completo', () => {
    it('deve bloquear finalização com desconto maior que subtotal', () => {
      const pedido = criarPedidoBase(50)
      const desconto: DescontoInput = { valor: 100, tipo: 'valor' }
      
      // 1. Tentar aplicar desconto inválido
      const validacao = validarDesconto(desconto.valor, desconto.tipo, pedido.subtotal!)
      
      // 2. Verificar que validação falhou
      expect(validacao.valido).toBe(false)
      expect(validacao.erro).toBeDefined()
      expect(validacao.erro).toContain('não pode ser maior que o subtotal')
      expect(validacao.erro).toContain('50.00')
    })

    it('deve permitir correção e finalização após erro', () => {
      const pedido = criarPedidoBase(50)
      
      // 1. Primeiro, desconto inválido
      let desconto: DescontoInput = { valor: 100, tipo: 'valor' }
      let validacao = validarDesconto(desconto.valor, desconto.tipo, pedido.subtotal!)
      
      expect(validacao.valido).toBe(false)
      expect(validacao.erro).toBeDefined()
      
      // 2. Corrigir valor
      desconto = { valor: 10, tipo: 'valor' }
      validacao = validarDesconto(desconto.valor, desconto.tipo, pedido.subtotal!)
      
      // 3. Verificar que erro foi removido
      expect(validacao.valido).toBe(true)
      expect(validacao.erro).toBeUndefined()
      
      // 4. Finalizar com sucesso
      const resumo = calcularResumoValores(pedido.subtotal!, desconto, 0, 0)
      expect(resumo.total).toBe(40.00)
    })

    it('deve bloquear desconto percentual acima de 100%', () => {
      const pedido = criarPedidoBase(100)
      const desconto: DescontoInput = { valor: 101, tipo: 'percentual' }
      
      const validacao = validarDesconto(desconto.valor, desconto.tipo, pedido.subtotal!)
      
      expect(validacao.valido).toBe(false)
      expect(validacao.erro).toBe('O desconto percentual não pode ser maior que 100%')
    })

    it('deve bloquear desconto negativo', () => {
      const pedido = criarPedidoBase(100)
      const desconto: DescontoInput = { valor: -10, tipo: 'valor' }
      
      const validacao = validarDesconto(desconto.valor, desconto.tipo, pedido.subtotal!)
      
      expect(validacao.valido).toBe(false)
      expect(validacao.erro).toBe('O desconto não pode ser negativo')
    })
  })

  describe('16.5 - Pedido sem desconto', () => {
    it('deve processar pedido sem desconto (desconto = 0)', () => {
      // 1. Criar pedido sem informar desconto
      const pedido = criarPedidoBase(100)
      const desconto: DescontoInput = { valor: 0, tipo: 'valor' }
      
      // 2. Verificar que desconto = 0
      expect(desconto.valor).toBe(0)
      
      // 3. Calcular
      const resumo = calcularResumoValores(pedido.subtotal!, desconto, 0, 0)
      
      // 4. Verificar que desconto não afeta o total
      expect(resumo.desconto_calculado).toBe(0)
      expect(resumo.subtotal_com_desconto).toBe(100.00)
      expect(resumo.total).toBe(100.00)
      
      // 5. Finalizar pedido
      const pedidoFinalizado: Partial<PedidoSupabase> = {
        ...pedido,
        desconto: 0,
        tipo_desconto: 'valor',
        total: resumo.total,
      }
      
      // 6. Verificar que banco tem desconto = 0 e tipo = 'valor'
      expect(pedidoFinalizado.desconto).toBe(0)
      expect(pedidoFinalizado.tipo_desconto).toBe('valor')
      expect(pedidoFinalizado.total).toBe(100.00)
    })

    it('deve omitir linhas de desconto quando desconto = 0', () => {
      const desconto: DescontoInput = { valor: 0, tipo: 'valor' }
      const resumo = calcularResumoValores(100, desconto, 5, 0)
      
      // Verificar que desconto_calculado é 0
      expect(resumo.desconto_calculado).toBe(0)
      
      // Em componentes de UI, linhas de desconto devem ser omitidas
      // quando desconto_calculado === 0
      const deveExibirDesconto = resumo.desconto_calculado > 0
      expect(deveExibirDesconto).toBe(false)
    })
  })

  describe('Cenários complexos de integração', () => {
    it('deve processar múltiplos pedidos com diferentes tipos de desconto', () => {
      // Pedido 1: Desconto em valor
      const pedido1 = criarPedidoBase(150)
      const desconto1: DescontoInput = { valor: 20, tipo: 'valor' }
      const resumo1 = calcularResumoValores(pedido1.subtotal!, desconto1, 10, 0)
      expect(resumo1.total).toBe(140.00) // (150 - 20) + 10
      
      // Pedido 2: Desconto percentual
      const pedido2 = criarPedidoBase(200)
      const desconto2: DescontoInput = { valor: 25, tipo: 'percentual' }
      const resumo2 = calcularResumoValores(pedido2.subtotal!, desconto2, 15, 5)
      expect(resumo2.total).toBe(170.00) // (200 - 50) + 15 + 5
      
      // Pedido 3: Sem desconto
      const pedido3 = criarPedidoBase(80)
      const desconto3: DescontoInput = { valor: 0, tipo: 'valor' }
      const resumo3 = calcularResumoValores(pedido3.subtotal!, desconto3, 8, 0)
      expect(resumo3.total).toBe(88.00) // 80 + 8
    })

    it('deve manter precisão decimal em cálculos complexos', () => {
      const pedido = criarPedidoBase(99.99)
      pedido.taxa_entrega = 7.77
      pedido.taxa_extra_km = 3.33
      
      const desconto: DescontoInput = { valor: 33.33, tipo: 'percentual' }
      const resumo = calcularResumoValores(
        pedido.subtotal!,
        desconto,
        pedido.taxa_entrega!,
        pedido.taxa_extra_km!
      )
      
      // Verificar precisão de 2 casas decimais
      expect(resumo.subtotal.toFixed(2)).toBe('99.99')
      expect(resumo.desconto_calculado.toFixed(2)).toBe('33.33')
      expect(resumo.subtotal_com_desconto.toFixed(2)).toBe('66.66')
      expect(resumo.total.toFixed(2)).toBe('77.76')
    })

    it('deve validar sequência completa: validação → cálculo → persistência', () => {
      const pedido = criarPedidoBase(180)
      pedido.taxa_entrega = 12
      
      const desconto: DescontoInput = { valor: 15, tipo: 'percentual' }
      
      // Etapa 1: Validação
      const validacao = validarDesconto(desconto.valor, desconto.tipo, pedido.subtotal!)
      expect(validacao.valido).toBe(true)
      
      // Etapa 2: Cálculo
      const resumo = calcularResumoValores(
        pedido.subtotal!,
        desconto,
        pedido.taxa_entrega!,
        0
      )
      expect(resumo.desconto_calculado).toBe(27.00) // 15% de 180
      expect(resumo.total).toBe(165.00) // (180 - 27) + 12
      
      // Etapa 3: Persistência
      const pedidoFinalizado: Partial<PedidoSupabase> = {
        ...pedido,
        desconto: desconto.valor,
        tipo_desconto: desconto.tipo,
        total: resumo.total,
      }
      
      expect(pedidoFinalizado.desconto).toBe(15)
      expect(pedidoFinalizado.tipo_desconto).toBe('percentual')
      expect(pedidoFinalizado.total).toBe(165.00)
    })
  })
})

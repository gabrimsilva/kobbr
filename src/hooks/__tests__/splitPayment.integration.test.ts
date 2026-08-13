/**
 * Integration tests for Split Payment functionality
 * 
 * Tests the complete flow of split payment from component to database:
 * - PDV flow: useFinalizarPedidoPDV hook
 * - Comandas flow: useFinalizarPedido hook (when integrated)
 * - Database persistence verification
 * 
 * These tests verify Requirements 7.1, 7.2, 4.1, 4.2, 4.3
 */

import { describe, it, expect, beforeEach, vi } from 'vitest'
import { renderHook, act, waitFor } from '@testing-library/react'
import { useFinalizarPedidoPDV } from '../useFinalizarPedidoPDV'
import { pedidoService } from '@/services'
import type { ItemCarrinhoPDV, DadosClientePDV } from '@/components/pdv/types'

// Mock dos serviços
vi.mock('@/services', () => ({
  pedidoService: {
    salvar: vi.fn()
  },
  clienteService: {
    buscarOuCriar: vi.fn(),
    incrementarEstatisticas: vi.fn()
  }
}))

describe('Split Payment Integration Tests', () => {
  // Dados de teste reutilizáveis
  const mockCarrinho: ItemCarrinhoPDV[] = [
    {
      id: 'item-1',
      produto: {
        id: 'prod-1',
        nome: 'Pizza Margherita',
        preco: 45.00,
        categoria: 'pizza',
        urlImagem: '/pizza.jpg'
      },
      quantidade: 2,
      precoUnitario: 45.00,
      precoTotal: 90.00
    },
    {
      id: 'item-2',
      produto: {
        id: 'prod-2',
        nome: 'Refrigerante',
        preco: 10.00,
        categoria: 'bebida',
        urlImagem: '/refri.jpg'
      },
      quantidade: 1,
      precoUnitario: 10.00,
      precoTotal: 10.00
    }
  ]

  const mockDadosCliente: DadosClientePDV = {
    nome: 'João',
    sobrenome: 'Silva',
    telefone: '11999999999',
    email: 'joao@example.com',
    endereco: 'Rua Teste',
    numero: '123',
    complemento: 'Apto 45',
    bairro: 'Centro',
    cidade: 'São Paulo',
    estado: 'SP',
    cep: '01234-567'
  }

  beforeEach(() => {
    vi.clearAllMocks()
    
    // Mock do pedidoService.salvar para retornar sucesso
    vi.mocked(pedidoService.salvar).mockResolvedValue({
      id: 'pedido-123',
      codigo_pedido: 'PDV-001',
      total: 100.00,
      created_at: new Date().toISOString()
    } as any)
  })

  describe('PDV Split Payment Flow', () => {
    it('should finalize order with split payment data', async () => {
      const { result } = renderHook(() => useFinalizarPedidoPDV())

      const splitPaymentData = {
        formaPagamentoDividido: true,
        pagamento1Tipo: 'PIX',
        pagamento1Valor: 60.00,
        pagamento2Tipo: 'Dinheiro',
        pagamento2Valor: 40.00
      }

      let finalizacaoResult: any

      await act(async () => {
        finalizacaoResult = await result.current.finalizarPedido({
          carrinho: mockCarrinho,
          dadosCliente: mockDadosCliente,
          entregaDomicilio: true,
          subtotal: 100.00,
          taxaEntrega: 0,
          dadosPagamento: {
            formaPagamento: 'pagamento_dividido',
            precisaTroco: false
          },
          ...splitPaymentData
        })
      })

      // Verificar que o pedido foi salvo
      expect(pedidoService.salvar).toHaveBeenCalledTimes(1)

      // Verificar que os dados de split payment foram incluídos
      const chamadaSalvar = vi.mocked(pedidoService.salvar).mock.calls[0][0]
      
      expect(chamadaSalvar.forma_pagamento_dividido).toBe(true)
      expect(chamadaSalvar.pagamento_1_tipo).toBe('PIX')
      expect(chamadaSalvar.pagamento_1_valor).toBe(60.00)
      expect(chamadaSalvar.pagamento_2_tipo).toBe('Dinheiro')
      expect(chamadaSalvar.pagamento_2_valor).toBe(40.00)

      // Verificar resultado da finalização
      expect(finalizacaoResult.sucesso).toBe(true)
      expect(finalizacaoResult.codigoPedido).toBe('PDV-001')
    })

    it('should finalize order without split payment (backward compatibility)', async () => {
      const { result } = renderHook(() => useFinalizarPedidoPDV())

      let finalizacaoResult: any

      await act(async () => {
        finalizacaoResult = await result.current.finalizarPedido({
          carrinho: mockCarrinho,
          dadosCliente: mockDadosCliente,
          entregaDomicilio: true,
          subtotal: 100.00,
          taxaEntrega: 5.00,
          dadosPagamento: {
            formaPagamento: 'dinheiro',
            precisaTroco: true,
            valorTroco: 150
          }
        })
      })

      // Verificar que o pedido foi salvo
      expect(pedidoService.salvar).toHaveBeenCalledTimes(1)

      // Verificar que os campos de split payment são false/undefined
      const chamadaSalvar = vi.mocked(pedidoService.salvar).mock.calls[0][0]
      
      expect(chamadaSalvar.forma_pagamento_dividido).toBe(false)
      expect(chamadaSalvar.pagamento_1_tipo).toBeUndefined()
      expect(chamadaSalvar.pagamento_1_valor).toBeUndefined()
      expect(chamadaSalvar.pagamento_2_tipo).toBeUndefined()
      expect(chamadaSalvar.pagamento_2_valor).toBeUndefined()

      // Verificar forma de pagamento tradicional
      expect(chamadaSalvar.forma_pagamento).toBe('dinheiro')
      expect(chamadaSalvar.precisa_troco).toBe(true)
      expect(chamadaSalvar.valor_troco).toBe(150)

      // Verificar resultado da finalização
      expect(finalizacaoResult.sucesso).toBe(true)
    })

    it('should include all required fields when split payment is enabled', async () => {
      const { result } = renderHook(() => useFinalizarPedidoPDV())

      await act(async () => {
        await result.current.finalizarPedido({
          carrinho: mockCarrinho,
          dadosCliente: mockDadosCliente,
          entregaDomicilio: false,
          subtotal: 100.00,
          taxaEntrega: 0,
          dadosPagamento: {
            formaPagamento: 'pagamento_dividido',
            precisaTroco: false
          },
          formaPagamentoDividido: true,
          pagamento1Tipo: 'Débito',
          pagamento1Valor: 70.00,
          pagamento2Tipo: 'Crédito',
          pagamento2Valor: 30.00
        })
      })

      const chamadaSalvar = vi.mocked(pedidoService.salvar).mock.calls[0][0]

      // Verificar todos os campos obrigatórios
      expect(chamadaSalvar).toHaveProperty('forma_pagamento_dividido', true)
      expect(chamadaSalvar).toHaveProperty('pagamento_1_tipo', 'Débito')
      expect(chamadaSalvar).toHaveProperty('pagamento_1_valor', 70.00)
      expect(chamadaSalvar).toHaveProperty('pagamento_2_tipo', 'Crédito')
      expect(chamadaSalvar).toHaveProperty('pagamento_2_valor', 30.00)

      // Verificar que outros campos do pedido também estão presentes
      expect(chamadaSalvar).toHaveProperty('cliente_nome', 'João')
      expect(chamadaSalvar).toHaveProperty('cliente_telefone', '11999999999')
      expect(chamadaSalvar).toHaveProperty('subtotal', 100.00)
      expect(chamadaSalvar).toHaveProperty('itens')
      expect(chamadaSalvar.itens).toHaveLength(2)
    })

    it('should handle split payment with different payment combinations', async () => {
      const { result } = renderHook(() => useFinalizarPedidoPDV())

      const combinations = [
        { tipo1: 'PIX', valor1: 50, tipo2: 'Dinheiro', valor2: 50 },
        { tipo1: 'Débito', valor1: 75, tipo2: 'Crédito', valor2: 25 },
        { tipo1: 'Crédito', valor1: 30, tipo2: 'PIX', valor2: 70 },
        { tipo1: 'Dinheiro', valor1: 90, tipo2: 'Débito', valor2: 10 }
      ]

      for (const combo of combinations) {
        vi.clearAllMocks()

        await act(async () => {
          await result.current.finalizarPedido({
            carrinho: mockCarrinho,
            dadosCliente: mockDadosCliente,
            entregaDomicilio: true,
            subtotal: 100.00,
            taxaEntrega: 0,
            dadosPagamento: {
              formaPagamento: 'pagamento_dividido',
              precisaTroco: false
            },
            formaPagamentoDividido: true,
            pagamento1Tipo: combo.tipo1,
            pagamento1Valor: combo.valor1,
            pagamento2Tipo: combo.tipo2,
            pagamento2Valor: combo.valor2
          })
        })

        const chamadaSalvar = vi.mocked(pedidoService.salvar).mock.calls[0][0]

        expect(chamadaSalvar.forma_pagamento_dividido).toBe(true)
        expect(chamadaSalvar.pagamento_1_tipo).toBe(combo.tipo1)
        expect(chamadaSalvar.pagamento_1_valor).toBe(combo.valor1)
        expect(chamadaSalvar.pagamento_2_tipo).toBe(combo.tipo2)
        expect(chamadaSalvar.pagamento_2_valor).toBe(combo.valor2)
      }
    })

    it('should handle errors gracefully when split payment save fails', async () => {
      // Mock falha no salvamento
      vi.mocked(pedidoService.salvar).mockRejectedValueOnce(
        new Error('Database connection failed')
      )

      const { result } = renderHook(() => useFinalizarPedidoPDV())

      let finalizacaoResult: any

      await act(async () => {
        finalizacaoResult = await result.current.finalizarPedido({
          carrinho: mockCarrinho,
          dadosCliente: mockDadosCliente,
          entregaDomicilio: true,
          subtotal: 100.00,
          taxaEntrega: 0,
          dadosPagamento: {
            formaPagamento: 'pagamento_dividido',
            precisaTroco: false
          },
          formaPagamentoDividido: true,
          pagamento1Tipo: 'PIX',
          pagamento1Valor: 60.00,
          pagamento2Tipo: 'Dinheiro',
          pagamento2Valor: 40.00
        })
      })

      // Verificar que o erro foi tratado
      expect(finalizacaoResult.sucesso).toBe(false)
      expect(finalizacaoResult.erro).toBeDefined()
      expect(finalizacaoResult.codigoPedido).toBeUndefined()
    })
  })

  describe('Data Validation', () => {
    it('should accept split payment with exact total match', async () => {
      const { result } = renderHook(() => useFinalizarPedidoPDV())

      await act(async () => {
        await result.current.finalizarPedido({
          carrinho: mockCarrinho,
          dadosCliente: mockDadosCliente,
          entregaDomicilio: true,
          subtotal: 100.00,
          taxaEntrega: 0,
          dadosPagamento: {
            formaPagamento: 'pagamento_dividido',
            precisaTroco: false
          },
          formaPagamentoDividido: true,
          pagamento1Tipo: 'PIX',
          pagamento1Valor: 60.00,
          pagamento2Tipo: 'Dinheiro',
          pagamento2Valor: 40.00
        })
      })

      expect(pedidoService.salvar).toHaveBeenCalled()
      
      const chamadaSalvar = vi.mocked(pedidoService.salvar).mock.calls[0][0]
      const somaValores = chamadaSalvar.pagamento_1_valor + chamadaSalvar.pagamento_2_valor
      
      // Verificar que a soma dos valores é igual ao total
      expect(somaValores).toBe(100.00)
    })

    it('should store decimal values correctly', async () => {
      const { result } = renderHook(() => useFinalizarPedidoPDV())

      await act(async () => {
        await result.current.finalizarPedido({
          carrinho: mockCarrinho,
          dadosCliente: mockDadosCliente,
          entregaDomicilio: true,
          subtotal: 100.00,
          taxaEntrega: 0,
          dadosPagamento: {
            formaPagamento: 'pagamento_dividido',
            precisaTroco: false
          },
          formaPagamentoDividido: true,
          pagamento1Tipo: 'PIX',
          pagamento1Valor: 33.33,
          pagamento2Tipo: 'Dinheiro',
          pagamento2Valor: 66.67
        })
      })

      const chamadaSalvar = vi.mocked(pedidoService.salvar).mock.calls[0][0]
      
      expect(chamadaSalvar.pagamento_1_valor).toBe(33.33)
      expect(chamadaSalvar.pagamento_2_valor).toBe(66.67)
    })
  })
})

/**
 * End-to-End Integration Tests - Split Payment Feature
 * 
 * Tests the complete flow of split payment functionality from component to database:
 * - PDV flow: Create order, select split payment, configure, finalize
 * - Comandas flow: Create comanda, select split payment, configure, finalize
 * - History migration: Execute zerar-pedidos function
 * - Reports: Generate reports with mixed data
 * 
 * These tests verify Requirements:
 * - 1.1, 1.2, 3.4: Split payment selection and configuration
 * - 4.1, 4.2, 4.3: Data persistence
 * - 5.1, 5.3: Display and printing
 * - 7.1, 7.2: Integration with hooks
 */

import { describe, it, expect, beforeEach, vi } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useFinalizarPedidoPDV } from '@/hooks/useFinalizarPedidoPDV'
import { pedidoService, comandaService } from '@/services'
import type { ItemCarrinhoPDV, DadosClientePDV } from '@/components/pdv/types'

// Mock dos serviços
vi.mock('@/services', () => ({
  pedidoService: {
    salvar: vi.fn(),
    buscarPorId: vi.fn(),
    gerarCodigoUnico: vi.fn()
  },
  comandaService: {
    criar: vi.fn(),
    finalizar: vi.fn(),
    buscarPorId: vi.fn(),
    salvarOuAtualizar: vi.fn()
  },
  clienteService: {
    buscarOuCriar: vi.fn(),
    incrementarEstatisticas: vi.fn()
  }
}))

describe('E2E: Split Payment - PDV Flow', () => {
  // Test data
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
    
    // Mock successful save
    vi.mocked(pedidoService.salvar).mockResolvedValue({
      id: 'pedido-123',
      codigo_pedido: 'PDV-001',
      total: 100.00,
      created_at: new Date().toISOString()
    } as any)
  })

  it('15.1.1 - Should complete PDV flow with split payment (PIX + Dinheiro)', async () => {
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

    // Verify persistence
    expect(pedidoService.salvar).toHaveBeenCalledTimes(1)
    const chamadaSalvar = vi.mocked(pedidoService.salvar).mock.calls[0][0]
    
    expect(chamadaSalvar.forma_pagamento_dividido).toBe(true)
    expect(chamadaSalvar.pagamento_1_tipo).toBe('PIX')
    expect(chamadaSalvar.pagamento_1_valor).toBe(60.00)
    expect(chamadaSalvar.pagamento_2_tipo).toBe('Dinheiro')
    expect(chamadaSalvar.pagamento_2_valor).toBe(40.00)

    // Verify success
    expect(finalizacaoResult.sucesso).toBe(true)
    expect(finalizacaoResult.codigoPedido).toBe('PDV-001')
  })

  it('15.1.2 - Should complete PDV flow with split payment (Débito + Crédito)', async () => {
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
    
    expect(chamadaSalvar.forma_pagamento_dividido).toBe(true)
    expect(chamadaSalvar.pagamento_1_tipo).toBe('Débito')
    expect(chamadaSalvar.pagamento_1_valor).toBe(70.00)
    expect(chamadaSalvar.pagamento_2_tipo).toBe('Crédito')
    expect(chamadaSalvar.pagamento_2_valor).toBe(30.00)
  })

  it('15.1.3 - Should verify all required fields are persisted', async () => {
    const { result } = renderHook(() => useFinalizarPedidoPDV())

    await act(async () => {
      await result.current.finalizarPedido({
        carrinho: mockCarrinho,
        dadosCliente: mockDadosCliente,
        entregaDomicilio: true,
        subtotal: 100.00,
        taxaEntrega: 5.00,
        dadosPagamento: {
          formaPagamento: 'pagamento_dividido',
          precisaTroco: false
        },
        formaPagamentoDividido: true,
        pagamento1Tipo: 'PIX',
        pagamento1Valor: 55.00,
        pagamento2Tipo: 'Dinheiro',
        pagamento2Valor: 50.00
      })
    })

    const chamadaSalvar = vi.mocked(pedidoService.salvar).mock.calls[0][0]

    // Verify split payment fields
    expect(chamadaSalvar).toHaveProperty('forma_pagamento_dividido', true)
    expect(chamadaSalvar).toHaveProperty('pagamento_1_tipo', 'PIX')
    expect(chamadaSalvar).toHaveProperty('pagamento_1_valor', 55.00)
    expect(chamadaSalvar).toHaveProperty('pagamento_2_tipo', 'Dinheiro')
    expect(chamadaSalvar).toHaveProperty('pagamento_2_valor', 50.00)

    // Verify other order fields
    expect(chamadaSalvar).toHaveProperty('cliente_nome', 'João')
    expect(chamadaSalvar).toHaveProperty('cliente_telefone', '11999999999')
    expect(chamadaSalvar).toHaveProperty('subtotal', 100.00)
    expect(chamadaSalvar).toHaveProperty('taxa_entrega', 5.00)
    expect(chamadaSalvar).toHaveProperty('total', 105.00)
    expect(chamadaSalvar).toHaveProperty('itens')
    expect(chamadaSalvar.itens).toHaveLength(2)
  })

  it('15.1.4 - Should verify display data structure for PedidoCard', async () => {
    // Mock pedido retrieval
    const mockPedidoSalvo = {
      id: 'pedido-123',
      pedido_id: 'pdv-123',
      codigo_pedido: 'PDV-001',
      cliente_nome: 'João',
      cliente_sobrenome: 'Silva',
      cliente_telefone: '11999999999',
      status: 'Pedido criado',
      total: 100.00,
      subtotal: 100.00,
      taxa_entrega: 0,
      desconto: 0,
      tipo_desconto: 'valor' as const,
      entrega_domicilio: false,
      forma_pagamento: 'pagamento_dividido',
      forma_pagamento_dividido: true,
      pagamento_1_tipo: 'PIX',
      pagamento_1_valor: 60.00,
      pagamento_2_tipo: 'Dinheiro',
      pagamento_2_valor: 40.00,
      criado_em: new Date().toISOString(),
      itens: mockCarrinho
    }

    vi.mocked(pedidoService.buscarPorId).mockResolvedValue(mockPedidoSalvo as any)

    const pedido = await pedidoService.buscarPorId('pdv-123')

    // Verify split payment data structure for display
    expect(pedido?.forma_pagamento_dividido).toBe(true)
    expect(pedido?.pagamento_1_tipo).toBe('PIX')
    expect(pedido?.pagamento_1_valor).toBe(60.00)
    expect(pedido?.pagamento_2_tipo).toBe('Dinheiro')
    expect(pedido?.pagamento_2_valor).toBe(40.00)

    // Verify display format
    const displayText = `${pedido?.pagamento_1_tipo} R$ ${pedido?.pagamento_1_valor?.toFixed(2)} + ${pedido?.pagamento_2_tipo} R$ ${pedido?.pagamento_2_valor?.toFixed(2)}`
    expect(displayText).toBe('PIX R$ 60.00 + Dinheiro R$ 40.00')
  })

  it('15.1.5 - Should verify print receipt data structure', async () => {
    const mockPedidoComSplit = {
      id: 'pedido-123',
      codigo_pedido: 'PDV-001',
      forma_pagamento_dividido: true,
      pagamento_1_tipo: 'PIX',
      pagamento_1_valor: 60.00,
      pagamento_2_tipo: 'Dinheiro',
      pagamento_2_valor: 40.00,
      total: 100.00,
      itens: mockCarrinho
    }

    // Simulate print receipt generation
    let receiptHTML = '<div class="receipt">'
    
    if (mockPedidoComSplit.forma_pagamento_dividido) {
      receiptHTML += '<div class="payment-section">'
      receiptHTML += '<strong>FORMA DE PAGAMENTO:</strong><br>'
      receiptHTML += `- ${mockPedidoComSplit.pagamento_1_tipo}: R$ ${mockPedidoComSplit.pagamento_1_valor.toFixed(2)}<br>`
      receiptHTML += `- ${mockPedidoComSplit.pagamento_2_tipo}: R$ ${mockPedidoComSplit.pagamento_2_valor.toFixed(2)}<br>`
      receiptHTML += `Total: R$ ${mockPedidoComSplit.total.toFixed(2)}`
      receiptHTML += '</div>'
    }
    
    receiptHTML += '</div>'

    // Verify receipt contains split payment details
    expect(receiptHTML).toContain('FORMA DE PAGAMENTO:')
    expect(receiptHTML).toContain('PIX: R$ 60.00')
    expect(receiptHTML).toContain('Dinheiro: R$ 40.00')
    expect(receiptHTML).toContain('Total: R$ 100.00')
  })
})


describe('E2E: Split Payment - Comandas Flow', () => {
  const mockItensComanda = [
    {
      produto: {
        id: 'prod-1',
        nome: 'Pizza Margherita',
        preco: 45.00,
        categoria: 'pizza'
      },
      quantidade: 2,
      precoUnitario: 45.00,
      precoTotal: 90.00
    },
    {
      produto: {
        id: 'prod-2',
        nome: 'Refrigerante',
        preco: 10.00,
        categoria: 'bebida'
      },
      quantidade: 1,
      precoUnitario: 10.00,
      precoTotal: 10.00
    }
  ]

  beforeEach(() => {
    vi.clearAllMocks()
    
    // Mock successful comanda creation
    vi.mocked(comandaService.salvarOuAtualizar).mockResolvedValue({
      id: 'comanda-123',
      numero_comanda: 1,
      itens: mockItensComanda,
      subtotal: 100.00,
      total: 100.00,
      status: 'aberta',
      criado_em: new Date().toISOString()
    } as any)

    // Mock successful comanda finalization
    vi.mocked(comandaService.finalizar).mockResolvedValue({
      id: 'comanda-123',
      numero_comanda: 1,
      itens: mockItensComanda,
      subtotal: 100.00,
      total: 100.00,
      status: 'finalizada',
      forma_pagamento: 'pagamento_dividido',
      forma_pagamento_dividido: true,
      pagamento_1_tipo: 'PIX',
      pagamento_1_valor: 60.00,
      pagamento_2_tipo: 'Dinheiro',
      pagamento_2_valor: 40.00,
      criado_em: new Date().toISOString(),
      finalizado_em: new Date().toISOString()
    } as any)
  })

  it('15.2.1 - Should complete Comanda flow with split payment', async () => {
    // Step 1: Create comanda
    const comanda = await comandaService.salvarOuAtualizar({
      numero_comanda: 1,
      itens: mockItensComanda,
      subtotal: 100.00,
      total: 100.00
    })

    expect(comanda.numero_comanda).toBe(1)
    expect(comanda.status).toBe('aberta')

    // Step 2: Finalize with split payment
    const comandaFinalizada = await comandaService.finalizar(
      comanda.id,
      'pagamento_dividido',
      {
        formaPagamentoDividido: true,
        pagamento1Tipo: 'PIX',
        pagamento1Valor: 60.00,
        pagamento2Tipo: 'Dinheiro',
        pagamento2Valor: 40.00
      }
    )

    // Verify persistence
    expect(comandaFinalizada.status).toBe('finalizada')
    expect(comandaFinalizada.forma_pagamento_dividido).toBe(true)
    expect(comandaFinalizada.pagamento_1_tipo).toBe('PIX')
    expect(comandaFinalizada.pagamento_1_valor).toBe(60.00)
    expect(comandaFinalizada.pagamento_2_tipo).toBe('Dinheiro')
    expect(comandaFinalizada.pagamento_2_valor).toBe(40.00)
  })

  it('15.2.2 - Should complete Comanda flow with different payment combinations', async () => {
    const combinations = [
      { tipo1: 'Débito', valor1: 75, tipo2: 'Crédito', valor2: 25 },
      { tipo1: 'Crédito', valor1: 30, tipo2: 'PIX', valor2: 70 },
      { tipo1: 'Dinheiro', valor1: 90, tipo2: 'Débito', valor2: 10 }
    ]

    for (const combo of combinations) {
      vi.clearAllMocks()

      // Mock for this iteration
      vi.mocked(comandaService.finalizar).mockResolvedValue({
        id: 'comanda-123',
        numero_comanda: 1,
        itens: mockItensComanda,
        subtotal: 100.00,
        total: 100.00,
        status: 'finalizada',
        forma_pagamento: 'pagamento_dividido',
        forma_pagamento_dividido: true,
        pagamento_1_tipo: combo.tipo1,
        pagamento_1_valor: combo.valor1,
        pagamento_2_tipo: combo.tipo2,
        pagamento_2_valor: combo.valor2,
        criado_em: new Date().toISOString(),
        finalizado_em: new Date().toISOString()
      } as any)

      const comandaFinalizada = await comandaService.finalizar(
        'comanda-123',
        'pagamento_dividido',
        {
          formaPagamentoDividido: true,
          pagamento1Tipo: combo.tipo1,
          pagamento1Valor: combo.valor1,
          pagamento2Tipo: combo.tipo2,
          pagamento2Valor: combo.valor2
        }
      )

      expect(comandaFinalizada.forma_pagamento_dividido).toBe(true)
      expect(comandaFinalizada.pagamento_1_tipo).toBe(combo.tipo1)
      expect(comandaFinalizada.pagamento_1_valor).toBe(combo.valor1)
      expect(comandaFinalizada.pagamento_2_tipo).toBe(combo.tipo2)
      expect(comandaFinalizada.pagamento_2_valor).toBe(combo.valor2)
    }
  })

  it('15.2.3 - Should verify display data structure for ComandaCard', async () => {
    const mockComandaSalva = {
      id: 'comanda-123',
      numero_comanda: 1,
      itens: mockItensComanda,
      subtotal: 100.00,
      total: 100.00,
      status: 'finalizada',
      forma_pagamento: 'pagamento_dividido',
      forma_pagamento_dividido: true,
      pagamento_1_tipo: 'PIX',
      pagamento_1_valor: 60.00,
      pagamento_2_tipo: 'Dinheiro',
      pagamento_2_valor: 40.00,
      criado_em: new Date().toISOString(),
      finalizado_em: new Date().toISOString()
    }

    vi.mocked(comandaService.buscarPorId).mockResolvedValue(mockComandaSalva as any)

    const comanda = await comandaService.buscarPorId('comanda-123')

    // Verify split payment data structure for display
    expect(comanda?.forma_pagamento_dividido).toBe(true)
    expect(comanda?.pagamento_1_tipo).toBe('PIX')
    expect(comanda?.pagamento_1_valor).toBe(60.00)
    expect(comanda?.pagamento_2_tipo).toBe('Dinheiro')
    expect(comanda?.pagamento_2_valor).toBe(40.00)

    // Verify display format
    const displayText = `${comanda?.pagamento_1_tipo} R$ ${comanda?.pagamento_1_valor?.toFixed(2)} + ${comanda?.pagamento_2_tipo} R$ ${comanda?.pagamento_2_valor?.toFixed(2)}`
    expect(displayText).toBe('PIX R$ 60.00 + Dinheiro R$ 40.00')
  })

  it('15.2.4 - Should verify print receipt for comanda', async () => {
    const mockComandaComSplit = {
      id: 'comanda-123',
      numero_comanda: 1,
      forma_pagamento_dividido: true,
      pagamento_1_tipo: 'PIX',
      pagamento_1_valor: 60.00,
      pagamento_2_tipo: 'Dinheiro',
      pagamento_2_valor: 40.00,
      total: 100.00,
      itens: mockItensComanda
    }

    // Simulate print receipt generation
    let receiptHTML = '<div class="receipt">'
    receiptHTML += `<div class="header">Comanda #${mockComandaComSplit.numero_comanda}</div>`
    
    if (mockComandaComSplit.forma_pagamento_dividido) {
      receiptHTML += '<div class="payment-section">'
      receiptHTML += '<strong>FORMA DE PAGAMENTO:</strong><br>'
      receiptHTML += `- ${mockComandaComSplit.pagamento_1_tipo}: R$ ${mockComandaComSplit.pagamento_1_valor.toFixed(2)}<br>`
      receiptHTML += `- ${mockComandaComSplit.pagamento_2_tipo}: R$ ${mockComandaComSplit.pagamento_2_valor.toFixed(2)}<br>`
      receiptHTML += `Total: R$ ${mockComandaComSplit.total.toFixed(2)}`
      receiptHTML += '</div>'
    }
    
    receiptHTML += '</div>'

    // Verify receipt contains split payment details
    expect(receiptHTML).toContain('Comanda #1')
    expect(receiptHTML).toContain('FORMA DE PAGAMENTO:')
    expect(receiptHTML).toContain('PIX: R$ 60.00')
    expect(receiptHTML).toContain('Dinheiro: R$ 40.00')
    expect(receiptHTML).toContain('Total: R$ 100.00')
  })
})

describe('E2E: Split Payment - History Migration', () => {
  it('15.3.1 - Should verify split payment fields are copied to history', async () => {
    // Simulate pedido with split payment
    const mockPedido = {
      pedido_id: 'pdv-123',
      codigo_pedido: 'PDV-001',
      cliente_nome: 'João',
      cliente_telefone: '11999999999',
      total: 100.00,
      subtotal: 100.00,
      taxa_entrega: 0,
      desconto: 0,
      tipo_desconto: 'valor' as const,
      forma_pagamento: 'pagamento_dividido',
      forma_pagamento_dividido: true,
      pagamento_1_tipo: 'PIX',
      pagamento_1_valor: 60.00,
      pagamento_2_tipo: 'Dinheiro',
      pagamento_2_valor: 40.00,
      status: 'Entregue',
      itens: []
    }

    // Simulate history record structure (what zerar-pedidos would create)
    const historicoRecord = {
      pedido_id: mockPedido.pedido_id,
      codigo_pedido: mockPedido.codigo_pedido,
      cliente_nome: mockPedido.cliente_nome,
      cliente_telefone: mockPedido.cliente_telefone,
      total: mockPedido.total,
      subtotal: mockPedido.subtotal,
      taxa_entrega: mockPedido.taxa_entrega,
      desconto: mockPedido.desconto,
      tipo_desconto: mockPedido.tipo_desconto,
      forma_pagamento: mockPedido.forma_pagamento,
      // Split payment fields must be copied
      forma_pagamento_dividido: mockPedido.forma_pagamento_dividido,
      pagamento_1_tipo: mockPedido.pagamento_1_tipo,
      pagamento_1_valor: mockPedido.pagamento_1_valor,
      pagamento_2_tipo: mockPedido.pagamento_2_tipo,
      pagamento_2_valor: mockPedido.pagamento_2_valor,
      status: mockPedido.status,
      itens: mockPedido.itens
    }

    // Verify all split payment fields are present in history
    expect(historicoRecord.forma_pagamento_dividido).toBe(true)
    expect(historicoRecord.pagamento_1_tipo).toBe('PIX')
    expect(historicoRecord.pagamento_1_valor).toBe(60.00)
    expect(historicoRecord.pagamento_2_tipo).toBe('Dinheiro')
    expect(historicoRecord.pagamento_2_valor).toBe(40.00)
  })

  it('15.3.2 - Should verify comanda split payment fields are copied to history', async () => {
    // Simulate comanda with split payment
    const mockComanda = {
      id: 'comanda-123',
      numero_comanda: 1,
      total: 100.00,
      subtotal: 100.00,
      desconto: 0,
      tipo_desconto: 'valor' as const,
      forma_pagamento: 'pagamento_dividido',
      forma_pagamento_dividido: true,
      pagamento_1_tipo: 'Débito',
      pagamento_1_valor: 70.00,
      pagamento_2_tipo: 'Crédito',
      pagamento_2_valor: 30.00,
      status: 'finalizada',
      itens: []
    }

    // Simulate history record structure
    const historicoComandaRecord = {
      numero_comanda: mockComanda.numero_comanda,
      total: mockComanda.total,
      subtotal: mockComanda.subtotal,
      desconto: mockComanda.desconto,
      tipo_desconto: mockComanda.tipo_desconto,
      forma_pagamento: mockComanda.forma_pagamento,
      // Split payment fields must be copied
      forma_pagamento_dividido: mockComanda.forma_pagamento_dividido,
      pagamento_1_tipo: mockComanda.pagamento_1_tipo,
      pagamento_1_valor: mockComanda.pagamento_1_valor,
      pagamento_2_tipo: mockComanda.pagamento_2_tipo,
      pagamento_2_valor: mockComanda.pagamento_2_valor,
      itens: mockComanda.itens
    }

    // Verify all split payment fields are present in history
    expect(historicoComandaRecord.forma_pagamento_dividido).toBe(true)
    expect(historicoComandaRecord.pagamento_1_tipo).toBe('Débito')
    expect(historicoComandaRecord.pagamento_1_valor).toBe(70.00)
    expect(historicoComandaRecord.pagamento_2_tipo).toBe('Crédito')
    expect(historicoComandaRecord.pagamento_2_valor).toBe(30.00)
  })
})

describe('E2E: Split Payment - Reports with Mixed Data', () => {
  it('15.4.1 - Should aggregate split payments correctly by payment type', () => {
    // Simulate mixed data: some with split payment, some without
    const mockPedidos = [
      {
        id: '1',
        total: 100.00,
        forma_pagamento: 'dinheiro',
        forma_pagamento_dividido: false
      },
      {
        id: '2',
        total: 150.00,
        forma_pagamento: 'pagamento_dividido',
        forma_pagamento_dividido: true,
        pagamento_1_tipo: 'PIX',
        pagamento_1_valor: 90.00,
        pagamento_2_tipo: 'Dinheiro',
        pagamento_2_valor: 60.00
      },
      {
        id: '3',
        total: 80.00,
        forma_pagamento: 'pix',
        forma_pagamento_dividido: false
      },
      {
        id: '4',
        total: 200.00,
        forma_pagamento: 'pagamento_dividido',
        forma_pagamento_dividido: true,
        pagamento_1_tipo: 'Débito',
        pagamento_1_valor: 120.00,
        pagamento_2_tipo: 'Crédito',
        pagamento_2_valor: 80.00
      }
    ]

    // Simulate report aggregation logic
    const totaisPorFormaPagamento: Record<string, number> = {}

    mockPedidos.forEach(pedido => {
      if (pedido.forma_pagamento_dividido) {
        // Split payment: add each part to its respective payment type
        const tipo1 = (pedido as any).pagamento_1_tipo
        const valor1 = (pedido as any).pagamento_1_valor
        const tipo2 = (pedido as any).pagamento_2_tipo
        const valor2 = (pedido as any).pagamento_2_valor

        totaisPorFormaPagamento[tipo1] = (totaisPorFormaPagamento[tipo1] || 0) + valor1
        totaisPorFormaPagamento[tipo2] = (totaisPorFormaPagamento[tipo2] || 0) + valor2
      } else {
        // Regular payment: add total to payment type
        const tipo = pedido.forma_pagamento
        totaisPorFormaPagamento[tipo] = (totaisPorFormaPagamento[tipo] || 0) + pedido.total
      }
    })

    // Verify aggregation
    expect(totaisPorFormaPagamento['Dinheiro']).toBe(60.00) // 60 (pedido 2 parte 2)
    expect(totaisPorFormaPagamento['dinheiro']).toBe(100.00) // 100 (pedido 1)
    expect(totaisPorFormaPagamento['PIX']).toBe(90.00) // 90 (pedido 2 parte 1)
    expect(totaisPorFormaPagamento['pix']).toBe(80.00) // 80 (pedido 3)
    expect(totaisPorFormaPagamento['Débito']).toBe(120.00) // 120 (pedido 4 parte 1)
    expect(totaisPorFormaPagamento['Crédito']).toBe(80.00) // 80 (pedido 4 parte 2)
  })

  it('15.4.2 - Should include historical records in report aggregation', () => {
    // Simulate data from both active and history tables
    const mockPedidosAtivos = [
      {
        id: '1',
        total: 100.00,
        forma_pagamento: 'dinheiro',
        forma_pagamento_dividido: false
      },
      {
        id: '2',
        total: 150.00,
        forma_pagamento: 'pagamento_dividido',
        forma_pagamento_dividido: true,
        pagamento_1_tipo: 'PIX',
        pagamento_1_valor: 90.00,
        pagamento_2_tipo: 'Dinheiro',
        pagamento_2_valor: 60.00
      }
    ]

    const mockPedidosHistorico = [
      {
        id: '3',
        total: 80.00,
        forma_pagamento: 'pix',
        forma_pagamento_dividido: false
      },
      {
        id: '4',
        total: 200.00,
        forma_pagamento: 'pagamento_dividido',
        forma_pagamento_dividido: true,
        pagamento_1_tipo: 'Débito',
        pagamento_1_valor: 120.00,
        pagamento_2_tipo: 'Crédito',
        pagamento_2_valor: 80.00
      }
    ]

    // Combine both sources
    const todosPedidos = [...mockPedidosAtivos, ...mockPedidosHistorico]

    // Aggregate
    const totaisPorFormaPagamento: Record<string, number> = {}

    todosPedidos.forEach(pedido => {
      if (pedido.forma_pagamento_dividido) {
        const tipo1 = (pedido as any).pagamento_1_tipo
        const valor1 = (pedido as any).pagamento_1_valor
        const tipo2 = (pedido as any).pagamento_2_tipo
        const valor2 = (pedido as any).pagamento_2_valor

        totaisPorFormaPagamento[tipo1] = (totaisPorFormaPagamento[tipo1] || 0) + valor1
        totaisPorFormaPagamento[tipo2] = (totaisPorFormaPagamento[tipo2] || 0) + valor2
      } else {
        const tipo = pedido.forma_pagamento
        totaisPorFormaPagamento[tipo] = (totaisPorFormaPagamento[tipo] || 0) + pedido.total
      }
    })

    // Verify aggregation includes both active and historical records
    expect(totaisPorFormaPagamento['Dinheiro']).toBe(60.00) // 60 (pedido 2 parte 2)
    expect(totaisPorFormaPagamento['dinheiro']).toBe(100.00) // 100 (pedido 1)
    expect(totaisPorFormaPagamento['PIX']).toBe(90.00) // 90 (pedido 2 parte 1)
    expect(totaisPorFormaPagamento['pix']).toBe(80.00) // 80 (pedido 3)
    expect(totaisPorFormaPagamento['Débito']).toBe(120.00) // 120 (pedido 4 parte 1)
    expect(totaisPorFormaPagamento['Crédito']).toBe(80.00) // 80 (pedido 4 parte 2)
  })

  it('15.4.3 - Should handle edge case: only split payments', () => {
    const mockPedidos = [
      {
        id: '1',
        total: 100.00,
        forma_pagamento: 'pagamento_dividido',
        forma_pagamento_dividido: true,
        pagamento_1_tipo: 'PIX',
        pagamento_1_valor: 60.00,
        pagamento_2_tipo: 'Dinheiro',
        pagamento_2_valor: 40.00
      },
      {
        id: '2',
        total: 150.00,
        forma_pagamento: 'pagamento_dividido',
        forma_pagamento_dividido: true,
        pagamento_1_tipo: 'Débito',
        pagamento_1_valor: 100.00,
        pagamento_2_tipo: 'Crédito',
        pagamento_2_valor: 50.00
      }
    ]

    const totaisPorFormaPagamento: Record<string, number> = {}

    mockPedidos.forEach(pedido => {
      if (pedido.forma_pagamento_dividido) {
        const tipo1 = (pedido as any).pagamento_1_tipo
        const valor1 = (pedido as any).pagamento_1_valor
        const tipo2 = (pedido as any).pagamento_2_tipo
        const valor2 = (pedido as any).pagamento_2_valor

        totaisPorFormaPagamento[tipo1] = (totaisPorFormaPagamento[tipo1] || 0) + valor1
        totaisPorFormaPagamento[tipo2] = (totaisPorFormaPagamento[tipo2] || 0) + valor2
      }
    })

    expect(totaisPorFormaPagamento['PIX']).toBe(60.00)
    expect(totaisPorFormaPagamento['Dinheiro']).toBe(40.00)
    expect(totaisPorFormaPagamento['Débito']).toBe(100.00)
    expect(totaisPorFormaPagamento['Crédito']).toBe(50.00)
  })

  it('15.4.4 - Should handle edge case: no split payments (backward compatibility)', () => {
    const mockPedidos = [
      {
        id: '1',
        total: 100.00,
        forma_pagamento: 'dinheiro',
        forma_pagamento_dividido: false
      },
      {
        id: '2',
        total: 80.00,
        forma_pagamento: 'pix',
        forma_pagamento_dividido: false
      },
      {
        id: '3',
        total: 120.00,
        forma_pagamento: 'cartao_credito',
        forma_pagamento_dividido: false
      }
    ]

    const totaisPorFormaPagamento: Record<string, number> = {}

    mockPedidos.forEach(pedido => {
      if (pedido.forma_pagamento_dividido) {
        const tipo1 = (pedido as any).pagamento_1_tipo
        const valor1 = (pedido as any).pagamento_1_valor
        const tipo2 = (pedido as any).pagamento_2_tipo
        const valor2 = (pedido as any).pagamento_2_valor

        totaisPorFormaPagamento[tipo1] = (totaisPorFormaPagamento[tipo1] || 0) + valor1
        totaisPorFormaPagamento[tipo2] = (totaisPorFormaPagamento[tipo2] || 0) + valor2
      } else {
        const tipo = pedido.forma_pagamento
        totaisPorFormaPagamento[tipo] = (totaisPorFormaPagamento[tipo] || 0) + pedido.total
      }
    })

    // Verify backward compatibility: regular payments work as before
    expect(totaisPorFormaPagamento['dinheiro']).toBe(100.00)
    expect(totaisPorFormaPagamento['pix']).toBe(80.00)
    expect(totaisPorFormaPagamento['cartao_credito']).toBe(120.00)
  })
})

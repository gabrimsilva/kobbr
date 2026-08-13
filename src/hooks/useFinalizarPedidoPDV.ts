import { useState } from 'react'
import { pedidoService } from "@/services"
import { type ItemCarrinhoPDV } from '@/components/pdv/types'
import { sanitizeFreeText } from '@/utils/sanitizacao'

/**
 * Dados de pagamento do pedido
 */
interface DadosPagamento {
  /** Forma de pagamento escolhida (dinheiro, cartaoDebito, pix, etc) */
  formaPagamento: string
  /** Se o cliente precisa de troco */
  precisaTroco: boolean
  /** Valor para o qual precisa de troco */
  valorTroco?: number
}

/**
 * Parâmetros necessários para finalizar um pedido no PDV (simplificado - sem dados de cliente)
 */
interface FinalizarPedidoParams {
  /** Itens do carrinho a serem incluídos no pedido */
  carrinho: ItemCarrinhoPDV[]
  /** Subtotal dos itens (sem taxa de entrega) */
  subtotal: number
  /** Dados de pagamento */
  dadosPagamento: DadosPagamento
  /** Desconto aplicado (sempre 0 - simplificado) */
  desconto?: number
  /** Tipo do desconto (sempre 'valor' - simplificado) */
  tipoDesconto?: 'valor'
  /** Se o pagamento é dividido (sempre false - simplificado) */
  formaPagamentoDividido?: boolean
}

/**
 * Hook customizado para gerenciar a finalização de pedidos no PDV (simplificado - sem dados de cliente)
 * 
 * Gerencia validações, processamento e salvamento de pedidos,
 * sem desconto manual, sem pagamento dividido e sem dados de cliente.
 * 
 * @example
 * ```tsx
 * const {
 *   processando,
 *   finalizarPedido
 * } = useFinalizarPedidoPDV()
 * 
 * const handleFinalizar = async () => {
 *   const resultado = await finalizarPedido({
 *     carrinho,
 *     subtotal,
 *     dadosPagamento
 *   })
 *   
 *   if (resultado.sucesso) {
 *     console.log('Pedido criado:', resultado.codigoPedido)
 *   } else {
 *     console.error('Erro:', resultado.erro)
 *   }
 * }
 * ```
 */
export function useFinalizarPedidoPDV() {
  const [processando, setProcessando] = useState(false)

  /**
   * Finaliza o pedido salvando no banco de dados (simplificado - sem dados de cliente)
   *
   * Executa as seguintes operações:
   * 1. Prepara os dados do pedido com itens e valores
   * 2. Salva o pedido com status 'pendente'
   * 3. Retorna código do pedido gerado
   *
   * @param params - Parâmetros completos do pedido
   * @returns Promise com objeto contendo sucesso e codigoPedido ou erro
   */
  const finalizarPedido = async (params: FinalizarPedidoParams) => {
    const {
      carrinho,
      subtotal,
      dadosPagamento,
      desconto = 0,
      tipoDesconto = 'valor'
    } = params

    try {
      setProcessando(true)

      // Calcular total simples (sem desconto e sem taxa de entrega)
      const total = subtotal

      // Gerar ID único para o pedido
      const pedidoId = `pdv-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`

      // Preparar dados do pedido (simplificado - sem dados de cliente)
      const dadosPedido = {
        pedido_id: pedidoId,
        // Sem dados de cliente (simplificado)
        cliente_nome: 'Cliente PDV',
        cliente_sobrenome: '',
        cliente_telefone: '',
        cliente_email: undefined,
        cliente_endereco: undefined,
        cliente_numero: undefined,
        cliente_complemento: undefined,
        cliente_bairro: undefined,
        cliente_cidade: undefined,
        cliente_estado: undefined,
        cliente_cep: undefined,
        entrega_domicilio: false, // Sempre false (simplificado)
        forma_pagamento: dadosPagamento.formaPagamento,
        precisa_troco: dadosPagamento.precisaTroco,
        valor_troco: dadosPagamento.valorTroco || undefined,
        subtotal: subtotal,
        taxa_entrega: 0, // Sempre 0 (simplificado)
        taxa_extra_km: 0, // Sempre 0 (simplificado)
        desconto: desconto, // Sempre 0 (simplificado)
        tipo_desconto: tipoDesconto, // Sempre 'valor' (simplificado)
        total: total,
        // Sem pagamento dividido (simplificado)
        forma_pagamento_dividido: false,
        itens: carrinho.map(item => ({
          produto: {
            id: item.produto.id,
            nome: item.produto.nome,
            preco: item.produto.preco,
            categoria: item.produto.categoria,
            imagem_path: item.produto.urlImagem
          },
          quantidade: item.quantidade,
          saboresSelecionados: item.saboresSelecionados || undefined,
          bordaSelecionada: item.bordaSelecionada || undefined,
          tamanhoSelecionado: item.tamanhoSelecionado || undefined,
          adicionaisSelecionados: item.adicionaisSelecionados || undefined,
          observacoes: item.observacoes ? sanitizeFreeText(item.observacoes, 300) : undefined,
          produtosCombo: item.produtosCombo || undefined
        })),
        status: 'Pedido criado',
        observacoes: `Pedido criado via PDV - ${new Date().toLocaleString()}`
      }

      // Salvar pedido
      const pedidoSalvo = await pedidoService.salvar(dadosPedido)

      // 🆕 FAZER BAIXA DE ESTOQUE PARA CADA ITEM DO CARRINHO
      try {
        const { stockService } = await import('@/services')
        for (const item of carrinho) {
          const quantidade = item.quantidade
          const variantId = (item as any).variantId
          
          console.log(`📦 PDV: Reduzindo estoque: produto=${item.produto.id}, quantidade=${quantidade}, variante=${variantId || 'nenhuma'}`)
          
          // Usar darBaixaEmVenda que resolve o stock_item automaticamente
          await stockService.darBaixaEmVenda(
            item.produto.id, 
            quantidade,
            variantId
          )
        }
        console.log('✅ Estoque reduzido com sucesso para todos os itens (PDV)')
      } catch (estoqueError) {
        console.error('⚠️ Erro ao reduzir estoque no PDV (continuando):', estoqueError)
        // Não bloquear o fluxo de PDV se houver erro no estoque
      }

      return {
        sucesso: true,
        codigoPedido: pedidoSalvo.codigo_pedido,
        pedidoId: pedidoSalvo.id
      }
    } catch (error) {
      console.error('Erro ao criar pedido:', error)
      return {
        sucesso: false,
        erro: error instanceof Error ? error.message : 'Erro ao criar pedido. Tente novamente.'
      }
    } finally {
      setProcessando(false)
    }
  }

  return {
    processando,
    finalizarPedido
  }
}
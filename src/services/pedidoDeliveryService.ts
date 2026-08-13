/**
 * Serviço para integração de pedidos delivery com vendas e estoque
 * 
 * @module services/pedidoDeliveryService
 */

import { vendaService } from './vendaService'
import { stockService } from './stockService'

/**
 * Classe de serviço para gerenciar integração de pedidos delivery
 */
class PedidoDeliveryService {
  /**
   * Finaliza um pedido delivery:
   * 1. Cria registro em sales
   * 2. Dá baixa no estoque
   * 3. Registra movimentações
   * 
   * @param pedido - Dados completos do pedido
   * @returns Objeto com sucesso e dados da venda criada
   */
  async finalizarPedidoDelivery(pedido: any): Promise<{
    sucesso: boolean
    venda?: any
    erro?: string
  }> {
    try {
      console.log(`🚀 Iniciando finalização do pedido delivery: ${pedido.codigo_pedido}`)
      console.log(`📦 Dados do pedido:`, pedido)

      // 1. VALIDAR E NORMALIZAR ITENS
      let itens = pedido.itens || []
      
      // Se itens for string (JSON stringificado), fazer parse
      if (typeof itens === 'string') {
        try {
          itens = JSON.parse(itens)
        } catch {
          console.warn(`⚠️ Não foi possível fazer parse de itens como JSON`)
          itens = []
        }
      }

      console.log(`📋 Itens do pedido (após normalização):`, itens)

      if (!Array.isArray(itens) || itens.length === 0) {
        console.warn(`⚠️ Pedido sem itens ou itens em formato inválido`)
        // Não falhar, apenas pular validação de estoque
      } else {
        // 2. VALIDAR ESTOQUE (mesma regra do PDV e das comandas).
        // Roda ANTES de criar a venda: se faltar saldo em qualquer item, nada
        // é persistido e nada é baixado.
        await stockService.validarEstoqueVenda(
          itens.map((item: any) => ({
            produtoId: item.produto_id || item.produto?.id,
            quantidade: item.quantidade || 1,
            variantId: item.variantId || undefined,
            nome: item.produto?.nome || item.nome
          }))
        )

        console.log(`✅ Estoque validado para todos os itens`)
      }

      // 3. CRIAR VENDA EM SALES
      console.log(`💾 Criando venda...`)
      const venda = await vendaService.criarVendaDelivery(pedido)
      console.log(`✅ Venda criada: ${venda?.sale_number}`)

      // 4. DAR BAIXA NO ESTOQUE (após venda criada com sucesso).
      // Esta é a ÚNICA baixa do fluxo delivery — o checkout não movimenta
      // estoque, porque roda como `anon` e não tem permissão RLS nas tabelas
      // stock_*. Falhas aqui são reportadas ao operador em vez de silenciadas.
      const falhasBaixa: string[] = []

      if (Array.isArray(itens) && itens.length > 0) {
        for (const item of itens) {
          const produtoId = item.produto_id || item.produto?.id
          const quantidade = item.quantidade || 1
          const variantId = item.variantId || undefined

          if (!produtoId) {
            console.warn(`⚠️ Item sem produto ID, pulando baixa de estoque`)
            continue
          }

          try {
            await stockService.darBaixaEmVenda(
              produtoId,
              quantidade,
              variantId,
              'DELIVERY',
              venda?.id
            )
            console.log(`✅ Baixa de estoque: ${quantidade} un`)
          } catch (error) {
            const nome = item.produto?.nome || item.nome || produtoId
            const msg = error instanceof Error ? error.message : 'erro desconhecido'
            console.error(`❌ ERRO ao dar baixa no estoque de ${nome}:`, error)
            falhasBaixa.push(`${nome}: ${msg}`)
          }
        }
      }

      if (falhasBaixa.length > 0) {
        // A venda foi criada, mas o estoque não fechou. Reportar para que o
        // operador ajuste manualmente pela tela de Entrada / Saída.
        return {
          sucesso: false,
          venda,
          erro: `Venda criada, mas a baixa de estoque falhou em: ${falhasBaixa.join('; ')}`
        }
      }

      console.log(`🎉 Pedido delivery finalizado com sucesso!`)

      return {
        sucesso: true,
        venda
      }
    } catch (error) {
      console.error('❌ Erro ao finalizar pedido delivery:', error)
      return {
        sucesso: false,
        erro: error instanceof Error ? error.message : 'Erro ao finalizar pedido delivery'
      }
    }
  }
}

// Exportar instância única do serviço
export const pedidoDeliveryService = new PedidoDeliveryService()

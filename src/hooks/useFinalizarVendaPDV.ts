import { useState } from 'react'
import { vendaService, stockService, configuracaoService } from "@/services"
import { receiptService } from "@/services/receiptService"
import { printJobService } from "@/services/printJobService"
import { type ItemCarrinhoPDV } from '@/components/pdv/types'
import { sanitizeFreeText } from '@/utils/sanitizacao'

/**
 * Dados de pagamento da venda
 */
interface DadosPagamento {
  /** Forma de pagamento escolhida (dinheiro, cartaoDebito, pix, etc) */
  formaPagamento: string
  /** Se o cliente precisa de troco */
  precisaTroco: boolean
  /** Valor para o qual precisa de troco */
  valorTroco?: number
  /** Se é consumo interno (sem cobrança) */
  consumoInterno?: boolean
}

/**
 * Parâmetros necessários para finalizar uma venda no PDV
 */
interface FinalizarVendaParams {
  /** Itens do carrinho a serem incluídos na venda */
  carrinho: ItemCarrinhoPDV[]
  /** Subtotal dos itens */
  subtotal: number
  /** Dados de pagamento */
  dadosPagamento: DadosPagamento
  /** Desconto aplicado (sempre 0 - simplificado) */
  desconto?: number
  /** Tipo do desconto (sempre 'valor' - simplificado) */
  tipoDesconto?: 'valor'
  /** Se o pagamento é dividido (sempre false - simplificado) */
  formaPagamentoDividido?: boolean
  /** Se é consumo interno (sem cobrança) */
  consumoInterno?: boolean
}

/**
 * Hook customizado para gerenciar a finalização de vendas no PDV
 * 
 * Gerencia validações, processamento, salvamento de vendas e baixa de estoque.
 * 
 * @example
 * ```tsx
 * const {
 *   processando,
 *   finalizarVenda
 * } = useFinalizarVendaPDV()
 * 
 * const handleFinalizar = async () => {
 *   const resultado = await finalizarVenda({
 *     carrinho,
 *     subtotal,
 *     dadosPagamento
 *   })
 *   
 *   if (resultado.sucesso) {
 *     console.log('Venda finalizada:', resultado.numeroVenda)
 *   } else {
 *     console.error('Erro:', resultado.erro)
 *   }
 * }
 * ```
 */
export function useFinalizarVendaPDV() {
  const [processando, setProcessando] = useState(false)

  /**
   * Finaliza a venda salvando no banco de dados e dando baixa no estoque
   *
   * Executa as seguintes operações:
   * 1. Prepara os dados da venda com itens e valores
   * 2. Salva a venda na tabela sales
   * 3. Dá baixa no estoque para cada produto vendido
   * 4. Retorna número da venda gerado
   *
   * @param params - Parâmetros completos da venda
   * @returns Promise com objeto contendo sucesso e numeroVenda ou erro
   */
  const finalizarVenda = async (params: FinalizarVendaParams) => {
    const {
      carrinho,
      subtotal,
      dadosPagamento,
      consumoInterno = false
      // desconto = 0,
      // tipoDesconto = 'valor'
    } = params

    try {
      setProcessando(true)

      // Calcular total simples (sem desconto e sem taxa de entrega)
      // Se for consumo interno, forçar total = 0
      const total = consumoInterno ? 0 : subtotal

      // Preparar itens da venda
      const itensVenda = carrinho.map(item => ({
        produto: {
          id: item.produto.id,
          nome: item.produto.nome,
          preco: item.produto.preco,
          custo: item.produto.custo || 0, // ✅ Incluir custo para cálculo de lucro
          categoria: item.produto.categoria,
          imagem_path: item.produto.urlImagem
        },
        quantidade: item.quantidade,
        saboresSelecionados: item.saboresSelecionados || undefined,
        bordaSelecionada: item.bordaSelecionada || undefined,
        tamanhoSelecionado: item.tamanhoSelecionado || undefined,
        adicionaisSelecionados: item.adicionaisSelecionados || undefined,
        observacoes: item.observacoes ? sanitizeFreeText(item.observacoes, 300) : undefined,
        produtosCombo: item.produtosCombo || undefined,
        precoUnitario: item.precoUnitario,
        precoTotal: item.precoTotal
      }))

      // Preparar dados da venda
      const dadosVenda: any = {
        total_amount: total, // Será 0 se consumo interno
        payment_method: consumoInterno ? 'INTERNAL_CONSUMPTION' : dadosPagamento.formaPagamento,
        needs_change: consumoInterno ? false : dadosPagamento.precisaTroco,
        change_amount: (consumoInterno || !dadosPagamento.precisaTroco) ? undefined : dadosPagamento.valorTroco,
        sale_type: consumoInterno ? 'INTERNAL_CONSUMPTION' : 'PDV',
        is_internal_consumption: consumoInterno, // Flag para rastreamento
        items: itensVenda,
        notes: consumoInterno 
          ? `Consumo interno - ${new Date().toLocaleString()}`
          : `Venda realizada via PDV - ${new Date().toLocaleString()}`
      }

      // VALIDAR ESTOQUE ANTES DE FINALIZAR VENDA.
      // Mesma regra usada pelas comandas e pelo delivery (respeita
      // produtos.requires_stock e valida por variante quando houver).
      await stockService.validarEstoqueVenda(
        carrinho.map(item => ({
          produtoId: item.produto.id,
          quantidade: item.quantidade,
          variantId: item.variantId,
          nome: item.produto.nome
        }))
      )

      // Salvar venda (só se estoque validado)
      const vendaSalva = await vendaService.salvar(dadosVenda)

      // Dar baixa no estoque para cada produto
      for (const item of carrinho) {
        try {
          // ✅ CORREÇÃO: Passar parâmetros na ordem correta, incluindo variantId
          await stockService.darBaixaEmVenda(
            item.produto.id,      // productId
            item.quantidade,      // quantity
            item.variantId,       // variantId (pode ser undefined)
            'SALE',               // refType
            vendaSalva.id         // refId (sale_id)
          )
        } catch (error) {
          // Se falhar baixa, erro crítico - não deve acontecer pois já validamos
          console.error(`ERRO CRÍTICO ao dar baixa no estoque do produto ${item.produto.nome}:`, error)
          throw new Error(`Falha ao dar baixa no estoque: ${error instanceof Error ? error.message : 'Erro desconhecido'}`)
        }
      }

      // IMPRESSÃO AUTOMÁTICA DO CUPOM FISCAL (se configurado)
      try {
        const configImpressaoAuto = await configuracaoService.buscarPorChave('impressao_automatica_pdv')
        const impressaoAutomaticaAtiva = configImpressaoAuto?.valor === 'true'

        console.log('🖨️ [PDV] Verificando impressão automática:', {
          configEncontrada: !!configImpressaoAuto,
          valorConfig: configImpressaoAuto?.valor,
          impressaoAtiva: impressaoAutomaticaAtiva,
          vendaId: vendaSalva.id
        })

        if (impressaoAutomaticaAtiva) {
          console.log('🖨️ [PDV] Iniciando impressão automática do cupom...')
          
          // Gerar cupom fiscal
          const cupomHTML = await receiptService.generateSaleReceipt(vendaSalva)
          console.log('✅ [PDV] Cupom HTML gerado com sucesso')

          // Criar print job
          await printJobService.create({
            refType: 'SALE',
            refId: vendaSalva.id,
            receiptHtml: cupomHTML
          })
          console.log('✅ [PDV] Print job criado no banco')

          // Tentar imprimir automaticamente
          await printJobService.print(vendaSalva.id, 'SALE')
          console.log('✅ [PDV] Impressão enviada com sucesso')
        } else {
          console.log('ℹ️ [PDV] Impressão automática desativada - pulando impressão')
        }
      } catch (errorImpressao) {
        // Não falhar a venda se impressão falhar, apenas logar
        console.warn('⚠️ [PDV] Falha na impressão automática do cupom, mas venda foi finalizada com sucesso:', errorImpressao)
      }

      return {
        sucesso: true,
        numeroVenda: vendaSalva.sale_number,
        vendaId: vendaSalva.id
      }
    } catch (error) {
      console.error('Erro ao finalizar venda:', error)
      return {
        sucesso: false,
        erro: error instanceof Error ? error.message : 'Erro ao finalizar venda. Tente novamente.'
      }
    } finally {
      setProcessando(false)
    }
  }

  return {
    processando,
    finalizarVenda
  }
}

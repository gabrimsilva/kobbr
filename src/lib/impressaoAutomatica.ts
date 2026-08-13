import { configuracaoService, type PedidoSupabase } from '@/services'
import { qzTrayService } from './qzTrayService'

/**
 * Serviço para gerenciar impressão automática de pedidos
 */
export const impressaoAutomaticaService = {
  /**
   * Verifica se a impressão automática está habilitada
   */
  async isHabilitada(): Promise<boolean> {
    try {
      const config = await configuracaoService.buscarPorChave('impressao_automatica_pedidos')
      return config?.valor === 'true'
    } catch (error) {
      console.error('Erro ao verificar impressão automática:', error)
      return false
    }
  },

  /**
   * Imprime automaticamente um pedido se a configuração estiver ativa
   */
  async imprimirPedido(pedido: PedidoSupabase): Promise<void> {
    try {
      // Verificar se impressão automática está habilitada
      const habilitada = await this.isHabilitada()

      if (!habilitada) {
        return
      }

      // NÃO imprimir pedidos aguardando pagamento (PIX)
      if (pedido.status === 'Aguardando pagamento') {
        return
      }

      // Buscar configurações de impressão
      const [configUsarQZ, configImpressora, configDensidade,
             fontBase, fontStoreName, fontSectionTitle, fontItemSub, fontTotals, fontTotalFinal] = await Promise.all([
        configuracaoService.buscarPorChave('usar_qz_tray'),
        configuracaoService.buscarPorChave('impressora_padrao'),
        configuracaoService.buscarPorChave('densidade_impressao'),
        configuracaoService.buscarPorChave('font_size_base'),
        configuracaoService.buscarPorChave('font_size_store_name'),
        configuracaoService.buscarPorChave('font_size_section_title'),
        configuracaoService.buscarPorChave('font_size_item_sub'),
        configuracaoService.buscarPorChave('font_size_totals'),
        configuracaoService.buscarPorChave('font_size_total_final')
      ])

      const usarQZTray = configUsarQZ?.valor === 'true'
      const impressoraPadrao = configImpressora?.valor || ''
      const densidadeImpressao = parseInt(configDensidade?.valor || '3')
      
      const fontSizes = {
        base: parseInt(fontBase?.valor || '11'),
        storeName: parseInt(fontStoreName?.valor || '16'),
        sectionTitle: parseInt(fontSectionTitle?.valor || '11'),
        itemSub: parseInt(fontItemSub?.valor || '10'),
        totals: parseInt(fontTotals?.valor || '12'),
        totalFinal: parseInt(fontTotalFinal?.valor || '14')
      }

      // Se QZ Tray não estiver habilitado ou impressora não configurada, não imprimir
      if (!usarQZTray || !impressoraPadrao) {
        return
      }

      // Buscar configurações da loja
      const [configNome, configEndereco, configTelefone] = await Promise.all([
        configuracaoService.buscarPorChave('nome_loja'),
        configuracaoService.buscarPorChave('endereco_loja'),
        configuracaoService.buscarPorChave('telefone_loja')
      ])

      const nomeEstabelecimento = configNome?.valor || 'Estabelecimento'
      const enderecoEstabelecimento = configEndereco?.valor || ''
      const telefoneEstabelecimento = configTelefone?.valor || ''

      // Gerar HTML para impressão
      const htmlThermal = this.gerarHTMLImpressao(
        pedido,
        nomeEstabelecimento,
        enderecoEstabelecimento,
        telefoneEstabelecimento,
        densidadeImpressao,
        fontSizes
      )

      // Imprimir
      await qzTrayService.printHTML(impressoraPadrao, htmlThermal)
    } catch (error) {
      console.error('❌ Erro ao imprimir pedido automaticamente:', error)
    }
  },

  /**
   * Gera o HTML para impressão térmica
   */
  gerarHTMLImpressao(
    pedido: PedidoSupabase,
    nomeEstabelecimento: string,
    enderecoEstabelecimento: string,
    telefoneEstabelecimento: string,
    densidadeImpressao: number,
    fontSizes: {
      base: number
      storeName: number
      sectionTitle: number
      itemSub: number
      totals: number
      totalFinal: number
    }
  ): string {
    const fontWeight = 200 + (densidadeImpressao * 100)
    const idCurto = pedido.codigo_pedido || pedido.pedido_id.split('-').pop()?.slice(-4) || pedido.pedido_id.slice(-4)

    const formatarFormaPagamento = (forma: string) => {
      const formas: { [key: string]: string } = {
        'dinheiro': 'Dinheiro',
        'cartao_credito': 'Cartão de Crédito',
        'cartao_debito': 'Cartão de Débito',
        'cartaoCredito': 'Cartão de Crédito',
        'cartaoDebito': 'Cartão de Débito',
        'pix': 'PIX',
        'pixEntrega': 'PIX na Entrega',
        'pix_entrega': 'PIX na Entrega',
        'cartaoVR': 'Cartão VR',
        'cartao_vr': 'Cartão VR',
        'cartaoVA': 'Cartão VA',
        'cartao_va': 'Cartão VA',
        'ticketPromo': 'Ticket Promocional',
        'ticket_promo': 'Ticket Promocional'
      }
      return formas[forma] || forma
    }

    const formatarHora = (dataISO: string) => {
      return new Date(dataISO).toLocaleString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }

    return `
<html>
<head>
  <style>
    @page { 
      size: 70mm auto; 
      margin: 0; 
    }
    @media print { 
      body { 
        margin: 0; 
        -webkit-print-color-adjust: exact; 
      } 
    }
    body {
      width: 70mm;
      font-family: "Courier New", Courier, monospace;
      font-size: ${fontSizes.base}px;
      color: #000;
      line-height: 1.2;
      word-break: break-word;
      padding: 2mm;
      margin: 0;
      font-weight: ${fontWeight};
    }
    .header { 
      text-align: center; 
      margin-bottom: 6px; 
    }
    .store-name { 
      font-size: ${fontSizes.storeName}px; 
      font-weight: ${Math.min(fontWeight + 200, 900)}; 
      letter-spacing: 1px; 
    }
    .store-address, .store-contact { 
      font-size: ${fontSizes.itemSub}px; 
    }
    .section-title { 
      font-weight: ${Math.min(fontWeight + 200, 900)}; 
      font-size: ${fontSizes.sectionTitle}px;
      margin-top: 6px; 
      margin-bottom: 4px; 
    }
    .divider { 
      border-top: 1px dashed #000; 
      margin: 6px 0; 
    }
    .info-block { 
      font-size: ${fontSizes.base}px; 
    }
    .info-row { 
      margin-bottom: 2px; 
    }
    .items { 
      margin-top: 4px; 
    }
    .item { 
      display: block; 
      margin-bottom: 4px; 
      width: 100%; 
    }
    .item-head { 
      display:flex; 
      justify-content:space-between; 
      align-items: flex-start;
    }
    .qty-name { 
      flex: 1;
      max-width: 58%; 
      white-space: normal; 
      padding-right: 1mm;
    }
    .price { 
      text-align: right; 
      white-space: nowrap;
      min-width: 32%;
    }
    .item-sub { 
      font-size: ${fontSizes.itemSub}px; 
      margin-left: 2mm; 
      margin-top: 2px; 
    }
    .totals { 
      margin-top: 6px; 
      font-size: ${fontSizes.totals}px; 
    }
    .totals .line { 
      display:flex; 
      justify-content:space-between; 
      align-items: flex-start;
      margin-bottom:2px; 
    }
    .totals .line > div:first-child {
      flex: 1;
      max-width: 58%;
      padding-right: 1mm;
    }
    .totals .line > div:last-child {
      white-space: nowrap;
      text-align: right;
      min-width: 32%;
    }
    .totals .total { 
      font-weight: ${Math.min(fontWeight + 200, 900)}; 
      font-size: ${fontSizes.totalFinal}px; 
    }
    .footer { 
      text-align:center; 
      margin-top:8px; 
      font-size: ${fontSizes.itemSub}px; 
    }
    .order-id { 
      font-size: ${fontSizes.totalFinal}px; 
      font-weight: ${Math.min(fontWeight + 200, 900)}; 
      text-align:center; 
      margin:6px 0; 
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="store-name">${nomeEstabelecimento}</div>
    <div class="store-address">${enderecoEstabelecimento}</div>
    <div class="store-contact">Tel: ${telefoneEstabelecimento}</div>
  </div>
  
  <div class="divider"></div>
  
  <div class="order-id">Detalhes do Pedido #${idCurto}</div>
  
  <div class="info-block">
    <div class="section-title">Dados Pessoais</div>
    <div class="info-row"><strong>Nome:</strong> ${pedido.cliente_nome} ${pedido.cliente_sobrenome}</div>
    <div class="info-row"><strong>Telefone:</strong> ${pedido.cliente_telefone}</div>
    ${pedido.cliente_email ? `<div class="info-row"><strong>Email:</strong> ${pedido.cliente_email}</div>` : ''}
    
    <div class="section-title">Dados de Entrega</div>
    <div class="info-row"><strong>Tipo:</strong> ${pedido.entrega_domicilio ? 'Entrega a Domicílio' : 'Retirada no Local'}</div>
    ${pedido.entrega_domicilio && pedido.cliente_endereco ? `
    <div class="info-row"><strong>Endereço:</strong> ${pedido.cliente_endereco}, ${pedido.cliente_numero}</div>
    ${pedido.cliente_complemento ? `<div class="info-row"><strong>Complemento:</strong> ${pedido.cliente_complemento}</div>` : ''}
    ${pedido.cliente_bairro ? `<div class="info-row"><strong>Bairro:</strong> ${pedido.cliente_bairro}</div>` : ''}
    ${pedido.cliente_cidade ? `<div class="info-row"><strong>Cidade:</strong> ${pedido.cliente_cidade} - ${pedido.cliente_estado}</div>` : ''}
    ${pedido.cliente_cep ? `<div class="info-row"><strong>CEP:</strong> ${pedido.cliente_cep}</div>` : ''}
    ` : ''}
    
    <div class="section-title">Dados do Pedido</div>
    <div class="info-row"><strong>Data/Hora:</strong> ${formatarHora(pedido.criado_em)}</div>
    <div class="info-row"><strong>Forma de Pagamento:</strong> ${formatarFormaPagamento(pedido.forma_pagamento)}</div>
    ${pedido.forma_pagamento === 'pix' && pedido.mercado_pago_date_approved ? `<div class="info-row"><strong>Aprovado em:</strong> ${formatarHora(pedido.mercado_pago_date_approved)}</div>` : ''}
    <div class="info-row"><strong>Status:</strong> ${pedido.forma_pagamento === 'pix' && pedido.mercado_pago_status === 'approved' ? 'Pedido pago com sucesso!' : 'Pedido há pagar'}</div>
    ${pedido.precisa_troco && pedido.valor_troco ? `<div class="info-row"><strong>Troco para:</strong> R$ ${pedido.valor_troco.toFixed(2).replace('.', ',')}</div>` : ''}
    ${pedido.observacoes ? `<div class="info-row"><strong>Observações:</strong> ${pedido.observacoes}</div>` : ''}
  </div>
  
  <div class="divider"></div>
  
  <div class="section-title">Itens</div>
  <div class="items">
    ${pedido.itens.map((item: any) => `
    <div class="item">
      <div class="item-head">
        <div class="qty-name">${item.quantidade}x ${item.produto.nome}</div>
        <div class="price">R$ ${(item.produto.preco * item.quantidade).toFixed(2).replace('.', ',')}</div>
      </div>
      ${item.tamanhoSelecionado ? `<div class="item-sub"><strong>Tamanho:</strong> ${item.tamanhoSelecionado.nome} (${item.tamanhoSelecionado.tamanho})</div>` : ''}
      ${item.saboresSelecionados && item.saboresSelecionados.length > 0 ? `<div class="item-sub"><strong>Sabores:</strong> ${item.saboresSelecionados.map((s: any) => s.nome).join(', ')}</div>` : ''}
      ${item.bordaSelecionada ? `<div class="item-sub"><strong>Borda:</strong> ${item.bordaSelecionada.nome}</div>` : ''}
      ${item.adicionaisSelecionados && item.adicionaisSelecionados.length > 0 ? `<div class="item-sub"><strong>Adicionais:</strong> ${item.adicionaisSelecionados.map((a: any) => `${a.quantidade}x ${a.nome} (+R$ ${(a.valor * a.quantidade).toFixed(2).replace('.', ',')})`).join(', ')}</div>` : ''}
      ${item.observacoes ? `<div class="item-sub"><strong>Obs:</strong> ${item.observacoes}</div>` : ''}
    </div>
    `).join('')}
  </div>
  
  <div class="divider"></div>
  
  <div class="totals">
    <div class="line">
      <div>Subtotal:</div>
      <div>R$ ${pedido.subtotal.toFixed(2).replace('.', ',')}</div>
    </div>
    ${pedido.taxa_entrega > 0 ? `
    <div class="line">
      <div>Taxa de entrega:</div>
      <div>R$ ${pedido.taxa_entrega.toFixed(2).replace('.', ',')}</div>
    </div>
    ` : ''}
    ${(pedido as any).taxa_extra_km > 0 ? `
    <div class="line">
      <div>Taxa extra (dist.):</div>
      <div>R$ ${(pedido as any).taxa_extra_km.toFixed(2).replace('.', ',')}</div>
    </div>
    ` : ''}
    <div class="line total">
      <div>Total:</div>
      <div>R$ ${pedido.total.toFixed(2).replace('.', ',')}</div>
    </div>
  </div>
  
  <div class="divider"></div>
  
  <div class="footer">
    Obrigado pela preferência!<br>
    Pedido gerado em ${formatarHora(pedido.criado_em)}
  </div>
</body>
</html>
    `
  }
}

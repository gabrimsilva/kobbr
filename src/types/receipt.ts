/**
 * Tipos para geração de cupom fiscal
 */

export interface ReceiptItem {
  nome: string
  quantidade: number
  precoUnitario: number
  precoTotal: number
  observacoes?: string
}

export interface ReceiptData {
  // Identificação
  tipo: 'SALE' | 'ORDER'
  numero: string
  data: string
  hora: string
  
  // Loja
  nomeLoja: string
  enderecoLoja?: string
  telefoneLoja?: string
  
  // Cliente (apenas para pedidos)
  clienteNome?: string
  clienteTelefone?: string
  clienteEndereco?: string
  
  // Itens
  itens: ReceiptItem[]
  
  // Valores
  subtotal: number
  desconto?: number
  taxaEntrega?: number
  total: number
  
  // Pagamento
  formaPagamento: string
  precisaTroco?: boolean
  valorTroco?: number
  
  // Observações
  observacoes?: string
  
  // Status (para pedidos)
  status?: string
}

export interface ReceiptConfig {
  // Tamanhos de fonte (em pixels)
  fontSizeBase?: number
  fontSizeStoreName?: number
  fontSizeSectionTitle?: number
  fontSizeItemSub?: number
  fontSizeTotals?: number
  fontSizeTotalFinal?: number
  
  // Densidade de impressão (1-5)
  densidade?: number
  
  // Largura do papel (em mm)
  paperWidth?: number
}

import { Button } from "@/components/ui/button"
import { DangerButton } from "@/components/ui/danger-button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { ShoppingCart, Trash2, Plus, Minus, CheckCircle, MessageSquare } from "lucide-react"
import { type ItemCarrinhoPDV, type DadosClientePDV } from "./types"
import { renderizarDetalhesCombo } from "@/utils/comboFormatacao"

/**
 * Props para o componente CarrinhoPDV
 */
interface CarrinhoPDVProps {
  /** Lista de itens no carrinho */
  carrinho: ItemCarrinhoPDV[]
  /** Callback para adicionar/incrementar item no carrinho */
  onAdicionarItem: (produtoId: string, index?: number) => void
  /** Callback para remover/decrementar item do carrinho */
  onRemoverItem: (produtoId: string, index?: number) => void
  /** Callback para limpar todo o carrinho */
  onLimparCarrinho: () => void
  /** Indica se é entrega a domicílio */
  entregaDomicilio: boolean
  /** Função para alterar tipo de entrega */
  setEntregaDomicilio: (entrega: boolean) => void
  /** Valor da taxa de entrega */
  taxaEntrega: number
  /** Valor da taxa extra por km */
  taxaExtraKm?: number
  /** Dados do cliente */
  dadosCliente: DadosClientePDV
  /** Callback para abrir modal de dados do cliente */
  onAbrirModalCliente: () => void
  /** Callback para finalizar o pedido */
  onFinalizarPedido: () => void
  /** Modo simplificado (sem desconto) */
  simplified?: boolean
}

/**
 * Componente de carrinho de compras para o PDV
 * 
 * Exibe os itens adicionados ao carrinho com controles de quantidade,
 * resumo de valores, opção de entrega/retirada e botões para
 * gerenciar dados do cliente e finalizar o pedido.
 * 
 * @example
 * ```tsx
 * <CarrinhoPDV
 *   carrinho={carrinho}
 *   onAdicionarItem={adicionarItem}
 *   onRemoverItem={removerItem}
 *   onLimparCarrinho={limparCarrinho}
 *   entregaDomicilio={entregaDomicilio}
 *   setEntregaDomicilio={setEntregaDomicilio}
 *   taxaEntrega={5.00}
 *   dadosCliente={dadosCliente}
 *   onAbrirModalCliente={() => setModalAberto(true)}
 *   onFinalizarPedido={finalizarPedido}
 * />
 * ```
 */
export default function CarrinhoPDV({
  carrinho,
  onAdicionarItem,
  onRemoverItem,
  onLimparCarrinho,
  entregaDomicilio,
  taxaEntrega,
  taxaExtraKm = 0,
  onFinalizarPedido
}: CarrinhoPDVProps) {
  const subtotal = carrinho.reduce((total, item) => total + item.precoTotal, 0)
  const valorTaxaEntrega = entregaDomicilio ? taxaEntrega : 0
  const valorTaxaExtraKm = entregaDomicilio ? taxaExtraKm : 0
  
  // Cálculo simplificado sem desconto
  const total = subtotal + valorTaxaEntrega + valorTaxaExtraKm

  return (
    <div className="space-y-6">
      {/* Carrinho */}
      <Card>
        <CardHeader className="pb-3 md:pb-6">
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2 text-lg md:text-xl">
              <ShoppingCart className="h-4 w-4 md:h-5 md:w-5" />
              Carrinho ({carrinho.length})
            </CardTitle>
            {carrinho.length > 0 && (
              <DangerButton
                variant="ghost"
                size="sm"
                onClick={onLimparCarrinho}
              >
                <Trash2 className="h-4 w-4" />
              </DangerButton>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {carrinho.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <ShoppingCart className="h-12 w-12 mx-auto mb-4 text-gray-300" />
              <p>Carrinho vazio</p>
            </div>
          ) : (
            <div className="space-y-3">
              {carrinho.map((item, index) => (
                <div key={`${item.produto.id}-${index}`} className="flex items-center gap-2 md:gap-3 p-2 md:p-3 bg-gray-50 rounded-lg">
                  <img
                    src={item.produto.urlImagem}
                    alt={item.produto.nome}
                    className="w-10 h-10 md:w-12 md:h-12 object-cover rounded"
                  />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-xs md:text-sm truncate">
                      {item.produto.nome}
                      {item.variantLabel && ` - ${item.variantLabel}`}
                    </p>
                    
                    {/* Renderizar detalhes do combo se for um combo */}
                    {renderizarDetalhesCombo(item)}
                    
                    {/* Renderizar detalhes normais se não for combo */}
                    {!item.produtosCombo && (
                      <>
                        {item.tamanhoSelecionado && (
                          <p className="text-xs text-gray-500">
                            Tamanho: {item.tamanhoSelecionado.nome} ({item.tamanhoSelecionado.tamanho})
                          </p>
                        )}
                        {item.saboresSelecionados && item.saboresSelecionados.length > 0 && (
                          <p className="text-xs text-gray-500">
                            Sabores: {item.saboresSelecionados.map((s: any) => s.nome).join(', ')}
                          </p>
                        )}
                        {item.bordaSelecionada && (
                          <p className="text-xs text-gray-500">
                            Borda: {item.bordaSelecionada.nome}
                          </p>
                        )}
                        {item.adicionaisSelecionados && item.adicionaisSelecionados.length > 0 && (
                          <p className="text-xs text-gray-500">
                            Adicionais: {item.adicionaisSelecionados.map((a: any) => `${a.quantidade}x ${a.nome}`).join(', ')}
                          </p>
                        )}
                        {item.observacoes && (
                          <p className="text-xs text-gray-500 italic">
                            <MessageSquare className="inline h-3 w-3 mr-1" />
                            Obs: {item.observacoes}
                          </p>
                        )}
                      </>
                    )}
                    
                    <p className="text-xs text-gray-600">
                      R$ {item.precoUnitario.toFixed(2).replace('.', ',')} x {item.quantidade}
                    </p>
                    <p className="font-bold text-sm text-[color:var(--price-color)]">
                      R$ {item.precoTotal.toFixed(2).replace('.', ',')}
                    </p>
                  </div>
                  <div className="flex items-center gap-1">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => onRemoverItem(item.produto.id, (item.saboresSelecionados || item.tamanhoSelecionado || item.bordaSelecionada || item.adicionaisSelecionados) ? index : undefined)}
                      className="h-8 w-8 p-0"
                    >
                      <Minus className="h-3 w-3" />
                    </Button>
                    <span className="w-8 text-center text-sm">{item.quantidade}</span>
                    <Button
                      size="sm"
                      onClick={() => onAdicionarItem(item.produto.id, (item.saboresSelecionados || item.tamanhoSelecionado || item.bordaSelecionada || item.adicionaisSelecionados) ? index : undefined)}
                      className="h-8 w-8 p-0"
                    >
                      <Plus className="h-3 w-3" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Resumo do Pedido */}
      {carrinho.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Resumo</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {/* Resumo Simplificado - apenas total */}
            <div className="space-y-2">
              <div className="border-t pt-2">
                <div className="flex justify-between text-lg font-bold">
                  <span>Total:</span>
                  <span className="text-green-600">R$ {total.toFixed(2).replace('.', ',')}</span>
                </div>
              </div>
            </div>

            <Button
              className="w-full"
              onClick={onFinalizarPedido}
            >
              <CheckCircle className="h-4 w-4 mr-2" />
              Finalizar Pedido
            </Button>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
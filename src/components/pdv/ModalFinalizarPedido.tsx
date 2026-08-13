import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Separator } from "@/components/ui/separator"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import { CreditCard, AlertTriangle } from "lucide-react"

interface ModalFinalizarPedidoProps {
  isOpen: boolean
  onClose: () => void
  onConfirmar: (dadosPagamento: {
    formaPagamento: string
    precisaTroco: boolean
    valorTroco?: number
    consumoInterno?: boolean
  }) => void
  subtotal: number
  taxaEntrega: number
  taxaExtraKm?: number
  total: number
  entregaDomicilio: boolean
  processando: boolean
  simplified?: boolean // Nova prop para modo simplificado
  carrinhoVazio?: boolean // Prop para indicar se carrinho está vazio
}

export default function ModalFinalizarPedido({
  isOpen,
  onClose,
  onConfirmar,
  subtotal,
  total,
  processando,
  carrinhoVazio = false
}: ModalFinalizarPedidoProps) {
  const [formaPagamento, setFormaPagamento] = useState('dinheiro')
  const [precisaTroco, setPrecisaTroco] = useState(false)
  const [valorTroco, setValorTroco] = useState('')
  const [consumoInterno, setConsumoInterno] = useState(false)
  const [mostrarConfirmacaoConsumo, setMostrarConfirmacaoConsumo] = useState(false)

  // 🔧 FIX: Resetar estado quando o modal fecha (isOpen muda para false)
  useEffect(() => {
    if (!isOpen) {
      setFormaPagamento('dinheiro')
      setPrecisaTroco(false)
      setValorTroco('')
      setConsumoInterno(false)
      setMostrarConfirmacaoConsumo(false)
    }
  }, [isOpen])

  // Forçar recalcular total e estado quando consumoInterno muda
  const totalExibido = consumoInterno ? 0 : total
  const formaPagamentoExibida = consumoInterno ? 'interno' : formaPagamento
  const clienteDesabilitado = consumoInterno
  const pagamentoDesabilitado = consumoInterno

  const handleConfirmar = () => {
    // Validações
    if (consumoInterno && carrinhoVazio) {
      alert('Adicione itens ao carrinho para registrar consumo interno')
      return
    }

    // Confirmação adicional para consumo interno - mostrar modal customizado
    if (consumoInterno) {
      setMostrarConfirmacaoConsumo(true)
      return
    }

    // Finalizar venda normal
    finalizarVenda()
  }

  const finalizarVenda = () => {
    onConfirmar({
      formaPagamento: formaPagamentoExibida,
      precisaTroco: consumoInterno ? false : precisaTroco,
      valorTroco: precisaTroco && !consumoInterno ? parseFloat(valorTroco) || 0 : undefined,
      consumoInterno
    })
  }

  const handleConfirmarConsumoInterno = () => {
    setMostrarConfirmacaoConsumo(false)
    finalizarVenda()
  }

  const handleCancelarConsumoInterno = () => {
    setMostrarConfirmacaoConsumo(false)
  }

  // Resetar quando modal fecha
  const handleClose = () => {
    setFormaPagamento('dinheiro')
    setPrecisaTroco(false)
    setValorTroco('')
    setConsumoInterno(false)
    setMostrarConfirmacaoConsumo(false)
    onClose()
  }

  return (
    <>
      {/* Modal de Confirmação de Consumo Interno */}
      <AlertDialog open={mostrarConfirmacaoConsumo} onOpenChange={setMostrarConfirmacaoConsumo}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center gap-2 text-orange-600">
              <AlertTriangle className="h-5 w-5" />
              Confirmar Consumo Interno
            </AlertDialogTitle>
            <AlertDialogDescription className="space-y-3 pt-2">
              <p className="text-base font-semibold text-gray-900">
                Deseja realmente registrar esta venda como CONSUMO INTERNO?
              </p>
              
              <div className="space-y-2 text-sm">
                <div className="flex items-start gap-2">
                  <span className="text-orange-600">•</span>
                  <span>Esta venda <strong>NÃO será cobrada</strong> (R$ 0,00)</span>
                </div>
                <div className="flex items-start gap-2">
                  <span className="text-orange-600">•</span>
                  <span>O estoque <strong>será reduzido normalmente</strong></span>
                </div>
                <div className="flex items-start gap-2">
                  <span className="text-orange-600">•</span>
                  <span>Esta operação <strong>não pode ser desfeita</strong></span>
                </div>
              </div>

              <div className="mt-4 p-3 bg-orange-50 border border-orange-200 rounded-lg">
                <p className="text-sm text-orange-800">
                  ⚠️ Confirme apenas se esta venda é realmente para consumo interno da equipe.
                </p>
              </div>
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={handleCancelarConsumoInterno}>
              Cancelar
            </AlertDialogCancel>
            <AlertDialogAction 
              onClick={handleConfirmarConsumoInterno}
              className="bg-orange-600 hover:bg-orange-700"
            >
              Sim, Registrar como Consumo Interno
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Modal Principal de Finalizar Pedido */}
      <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="max-md:!top-0 max-md:!left-0 max-md:!translate-x-0 max-md:!translate-y-0 max-md:!max-w-full max-md:!w-full max-md:!h-full max-md:!max-h-full max-md:!rounded-none max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <CreditCard className="h-5 w-5" />
            Finalizar Pedido
          </DialogTitle>
          <DialogDescription>
            {consumoInterno 
              ? 'Registrar consumo interno - Sem cobrança' 
              : 'Confirme os dados do pagamento'}
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4">
          {/* Checkbox Consumo Interno - Seção separada */}
          <div className={`p-4 rounded-lg border-2 ${consumoInterno 
            ? 'bg-blue-50 border-blue-300' 
            : 'bg-gray-50 border-gray-200'}`}>
            <div className="flex items-center space-x-3">
              <input
                type="checkbox"
                id="consumoInterno"
                checked={consumoInterno}
                onChange={(e) => setConsumoInterno(e.target.checked)}
                disabled={processando}
                className="w-5 h-5 cursor-pointer accent-blue-600"
              />
              <label htmlFor="consumoInterno" className="cursor-pointer flex-1">
                <div className="font-semibold text-gray-900">Consumo Interno</div>
                <div className="text-sm text-gray-600">
                  Marcar para registrar como consumo interno (sem cobrança)
                </div>
              </label>
            </div>
          </div>

          {consumoInterno && (
            <div className="p-3 bg-blue-100 border border-blue-300 rounded-lg text-sm text-blue-900">
              ✓ Consumo interno ativado - Total será R$ 0,00 e estoque será reduzido normalmente
            </div>
          )}

          <Separator />

          {/* Forma de Pagamento - Desabilitada se consumo interno */}
          <div>
            <Label 
              htmlFor="formaPagamento"
              className={clienteDesabilitado ? 'text-gray-500' : ''}
            >
              Forma de Pagamento
            </Label>
            <select 
              className={`w-full px-3 py-2 border border-gray-300 rounded-md ${
                clienteDesabilitado 
                  ? 'bg-gray-100 cursor-not-allowed opacity-60' 
                  : 'bg-white'
              }`}
              value={formaPagamentoExibida} 
              onChange={(e) => !consumoInterno && setFormaPagamento(e.target.value)}
              disabled={pagamentoDesabilitado || processando}
            >
              {!consumoInterno && (
                <>
                  <option value="dinheiro">Dinheiro</option>
                  <option value="cartaoDebito">Cartão de Débito</option>
                  <option value="cartaoCredito">Cartão de Crédito</option>
                  <option value="pix">PIX</option>
                </>
              )}
              {consumoInterno && (
                <option value="interno">Consumo Interno (Sem Pagamento)</option>
              )}
            </select>
            {consumoInterno && (
              <p className="text-xs text-gray-600 mt-1">
                Campo desabilitado para consumo interno
              </p>
            )}
          </div>

          {formaPagamento === 'dinheiro' && !consumoInterno && (
            <div className="space-y-3">
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="precisaTroco"
                  checked={precisaTroco}
                  onChange={(e) => setPrecisaTroco(e.target.checked)}
                  disabled={processando}
                />
                <Label htmlFor="precisaTroco">Cliente precisa de troco</Label>
              </div>
              
              {precisaTroco && (
                <div className="space-y-3 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                  <div>
                    <Label htmlFor="valorTroco">Valor pago (troco para)</Label>
                    <Input
                      id="valorTroco"
                      type="number"
                      step="0.01"
                      value={valorTroco}
                      onChange={(e) => setValorTroco(e.target.value)}
                      placeholder="0,00"
                    />
                  </div>
                  
                  {/* Exibir troco calculado */}
                  {valorTroco && parseFloat(valorTroco) > 0 && (
                    <div className="p-3 bg-white rounded border border-blue-300 space-y-1">
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Total do pedido:</span>
                        <span className="font-semibold">R$ {total.toFixed(2).replace('.', ',')}</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Valor pago:</span>
                        <span className="font-semibold">R$ {parseFloat(valorTroco).toFixed(2).replace('.', ',')}</span>
                      </div>
                      <div className="border-t pt-2 flex justify-between">
                        <span className="font-semibold text-green-700">Troco:</span>
                        <span className="font-bold text-green-700 text-lg">
                          R$ {(parseFloat(valorTroco) - total).toFixed(2).replace('.', ',')}
                        </span>
                      </div>
                      {parseFloat(valorTroco) < total && (
                        <div className="text-xs text-red-600 mt-2">
                          ⚠️ Valor pago é menor que o total!
                        </div>
                      )}
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          <Separator />

          {/* Resumo Simplificado - PDV */}
          <div className={`p-4 rounded-lg space-y-2 ${consumoInterno 
            ? 'bg-blue-50 border border-blue-200' 
            : 'bg-gray-50'}`}>
            <div className="flex justify-between">
              <span>Subtotal:</span>
              <span>R$ {subtotal.toFixed(2).replace('.', ',')}</span>
            </div>
            <Separator />
            <div className="flex justify-between text-lg font-bold">
              <span>Total:</span>
              <span className={consumoInterno ? 'text-blue-600' : 'text-green-600'}>
                R$ {totalExibido.toFixed(2).replace('.', ',')}
              </span>
            </div>
            {consumoInterno && (
              <div className="text-xs text-blue-700 pt-2">
                Total zerado devido ao consumo interno
              </div>
            )}
          </div>
        </div>

        <DialogFooter>
          <Button 
            variant="outline" 
            onClick={handleClose} 
            disabled={processando}
          >
            Cancelar
          </Button>
          <Button 
            onClick={handleConfirmar} 
            disabled={processando || (consumoInterno && carrinhoVazio)}
            title={consumoInterno && carrinhoVazio ? 'Adicione itens ao carrinho' : ''}
          >
            {processando ? 'Processando...' : 'Confirmar Pedido'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
    </>
  )
}
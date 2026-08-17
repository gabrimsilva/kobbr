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
import { CreditCard } from "lucide-react"

interface ModalFinalizarPedidoProps {
  isOpen: boolean
  onClose: () => void
  onConfirmar: (dadosPagamento: {
    formaPagamento: string
    precisaTroco: boolean
    valorTroco?: number
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
  processando
}: ModalFinalizarPedidoProps) {
  const [formaPagamento, setFormaPagamento] = useState('dinheiro')
  const [precisaTroco, setPrecisaTroco] = useState(false)
  const [valorTroco, setValorTroco] = useState('')

  // 🔧 FIX: Resetar estado quando o modal fecha (isOpen muda para false)
  useEffect(() => {
    if (!isOpen) {
      setFormaPagamento('dinheiro')
      setPrecisaTroco(false)
      setValorTroco('')
    }
  }, [isOpen])

  const handleConfirmar = () => {
    // Finalizar venda
    onConfirmar({
      formaPagamento,
      precisaTroco,
      valorTroco: precisaTroco ? parseFloat(valorTroco) || 0 : undefined
    })
  }

  // Resetar quando modal fecha
  const handleClose = () => {
    setFormaPagamento('dinheiro')
    setPrecisaTroco(false)
    setValorTroco('')
    onClose()
  }

  return (
    <>
      {/* Modal Principal de Finalizar Pedido */}
      <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="max-md:!top-0 max-md:!left-0 max-md:!translate-x-0 max-md:!translate-y-0 max-md:!max-w-full max-md:!w-full max-md:!h-full max-md:!max-h-full max-md:!rounded-none max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <CreditCard className="h-5 w-5" />
            Finalizar Pedido
          </DialogTitle>
          <DialogDescription>
            Confirme os dados do pagamento
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4">
          {/* Forma de Pagamento */}
          <div>
            <Label htmlFor="formaPagamento">
              Forma de Pagamento
            </Label>
            <select 
              className="w-full px-3 py-2 border border-gray-300 rounded-md bg-white"
              value={formaPagamento} 
              onChange={(e) => setFormaPagamento(e.target.value)}
              disabled={processando}
            >
              <option value="dinheiro">Dinheiro</option>
              <option value="cartaoDebito">Cartão de Débito</option>
              <option value="cartaoCredito">Cartão de Crédito</option>
              <option value="pix">PIX</option>
            </select>
          </div>

          {formaPagamento === 'dinheiro' && (
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
          <div className="p-4 rounded-lg space-y-2 bg-gray-50">
            <div className="flex justify-between">
              <span>Subtotal:</span>
              <span>R$ {subtotal.toFixed(2).replace('.', ',')}</span>
            </div>
            <Separator />
            <div className="flex justify-between text-lg font-bold">
              <span>Total:</span>
              <span className="text-green-600">
                R$ {total.toFixed(2).replace('.', ',')}
              </span>
            </div>
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
            disabled={processando}
          >
            {processando ? 'Processando...' : 'Confirmar Pedido'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
    </>
  )
}
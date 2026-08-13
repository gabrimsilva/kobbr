/**
 * Componente de Pagamento Dividido para Comandas
 * 
 * @deprecated Não utilizado no PDV simplificado (desde 31/01/2026)
 * @usage Utilizado em: Comandas
 * @reactivation Para reativar no PDV, consulte PLANO_LIMPEZA_SISTEMA.md seção 5.1
 * 
 * Este componente foi removido do fluxo PDV simplificado para reduzir complexidade.
 * Continua sendo utilizado em Comandas para dividir pagamento entre 2 formas diferentes.
 * 
 * Permite dividir o pagamento de um pedido entre duas formas de pagamento diferentes,
 * com validação automática de valores e tipos.
 * 
 * @module PagamentoDividido
 */

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { AlertCircle } from "lucide-react"
import type { SplitPaymentData } from "@/types/supabase"

interface PagamentoDividoProps {
  totalPedido: number
  onConfirm: (data: SplitPaymentData) => void
  onCancel: () => void
  formasPagamento: string[]
}

interface ValidationErrors {
  tiposDuplicados?: string
  somaIncorreta?: string
  camposVazios?: string
}

export default function PagamentoDividido({
  totalPedido,
  onConfirm,
  onCancel,
  formasPagamento
}: PagamentoDividoProps) {
  const [pagamento1Tipo, setPagamento1Tipo] = useState<string>("")
  const [pagamento1Valor, setPagamento1Valor] = useState<string>("")
  const [pagamento2Tipo, setPagamento2Tipo] = useState<string>("")
  const [pagamento2Valor, setPagamento2Valor] = useState<string>("")
  const [errors, setErrors] = useState<ValidationErrors>({})

  // Formatar valor como moeda brasileira
  const formatarMoeda = (valor: number): string => {
    return valor.toLocaleString('pt-BR', {
      style: 'currency',
      currency: 'BRL'
    })
  }

  // Parse valor do input (aceita vírgula ou ponto como separador decimal)
  const parseValor = (valor: string): number => {
    if (!valor) return 0
    const valorLimpo = valor.replace(/[^\d,.-]/g, '').replace(',', '.')
    return parseFloat(valorLimpo) || 0
  }

  // Validação em tempo real
  useEffect(() => {
    const newErrors: ValidationErrors = {}
    
    const valor1 = parseValor(pagamento1Valor)
    const valor2 = parseValor(pagamento2Valor)

    // Validar campos vazios ou zero
    if (!pagamento1Tipo || !pagamento2Tipo || valor1 <= 0 || valor2 <= 0) {
      if (pagamento1Tipo || pagamento2Tipo || pagamento1Valor || pagamento2Valor) {
        newErrors.camposVazios = "Todos os campos devem ser preenchidos com valores maiores que zero"
      }
    }

    // Validar tipos duplicados
    if (pagamento1Tipo && pagamento2Tipo && pagamento1Tipo === pagamento2Tipo) {
      newErrors.tiposDuplicados = "As formas de pagamento devem ser diferentes"
    }

    // Validar soma dos valores
    if (valor1 > 0 && valor2 > 0) {
      const soma = valor1 + valor2
      const diferenca = Math.abs(soma - totalPedido)
      
      if (diferenca > 0.01) { // Tolerância para erros de arredondamento
        const diferencaFormatada = formatarMoeda(Math.abs(totalPedido - soma))
        const somaFormatada = formatarMoeda(soma)
        const totalFormatado = formatarMoeda(totalPedido)
        
        newErrors.somaIncorreta = `A soma dos valores (${somaFormatada}) deve ser igual ao total do pedido (${totalFormatado}). Diferença: ${diferencaFormatada}`
      }
    }

    setErrors(newErrors)
  }, [pagamento1Tipo, pagamento1Valor, pagamento2Tipo, pagamento2Valor, totalPedido])

  // Calcular valores para exibição
  const valor1 = parseValor(pagamento1Valor)
  const valor2 = parseValor(pagamento2Valor)
  const totalConfigurado = valor1 + valor2
  const diferenca = totalPedido - totalConfigurado

  // Verificar se pode confirmar
  const podeConfirmar = 
    pagamento1Tipo && 
    pagamento2Tipo && 
    valor1 > 0 && 
    valor2 > 0 && 
    Object.keys(errors).length === 0

  const handleConfirmar = () => {
    if (podeConfirmar) {
      onConfirm({
        formaPagamentoDividido: true,
        pagamento1Tipo,
        pagamento1Valor: valor1,
        pagamento2Tipo,
        pagamento2Valor: valor2
      })
    }
  }

  // Formatar input enquanto digita
  const handleValorChange = (
    valor: string, 
    setter: (value: string) => void
  ) => {
    // Permitir apenas números, vírgula e ponto
    const valorLimpo = valor.replace(/[^\d,.-]/g, '')
    setter(valorLimpo)
  }

  return (
    <div className="space-y-3">
      <div className="bg-indigo-50 border border-indigo-200 rounded-md p-2">
        <p className="text-xs text-indigo-800">
          Configure as duas formas de pagamento. A soma deve ser igual ao total do pedido: {formatarMoeda(totalPedido)}
        </p>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {/* Pagamento 1 */}
        <div className="space-y-2 p-3 border border-gray-200 rounded-md">
          <h4 className="font-medium text-xs">Pagamento 1</h4>
          
          <div>
            <Label htmlFor="pagamento1Tipo" className="text-xs">Forma de Pagamento</Label>
            <select
              id="pagamento1Tipo"
              className="w-full px-2 py-1.5 text-sm border border-gray-300 rounded-md"
              value={pagamento1Tipo}
              onChange={(e) => setPagamento1Tipo(e.target.value)}
            >
              <option value="">Selecione...</option>
              {formasPagamento.map((forma) => (
                <option key={forma} value={forma}>
                  {forma}
                </option>
              ))}
            </select>
          </div>

          <div>
            <Label htmlFor="pagamento1Valor" className="text-xs">Valor</Label>
            <Input
              id="pagamento1Valor"
              type="text"
              placeholder="0,00"
              className="h-8 text-sm"
              value={pagamento1Valor}
              onChange={(e) => handleValorChange(e.target.value, setPagamento1Valor)}
            />
            {valor1 > 0 && (
              <p className="text-xs text-gray-500 mt-0.5">
                {formatarMoeda(valor1)}
              </p>
            )}
          </div>
        </div>

        {/* Pagamento 2 */}
        <div className="space-y-2 p-3 border border-gray-200 rounded-md">
          <h4 className="font-medium text-xs">Pagamento 2</h4>
          
          <div>
            <Label htmlFor="pagamento2Tipo" className="text-xs">Forma de Pagamento</Label>
            <select
              id="pagamento2Tipo"
              className="w-full px-2 py-1.5 text-sm border border-gray-300 rounded-md"
              value={pagamento2Tipo}
              onChange={(e) => setPagamento2Tipo(e.target.value)}
            >
              <option value="">Selecione...</option>
              {formasPagamento.map((forma) => (
                <option key={forma} value={forma}>
                  {forma}
                </option>
              ))}
            </select>
          </div>

          <div>
            <Label htmlFor="pagamento2Valor" className="text-xs">Valor</Label>
            <Input
              id="pagamento2Valor"
              type="text"
              placeholder="0,00"
              className="h-8 text-sm"
              value={pagamento2Valor}
              onChange={(e) => handleValorChange(e.target.value, setPagamento2Valor)}
            />
            {valor2 > 0 && (
              <p className="text-xs text-gray-500 mt-0.5">
                {formatarMoeda(valor2)}
              </p>
            )}
          </div>
        </div>
      </div>

      {/* Resumo de valores - mais compacto */}
      <div className="bg-gray-50 border border-gray-200 rounded-md p-2">
        <div className="grid grid-cols-3 gap-2 text-xs">
          <div className="text-center">
            <div className="text-gray-600">Configurado</div>
            <div className="font-medium">{formatarMoeda(totalConfigurado)}</div>
          </div>
          <div className="text-center border-x border-gray-300">
            <div className="text-gray-600">Total</div>
            <div className="font-medium">{formatarMoeda(totalPedido)}</div>
          </div>
          <div className="text-center">
            <div className="text-gray-600">Diferença</div>
            <div className={`font-medium ${diferenca === 0 ? 'text-green-600' : 'text-red-600'}`}>
              {totalConfigurado > 0 ? (
                diferenca === 0 ? '✓' : formatarMoeda(Math.abs(diferenca))
              ) : '-'}
            </div>
          </div>
        </div>
      </div>

      {/* Mensagens de erro - mais compactas */}
      {Object.keys(errors).length > 0 && (
        <div className="space-y-1.5">
          {errors.tiposDuplicados && (
            <div className="flex items-start gap-1.5 text-xs text-red-600 bg-red-50 border border-red-200 rounded-md p-2">
              <AlertCircle className="h-3.5 w-3.5 mt-0.5 flex-shrink-0" />
              <span>{errors.tiposDuplicados}</span>
            </div>
          )}
          {errors.somaIncorreta && (
            <div className="flex items-start gap-1.5 text-xs text-red-600 bg-red-50 border border-red-200 rounded-md p-2">
              <AlertCircle className="h-3.5 w-3.5 mt-0.5 flex-shrink-0" />
              <span>{errors.somaIncorreta}</span>
            </div>
          )}
          {errors.camposVazios && (
            <div className="flex items-start gap-1.5 text-xs text-red-600 bg-red-50 border border-red-200 rounded-md p-2">
              <AlertCircle className="h-3.5 w-3.5 mt-0.5 flex-shrink-0" />
              <span>{errors.camposVazios}</span>
            </div>
          )}
        </div>
      )}

      {/* Botões de ação */}
      <div className="flex gap-2 justify-end pt-1">
        <Button variant="outline" onClick={onCancel} size="sm">
          Cancelar
        </Button>
        <Button 
          onClick={handleConfirmar} 
          disabled={!podeConfirmar}
          size="sm"
        >
          Confirmar Pagamento Dividido
        </Button>
      </div>
    </div>
  )
}

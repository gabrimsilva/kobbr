/**
 * Campo de entrada de desconto manual para Comandas
 * 
 * @deprecated Não utilizado no PDV simplificado (desde 31/01/2026)
 * @usage Utilizado em: Comandas
 * @reactivation Para reativar no PDV, consulte PLANO_LIMPEZA_SISTEMA.md seção 5.1
 * 
 * Este componente foi removido do fluxo PDV simplificado para reduzir complexidade.
 * Continua sendo utilizado em Comandas para aplicar descontos manuais.
 * 
 * Permite que operadores apliquem descontos em pedidos,
 * alternando entre desconto em valor absoluto (R$) ou percentual (%).
 * Inclui validação de limites e exibição de mensagens de erro.
 * 
 * @module CampoDesconto
 */

import type { DescontoInput } from '@/types/supabase'
import { Label } from '@/components/ui/label'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'

/**
 * Props do componente CampoDesconto
 */
interface CampoDescontoProps {
  /** Objeto com valor e tipo do desconto atual */
  desconto: DescontoInput
  /** Subtotal do pedido (usado para validação de limite) */
  subtotal: number
  /** Callback chamado quando o desconto é alterado */
  onChange: (desconto: DescontoInput) => void
  /** Mensagem de erro de validação (opcional) */
  erro?: string
}

/**
 * Componente para entrada de desconto manual
 * 
 * Permite alternar entre desconto em valor (R$) ou percentual (%).
 * Valida limites baseados no tipo de desconto:
 * - Valor: 0 até subtotal
 * - Percentual: 0 até 100
 * 
 * @param props - Propriedades do componente
 * @returns Elemento React com campo de desconto
 * 
 * @example
 * ```tsx
 * <CampoDesconto
 *   desconto={{ valor: 10, tipo: 'valor' }}
 *   subtotal={100}
 *   onChange={(desconto) => setDesconto(desconto)}
 *   erro={erroDesconto}
 * />
 * ```
 */
export function CampoDesconto({
  desconto,
  subtotal,
  onChange,
  erro,
}: CampoDescontoProps) {
  const handleValorChange = (valor: number) => {
    onChange({ ...desconto, valor })
  }

  const handleTipoChange = (tipo: 'valor' | 'percentual') => {
    onChange({ valor: desconto.valor, tipo })
  }

  return (
    <div className="space-y-2">
      <div className="grid grid-cols-[120px_1fr] gap-2">
        <div className="space-y-2">
          <Label htmlFor="desconto-tipo">Desconto</Label>
          <Select
            value={desconto.tipo}
            onValueChange={(value) => handleTipoChange(value as 'valor' | 'percentual')}
          >
            <SelectTrigger id="desconto-tipo" className="w-full h-9">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="valor">R$</SelectItem>
              <SelectItem value="percentual">%</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-2">
          <Label htmlFor="desconto-input">Valor ou Porcentagem</Label>
          <Input
            id="desconto-input"
            type="number"
            min="0"
            step={desconto.tipo === 'valor' ? '0.01' : '1'}
            max={desconto.tipo === 'valor' ? subtotal : 100}
            value={desconto.valor}
            onChange={(e) => handleValorChange(Number(e.target.value))}
            placeholder="0"
            className="w-full"
            aria-invalid={!!erro}
          />
        </div>
      </div>
      {erro && (
        <span className="text-sm text-destructive" role="alert">
          {erro}
        </span>
      )}
    </div>
  )
}

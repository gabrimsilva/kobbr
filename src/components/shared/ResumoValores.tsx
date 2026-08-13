/**
 * Componente de resumo de valores do pedido com desconto
 * 
 * Exibe o breakdown completo dos valores do pedido:
 * - Subtotal original
 * - Desconto aplicado (se houver)
 * - Subtotal com desconto
 * - Taxas de entrega
 * - Total final
 * 
 * @module ResumoValores
 */

import type { ResumoValores } from '@/types/supabase'
import { Separator } from '@/components/ui/separator'

/**
 * Props do componente ResumoValores
 */
interface ResumoValoresProps {
  /** Objeto com todos os valores calculados do pedido */
  resumo: ResumoValores
}

/**
 * Componente para exibir resumo de valores do pedido
 * 
 * Mostra subtotal, desconto (se aplicável), taxas e total final.
 * Omite linhas de desconto quando desconto = 0 para manter a interface limpa.
 * 
 * @param props - Propriedades do componente
 * @returns Elemento React com resumo de valores
 * 
 * @example
 * ```tsx
 * <ResumoValoresComponent
 *   resumo={{
 *     subtotal: 100.00,
 *     desconto: 10,
 *     tipo_desconto: 'valor',
 *     desconto_calculado: 10.00,
 *     subtotal_com_desconto: 90.00,
 *     taxa_entrega: 5.00,
 *     taxa_extra_km: 0.00,
 *     total: 95.00
 *   }}
 * />
 * ```
 */
export function ResumoValoresComponent({ resumo }: ResumoValoresProps) {
  const temDesconto = resumo.desconto_calculado > 0

  return (
    <div className="space-y-2">
      {/* Subtotal original */}
      <div className="flex justify-between text-sm">
        <span className="text-muted-foreground">Subtotal:</span>
        <span className="font-medium">R$ {resumo.subtotal.toFixed(2)}</span>
      </div>

      {/* Desconto (apenas se > 0) */}
      {temDesconto && (
        <>
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">
              Desconto{' '}
              {resumo.tipo_desconto === 'percentual'
                ? `(${resumo.desconto}%)`
                : '(valor)'}
              :
            </span>
            <span className="font-medium text-destructive">
              -R$ {resumo.desconto_calculado.toFixed(2)}
            </span>
          </div>
          <Separator />
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">Subtotal c/ desconto:</span>
            <span className="font-medium">
              R$ {resumo.subtotal_com_desconto.toFixed(2)}
            </span>
          </div>
        </>
      )}

      {/* Taxa de entrega (apenas se > 0) */}
      {resumo.taxa_entrega > 0 && (
        <div className="flex justify-between text-sm">
          <span className="text-muted-foreground">Taxa de entrega:</span>
          <span className="font-medium">R$ {resumo.taxa_entrega.toFixed(2)}</span>
        </div>
      )}

      {/* Taxa extra km (apenas se > 0) */}
      {resumo.taxa_extra_km > 0 && (
        <div className="flex justify-between text-sm">
          <span className="text-muted-foreground">Taxa extra km:</span>
          <span className="font-medium">R$ {resumo.taxa_extra_km.toFixed(2)}</span>
        </div>
      )}

      {/* Separador antes do total */}
      <Separator />

      {/* Total final com destaque */}
      <div className="flex justify-between text-base font-bold">
        <span>Total:</span>
        <span className="text-primary">R$ {resumo.total.toFixed(2)}</span>
      </div>
    </div>
  )
}

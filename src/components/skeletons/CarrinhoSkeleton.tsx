import { Skeleton } from '@/components/ui/skeleton'
import { Separator } from '@/components/ui/separator'

/**
 * Skeleton loader para um item individual do carrinho
 *
 * Representa o layout de um item com imagem, nome, quantidade e preço.
 */
export function CarrinhoItemSkeleton() {
  return (
    <div className="flex gap-3 py-3">
      {/* Imagem do produto */}
      <Skeleton className="w-16 h-16 rounded flex-shrink-0" />

      {/* Informações do produto */}
      <div className="flex-1 space-y-2">
        <Skeleton className="h-4 w-3/4" />
        <Skeleton className="h-3 w-1/2" />
        <div className="flex items-center gap-2">
          <Skeleton className="h-8 w-24" />
        </div>
      </div>

      {/* Preço */}
      <div className="flex flex-col items-end gap-2">
        <Skeleton className="h-4 w-16" />
        <Skeleton className="h-6 w-6 rounded-full" />
      </div>
    </div>
  )
}

/**
 * Skeleton loader completo para o carrinho de compras
 *
 * Exibe placeholders para múltiplos itens, subtotal e botão de finalizar.
 *
 * @param itemCount - Número de itens skeleton a exibir (padrão: 3)
 *
 * @example
 * ```tsx
 * <Sheet>
 *   <SheetContent>
 *     {loading ? (
 *       <CarrinhoSkeleton itemCount={3} />
 *     ) : (
 *       <CarrinhoContent items={items} />
 *     )}
 *   </SheetContent>
 * </Sheet>
 * ```
 */
export function CarrinhoSkeleton({ itemCount = 3 }: { itemCount?: number }) {
  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="pb-4">
        <Skeleton className="h-6 w-32" />
      </div>

      <Separator />

      {/* Lista de itens */}
      <div className="flex-1 overflow-auto py-4 space-y-2">
        {Array.from({ length: itemCount }).map((_, i) => (
          <div key={i}>
            <CarrinhoItemSkeleton />
            {i < itemCount - 1 && <Separator className="my-2" />}
          </div>
        ))}
      </div>

      {/* Footer com totais */}
      <div className="border-t pt-4 space-y-4">
        {/* Subtotal */}
        <div className="flex justify-between">
          <Skeleton className="h-4 w-20" />
          <Skeleton className="h-4 w-24" />
        </div>

        {/* Taxa de entrega */}
        <div className="flex justify-between">
          <Skeleton className="h-4 w-32" />
          <Skeleton className="h-4 w-20" />
        </div>

        <Separator />

        {/* Total */}
        <div className="flex justify-between">
          <Skeleton className="h-6 w-16" />
          <Skeleton className="h-6 w-28" />
        </div>

        {/* Botão finalizar */}
        <Skeleton className="h-12 w-full" />
      </div>
    </div>
  )
}

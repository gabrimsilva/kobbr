import { Card, CardContent } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'

/**
 * Skeleton loader para card de produto
 *
 * Exibe um placeholder animado enquanto os produtos estão sendo carregados.
 * Mantém as mesmas proporções e layout do ProdutoCard real.
 *
 * @example
 * ```tsx
 * {loading ? (
 *   <ProdutoCardSkeleton />
 * ) : (
 *   <ProdutoCard produto={produto} />
 * )}
 * ```
 */
export function ProdutoCardSkeleton() {
  return (
    <Card className="overflow-hidden">
      {/* Imagem skeleton */}
      <Skeleton className="w-full h-48" />

      <CardContent className="p-4 space-y-3">
        {/* Título skeleton */}
        <Skeleton className="h-5 w-3/4" />

        {/* Descrição skeleton (2 linhas) */}
        <div className="space-y-2">
          <Skeleton className="h-3 w-full" />
          <Skeleton className="h-3 w-5/6" />
        </div>

        {/* Preço skeleton */}
        <Skeleton className="h-6 w-24" />

        {/* Botão skeleton */}
        <Skeleton className="h-10 w-full" />
      </CardContent>
    </Card>
  )
}

/**
 * Grid de skeleton loaders para produtos
 *
 * @param count - Número de skeletons a exibir (padrão: 6)
 *
 * @example
 * ```tsx
 * {loading ? (
 *   <ProdutoCardSkeletonGrid count={8} />
 * ) : (
 *   <div className="grid">
 *     {produtos.map(p => <ProdutoCard key={p.id} produto={p} />)}
 *   </div>
 * )}
 * ```
 */
export function ProdutoCardSkeletonGrid({ count = 6 }: { count?: number }) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
      {Array.from({ length: count }).map((_, i) => (
        <ProdutoCardSkeleton key={i} />
      ))}
    </div>
  )
}

import { useRef } from 'react'
import { Button } from '@/components/ui/button'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import type { CategoriaSupabase } from "@/services"

/**
 * Props do componente FiltroCategorias
 */
interface FiltroCategoriasProps {
  /** Lista de categorias disponíveis */
  categorias: CategoriaSupabase[]
  /** Categoria atualmente ativa */
  categoriaAtiva: string
  /** Callback quando uma categoria é selecionada */
  onCategoriaChange: (categoriaId: string) => void
  /** Se deve mostrar a opção "Todos" */
  mostrarTodos?: boolean
  /** Se deve mostrar a opção "Promoções" */
  mostrarPromocoes?: boolean
  /** Se há produtos com preço promocional */
  temPromocoes?: boolean
}

/**
 * Componente de filtro de categorias com scroll horizontal
 * Permite navegar entre categorias com botões de navegação
 * 
 * @example
 * <FiltroCategorias
 *   categorias={categorias}
 *   categoriaAtiva="todos"
 *   onCategoriaChange={(id) => setCategoriaAtiva(id)}
 *   mostrarTodos
 *   mostrarPromocoes
 *   temPromocoes
 * />
 */
export default function FiltroCategorias({
  categorias,
  categoriaAtiva,
  onCategoriaChange,
  mostrarTodos = true,
  mostrarPromocoes = true,
  temPromocoes = false
}: FiltroCategoriasProps) {
  const categoriasRef = useRef<HTMLDivElement>(null)

  const scrollLeft = () => {
    if (categoriasRef.current) {
      const container = categoriasRef.current
      const scrollAmount = 200

      // Se estiver no início, vai para o final
      if (container.scrollLeft <= 0) {
        container.scrollTo({ left: container.scrollWidth - container.clientWidth, behavior: 'smooth' })
      } else {
        container.scrollBy({ left: -scrollAmount, behavior: 'smooth' })
      }
    }
  }

  const scrollRight = () => {
    if (categoriasRef.current) {
      const container = categoriasRef.current
      const scrollAmount = 200

      // Se estiver no final, volta para o início
      if (container.scrollLeft + container.clientWidth >= container.scrollWidth - 1) {
        container.scrollTo({ left: 0, behavior: 'smooth' })
      } else {
        container.scrollBy({ left: scrollAmount, behavior: 'smooth' })
      }
    }
  }

  return (
    <div className="mb-6">
      <div className="relative">
        <Button
          variant="outline"
          size="sm"
          className="absolute left-0 top-1/2 -translate-y-1/2 z-10 cursor-pointer"
          onClick={scrollLeft}
          aria-label="Rolar categorias para esquerda"
        >
          <ChevronLeft className="h-4 w-4" />
        </Button>

        <div
          ref={categoriasRef}
          className="overflow-x-auto mx-8 scroll-smooth"
          style={{
            scrollbarWidth: 'none',
            msOverflowStyle: 'none'
          } as React.CSSProperties}
        >
          <div className="flex gap-2 min-w-max px-2">
            {/* Categoria Todos */}
            {mostrarTodos && (
              <Button
                key="todos"
                variant={categoriaAtiva === 'todos' ? 'default' : 'outline'}
                onClick={() => onCategoriaChange('todos')}
                className={`whitespace-nowrap cursor-pointer ${categoriaAtiva === 'todos'
                    ? 'bg-[color:var(--secondary-foreground)] hover:bg-[color:var(--secondary-foreground)]/90'
                    : ''
                  }`}
              >
                Todos
              </Button>
            )}

            {/* Categoria Promoções */}
            {mostrarPromocoes && temPromocoes && (
              <Button
                key="promocoes"
                variant={categoriaAtiva === 'promocoes' ? 'default' : 'outline'}
                onClick={() => onCategoriaChange('promocoes')}
                className={`whitespace-nowrap cursor-pointer ${categoriaAtiva === 'promocoes'
                    ? 'bg-[color:var(--secondary-foreground)] hover:bg-[color:var(--secondary-foreground)]/90'
                    : ''
                  }`}
              >
                Promoções
              </Button>
            )}

            {/* Categorias do sistema */}
            {categorias.map((categoria) => (
              <Button
                key={categoria.id}
                variant={categoriaAtiva === categoria.id ? 'default' : 'outline'}
                onClick={() => onCategoriaChange(categoria.id)}
                className={`whitespace-nowrap cursor-pointer ${categoriaAtiva === categoria.id
                    ? 'bg-[color:var(--secondary-foreground)] hover:bg-[color:var(--secondary-foreground)]/90'
                    : ''
                  }`}
              >
                {categoria.nome}
              </Button>
            ))}
          </div>
        </div>

        <Button
          variant="outline"
          size="sm"
          className="absolute right-0 top-1/2 -translate-y-1/2 z-10 cursor-pointer"
          onClick={scrollRight}
          aria-label="Rolar categorias para direita"
        >
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>
    </div>
  )
}

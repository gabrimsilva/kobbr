import { Search, X } from 'lucide-react'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue
} from '@/components/ui/select'
import type { CategoriaSupabase } from '@/services'

interface BuscaCatalogoProps {
  termo: string
  onTermoChange: (termo: string) => void
  categorias: CategoriaSupabase[]
  categoriaAtiva: string
  onCategoriaChange: (categoriaId: string) => void
}

/** Remove acentos e caixa para comparar nomes ("Pão" casa com "pao") */
export function normalizarBusca(texto: string): string {
  return texto.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim()
}

/**
 * Barra de busca do catálogo público: nome do produto + categoria
 */
export default function BuscaCatalogo({
  termo,
  onTermoChange,
  categorias,
  categoriaAtiva,
  onCategoriaChange
}: BuscaCatalogoProps) {
  return (
    <div className="flex flex-col sm:flex-row gap-2 mb-4">
      <div className="relative flex-1">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 pointer-events-none" />
        <Input
          type="search"
          id="buscar-produto"
          name="buscar-produto"
          placeholder="Buscar produto pelo nome..."
          aria-label="Buscar produto pelo nome"
          className="pl-9 pr-9 bg-white h-10"
          value={termo}
          onChange={(e) => onTermoChange(e.target.value)}
        />
        {termo && (
          <button
            type="button"
            onClick={() => onTermoChange('')}
            className="absolute right-2 top-1/2 -translate-y-1/2 p-1 rounded-full text-gray-400 hover:text-gray-600 cursor-pointer"
            aria-label="Limpar busca"
          >
            <X className="h-4 w-4" />
          </button>
        )}
      </div>

      <Select value={categoriaAtiva} onValueChange={onCategoriaChange}>
        <SelectTrigger className="sm:w-56 bg-white h-10" aria-label="Filtrar por categoria">
          <SelectValue placeholder="Categoria" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="todos">Todas as categorias</SelectItem>
          {categorias.map(categoria => (
            <SelectItem key={categoria.id} value={categoria.id}>
              {categoria.nome}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  )
}

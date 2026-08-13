import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { type CategoriaSupabase } from "@/services"

/**
 * Props para o componente FiltrosProdutos
 */
interface FiltrosProdutosProps {
  /** Termo de busca atual */
  searchTerm: string
  /** Função para atualizar o termo de busca */
  setSearchTerm: (term: string) => void
  /** ID da categoria ativa ou 'todos' */
  categoriaAtiva: string
  /** Função para atualizar a categoria ativa */
  setCategoriaAtiva: (categoria: string) => void
  /** Lista de categorias disponíveis */
  categorias: CategoriaSupabase[]
}

/**
 * Componente de filtros de produtos para o PDV
 * 
 * Exibe uma barra de busca e botões de filtro por categoria,
 * permitindo ao usuário encontrar produtos rapidamente
 * 
 * @example
 * ```tsx
 * <FiltrosProdutos
 *   searchTerm={searchTerm}
 *   setSearchTerm={setSearchTerm}
 *   categoriaAtiva={categoriaAtiva}
 *   setCategoriaAtiva={setCategoriaAtiva}
 *   categorias={categorias}
 * />
 * ```
 */
export default function FiltrosProdutos({
  searchTerm,
  setSearchTerm,
  categoriaAtiva,
  setCategoriaAtiva,
  categorias
}: FiltrosProdutosProps) {
  return (
    <Card>
      <CardHeader className="pb-3 md:pb-6">
        <CardTitle className="text-lg md:text-xl">Produtos</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3 md:space-y-4">
        {/* Busca */}
        <Input
          id="buscar-produtos-pdv"
          name="buscar-produtos-pdv"
          placeholder="Buscar produtos..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="text-sm md:text-base"
        />

        {/* Categorias */}
        <div className="flex flex-wrap gap-1 md:gap-2">
          <Button
            variant={categoriaAtiva === 'todos' ? "default" : "outline"}
            size="sm"
            onClick={() => setCategoriaAtiva('todos')}
            className="text-xs md:text-sm px-2 md:px-3"
          >
            Todos
          </Button>
          {categorias.map((categoria) => (
            <Button
              key={categoria.id}
              variant={categoriaAtiva === categoria.id ? "default" : "outline"}
              size="sm"
              onClick={() => setCategoriaAtiva(categoria.id)}
              className="text-xs md:text-sm px-2 md:px-3"
            >
              {categoria.nome}
            </Button>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}
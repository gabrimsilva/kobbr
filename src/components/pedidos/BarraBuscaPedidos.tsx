import { Search } from "lucide-react"
import { Input } from "@/components/ui/input"

/**
 * Props do componente BarraBuscaPedidos
 */
interface BarraBuscaPedidosProps {
  /**
   * Termo de busca atual
   */
  searchTerm: string
  /**
   * Callback chamado quando o termo de busca muda
   */
  onSearchChange: (value: string) => void
  /**
   * Placeholder customizado (opcional)
   * @default "Buscar por nome, telefone ou #ID..."
   */
  placeholder?: string
  /**
   * Classes CSS adicionais (opcional)
   */
  className?: string
}

/**
 * Componente de barra de busca para pedidos
 * 
 * Permite buscar pedidos por:
 * - Nome do cliente (case insensitive)
 * - Telefone (com ou sem formatação)
 * - ID do pedido (com ou sem #)
 * 
 * @example
 * ```tsx
 * <BarraBuscaPedidos
 *   searchTerm={searchTerm}
 *   onSearchChange={setSearchTerm}
 * />
 * ```
 */
export default function BarraBuscaPedidos({
  searchTerm,
  onSearchChange,
  placeholder = "Buscar por nome, telefone ou #ID...",
  className = ""
}: BarraBuscaPedidosProps) {
  return (
    <div className={`flex items-center space-x-2 ${className}`}>
      <div className="relative flex-1">
        <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
        <Input
          id="buscar-pedidos"
          name="buscar-pedidos"
          placeholder={placeholder}
          className="pl-8"
          value={searchTerm}
          onChange={(e) => onSearchChange(e.target.value)}
        />
      </div>
    </div>
  )
}

import * as React from "react"
import { Loader2 } from "lucide-react"
import { Button, buttonVariants } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import { type VariantProps } from "class-variance-authority"

export interface LoadingButtonProps
  extends React.ComponentProps<"button">,
    VariantProps<typeof buttonVariants> {
  /**
   * Estado de carregamento do botão
   */
  loading?: boolean
  /**
   * Texto alternativo a ser exibido durante o carregamento
   */
  loadingText?: string
  /**
   * Renderizar como filho (usando Slot do Radix)
   */
  asChild?: boolean
}

/**
 * Botão com indicador de loading integrado
 *
 * Extensão do componente Button que adiciona um spinner de loading e desabilita
 * automaticamente o botão durante operações assíncronas.
 *
 * @example
 * ```tsx
 * const [loading, setLoading] = useState(false)
 *
 * const handleSalvar = async () => {
 *   setLoading(true)
 *   await salvarDados()
 *   setLoading(false)
 * }
 *
 * <LoadingButton
 *   loading={loading}
 *   onClick={handleSalvar}
 * >
 *   Salvar
 * </LoadingButton>
 * ```
 *
 * @example Com texto de loading customizado
 * ```tsx
 * <LoadingButton
 *   loading={processando}
 *   loadingText="Processando..."
 *   onClick={handleProcessar}
 * >
 *   Processar Pedido
 * </LoadingButton>
 * ```
 */
const LoadingButton = React.forwardRef<HTMLButtonElement, LoadingButtonProps>(
  ({ className, variant, size, children, loading = false, loadingText, disabled, asChild, ...props }, ref) => {
    return (
      <Button
        ref={ref}
        className={cn(className)}
        variant={variant}
        size={size}
        disabled={loading || disabled}
        asChild={asChild}
        {...props}
      >
        {loading ? (
          <>
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            {loadingText || children}
          </>
        ) : (
          children
        )}
      </Button>
    )
  }
)
LoadingButton.displayName = "LoadingButton"

export { LoadingButton }

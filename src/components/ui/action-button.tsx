import { Button, buttonVariants } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import type { VariantProps } from "class-variance-authority"
import * as React from "react"

export interface ActionButtonProps 
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  /**
   * Se true, mostra um spinner de loading
   */
  loading?: boolean
  /**
   * Renderiza como um componente filho
   */
  asChild?: boolean
}

/**
 * Botão padrão para ações positivas do sistema
 * 
 * Usa o estilo primary por padrão e pode mostrar estado de loading
 */
export function ActionButton({ 
  children, 
  loading, 
  disabled, 
  className, 
  variant = "default", 
  size = "default", 
  asChild,
  ...props 
}: ActionButtonProps) {
  return (
    <Button
      disabled={disabled || loading}
      variant={variant}
      size={size}
      asChild={asChild}
      className={cn(
        "bg-primary hover:bg-primary/80 text-primary-foreground transition-colors",
        className
      )}
      {...props}
    >
      {loading && (
        <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2" />
      )}
      {children}
    </Button>
  )
}

import { Button, buttonVariants } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import type { VariantProps } from "class-variance-authority"
import * as React from "react"

export interface DangerButtonProps 
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
 * Botão para ações destrutivas e perigosas do sistema
 * 
 * Usa o estilo destructive por padrão e pode mostrar estado de loading.
 * Use este botão para ações que:
 * - Removem dados permanentemente
 * - Cancelam operações importantes
 * - Descartam trabalho do usuário
 * - São irreversíveis ou de alto impacto
 * 
 * @example
 * // Ação destrutiva simples
 * <DangerButton onClick={handleDelete}>
 *   Excluir
 * </DangerButton>
 * 
 * @example
 * // Com loading state
 * <DangerButton loading={isDeleting} onClick={handleDelete}>
 *   Excluir Todos
 * </DangerButton>
 * 
 * @example
 * // Variante outline para ações menos críticas
 * <DangerButton variant="outline" onClick={handleClear}>
 *   Limpar Filtros
 * </DangerButton>
 */
export function DangerButton({ 
  children, 
  loading, 
  disabled, 
  className, 
  variant = "destructive", 
  size = "default", 
  asChild,
  ...props 
}: DangerButtonProps) {
  return (
    <Button
      disabled={disabled || loading}
      variant={variant}
      size={size}
      asChild={asChild}
      className={cn(className)}
      {...props}
    >
      {loading ? (
        <>
          <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin mr-2" />
          {children}
        </>
      ) : (
        children
      )}
    </Button>
  )
}

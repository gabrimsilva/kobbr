/**
 * Validation utilities for discount functionality in PDV and Comandas
 * 
 * This module provides validation functions to ensure discount values
 * are within acceptable ranges based on discount type (valor/percentual)
 * and order subtotal.
 */

/**
 * Result of discount validation
 */
export interface ValidacaoDesconto {
  /** Whether the discount is valid */
  valido: boolean;
  /** Error message if validation failed */
  erro?: string;
}

/**
 * Validates a discount value based on type and order subtotal
 * 
 * @param desconto - The discount value (in R$ or %)
 * @param tipo - The discount type ('valor' for R$, 'percentual' for %)
 * @param subtotal - The order subtotal before discount
 * @returns Validation result with error message if invalid
 * 
 * @example
 * // Valid discount in reais
 * validarDesconto(10, 'valor', 100) // { valido: true }
 * 
 * @example
 * // Invalid: negative discount
 * validarDesconto(-5, 'valor', 100) // { valido: false, erro: '...' }
 * 
 * @example
 * // Invalid: discount greater than subtotal
 * validarDesconto(150, 'valor', 100) // { valido: false, erro: '...' }
 * 
 * @example
 * // Invalid: percentage above 100%
 * validarDesconto(101, 'percentual', 100) // { valido: false, erro: '...' }
 */
export function validarDesconto(
  desconto: number,
  tipo: 'valor' | 'percentual',
  subtotal: number
): ValidacaoDesconto {
  // Validação de valor negativo
  if (desconto < 0) {
    return {
      valido: false,
      erro: 'O desconto não pode ser negativo'
    };
  }

  // Validação específica por tipo
  if (tipo === 'valor') {
    if (desconto > subtotal) {
      return {
        valido: false,
        erro: `O desconto não pode ser maior que o subtotal (R$ ${subtotal.toFixed(2)})`
      };
    }
  } else if (tipo === 'percentual') {
    if (desconto > 100) {
      return {
        valido: false,
        erro: 'O desconto percentual não pode ser maior que 100%'
      };
    }
  }

  return { valido: true };
}

/**
 * Utilitários de formatação para strings e valores
 * @module utils/formatacao
 */

/**
 * Formata um número de telefone brasileiro
 * @param value - String com o número de telefone (apenas dígitos ou com formatação)
 * @returns String formatada no padrão (XX) XXXXX-XXXX ou (XX) XXXX-XXXX
 * @example
 * formatarTelefone('11987654321') // '(11) 98765-4321'
 * formatarTelefone('1134567890') // '(11) 3456-7890'
 */
export function formatarTelefone(value: string): string {
  if (!value) return ''
  
  const apenasNumeros = value.replace(/\D/g, '')
  
  if (apenasNumeros.length <= 10) {
    // Telefone fixo: (XX) XXXX-XXXX
    return apenasNumeros
      .replace(/^(\d{2})(\d{4})(\d{4})$/, '($1) $2-$3')
      .replace(/^(\d{2})(\d{0,4})/, '($1) $2')
      .replace(/^(\d{2})(\d{4})(\d{0,4})/, '($1) $2-$3')
  } else {
    // Celular: (XX) XXXXX-XXXX
    return apenasNumeros
      .replace(/^(\d{2})(\d{5})(\d{4})$/, '($1) $2-$3')
      .replace(/^(\d{2})(\d{0,5})/, '($1) $2')
      .replace(/^(\d{2})(\d{5})(\d{0,4})/, '($1) $2-$3')
  }
}

/**
 * Formata um CEP brasileiro
 * @param value - String com o CEP (apenas dígitos ou com formatação)
 * @returns String formatada no padrão XXXXX-XXX
 * @example
 * formatarCEP('01310100') // '01310-100'
 */
export function formatarCEP(value: string): string {
  if (!value) return ''
  
  const apenasNumeros = value.replace(/\D/g, '')
  
  // Limitar a 8 dígitos
  const limitado = apenasNumeros.slice(0, 8)
  
  // Formatar: XXXXX-XXX
  if (limitado.length <= 5) {
    return limitado
  }
  
  return `${limitado.slice(0, 5)}-${limitado.slice(5)}`
}

/**
 * Formata um CPF brasileiro
 * @param value - String com o CPF (apenas dígitos ou com formatação)
 * @returns String formatada no padrão XXX.XXX.XXX-XX
 * @example
 * formatarCPF('12345678900') // '123.456.789-00'
 */
export function formatarCPF(value: string): string {
  if (!value) return ''
  
  const apenasNumeros = value.replace(/\D/g, '')
  
  return apenasNumeros
    .replace(/^(\d{3})(\d{3})(\d{3})(\d{2})$/, '$1.$2.$3-$4')
    .replace(/^(\d{0,3})/, '$1')
    .replace(/^(\d{3})(\d{0,3})/, '$1.$2')
    .replace(/^(\d{3})\.(\d{3})(\d{0,3})/, '$1.$2.$3')
    .replace(/^(\d{3})\.(\d{3})\.(\d{3})(\d{0,2})/, '$1.$2.$3-$4')
}

/**
 * Formata um valor monetário em Real brasileiro
 * @param value - Número ou string representando o valor
 * @returns String formatada no padrão R$ X.XXX,XX
 * @example
 * formatarMoeda(1234.56) // 'R$ 1.234,56'
 * formatarMoeda('1234.56') // 'R$ 1.234,56'
 */
export function formatarMoeda(value: number | string): string {
  const numero = typeof value === 'string' ? parseFloat(value) : value
  
  if (isNaN(numero)) return 'R$ 0,00'
  
  return numero.toLocaleString('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  })
}

/**
 * Remove toda formatação de uma string, mantendo apenas dígitos
 * @param value - String com formatação
 * @returns String contendo apenas dígitos
 * @example
 * removerFormatacao('(11) 98765-4321') // '11987654321'
 * removerFormatacao('123.456.789-00') // '12345678900'
 * removerFormatacao('01310-100') // '01310100'
 */
export function removerFormatacao(value: string): string {
  if (!value) return ''
  return value.replace(/\D/g, '')
}

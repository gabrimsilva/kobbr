/**
 * Utilitários de validação para formulários
 * @module utils/validacao
 */

/**
 * Valida um CPF brasileiro
 * @param cpf - String com o CPF (com ou sem formatação)
 * @returns true se o CPF é válido, false caso contrário
 * @example
 * validarCPF('123.456.789-00') // false (CPF inválido)
 * validarCPF('111.111.111-11') // false (CPF com dígitos repetidos)
 */
export function validarCPF(cpf: string): boolean {
  if (!cpf) return false
  
  // Remove formatação
  const apenasNumeros = cpf.replace(/\D/g, '')
  
  // Verifica se tem 11 dígitos
  if (apenasNumeros.length !== 11) return false
  
  // Verifica se todos os dígitos são iguais
  if (/^(\d)\1{10}$/.test(apenasNumeros)) return false
  
  // Validação do primeiro dígito verificador
  let soma = 0
  for (let i = 0; i < 9; i++) {
    soma += parseInt(apenasNumeros.charAt(i)) * (10 - i)
  }
  let resto = (soma * 10) % 11
  if (resto === 10 || resto === 11) resto = 0
  if (resto !== parseInt(apenasNumeros.charAt(9))) return false
  
  // Validação do segundo dígito verificador
  soma = 0
  for (let i = 0; i < 10; i++) {
    soma += parseInt(apenasNumeros.charAt(i)) * (11 - i)
  }
  resto = (soma * 10) % 11
  if (resto === 10 || resto === 11) resto = 0
  if (resto !== parseInt(apenasNumeros.charAt(10))) return false
  
  return true
}

/**
 * Valida um endereço de email
 * @param email - String com o email
 * @returns true se o email é válido, false caso contrário
 * @example
 * validarEmail('usuario@exemplo.com') // true
 * validarEmail('email-invalido') // false
 */
export function validarEmail(email: string): boolean {
  if (!email) return false
  
  const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return regex.test(email)
}

/**
 * Valida um número de telefone brasileiro
 * @param telefone - String com o telefone (com ou sem formatação)
 * @returns true se o telefone é válido, false caso contrário
 * @example
 * validarTelefone('(11) 98765-4321') // true
 * validarTelefone('(11) 3456-7890') // true
 * validarTelefone('123') // false
 */
export function validarTelefone(telefone: string): boolean {
  if (!telefone) return false
  
  // Remove formatação
  const apenasNumeros = telefone.replace(/\D/g, '')
  
  // Telefone deve ter 10 (fixo) ou 11 (celular) dígitos
  if (apenasNumeros.length < 10 || apenasNumeros.length > 11) return false
  
  // DDD deve estar entre 11 e 99
  const ddd = parseInt(apenasNumeros.substring(0, 2))
  if (ddd < 11 || ddd > 99) return false
  
  return true
}

/**
 * Valida um CEP brasileiro
 * @param cep - String com o CEP (com ou sem formatação)
 * @returns true se o CEP é válido, false caso contrário
 * @example
 * validarCEP('01310-100') // true
 * validarCEP('01310100') // true
 * validarCEP('123') // false
 */
export function validarCEP(cep: string): boolean {
  if (!cep) return false
  
  // Remove formatação
  const apenasNumeros = cep.replace(/\D/g, '')
  
  // CEP deve ter exatamente 8 dígitos
  return apenasNumeros.length === 8
}

/**
 * Valida se um campo obrigatório foi preenchido
 * @param valor - Valor do campo
 * @returns true se o campo está preenchido, false caso contrário
 * @example
 * validarCampoObrigatorio('texto') // true
 * validarCampoObrigatorio('') // false
 * validarCampoObrigatorio(null) // false
 * validarCampoObrigatorio(undefined) // false
 */
export function validarCampoObrigatorio(valor: any): boolean {
  if (valor === null || valor === undefined) return false
  if (typeof valor === 'string') return valor.trim().length > 0
  if (typeof valor === 'number') return true
  if (Array.isArray(valor)) return valor.length > 0
  return Boolean(valor)
}

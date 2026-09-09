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

/**
 * Normaliza a digitação de um valor monetário, aceitando vírgula ou ponto
 * como separador decimal e removendo separadores de milhar.
 *
 * Mantém o texto "em edição" (não converte para número) para que o usuário
 * consiga digitar livremente, inclusive valores incompletos como '11,'.
 *
 * Regras:
 * - Aceita apenas dígitos, vírgula e ponto
 * - O ÚLTIMO separador digitado é tratado como decimal; os anteriores são milhar
 * - Sempre devolve o decimal como '.' para ser aceito por parseFloat
 * - Limita a 2 casas decimais
 *
 * @param value - Texto digitado pelo usuário
 * @returns Texto normalizado, seguro para parseFloat
 * @example
 * normalizarEntradaMoeda('11,50')    // '11.50'
 * normalizarEntradaMoeda('11.50')    // '11.50'
 * normalizarEntradaMoeda('1.150,00') // '1150.00'
 * normalizarEntradaMoeda('1,150.00') // '1150.00'
 * normalizarEntradaMoeda('11,')      // '11.'
 * normalizarEntradaMoeda('11,509')   // '11.50'
 */
export function normalizarEntradaMoeda(value: string): string {
  if (!value) return ''

  // Mantém apenas dígitos e separadores
  let limpo = value.replace(/[^\d.,]/g, '')
  if (!limpo) return ''

  // Descobre a posição do último separador (o decimal, na intenção do usuário)
  const ultimoSeparador = Math.max(limpo.lastIndexOf(','), limpo.lastIndexOf('.'))

  if (ultimoSeparador === -1) {
    return limpo
  }

  // Parte inteira: remove todos os separadores restantes (milhar)
  const inteiro = limpo.slice(0, ultimoSeparador).replace(/[.,]/g, '')
  // Parte decimal: só dígitos, no máximo 2 casas
  const decimal = limpo.slice(ultimoSeparador + 1).replace(/[.,]/g, '').slice(0, 2)

  return `${inteiro || '0'}.${decimal}`
}

/**
 * Aplica máscara monetária progressiva, preenchendo da direita para a esquerda
 * (centavos primeiro), no padrão brasileiro.
 *
 * Só os dígitos são considerados: vírgulas e pontos digitados são ignorados,
 * porque a posição do decimal é determinada pela máscara. Isso elimina o erro
 * de digitar 11,50 e salvar 1150.
 *
 * Máximo de 12 dígitos para evitar overflow.
 *
 * @param value - Texto digitado pelo usuário
 * @returns Texto formatado para exibição no input
 * @example
 * aplicarMascaraMoeda('1')      // '0,01'
 * aplicarMascaraMoeda('12')     // '0,12'
 * aplicarMascaraMoeda('125')    // '1,25'
 * aplicarMascaraMoeda('1250')   // '12,50'
 * aplicarMascaraMoeda('12500')  // '125,00'
 * aplicarMascaraMoeda('125000') // '1.250,00'
 * aplicarMascaraMoeda('')       // ''
 */
export function aplicarMascaraMoeda(value: string): string {
  if (!value) return ''

  // Considera apenas dígitos; separadores digitados são irrelevantes
  const digitos = value.replace(/\D/g, '').slice(0, 12)
  if (!digitos) return ''

  const centavos = parseInt(digitos, 10)
  if (isNaN(centavos)) return ''

  return (centavos / 100).toLocaleString('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })
}

/**
 * Formata um número no padrão brasileiro para exibição dentro de um input
 * de valor (sem o símbolo R$), com 2 casas decimais.
 *
 * @param valor - Número a formatar
 * @returns Texto no formato '1.150,00'
 * @example
 * formatarValorParaEdicao(11.5)  // '11,50'
 * formatarValorParaEdicao(1150)  // '1.150,00'
 */
export function formatarValorParaEdicao(valor: number): string {
  if (isNaN(valor)) return ''
  return valor.toLocaleString('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })
}

/**
 * Converte um texto de valor monetário em número, aceitando vírgula ou ponto.
 *
 * @param value - Texto digitado (ex.: '11,50', '1.150,00') ou número
 * @returns Número correspondente, ou 0 quando inválido
 * @example
 * parsearMoeda('11,50')    // 11.5
 * parsearMoeda('1.150,00') // 1150
 * parsearMoeda('')         // 0
 * parsearMoeda('abc')      // 0
 */
export function parsearMoeda(value: string | number | null | undefined): number {
  if (value === null || value === undefined || value === '') return 0
  if (typeof value === 'number') return isNaN(value) ? 0 : value

  const numero = parseFloat(normalizarEntradaMoeda(value))
  return isNaN(numero) ? 0 : numero
}

import { useCallback } from 'react'
import {
  formatarTelefone as formatarTelefoneUtil,
  formatarCEP as formatarCEPUtil,
  formatarCPF as formatarCPFUtil,
  formatarMoeda as formatarMoedaUtil,
  removerFormatacao as removerFormatacaoUtil
} from '@/utils/formatacao'

/**
 * Hook customizado para formatação de valores
 * 
 * Fornece funções memoizadas para formatação de telefone, CEP, CPF, moeda
 * e remoção de formatação. Útil para formulários e exibição de dados.
 * 
 * @returns Objeto com funções de formatação
 * 
 * @example
 * ```tsx
 * function FormularioCliente() {
 *   const { formatarTelefone, formatarCEP, formatarCPF } = useFormatacao()
 *   const [telefone, setTelefone] = useState('')
 * 
 *   const handleTelefoneChange = (e: React.ChangeEvent<HTMLInputElement>) => {
 *     const valorFormatado = formatarTelefone(e.target.value)
 *     setTelefone(valorFormatado)
 *   }
 * 
 *   return (
 *     <input 
 *       value={telefone} 
 *       onChange={handleTelefoneChange}
 *       placeholder="(11) 98765-4321"
 *     />
 *   )
 * }
 * ```
 */
export function useFormatacao() {
  /**
   * Formata um número de telefone brasileiro
   * @param value - String com o número de telefone
   * @returns String formatada no padrão (XX) XXXXX-XXXX ou (XX) XXXX-XXXX
   */
  const formatarTelefone = useCallback((value: string): string => {
    return formatarTelefoneUtil(value)
  }, [])

  /**
   * Formata um CEP brasileiro
   * @param value - String com o CEP
   * @returns String formatada no padrão XXXXX-XXX
   */
  const formatarCEP = useCallback((value: string): string => {
    return formatarCEPUtil(value)
  }, [])

  /**
   * Formata um CPF brasileiro
   * @param value - String com o CPF
   * @returns String formatada no padrão XXX.XXX.XXX-XX
   */
  const formatarCPF = useCallback((value: string): string => {
    return formatarCPFUtil(value)
  }, [])

  /**
   * Formata um valor monetário em Real brasileiro
   * @param value - Número ou string representando o valor
   * @returns String formatada no padrão R$ X.XXX,XX
   */
  const formatarMoeda = useCallback((value: number | string): string => {
    return formatarMoedaUtil(value)
  }, [])

  /**
   * Remove toda formatação de uma string, mantendo apenas dígitos
   * @param value - String com formatação
   * @returns String contendo apenas dígitos
   */
  const removerFormatacao = useCallback((value: string): string => {
    return removerFormatacaoUtil(value)
  }, [])

  return {
    formatarTelefone,
    formatarCEP,
    formatarCPF,
    formatarMoeda,
    removerFormatacao
  }
}

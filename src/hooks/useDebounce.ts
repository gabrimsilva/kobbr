/**
 * Hook customizado para debouncing de valores
 *
 * Retorna um valor debounced que só atualiza após o delay especificado
 * sem novas mudanças no valor original. Útil para reduzir chamadas de API
 * em campos de busca ou outros inputs que mudam frequentemente.
 *
 * @module hooks/useDebounce
 *
 * @example
 * ```tsx
 * const [searchTerm, setSearchTerm] = useState('')
 * const debouncedSearchTerm = useDebounce(searchTerm, 500)
 *
 * useEffect(() => {
 *   if (debouncedSearchTerm) {
 *     // Fazer busca na API
 *     searchAPI(debouncedSearchTerm)
 *   }
 * }, [debouncedSearchTerm])
 * ```
 */

import { useState, useEffect } from 'react'

/**
 * Hook para fazer debounce de valores
 *
 * @param value - Valor a ser debounced
 * @param delay - Tempo de delay em milissegundos (padrão: 500ms)
 * @returns Valor debounced que só atualiza após o delay
 *
 * @example
 * ```tsx
 * // Busca com debounce de 500ms
 * const debouncedSearch = useDebounce(searchTerm, 500)
 *
 * // CEP com debounce maior (800ms)
 * const debouncedCEP = useDebounce(cep, 800)
 *
 * // Validação de formulário (300ms)
 * const debouncedInput = useDebounce(inputValue, 300)
 * ```
 */
export function useDebounce<T>(value: T, delay: number = 500): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    // Criar timer que atualiza o valor debounced após o delay
    const timer = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    // Limpar timer se o valor mudar antes do delay completar
    // ou quando o componente desmontar
    return () => {
      clearTimeout(timer)
    }
  }, [value, delay])

  return debouncedValue
}

/**
 * Hook para criar uma função debounced
 *
 * Útil quando você quer fazer debounce de uma função específica
 * ao invés de um valor.
 *
 * @param callback - Função a ser executada após o debounce
 * @param delay - Tempo de delay em milissegundos (padrão: 500ms)
 * @returns Função debounced
 *
 * @example
 * ```tsx
 * const handleSearch = useDebouncedCallback((searchTerm: string) => {
 *   searchAPI(searchTerm)
 * }, 500)
 *
 * // Usar no onChange
 * <input onChange={(e) => handleSearch(e.target.value)} />
 * ```
 */
export function useDebouncedCallback<T extends (...args: any[]) => any>(
  callback: T,
  delay: number = 500
): (...args: Parameters<T>) => void {
  const [timer, setTimer] = useState<NodeJS.Timeout | null>(null)

  useEffect(() => {
    // Limpar timer quando o componente desmontar
    return () => {
      if (timer) {
        clearTimeout(timer)
      }
    }
  }, [timer])

  return (...args: Parameters<T>) => {
    // Limpar timer anterior se existir
    if (timer) {
      clearTimeout(timer)
    }

    // Criar novo timer
    const newTimer = setTimeout(() => {
      callback(...args)
    }, delay)

    setTimer(newTimer)
  }
}

/**
 * Hook para debounce com loading state
 *
 * Similar ao useDebounce mas também retorna um estado de loading
 * que indica quando o debounce está aguardando.
 *
 * @param value - Valor a ser debounced
 * @param delay - Tempo de delay em milissegundos (padrão: 500ms)
 * @returns Tupla [valorDebounced, isDebouncing]
 *
 * @example
 * ```tsx
 * const [searchTerm, setSearchTerm] = useState('')
 * const [debouncedSearch, isSearching] = useDebounceWithLoading(searchTerm, 500)
 *
 * return (
 *   <div>
 *     <input value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
 *     {isSearching && <Spinner />}
 *   </div>
 * )
 * ```
 */
export function useDebounceWithLoading<T>(
  value: T,
  delay: number = 500
): [T, boolean] {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)
  const [isDebouncing, setIsDebouncing] = useState<boolean>(false)

  useEffect(() => {
    // Marcar como debouncing se o valor mudou
    setIsDebouncing(true)

    // Criar timer que atualiza o valor debounced após o delay
    const timer = setTimeout(() => {
      setDebouncedValue(value)
      setIsDebouncing(false)
    }, delay)

    // Limpar timer se o valor mudar antes do delay completar
    return () => {
      clearTimeout(timer)
    }
  }, [value, delay])

  return [debouncedValue, isDebouncing]
}

/**
 * Exportar como default para facilitar importação
 */
export default useDebounce

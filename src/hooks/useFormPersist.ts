import { useEffect, useCallback, useRef } from 'react'

/**
 * Hook para persistir dados de formulário no localStorage
 * Salva automaticamente os dados e os restaura quando o componente é montado
 * 
 * @param key - Chave única para identificar o formulário no localStorage
 * @param data - Dados do formulário a serem persistidos
 * @param enabled - Se a persistência está habilitada (padrão: true)
 * 
 * @example
 * ```tsx
 * const [nome, setNome] = useState('')
 * const [email, setEmail] = useState('')
 * 
 * const { clearPersistedData, loadPersistedData } = useFormPersist(
 *   'novo-funcionario-form',
 *   { nome, email }
 * )
 * 
 * // Carregar dados ao montar
 * useEffect(() => {
 *   const saved = loadPersistedData()
 *   if (saved) {
 *     setNome(saved.nome || '')
 *     setEmail(saved.email || '')
 *   }
 * }, [])
 * 
 * // Limpar ao submeter com sucesso
 * const handleSubmit = async () => {
 *   await salvar()
 *   clearPersistedData()
 * }
 * ```
 */
export function useFormPersist<T extends Record<string, any>>(
  key: string,
  data: T,
  enabled: boolean = true
) {
  const isFirstRender = useRef(true)

  /**
   * Salva os dados no localStorage
   */
  const saveData = useCallback(() => {
    if (!enabled) return
    
    try {
      // Filtrar valores vazios para não poluir o localStorage
      const dataToSave = Object.entries(data).reduce((acc, [key, value]) => {
        // Salvar apenas se tiver valor
        if (value !== '' && value !== null && value !== undefined) {
          acc[key] = value
        }
        return acc
      }, {} as Record<string, any>)
      
      // Só salvar se houver dados
      if (Object.keys(dataToSave).length > 0) {
        localStorage.setItem(key, JSON.stringify(dataToSave))
      }
    } catch (error) {
      console.error('Erro ao salvar dados do formulário:', error)
    }
  }, [key, data, enabled])

  /**
   * Carrega os dados do localStorage
   */
  const loadPersistedData = useCallback((): Partial<T> | null => {
    if (!enabled) return null
    
    try {
      const saved = localStorage.getItem(key)
      if (saved) {
        return JSON.parse(saved) as Partial<T>
      }
    } catch (error) {
      console.error('Erro ao carregar dados do formulário:', error)
    }
    return null
  }, [key, enabled])

  /**
   * Limpa os dados do localStorage
   */
  const clearPersistedData = useCallback(() => {
    try {
      localStorage.removeItem(key)
    } catch (error) {
      console.error('Erro ao limpar dados do formulário:', error)
    }
  }, [key])

  /**
   * Salva automaticamente quando os dados mudam
   * Ignora o primeiro render para não sobrescrever dados carregados
   */
  useEffect(() => {
    if (!enabled) return
    
    // Pular primeiro render
    if (isFirstRender.current) {
      isFirstRender.current = false
      return
    }
    
    // Debounce para não salvar a cada tecla digitada
    const timeoutId = setTimeout(() => {
      saveData()
    }, 500) // 500ms de delay

    return () => clearTimeout(timeoutId)
  }, [data, enabled, saveData])

  return {
    loadPersistedData,
    clearPersistedData,
    saveData
  }
}

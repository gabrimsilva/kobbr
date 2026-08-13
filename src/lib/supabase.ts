import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Variáveis de ambiente do Supabase não encontradas')
}

/**
 * Cliente Supabase configurado
 * Use este cliente para operações diretas ao banco de dados
 *
 * @example
 * ```ts
 * import { supabase } from '@/lib/supabase'
 * const { data } = await supabase.from('tabela').select('*')
 * ```
 */
export const supabase = createClient(supabaseUrl, supabaseAnonKey)

/**
 * IMPORTANTE: Todos os services foram migrados para @/services
 *
 * Para usar os services, importe de @/services:
 * ```ts
 * import { pedidoService, clienteService, etc } from '@/services'
 * ```
 *
 * Não importe services deste arquivo.
 */

// Re-exportar tipos do arquivo centralizado para compatibilidade
export type {
  UsuarioSupabase,
  ConfiguracaoSupabase,
  CategoriaSupabase,
  EstoqueSupabase,
  FuncionarioSupabase,
  SaborSupabase,
  AdicionalSupabase,
  ComandaSupabase,
  HistoricoComandaSupabase,
  ProdutoSupabase,
  ComboSupabase,
  TamanhoSupabase,
  ProdutoSaborSupabase,
  ComboProdutoSupabase,
  HistoricoPedidoSupabase,
  PedidoSupabase
} from '@/types/supabase'

// Re-exportar clienteService do arquivo antigo (deprecado, migrar para @/services)
export { clienteService } from './clienteService'

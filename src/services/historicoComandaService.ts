import { supabase } from "@/lib/supabase"
import { tenantId } from "./tenant"
import type { HistoricoComandaSupabase } from '@/types/supabase'

/**
 * Interface para o serviço de histórico de comandas
 * Gerencia operações de consulta ao histórico de comandas finalizadas
 */
export interface IHistoricoComandaService {
  buscarTodos(limite?: number): Promise<HistoricoComandaSupabase[]>
  buscarPorNumero(numeroComanda: number, limite?: number): Promise<HistoricoComandaSupabase[]>
  buscarPorPeriodo(dataInicio: string, dataFim: string): Promise<HistoricoComandaSupabase[]>
}

/**
 * Implementação do serviço de histórico de comandas
 */
const historicoComandaServiceImpl: IHistoricoComandaService = {
  /**
   * Buscar histórico de comandas
   * @param limite - Limite de registros a retornar (padrão: 500)
   * @returns Array de comandas do histórico
   */
  async buscarTodos(limite: number = 500): Promise<HistoricoComandaSupabase[]> {
    const { data, error } = await supabase
      .from('historico_comandas')
      .select('*')
      .eq('estabelecimento_id', tenantId())
      .order('finalizado_em', { ascending: false })
      .limit(limite)

    if (error) {
      console.error('Erro ao buscar histórico de comandas:', error)
      throw new Error(`Erro ao buscar histórico de comandas: ${error.message}`)
    }

    // Buscar nomes dos usuários separadamente
    if (data && data.length > 0) {
      const userIds = new Set<string>()
      data.forEach(comanda => {
        if (comanda.criado_por) userIds.add(comanda.criado_por)
        if (comanda.finalizado_por) userIds.add(comanda.finalizado_por)
      })

      if (userIds.size > 0) {
        const { data: users } = await supabase
          .from('funcionarios')
          .select('user_id, nome, email')
          .in('user_id', Array.from(userIds))

        const userMap = new Map(users?.map(u => [u.user_id, { nome: u.nome, email: u.email }]) || [])

        return data.map(comanda => ({
          ...comanda,
          criador: comanda.criado_por ? {
            id: comanda.criado_por,
            email: userMap.get(comanda.criado_por)?.nome || userMap.get(comanda.criado_por)?.email || ''
          } : undefined,
          finalizador: comanda.finalizado_por ? {
            id: comanda.finalizado_por,
            email: userMap.get(comanda.finalizado_por)?.nome || userMap.get(comanda.finalizado_por)?.email || ''
          } : undefined
        }))
      }
    }

    return data || []
  },

  /**
   * Buscar histórico por número de comanda
   * @param numeroComanda - Número da comanda
   * @param limite - Limite de registros a retornar (padrão: 50)
   * @returns Array de comandas do histórico
   */
  async buscarPorNumero(numeroComanda: number, limite: number = 50): Promise<HistoricoComandaSupabase[]> {
    const { data, error } = await supabase
      .from('historico_comandas')
      .select('*')
      .eq('numero_comanda', numeroComanda)
      .order('finalizado_em', { ascending: false })
      .limit(limite)

    if (error) {
      console.error('Erro ao buscar histórico por número:', error)
      throw new Error(`Erro ao buscar histórico por número: ${error.message}`)
    }

    return data || []
  },

  /**
   * Buscar histórico por período
   * @param dataInicio - Data inicial (formato ISO 8601)
   * @param dataFim - Data final (formato ISO 8601)
   * @returns Array de comandas do histórico
   */
  async buscarPorPeriodo(dataInicio: string, dataFim: string): Promise<HistoricoComandaSupabase[]> {
    const { data, error } = await supabase
      .from('historico_comandas')
      .select('*')
      .gte('finalizado_em', dataInicio)
      .lte('finalizado_em', dataFim)
      .order('finalizado_em', { ascending: false })

    if (error) {
      console.error('Erro ao buscar histórico por período:', error)
      throw new Error(`Erro ao buscar histórico por período: ${error.message}`)
    }

    return data || []
  }
}

// Export nomeado
export { historicoComandaServiceImpl as historicoComandaService }

// Export default
export default historicoComandaServiceImpl

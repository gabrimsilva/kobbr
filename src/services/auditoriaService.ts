/**
 * Serviço de Auditoria (multi-tenant)
 *
 * Registra e consulta ações relevantes em `logs_auditoria`. O registro é
 * NÃO BLOQUEANTE: falhas ao gravar auditoria nunca propagam erro para a ação
 * de negócio que a originou (Req 9.7, Property 12). A consulta é paginada e
 * escopada por estabelecimento via RLS (Req 9.4, 9.5).
 *
 * @module services/auditoriaService
 */

import { supabase } from '@/lib/supabase'
import type { LogAuditoria } from '@/types/estabelecimento'
import { getEstabelecimentoAtivo } from './tenant'

export type RegistroAuditoria = {
  acao: string
  descricao: string
  estabelecimento_id?: string | null
  metadata?: Record<string, unknown> | null
}

const TAMANHO_PAGINA = 50

export interface AuditoriaService {
  registrar(registro: RegistroAuditoria): Promise<void>
  listar(pagina?: number): Promise<{ registros: LogAuditoria[]; pagina: number; temMais: boolean }>
}

export const auditoriaService: AuditoriaService = {
  /**
   * Registra uma ação de auditoria. Nunca lança — apenas loga no console em
   * caso de falha (Property 12). A ação de negócio não deve ser revertida por
   * causa de uma falha de auditoria.
   */
  async registrar(registro: RegistroAuditoria): Promise<void> {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      const estabId = registro.estabelecimento_id ?? getEstabelecimentoAtivo()

      const descricao = (registro.descricao || '').slice(0, 500)

      const { error } = await supabase.from('logs_auditoria').insert({
        usuario_id: user?.id ?? null,
        estabelecimento_id: estabId,
        acao: registro.acao.slice(0, 80),
        descricao,
        metadata: registro.metadata ?? null,
      })

      if (error) {
        console.warn('Falha ao registrar auditoria (ação preservada):', error.message)
      }
    } catch (err) {
      // Auditoria nunca bloqueia a operação principal
      console.warn('Falha ao registrar auditoria (ação preservada):', err)
    }
  },

  /**
   * Lista registros de auditoria em ordem cronológica decrescente, paginados
   * (≤50 por página). A RLS limita aos estabelecimentos autorizados (Req 9.4/9.5).
   */
  async listar(pagina = 0): Promise<{ registros: LogAuditoria[]; pagina: number; temMais: boolean }> {
    const inicio = pagina * TAMANHO_PAGINA
    const fim = inicio + TAMANHO_PAGINA // busca 1 a mais para saber se há próxima página

    const { data, error } = await supabase
      .from('logs_auditoria')
      .select('*')
      .order('criado_em', { ascending: false })
      .range(inicio, fim)

    if (error) {
      console.error('Erro ao listar auditoria:', error)
      throw new Error(`Falha ao listar auditoria: ${error.message}`)
    }

    const linhas = data || []
    const temMais = linhas.length > TAMANHO_PAGINA
    return {
      registros: temMais ? linhas.slice(0, TAMANHO_PAGINA) : linhas,
      pagina,
      temMais,
    }
  },
}

export default auditoriaService

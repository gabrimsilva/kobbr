/**
 * Serviço para gerenciamento de configurações do sistema
 *
 * Este serviço gerencia todas as configurações chave-valor do sistema,
 * com suporte a cache para melhor performance.
 *
 * @module services/configuracaoService
 */

import { supabase } from "@/lib/supabase"
import { comTenant, getEstabelecimentoAtivo } from "./tenant"
import type { ConfiguracaoSupabase } from '@/types/supabase'
import { CACHE_DURATIONS } from '@/constants/timers'

// Cache de configurações (por estabelecimento — multi-tenant).
// A chave do cache é o id do estabelecimento ativo (ou 'global' quando não há
// estabelecimento selecionado, ex.: páginas públicas/login).
const configuracoesCache = new Map<string, {
  data: ConfiguracaoSupabase[]
  timestamp: number
}>()

const CACHE_DURATION = CACHE_DURATIONS.CONFIGURACOES

/** Chave de cache derivada do estabelecimento ativo. */
function chaveCache(): string {
  return getEstabelecimentoAtivo() ?? 'global'
}

/**
 * Interface do serviço de configurações
 */
export interface ConfiguracaoService {
  /**
   * Limpa o cache de configurações
   */
  limparCache(): void

  /**
   * Busca todas as configurações com cache opcional
   * @param useCache - Se deve usar cache (padrão: true)
   * @returns Promise com array de configurações
   */
  buscarTodas(useCache?: boolean): Promise<ConfiguracaoSupabase[]>

  /**
   * Busca múltiplas configurações de uma vez (otimizado para evitar N+1)
   * @param chaves - Array de chaves para buscar
   * @returns Promise com Map chave -> ConfiguracaoSupabase
   */
  buscarMultiplas(chaves: string[]): Promise<Map<string, ConfiguracaoSupabase | null>>

  /**
   * Busca configuração por chave
   * @param chave - Chave da configuração
   * @returns Promise com a configuração ou null
   */
  buscarPorChave(chave: string): Promise<ConfiguracaoSupabase | null>

  /**
   * Atualiza uma configuração existente
   * @param chave - Chave da configuração
   * @param valor - Novo valor
   * @returns Promise com a configuração atualizada
   */
  atualizar(chave: string, valor: string): Promise<ConfiguracaoSupabase>

  /**
   * Cria uma nova configuração
   * @param config - Dados da configuração
   * @returns Promise com a configuração criada
   */
  criar(config: Omit<ConfiguracaoSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<ConfiguracaoSupabase>

  /**
   * Salva configuração (cria ou atualiza - upsert)
   * @param chave - Chave da configuração
   * @param valor - Valor da configuração
   * @param descricao - Descrição opcional
   * @param tipo - Tipo do valor
   * @param categoria - Categoria da configuração
   * @returns Promise com a configuração salva
   */
  salvar(
    chave: string,
    valor: string,
    descricao?: string,
    tipo?: 'texto' | 'numero' | 'booleano' | 'json',
    categoria?: string
  ): Promise<ConfiguracaoSupabase>
}

/**
 * Implementação do serviço de configurações
 */
export const configuracaoService: ConfiguracaoService = {
  /**
   * Limpa o cache de configurações forçando nova busca
   */
  limparCache(): void {
    configuracoesCache.clear()
  },

  /**
   * Busca todas as configurações ordenadas por categoria e chave
   * (escopadas ao estabelecimento ativo — multi-tenant)
   */
  async buscarTodas(useCache: boolean = true): Promise<ConfiguracaoSupabase[]> {
    const estabId = getEstabelecimentoAtivo()
    const cacheKey = chaveCache()

    // Verificar cache (por estabelecimento)
    const cached = configuracoesCache.get(cacheKey)
    if (useCache && cached && Date.now() - cached.timestamp < CACHE_DURATION) {
      return cached.data
    }

    let query = supabase
      .from('configuracoes')
      .select('*')
    if (estabId) query = query.eq('estabelecimento_id', estabId)
    const { data, error } = await query
      .order('categoria', { ascending: true })
      .order('chave', { ascending: true })

    if (error) {
      console.error('Erro ao buscar configurações:', error)
      throw new Error(`Falha ao buscar configurações: ${error.message}`)
    }

    // Atualizar cache (por estabelecimento)
    configuracoesCache.set(cacheKey, {
      data: data || [],
      timestamp: Date.now()
    })

    return data || []
  },

  /**
   * Busca múltiplas configurações em uma única query (otimizado)
   * (escopadas ao estabelecimento ativo — multi-tenant)
   */
  async buscarMultiplas(chaves: string[]): Promise<Map<string, ConfiguracaoSupabase | null>> {
    let query = supabase
      .from('configuracoes')
      .select('*')
      .in('chave', chaves)
    const estabId = getEstabelecimentoAtivo()
    if (estabId) query = query.eq('estabelecimento_id', estabId)
    const { data, error } = await query

    if (error) {
      console.error('Erro ao buscar configurações:', error)
      throw new Error(`Falha ao buscar configurações: ${error.message}`)
    }

    // Criar map para acesso rápido
    const resultado = new Map<string, ConfiguracaoSupabase | null>()

    // Inicializar todas as chaves com null
    chaves.forEach(chave => resultado.set(chave, null))

    // Preencher com dados encontrados
    data?.forEach(config => {
      resultado.set(config.chave, config)
    })

    return resultado
  },

  /**
   * Busca configuração específica por chave
   * (escopada ao estabelecimento ativo — multi-tenant)
   */
  async buscarPorChave(chave: string): Promise<ConfiguracaoSupabase | null> {
    let query = supabase
      .from('configuracoes')
      .select('*')
      .eq('chave', chave)
    const estabId = getEstabelecimentoAtivo()
    if (estabId) query = query.eq('estabelecimento_id', estabId)
    // limit(1) + maybeSingle: com UNIQUE(estabelecimento_id, chave) há no máx. 1
    // linha por estabelecimento; sem estabelecimento ativo evita erro de
    // múltiplas linhas (uma por estabelecimento).
    const { data, error } = await query.limit(1).maybeSingle()

    if (error) {
      console.error('Erro ao buscar configuração:', error)
      throw new Error(`Falha ao buscar configuração: ${error.message}`)
    }

    return data
  },

  /**
   * Atualiza valor de configuração existente
   */
  async atualizar(chave: string, valor: string): Promise<ConfiguracaoSupabase> {
    let query = supabase
      .from('configuracoes')
      .update({ valor, atualizado_em: new Date().toISOString() })
      .eq('chave', chave)
    const estabId = getEstabelecimentoAtivo()
    if (estabId) query = query.eq('estabelecimento_id', estabId)
    const { data, error } = await query
      .select()
      .single()

    if (error) {
      console.error('Erro ao atualizar configuração:', error)
      throw new Error(`Falha ao atualizar configuração: ${error.message}`)
    }

    if (!data) {
      throw new Error('Configuração não encontrada')
    }

    // Invalidar cache
    configuracaoService.limparCache()

    return data
  },

  /**
   * Cria nova configuração
   */
  async criar(config: Omit<ConfiguracaoSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<ConfiguracaoSupabase> {
    const { data, error } = await supabase
      .from('configuracoes')
      .insert(comTenant(config as Record<string, unknown>))
      .select()
      .single()

    if (error) {
      console.error('Erro ao criar configuração:', error)
      throw new Error(`Falha ao criar configuração: ${error.message}`)
    }

    if (!data) {
      throw new Error('Configuração não foi criada corretamente')
    }

    // Invalidar cache
    configuracaoService.limparCache()

    return data
  },

  /**
   * Salva configuração (upsert: cria se não existe, atualiza se existe)
   */
  async salvar(
    chave: string,
    valor: string,
    descricao?: string,
    tipo: 'texto' | 'numero' | 'booleano' | 'json' = 'texto',
    categoria: string = 'geral'
  ): Promise<ConfiguracaoSupabase> {
    // Primeiro, tentar atualizar (escopado ao estabelecimento ativo)
    const estabId = getEstabelecimentoAtivo()
    let updateQuery = supabase
      .from('configuracoes')
      .update({
        valor,
        descricao,
        tipo,
        categoria,
        atualizado_em: new Date().toISOString()
      })
      .eq('chave', chave)
    if (estabId) updateQuery = updateQuery.eq('estabelecimento_id', estabId)
    const { data: updateData, error: updateError } = await updateQuery
      .select()
      .single()

    if (updateData) {
      // Invalidar cache
      configuracaoService.limparCache()
      return updateData
    }

    // Se não existir, criar nova
    if (updateError && updateError.code === 'PGRST116') {
      const { data: insertData, error: insertError } = await supabase
        .from('configuracoes')
        .insert(comTenant({
          chave,
          valor,
          descricao,
          tipo,
          categoria
        }))
        .select()
        .single()

      if (insertError) {
        console.error('Erro ao criar configuração:', insertError)
        throw new Error(`Falha ao criar configuração: ${insertError.message}`)
      }

      if (!insertData) {
        throw new Error('Configuração não foi criada corretamente')
      }

      // Invalidar cache
      configuracaoService.limparCache()
      return insertData
    }

    // Se houve outro erro
    console.error('Erro ao salvar configuração:', updateError)
    throw new Error(`Falha ao salvar configuração: ${updateError?.message}`)
  }
}

/**
 * Exportar como default para facilitar importação
 */
export default configuracaoService

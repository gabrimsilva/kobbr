import { configuracaoService } from '@/services'
import { getEstabelecimentoAtivo } from '@/services/tenant'

// Cache local das configurações (namespaced por estabelecimento — multi-tenant).
// As chaves do cache têm o formato `${estabId}:${chave}` para evitar vazamento
// de configurações entre estabelecimentos.
let configCache: Record<string, string> = {}
let cacheTimestamp = 0
const CACHE_DURATION = 5 * 60 * 1000 // 5 minutos
const STORAGE_KEY = 'loja-config-cache'

/** Prefixo de cache do estabelecimento ativo (ou 'global'). */
const nsAtual = (): string => getEstabelecimentoAtivo() ?? 'global'
/** Chave de cache namespaced por estabelecimento. */
const ck = (chave: string): string => `${nsAtual()}:${chave}`

// Carregar cache do localStorage na inicialização
try {
  const savedCache = localStorage.getItem(STORAGE_KEY)
  if (savedCache) {
    const parsed = JSON.parse(savedCache)
    configCache = parsed.data || {}
    cacheTimestamp = parsed.timestamp || 0
  }
} catch (error) {
  // Erro ao carregar cache do localStorage
}

// Configurações padrão para fallback
const CONFIG_DEFAULTS: Record<string, string> = {
  'modo_cardapio_whatsapp': 'false',
  'tipo_checkout': 'step-by-step', // Padrão para step-by-step
  'nome_loja': 'Sua Empresa',
  'endereco_loja': 'Rua Exemplo, 123 - Centro',
  'whatsapp_loja': '(41) 9 9999-9999',
  'logo_url': '',
  'banner_url': '',
  'metodos_pagamento': JSON.stringify(['dinheiro', 'cartao_debito', 'cartao_credito', 'pix'])
}

// Função para verificar se o cache é válido
const isCacheValid = (): boolean => {
  return Date.now() - cacheTimestamp < CACHE_DURATION
}

// Função para salvar cache no localStorage
const salvarCacheNoStorage = (): void => {
  try {
    const cacheData = {
      data: configCache,
      timestamp: cacheTimestamp
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(cacheData))
  } catch (error) {
    // Erro ao salvar cache no localStorage
  }
}

// Função para buscar configurações do Supabase com fallback
export const buscarConfiguracaoSegura = async (chave: string): Promise<{ valor: string } | null> => {
  // 1. Verificar cache primeiro (namespaced por estabelecimento)
  if (isCacheValid() && configCache[ck(chave)]) {
    return { valor: configCache[ck(chave)] }
  }

  try {
    // 2. Tentar buscar do Supabase
    const config = await configuracaoService.buscarPorChave(chave)

    if (config?.valor) {
      // Atualizar cache
      configCache[ck(chave)] = config.valor
      cacheTimestamp = Date.now()
      // Salvar no localStorage
      salvarCacheNoStorage()
      return config
    }
  } catch (error) {
    // Erro ao buscar configuração do Supabase
  }

  // 3. Usar valor padrão como fallback
  const valorPadrao = CONFIG_DEFAULTS[chave]
  if (valorPadrao !== undefined) {
    // Atualizar cache com valor padrão
    configCache[ck(chave)] = valorPadrao
    cacheTimestamp = Date.now()
    // Salvar no localStorage
    salvarCacheNoStorage()
    return { valor: valorPadrao }
  }

  return null
}

// Função para buscar múltiplas configurações
export const buscarMultiplasConfiguracoes = async (chaves: string[]): Promise<Record<string, string>> => {
  const resultado: Record<string, string> = {}

  // Buscar todas em paralelo
  const promessas = chaves.map(async (chave) => {
    const config = await buscarConfiguracaoSegura(chave)
    if (config?.valor) {
      resultado[chave] = config.valor
    }
  })

  await Promise.all(promessas)

  return resultado
}

// Função para limpar cache (útil para testes)
export const limparCache = (): void => {
  configCache = {}
  cacheTimestamp = 0
  try {
    localStorage.removeItem(STORAGE_KEY)
  } catch (error) {
    // Erro ao limpar cache do localStorage
  }
}

// Função para invalidar cache de uma chave específica
export const invalidarCacheChave = (chave: string): void => {
  if (configCache[ck(chave)]) {
    delete configCache[ck(chave)]
    // Atualizar localStorage
    salvarCacheNoStorage()
  }
}

// Função para pré-carregar configurações essenciais
export const preCarregarConfiguracoes = async (): Promise<void> => {
  const chavesEssenciais = [
    'modo_cardapio_whatsapp',
    'tipo_checkout',
    'nome_loja',
    'whatsapp_loja'
  ]

  await buscarMultiplasConfiguracoes(chavesEssenciais)
}

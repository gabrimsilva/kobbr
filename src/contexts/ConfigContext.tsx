import { createContext, useContext, useEffect, useState } from 'react'
import type { ReactNode } from 'react'
import { configuracaoService } from '@/services'
import { useFavicon } from '@/hooks/useFavicon'

interface ConfigContextType {
  faviconUrl: string
  logoUrl: string
  nomeEstabelecimento: string
  modoCardapioWhatsapp: boolean
  tipoCheckout: 'normal' | 'step-by-step'
  loading: boolean
}

const ConfigContext = createContext<ConfigContextType | undefined>(undefined)

export const useConfig = () => {
  const context = useContext(ConfigContext)
  if (context === undefined) {
    throw new Error('useConfig must be used within a ConfigProvider')
  }
  return context
}

interface ConfigProviderProps {
  children: ReactNode
}

export const ConfigProvider = ({ children }: ConfigProviderProps) => {
  const [config, setConfig] = useState({
    faviconUrl: '',
    logoUrl: '',
    nomeEstabelecimento: 'Sua Empresa',
    modoCardapioWhatsapp: false,
    tipoCheckout: 'step-by-step' as 'normal' | 'step-by-step'
  })
  const [loading, setLoading] = useState(true)

  // Aplicar o favicon quando ele mudar
  useFavicon(config.faviconUrl)

  // Atualizar o título da página quando o nome do estabelecimento mudar
  useEffect(() => {
    if (config.nomeEstabelecimento) {
      document.title = config.nomeEstabelecimento
    }
  }, [config.nomeEstabelecimento])

  useEffect(() => {
    const carregarConfiguracoes = async () => {
      try {
        const [faviconConfig, logoConfig, nomeConfig, modoCardapioConfig, tipoCheckoutConfig] = await Promise.all([
          configuracaoService.buscarPorChave('favicon_url').catch(() => null),
          configuracaoService.buscarPorChave('logo_url').catch(() => null),
          configuracaoService.buscarPorChave('nome_loja').catch(() => null),
          configuracaoService.buscarPorChave('modo_cardapio_whatsapp').catch(() => null),
          configuracaoService.buscarPorChave('tipo_checkout').catch(() => null)
        ])

        const novaConfig = {
          faviconUrl: faviconConfig?.valor || '',
          logoUrl: logoConfig?.valor || '',
          nomeEstabelecimento: nomeConfig?.valor || 'Sua Empresa',
          modoCardapioWhatsapp: modoCardapioConfig?.valor === 'true',
          tipoCheckout: (tipoCheckoutConfig?.valor as 'normal' | 'step-by-step') || 'step-by-step'
        }

        setConfig(novaConfig)
      } catch (error) {
        console.error('Erro ao carregar configurações globais:', error)
      } finally {
        setLoading(false)
      }
    }

    carregarConfiguracoes()
  }, [])

  return (
    <ConfigContext.Provider value={{ ...config, loading }}>
      {children}
    </ConfigContext.Provider>
  )
}
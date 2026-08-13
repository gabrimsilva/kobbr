import { useState, useEffect } from 'react'
import { configuracaoService } from "@/services"

interface ConfiguracoesLoja {
  nome: string
  endereco: string
  telefone: string
  email?: string
}

export function useConfiguracoesLoja() {
  const [configuracoes, setConfiguracoes] = useState<ConfiguracoesLoja>({
    nome: 'SUA EMPRESA',
    endereco: 'Rua Exemplo, 123 - Centro',
    telefone: '(11) 99999-9999',
    email: ''
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    carregarConfiguracoes()
  }, [])

  const carregarConfiguracoes = async () => {
    try {
      // Buscar configurações específicas
      const configs = await Promise.all([
        configuracaoService.buscarPorChave('nome_loja'),
        configuracaoService.buscarPorChave('endereco_loja'),
        configuracaoService.buscarPorChave('telefone_loja'),
        configuracaoService.buscarPorChave('email_loja')
      ])

      const [nome, endereco, telefone, email] = configs

      setConfiguracoes({
        nome: nome?.valor || 'SUA EMPRESA',
        endereco: endereco?.valor || 'Rua Exemplo, 123 - Centro',
        telefone: telefone?.valor || '(11) 99999-9999',
        email: email?.valor || ''
      })
    } catch (error) {
      console.error('Erro ao carregar configurações:', error)
    } finally {
      setLoading(false)
    }
  }

  return { configuracoes, loading }
}
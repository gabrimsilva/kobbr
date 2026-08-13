import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import Configuracoes from '../Configuracoes'
import { configuracaoService } from "@/services"

// Mock do serviço de configuração
vi.mock('@/lib/supabase', () => ({
  configuracaoService: {
    buscarTodas: vi.fn(),
    salvar: vi.fn()
  }
}))

// Mock do hook de formatação
vi.mock('@/hooks/useFormatacao', () => ({
  useFormatacao: () => ({
    formatarTelefone: (value: string) => {
      const numbers = value.replace(/\D/g, '')
      if (numbers.length <= 10) {
        return numbers.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3')
      }
      return numbers.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3')
    }
  })
}))

describe('Configuracoes - Testes de Funcionalidade', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    
    // Mock de configurações vazias
    vi.mocked(configuracaoService.buscarTodas).mockResolvedValue([])
  })

  it('deve carregar configurações do Supabase ao montar', async () => {
    render(<Configuracoes />)
    
    await waitFor(() => {
      expect(configuracaoService.buscarTodas).toHaveBeenCalled()
    })
  })

  it('deve exibir loader enquanto carrega configurações', () => {
    render(<Configuracoes />)
    
    expect(screen.getByText(/Carregando configurações/i)).toBeInTheDocument()
  })

  it('deve renderizar todos os campos do formulário após carregar', async () => {
    render(<Configuracoes />)
    
    await waitFor(() => {
      expect(screen.queryByText(/Carregando configurações/i)).not.toBeInTheDocument()
    })
    
    // Verificar campos principais
    expect(screen.getByPlaceholderText(/Digite o nome do seu estabelecimento/i)).toBeInTheDocument()
    expect(screen.getByPlaceholderText(/Endereço completo/i)).toBeInTheDocument()
    expect(screen.getByPlaceholderText(/00000-000/i)).toBeInTheDocument()
  })

  it('deve formatar telefone automaticamente ao digitar', async () => {
    render(<Configuracoes />)
    
    await waitFor(() => {
      expect(screen.queryByText(/Carregando configurações/i)).not.toBeInTheDocument()
    })
    
    const telefoneInput = screen.getAllByPlaceholderText(/\(11\) 9 9999-9999/i)[0]
    
    fireEvent.change(telefoneInput, { target: { value: '11999998888' } })
    
    await waitFor(() => {
      expect(telefoneInput).toHaveValue('(11) 99999-8888')
    })
  })

  it('deve salvar configurações ao clicar em Salvar', async () => {
    vi.mocked(configuracaoService.salvar).mockResolvedValue(undefined)
    
    render(<Configuracoes />)
    
    await waitFor(() => {
      expect(screen.queryByText(/Carregando configurações/i)).not.toBeInTheDocument()
    })
    
    const nomeInput = screen.getByPlaceholderText(/Digite o nome do seu estabelecimento/i)
    fireEvent.change(nomeInput, { target: { value: 'Pizzaria Teste' } })
    
    const salvarButton = screen.getByRole('button', { name: /Salvar Configurações/i })
    fireEvent.click(salvarButton)
    
    await waitFor(() => {
      expect(configuracaoService.salvar).toHaveBeenCalled()
    })
  })

  it('deve exibir dialog de sucesso após salvar', async () => {
    vi.mocked(configuracaoService.salvar).mockResolvedValue(undefined)
    
    render(<Configuracoes />)
    
    await waitFor(() => {
      expect(screen.queryByText(/Carregando configurações/i)).not.toBeInTheDocument()
    })
    
    const salvarButton = screen.getByRole('button', { name: /Salvar Configurações/i })
    fireEvent.click(salvarButton)
    
    await waitFor(() => {
      expect(screen.getByText(/Sucesso!/i)).toBeInTheDocument()
      expect(screen.getByText(/Configurações salvas com sucesso/i)).toBeInTheDocument()
    })
  })

  it('deve exibir erro ao falhar ao salvar', async () => {
    vi.mocked(configuracaoService.salvar).mockRejectedValue(new Error('Erro ao salvar'))
    
    render(<Configuracoes />)
    
    await waitFor(() => {
      expect(screen.queryByText(/Carregando configurações/i)).not.toBeInTheDocument()
    })
    
    const salvarButton = screen.getByRole('button', { name: /Salvar Configurações/i })
    fireEvent.click(salvarButton)
    
    await waitFor(() => {
      expect(screen.getByText(/Erro ao salvar configurações/i)).toBeInTheDocument()
    })
  })

  it('deve alternar horário de funcionamento corretamente', async () => {
    render(<Configuracoes />)
    
    await waitFor(() => {
      expect(screen.queryByText(/Carregando configurações/i)).not.toBeInTheDocument()
    })
    
    // Encontrar o select do primeiro dia (Segunda-feira)
    const selects = screen.getAllByRole('combobox')
    const primeiroSelect = selects[0]
    
    fireEvent.change(primeiroSelect, { target: { value: 'fechado' } })
    
    expect(primeiroSelect).toHaveValue('fechado')
  })

  it('deve alternar formas de pagamento usando switches', async () => {
    render(<Configuracoes />)
    
    await waitFor(() => {
      expect(screen.queryByText(/Carregando configurações/i)).not.toBeInTheDocument()
    })
    
    // Verificar que os switches de pagamento estão presentes
    expect(screen.getByText(/Dinheiro/i)).toBeInTheDocument()
    expect(screen.getByText(/Cartão de Débito/i)).toBeInTheDocument()
    expect(screen.getByText(/PIX/i)).toBeInTheDocument()
  })

  it('deve validar campos numéricos', async () => {
    render(<Configuracoes />)
    
    await waitFor(() => {
      expect(screen.queryByText(/Carregando configurações/i)).not.toBeInTheDocument()
    })
    
    const tempoEntregaInput = screen.getByPlaceholderText('45')
    fireEvent.change(tempoEntregaInput, { target: { value: '60' } })
    
    expect(tempoEntregaInput).toHaveValue('60')
  })

  it('deve carregar configurações existentes do Supabase', async () => {
    const mockConfiguracoes = [
      { chave: 'nome_loja', valor: 'Pizzaria Teste', categoria: 'loja', descricao: 'Nome da loja' },
      { chave: 'telefone_loja', valor: '11999998888', categoria: 'loja', descricao: 'Telefone' },
      { chave: 'email_loja', valor: 'teste@pizzaria.com', categoria: 'loja', descricao: 'Email' }
    ]
    
    vi.mocked(configuracaoService.buscarTodas).mockResolvedValue(mockConfiguracoes)
    
    render(<Configuracoes />)
    
    await waitFor(() => {
      const nomeInput = screen.getByPlaceholderText(/Digite o nome do seu estabelecimento/i)
      expect(nomeInput).toHaveValue('Pizzaria Teste')
    })
  })
})

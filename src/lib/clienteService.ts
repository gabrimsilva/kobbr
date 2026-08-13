import { supabase } from './supabase'

export interface Cliente {
  id: string
  nome: string
  sobrenome: string
  cpf?: string
  telefone: string
  email?: string
  cep?: string
  endereco?: string
  numero?: string
  complemento?: string
  bairro?: string
  cidade?: string
  estado?: string
  total_pedidos: number
  valor_total_gasto: number
  ultimo_pedido_em?: string
  criado_em: string
  atualizado_em: string
}

export interface NovoCliente {
  nome: string
  sobrenome: string
  cpf?: string
  telefone: string
  email?: string
  cep?: string
  endereco?: string
  numero?: string
  complemento?: string
  bairro?: string
  cidade?: string
  estado?: string
}

class ClienteService {
  async buscarTodos(): Promise<Cliente[]> {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .order('criado_em', { ascending: false })

    if (error) {
      console.error('Erro ao buscar clientes:', error)
      throw error
    }

    return data || []
  }

  async buscarPorId(id: string): Promise<Cliente | null> {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .eq('id', id)
      .single()

    if (error) {
      console.error('Erro ao buscar cliente por ID:', error)
      throw error
    }

    return data
  }

  async buscarPorTelefone(telefone: string): Promise<Cliente | null> {
    try {
      // Extrair apenas números do telefone
      const telefoneNumeros = telefone.replace(/\D/g, '')
      
      if (telefoneNumeros.length < 10) {
        return null
      }

      // Buscar todos os clientes e filtrar no código
      const { data, error } = await supabase
        .from('clientes')
        .select('*')
        .order('total_pedidos', { ascending: false })
        .order('ultimo_pedido_em', { ascending: false, nullsFirst: false })
        .order('criado_em', { ascending: false })

      if (error) {
        console.error('Erro ao buscar clientes:', error)
        return null
      }

      if (!data || data.length === 0) {
        return null
      }

      // Filtrar clientes que contenham os números do telefone
      const clientesFiltrados = data.filter(cliente => {
        const clienteTelefoneNumeros = cliente.telefone?.replace(/\D/g, '') || ''
        return clienteTelefoneNumeros.includes(telefoneNumeros)
      })

      if (clientesFiltrados.length === 0) {
        return null
      }

      // Priorizar cliente com mais dados preenchidos
      const clienteCompleto = clientesFiltrados.find(cliente => 
        cliente.nome && cliente.endereco && cliente.cep && cliente.cidade
      )
      
      if (clienteCompleto) {
        return clienteCompleto
      }
      
      // Se não há cliente completo, retornar o primeiro (mais pedidos/mais recente)
      return clientesFiltrados[0]
    } catch (error) {
      console.error('Erro ao buscar cliente por telefone:', error)
      return null
    }
  }

  async buscarPorCPF(cpf: string): Promise<Cliente | null> {
    if (!cpf) return null

    // Limpar CPF para busca (remover formatação)
    const cpfNumeros = cpf.replace(/\D/g, '')
    
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .or(`cpf.eq.${cpf},cpf.like.%${cpfNumeros}%`)
      .limit(1)
      .maybeSingle()

    if (error) {
      console.error('Erro ao buscar cliente por CPF:', error)
      return null // Não lançar erro, apenas retornar null
    }

    return data
  }

  async criar(cliente: NovoCliente): Promise<Cliente> {
    const { data, error } = await supabase
      .from('clientes')
      .insert([cliente])
      .select()
      .single()

    if (error) {
      console.error('Erro ao criar cliente:', error)
      throw error
    }

    return data
  }

  async atualizar(id: string, cliente: Partial<NovoCliente>): Promise<Cliente> {
    const { data, error } = await supabase
      .from('clientes')
      .update({
        ...cliente,
        atualizado_em: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Erro ao atualizar cliente:', error)
      throw error
    }

    return data
  }

  async incrementarEstatisticas(id: string, valorPedido: number): Promise<void> {
    // Buscar dados atuais do cliente
    const cliente = await this.buscarPorId(id)
    if (!cliente) {
      throw new Error('Cliente não encontrado')
    }

    // Incrementar estatísticas
    const { error } = await supabase
      .from('clientes')
      .update({
        total_pedidos: cliente.total_pedidos + 1,
        valor_total_gasto: cliente.valor_total_gasto + valorPedido,
        ultimo_pedido_em: new Date().toISOString(),
        atualizado_em: new Date().toISOString()
      })
      .eq('id', id)

    if (error) {
      console.error('Erro ao incrementar estatísticas do cliente:', error)
      throw error
    }
  }

  async decrementarEstatisticas(id: string, valorPedido: number): Promise<void> {
    // Buscar dados atuais do cliente
    const cliente = await this.buscarPorId(id)
    if (!cliente) {
      throw new Error('Cliente não encontrado')
    }

    // Decrementar estatísticas (não deixar valores negativos)
    const novoTotalPedidos = Math.max(0, cliente.total_pedidos - 1)
    const novoValorGasto = Math.max(0, cliente.valor_total_gasto - valorPedido)

    const { error } = await supabase
      .from('clientes')
      .update({
        total_pedidos: novoTotalPedidos,
        valor_total_gasto: novoValorGasto,
        atualizado_em: new Date().toISOString()
      })
      .eq('id', id)

    if (error) {
      console.error('Erro ao decrementar estatísticas do cliente:', error)
      throw error
    }
  }

  async buscarOuCriar(dadosCliente: NovoCliente): Promise<Cliente> {
    // Primeiro, tentar buscar por telefone
    let cliente = await this.buscarPorTelefone(dadosCliente.telefone)

    // Se não encontrou por telefone e tem CPF, tentar buscar por CPF
    if (!cliente && dadosCliente.cpf) {
      cliente = await this.buscarPorCPF(dadosCliente.cpf)
    }

    if (cliente) {
      // Cliente existe, atualizar dados se necessário
      const dadosAtualizados: Partial<NovoCliente> = {}
      
      // Atualizar campos que podem ter mudado ou estão vazios
      if (dadosCliente.nome && dadosCliente.nome !== cliente.nome) {
        dadosAtualizados.nome = dadosCliente.nome
      }
      if (dadosCliente.sobrenome && dadosCliente.sobrenome !== cliente.sobrenome) {
        dadosAtualizados.sobrenome = dadosCliente.sobrenome
      }
      if (dadosCliente.cpf && dadosCliente.cpf !== cliente.cpf) {
        dadosAtualizados.cpf = dadosCliente.cpf
      }
      if (dadosCliente.email && dadosCliente.email !== cliente.email) {
        dadosAtualizados.email = dadosCliente.email
      }
      
      // Para dados de endereço, só atualizar se o cliente não tem ou se mudou
      if (dadosCliente.cep && (!cliente.cep || dadosCliente.cep !== cliente.cep)) {
        dadosAtualizados.cep = dadosCliente.cep
      }
      if (dadosCliente.endereco && (!cliente.endereco || dadosCliente.endereco !== cliente.endereco)) {
        dadosAtualizados.endereco = dadosCliente.endereco
      }
      if (dadosCliente.numero && (!cliente.numero || dadosCliente.numero !== cliente.numero)) {
        dadosAtualizados.numero = dadosCliente.numero
      }
      if (dadosCliente.complemento !== cliente.complemento) {
        dadosAtualizados.complemento = dadosCliente.complemento
      }
      if (dadosCliente.bairro && (!cliente.bairro || dadosCliente.bairro !== cliente.bairro)) {
        dadosAtualizados.bairro = dadosCliente.bairro
      }
      if (dadosCliente.cidade && (!cliente.cidade || dadosCliente.cidade !== cliente.cidade)) {
        dadosAtualizados.cidade = dadosCliente.cidade
      }
      if (dadosCliente.estado && (!cliente.estado || dadosCliente.estado !== cliente.estado)) {
        dadosAtualizados.estado = dadosCliente.estado
      }

      // Se há dados para atualizar, fazer a atualização
      if (Object.keys(dadosAtualizados).length > 0) {
        console.log('Atualizando dados do cliente:', dadosAtualizados)
        cliente = await this.atualizar(cliente.id, dadosAtualizados)
      }

      return cliente
    } else {
      // Cliente não existe, criar novo
      console.log('Criando novo cliente:', dadosCliente)
      return await this.criar(dadosCliente)
    }
  }

  async buscarMelhoresClientes(limite: number = 10): Promise<Cliente[]> {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .order('valor_total_gasto', { ascending: false })
      .limit(limite)

    if (error) {
      console.error('Erro ao buscar melhores clientes:', error)
      throw error
    }

    return data || []
  }

  async buscarClientesRecentes(limite: number = 10): Promise<Cliente[]> {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .order('ultimo_pedido_em', { ascending: false })
      .limit(limite)

    if (error) {
      console.error('Erro ao buscar clientes recentes:', error)
      throw error
    }

    return data || []
  }

  async excluir(id: string): Promise<void> {
    const { error } = await supabase
      .from('clientes')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Erro ao excluir cliente:', error)
      throw error
    }
  }
}

export const clienteService = new ClienteService()
/**
 * Serviço para gerenciamento de clientes
 *
 * Este serviço encapsula todas as operações relacionadas a clientes,
 * incluindo cadastro, busca, atualização e estatísticas.
 *
 * @module services/clienteService
 */

import { supabase } from "@/lib/supabase"
import { comTenant, tenantId } from "./tenant"
import type { ClienteSupabase } from '@/types/supabase'

/**
 * Dados para criar um novo cliente
 */
export type NovoCliente = Omit<ClienteSupabase, 'id' | 'total_pedidos' | 'valor_total_gasto' | 'ultimo_pedido_em' | 'criado_em' | 'atualizado_em'>

/**
 * Interface do serviço de clientes
 */
export interface ClienteService {
  /**
   * Busca todos os clientes
   * @returns Promise com array de clientes
   */
  buscarTodos(): Promise<ClienteSupabase[]>

  /**
   * Busca cliente por ID
   * @param id - ID do cliente
   * @returns Promise com o cliente ou null
   */
  buscarPorId(id: string): Promise<ClienteSupabase | null>

  /**
   * Busca cliente por telefone
   * @param telefone - Telefone do cliente
   * @returns Promise com o cliente ou null
   */
  buscarPorTelefone(telefone: string): Promise<ClienteSupabase | null>

  /**
   * Busca cliente por CPF
   * @param cpf - CPF do cliente
   * @returns Promise com o cliente ou null
   */
  buscarPorCPF(cpf: string): Promise<ClienteSupabase | null>

  /**
   * Cria um novo cliente
   * @param cliente - Dados do cliente
   * @returns Promise com o cliente criado
   */
  criar(cliente: NovoCliente): Promise<ClienteSupabase>

  /**
   * Atualiza dados de um cliente
   * @param id - ID do cliente
   * @param cliente - Dados a atualizar
   * @returns Promise com o cliente atualizado
   */
  atualizar(id: string, cliente: Partial<NovoCliente>): Promise<ClienteSupabase>

  /**
   * Incrementa estatísticas do cliente após um pedido
   * @param id - ID do cliente
   * @param valorPedido - Valor do pedido
   */
  incrementarEstatisticas(id: string, valorPedido: number): Promise<void>

  /**
   * Decrementa estatísticas do cliente (cancelamento)
   * @param id - ID do cliente
   * @param valorPedido - Valor do pedido cancelado
   */
  decrementarEstatisticas(id: string, valorPedido: number): Promise<void>

  /**
   * Busca ou cria um cliente (usado no checkout)
   * @param dadosCliente - Dados do cliente
   * @returns Promise com o cliente encontrado ou criado
   */
  buscarOuCriar(dadosCliente: NovoCliente): Promise<ClienteSupabase>

  /**
   * Busca os melhores clientes por valor gasto
   * @param limite - Número de clientes a retornar
   * @returns Promise com array de clientes
   */
  buscarMelhoresClientes(limite?: number): Promise<ClienteSupabase[]>

  /**
   * Busca clientes com pedidos recentes
   * @param limite - Número de clientes a retornar
   * @returns Promise com array de clientes
   */
  buscarClientesRecentes(limite?: number): Promise<ClienteSupabase[]>

  /**
   * Exclui um cliente
   * @param id - ID do cliente
   */
  excluir(id: string): Promise<void>
}

/**
 * Implementação do serviço de clientes
 */
class ClienteServiceImpl implements ClienteService {
  async buscarTodos(): Promise<ClienteSupabase[]> {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .eq('estabelecimento_id', tenantId())
      .order('criado_em', { ascending: false })

    if (error) {
      console.error('Erro ao buscar clientes:', error)
      throw new Error(`Falha ao buscar clientes: ${error.message}`)
    }

    return data || []
  }

  async buscarPorId(id: string): Promise<ClienteSupabase | null> {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .eq('id', id)
      .single()

    if (error && error.code !== 'PGRST116') {
      console.error('Erro ao buscar cliente por ID:', error)
      throw new Error(`Falha ao buscar cliente: ${error.message}`)
    }

    return data
  }

  async buscarPorTelefone(telefone: string): Promise<ClienteSupabase | null> {
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
        .eq('estabelecimento_id', tenantId())
        .order('total_pedidos', { ascending: false })
        .order('ultimo_pedido_em', { ascending: false })
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

  async buscarPorCPF(cpf: string): Promise<ClienteSupabase | null> {
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
      return null
    }

    return data
  }

  async criar(cliente: NovoCliente): Promise<ClienteSupabase> {
    // Respeita estabelecimento_id já presente (checkout público por slug);
    // caso contrário injeta o tenant ativo da sessão.
    const payload = (cliente as Record<string, unknown>).estabelecimento_id
      ? cliente
      : comTenant(cliente as Record<string, unknown>)
    const { data, error } = await supabase
      .from('clientes')
      .insert([payload])
      .select()
      .single()

    if (error) {
      console.error('Erro ao criar cliente:', error)
      throw new Error(`Falha ao criar cliente: ${error.message}`)
    }

    if (!data) {
      throw new Error('Cliente não foi criado corretamente')
    }

    return data
  }

  async atualizar(id: string, cliente: Partial<NovoCliente>): Promise<ClienteSupabase> {
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
      throw new Error(`Falha ao atualizar cliente: ${error.message}`)
    }

    if (!data) {
      throw new Error('Cliente não encontrado')
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
        total_pedidos: (cliente.total_pedidos || 0) + 1,
        valor_total_gasto: (cliente.valor_total_gasto || 0) + valorPedido,
        ultimo_pedido_em: new Date().toISOString(),
        atualizado_em: new Date().toISOString()
      })
      .eq('id', id)

    if (error) {
      console.error('Erro ao incrementar estatísticas do cliente:', error)
      throw new Error(`Falha ao atualizar estatísticas: ${error.message}`)
    }
  }

  async decrementarEstatisticas(id: string, valorPedido: number): Promise<void> {
    const cliente = await this.buscarPorId(id)
    if (!cliente) {
      throw new Error('Cliente não encontrado')
    }

    // Decrementar estatísticas (não deixar valores negativos)
    const novoTotalPedidos = Math.max(0, (cliente.total_pedidos || 0) - 1)
    const novoValorGasto = Math.max(0, (cliente.valor_total_gasto || 0) - valorPedido)

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
      throw new Error(`Falha ao atualizar estatísticas: ${error.message}`)
    }
  }

  async buscarOuCriar(dadosCliente: NovoCliente): Promise<ClienteSupabase> {
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
        cliente = await this.atualizar(cliente.id, dadosAtualizados)
      }

      return cliente
    } else {
      // Cliente não existe, criar novo
      return await this.criar(dadosCliente)
    }
  }

  async buscarMelhoresClientes(limite: number = 10): Promise<ClienteSupabase[]> {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .eq('estabelecimento_id', tenantId())
      .order('valor_total_gasto', { ascending: false })
      .limit(limite)

    if (error) {
      console.error('Erro ao buscar melhores clientes:', error)
      throw new Error(`Falha ao buscar melhores clientes: ${error.message}`)
    }

    return data || []
  }

  async buscarClientesRecentes(limite: number = 10): Promise<ClienteSupabase[]> {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .eq('estabelecimento_id', tenantId())
      .order('ultimo_pedido_em', { ascending: false })
      .limit(limite)

    if (error) {
      console.error('Erro ao buscar clientes recentes:', error)
      throw new Error(`Falha ao buscar clientes recentes: ${error.message}`)
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
      throw new Error(`Falha ao excluir cliente: ${error.message}`)
    }
  }
}

/**
 * Instância exportada do serviço de clientes
 */
export const clienteService = new ClienteServiceImpl()

/**
 * Exportar como default para facilitar importação
 */
export default clienteService

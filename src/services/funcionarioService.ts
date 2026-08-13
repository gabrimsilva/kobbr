/**
 * Serviço para gerenciamento de funcionários
 *
 * Este serviço encapsula todas as operações relacionadas a funcionários,
 * incluindo criação de contas de acesso e filtros por função.
 *
 * @module services/funcionarioService
 */

import { supabase } from "@/lib/supabase"
import { comTenant } from "./tenant"
import type { FuncionarioSupabase } from '@/types/supabase'

/**
 * Interface do serviço de funcionários
 */
export interface FuncionarioService {
  /**
   * Busca todos os funcionários
   * @returns Promise com array de funcionários
   */
  buscarTodos(): Promise<FuncionarioSupabase[]>

  /**
   * Busca um funcionário por ID
   * @param id - ID do funcionário
   * @returns Promise com o funcionário ou null
   */
  buscarPorId(id: string): Promise<FuncionarioSupabase | null>

  /**
   * Cria um novo funcionário
   * @param data - Dados do funcionário
   * @returns Promise com o funcionário criado
   */
  criar(data: Omit<FuncionarioSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<FuncionarioSupabase>

  /**
   * Atualiza um funcionário existente
   * @param id - ID do funcionário
   * @param data - Dados para atualizar
   * @returns Promise com o funcionário atualizado
   */
  atualizar(id: string, data: Partial<FuncionarioSupabase>): Promise<FuncionarioSupabase>

  /**
   * Deleta um funcionário permanentemente
   * @param id - ID do funcionário
   */
  excluir(id: string): Promise<void>

  /**
   * Busca funcionários por cargo (compatibilidade)
   * @param cargo - Cargo do funcionário
   * @returns Promise com array de funcionários
   */
  buscarPorCargo(cargo: string): Promise<FuncionarioSupabase[]>

  /**
   * Busca funcionários por função
   * @param funcao - Função do funcionário
   * @returns Promise com array de funcionários
   */
  buscarPorFuncao(funcao: 'atendente' | 'garcom' | 'entregador'): Promise<FuncionarioSupabase[]>

  /**
   * Busca funcionário por email
   * @param email - Email do funcionário
   * @returns Promise com o funcionário ou null
   */
  buscarPorEmail(email: string): Promise<FuncionarioSupabase | null>

  /**
   * Cria funcionário com conta de acesso
   * @param data - Dados do funcionário com senha
   * @returns Promise com o funcionário criado
   */
  criarComAcesso(data: {
    nome: string
    funcao: 'atendente' | 'garcom' | 'entregador'
    telefone: string
    email: string
    senha: string
  }): Promise<FuncionarioSupabase>
}

/**
 * Implementação do serviço de funcionários
 */
export const funcionarioService: FuncionarioService = {
  /**
   * Busca todos os funcionários ordenados por nome
   */
  async buscarTodos(): Promise<FuncionarioSupabase[]> {
    const { data, error } = await supabase
      .from('funcionarios')
      .select('*')
      .order('nome', { ascending: true })

    if (error) {
      console.error('Erro ao buscar funcionários:', error)
      throw new Error(`Falha ao buscar funcionários: ${error.message}`)
    }

    return data || []
  },

  /**
   * Busca funcionário específico por ID
   */
  async buscarPorId(id: string): Promise<FuncionarioSupabase | null> {
    const { data, error } = await supabase
      .from('funcionarios')
      .select('*')
      .eq('id', id)
      .single()

    if (error) {
      if (error.code === 'PGRST116') {
        return null
      }
      console.error('Erro ao buscar funcionário:', error)
      throw new Error(`Falha ao buscar funcionário: ${error.message}`)
    }

    return data
  },

  /**
   * Cria um novo funcionário
   */
  async criar(data: Omit<FuncionarioSupabase, 'id' | 'criado_em' | 'atualizado_em'>): Promise<FuncionarioSupabase> {
    const { data: funcionario, error } = await supabase
      .from('funcionarios')
      .insert([comTenant(data as Record<string, unknown>)])
      .select()
      .single()

    if (error) {
      console.error('Erro ao criar funcionário:', error)
      throw new Error(`Falha ao criar funcionário: ${error.message}`)
    }

    if (!funcionario) {
      throw new Error('Funcionário não foi criado corretamente')
    }

    return funcionario
  },

  /**
   * Atualiza dados de um funcionário (mapeia função para cargo)
   */
  async atualizar(id: string, data: Partial<FuncionarioSupabase>): Promise<FuncionarioSupabase> {
    // Mapear funcao para cargo (compatibilidade)
    const cargoMap: Record<string, string> = {
      'atendente': 'Atendente',
      'garcom': 'Garçom',
      'entregador': 'Entregador'
    }

    // Se funcao foi alterada, atualizar cargo também
    const updateData = { ...data, atualizado_em: new Date().toISOString() }
    if (data.funcao) {
      updateData.cargo = cargoMap[data.funcao]
    }

    const { data: funcionario, error } = await supabase
      .from('funcionarios')
      .update(updateData)
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Erro ao atualizar funcionário:', error)
      throw new Error(`Falha ao atualizar funcionário: ${error.message}`)
    }

    if (!funcionario) {
      throw new Error('Funcionário não encontrado')
    }

    return funcionario
  },

  /**
   * Remove funcionário permanentemente
   */
  async excluir(id: string): Promise<void> {
    const { error } = await supabase
      .from('funcionarios')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Erro ao excluir funcionário:', error)
      throw new Error(`Falha ao excluir funcionário: ${error.message}`)
    }
  },

  /**
   * Busca funcionários por cargo (compatibilidade)
   */
  async buscarPorCargo(cargo: string): Promise<FuncionarioSupabase[]> {
    const { data, error } = await supabase
      .from('funcionarios')
      .select('*')
      .eq('cargo', cargo)
      .order('nome', { ascending: true })

    if (error) {
      console.error('Erro ao buscar funcionários por cargo:', error)
      throw new Error(`Falha ao buscar funcionários por cargo: ${error.message}`)
    }

    return data || []
  },

  /**
   * Busca funcionários por função
   */
  async buscarPorFuncao(funcao: 'atendente' | 'garcom' | 'entregador'): Promise<FuncionarioSupabase[]> {
    const { data, error } = await supabase
      .from('funcionarios')
      .select('*')
      .eq('funcao', funcao)
      .order('nome', { ascending: true })

    if (error) {
      console.error('Erro ao buscar funcionários por função:', error)
      throw new Error(`Falha ao buscar funcionários por função: ${error.message}`)
    }

    return data || []
  },

  /**
   * Busca funcionário por email
   */
  async buscarPorEmail(email: string): Promise<FuncionarioSupabase | null> {
    const { data, error } = await supabase
      .from('funcionarios')
      .select('*')
      .eq('email', email)
      .single()

    if (error) {
      if (error.code === 'PGRST116') {
        return null
      }
      console.error('Erro ao buscar funcionário por email:', error)
      throw new Error(`Falha ao buscar funcionário por email: ${error.message}`)
    }

    return data
  },

  /**
   * Cria funcionário com conta de acesso no auth
   */
  async criarComAcesso(data: {
    nome: string
    funcao: 'atendente' | 'garcom' | 'entregador'
    telefone: string
    email: string
    senha: string
  }): Promise<FuncionarioSupabase> {
    try {
      // Salvar sessão atual do admin
      const { data: { session: adminSession } } = await supabase.auth.getSession()

      if (!adminSession) {
        throw new Error('Nenhuma sessão ativa encontrada. Faça login novamente.')
      }

      // Criar usuário no auth
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: data.email,
        password: data.senha,
        options: {
          data: {
            nome: data.nome,
            funcao: data.funcao
          },
          emailRedirectTo: undefined
        }
      })

      if (authError) {
        console.error('Erro ao criar usuário no auth:', authError)
        throw new Error(`Falha ao criar usuário no auth: ${authError.message}`)
      }

      if (!authData.user) {
        throw new Error('Usuário não foi criado no sistema de autenticação')
      }

      // Mapear funcao para cargo
      const cargoMap: Record<string, string> = {
        'atendente': 'Atendente',
        'garcom': 'Garçom',
        'entregador': 'Entregador'
      }

      // Criar registro na tabela funcionarios
      const { data: funcionario, error } = await supabase
        .from('funcionarios')
        .insert(comTenant({
          nome: data.nome,
          funcao: data.funcao,
          cargo: cargoMap[data.funcao],
          telefone: data.telefone,
          email: data.email,
          user_id: authData.user.id,
          ativo: true
        }))
        .select()
        .single()

      if (error) {
        console.error('Erro ao criar funcionário:', error)
        // Tentar restaurar sessão do admin antes de lançar erro
        await supabase.auth.setSession({
          access_token: adminSession.access_token,
          refresh_token: adminSession.refresh_token
        })
        throw new Error(`Falha ao criar funcionário: ${error.message}`)
      }

      if (!funcionario) {
        // Tentar restaurar sessão do admin antes de lançar erro
        await supabase.auth.setSession({
          access_token: adminSession.access_token,
          refresh_token: adminSession.refresh_token
        })
        throw new Error('Funcionário não foi criado corretamente')
      }

      // Restaurar sessão do admin
      await supabase.auth.setSession({
        access_token: adminSession.access_token,
        refresh_token: adminSession.refresh_token
      })

      return funcionario
    } catch (err) {
      console.error('Erro ao criar funcionário com acesso:', err)
      throw err instanceof Error ? err : new Error('Erro desconhecido ao criar funcionário com acesso')
    }
  }
}

/**
 * Exportar como default para facilitar importação
 */
export default funcionarioService

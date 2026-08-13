/**
 * Serviço para gerenciamento de autenticação
 *
 * Este serviço encapsula todas as operações relacionadas a autenticação,
 * incluindo login, logout, registro e gerenciamento de sessão.
 *
 * @module services/authService
 */

import { supabase } from "@/lib/supabase"

/**
 * Interface do serviço de autenticação
 */
export interface AuthService {
  /**
   * Faz login com email e senha
   * @param email - Email do usuário
   * @param password - Senha do usuário
   * @returns Promise com dados de autenticação
   */
  login(email: string, password: string): Promise<any>

  /**
   * Faz logout do usuário atual
   */
  logout(): Promise<void>

  /**
   * Obtém o usuário atual
   * @returns Promise com o usuário ou null
   */
  getCurrentUser(): Promise<any>

  /**
   * Verifica se o usuário está autenticado
   * @returns Promise com booleano
   */
  isAuthenticated(): Promise<boolean>

  /**
   * Obtém a sessão atual
   * @returns Promise com a sessão ou null
   */
  getSession(): Promise<any>

  /**
   * Escuta mudanças de autenticação
   * @param callback - Função chamada quando há mudança
   * @returns Função para remover o listener
   */
  onAuthStateChange(callback: (event: string, session: any) => void): any

  /**
   * Registra novo usuário
   * @param email - Email do usuário
   * @param password - Senha do usuário
   * @param userData - Dados adicionais do usuário
   * @returns Promise com dados do registro
   */
  register(email: string, password: string, userData?: { nome?: string }): Promise<any>

  /**
   * Altera senha do usuário logado
   * @param novaSenha - Nova senha
   * @returns Promise com dados da atualização
   */
  alterarSenha(novaSenha: string): Promise<any>

  /**
   * Solicita reset de senha por email
   * @param email - Email do usuário
   * @returns Promise com dados da solicitação
   */
  solicitarResetSenha(email: string): Promise<any>

  /**
   * Verifica se o usuário atual é um administrador
   * @returns Promise com booleano
   */
  isAdmin(): Promise<boolean>

  /**
   * Verifica se o funcionário está bloqueado
   * @returns Promise com booleano
   */
  isBloqueado(): Promise<boolean>
}

/**
 * Implementação do serviço de autenticação
 */
export const authService: AuthService = {
  /**
   * Autentica usuário com email e senha
   */
  async login(email: string, password: string): Promise<any> {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    })

    if (error) {
      console.error('Erro no login:', error)
      throw new Error(`Falha no login: ${error.message}`)
    }

    // Verificar se o usuário está bloqueado
    if (data.user) {
      try {
        const { data: funcionario, error: funcError } = await supabase
          .from('funcionarios')
          .select('bloqueado')
          .eq('user_id', data.user.id)
          .maybeSingle()

        // Se encontrou o funcionário e está bloqueado
        if (!funcError && funcionario?.bloqueado) {
          // Fazer logout imediatamente
          await supabase.auth.signOut()
          throw new Error('USUARIO_BLOQUEADO')
        }
      } catch (checkError) {
        // Se der erro ao verificar bloqueio, permitir login
        // (pode ser admin ou erro de permissão)
        console.warn('Não foi possível verificar status de bloqueio:', checkError)
      }
    }

    return data
  },

  /**
   * Encerra sessão do usuário
   */
  async logout(): Promise<void> {
    const { error } = await supabase.auth.signOut()

    if (error) {
      console.error('Erro no logout:', error)
      throw new Error(`Falha no logout: ${error.message}`)
    }
  },

  /**
   * Obtém dados do usuário autenticado
   */
  async getCurrentUser(): Promise<any> {
    const { data: { user }, error } = await supabase.auth.getUser()

    if (error) {
      console.error('Erro ao obter usuário:', error)
      throw new Error(`Falha ao obter usuário: ${error.message}`)
    }

    return user
  },

  /**
   * Verifica se existe sessão ativa
   */
  async isAuthenticated(): Promise<boolean> {
    const { data: { session } } = await supabase.auth.getSession()
    return !!session
  },

  /**
   * Obtém sessão ativa
   */
  async getSession(): Promise<any> {
    const { data: { session }, error } = await supabase.auth.getSession()

    if (error) {
      console.error('Erro ao obter sessão:', error)
      throw new Error(`Falha ao obter sessão: ${error.message}`)
    }

    return session
  },

  /**
   * Registra callback para mudanças de autenticação
   */
  onAuthStateChange(callback: (event: string, session: any) => void): any {
    return supabase.auth.onAuthStateChange(callback)
  },

  /**
   * Registra novo usuário no sistema
   */
  async register(email: string, password: string, userData?: { nome?: string }): Promise<any> {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: userData
      }
    })

    if (error) {
      console.error('Erro no registro:', error)
      throw new Error(`Falha no registro: ${error.message}`)
    }

    return data
  },

  /**
   * Atualiza senha do usuário autenticado
   */
  async alterarSenha(novaSenha: string): Promise<any> {
    const { data, error } = await supabase.auth.updateUser({
      password: novaSenha
    })

    if (error) {
      console.error('Erro ao alterar senha:', error)
      throw new Error(`Falha ao alterar senha: ${error.message}`)
    }

    return data
  },

  /**
   * Envia email para reset de senha
   */
  async solicitarResetSenha(email: string): Promise<any> {
    const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`
    })

    if (error) {
      console.error('Erro ao solicitar reset de senha:', error)
      throw new Error(`Falha ao solicitar reset de senha: ${error.message}`)
    }

    return data
  },

  /**
   * Verifica se o usuário atual é um administrador
   */
  async isAdmin(): Promise<boolean> {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      
      if (!user) {
        return false
      }

      const { data, error } = await supabase
        .from('profile')
        .select('ativo')
        .eq('user_id', user.id)
        .eq('ativo', true)
        .single()

      if (error || !data) {
        return false
      }

      return true
    } catch (error) {
      console.error('Erro ao verificar se é admin:', error)
      return false
    }
  },

  /**
   * Verifica se o funcionário está bloqueado
   */
  async isBloqueado(): Promise<boolean> {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      
      if (!user) {
        return false
      }

      const { data, error } = await supabase
        .from('funcionarios')
        .select('bloqueado')
        .eq('user_id', user.id)
        .maybeSingle()

      if (error) {
        console.warn('Erro ao verificar se está bloqueado:', error)
        return false
      }

      if (!data) {
        // Não é funcionário, provavelmente é admin
        return false
      }

      return data.bloqueado === true
    } catch (error) {
      console.error('Erro ao verificar se está bloqueado:', error)
      return false
    }
  }
}

/**
 * Exportar como default para facilitar importação
 */
export default authService

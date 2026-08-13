import { supabase } from '@/lib/supabase';

export interface Profile {
  id: string;
  user_id: string;
  nome: string;
  email: string;
  telefone?: string;
  ativo: boolean;
  criado_em: string;
  atualizado_em: string;
}

/**
 * Serviço para gerenciar perfis de administradores
 * Nota: A criação de novos administradores deve ser feita diretamente no banco de dados
 */
export const profileService = {
  /**
   * Busca o perfil do administrador logado
   * Retorna null se o usuário não for administrador (sem lançar erro)
   */
  async getProfile(): Promise<Profile | null> {
    const { data: { user } } = await supabase.auth.getUser();
    
    if (!user) {
      return null;
    }

    const { data, error } = await supabase
      .from('profile')
      .select('*')
      .eq('user_id', user.id)
      .eq('ativo', true)
      .maybeSingle(); // Usa maybeSingle() para não lançar erro se não encontrar

    if (error) {
      console.error('Erro ao buscar perfil:', error);
      return null;
    }

    return data;
  },

  /**
   * Verifica se o usuário logado é um administrador
   */
  async isAdmin(): Promise<boolean> {
    const profile = await this.getProfile();
    return profile !== null && profile.ativo;
  },

  /**
   * Busca todos os perfis de administradores (apenas para admins)
   */
  async getAllProfiles(): Promise<Profile[]> {
    const { data, error } = await supabase
      .from('profile')
      .select('*')
      .order('nome', { ascending: true });

    if (error) {
      console.error('Erro ao buscar perfis:', error);
      throw error;
    }

    return data || [];
  },

  /**
   * Atualiza o perfil do administrador
   */
  async updateProfile(id: string, updates: Partial<Omit<Profile, 'id' | 'user_id' | 'criado_em' | 'atualizado_em'>>): Promise<Profile> {
    const { data, error } = await supabase
      .from('profile')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Erro ao atualizar perfil:', error);
      throw error;
    }

    return data;
  },

  /**
   * Desativa um perfil de administrador
   */
  async deactivateProfile(id: string): Promise<void> {
    const { error } = await supabase
      .from('profile')
      .update({ ativo: false })
      .eq('id', id);

    if (error) {
      console.error('Erro ao desativar perfil:', error);
      throw error;
    }
  },

  /**
   * Ativa um perfil de administrador
   */
  async activateProfile(id: string): Promise<void> {
    const { error } = await supabase
      .from('profile')
      .update({ ativo: true })
      .eq('id', id);

    if (error) {
      console.error('Erro ao ativar perfil:', error);
      throw error;
    }
  }
};

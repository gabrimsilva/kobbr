import { useState, useEffect } from 'react';
import { profileService, type Profile } from '@/services/profileService';

/**
 * Hook para gerenciar o perfil do administrador logado
 */
export function useProfile() {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadProfile();
  }, []);

  const loadProfile = async () => {
    try {
      setLoading(true);
      const profileData = await profileService.getProfile();
      setProfile(profileData);
      setIsAdmin(profileData !== null && profileData.ativo);
    } catch (error) {
      // Silenciosamente trata o caso de não ser admin (funcionário)
      // Não loga erro pois é comportamento esperado
      setProfile(null);
      setIsAdmin(false);
    } finally {
      setLoading(false);
    }
  };

  const updateProfile = async (updates: Partial<Omit<Profile, 'id' | 'user_id' | 'criado_em' | 'atualizado_em'>>) => {
    if (!profile) {
      throw new Error('Nenhum perfil carregado');
    }

    const updatedProfile = await profileService.updateProfile(profile.id, updates);
    setProfile(updatedProfile);
    return updatedProfile;
  };

  return {
    profile,
    isAdmin,
    loading,
    updateProfile,
    refreshProfile: loadProfile
  };
}

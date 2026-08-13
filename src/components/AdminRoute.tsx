import { useEffect, useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useProfile } from '@/hooks';

interface AdminRouteProps {
  children: React.ReactNode;
}

/**
 * Componente para proteger rotas que requerem acesso de administrador
 * 
 * @example
 * ```tsx
 * <AdminRoute>
 *   <ConfiguracoesPage />
 * </AdminRoute>
 * ```
 */
export function AdminRoute({ children }: AdminRouteProps) {
  const { isAdmin, loading } = useProfile();
  const [shouldRedirect, setShouldRedirect] = useState(false);

  useEffect(() => {
    if (!loading && !isAdmin) {
      setShouldRedirect(true);
    }
  }, [loading, isAdmin]);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
          <p className="text-muted-foreground">Verificando permissões...</p>
        </div>
      </div>
    );
  }

  if (shouldRedirect) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
}

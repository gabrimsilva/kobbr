/**
 * Tipos TypeScript da camada multi-estabelecimento (multi-tenant)
 *
 * Centraliza os tipos de tenant: estabelecimentos, vínculo de usuários/perfis
 * e registros de auditoria. Mantém consistência com a convenção de
 * `src/types/supabase.ts`.
 */

// ========================================
// PERFIL DE USUÁRIO
// ========================================

/**
 * Nível de autorização do usuário no sistema
 */
export type PerfilUsuario =
  | 'administrador_geral'
  | 'administrador_estabelecimento'
  | 'operador'

// ========================================
// ESTABELECIMENTO
// ========================================

/**
 * Estabelecimento (prédio/filial) que atua como inquilino (tenant)
 */
export interface Estabelecimento {
  id: string
  nome: string
  /** Identificador de rota pública (ex: 'cic', 'boqueirao') */
  slug: string
  descricao: string | null
  /** Cor de tema em formato hex (ex: "#2563EB") */
  cor_tema: string
  ativo: boolean
  criado_em: string
}

// ========================================
// USUÁRIO / VÍNCULO COM ESTABELECIMENTO
// ========================================

/**
 * Vínculo entre usuário, perfil e estabelecimento
 */
export interface UsuarioEstabelecimento {
  id: string
  /** Referência a auth.users(id) */
  user_id: string
  nome: string
  email: string
  perfil: PerfilUsuario
  /** null para administrador_geral (autorizado em todos) */
  estabelecimento_id: string | null
  ativo: boolean
  /** Último estabelecimento usado (restaurado no login) */
  ultimo_estabelecimento_id: string | null
  criado_em: string
}

// ========================================
// AUDITORIA
// ========================================

/**
 * Registro de auditoria de uma ação relevante
 */
export interface LogAuditoria {
  id: string
  usuario_id: string | null
  estabelecimento_id: string | null
  /** Ação executada (ex: 'produto.atualizar', 'estabelecimento.trocar') */
  acao: string
  /** Descrição legível da ação (máx. 500 caracteres) */
  descricao: string
  metadata: Record<string, unknown> | null
  criado_em: string
}

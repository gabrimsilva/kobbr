/**
 * EstabelecimentoContext — contexto do tenant (multi-estabelecimento)
 *
 * Mantém o Estabelecimento_Atual da sessão, a lista de estabelecimentos
 * autorizados e o perfil do usuário. Permite a troca (apenas Administrador_Geral),
 * persiste a escolha e a restaura no login. Sincroniza o store de tenant dos
 * services via setEstabelecimentoAtivo (Property 7).
 *
 * Requisitos: 3.3, 3.4, 3.8, 4.1-4.6, 9.2
 *
 * @module contexts/EstabelecimentoContext
 */

import { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react'
import type { ReactNode } from 'react'
import { supabase } from '@/lib/supabase'
import {
  estabelecimentoService,
  usuarioService,
  auditoriaService,
  setEstabelecimentoAtivo,
} from '@/services'
import type { Estabelecimento, PerfilUsuario, UsuarioEstabelecimento } from '@/types/estabelecimento'

const CHAVE_LOCAL = 'estabelecimento_atual_id'

interface EstabelecimentoContextType {
  estabelecimentoAtual: Estabelecimento | null
  estabelecimentosAutorizados: Estabelecimento[]
  perfil: PerfilUsuario | null
  usuario: UsuarioEstabelecimento | null
  podeTrocar: boolean
  loading: boolean
  erro: string | null
  trocarEstabelecimento: (id: string) => Promise<void>
  recarregar: () => Promise<void>
}

const EstabelecimentoContext = createContext<EstabelecimentoContextType | undefined>(undefined)

export const useEstabelecimento = () => {
  const ctx = useContext(EstabelecimentoContext)
  if (ctx === undefined) {
    throw new Error('useEstabelecimento deve ser usado dentro de EstabelecimentoProvider')
  }
  return ctx
}

interface ProviderProps {
  children: ReactNode
}

export const EstabelecimentoProvider = ({ children }: ProviderProps) => {
  const [estabelecimentoAtual, setAtual] = useState<Estabelecimento | null>(null)
  const [estabelecimentosAutorizados, setAutorizados] = useState<Estabelecimento[]>([])
  const [usuario, setUsuario] = useState<UsuarioEstabelecimento | null>(null)
  const [perfil, setPerfil] = useState<PerfilUsuario | null>(null)
  const [loading, setLoading] = useState(true)
  const [erro, setErro] = useState<string | null>(null)
  const anteriorRef = useRef<Estabelecimento | null>(null)

  /** Atualiza o estado do atual e sincroniza o store dos services. */
  const aplicarAtual = useCallback((estab: Estabelecimento | null) => {
    anteriorRef.current = estab
    setAtual(estab)
    setEstabelecimentoAtivo(estab?.id ?? null)
    if (estab?.id) {
      try { localStorage.setItem(CHAVE_LOCAL, estab.id) } catch { /* ignore */ }
    }
  }, [])

  const carregar = useCallback(async () => {
    setLoading(true)
    setErro(null)
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        setLoading(false)
        return
      }

      // Carrega o vínculo do usuário e a lista de estabelecimentos autorizados.
      const [vinculo, autorizados] = await Promise.all([
        usuarioService.buscarPorUserId(user.id),
        estabelecimentoService.buscarAtivos(), // RLS já restringe ao escopo do usuário
      ])

      setUsuario(vinculo)
      setPerfil(vinculo?.perfil ?? null)
      setAutorizados(autorizados)

      if (!autorizados || autorizados.length === 0) {
        // Sem estabelecimento ativo vinculado (Req 4.6)
        aplicarAtual(null)
        setErro('Nenhum estabelecimento ativo disponível para o seu usuário.')
        setLoading(false)
        return
      }

      const ehAdminGeral = vinculo?.perfil === 'administrador_geral'

      if (ehAdminGeral) {
        // Restaura último usado (preferência salva ou localStorage) — Req 4.3
        const ultimoId = vinculo?.ultimo_estabelecimento_id
          || (() => { try { return localStorage.getItem(CHAVE_LOCAL) } catch { return null } })()
        const restaurado = autorizados.find((e) => e.id === ultimoId && e.ativo)
        // Se não houver válido, exige seleção mas pré-seleciona o primeiro (Req 4.4)
        aplicarAtual(restaurado ?? autorizados[0])
      } else {
        // Admin de estabelecimento / operador: fixa o vinculado (Req 4.5)
        const vinculado = autorizados.find((e) => e.id === vinculo?.estabelecimento_id) ?? autorizados[0]
        aplicarAtual(vinculado)
      }
    } catch (e) {
      console.error('Erro ao carregar contexto de estabelecimento:', e)
      setErro(e instanceof Error ? e.message : 'Erro ao carregar estabelecimentos.')
    } finally {
      setLoading(false)
    }
  }, [aplicarAtual])

  useEffect(() => {
    carregar()
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_IN' || event === 'SIGNED_OUT') {
        carregar()
      }
    })
    return () => subscription.unsubscribe()
  }, [carregar])

  const podeTrocar = perfil === 'administrador_geral'

  const trocarEstabelecimento = useCallback(async (id: string) => {
    if (!podeTrocar) {
      throw new Error('Seu perfil não permite trocar de estabelecimento.')
    }
    const destino = estabelecimentosAutorizados.find((e) => e.id === id)
    if (!destino) {
      throw new Error('Estabelecimento não disponível.')
    }
    const origem = anteriorRef.current

    // Aplica imediatamente (tema/indicador/contexto). Persistência best-effort.
    aplicarAtual(destino)

    // Persistir último estabelecimento (Req 4.1, 4.2 — não bloqueante)
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (user) {
        const { error } = await supabase
          .from('usuarios_estabelecimento')
          .update({ ultimo_estabelecimento_id: destino.id })
          .eq('user_id', user.id)
        if (error) {
          console.warn('Não foi possível salvar a preferência de estabelecimento:', error.message)
        }
      }
    } catch (e) {
      console.warn('Falha ao persistir último estabelecimento:', e)
    }

    // Auditoria da troca (Req 9.2 — não bloqueante)
    void auditoriaService.registrar({
      acao: 'estabelecimento.trocar',
      descricao: `Troca de estabelecimento de "${origem?.nome ?? '—'}" para "${destino.nome}"`,
      estabelecimento_id: destino.id,
      metadata: { origem_id: origem?.id ?? null, destino_id: destino.id },
    })
  }, [podeTrocar, estabelecimentosAutorizados, aplicarAtual])

  const value: EstabelecimentoContextType = {
    estabelecimentoAtual,
    estabelecimentosAutorizados,
    perfil,
    usuario,
    podeTrocar,
    loading,
    erro,
    trocarEstabelecimento,
    recarregar: carregar,
  }

  return (
    <EstabelecimentoContext.Provider value={value}>
      {children}
    </EstabelecimentoContext.Provider>
  )
}

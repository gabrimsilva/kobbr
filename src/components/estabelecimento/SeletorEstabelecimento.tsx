/**
 * SeletorEstabelecimento — controle de troca de estabelecimento no header.
 *
 * Administrador_Geral: lista estabelecimentos ativos ordenados por nome e
 * permite trocar. Demais perfis: exibe o estabelecimento vinculado em modo
 * somente leitura (Req 3.1, 3.2, 3.3, 3.4).
 *
 * @module components/estabelecimento/SeletorEstabelecimento
 */

import { useState } from 'react'
import { Building2, ChevronDown, Check, Lock } from 'lucide-react'
import toast from 'react-hot-toast'
import { useEstabelecimento } from '@/contexts/EstabelecimentoContext'

export default function SeletorEstabelecimento() {
  const {
    estabelecimentoAtual,
    estabelecimentosAutorizados,
    podeTrocar,
    trocarEstabelecimento,
    loading,
  } = useEstabelecimento()
  const [aberto, setAberto] = useState(false)
  const [trocando, setTrocando] = useState(false)

  const cor = estabelecimentoAtual?.cor_tema || '#64748b'

  const handleTrocar = async (id: string) => {
    if (id === estabelecimentoAtual?.id) {
      setAberto(false)
      return
    }
    try {
      setTrocando(true)
      await trocarEstabelecimento(id)
      setAberto(false)
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'Falha ao trocar de estabelecimento')
    } finally {
      setTrocando(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-gray-100 animate-pulse">
        <Building2 className="h-4 w-4 text-gray-400" />
        <span className="text-sm text-gray-400">Carregando…</span>
      </div>
    )
  }

  // Perfis sem permissão de troca: somente leitura (Req 3.3)
  if (!podeTrocar) {
    return (
      <div
        className="flex items-center gap-2 px-3 py-2 rounded-lg border"
        style={{ borderColor: cor, color: cor }}
        title="Você não tem permissão para trocar de estabelecimento"
      >
        <Building2 className="h-4 w-4" />
        <span className="text-sm font-medium">
          {estabelecimentoAtual?.nome ?? 'Nenhum estabelecimento'}
        </span>
        <Lock className="h-3 w-3 opacity-60" />
      </div>
    )
  }

  // Admin geral sem estabelecimentos ativos (Req 3.2)
  if (estabelecimentosAutorizados.length === 0) {
    return (
      <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-amber-50 border border-amber-200">
        <Building2 className="h-4 w-4 text-amber-600" />
        <span className="text-sm text-amber-700">Nenhum estabelecimento disponível</span>
      </div>
    )
  }

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setAberto((v) => !v)}
        disabled={trocando}
        className="flex items-center gap-2 px-3 py-2 rounded-lg border transition-colors hover:bg-gray-50 disabled:opacity-60"
        style={{ borderColor: cor }}
      >
        <Building2 className="h-4 w-4" style={{ color: cor }} />
        <span className="text-sm font-semibold" style={{ color: cor }}>
          {estabelecimentoAtual?.nome ?? 'Selecione'}
        </span>
        <ChevronDown className="h-4 w-4 text-gray-500" />
      </button>

      {aberto && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setAberto(false)} />
          <div className="absolute right-0 z-50 mt-1 w-64 max-h-80 overflow-y-auto rounded-lg border border-gray-200 bg-white shadow-lg py-1">
            {estabelecimentosAutorizados.map((e) => {
              const ativoSel = e.id === estabelecimentoAtual?.id
              return (
                <button
                  key={e.id}
                  type="button"
                  onClick={() => handleTrocar(e.id)}
                  className={`w-full flex items-center gap-2 px-3 py-2 text-sm text-left hover:bg-gray-50 ${ativoSel ? 'font-semibold' : ''}`}
                >
                  <span
                    className="inline-block h-3 w-3 rounded-full flex-shrink-0"
                    style={{ backgroundColor: e.cor_tema }}
                  />
                  <span className="flex-1 truncate">{e.nome}</span>
                  {ativoSel && <Check className="h-4 w-4 text-green-600" />}
                </button>
              )
            })}
          </div>
        </>
      )}
    </div>
  )
}

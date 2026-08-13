/**
 * Página de gestão de Estabelecimentos (Configurações > Estabelecimentos).
 * Restrita a Administrador_Geral (Req 1).
 */

import { useEffect, useState, useCallback } from 'react'
import toast from 'react-hot-toast'
import { Building2, Plus, Pencil, Power, Loader2, Copy, ExternalLink } from 'lucide-react'
import { estabelecimentoService, gerarSlug } from '@/services/estabelecimentoService'
import { usePermissoes } from '@/hooks/usePermissoes'
import { useEstabelecimento } from '@/contexts/EstabelecimentoContext'
import { auditoriaService } from '@/services'
import type { Estabelecimento } from '@/types/estabelecimento'

type FormState = {
  id?: string
  nome: string
  slug: string
  descricao: string
  cor_tema: string
  ativo: boolean
}

const FORM_VAZIO: FormState = {
  nome: '',
  slug: '',
  descricao: '',
  cor_tema: '#2563EB',
  ativo: true,
}

export default function Estabelecimentos() {
  const { podeGerenciarEstabelecimentos } = usePermissoes()
  const { recarregar } = useEstabelecimento()
  const [lista, setLista] = useState<Estabelecimento[]>([])
  const [loading, setLoading] = useState(true)
  const [form, setForm] = useState<FormState | null>(null)
  const [salvando, setSalvando] = useState(false)

  const carregar = useCallback(async () => {
    setLoading(true)
    try {
      setLista(await estabelecimentoService.buscarTodos())
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'Erro ao carregar estabelecimentos')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { carregar() }, [carregar])

  if (!podeGerenciarEstabelecimentos) {
    return (
      <div className="p-6">
        <div className="max-w-md mx-auto bg-white rounded-lg shadow p-8 text-center">
          <Building2 className="h-12 w-12 text-gray-400 mx-auto mb-3" />
          <p className="text-gray-600">Apenas o Administrador Geral pode gerenciar estabelecimentos.</p>
        </div>
      </div>
    )
  }

  const abrirNovo = () => setForm({ ...FORM_VAZIO })
  const abrirEdicao = (e: Estabelecimento) => setForm({
    id: e.id,
    nome: e.nome,
    slug: e.slug,
    descricao: e.descricao ?? '',
    cor_tema: e.cor_tema,
    ativo: e.ativo,
  })

  const salvar = async () => {
    if (!form) return
    setSalvando(true)
    try {
      if (form.id) {
        await estabelecimentoService.atualizar(form.id, {
          nome: form.nome,
          slug: form.slug || gerarSlug(form.nome),
          descricao: form.descricao,
          cor_tema: form.cor_tema,
          ativo: form.ativo,
        })
        await auditoriaService.registrar({
          acao: 'estabelecimento.atualizar',
          descricao: `Estabelecimento "${form.nome}" atualizado`,
          estabelecimento_id: form.id,
        })
        toast.success('Estabelecimento atualizado')
      } else {
        const novo = await estabelecimentoService.criar({
          nome: form.nome,
          slug: form.slug || gerarSlug(form.nome),
          descricao: form.descricao,
          cor_tema: form.cor_tema,
          ativo: form.ativo,
        })
        await auditoriaService.registrar({
          acao: 'estabelecimento.criar',
          descricao: `Estabelecimento "${novo.nome}" criado`,
          estabelecimento_id: novo.id,
        })
        toast.success('Estabelecimento criado')
      }
      setForm(null)
      await carregar()
      await recarregar()
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'Erro ao salvar')
    } finally {
      setSalvando(false)
    }
  }

  const alternarAtivo = async (e: Estabelecimento) => {
    try {
      await estabelecimentoService.definirAtivo(e.id, !e.ativo)
      toast.success(!e.ativo ? 'Estabelecimento ativado' : 'Estabelecimento desativado')
      await carregar()
      await recarregar()
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Erro ao alterar status')
    }
  }

  /** Monta o link público (cardápio do cliente) do estabelecimento pelo slug. */
  const linkCliente = (e: Estabelecimento) => `${window.location.origin}/${e.slug}`

  const copiarLink = async (e: Estabelecimento) => {
    const url = linkCliente(e)
    try {
      await navigator.clipboard.writeText(url)
      toast.success('Link do cliente copiado!')
    } catch {
      // Fallback para navegadores/contextos sem permissão de clipboard
      window.prompt('Copie o link do cliente:', url)
    }
  }

  return (
    <div className="p-6 max-w-5xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <Building2 className="h-7 w-7 text-primary" />
          <h1 className="text-2xl font-bold text-gray-900">Estabelecimentos</h1>
        </div>
        <button
          onClick={abrirNovo}
          className="flex items-center gap-2 px-4 py-2 rounded-lg bg-primary text-primary-foreground hover:opacity-90"
        >
          <Plus className="h-4 w-4" /> Novo
        </button>
      </div>

      {loading ? (
        <div className="flex justify-center py-12"><Loader2 className="h-6 w-6 animate-spin text-gray-400" /></div>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-600">
              <tr>
                <th className="text-left px-4 py-3">Nome</th>
                <th className="text-left px-4 py-3">Slug</th>
                <th className="text-left px-4 py-3">Link do cliente</th>
                <th className="text-left px-4 py-3">Cor</th>
                <th className="text-left px-4 py-3">Status</th>
                <th className="text-right px-4 py-3">Ações</th>
              </tr>
            </thead>
            <tbody>
              {lista.map((e) => (
                <tr key={e.id} className="border-t border-gray-100">
                  <td className="px-4 py-3 font-medium">{e.nome}</td>
                  <td className="px-4 py-3 text-gray-500">/{e.slug}</td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-1">
                      <code className="text-xs text-gray-600 bg-gray-50 border border-gray-200 rounded px-2 py-1 max-w-[220px] truncate inline-block align-middle" title={linkCliente(e)}>
                        {linkCliente(e)}
                      </code>
                      <button onClick={() => copiarLink(e)} className="p-1.5 rounded hover:bg-gray-100" title="Copiar link do cliente">
                        <Copy className="h-4 w-4 text-gray-600" />
                      </button>
                      <a href={linkCliente(e)} target="_blank" rel="noopener noreferrer" className="p-1.5 rounded hover:bg-gray-100" title="Abrir link do cliente">
                        <ExternalLink className="h-4 w-4 text-gray-600" />
                      </a>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span className="inline-flex items-center gap-2">
                      <span className="h-4 w-4 rounded-full" style={{ backgroundColor: e.cor_tema }} />
                      {e.cor_tema}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded-full text-xs ${e.ativo ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                      {e.ativo ? 'Ativo' : 'Inativo'}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center justify-end gap-2">
                      <button onClick={() => abrirEdicao(e)} className="p-2 rounded hover:bg-gray-100" title="Editar">
                        <Pencil className="h-4 w-4 text-gray-600" />
                      </button>
                      <button onClick={() => alternarAtivo(e)} className="p-2 rounded hover:bg-gray-100" title={e.ativo ? 'Desativar' : 'Ativar'}>
                        <Power className={`h-4 w-4 ${e.ativo ? 'text-green-600' : 'text-gray-400'}`} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {lista.length === 0 && (
                <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-400">Nenhum estabelecimento cadastrado</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {form && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md bg-white rounded-lg shadow-xl p-6">
            <h2 className="text-lg font-bold mb-4">{form.id ? 'Editar' : 'Novo'} estabelecimento</h2>
            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Nome *</label>
                <input
                  className="w-full border border-gray-300 rounded-lg px-3 py-2"
                  value={form.nome}
                  maxLength={100}
                  onChange={(ev) => setForm({ ...form, nome: ev.target.value, slug: form.id ? form.slug : gerarSlug(ev.target.value) })}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Slug (rota pública)</label>
                <input
                  className="w-full border border-gray-300 rounded-lg px-3 py-2"
                  value={form.slug}
                  maxLength={60}
                  onChange={(ev) => setForm({ ...form, slug: ev.target.value })}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Descrição</label>
                <textarea
                  className="w-full border border-gray-300 rounded-lg px-3 py-2"
                  value={form.descricao}
                  maxLength={500}
                  rows={2}
                  onChange={(ev) => setForm({ ...form, descricao: ev.target.value })}
                />
              </div>
              <div className="flex items-center gap-3">
                <label className="text-sm font-medium text-gray-700">Cor do tema *</label>
                <input
                  type="color"
                  value={/^#([0-9a-fA-F]{6})$/.test(form.cor_tema) ? form.cor_tema : '#2563EB'}
                  onChange={(ev) => setForm({ ...form, cor_tema: ev.target.value })}
                  className="h-9 w-14 rounded border border-gray-300"
                />
                <input
                  className="flex-1 border border-gray-300 rounded-lg px-3 py-2"
                  value={form.cor_tema}
                  onChange={(ev) => setForm({ ...form, cor_tema: ev.target.value })}
                />
              </div>
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" checked={form.ativo} onChange={(ev) => setForm({ ...form, ativo: ev.target.checked })} />
                Ativo
              </label>
            </div>
            <div className="flex justify-end gap-2 mt-6">
              <button onClick={() => setForm(null)} className="px-4 py-2 rounded-lg border border-gray-300 hover:bg-gray-50">Cancelar</button>
              <button onClick={salvar} disabled={salvando} className="px-4 py-2 rounded-lg bg-primary text-primary-foreground hover:opacity-90 disabled:opacity-60 flex items-center gap-2">
                {salvando && <Loader2 className="h-4 w-4 animate-spin" />} Salvar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

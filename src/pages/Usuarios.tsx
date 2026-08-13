/**
 * Página de gestão de Usuários (Configurações > Usuários).
 * Admin Geral gerencia todos; Admin de Estabelecimento gerencia o próprio prédio
 * e não pode conceder o perfil Administrador Geral (Req 2).
 */

import { useEffect, useState, useCallback } from 'react'
import toast from 'react-hot-toast'
import { Users, Plus, Power, Loader2, ShieldAlert, Pencil, Trash2, KeyRound } from 'lucide-react'
import { usuarioService, estabelecimentoService, auditoriaService } from '@/services'
import { usePermissoes } from '@/hooks/usePermissoes'
import type { Estabelecimento, PerfilUsuario, UsuarioEstabelecimento } from '@/types/estabelecimento'

const ROTULO_PERFIL: Record<PerfilUsuario, string> = {
  administrador_geral: 'Administrador Geral',
  administrador_estabelecimento: 'Administrador do Estabelecimento',
  operador: 'Operador',
}

type FormState = {
  nome: string
  email: string
  senha: string
  perfil: PerfilUsuario
  estabelecimento_id: string | null
  ativo: boolean
}

const FORM_VAZIO: FormState = {
  nome: '',
  email: '',
  senha: '',
  perfil: 'operador',
  estabelecimento_id: null,
  ativo: true,
}

export default function Usuarios() {
  const { podeGerenciarUsuarios, perfil, estabelecimentoId } = usePermissoes()
  const [lista, setLista] = useState<UsuarioEstabelecimento[]>([])
  const [estabs, setEstabs] = useState<Estabelecimento[]>([])
  const [loading, setLoading] = useState(true)
  const [form, setForm] = useState<FormState | null>(null)
  const [editId, setEditId] = useState<string | null>(null)
  const [salvando, setSalvando] = useState(false)
  
  // Estado para modal de reset de senha
  const [resetSenhaUsuario, setResetSenhaUsuario] = useState<UsuarioEstabelecimento | null>(null)
  const [novaSenha, setNovaSenha] = useState('')
  const [confirmaSenha, setConfirmaSenha] = useState('')
  const [resetando, setResetando] = useState(false)

  const ehAdminGeral = perfil === 'administrador_geral'

  const carregar = useCallback(async () => {
    setLoading(true)
    try {
      const [us, es] = await Promise.all([
        usuarioService.listar(),
        estabelecimentoService.buscarAtivos(),
      ])
      setLista(us)
      setEstabs(es)
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'Erro ao carregar usuários')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { carregar() }, [carregar])

  if (!podeGerenciarUsuarios) {
    return (
      <div className="p-6">
        <div className="max-w-md mx-auto bg-white rounded-lg shadow p-8 text-center">
          <ShieldAlert className="h-12 w-12 text-gray-400 mx-auto mb-3" />
          <p className="text-gray-600">Seu perfil não tem permissão para gerenciar usuários.</p>
        </div>
      </div>
    )
  }

  const abrirNovo = () => {
    setEditId(null)
    setForm({
      ...FORM_VAZIO,
      // Admin de estabelecimento já vincula ao próprio prédio
      estabelecimento_id: ehAdminGeral ? null : estabelecimentoId,
    })
  }

  const abrirEdicao = (u: UsuarioEstabelecimento) => {
    setEditId(u.id)
    setForm({
      nome: u.nome,
      email: u.email,
      senha: '',
      perfil: u.perfil,
      estabelecimento_id: u.estabelecimento_id,
      ativo: u.ativo,
    })
  }

  const salvar = async () => {
    if (!form) return
    // Admin de estabelecimento não pode criar/definir admin geral (Req 2.8)
    if (!ehAdminGeral && form.perfil === 'administrador_geral') {
      toast.error('Você não pode definir um Administrador Geral.')
      return
    }
    setSalvando(true)
    try {
      if (editId) {
        // Edição: atualiza perfil/estabelecimento/ativo/nome (sem alterar email/senha aqui)
        await usuarioService.atualizar(editId, {
          nome: form.nome,
          perfil: form.perfil,
          estabelecimento_id: form.perfil === 'administrador_geral'
            ? null
            : (ehAdminGeral ? form.estabelecimento_id : estabelecimentoId),
          ativo: form.ativo,
        })
        await auditoriaService.registrar({
          acao: 'usuario.atualizar',
          descricao: `Usuário "${form.nome}" (${ROTULO_PERFIL[form.perfil]}) atualizado`,
          estabelecimento_id: form.estabelecimento_id,
        })
        toast.success('Usuário atualizado')
      } else {
        const novo = await usuarioService.criar({
          nome: form.nome,
          email: form.email,
          senha: form.senha,
          perfil: form.perfil,
          estabelecimento_id: form.perfil === 'administrador_geral'
            ? null
            : (ehAdminGeral ? form.estabelecimento_id : estabelecimentoId),
          ativo: form.ativo,
        })
        await auditoriaService.registrar({
          acao: 'usuario.criar',
          descricao: `Usuário "${form.nome}" (${ROTULO_PERFIL[form.perfil]}) criado`,
          estabelecimento_id: novo.estabelecimento_id,
        })
        toast.success('Usuário criado')
      }
      setForm(null)
      setEditId(null)
      await carregar()
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'Erro ao salvar usuário')
    } finally {
      setSalvando(false)
    }
  }

  const alternarAtivo = async (u: UsuarioEstabelecimento) => {
    try {
      await usuarioService.definirAtivo(u.id, !u.ativo)
      toast.success(!u.ativo ? 'Usuário ativado' : 'Usuário desativado')
      await carregar()
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Erro ao alterar status')
    }
  }

  const excluirUsuario = async (u: UsuarioEstabelecimento) => {
    const confirmacao = window.confirm(
      `⚠️ ATENÇÃO: Esta ação é IRREVERSÍVEL!\n\n` +
      `Você está prestes a EXCLUIR PERMANENTEMENTE o usuário "${u.nome}".\n\n` +
      `Todos os dados deste usuário serão removidos do sistema.\n\n` +
      `Se você deseja apenas impedir o acesso temporariamente, use o botão de DESATIVAR em vez de excluir.\n\n` +
      `Tem certeza que deseja EXCLUIR permanentemente?`
    )
    
    if (!confirmacao) return
    
    try {
      await usuarioService.excluir(u.id)
      await auditoriaService.registrar({
        acao: 'usuario.excluir',
        descricao: `Usuário "${u.nome}" (${u.email}) excluído permanentemente`,
        estabelecimento_id: u.estabelecimento_id,
      })
      toast.success('Usuário excluído permanentemente')
      await carregar()
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Erro ao excluir usuário')
    }
  }

  const abrirResetSenha = (u: UsuarioEstabelecimento) => {
    setResetSenhaUsuario(u)
    setNovaSenha('')
    setConfirmaSenha('')
  }

  const fecharResetSenha = () => {
    setResetSenhaUsuario(null)
    setNovaSenha('')
    setConfirmaSenha('')
  }

  const resetarSenha = async () => {
    if (!resetSenhaUsuario) return

    // Validações
    if (!novaSenha || novaSenha.length < 6) {
      toast.error('A senha deve ter no mínimo 6 caracteres')
      return
    }
    if (novaSenha !== confirmaSenha) {
      toast.error('As senhas não coincidem')
      return
    }

    setResetando(true)
    try {
      await usuarioService.resetarSenha(resetSenhaUsuario.id, novaSenha)
      await auditoriaService.registrar({
        acao: 'usuario.reset_senha',
        descricao: `Senha do usuário "${resetSenhaUsuario.nome}" (${resetSenhaUsuario.email}) foi resetada`,
        estabelecimento_id: resetSenhaUsuario.estabelecimento_id,
      })
      toast.success('Senha resetada com sucesso')
      fecharResetSenha()
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Erro ao resetar senha')
    } finally {
      setResetando(false)
    }
  }

  const nomeEstab = (id: string | null) => estabs.find((e) => e.id === id)?.nome ?? (id ? '—' : 'Todos')

  return (
    <div className="p-6 max-w-5xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <Users className="h-7 w-7 text-primary" />
          <h1 className="text-2xl font-bold text-gray-900">Usuários</h1>
        </div>
        <button onClick={abrirNovo} className="flex items-center gap-2 px-4 py-2 rounded-lg bg-primary text-primary-foreground hover:opacity-90">
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
                <th className="text-left px-4 py-3">Email</th>
                <th className="text-left px-4 py-3">Perfil</th>
                <th className="text-left px-4 py-3">Estabelecimento</th>
                <th className="text-left px-4 py-3">Status</th>
                <th className="text-right px-4 py-3">Ações</th>
              </tr>
            </thead>
            <tbody>
              {lista.map((u) => (
                <tr key={u.id} className="border-t border-gray-100">
                  <td className="px-4 py-3 font-medium">{u.nome}</td>
                  <td className="px-4 py-3 text-gray-500">{u.email}</td>
                  <td className="px-4 py-3">{ROTULO_PERFIL[u.perfil]}</td>
                  <td className="px-4 py-3">{nomeEstab(u.estabelecimento_id)}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded-full text-xs ${u.ativo ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                      {u.ativo ? 'Ativo' : 'Inativo'}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button onClick={() => abrirEdicao(u)} className="p-2 rounded hover:bg-gray-100" title="Editar usuário">
                        <Pencil className="h-4 w-4 text-gray-600" />
                      </button>
                      {(perfil === 'administrador_geral' || perfil === 'administrador_estabelecimento') && (
                        <button onClick={() => abrirResetSenha(u)} className="p-2 rounded hover:bg-blue-50" title="Resetar senha">
                          <KeyRound className="h-4 w-4 text-blue-600" />
                        </button>
                      )}
                      <button onClick={() => alternarAtivo(u)} className="p-2 rounded hover:bg-gray-100" title={u.ativo ? 'Desativar usuário' : 'Ativar usuário'}>
                        <Power className={`h-4 w-4 ${u.ativo ? 'text-green-600' : 'text-gray-400'}`} />
                      </button>
                      <button onClick={() => excluirUsuario(u)} className="p-2 rounded hover:bg-red-50" title="Excluir permanentemente (irreversível)">
                        <Trash2 className="h-4 w-4 text-red-600" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {lista.length === 0 && (
                <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-400">Nenhum usuário cadastrado</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {form && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md bg-white rounded-lg shadow-xl p-6">
            <h2 className="text-lg font-bold mb-4">{editId ? 'Editar usuário' : 'Novo usuário'}</h2>
            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Nome *</label>
                <input className="w-full border border-gray-300 rounded-lg px-3 py-2" value={form.nome} maxLength={120}
                  onChange={(e) => setForm({ ...form, nome: e.target.value })} />
              </div>
              {!editId && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Email *</label>
                    <input type="email" className="w-full border border-gray-300 rounded-lg px-3 py-2" value={form.email}
                      onChange={(e) => setForm({ ...form, email: e.target.value })} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Senha *</label>
                    <input type="password" className="w-full border border-gray-300 rounded-lg px-3 py-2" value={form.senha}
                      onChange={(e) => setForm({ ...form, senha: e.target.value })} />
                  </div>
                </>
              )}
              {editId && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                  <input disabled className="w-full border border-gray-200 rounded-lg px-3 py-2 bg-gray-50 text-gray-500" value={form.email} />
                </div>
              )}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Perfil *</label>
                <select className="w-full border border-gray-300 rounded-lg px-3 py-2" value={form.perfil}
                  onChange={(e) => setForm({ ...form, perfil: e.target.value as PerfilUsuario })}>
                  {ehAdminGeral && <option value="administrador_geral">Administrador Geral</option>}
                  <option value="administrador_estabelecimento">Administrador do Estabelecimento</option>
                  <option value="operador">Operador</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Estabelecimento *</label>
                {form.perfil === 'administrador_geral' ? (
                  <input disabled className="w-full border border-gray-200 rounded-lg px-3 py-2 bg-gray-50 text-gray-500"
                    value="Todos os estabelecimentos" />
                ) : ehAdminGeral ? (
                  <select className="w-full border border-gray-300 rounded-lg px-3 py-2" value={form.estabelecimento_id ?? ''}
                    onChange={(e) => setForm({ ...form, estabelecimento_id: e.target.value || null })}>
                    <option value="">Selecione…</option>
                    {estabs.map((e) => <option key={e.id} value={e.id}>{e.nome}</option>)}
                  </select>
                ) : (
                  <input disabled className="w-full border border-gray-200 rounded-lg px-3 py-2 bg-gray-50 text-gray-500"
                    value={nomeEstab(estabelecimentoId)} />
                )}
              </div>
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" checked={form.ativo} onChange={(e) => setForm({ ...form, ativo: e.target.checked })} /> Ativo
              </label>
            </div>
            <div className="flex justify-end gap-2 mt-6">
              <button onClick={() => { setForm(null); setEditId(null) }} className="px-4 py-2 rounded-lg border border-gray-300 hover:bg-gray-50">Cancelar</button>
              <button onClick={salvar} disabled={salvando} className="px-4 py-2 rounded-lg bg-primary text-primary-foreground hover:opacity-90 disabled:opacity-60 flex items-center gap-2">
                {salvando && <Loader2 className="h-4 w-4 animate-spin" />} {editId ? 'Salvar' : 'Criar'}
              </button>
            </div>
          </div>
        </div>
      )}

      {resetSenhaUsuario && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md bg-white rounded-lg shadow-xl p-6">
            <h2 className="text-lg font-bold mb-2">Resetar senha</h2>
            <p className="text-sm text-gray-600 mb-4">
              Usuário: <strong>{resetSenhaUsuario.nome}</strong> ({resetSenhaUsuario.email})
            </p>
            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Nova senha *</label>
                <input 
                  type="password" 
                  className="w-full border border-gray-300 rounded-lg px-3 py-2" 
                  value={novaSenha}
                  onChange={(e) => setNovaSenha(e.target.value)}
                  placeholder="Mínimo 6 caracteres"
                  minLength={6}
                />
                {novaSenha && novaSenha.length < 6 && (
                  <p className="text-xs text-red-600 mt-1">A senha deve ter no mínimo 6 caracteres</p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Confirmar senha *</label>
                <input 
                  type="password" 
                  className="w-full border border-gray-300 rounded-lg px-3 py-2" 
                  value={confirmaSenha}
                  onChange={(e) => setConfirmaSenha(e.target.value)}
                  placeholder="Digite a senha novamente"
                />
                {confirmaSenha && novaSenha !== confirmaSenha && (
                  <p className="text-xs text-red-600 mt-1">As senhas não coincidem</p>
                )}
              </div>
            </div>
            <div className="flex justify-end gap-2 mt-6">
              <button onClick={fecharResetSenha} className="px-4 py-2 rounded-lg border border-gray-300 hover:bg-gray-50">
                Cancelar
              </button>
              <button 
                onClick={resetarSenha} 
                disabled={resetando || !novaSenha || novaSenha.length < 6 || novaSenha !== confirmaSenha} 
                className="px-4 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-60 disabled:cursor-not-allowed flex items-center gap-2"
              >
                {resetando && <Loader2 className="h-4 w-4 animate-spin" />} 
                Resetar senha
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

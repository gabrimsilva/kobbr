/**
 * IndicadorEstabelecimento — indicador visual permanente do estabelecimento
 * atual no cabeçalho, exibindo nome e cor correspondente (Req 7.1-7.5).
 *
 * @module components/estabelecimento/IndicadorEstabelecimento
 */

import { Building2, AlertTriangle } from 'lucide-react'
import { useEstabelecimento } from '@/contexts/EstabelecimentoContext'

export default function IndicadorEstabelecimento() {
  const { estabelecimentoAtual, loading } = useEstabelecimento()

  if (loading) return null

  if (!estabelecimentoAtual) {
    // Nenhum estabelecimento selecionado (Req 7.5)
    return (
      <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-amber-50 border border-amber-200">
        <AlertTriangle className="h-4 w-4 text-amber-600" />
        <span className="text-xs font-medium text-amber-700">
          Nenhum estabelecimento selecionado
        </span>
      </div>
    )
  }

  const cor = estabelecimentoAtual.cor_tema

  return (
    <div
      className="flex items-center gap-2 px-3 py-1.5 rounded-full"
      style={{ backgroundColor: `${cor}1A`, border: `1px solid ${cor}` }}
      title={`Estabelecimento atual: ${estabelecimentoAtual.nome}`}
    >
      <Building2 className="h-4 w-4" style={{ color: cor }} />
      <span className="text-xs font-semibold uppercase tracking-wide" style={{ color: cor }}>
        {estabelecimentoAtual.nome}
      </span>
    </div>
  )
}

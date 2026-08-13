/**
 * Lista de Produtos de Consumo Interno
 * 
 * Task 3.2: Exibe a lista dos produtos consumidos internamente
 * no período selecionado com quantidade e frequência
 */

import { useState, useEffect } from 'react'
import { supabase, tenantId } from '@/services'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from '@/components/ui/table'
import { AlertCircle, Package, Loader2 } from 'lucide-react'

interface ProdutoConsumo {
  nome: string
  quantidade: number
  unidade?: string
  precoUnitario: number
  valorTotal: number
}

interface ListaConsumoInternoProps {
  dataInicio: Date
  dataFim: Date
}

export default function ListaConsumoInterno({ dataInicio, dataFim }: ListaConsumoInternoProps) {
  const [produtos, setProdutos] = useState<ProdutoConsumo[]>([])
  const [carregando, setCarregando] = useState(true)
  const [erro, setErro] = useState<string | null>(null)

  useEffect(() => {
    carregarProdutosConsumo()
  }, [dataInicio, dataFim])

  const carregarProdutosConsumo = async () => {
    try {
      setCarregando(true)
      setErro(null)

      const estabelecimentoId = tenantId()
      if (!estabelecimentoId) {
        setErro('Estabelecimento não identificado')
        return
      }

      // Usar formato de data simples (YYYY-MM-DD) para evitar problemas de timezone
      const formatarData = (date: Date) => {
        const year = date.getFullYear()
        const month = String(date.getMonth() + 1).padStart(2, '0')
        const day = String(date.getDate()).padStart(2, '0')
        return `${year}-${month}-${day}`
      }

      const inicio = `${formatarData(dataInicio)}T00:00:00Z`
      const fimAjustado = `${formatarData(new Date(dataFim.getTime() + 24 * 60 * 60 * 1000))}T00:00:00Z`

      console.log('🔍 [LISTA_CONSUMO] Filtro aplicado:', {
        dataInicio: dataInicio.toLocaleDateString('pt-BR'),
        dataFim: dataFim.toLocaleDateString('pt-BR'),
        inicio,
        fimAjustado
      })

      // Buscar consumos internos de ambas as fontes
      // Fonte 1: internal_consumptions
      const { data: consumosInternos, error: erro1 } = await supabase
        .from('internal_consumptions')
        .select('items_json')
        .eq('estabelecimento_id', estabelecimentoId)
        .gte('consumed_at', inicio)
        .lt('consumed_at', fimAjustado) // Usar < ao invés de <=

      // Fonte 2: sales com sale_type='INTERNAL_CONSUMPTION'
      // Primeiro, buscar IDs de sales que já estão em internal_consumptions
      const { data: consumosExistentes } = await supabase
        .from('internal_consumptions')
        .select('sale_id')
        .eq('estabelecimento_id', estabelecimentoId)
        .gte('consumed_at', inicio)
        .lt('consumed_at', fimAjustado) // Usar < ao invés de <=

      const salesJaRegistradas = consumosExistentes?.map(c => c.sale_id) || []

      // Buscar vendas internas que NÃO estão em internal_consumptions
      let queryVendas = supabase
        .from('sales')
        .select('id, items')
        .eq('estabelecimento_id', estabelecimentoId)
        .eq('sale_type', 'INTERNAL_CONSUMPTION')
        .gte('created_at', inicio)
        .lt('created_at', fimAjustado) // Usar < ao invés de <=

      const { data: vendasInternas, error: erro2 } = await queryVendas

      if (erro1 && erro1.code !== 'PGRST116') throw erro1
      if (erro2 && erro2.code !== 'PGRST116') throw erro2

      // Agregar produtos de ambas as fontes
      const produtosMap = new Map<string, { quantidade: number; precoUnitario: number }>()

      // Processar internal_consumptions
      if (consumosInternos) {
        consumosInternos.forEach((consumo) => {
          const items = Array.isArray(consumo.items_json) ? consumo.items_json : []
          items.forEach((item: any) => {
            // Suportar ambas estruturas: nova (produto) e antiga (product_name)
            const nome = item.produto?.nome || item.product_name || 'Produto sem nome'
            const quantidade = item.quantidade || 0
            const precoUnitario = item.produto?.preco || item.precoUnitario || 0
            const atual = produtosMap.get(nome) || { quantidade: 0, precoUnitario }
            produtosMap.set(nome, {
              quantidade: atual.quantidade + quantidade,
              precoUnitario // Mantém o preço do primeiro registro
            })
          })
        })
      }

      // Processar vendas internas (excluindo as que já estão em internal_consumptions)
      if (vendasInternas) {
        vendasInternas.forEach((venda) => {
          // Verificar se esta venda já foi registrada em internal_consumptions
          const jáRegistrada = salesJaRegistradas.includes(venda.id)
          if (jáRegistrada) return // Pular se já está registrada

          const items = Array.isArray(venda.items) ? venda.items : []
          items.forEach((item: any) => {
            // Suportar ambas estruturas: nova (produto) e antiga (product_name)
            const nome = item.produto?.nome || item.product_name || 'Produto sem nome'
            const quantidade = item.quantidade || 0
            const precoUnitario = item.produto?.preco || item.precoUnitario || 0
            const atual = produtosMap.get(nome) || { quantidade: 0, precoUnitario }
            produtosMap.set(nome, {
              quantidade: atual.quantidade + quantidade,
              precoUnitario // Mantém o preço do primeiro registro
            })
          })
        })
      }

      // Converter Map para Array e ordenar por quantidade decrescente
      const produtosOrdenados = Array.from(produtosMap.entries())
        .map(([nome, dados]) => ({
          nome,
          quantidade: dados.quantidade,
          precoUnitario: dados.precoUnitario,
          valorTotal: dados.quantidade * dados.precoUnitario,
          unidade: 'un'
        }))
        .sort((a, b) => b.quantidade - a.quantidade)

      setProdutos(produtosOrdenados)

      console.log('✅ [LISTA_CONSUMO] Produtos carregados:', {
        periodo: `${dataInicio.toLocaleDateString('pt-BR')} a ${dataFim.toLocaleDateString('pt-BR')}`,
        quantidade: produtosOrdenados.length,
        total: produtosOrdenados.reduce((sum, p) => sum + p.quantidade, 0),
        consumosInternos: consumosInternos?.length || 0,
        vendasInternas: vendasInternas?.length || 0,
        vendasInternas_filtradas: vendasInternas?.filter(v => !salesJaRegistradas.includes(v.id)).length || 0,
        detalhes: produtosOrdenados.map(p => `${p.nome}: ${p.quantidade}`)
      })
    } catch (error) {
      const mensagem = error instanceof Error ? error.message : 'Erro ao carregar produtos'
      setErro(mensagem)
      console.error('❌ [LISTA_CONSUMO] Erro ao carregar:', error)
    } finally {
      setCarregando(false)
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Package className="h-5 w-5 text-blue-600" />
          Produtos Consumidos
        </CardTitle>
        <CardDescription>
          Detalhamento dos produtos consumidos internamente no período
        </CardDescription>
      </CardHeader>
      <CardContent>
        {carregando ? (
          <div className="flex items-center justify-center py-12">
            <div className="flex items-center gap-2 text-muted-foreground">
              <Loader2 className="h-4 w-4 animate-spin" />
              <span>Carregando produtos...</span>
            </div>
          </div>
        ) : erro ? (
          <div className="flex items-center gap-2 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
            <AlertCircle className="h-5 w-5" />
            <span className="text-sm">{erro}</span>
          </div>
        ) : produtos.length === 0 ? (
          <div className="text-center py-12">
            <Package className="h-12 w-12 text-muted-foreground mx-auto mb-4 opacity-50" />
            <p className="text-muted-foreground">Nenhum produto consumido neste período</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow className="border-gray-200">
                  <TableHead className="text-left">Produto</TableHead>
                  <TableHead className="text-right">Quantidade</TableHead>
                  <TableHead className="text-right">Unidade</TableHead>
                  <TableHead className="text-right">Valor Total</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {produtos.map((produto, index) => (
                  <TableRow key={`${produto.nome}-${index}`} className="border-gray-100 hover:bg-gray-50">
                    <TableCell className="font-medium text-gray-900">
                      {produto.nome}
                    </TableCell>
                    <TableCell className="text-right font-semibold text-gray-700">
                      {produto.quantidade.toLocaleString('pt-BR')}
                    </TableCell>
                    <TableCell className="text-right text-gray-600">
                      {produto.unidade}
                    </TableCell>
                    <TableCell className="text-right font-semibold text-green-700">
                      R$ {produto.valorTotal.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </TableCell>
                  </TableRow>
                ))}
                {/* Linha de total */}
                <TableRow className="border-t-2 border-gray-300 bg-gray-50 font-semibold">
                  <TableCell className="text-gray-900">
                    TOTAL
                  </TableCell>
                  <TableCell className="text-right text-gray-900">
                    {produtos.reduce((sum, p) => sum + p.quantidade, 0).toLocaleString('pt-BR')}
                  </TableCell>
                  <TableCell className="text-right">
                    un
                  </TableCell>
                  <TableCell className="text-right text-green-700 text-base">
                    R$ {produtos.reduce((sum, p) => sum + p.valorTotal, 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

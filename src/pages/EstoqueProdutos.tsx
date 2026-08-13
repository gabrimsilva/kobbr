// @ts-nocheck
import { useState, useEffect, useMemo } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip"
import { Package, Layers, AlertTriangle, Loader2, AlertCircle, ArrowUpDown, Settings, X, HelpCircle } from "lucide-react"
import VariantesModal from "@/components/VariantesModal"
import BuscaUnificadaPDV from "@/components/pdv/BuscaUnificadaPDV"
import MovimentacaoManualModal from "@/components/MovimentacaoManualModal"
import EditarEstoqueModal from "@/components/EditarEstoqueModal"
import { stockService, produtoService, type StockItem } from "@/services"
import { calcularStatusEstoque } from "@/services/stockService"
import toast from "react-hot-toast"

interface StockItemWithProduct extends StockItem {
  product_name?: string
  has_variants?: boolean
  variants_count?: number
}

type FiltroStatus = 'ALL' | 'CRITICAL' | 'WARNING' | 'HEALTHY'

export default function EstoqueProdutos() {
  const [itens, setItens] = useState<StockItemWithProduct[]>([])
  const [termoBusca, setTermoBusca] = useState("")
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  
  // Estados para modal de variedades
  const [variantesModalOpen, setVariantesModalOpen] = useState(false)
  const [itemSelecionado, setItemSelecionado] = useState<{ stockItemId: string; productName: string } | null>(null)
  
  // Estados para modal de movimentação manual
  const [movimentacaoModalOpen, setMovimentacaoModalOpen] = useState(false)
  const [itemMovimentacao, setItemMovimentacao] = useState<{ 
    stockItemId: string; 
    productName: string;
    currentQty: number;
    hasVariants: boolean;
  } | null>(null)

  // Estados para modal de edição de estoque
  const [editarEstoqueModalOpen, setEditarEstoqueModalOpen] = useState(false)
  const [itemEdicao, setItemEdicao] = useState<{
    stockItemId: string;
    productName: string;
    minQty: number;
    reorderQty: number;
  } | null>(null)

  // Estado para ordenação
  const [ordenarPorCriticidade, setOrdenarPorCriticidade] = useState(true)

  // Estado para filtro de status
  const [filtroStatus, setFiltroStatus] = useState<FiltroStatus>('ALL')

  useEffect(() => {
    carregarItens()
  }, [])

  const carregarItens = async () => {
    try {
      setLoading(true)
      setError(null)
      
      const stockItems = await stockService.buscarTodos()
      
      // Buscar informações dos produtos e variantes
      const itensComInfo = await Promise.all(
        stockItems.map(async (item) => {
          try {
            const produto = await produtoService.buscarPorId(item.product_id)
            const variantes = await stockService.buscarVariantes(item.id)
            
            return {
              ...item,
              product_name: produto?.nome || 'Produto não encontrado',
              has_variants: variantes.length > 0,
              variants_count: variantes.length
            }
          } catch (err) {
            return {
              ...item,
              product_name: 'Erro ao carregar',
              has_variants: false,
              variants_count: 0
            }
          }
        })
      )
      
      setItens(itensComInfo)
    } catch (err) {
      console.error('Erro ao carregar estoque:', err)
      setError('Erro ao carregar estoque de produtos.')
    } finally {
      setLoading(false)
    }
  }

  const handleGerenciarVariantes = (item: StockItemWithProduct) => {
    setItemSelecionado({
      stockItemId: item.id,
      productName: item.product_name || 'Produto'
    })
    setVariantesModalOpen(true)
  }

  const handleAbrirMovimentacao = (item: StockItemWithProduct) => {
    setItemMovimentacao({
      stockItemId: item.id,
      productName: item.product_name || 'Produto',
      currentQty: item.quantidade,
      hasVariants: item.has_variants || false
    })
    setMovimentacaoModalOpen(true)
  }

  const handleAbrirEdicaoEstoque = (item: StockItemWithProduct) => {
    setItemEdicao({
      stockItemId: item.id,
      productName: item.product_name || 'Produto',
      minQty: item.min_qty ?? 0,
      reorderQty: item.reorder_qty ?? 0
    })
    setEditarEstoqueModalOpen(true)
  }

  const handleBuscarPorBarcode = async (barcode: string) => {
    // Função removida temporariamente - código de barras será implementado depois
    toast.error('Busca por código de barras ainda não implementada', { id: 'barcode-search' })
  }

  const itensFiltrados = itens.filter(item =>
    item.product_name?.toLowerCase().includes(termoBusca.toLowerCase())
  )

  // Aplicar filtro de status
  const aplicarFiltroStatus = (itens: StockItemWithProduct[]) => {
    if (filtroStatus === 'ALL') {
      return itens
    }
    
    return itens.filter(item => {
      const status = calcularStatusEstoque(item.quantidade, item.min_qty ?? 0, item.reorder_qty ?? 0)
      return status === filtroStatus
    })
  }

  const itensFiltradosPorStatus = aplicarFiltroStatus(itensFiltrados)

  // Calcular contadores de status (baseado em busca, não em filtro)
  const contadores = useMemo(() => {
    const critical = itensFiltrados.filter(item => 
      calcularStatusEstoque(item.quantidade, item.min_qty ?? 0, item.reorder_qty ?? 0) === 'CRITICAL'
    ).length
    
    const warning = itensFiltrados.filter(item => 
      calcularStatusEstoque(item.quantidade, item.min_qty ?? 0, item.reorder_qty ?? 0) === 'WARNING'
    ).length
    
    const healthy = itensFiltrados.filter(item => 
      calcularStatusEstoque(item.quantidade, item.min_qty ?? 0, item.reorder_qty ?? 0) === 'HEALTHY'
    ).length
    
    return { critical, warning, healthy, total: itensFiltrados.length }
  }, [itensFiltrados])

  // Função de ordenação
  const ordenarItens = (itens: StockItemWithProduct[]) => {
    if (!ordenarPorCriticidade) {
      return [...itens].sort((a, b) => 
        (a.product_name || '').localeCompare(b.product_name || '')
      )
    }

    return [...itens].sort((a, b) => {
      const statusA = calcularStatusEstoque(a.quantidade, a.min_qty ?? 0, a.reorder_qty ?? 0)
      const statusB = calcularStatusEstoque(b.quantidade, b.min_qty ?? 0, b.reorder_qty ?? 0)
      
      const prioridadeA = statusA === 'CRITICAL' ? 1 : statusA === 'WARNING' ? 2 : 3
      const prioridadeB = statusB === 'CRITICAL' ? 1 : statusB === 'WARNING' ? 2 : 3
      
      if (prioridadeA !== prioridadeB) {
        return prioridadeA - prioridadeB
      }
      
      return (a.product_name || '').localeCompare(b.product_name || '')
    })
  }

  // Aplicar ordenação
  const itensOrdenados = useMemo(() => 
    ordenarItens(itensFiltradosPorStatus), 
    [itensFiltradosPorStatus, ordenarPorCriticidade]
  )

  // Função para obter label do filtro
  const getFiltroLabel = (filtro: FiltroStatus) => {
    switch (filtro) {
      case 'CRITICAL': return '🔴 Críticos'
      case 'WARNING': return '🟡 Atenção'
      case 'HEALTHY': return '🟢 Saudáveis'
      default: return '📦 Todos'
    }
  }

  // Função para alternar filtro
  const toggleFiltro = (novoFiltro: FiltroStatus) => {
    setFiltroStatus(filtroStatus === novoFiltro ? 'ALL' : novoFiltro)
  }

  const getStatusInfo = (item: StockItemWithProduct) => {
    const status = calcularStatusEstoque(item.quantidade, item.min_qty ?? 0, item.reorder_qty ?? 0)
    
    switch (status) {
      case 'CRITICAL':
        return { 
          status: 'CRITICAL', 
          label: '🔴 Crítico', 
          cor: 'red', 
          bgClass: 'bg-red-100 border-red-200',
          textClass: 'text-red-800',
          icon: AlertTriangle 
        }
      case 'WARNING':
        return { 
          status: 'WARNING', 
          label: '🟡 Atenção', 
          cor: 'yellow', 
          bgClass: 'bg-yellow-100 border-yellow-200',
          textClass: 'text-yellow-800',
          icon: AlertTriangle 
        }
      case 'HEALTHY':
        return { 
          status: 'HEALTHY', 
          label: '🟢 Saudável', 
          cor: 'green', 
          bgClass: 'bg-green-100 border-green-200',
          textClass: 'text-green-800',
          icon: Package 
        }
    }
  }

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-[400px]">
        <div className="flex items-center gap-2">
          <Loader2 className="h-6 w-6 animate-spin" />
          <span>Carregando estoque...</span>
        </div>
      </div>
    )
  }

  return (
    <div className="container mx-auto p-6 space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold tracking-tight flex items-center gap-2">
          <Package className="h-6 w-6" />
          Estoque de Produtos
        </h1>
        <p className="text-muted-foreground">
          Controle de estoque com variedades (cor, fragrância, tamanho)
        </p>
      </div>

      {error && (
        <div className="flex items-center gap-2 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
          <AlertCircle className="h-5 w-5" />
          <span>{error}</span>
        </div>
      )}

      {/* Resumo do Estoque */}
      {itens.length > 0 && (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="text-base">📊 Resumo do Estoque</CardTitle>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setOrdenarPorCriticidade(!ordenarPorCriticidade)}
              >
                {ordenarPorCriticidade ? (
                  <>
                    <AlertTriangle className="h-4 w-4 mr-2" />
                    Por Criticidade
                  </>
                ) : (
                  <>
                    <ArrowUpDown className="h-4 w-4 mr-2" />
                    Alfabético
                  </>
                )}
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {/* Críticos */}
              <div 
                onClick={() => toggleFiltro('CRITICAL')}
                className={`
                  flex items-center gap-3 p-3 bg-red-50 rounded-lg border border-red-200
                  cursor-pointer transition-all
                  ${filtroStatus === 'CRITICAL' 
                    ? 'ring-2 ring-red-500 shadow-lg scale-105' 
                    : 'hover:shadow-md hover:scale-102'
                  }
                `}
              >
                <span className="text-3xl">🔴</span>
                <div>
                  <p className="text-2xl font-bold text-red-600">{contadores.critical}</p>
                  <p className="text-xs text-red-700 font-medium">Críticos</p>
                </div>
              </div>

              {/* Atenção */}
              <div 
                onClick={() => toggleFiltro('WARNING')}
                className={`
                  flex items-center gap-3 p-3 bg-yellow-50 rounded-lg border border-yellow-200
                  cursor-pointer transition-all
                  ${filtroStatus === 'WARNING' 
                    ? 'ring-2 ring-yellow-500 shadow-lg scale-105' 
                    : 'hover:shadow-md hover:scale-102'
                  }
                `}
              >
                <span className="text-3xl">🟡</span>
                <div>
                  <p className="text-2xl font-bold text-yellow-600">{contadores.warning}</p>
                  <p className="text-xs text-yellow-700 font-medium">Atenção</p>
                </div>
              </div>

              {/* Saudáveis */}
              <div 
                onClick={() => toggleFiltro('HEALTHY')}
                className={`
                  flex items-center gap-3 p-3 bg-green-50 rounded-lg border border-green-200
                  cursor-pointer transition-all
                  ${filtroStatus === 'HEALTHY' 
                    ? 'ring-2 ring-green-500 shadow-lg scale-105' 
                    : 'hover:shadow-md hover:scale-102'
                  }
                `}
              >
                <span className="text-3xl">🟢</span>
                <div>
                  <p className="text-2xl font-bold text-green-600">{contadores.healthy}</p>
                  <p className="text-xs text-green-700 font-medium">Saudáveis</p>
                </div>
              </div>

              {/* Total */}
              <div 
                onClick={() => setFiltroStatus('ALL')}
                className={`
                  flex items-center gap-3 p-3 bg-gray-50 rounded-lg border border-gray-200
                  cursor-pointer transition-all
                  ${filtroStatus === 'ALL' 
                    ? 'ring-2 ring-gray-500 shadow-lg scale-105' 
                    : 'hover:shadow-md hover:scale-102'
                  }
                `}
              >
                <span className="text-3xl">📦</span>
                <div>
                  <p className="text-2xl font-bold text-gray-600">{contadores.total}</p>
                  <p className="text-xs text-gray-700 font-medium">Total</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Indicador de Filtro Ativo */}
      {filtroStatus !== 'ALL' && (
        <div className="flex items-center justify-between p-3 bg-indigo-50 border border-indigo-200 rounded-lg">
          <div className="flex items-center gap-2">
            <span className="text-sm font-medium text-indigo-900">
              Filtrando: {getFiltroLabel(filtroStatus)}
            </span>
            <span className="text-xs text-indigo-700">
              ({itensOrdenados.length} {itensOrdenados.length === 1 ? 'produto' : 'produtos'})
            </span>
          </div>
          <Button 
            size="sm" 
            variant="ghost"
            onClick={() => setFiltroStatus('ALL')}
            className="text-indigo-700 hover:text-indigo-900 hover:bg-indigo-100"
          >
            <X className="h-4 w-4 mr-1" />
            Limpar Filtro
          </Button>
        </div>
      )}

      {/* Scanner de Código de Barras */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Entrada Rápida por Código de Barras</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <BuscaUnificadaPDV
            onBuscarPorNome={setTermoBusca}
            onBuscarPorBarcode={handleBuscarPorBarcode}
            placeholder="Buscar por nome ou código de barras..."
          />
          <div className="text-xs text-gray-500 space-y-1 pt-2 border-t">
            <p className="flex items-start gap-2">
              <span className="text-base">💡</span>
              <span>Digite o nome do produto para filtrar a lista</span>
            </p>
            <p className="flex items-start gap-2">
              <span className="text-base">📱</span>
              <span>Use o leitor de código de barras (BIP) para localizar o produto</span>
            </p>
            <p className="flex items-start gap-2">
              <span className="text-base">⌨️</span>
              <span>Ou digite o código e pressione Enter</span>
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Lista de itens */}
      {itensOrdenados.length === 0 ? (
        <div className="text-center py-12">
          <Package className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-muted-foreground mb-2">
            {termoBusca ? "Nenhum produto encontrado" : "Nenhum produto com estoque"}
          </h3>
          <p className="text-muted-foreground">
            {termoBusca 
              ? "Tente buscar com outros termos" 
              : "Crie produtos com controle de estoque ativado"
            }
          </p>
        </div>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {itensOrdenados.map((item) => {
            const statusInfo = getStatusInfo(item)
            const StatusIcon = statusInfo.icon

            return (
              <Card key={item.id} id={`stock-item-${item.id}`} className="transition-all">
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <CardTitle className="flex items-center gap-2 text-base">
                      <StatusIcon className={`h-5 w-5 text-${statusInfo.cor}-500`} />
                      {item.product_name}
                    </CardTitle>
                  </div>
                </CardHeader>
                <CardContent className="space-y-3">
                  {/* Quantidade */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5">
                      <span className="text-sm font-medium">Quantidade:</span>
                      <TooltipProvider>
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <HelpCircle className="h-3.5 w-3.5 text-muted-foreground cursor-help" />
                          </TooltipTrigger>
                          <TooltipContent side="top" className="max-w-[250px]">
                            <p className="text-xs">
                              {item.has_variants 
                                ? "Este total é calculado automaticamente pela soma de todas as variantes do produto."
                                : "Quantidade total em estoque. Use 'Entrada / Saída' para ajustar."}
                            </p>
                          </TooltipContent>
                        </Tooltip>
                      </TooltipProvider>
                    </div>
                    <span className={`font-bold text-${statusInfo.cor}-600 text-lg`}>
                      {item.quantidade}
                    </span>
                  </div>

                  {/* Variedades */}
                  {item.has_variants && (
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted-foreground">Variedades:</span>
                      <span className="font-medium">{item.variants_count}</span>
                    </div>
                  )}

                  {/* Status */}
                  <div className={`
                    inline-flex items-center justify-center w-full px-2.5 py-1.5 rounded-md text-xs font-medium border
                    ${statusInfo.bgClass} ${statusInfo.textClass}
                  `}>
                    {statusInfo.label}
                  </div>

                  {/* Botão Gerenciar Variedades */}
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleGerenciarVariantes(item)}
                    className="w-full"
                  >
                    <Layers className="h-4 w-4 mr-2" />
                    Gerenciar Variedades
                  </Button>

                  {/* Botão Entrada/Saída Manual */}
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleAbrirMovimentacao(item)}
                    className="w-full border-indigo-200 text-indigo-700 hover:bg-indigo-50"
                  >
                    <ArrowUpDown className="h-4 w-4 mr-2" />
                    Entrada / Saída
                  </Button>

                  {/* Botão Configurar Estoque */}
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleAbrirEdicaoEstoque(item)}
                    className="w-full border-gray-200 text-gray-700 hover:bg-gray-50"
                  >
                    <Settings className="h-4 w-4 mr-2" />
                    Configurar Estoque
                  </Button>

                  {item.has_variants && (
                    <p className="text-xs text-muted-foreground text-center pt-1 border-t">
                      💡 Total calculado automaticamente pela soma das variantes
                    </p>
                  )}
                </CardContent>
              </Card>
            )
          })}
        </div>
      )}

      {/* Modal de Variedades */}
      {itemSelecionado && (
        <VariantesModal
          isOpen={variantesModalOpen}
          onClose={() => {
            setVariantesModalOpen(false)
            setItemSelecionado(null)
          }}
          stockItemId={itemSelecionado.stockItemId}
          productName={itemSelecionado.productName}
          onVariantesChanged={carregarItens}
        />
      )}

      {/* Modal de Movimentação Manual */}
      {itemMovimentacao && (
        <MovimentacaoManualModal
          isOpen={movimentacaoModalOpen}
          onClose={() => {
            setMovimentacaoModalOpen(false)
            setItemMovimentacao(null)
          }}
          stockItemId={itemMovimentacao.stockItemId}
          productName={itemMovimentacao.productName}
          currentQty={itemMovimentacao.currentQty}
          hasVariants={itemMovimentacao.hasVariants}
          onMovimentacaoCompleta={carregarItens}
        />
      )}

      {/* Modal de Edição de Estoque */}
      {itemEdicao && (
        <EditarEstoqueModal
          isOpen={editarEstoqueModalOpen}
          onClose={() => {
            setEditarEstoqueModalOpen(false)
            setItemEdicao(null)
          }}
          stockItemId={itemEdicao.stockItemId}
          productName={itemEdicao.productName}
          currentMinQty={itemEdicao.minQty}
          currentReorderQty={itemEdicao.reorderQty}
          onSaved={carregarItens}
        />
      )}
    </div>
  )
}

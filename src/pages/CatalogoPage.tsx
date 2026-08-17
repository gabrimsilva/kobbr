import { useState, useEffect } from 'react'
import Header from "@/components/Header"
import Footer from "@/components/Footer"
import CookieConsent from "@/components/CookieConsent"
import FiltroCategorias from "@/components/delivery/FiltroCategorias"
import BotaoVoltarTopo from "@/components/delivery/BotaoVoltarTopo"
import CatalogoProdutoCard, { type ProdutoCatalogo } from "@/components/delivery/CatalogoProdutoCard"
import CatalogoProdutoModal from "@/components/CatalogoProdutoModal"
import { ProdutoCardSkeletonGrid } from "@/components/skeletons/ProdutoCardSkeleton"
import { produtoService, categoriaService, configuracaoService, supabase, type CategoriaSupabase } from "@/services"

export default function CatalogoPage() {
  const [produtos, setProdutos] = useState<ProdutoCatalogo[]>([])
  const [categorias, setCategorias] = useState<CategoriaSupabase[]>([])
  const [categoriaAtiva, setCategoriaAtiva] = useState('todos')
  const [configuracao, setConfiguracao] = useState({
    nomeEstabelecimento: 'KOBE E-Commerce',
    logoUrl: '',
    bannerUrl: '',
    telefone: ''
  })
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [modalDetalhesAberto, setModalDetalhesAberto] = useState(false)
  const [produtoSelecionado, setProdutoSelecionado] = useState<ProdutoCatalogo | null>(null)

  // Carregar dados iniciais
  useEffect(() => {
    carregarDados()
  }, [])

  const carregarDados = async () => {
    try {
      setLoading(true)
      setError(null)

      const [produtosData, categoriasData, configsMap] = await Promise.all([
        // Buscar produtos diretamente sem tenant filter para o catálogo público
        supabase
          .from('produtos')
          .select('*')
          .eq('ativo', true)
          .eq('estabelecimento_id', 'e1cb89b8-8ccb-49b4-85f6-1badc1d396ae')
          .order('categoria_nome', { ascending: true })
          .order('nome', { ascending: true })
          .then(({ data, error }) => {
            if (error) throw error
            return data || []
          }),
        categoriaService.buscarAtivas(),
        configuracaoService.buscarMultiplas([
          'nome_estabelecimento',
          'logo_url',
          'banner_url',
          'telefone'
        ])
      ])

      // Converter produtos para formato do catálogo
      const produtosCatalogo: ProdutoCatalogo[] = produtosData
        .filter(p => p.ativo)
        .map(p => ({
          id: p.id,
          nome: p.nome,
          descricao: p.descricao || '',
          preco: p.preco,
          precoPromocional: p.preco_promocional,
          categoria: p.categoria_nome || 'Outros',
          urlImagem: p.imagem_path || '/placeholder-food.svg',
          estoqueDisponivel: true, // Sempre disponível no catálogo
          quantidadeEstoque: 999
        }))

      console.log('📦 Produtos carregados:', produtosCatalogo.length)
      console.log('🏷️ Categorias carregadas:', categoriasData.length)
      console.log('Produtos:', produtosCatalogo)
      console.log('Categorias:', categoriasData)
      
      setProdutos(produtosCatalogo)
      setCategorias(categoriasData)

      // Configurações
      const nomeEstab = configsMap.get('nome_estabelecimento')?.valor || 'KOBE E-Commerce'
      const logoUrl = configsMap.get('logo_url')?.valor || ''
      const bannerUrl = configsMap.get('banner_url')?.valor || ''
      const telefone = configsMap.get('telefone')?.valor || ''

      setConfiguracao({
        nomeEstabelecimento: nomeEstab,
        logoUrl,
        bannerUrl,
        telefone
      })

    } catch (err) {
      console.error('Erro ao carregar catálogo:', err)
      setError('Erro ao carregar o catálogo. Tente novamente mais tarde.')
    } finally {
      setLoading(false)
    }
  }

  const handleAbrirDetalhes = (produto: ProdutoCatalogo) => {
    setProdutoSelecionado(produto)
    setModalDetalhesAberto(true)
  }

  const handleFecharModal = () => {
    setModalDetalhesAberto(false)
    setProdutoSelecionado(null)
  }

  // Filtrar produtos por categoria
  const produtosFiltrados = categoriaAtiva === 'todos'
    ? produtos
    : produtos.filter(p => p.categoria.toLowerCase() === categoriaAtiva.toLowerCase())

  // Agrupar produtos por categoria
  const produtosAgrupados = categorias.reduce((acc, cat) => {
    const produtosCategoria = produtos.filter(p => 
      p.categoria.toLowerCase() === cat.nome.toLowerCase()
    )
    if (produtosCategoria.length > 0) {
      acc.push({
        categoria: cat,
        produtos: produtosCategoria
      })
    }
    return acc
  }, [] as { categoria: CategoriaSupabase; produtos: ProdutoCatalogo[] }[])

  const obterNomeCategoria = (categoriaId: string): string => {
    if (categoriaId === 'todos') return 'Todos os Produtos'
    const cat = categorias.find(c => c.nome.toLowerCase() === categoriaId.toLowerCase())
    return cat?.nome || categoriaId
  }

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      {/* Header */}
      <Header
        nomeEstabelecimento={configuracao.nomeEstabelecimento}
        logoUrl={configuracao.logoUrl}
        bannerUrl={configuracao.bannerUrl}
        onMaisInformacoes={() => {}} // Pode adicionar modal de info depois
      />

      {/* Banner */}
      {configuracao.bannerUrl && (
        <div className="w-full h-32 md:h-48 bg-gradient-to-r from-purple-600 to-pink-600 relative overflow-hidden">
          <img
            src={configuracao.bannerUrl}
            alt="Banner"
            className="w-full h-full object-cover"
            onError={(e) => {
              const target = e.target as HTMLImageElement
              target.style.display = 'none'
            }}
          />
          <div className="absolute inset-0 bg-gradient-to-r from-purple-900/50 to-pink-900/50 flex items-center justify-center">
            <div className="text-center text-white">
              <h1 className="text-3xl md:text-5xl font-bold mb-2">Catálogo de Produtos</h1>
              <p className="text-lg md:text-xl">Térmicas Atacado - Qualidade e Preço</p>
            </div>
          </div>
        </div>
      )}

      {/* Conteúdo Principal */}
      <main className="flex-1 container mx-auto px-4 py-6 max-w-7xl">
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
            <p className="text-red-600 text-center">{error}</p>
          </div>
        )}

        {/* Filtro de Categorias */}
        <FiltroCategorias
          categorias={categorias}
          categoriaAtiva={categoriaAtiva}
          onCategoriaChange={setCategoriaAtiva}
        />

        {/* Loading */}
        {loading && <ProdutoCardSkeletonGrid count={6} />}

        {/* Grid de Produtos - Visualização por Categoria Ativa */}
        {!loading && categoriaAtiva === 'todos' && (
          <div className="space-y-8 mt-6">
            {produtosAgrupados.map(({ categoria, produtos: produtosCategoria }) => (
              <section key={categoria.id} id={`categoria-${categoria.id}`}>
                <h2 className="text-2xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                  {categoria.nome}
                  <span className="text-sm font-normal text-gray-500">
                    ({produtosCategoria.length} {produtosCategoria.length === 1 ? 'produto' : 'produtos'})
                  </span>
                </h2>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {produtosCategoria.map(produto => (
                    <CatalogoProdutoCard
                      key={produto.id}
                      produto={produto}
                      onAbrirDetalhes={handleAbrirDetalhes}
                    />
                  ))}
                </div>
              </section>
            ))}
          </div>
        )}

        {/* Grid de Produtos - Categoria Específica */}
        {!loading && categoriaAtiva !== 'todos' && (
          <div className="mt-6">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">
              {obterNomeCategoria(categoriaAtiva)}
              <span className="text-sm font-normal text-gray-500 ml-2">
                ({produtosFiltrados.length} {produtosFiltrados.length === 1 ? 'produto' : 'produtos'})
              </span>
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {produtosFiltrados.map(produto => (
                <CatalogoProdutoCard
                  key={produto.id}
                  produto={produto}
                  onAbrirDetalhes={handleAbrirDetalhes}
                />
              ))}
            </div>
          </div>
        )}

        {/* Mensagem vazia */}
        {!loading && produtosFiltrados.length === 0 && (
          <div className="text-center py-12">
            <p className="text-gray-500 text-lg">Nenhum produto encontrado nesta categoria.</p>
          </div>
        )}
      </main>

      {/* Footer */}
      <Footer />

      {/* Botão Voltar ao Topo */}
      <BotaoVoltarTopo />

      {/* Modal de Detalhes */}
      <CatalogoProdutoModal
        isOpen={modalDetalhesAberto}
        onClose={handleFecharModal}
        produto={produtoSelecionado}
        whatsapp={configuracao.telefone}
      />

      {/* Cookie Consent */}
      <CookieConsent />
    </div>
  )
}

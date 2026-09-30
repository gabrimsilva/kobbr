import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { ActionButton } from "@/components/ui/action-button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import ImageUpload from "@/components/ImageUpload"
import { categoriaService, type CategoriaSupabase, type ProdutoSupabase } from "@/services"
import {
  aplicarMascaraMoeda,
  formatarValorParaEdicao,
  parsearMoeda,
  formatarMoeda
} from "@/utils/formatacao"

type Categoria = CategoriaSupabase

interface Produto extends ProdutoSupabase {
  categoria: string
  urlImagem: string
  precoPromocional?: number
}

interface ProdutoFormProps {
  produtoParaEditar?: Produto | null
  onSave: (produto: any) => void
  onCancel: () => void
  saving?: boolean
}

export default function ProdutoForm({ produtoParaEditar, onSave, onCancel, saving = false }: ProdutoFormProps) {
  const [categorias, setCategorias] = useState<Categoria[]>([])
  const [nome, setNome] = useState("")
  const [descricao, setDescricao] = useState("")
  const [custo, setCusto] = useState("")
  const [preco, setPreco] = useState("")
  const [precoPromocional, setPrecoPromocional] = useState("")
  const [precoAtacado, setPrecoAtacado] = useState("")
  const [precoOnline, setPrecoOnline] = useState("")
  const [categoria, setCategoria] = useState<string>("")
  const [urlImagem, setUrlImagem] = useState("")
  const [requiresStock, setRequiresStock] = useState(true)
  const [barcode, setBarcode] = useState("")

  // Valores numéricos derivados (aceitam vírgula ou ponto)
  const custoNumerico = parsearMoeda(custo)
  const precoNumerico = parsearMoeda(preco)
  const precoPromocionalNumerico = parsearMoeda(precoPromocional)
  const precoAtacadoNumerico = parsearMoeda(precoAtacado)
  const precoOnlineNumerico = parsearMoeda(precoOnline)

  // Validação: custo não pode ser maior que o preço de venda.
  // Só acusa erro quando ambos os campos têm valor, para não reclamar
  // enquanto o usuário ainda está preenchendo o formulário.
  const custoMaiorQuePreco =
    custoNumerico > 0 && precoNumerico > 0 && custoNumerico > precoNumerico

  // Validação: preço promocional não pode ficar abaixo do custo
  const promocionalAbaixoDoCusto =
    precoPromocionalNumerico > 0 && custoNumerico > 0 && precoPromocionalNumerico < custoNumerico

  // Validação: preço de atacado não pode ficar abaixo do custo
  const atacadoAbaixoDoCusto =
    precoAtacadoNumerico > 0 && custoNumerico > 0 && precoAtacadoNumerico < custoNumerico

  // Validação: preço do pedido online não pode ficar abaixo do custo
  const onlineAbaixoDoCusto =
    precoOnlineNumerico > 0 && custoNumerico > 0 && precoOnlineNumerico < custoNumerico

  const erroCusto = custoMaiorQuePreco
    ? `O custo (${formatarMoeda(custoNumerico)}) é maior que o preço de venda (${formatarMoeda(precoNumerico)}). Confira se digitou o valor com a vírgula no lugar certo.`
    : ""

  const erroPrecoPromocional = promocionalAbaixoDoCusto
    ? `O preço promocional (${formatarMoeda(precoPromocionalNumerico)}) está abaixo do custo (${formatarMoeda(custoNumerico)}), o que gera prejuízo na venda.`
    : ""

  const erroPrecoAtacado = atacadoAbaixoDoCusto
    ? `O preço de atacado (${formatarMoeda(precoAtacadoNumerico)}) está abaixo do custo (${formatarMoeda(custoNumerico)}), o que gera prejuízo na venda.`
    : ""

  const erroPrecoOnline = onlineAbaixoDoCusto
    ? `O preço do pedido online (${formatarMoeda(precoOnlineNumerico)}) está abaixo do custo (${formatarMoeda(custoNumerico)}), o que gera prejuízo na venda.`
    : ""

  const formularioInvalido =
    !nome.trim() || !descricao.trim() || !preco || !urlImagem || custoMaiorQuePreco

  // Carregar categorias do Supabase
  useEffect(() => {
    carregarDados()
  }, [])

  const carregarDados = async () => {
    try {
      const categoriasData = await categoriaService.buscarTodas()

      const categoriasAtivas = categoriasData
        .filter(cat => cat.ativa)
        .sort((a, b) => a.ordem - b.ordem)
      setCategorias(categoriasAtivas)

      if (!produtoParaEditar && categoriasAtivas.length > 0) {
        setCategoria(categoriasAtivas[0].nome.toLowerCase())
      }
    } catch (error) {
      setCategorias([])
    }
  }

  useEffect(() => {
    if (produtoParaEditar) {
      setNome(produtoParaEditar.nome)
      setDescricao(produtoParaEditar.descricao)
      // Exibe no padrão brasileiro (11,50) em vez de 11.5
      setCusto(formatarValorParaEdicao(parsearMoeda((produtoParaEditar as any).custo ?? 0)))
      setPreco(formatarValorParaEdicao(parsearMoeda(produtoParaEditar.preco)))
      setPrecoPromocional(
        produtoParaEditar.precoPromocional
          ? formatarValorParaEdicao(parsearMoeda(produtoParaEditar.precoPromocional))
          : ""
      )
      setPrecoAtacado(
        (produtoParaEditar as any).preco_atacado
          ? formatarValorParaEdicao(parsearMoeda((produtoParaEditar as any).preco_atacado))
          : ""
      )
      setPrecoOnline(
        (produtoParaEditar as any).preco_online
          ? formatarValorParaEdicao(parsearMoeda((produtoParaEditar as any).preco_online))
          : ""
      )
      setCategoria(produtoParaEditar.categoria)
      setUrlImagem(produtoParaEditar.urlImagem)
      setRequiresStock((produtoParaEditar as any).requires_stock ?? true)
      setBarcode((produtoParaEditar as any).barcode || "")
    } else {
      setNome("")
      setDescricao("")
      setCusto("0")
      setPreco("")
      setPrecoPromocional("")
      setPrecoAtacado("")
      setCategoria('pizza')
      setUrlImagem("")
      setRequiresStock(true)
      setBarcode("")
    }
  }, [produtoParaEditar])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()

    if (!nome.trim() || !descricao.trim() || !preco || !urlImagem) return

    // 🔒 Trava: bloqueia o salvamento quando o custo é maior que o preço de venda
    if (custoMaiorQuePreco) return

    const categoriaSelecionada = categorias.find(cat => {
      const catNome = cat.nome.toLowerCase()
      const categoriaLower = categoria.toLowerCase()

      if (catNome === categoriaLower) return true

      if ((catNome === 'pizza' && categoriaLower === 'pizzas') ||
        (catNome === 'pizzas' && categoriaLower === 'pizza')) return true

      if (catNome.includes('pizza') && categoriaLower.includes('pizza')) return true

      return false
    })

    const produtoData = {
      nome: nome.trim(),
      descricao: descricao.trim(),
      custo: custoNumerico >= 0 ? custoNumerico : 0,
      preco: precoNumerico,
      preco_promocional: precoPromocionalNumerico > 0 ? precoPromocionalNumerico : null,
      precoPromocional: precoPromocionalNumerico > 0 ? precoPromocionalNumerico : null,
      preco_atacado: precoAtacadoNumerico > 0 ? precoAtacadoNumerico : null,
      preco_online: precoOnlineNumerico > 0 ? precoOnlineNumerico : null,
      categoria_id: categoriaSelecionada?.id || null,
      categoria_nome: categoria,
      categoria,
      imagem_path: urlImagem,
      urlImagem: urlImagem,
      sabores_disponiveis: false,
      saboresDisponiveis: false,
      quantidade_sabores: 1,
      quantidadeSabores: 1,
      ativo: true,
      permite_adicionais: false,
      saboresSelecionados: [],
      tamanhos: [],
      requires_stock: requiresStock,
      barcode: barcode.trim() || null
    }

    onSave(produtoData)
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="space-y-2">
        <Label htmlFor="nome">Nome do Produto</Label>
        <Input
          id="nome"
          type="text"
          placeholder="Ex: Batom Matte Rosa..."
          value={nome}
          onChange={(e) => setNome(e.target.value)}
          required
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="custo">Custo (R$)</Label>
        <Input
          id="custo"
          type="text"
          inputMode="decimal"
          placeholder="0,00"
          value={custo}
          onChange={(e) => setCusto(aplicarMascaraMoeda(e.target.value))}
          aria-invalid={!!erroCusto}
          aria-describedby={erroCusto ? "custo-erro" : undefined}
          className={erroCusto ? "border-red-500 focus-visible:ring-red-500" : ""}
        />
        {erroCusto ? (
          <p id="custo-erro" role="alert" className="text-sm text-red-600 font-medium">
            ⚠️ {erroCusto}
          </p>
        ) : (
          <p className="text-xs text-muted-foreground">
            Custo unitário do produto (usado para calcular o lucro nas métricas).
            Digite apenas números, começando pelos centavos: 125 vira 1,25
          </p>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label htmlFor="preco">Preço (R$)</Label>
          <Input
            id="preco"
            type="text"
            inputMode="decimal"
            placeholder="0,00"
            value={preco}
            onChange={(e) => setPreco(aplicarMascaraMoeda(e.target.value))}
            required
            aria-invalid={!!erroCusto}
            className={erroCusto ? "border-red-500 focus-visible:ring-red-500" : ""}
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="precoPromocional">Preço Promocional (R$)</Label>
          <Input
            id="precoPromocional"
            type="text"
            inputMode="decimal"
            placeholder="0,00 (opcional)"
            value={precoPromocional}
            onChange={(e) => setPrecoPromocional(aplicarMascaraMoeda(e.target.value))}
            aria-invalid={!!erroPrecoPromocional}
            aria-describedby={erroPrecoPromocional ? "promocional-erro" : undefined}
            className={erroPrecoPromocional ? "border-amber-500 focus-visible:ring-amber-500" : ""}
          />
          {erroPrecoPromocional && (
            <p id="promocional-erro" role="alert" className="text-sm text-amber-600 font-medium">
              ⚠️ {erroPrecoPromocional}
            </p>
          )}
        </div>
      </div>

      <div className="space-y-2">
        <Label htmlFor="precoOnline">Preço para Pedido Online (R$)</Label>
        <Input
          id="precoOnline"
          type="text"
          inputMode="decimal"
          placeholder="0,00 (opcional)"
          value={precoOnline}
          onChange={(e) => setPrecoOnline(aplicarMascaraMoeda(e.target.value))}
          aria-invalid={!!erroPrecoOnline}
          aria-describedby={erroPrecoOnline ? "online-erro" : "online-ajuda"}
          className={erroPrecoOnline ? "border-amber-500 focus-visible:ring-amber-500" : ""}
        />
        {erroPrecoOnline ? (
          <p id="online-erro" role="alert" className="text-sm text-amber-600 font-medium">
            ⚠️ {erroPrecoOnline}
          </p>
        ) : (
          <p id="online-ajuda" className="text-xs text-muted-foreground">
            Preço cobrado nos pedidos feitos pelo catálogo (varejo), separado do preço do PDV. Em branco, vale o preço do PDV.
          </p>
        )}
      </div>

      <div className="space-y-2">
        <Label htmlFor="precoAtacado">Preço de Atacado (R$)</Label>
        <Input
          id="precoAtacado"
          type="text"
          inputMode="decimal"
          placeholder="0,00 (opcional)"
          value={precoAtacado}
          onChange={(e) => setPrecoAtacado(aplicarMascaraMoeda(e.target.value))}
          aria-invalid={!!erroPrecoAtacado}
          aria-describedby={erroPrecoAtacado ? "atacado-erro" : "atacado-ajuda"}
          className={erroPrecoAtacado ? "border-amber-500 focus-visible:ring-amber-500" : ""}
        />
        {erroPrecoAtacado ? (
          <p id="atacado-erro" role="alert" className="text-sm text-amber-600 font-medium">
            ⚠️ {erroPrecoAtacado}
          </p>
        ) : (
          <p id="atacado-ajuda" className="text-xs text-muted-foreground">
            Preço cobrado quando o cliente compra no modo Atacado pelo catálogo. Em branco, vale o preço normal.
          </p>
        )}
      </div>

      <div className="space-y-2">
        <Label htmlFor="barcode">Código de Barras (opcional)</Label>
        <Input
          id="barcode"
          type="text"
          placeholder="Ex: 7891234567890"
          value={barcode}
          onChange={(e) => setBarcode(e.target.value)}
          maxLength={50}
        />
        <p className="text-xs text-muted-foreground">
          Use o leitor de código de barras ou digite manualmente
        </p>
      </div>

      <div className="space-y-2">
        <Label htmlFor="descricao">Descrição</Label>
        <textarea
          id="descricao"
          placeholder="Descreva o produto..."
          value={descricao}
          onChange={(e) => setDescricao(e.target.value)}
          required
          className="w-full min-h-[80px] px-3 py-2 border border-input bg-background text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 rounded-md resize-none"
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="categoria">Categoria</Label>
        <select
          id="categoria"
          value={categoria}
          onChange={(e) => setCategoria(e.target.value)}
          className="w-full px-3 py-2 border border-input bg-background text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 rounded-md"
          disabled={categorias.length === 0}
        >
          {categorias.length > 0 ? (
            categorias.map((cat) => (
              <option key={cat.id} value={cat.nome.toLowerCase()}>
                {cat.nome}
              </option>
            ))
          ) : (
            <option value="">Nenhuma categoria cadastrada</option>
          )}
        </select>
        {categorias.length === 0 && (
          <p className="text-sm text-amber-600">
            ⚠️ Cadastre categorias antes de criar produtos
          </p>
        )}
        {precoPromocionalNumerico > 0 && (
          <p className="text-sm text-green-600 font-medium">
            ✨ Este produto também aparecerá na seção de promoções
          </p>
        )}
      </div>

      <div className="grid gap-2">
        <span className="text-sm font-medium">Imagem do Produto *</span>
        <ImageUpload
          currentImageUrl={urlImagem}
          onImageUploaded={setUrlImagem}
          bucketName="produtos-imagens"
          folder="produtos"
          recommendedSize="400x300px"
          placeholder="Clique para fazer upload da imagem do produto"
          maxSizeMB={5}
        />
      </div>

      {/* Toggle de Controle de Estoque */}
      <div className="space-y-3 border-t pt-4">
        <div className="flex items-center justify-between">
          <div className="space-y-1">
            <Label htmlFor="requiresStock" className="text-base font-medium">
              Produto precisa de estoque
            </Label>
            <p className="text-sm text-muted-foreground">
              Se ativo, o sistema criará automaticamente o item no estoque
            </p>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={requiresStock}
            onClick={() => setRequiresStock(!requiresStock)}
            className={`
              relative inline-flex h-6 w-11 items-center rounded-full transition-colors border-2
              ${requiresStock 
                ? 'bg-indigo-500 border-indigo-500' 
                : 'bg-gray-300 border-gray-400'
              }
            `}
          >
            <span
              className={`
                inline-block h-4 w-4 transform rounded-full bg-white shadow-sm transition-transform
                ${requiresStock ? 'translate-x-6' : 'translate-x-1'}
              `}
            />
          </button>
        </div>
      </div>

      <div className="flex justify-end gap-3 pt-4 border-t">
        <Button type="button" variant="outline" onClick={onCancel} disabled={saving}>
          Cancelar
        </Button>
        <ActionButton 
          type="submit" 
          disabled={formularioInvalido}
          loading={saving}
        >
          {produtoParaEditar ? "Atualizar" : "Salvar"}
        </ActionButton>
      </div>
    </form>
  )
}

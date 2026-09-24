import { useEffect, useMemo, useState } from "react"
import { Sheet, SheetContent, SheetDescription, SheetFooter, SheetHeader, SheetTitle } from "@/components/ui/sheet"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { ArrowLeft, CreditCard, Loader2, Minus, Plus, QrCode, ShoppingBag, Trash2, Wallet } from "lucide-react"
import type { ProdutoCatalogo } from "@/components/delivery/CatalogoProdutoCard"
import { chaveItem, type ItemCarrinhoCatalogo } from "@/hooks/useCarrinhoCatalogo"
import { disponivelParaCompra, formatarReais, precoUnitario } from "./precos"
import { lojaOnlineService, type ConfigCatalogoPublica, type FormaPagamentoOnline, type TipoVenda } from "@/services/lojaOnlineService"
import { formatarTelefone } from "@/utils/formatacao"

const CHAVE_CLIENTE = "kobe_cliente_catalogo"

interface CarrinhoCatalogoSheetProps {
  aberto: boolean
  onMudarAberto: (aberto: boolean) => void
  itens: ItemCarrinhoCatalogo[]
  produtos: Map<string, ProdutoCatalogo>
  modo: TipoVenda
  config: ConfigCatalogoPublica
  onAlterarQuantidade: (chave: string, quantidade: number) => void
  onRemover: (chave: string) => void
  onPedidoCriado: () => void
}

const FORMAS: Array<{ id: FormaPagamentoOnline; titulo: string; detalhe: string; icone: typeof QrCode }> = [
  { id: "pix", titulo: "PIX", detalhe: "Aprovação na hora", icone: QrCode },
  { id: "credito", titulo: "Cartão de crédito", detalhe: "", icone: CreditCard },
  { id: "debito", titulo: "Cartão de débito", detalhe: "Débito online", icone: Wallet },
]

function lerCliente() {
  try {
    const salvo = JSON.parse(localStorage.getItem(CHAVE_CLIENTE) || "{}")
    return { nome: salvo.nome || "", telefone: salvo.telefone || "", email: salvo.email || "" }
  } catch {
    return { nome: "", telefone: "", email: "" }
  }
}

export default function CarrinhoCatalogoSheet({
  aberto,
  onMudarAberto,
  itens,
  produtos,
  modo,
  config,
  onAlterarQuantidade,
  onRemover,
  onPedidoCriado,
}: CarrinhoCatalogoSheetProps) {
  const [etapa, setEtapa] = useState<"carrinho" | "dados">("carrinho")
  const [cliente, setCliente] = useState(lerCliente)
  const [observacoes, setObservacoes] = useState("")
  const [forma, setForma] = useState<FormaPagamentoOnline | null>(null)
  const [enviando, setEnviando] = useState(false)
  const [erro, setErro] = useState<string | null>(null)

  const formasAtivas = FORMAS.filter(f => config[f.id])

  useEffect(() => {
    if (!aberto) {
      setEtapa("carrinho")
      setErro(null)
    }
  }, [aberto])

  useEffect(() => {
    if (!forma && formasAtivas.length > 0) setForma(formasAtivas[0].id)
  }, [forma, formasAtivas])

  const linhas = useMemo(
    () =>
      itens
        .map(item => {
          const produto = produtos.get(item.produtoId)
          if (!produto) return null
          const unitario = precoUnitario(produto, modo)
          return {
            item,
            chave: chaveItem(item),
            produto,
            unitario,
            total: unitario * item.quantidade,
            disponivel: disponivelParaCompra(produto, item.varianteId),
          }
        })
        .filter((l): l is NonNullable<typeof l> => l !== null),
    [itens, produtos, modo]
  )

  const total = linhas.reduce((soma, l) => soma + l.total, 0)
  const faltaAtacado = modo === "atacado" ? Math.max(config.atacado_pedido_minimo - total, 0) : 0
  const excedeEstoque = linhas.some(l => l.disponivel !== null && l.item.quantidade > l.disponivel)
  const podeAvancar = linhas.length > 0 && faltaAtacado <= 0 && !excedeEstoque

  const telefoneDigitos = cliente.telefone.replace(/\D/g, "")
  const dadosValidos =
    cliente.nome.trim().split(/\s+/).length >= 2 &&
    telefoneDigitos.length >= 10 &&
    /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(cliente.email.trim()) &&
    !!forma

  const finalizar = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!dadosValidos || !forma || enviando) return
    setEnviando(true)
    setErro(null)
    try {
      try {
        localStorage.setItem(CHAVE_CLIENTE, JSON.stringify(cliente))
      } catch {
        /* sem storage */
      }
      const pedido = await lojaOnlineService.criarPedido({
        tipo_venda: modo,
        forma_pagamento: forma,
        cliente: { nome: cliente.nome.trim(), telefone: telefoneDigitos, email: cliente.email.trim() },
        itens: linhas.map(l => ({
          produto_id: l.item.produtoId,
          variante_id: l.item.varianteId,
          quantidade: l.item.quantidade,
        })),
        observacoes: observacoes.trim() || undefined,
      })
      onPedidoCriado()
      window.location.href = pedido.checkout_url
    } catch (err) {
      setErro(err instanceof Error ? err.message : "Não foi possível criar o pedido.")
      setEnviando(false)
    }
  }

  return (
    <Sheet open={aberto} onOpenChange={onMudarAberto}>
      <SheetContent side="right" className="w-full sm:max-w-md p-0 gap-0">
        <SheetHeader className="border-b pr-12">
          <SheetTitle className="flex items-center gap-2 text-lg">
            {etapa === "dados" && (
              <button
                type="button"
                onClick={() => setEtapa("carrinho")}
                className="p-1 -ml-1 rounded-full hover:bg-gray-100 cursor-pointer"
                aria-label="Voltar ao carrinho"
              >
                <ArrowLeft className="h-4 w-4" />
              </button>
            )}
            {etapa === "carrinho" ? "Seu carrinho" : "Finalizar pedido"}
            <span className="ml-auto text-xs font-semibold uppercase tracking-wide text-purple-700 bg-purple-50 px-2 py-0.5 rounded-full">
              {modo === "atacado" ? "Atacado" : "Varejo"}
            </span>
          </SheetTitle>
          <SheetDescription>
            {etapa === "carrinho"
              ? `${linhas.length} ${linhas.length === 1 ? "item" : "itens"}`
              : "Informe seus dados e a forma de pagamento"}
          </SheetDescription>
        </SheetHeader>

        {etapa === "carrinho" ? (
          <>
            <div className="flex-1 overflow-y-auto p-4 space-y-3">
              {linhas.length === 0 && (
                <div className="text-center py-16 text-gray-500">
                  <ShoppingBag className="h-10 w-10 mx-auto mb-3 text-gray-300" />
                  <p>Seu carrinho está vazio.</p>
                </div>
              )}
              {linhas.map(l => (
                <div key={l.chave} className="flex gap-3 border border-gray-200 rounded-xl p-3">
                  <img
                    src={l.produto.urlImagem}
                    alt=""
                    className="w-16 h-16 rounded-lg object-cover flex-shrink-0"
                    onError={(e) => { (e.target as HTMLImageElement).src = "/placeholder-food.svg" }}
                  />
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-sm text-gray-900 leading-tight">{l.produto.nome}</p>
                    {l.item.varianteNome && <p className="text-xs text-gray-500">{l.item.varianteNome}</p>}
                    <p className="text-xs text-gray-500 mt-0.5">{formatarReais(l.unitario)} / un.</p>
                    {l.disponivel !== null && l.item.quantidade > l.disponivel && (
                      <p className="text-xs text-red-600 font-medium mt-1" role="alert">
                        {l.disponivel > 0 ? `Só temos ${l.disponivel} em estoque.` : "Esgotado. Remova este item."}
                      </p>
                    )}
                    <div className="flex items-center justify-between mt-2">
                      <div className="flex items-center gap-1.5">
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          className="h-7 w-7 p-0 rounded-full"
                          onClick={() => onAlterarQuantidade(l.chave, l.item.quantidade - 1)}
                          aria-label={`Diminuir ${l.produto.nome}`}
                        >
                          <Minus className="h-3.5 w-3.5" />
                        </Button>
                        <span className="w-8 text-center text-sm font-medium tabular-nums">{l.item.quantidade}</span>
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          className="h-7 w-7 p-0 rounded-full"
                          onClick={() => onAlterarQuantidade(l.chave, l.item.quantidade + 1)}
                          disabled={l.disponivel !== null && l.item.quantidade >= l.disponivel}
                          aria-label={`Aumentar ${l.produto.nome}`}
                        >
                          <Plus className="h-3.5 w-3.5" />
                        </Button>
                        <button
                          type="button"
                          onClick={() => onRemover(l.chave)}
                          className="ml-1 p-1.5 text-gray-400 hover:text-red-600 rounded-full cursor-pointer"
                          aria-label={`Remover ${l.produto.nome}`}
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                      <span className="font-bold text-sm text-gray-900 tabular-nums">{formatarReais(l.total)}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {linhas.length > 0 && (
              <SheetFooter className="border-t bg-gray-50">
                {faltaAtacado > 0 && (
                  <p className="text-sm text-amber-800 bg-amber-50 border border-amber-200 rounded-lg p-2.5" role="status">
                    Pedido mínimo no atacado: {formatarReais(config.atacado_pedido_minimo)}. Faltam{" "}
                    <strong>{formatarReais(faltaAtacado)}</strong>.
                  </p>
                )}
                <div className="flex justify-between items-baseline">
                  <span className="text-gray-600">Total</span>
                  <span className="text-2xl font-bold text-gray-900 tabular-nums">{formatarReais(total)}</span>
                </div>
                <Button
                  onClick={() => setEtapa("dados")}
                  disabled={!podeAvancar}
                  className="w-full h-12 text-base font-semibold bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white cursor-pointer"
                >
                  Continuar
                </Button>
              </SheetFooter>
            )}
          </>
        ) : (
          <form onSubmit={finalizar} className="flex-1 flex flex-col min-h-0">
            <div className="flex-1 overflow-y-auto p-4 space-y-4">
              <div className="space-y-1.5">
                <Label htmlFor="cat-nome">Nome completo</Label>
                <Input
                  id="cat-nome"
                  autoComplete="name"
                  value={cliente.nome}
                  onChange={(e) => setCliente(c => ({ ...c, nome: e.target.value }))}
                  maxLength={100}
                  required
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="cat-telefone">WhatsApp</Label>
                <Input
                  id="cat-telefone"
                  type="tel"
                  inputMode="tel"
                  autoComplete="tel-national"
                  placeholder="(41) 99999-9999"
                  value={cliente.telefone}
                  onChange={(e) => setCliente(c => ({ ...c, telefone: formatarTelefone(e.target.value) }))}
                  maxLength={15}
                  required
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="cat-email">E-mail</Label>
                <Input
                  id="cat-email"
                  type="email"
                  autoComplete="email"
                  value={cliente.email}
                  onChange={(e) => setCliente(c => ({ ...c, email: e.target.value }))}
                  maxLength={120}
                  required
                />
                <p className="text-xs text-gray-500">O comprovante do pagamento é enviado para este e-mail.</p>
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="cat-obs">Observações (opcional)</Label>
                <textarea
                  id="cat-obs"
                  value={observacoes}
                  onChange={(e) => setObservacoes(e.target.value)}
                  maxLength={500}
                  rows={2}
                  className="w-full px-3 py-2 border border-input bg-background text-sm rounded-md resize-none focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                />
              </div>

              <fieldset className="space-y-2">
                <legend className="text-sm font-medium mb-2">Forma de pagamento</legend>
                {formasAtivas.map(f => {
                  const Icone = f.icone
                  const detalhe =
                    f.id === "credito"
                      ? config.max_parcelas > 1
                        ? `Em até ${config.max_parcelas}x`
                        : "À vista"
                      : f.detalhe
                  return (
                    <label
                      key={f.id}
                      className={`flex items-center gap-3 border rounded-xl p-3 cursor-pointer transition-colors ${
                        forma === f.id ? "border-purple-600 bg-purple-50" : "border-gray-200 hover:border-purple-300"
                      }`}
                    >
                      <input
                        type="radio"
                        name="forma-pagamento"
                        value={f.id}
                        checked={forma === f.id}
                        onChange={() => setForma(f.id)}
                        className="accent-purple-600"
                      />
                      <Icone className="h-5 w-5 text-purple-700" aria-hidden="true" />
                      <span className="flex-1">
                        <span className="block text-sm font-medium text-gray-900">{f.titulo}</span>
                        {detalhe && <span className="block text-xs text-gray-500">{detalhe}</span>}
                      </span>
                    </label>
                  )
                })}
              </fieldset>
            </div>

            <SheetFooter className="border-t bg-gray-50">
              {erro && (
                <p className="text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg p-2.5" role="alert">
                  {erro}
                </p>
              )}
              <div className="flex justify-between items-baseline">
                <span className="text-gray-600">Total</span>
                <span className="text-2xl font-bold text-gray-900 tabular-nums">{formatarReais(total)}</span>
              </div>
              <Button
                type="submit"
                disabled={!dadosValidos || enviando}
                className="w-full h-12 text-base font-semibold bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white cursor-pointer"
              >
                {enviando ? (
                  <>
                    <Loader2 className="h-5 w-5 animate-spin" /> Gerando pagamento...
                  </>
                ) : (
                  "Ir para o pagamento"
                )}
              </Button>
              <p className="text-xs text-center text-gray-500">
                Você será levado ao ambiente seguro do Mercado Pago.
              </p>
            </SheetFooter>
          </form>
        )}
      </SheetContent>
    </Sheet>
  )
}

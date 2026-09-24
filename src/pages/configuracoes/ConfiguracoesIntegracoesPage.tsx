import { useEffect, useState } from "react"
import toast from "react-hot-toast"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { ActionButton } from "@/components/ui/action-button"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { CheckCircle2, ExternalLink, KeyRound, Loader2, Save, ShoppingBag, AlertTriangle } from "lucide-react"
import { lojaOnlineService, type ConfigLojaOnline } from "@/services/lojaOnlineService"
import { aplicarMascaraMoeda, formatarValorParaEdicao, parsearMoeda } from "@/utils/formatacao"

/**
 * Configurações > Integração de Pagamentos
 * Mercado Pago (Checkout Pro) para os pedidos feitos pelo catálogo, formas
 * de pagamento online e regras do atacado.
 */
export default function ConfiguracoesIntegracoesPage() {
  const [config, setConfig] = useState<ConfigLojaOnline | null>(null)
  const [pedidoMinimo, setPedidoMinimo] = useState("")
  const [novoToken, setNovoToken] = useState("")
  const [editandoToken, setEditandoToken] = useState(false)
  const [salvando, setSalvando] = useState(false)
  const [erro, setErro] = useState<string | null>(null)

  useEffect(() => {
    lojaOnlineService
      .buscarConfig()
      .then(c => {
        setConfig(c)
        setPedidoMinimo(c.atacado_pedido_minimo > 0 ? formatarValorParaEdicao(c.atacado_pedido_minimo) : "")
        setEditandoToken(!c.token_configurado)
      })
      .catch(e => setErro(e instanceof Error ? e.message : "Erro ao carregar"))
  }, [])

  if (!config) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        {erro ? <p className="text-red-600">{erro}</p> : <Loader2 className="h-6 w-6 animate-spin" />}
      </div>
    )
  }

  const atualizar = <K extends keyof ConfigLojaOnline>(campo: K, valor: ConfigLojaOnline[K]) =>
    setConfig(c => (c ? { ...c, [campo]: valor } : c))

  const tokenInformado = novoToken.trim()
  const tokenPareceTeste = tokenInformado.startsWith("TEST-")
  const tokenValido = !tokenInformado || /^(TEST|APP_USR)-[\w-]{20,}$/.test(tokenInformado)
  const temToken = config.token_configurado || !!tokenInformado
  const nenhumaForma = !config.pix_ativo && !config.credito_ativo && !config.debito_ativo

  const salvar = async () => {
    if (!tokenValido) {
      toast.error("O Access Token deve começar com TEST- ou APP_USR-")
      return
    }
    if (config.pedidos_ativos && (!temToken || nenhumaForma)) {
      toast.error("Para ativar os pedidos, informe o Access Token e ative ao menos uma forma de pagamento.")
      return
    }
    setSalvando(true)
    try {
      const salvo = await lojaOnlineService.salvarConfig(
        { ...config, atacado_pedido_minimo: parsearMoeda(pedidoMinimo) || 0 },
        tokenInformado ? tokenInformado : undefined
      )
      setConfig(salvo)
      setNovoToken("")
      setEditandoToken(!salvo.token_configurado)
      toast.success("Integração salva")
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Erro ao salvar")
    } finally {
      setSalvando(false)
    }
  }

  return (
    <div className="container mx-auto space-y-6 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold">Integração de Pagamentos</h2>
        <p className="text-muted-foreground">
          Pagamento online dos pedidos feitos pelo catálogo, via Mercado Pago
        </p>
      </div>

      {/* Ativação */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <ShoppingBag className="h-5 w-5 text-purple-600" />
            Pedidos pelo catálogo
          </CardTitle>
          <CardDescription>
            Quando ativo, o catálogo mostra preços, carrinho e checkout. Cada pedido cai em Pedidos.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Switch
            id="pedidos-ativos"
            checked={config.pedidos_ativos}
            onChange={v => atualizar("pedidos_ativos", v)}
            label="Receber pedidos pelo catálogo"
            description={
              config.pedidos_ativos
                ? "Clientes podem comprar e pagar online."
                : "O catálogo continua apenas como vitrine, com contato pelo WhatsApp."
            }
          />
        </CardContent>
      </Card>

      {/* Mercado Pago */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-lg">
            <KeyRound className="h-5 w-5 text-sky-600" />
            Mercado Pago
          </CardTitle>
          <CardDescription>
            Checkout Pro: o cliente paga em um ambiente seguro do Mercado Pago e volta para a loja.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="space-y-2">
            <Label htmlFor="mp-token">Access Token</Label>
            {config.token_configurado && !editandoToken ? (
              <div className="flex flex-wrap items-center gap-3">
                <span className="inline-flex items-center gap-1.5 text-sm text-green-700 bg-green-50 border border-green-200 rounded-md px-3 py-2">
                  <CheckCircle2 className="h-4 w-4" /> Token configurado
                </span>
                <Button type="button" variant="outline" size="sm" onClick={() => setEditandoToken(true)}>
                  Trocar token
                </Button>
              </div>
            ) : (
              <>
                <Input
                  id="mp-token"
                  type="password"
                  autoComplete="off"
                  placeholder="APP_USR-... ou TEST-..."
                  value={novoToken}
                  onChange={e => setNovoToken(e.target.value)}
                  aria-invalid={!tokenValido}
                />
                {!tokenValido && (
                  <p className="text-sm text-red-600" role="alert">O token deve começar com TEST- ou APP_USR-.</p>
                )}
                {config.token_configurado && (
                  <Button type="button" variant="ghost" size="sm" onClick={() => { setEditandoToken(false); setNovoToken("") }}>
                    Cancelar troca
                  </Button>
                )}
              </>
            )}
            <p className="text-xs text-muted-foreground">
              O token fica guardado no servidor e não pode ser lido pelo navegador depois de salvo.{" "}
              <a
                href="https://www.mercadopago.com.br/developers/panel/app"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-0.5 text-sky-700 underline"
              >
                Pegar credenciais <ExternalLink className="h-3 w-3" />
              </a>
            </p>
          </div>

          <fieldset className="space-y-2">
            <legend className="text-sm font-medium">Ambiente</legend>
            <div className="flex flex-wrap gap-2">
              {(["teste", "producao"] as const).map(amb => (
                <label
                  key={amb}
                  className={`flex items-center gap-2 border rounded-lg px-3 py-2 cursor-pointer text-sm ${
                    config.ambiente === amb ? "border-indigo-600 bg-indigo-50" : "border-gray-200"
                  }`}
                >
                  <input
                    type="radio"
                    name="ambiente"
                    checked={config.ambiente === amb}
                    onChange={() => atualizar("ambiente", amb)}
                    className="accent-indigo-600"
                  />
                  {amb === "teste" ? "Teste (sandbox)" : "Produção (vendas reais)"}
                </label>
              ))}
            </div>
            {tokenInformado && tokenPareceTeste && config.ambiente === "producao" && (
              <p className="text-sm text-amber-700 flex items-center gap-1.5">
                <AlertTriangle className="h-4 w-4" /> Token de teste com ambiente de produção.
              </p>
            )}
          </fieldset>
        </CardContent>
      </Card>

      {/* Formas de pagamento */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Formas de pagamento online</CardTitle>
          <CardDescription>O cliente escolhe uma delas no checkout do catálogo.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Switch checked={config.pix_ativo} onChange={v => atualizar("pix_ativo", v)} label="PIX" description="Aprovação imediata" />
          <Switch checked={config.debito_ativo} onChange={v => atualizar("debito_ativo", v)} label="Cartão de débito" description="Débito online (Caixa, Mercado Pago e bancos habilitados)" />
          <Switch checked={config.credito_ativo} onChange={v => atualizar("credito_ativo", v)} label="Cartão de crédito" />
          {config.credito_ativo && (
            <div className="pl-14 space-y-1.5">
              <Label htmlFor="max-parcelas">Parcelamento máximo</Label>
              <select
                id="max-parcelas"
                value={config.max_parcelas}
                onChange={e => atualizar("max_parcelas", Number(e.target.value))}
                className="w-40 px-3 py-2 border border-input bg-background text-sm rounded-md"
              >
                {Array.from({ length: 12 }, (_, i) => i + 1).map(n => (
                  <option key={n} value={n}>{n === 1 ? "À vista" : `Até ${n}x`}</option>
                ))}
              </select>
              <p className="text-xs text-muted-foreground">Juros do parcelamento seguem as regras da sua conta Mercado Pago.</p>
            </div>
          )}
          {nenhumaForma && (
            <p className="text-sm text-amber-700" role="alert">Ative ao menos uma forma de pagamento.</p>
          )}
        </CardContent>
      </Card>

      {/* Atacado */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Atacado</CardTitle>
          <CardDescription>
            No catálogo o cliente escolhe Varejo ou Atacado. No atacado vale o "Preço de Atacado" de cada produto.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Switch checked={config.atacado_ativo} onChange={v => atualizar("atacado_ativo", v)} label="Vender no atacado pelo catálogo" />
          {config.atacado_ativo && (
            <div className="space-y-1.5 max-w-xs">
              <Label htmlFor="pedido-minimo">Pedido mínimo no atacado (R$)</Label>
              <Input
                id="pedido-minimo"
                type="text"
                inputMode="decimal"
                placeholder="0,00 (sem mínimo)"
                value={pedidoMinimo}
                onChange={e => setPedidoMinimo(aplicarMascaraMoeda(e.target.value))}
              />
            </div>
          )}
        </CardContent>
      </Card>

      <div className="flex justify-end">
        <ActionButton onClick={salvar} loading={salvando} disabled={!tokenValido}>
          <Save className="h-4 w-4 mr-2" />
          Salvar
        </ActionButton>
      </div>
    </div>
  )
}

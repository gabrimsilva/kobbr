import { Button } from "@/components/ui/button"
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogDescription,
  AlertDialogFooter,
} from "@/components/ui/alert-dialog"
import { X, MessageCircle } from "lucide-react"
import type { ProdutoCatalogo } from "@/components/delivery/CatalogoProdutoCard"

interface CatalogoProdutoModalProps {
  isOpen: boolean
  onClose: () => void
  produto: ProdutoCatalogo | null
  whatsapp: string // Número do WhatsApp do estabelecimento
}

export default function CatalogoProdutoModal({
  isOpen,
  onClose,
  produto,
  whatsapp
}: CatalogoProdutoModalProps) {
  if (!produto) return null

  const precoExibicao = produto.precoPromocional && produto.precoPromocional > 0
    ? produto.precoPromocional
    : produto.preco

  const temPromocao = produto.precoPromocional && produto.precoPromocional > 0

  const handleWhatsApp = () => {
    console.log('🔍 Dados WhatsApp:')
    console.log('  - Telefone recebido:', whatsapp)
    console.log('  - Produto:', produto.nome)
    
    if (!whatsapp || whatsapp.trim() === '') {
      console.error('❌ WhatsApp não configurado!')
      alert('WhatsApp não configurado. Entre em contato pelo site.')
      return
    }
    
    // Mensagem simples sem emojis para evitar problemas de codificação
    const mensagem = `Olá! Vi o produto *${produto.nome}* no catálogo e fiquei interessado(a)!\n\nPoderia me passar mais informações sobre disponibilidade e formas de pagamento?\n\nAguardo retorno!`
    const whatsappClean = whatsapp.replace(/\D/g, '') // Remove caracteres não numéricos
    const url = `https://wa.me/55${whatsappClean}?text=${encodeURIComponent(mensagem)}`
    
    console.log('  - Telefone limpo:', whatsappClean)
    console.log('  - URL gerada:', url)
    console.log('  - Mensagem:', mensagem)
    
    window.open(url, '_blank')
  }

  return (
    <AlertDialog open={isOpen} onOpenChange={onClose}>
      <AlertDialogContent className="w-[525px] h-[500px] max-w-[calc(100%-2rem)] max-h-[90vh] p-0 overflow-hidden max-md:flex max-md:flex-col max-md:justify-between">
        {/* Botão fechar */}
        <button
          onClick={onClose}
          className="absolute right-3 top-3 z-10 rounded-full bg-white/90 p-1.5 hover:bg-white transition-colors shadow-md cursor-pointer"
          aria-label="Fechar"
        >
          <X className="h-3.5 w-3.5" />
        </button>

        {/* Badge de Promoção no topo da imagem */}
        {temPromocao && (
          <div className="absolute top-3 left-3 z-10 bg-gradient-to-r from-pink-500 to-purple-500 text-white text-sm font-bold px-4 py-1.5 rounded-full shadow-lg">
            {Math.round(((produto.preco - precoExibicao) / produto.preco) * 100)}% OFF
          </div>
        )}

        {/* Imagem do produto */}
        <div className="w-full h-56 bg-gray-100 max-md:h-[40vh] max-md:flex-shrink-0">
          <img
            src={produto.urlImagem}
            alt={produto.nome}
            className="w-full h-full object-cover"
            onError={(e) => {
              const target = e.target as HTMLImageElement
              target.src = '/placeholder-food.svg'
            }}
          />
        </div>

        {/* Conteúdo */}
        <div className="p-5 max-md:flex-1 max-md:flex max-md:flex-col max-md:justify-between max-md:overflow-y-auto">
          <AlertDialogHeader className="space-y-2 text-left">
            <AlertDialogTitle className="text-xl font-bold text-gray-900">
              {produto.nome}
            </AlertDialogTitle>
            
            <p className="text-sm text-purple-600 font-medium capitalize">
              {produto.categoria}
            </p>

            <AlertDialogDescription className="text-sm text-gray-600 leading-relaxed">
              {produto.descricao}
            </AlertDialogDescription>

            {!produto.estoqueDisponivel && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-3 mt-2">
                <p className="text-sm text-red-600 font-semibold">
                  ⚠️ Produto temporariamente indisponível
                </p>
              </div>
            )}
          </AlertDialogHeader>

          {/* Preço */}
          <div className="mt-4 mb-4 text-left">
            {temPromocao ? (
              <div className="flex items-center justify-start gap-3">
                <span className="text-3xl font-bold text-purple-600">
                  R$ {precoExibicao.toFixed(2).replace('.', ',')}
                </span>
                <div className="flex flex-col">
                  <span className="text-sm text-gray-400 line-through">
                    R$ {produto.preco.toFixed(2).replace('.', ',')}
                  </span>
                </div>
              </div>
            ) : (
              <span className="text-3xl font-bold text-purple-600">
                R$ {precoExibicao.toFixed(2).replace('.', ',')}
              </span>
            )}
          </div>

          {/* Botão WhatsApp */}
          <AlertDialogFooter className="sm:justify-center">
            <Button
              onClick={handleWhatsApp}
              className="w-full bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white font-semibold py-5 text-base cursor-pointer shadow-lg flex items-center justify-center gap-2"
            >
              <MessageCircle className="h-5 w-5" />
              Tenho interesse - Falar no WhatsApp
            </Button>
          </AlertDialogFooter>
        </div>
      </AlertDialogContent>
    </AlertDialog>
  )
}

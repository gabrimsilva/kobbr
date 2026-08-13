import { Info, ArrowLeft } from "lucide-react"
import LojaStatusBadge from "./LojaStatusBadge"

interface HeaderProps {
  nomeEstabelecimento: string
  logoUrl?: string
  bannerUrl?: string
  onMaisInformacoes: () => void
  showBackButton?: boolean
  onBack?: () => void
}

export default function Header({
  nomeEstabelecimento,
  logoUrl,
  bannerUrl,
  onMaisInformacoes,
  showBackButton = false,
  onBack
}: HeaderProps) {
  return (
    <div
      className="relative shadow-sm border-b overflow-hidden min-h-[200px]"
      style={{
        background: 'linear-gradient(135deg, #e3f2fd 0%, #bbdefb 30%, #90caf9 70%, #64b5f6 100%)'
      }}
    >
      {/* Banner como fundo - usa o configurado ou o fallback */}
      <div className="absolute inset-0 w-full h-full flex items-center justify-center">
        <div className="w-full h-full" style={{ maxWidth: '1550px' }}>
          <img
            src={bannerUrl || '/banner-exemplo.svg'}
            alt="Banner do estabelecimento"
            className="w-full h-full object-cover"
            onError={(e) => {
              const target = e.target as HTMLImageElement;
              target.style.display = 'none';
            }}
          />
        </div>
      </div>

      {/* Content Section - sobreposto ao banner */}
      <div className="relative z-10 max-w-7xl mx-auto px-4 py-6 flex flex-col items-center justify-center min-h-[200px]">
        {/* Botão de voltar */}
        {showBackButton && onBack && (
          <button
            onClick={onBack}
            className="absolute top-4 left-4 flex items-center gap-2 text-white bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-700 hover:to-indigo-800 px-3 py-2 rounded-xl transition-all cursor-pointer shadow-md"
            title="Voltar"
          >
            <ArrowLeft className="w-4 h-4" />
            <span className="text-sm font-medium">Voltar</span>
          </button>
        )}

        {/* Badge de status da loja */}
        <div className="absolute top-4 right-4">
          <LojaStatusBadge className="bg-white bg-opacity-95 shadow-sm" />
        </div>

        {/* Logo */}
        <div className="flex items-center justify-center mb-3">
          <div className="w-16 h-16 bg-gradient-to-br from-indigo-500 to-indigo-600 rounded-full flex items-center justify-center overflow-hidden shadow-lg ring-4 ring-white ring-opacity-50">
            {logoUrl ? (
              <img
                src={logoUrl}
                alt={nomeEstabelecimento}
                className="w-full h-full object-cover"
                onError={(e) => {
                  const target = e.target as HTMLImageElement;
                  target.style.display = 'none';
                  target.nextElementSibling?.classList.remove('hidden');
                }}
              />
            ) : (
              <span className="text-white text-2xl font-bold">
                {nomeEstabelecimento.charAt(0).toUpperCase()}
              </span>
            )}
            <span className={`text-white text-2xl font-bold ${logoUrl ? 'hidden' : ''}`}>
              {nomeEstabelecimento.charAt(0).toUpperCase()}
            </span>
          </div>
        </div>

        {/* Nome do estabelecimento */}
        <div className="inline-block bg-white bg-opacity-95 px-6 py-2 rounded-2xl shadow-md mb-3">
          <h1 className="text-2xl font-bold text-indigo-700 text-center">
            {nomeEstabelecimento}
          </h1>
        </div>

        {/* Botão "Mais informações" com fundo branco semi-transparente */}
        <div className="inline-block bg-white bg-opacity-95 px-6 py-3 rounded-2xl shadow-md">
          <button
            onClick={onMaisInformacoes}
            className="flex items-center gap-2 text-indigo-600 hover:text-indigo-700 font-medium transition-colors cursor-pointer text-sm"
          >
            <Info className="h-4 w-4" />
            <span>Mais informações</span>
          </button>
        </div>
      </div>
    </div>
  )
}

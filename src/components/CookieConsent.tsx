import { useState, useEffect } from 'react';
import { X, Cookie, Shield } from 'lucide-react';
import { Button } from '@/components/ui/button';

/**
 * Componente de consentimento de cookies e analytics
 * Botão sempre visível no canto inferior esquerdo
 */
export default function CookieConsent() {
  const [showBanner, setShowBanner] = useState(false);
  const [hasConsent, setHasConsent] = useState<string | null>(null);

  useEffect(() => {
    // Verificar se o usuário já deu consentimento
    const consent = localStorage.getItem('cookie-consent');
    setHasConsent(consent);
  }, []);

  const handleAccept = () => {
    // Salvar consentimento
    localStorage.setItem('cookie-consent', 'accepted');
    localStorage.setItem('cookie-consent-date', new Date().toISOString());
    setHasConsent('accepted');
    
    // Fechar banner
    setShowBanner(false);
  };

  const handleReject = () => {
    // Salvar rejeição
    localStorage.setItem('cookie-consent', 'rejected');
    localStorage.setItem('cookie-consent-date', new Date().toISOString());
    setHasConsent('rejected');
    
    // Desabilitar Google Analytics
    if (window.gtag) {
      window.gtag('consent', 'update', {
        analytics_storage: 'denied'
      });
    }
    
    // Fechar banner
    setShowBanner(false);
  };

  const handleToggle = () => {
    setShowBanner(!showBanner);
  };

  return (
    <>
      {/* Botão Toggle - Sempre visível, mas escondido quando banner está aberto */}
      {!showBanner && (
        <button
          onClick={handleToggle}
          className="fixed bottom-4 left-4 z-50 bg-indigo-600 hover:bg-indigo-700 text-white rounded-full p-3 shadow-lg transition-all duration-300 hover:scale-110 group"
          aria-label="Configurações de Privacidade"
          title="Configurações de Privacidade"
        >
          <div className="relative">
            <Shield className="h-6 w-6" />
            {!hasConsent && (
              <span className="absolute -top-1 -right-1 h-3 w-3 bg-red-500 rounded-full animate-pulse" />
            )}
          </div>
        </button>
      )}

      {/* Banner - Aparece quando clicar no botão */}
      {showBanner && (
        <div className="fixed bottom-4 left-4 right-4 md:right-auto md:max-w-sm z-50 animate-in slide-in-from-bottom-5 duration-300">
          <div className="bg-white rounded-lg shadow-2xl border border-gray-200 overflow-hidden">
            {/* Header */}
            <div className="bg-gradient-to-r from-indigo-600 to-indigo-700 p-3 md:p-4 flex items-center justify-between">
              <div className="flex items-center gap-2 text-white">
                <Cookie className="h-4 w-4 md:h-5 md:w-5" />
                <h3 className="font-semibold text-xs md:text-sm">Cookies e Privacidade</h3>
              </div>
              <button
                onClick={() => setShowBanner(false)}
                className="text-white hover:bg-white/20 rounded p-1 transition-colors"
                aria-label="Fechar"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            {/* Content */}
            <div className="p-3 md:p-4 space-y-2 md:space-y-3 max-h-[70vh] overflow-y-auto">
              {/* Status atual */}
              {hasConsent && (
                <div className={`p-2 md:p-3 rounded-lg border ${
                  hasConsent === 'accepted' 
                    ? 'bg-green-50 border-green-200' 
                    : 'bg-orange-50 border-orange-200'
                }`}>
                  <p className="text-xs font-semibold">
                    {hasConsent === 'accepted' 
                      ? '✓ Cookies aceitos' 
                      : '✗ Cookies recusados'}
                  </p>
                  <p className="text-xs text-gray-600 mt-1">
                    Você pode alterar sua preferência abaixo.
                  </p>
                </div>
              )}

              <p className="text-xs md:text-sm text-gray-700 leading-relaxed">
                Usamos cookies e ferramentas de análise como o{' '}
                <strong>Google Analytics</strong> para melhorar sua experiência e
                entender como você usa nosso site.
              </p>

              <div className="bg-indigo-50 border border-indigo-200 rounded-lg p-2 md:p-3">
                <p className="text-xs text-indigo-900">
                  <strong>O que coletamos:</strong>
                </p>
                <ul className="text-xs text-indigo-800 mt-1 space-y-1 ml-4 list-disc">
                  <li>Páginas visitadas</li>
                  <li>Produtos visualizados</li>
                  <li>Itens adicionados ao carrinho</li>
                  <li>Pedidos finalizados</li>
                </ul>
              </div>

              <p className="text-xs text-gray-600">
                Não coletamos dados pessoais identificáveis. Você pode alterar suas
                preferências a qualquer momento clicando no ícone de privacidade.
              </p>

              {/* Buttons */}
              <div className="flex gap-2 pt-2">
                <Button
                  onClick={handleAccept}
                  className="flex-1 bg-indigo-600 hover:bg-indigo-700 text-white text-xs md:text-sm py-2"
                >
                  {hasConsent === 'accepted' ? 'Manter Aceito' : 'Aceitar'}
                </Button>
                <Button
                  onClick={handleReject}
                  variant="outline"
                  className="flex-1 border-gray-300 text-gray-700 hover:bg-gray-50 text-xs md:text-sm py-2"
                >
                  {hasConsent === 'rejected' ? 'Manter Recusado' : 'Recusar'}
                </Button>
              </div>

              <button
                onClick={() => {
                  // Abrir modal de privacidade (se existir)
                  window.location.href = '/politicas-privacidade';
                }}
                className="text-xs text-indigo-600 hover:text-indigo-700 underline w-full text-center"
              >
                Política de Privacidade
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

// Declaração global para TypeScript
declare global {
  interface Window {
    gtag: (...args: unknown[]) => void;
  }
}

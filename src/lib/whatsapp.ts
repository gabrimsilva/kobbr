// Função para detectar se é mobile
export const isMobile = (): boolean => {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ||
        window.innerWidth <= 768
}

// Função para abrir WhatsApp de forma otimizada para mobile/desktop
export const openWhatsApp = (url: string): void => {
    try {
        if (isMobile()) {
            // No mobile, tenta diferentes abordagens

            // Primeira tentativa: criar um link temporário e clicar nele
            const link = document.createElement('a')
            link.href = url
            link.target = '_blank'
            link.rel = 'noopener noreferrer'

            // Adiciona o link ao DOM temporariamente
            document.body.appendChild(link)
            link.click()
            document.body.removeChild(link)

        } else {
            // No desktop, abre em nova aba
            const newWindow = window.open(url, '_blank', 'noopener,noreferrer')
            if (!newWindow || newWindow.closed || typeof newWindow.closed == 'undefined') {
                // Fallback: criar link e clicar
                const link = document.createElement('a')
                link.href = url
                link.target = '_blank'
                link.rel = 'noopener noreferrer'
                document.body.appendChild(link)
                link.click()
                document.body.removeChild(link)
            }
        }
    } catch (error) {
        console.error('❌ Erro ao abrir WhatsApp:', error)
        // Último fallback: redirecionamento direto
        window.location.href = url
    }
}

// Função para criar URL do WhatsApp
export const createWhatsAppUrl = (phoneNumber: string, message: string): string => {
    const numeroLimpo = phoneNumber.replace(/\D/g, '')

    if (!numeroLimpo || numeroLimpo.length < 10) {
        console.error('❌ Número de telefone inválido:', numeroLimpo)
        throw new Error('Número de WhatsApp inválido')
    }

    const mensagemCodificada = encodeURIComponent(message)
    const url = `https://wa.me/55${numeroLimpo}?text=${mensagemCodificada}`

    return url
}
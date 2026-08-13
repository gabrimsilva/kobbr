import { useEffect } from "react"
import { useConfig } from "@/contexts/ConfigContext"

export default function SEOHead() {
  const { nomeEstabelecimento } = useConfig()

  useEffect(() => {
    // Atualizar título da página com o nome do estabelecimento
    const title = nomeEstabelecimento || 'Sistema de Delivery'
    document.title = title

    // Meta tags básicas
    updateMetaTag('meta[name="description"]', 'name', `Sistema de delivery - ${title}`)
    updateMetaTag('meta[name="robots"]', 'name', 'index, follow')
    
    // Open Graph básico
    updateMetaTag('meta[property="og:type"]', 'property', 'website')
    updateMetaTag('meta[property="og:title"]', 'property', title)
    updateMetaTag('meta[property="og:description"]', 'property', `Sistema de delivery - ${title}`)
    updateMetaTag('meta[property="og:site_name"]', 'property', title)
    
    // Twitter Card básico
    updateMetaTag('meta[name="twitter:card"]', 'name', 'summary_large_image')
    updateMetaTag('meta[name="twitter:title"]', 'name', title)
    updateMetaTag('meta[name="twitter:description"]', 'name', `Sistema de delivery - ${title}`)
  }, [nomeEstabelecimento])

  const updateMetaTag = (selector: string, attribute: string, content: string) => {
    let element = document.querySelector(selector) as HTMLMetaElement
    
    if (!element) {
      element = document.createElement('meta')
      element.setAttribute(attribute, selector.match(/\[.*="(.*)"\]/)?.[1] || '')
      document.head.appendChild(element)
    }
    
    element.setAttribute('content', content)
  }

  return null
}

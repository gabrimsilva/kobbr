import { KEYUTIL, KJUR } from 'jsrsasign'

// Declarar tipo global para qz
declare global {
  interface Window {
    qz: any
  }
}

/**
 * Serviço para gerenciar impressão via QZ Tray
 */
class QZTrayService {
  private connected = false
  private privateKey: string
  private get qz() {
    if (!window.qz) {
      throw new Error('QZ Tray não está carregado. Certifique-se de que o QZ Tray está rodando.')
    }
    return window.qz
  }

  constructor() {
    // Chave privada
    this.privateKey = `-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDoY8R/ss2UH96s
vfA9vaMZ/ZlF8wDp1VZVu50Ps/LwzYuPDPP9Vm/iFs2JZDaXDIOeCMEAvEXzyUxA
A+poT3N5XQuIo9nIKR0P3aJUD+Y6nG6nY8c2nmg48B2Js5a5ZH7DGXlF9OS4YZ8c
kZnCgFms42Rfa0JzwOeO5KT25p+0l745ma6+JlImdtzPJq37lPsJajBrcyhAy+J8
9txtYqJBQZojvRGL+MXuDk0OPq4OXTWK9kboivRw2ObTqMja5Mj1LPtYbOYeD65m
FzqWD+mHWVxakEwAN1w21mYjth245kQGnqcnMzMDJG5m4DuRIWQhWDTGZw46RXf0
7AVGzpzbAgMBAAECggEADN37swLGwJ7BH0YHB5jr70dfSLdRqiDU8aGvneWqgmwt
f+ni/cVFVzqu/h5gqjb+d9SBQNXfEHmcixpyzK+PGiQT1hviAspJk/RpuNQGieFA
FgZl/d+CFgD8vOagmYd3pok1cbFDefTbY/zcPoY8l0a7hIMCWdMCnzyITvlqOov/
V2xgccfGA9sa5cu6Pz1mREL1E3i8kvRvCO4D1EbBGYTHXH6LsT0HQW8h4sMbaicR
7bi3OO2w6lP3hx4cXJcGSCAUnd2xf1n+5xYHkucfSQ7pk7WYJuWQzSDzatKWl9lH
2pAuJymyEJLbKVzVX7K+6qttw6RXFHmr0kGAFSizdQKBgQD0M+E5S7av3YYyCOxi
GmPUE8L7gV86uXRAyyVnGOzlR0t7XDUHx1EHq8RgiytyGsEL+Aw0dIFuJG8P8cNC
RKc/oBSqd6yr/agTLwyvVZ4HsVuSGTUIw8tEDCCOSMWlymSzVP+lxMgbHPRBNBZh
vc+aRwko585Ec2dXLwOJU3ncXwKBgQDznctDJEuKoorllzgn37inkpR3YFEIrSm0
hQJbxx3mU6/ORzlZXpATFQ+UJnH5xAMLfEd5tlaBFWacgvMO9RniFg/5X4TkIbI8
Zhvm2ZBhljrIsdPFAs3MIw1XaopwmyloS2hkfPn7D6CECuEi7P9xaW9KsfepFy08
B/uFxhURBQKBgQCQIeLH53k/GZewBnZGfN74+GT3/ubPCVClQYGk9SA1Pzw85jJi
kfCwf2Abv2h4I3RXdSL2/uC5uoVWutINVeoE8p3f81yV8tP15qos/nKUhcjPVVNp
Be7+Dc5VTHxjmy6ObhepppiY8CD2LyEatWZH3693VkH3Qsn2ukfzELL3LwKBgQC8
giV+1t79b7k630C82gjw4iOwG/+YTyYuYZ3plrI0QB2R6NsfpGSn32wmn3kiY+JX
SNul+soFKKI2Cb46nL5ii9/gf2E9hjV9NyXwA/oNCUqDcdcEY58LjzQLqI1nhSkN
YwxsdaiZ9QWoJyL++5TOFV/g1MVnOl/uS979LMGwYQKBgBXlCa6qV7b5nPN+eeFi
MRuTNpIDnrkKqaOQZKk4yvgBipRIquf2q8Wwvhi8ZZLmaonE9cup+ZMRYW631HQC
Nzq/Cmbv9gSd3GCGzZF8zD2fowAIR7ZhA2p748Vypz0w1Bqe1k91J7adWeqbLUEz
zdmdlZ08qyh72C5SsnHDG7Kr
-----END PRIVATE KEY-----`

    this.setupSecurity()
  }

  /**
   * Converte hexadecimal para base64
   */
  private hexToBase64(hexString: string): string {
    const bytes = []
    for (let i = 0; i < hexString.length; i += 2) {
      bytes.push(parseInt(hexString.substr(i, 2), 16))
    }
    return btoa(String.fromCharCode.apply(null, bytes as any))
  }

  /**
   * Configura certificados de segurança para o QZ Tray
   */
  private setupSecurity() {
    // Certificado público
    const certificate = `-----BEGIN CERTIFICATE-----
MIIECzCCAvOgAwIBAgIGAZnJc0lGMA0GCSqGSIb3DQEBCwUAMIGiMQswCQYDVQQG
EwJVUzELMAkGA1UECAwCTlkxEjAQBgNVBAcMCUNhbmFzdG90YTEbMBkGA1UECgwS
UVogSW5kdXN0cmllcywgTExDMRswGQYDVQQLDBJRWiBJbmR1c3RyaWVzLCBMTEMx
HDAaBgkqhkiG9w0BCQEWDXN1cHBvcnRAcXouaW8xGjAYBgNVBAMMEVFaIFRyYXkg
RGVtbyBDZXJ0MB4XDTI1MTAwODE0NDk1OVoXDTQ1MTAwODE0NDk1OVowgaIxCzAJ
BgNVBAYTAlVTMQswCQYDVQQIDAJOWTESMBAGA1UEBwwJQ2FuYXN0b3RhMRswGQYD
VQQKDBJRWiBJbmR1c3RyaWVzLCBMTEMxGzAZBgNVBAsMElFaIEluZHVzdHJpZXMs
IExMQzEcMBoGCSqGSIb3DQEJARYNc3VwcG9ydEBxei5pbzEaMBgGA1UEAwwRUVog
VHJheSBEZW1vIENlcnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDo
Y8R/ss2UH96svfA9vaMZ/ZlF8wDp1VZVu50Ps/LwzYuPDPP9Vm/iFs2JZDaXDIOe
CMEAvEXzyUxAA+poT3N5XQuIo9nIKR0P3aJUD+Y6nG6nY8c2nmg48B2Js5a5ZH7D
GXlF9OS4YZ8ckZnCgFms42Rfa0JzwOeO5KT25p+0l745ma6+JlImdtzPJq37lPsJ
ajBrcyhAy+J89txtYqJBQZojvRGL+MXuDk0OPq4OXTWK9kboivRw2ObTqMja5Mj1
LPtYbOYeD65mFzqWD+mHWVxakEwAN1w21mYjth245kQGnqcnMzMDJG5m4DuRIWQh
WDTGZw46RXf07AVGzpzbAgMBAAGjRTBDMBIGA1UdEwEB/wQIMAYBAf8CAQEwDgYD
VR0PAQH/BAQDAgEGMB0GA1UdDgQWBBT++OCxHW+Ne/A8MqH8JzwpWiFvXjANBgkq
hkiG9w0BAQsFAAOCAQEAhYp+Z1G1uqaeWjsI3zWM+/MYJdGX/whXDP1DPdHgFoY+
9jENIRaRIbzjNQz7ppY8/nVrcqE1L82Fo0Bm8TIHYDBxBmnDr11WdIePHFnI/AVm
W5IuF/rMRqBLGFpL1ODe9AkILRIBQVQwhtv7NalV3Te3J9QWE0yEuS3Nvvy4S/uF
Bbutm6JAbO7bJgOX4ktIPASdbZhHf3G7gM9PasAGe7axOwjbhEbyuLLOSaKn9vKz
8nyG7JjURMhe8gfc2TJPLewOrUKIvW4f4WzsXLBWQt2qPP7RyyTvOYvI7VZDEXI7
ZatpxfIy242cwHmNUBpXPVf1OzTlMuDLyNJvYf9/1A==
-----END CERTIFICATE-----`

    // Aguardar o QZ Tray estar disponível
    if (typeof window !== 'undefined' && window.qz) {
      try {
        // Configurar certificado usando a API do QZ Tray
        window.qz.security.setCertificatePromise((resolve: any) => {
          resolve(certificate)
        })

        // Configurar algoritmo de assinatura
        window.qz.security.setSignatureAlgorithm('SHA512')

        // Configurar assinatura com a chave privada
        window.qz.security.setSignaturePromise((toSign: string) => {
          return (resolve: any, reject: any) => {
            try {
              // Verificar se jsrsasign está disponível
              if (!KEYUTIL || !KJUR) {
                console.error('❌ jsrsasign não está carregado')
                reject(new Error('jsrsasign não está disponível'))
                return
              }

              // Carregar a chave privada
              const key = KEYUTIL.getKey(this.privateKey)

              // Criar assinatura SHA512
              const sig = new KJUR.crypto.Signature({ alg: 'SHA512withRSA' })
              sig.init(key)
              sig.updateString(toSign)
              const hexSignature = sig.sign()

              // Converter hexadecimal para base64
              const base64Signature = this.hexToBase64(hexSignature)

              resolve(base64Signature)
            } catch (error) {
              console.error('❌ Erro ao assinar:', error)
              reject(error)
            }
          }
        })
      } catch (error) {
        console.error('❌ Erro ao configurar segurança do QZ Tray:', error)
      }
    }
  }

  /**
   * Conecta ao QZ Tray com timeout
   */
  async connect(timeoutMs: number = 3000): Promise<boolean> {
    try {
      // Criar promise com timeout
      const connectPromise = new Promise<boolean>(async (resolve) => {
        try {
          if (!this.qz.websocket.isActive()) {
            await this.qz.websocket.connect()
            this.connected = true
            resolve(true)
          } else {
            this.connected = true
            resolve(true)
          }
        } catch (error) {
          console.error('❌ Erro ao conectar ao QZ Tray:', error)
          this.connected = false
          resolve(false)
        }
      })

      const timeoutPromise = new Promise<boolean>((resolve) => {
        setTimeout(() => {
          this.connected = false
          resolve(false)
        }, timeoutMs)
      })

      // Retorna a primeira promise que resolver
      return await Promise.race([connectPromise, timeoutPromise])
    } catch (error) {
      console.error('❌ Erro ao conectar ao QZ Tray:', error)
      this.connected = false
      return false
    }
  }

  /**
   * Desconecta do QZ Tray
   */
  async disconnect(): Promise<void> {
    try {
      if (this.qz.websocket.isActive()) {
        await this.qz.websocket.disconnect()
        this.connected = false
      }
    } catch (error) {
      console.error('❌ Erro ao desconectar do QZ Tray:', error)
    }
  }

  /**
   * Verifica se está conectado
   */
  isConnected(): boolean {
    try {
      if (!window.qz) {
        return false
      }
      return this.connected && this.qz.websocket.isActive()
    } catch (error) {
      return false
    }
  }

  /**
   * Verifica o status do QZ Tray e retorna informações de diagnóstico
   */
  async diagnosticar(): Promise<{
    qzCarregado: boolean
    versao: string | null
    conectado: boolean
    erro: string | null
  }> {
    const diagnostico = {
      qzCarregado: false,
      versao: null as string | null,
      conectado: false,
      erro: null as string | null
    }

    try {
      // Verificar se QZ está carregado
      if (!window.qz) {
        diagnostico.erro = 'QZ Tray não está carregado no navegador'
        return diagnostico
      }

      diagnostico.qzCarregado = true

      // Tentar obter versão
      try {
        diagnostico.versao = await this.qz.api.getVersion()
      } catch (error) {
        diagnostico.erro = 'Não foi possível obter a versão do QZ Tray'
      }

      // Verificar conexão
      try {
        if (this.qz.websocket.isActive()) {
          diagnostico.conectado = true
        } else {
          const connected = await this.connect(3000)
          diagnostico.conectado = connected
          if (!connected) {
            diagnostico.erro = 'Não foi possível conectar ao QZ Tray'
          }
        }
      } catch (error: any) {
        diagnostico.erro = `Erro ao conectar: ${error.message}`
      }

      return diagnostico
    } catch (error: any) {
      diagnostico.erro = `Erro no diagnóstico: ${error.message}`
      return diagnostico
    }
  }

  /**
   * Lista impressoras disponíveis
   */
  async getPrinters(): Promise<string[]> {
    try {
      // Verificar se QZ Tray está disponível
      if (!window.qz) {
        throw new Error('QZ Tray não está carregado. Certifique-se de que o QZ Tray está instalado e rodando.')
      }

      // Tentar conectar se não estiver conectado
      if (!this.isConnected()) {
        const connected = await this.connect(5000) // Timeout de 5 segundos
        if (!connected) {
          throw new Error('Não foi possível conectar ao QZ Tray. Verifique se o aplicativo está rodando.')
        }
      }

      // Buscar impressoras
      const printers = await this.qz.printers.find()
      
      // Validar resultado
      if (!printers || !Array.isArray(printers)) {
        throw new Error('Resposta inválida do QZ Tray ao buscar impressoras.')
      }

      console.log('🖨️ Impressoras encontradas:', printers)
      return printers
    } catch (error) {
      console.error('❌ Erro ao listar impressoras:', error)
      // Re-lançar o erro para que o componente possa tratá-lo adequadamente
      throw error
    }
  }

  /**
   * Imprime conteúdo HTML em impressora térmica
   */
  async printHTML(printerName: string, htmlContent: string): Promise<boolean> {
    try {
      if (!this.isConnected()) {
        const connected = await this.connect(3000) // Timeout de 3 segundos
        if (!connected) {
          throw new Error('Não foi possível conectar ao QZ Tray')
        }
      }

      const config = this.qz.configs.create(printerName)

      const data = [{
        type: 'html' as const,
        format: 'plain' as const,
        data: htmlContent
      }]

      await this.qz.print(config, data)
      return true
    } catch (error) {
      console.error('❌ Erro ao imprimir:', error)
      return false
    }
  }

  /**
   * Tenta imprimir via QZ Tray, se falhar usa impressão nativa do navegador
   */
  async printHTMLWithFallback(printerName: string, htmlContent: string): Promise<{ success: boolean; method: 'qz' | 'browser' | 'failed' }> {
    try {
      // Tentar QZ Tray primeiro (com timeout curto)
      const qzSuccess = await this.printHTML(printerName, htmlContent)

      if (qzSuccess) {
        return { success: true, method: 'qz' }
      }

      // Se falhou, usar impressão nativa do navegador
      this.printViaBrowser(htmlContent)
      return { success: true, method: 'browser' }

    } catch (error) {
      console.error('❌ Erro ao tentar imprimir via QZ Tray:', error)

      // Fallback para impressão nativa
      this.printViaBrowser(htmlContent)
      return { success: true, method: 'browser' }
    }
  }

  /**
   * Imprime usando o diálogo nativo do navegador
   */
  private printViaBrowser(htmlContent: string): void {
    // Criar iframe oculto para impressão
    const iframe = document.createElement('iframe')
    iframe.style.position = 'absolute'
    iframe.style.width = '0'
    iframe.style.height = '0'
    iframe.style.border = 'none'
    
    document.body.appendChild(iframe)
    
    const iframeDoc = iframe.contentWindow?.document
    if (iframeDoc) {
      iframeDoc.open()
      iframeDoc.write(`
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="UTF-8">
            <style>
              @media print {
                body { margin: 0; padding: 10px; }
                @page { margin: 0; }
              }
            </style>
          </head>
          <body>
            ${htmlContent}
          </body>
        </html>
      `)
      iframeDoc.close()
      
      // Aguardar carregamento e imprimir
      iframe.onload = () => {
        setTimeout(() => {
          iframe.contentWindow?.print()
          
          // Remover iframe após impressão
          setTimeout(() => {
            document.body.removeChild(iframe)
          }, 1000)
        }, 100)
      }
    }
  }

  /**
   * Imprime comandos ESC/POS diretos (para impressoras térmicas)
   */
  async printRaw(printerName: string, commands: string): Promise<boolean> {
    try {
      if (!this.isConnected()) {
        const connected = await this.connect()
        if (!connected) {
          throw new Error('Não foi possível conectar ao QZ Tray')
        }
      }

      const config = this.qz.configs.create(printerName)

      const data = [{
        type: 'raw' as const,
        format: 'command' as const,
        data: commands
      }]

      await this.qz.print(config, data)
      return true
    } catch (error) {
      console.error('❌ Erro ao imprimir:', error)
      return false
    }
  }
}

export const qzTrayService = new QZTrayService()

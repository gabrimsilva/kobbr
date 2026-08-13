import OpenAI from 'openai'

export interface IAConfig {
  apiKey: string
  modelo: string
}

export interface Mensagem {
  role: 'user' | 'assistant' | 'system'
  content: string
  timestamp?: number
}

export interface DadosExtraidos {
  categorias?: Array<{
    nome: string
    descricao: string
    ativa: boolean
    ordem: number
    tem_sabores: boolean
    tem_borda: boolean
    tem_tamanhos: boolean
    tem_adicionais: boolean
  }>
  sabores?: Array<{
    nome: string
    descricao: string
    is_premium: boolean
    valor_premium: number
    tipo: string
    categoria_sabor: 'tradicional' | 'especiais' | 'nobres' | 'doces' | 'doces_especiais' | 'refrigerante'
    tipo_sabor: 'normal' | 'borda'
    ativo: boolean
    categoria_nome?: string // Nome da categoria para associação
  }>
  produtos?: Array<{
    nome: string
    descricao: string
    preco: number
    categoria_nome: string
    sabores_disponiveis: boolean
    quantidade_sabores: number
    ativo: boolean
    permite_adicionais: boolean
    sabores?: string[] // Nomes dos sabores associados
  }>
}

class OpenAIService {
  private client: OpenAI | null = null
  private modelo: string = 'gpt-4o'

  /**
   * Inicializa o cliente OpenAI com a API key
   */
  inicializar(config: IAConfig) {
    this.client = new OpenAI({
      apiKey: config.apiKey,
      dangerouslyAllowBrowser: true // Necessário para uso no browser
    })
    this.modelo = config.modelo
  }

  /**
   * Verifica se o serviço está inicializado
   */
  estaInicializado(): boolean {
    return this.client !== null
  }

  /**
   * Processa uma mensagem de texto simples
   */
  async processarMensagem(mensagens: Mensagem[]): Promise<string> {
    if (!this.client) {
      throw new Error('OpenAI não inicializado. Configure a API Key primeiro.')
    }

    try {
      const response = await this.client.chat.completions.create({
        model: this.modelo,
        messages: mensagens.map(m => ({
          role: m.role,
          content: m.content
        })),
        temperature: 0.7,
        max_tokens: 2000
      })

      return response.choices[0]?.message?.content || ''
    } catch (error: any) {
      console.error('Erro ao processar mensagem:', error)
      throw new Error(error.message || 'Erro ao se comunicar com a IA')
    }
  }

  /**
   * Processa um arquivo (imagem, PDF, etc) e extrai informações
   */
  async processarArquivo(
    arquivo: { name: string; type: string; url: string },
    mensagens: Mensagem[]
  ): Promise<string> {
    if (!this.client) {
      throw new Error('OpenAI não inicializado. Configure a API Key primeiro.')
    }

    try {
      // Para imagens, usar Vision API
      if (arquivo.type.startsWith('image/')) {
        const response = await this.client.chat.completions.create({
          model: this.modelo,
          messages: [
            ...mensagens.map(m => ({
              role: m.role,
              content: m.content
            })),
            {
              role: 'user',
              content: [
                {
                  type: 'text' as const,
                  text: `Analise esta imagem (${arquivo.name}) e extraia informações sobre produtos, categorias e sabores conforme solicitado.`
                },
                {
                  type: 'image_url' as const,
                  image_url: {
                    url: arquivo.url
                  }
                }
              ]
            }
          ],
          temperature: 0.7,
          max_tokens: 2000
        })

        return response.choices[0]?.message?.content || ''
      }

      // Para outros tipos de arquivo (PDF, Excel), informar que precisa ser processado manualmente
      return `Recebi o arquivo "${arquivo.name}" (tipo: ${arquivo.type}).

Para processar arquivos PDF e Excel/CSV, você pode:
1. Copiar e colar o conteúdo do arquivo aqui no chat
2. Descrever manualmente as informações que deseja cadastrar

Como posso ajudar?`
    } catch (error: any) {
      console.error('Erro ao processar arquivo:', error)
      throw new Error(error.message || 'Erro ao processar arquivo com a IA')
    }
  }

  /**
   * Extrai dados estruturados de uma conversa
   */
  async extrairDadosEstruturados(mensagens: Mensagem[]): Promise<DadosExtraidos> {
    if (!this.client) {
      throw new Error('OpenAI não inicializado. Configure a API Key primeiro.')
    }

    try {
      const prompt = `Com base na conversa anterior, extraia e estruture as informações sobre categorias, sabores e produtos.

IMPORTANTE: Retorne APENAS um objeto JSON válido, sem nenhum texto adicional antes ou depois.

Formato esperado (com TODOS os campos obrigatórios):
{
  "categorias": [{
    "nome": "Nome da Categoria",
    "descricao": "Descrição da categoria",
    "ativa": true,
    "ordem": 1,
    "tem_sabores": true,
    "tem_borda": false,
    "tem_tamanhos": false,
    "tem_adicionais": false
  }],
  "sabores": [{
    "nome": "Nome do Sabor",
    "descricao": "Descrição detalhada com ingredientes",
    "is_premium": false,
    "valor_premium": 0,
    "tipo": "pizza",
    "categoria_sabor": "tradicional",
    "tipo_sabor": "normal",
    "ativo": true,
    "categoria_nome": "Nome da Categoria"
  }],
  "produtos": [{
    "nome": "Nome do Produto",
    "descricao": "Descrição do produto",
    "preco": 0,
    "categoria_nome": "Nome da Categoria",
    "sabores_disponiveis": true,
    "quantidade_sabores": 1,
    "ativo": true,
    "permite_adicionais": false,
    "sabores": ["Sabor 1", "Sabor 2"]
  }]
}

Regras importantes:
- Se alguma informação não foi mencionada, use valores padrão sensatos
- Para categorias: ordem começa em 1, ativa sempre true
- Para sabores: is_premium false, valor_premium 0, tipo_sabor "normal", ativo true
- Para produtos: ativo sempre true
- categoria_sabor deve ser: tradicional, especiais, nobres, doces, doces_especiais ou refrigerante
- tipo_sabor deve ser: normal ou borda
- Se não houver produtos, use array vazio []
- Não inclua explicações, comentários ou markdown
- Retorne APENAS o JSON puro
- Certifique-se de que o JSON é válido e pode ser parseado`

      const response = await this.client.chat.completions.create({
        model: this.modelo,
        messages: [
          ...mensagens.map(m => ({
            role: m.role,
            content: m.content
          })),
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.3,
        max_tokens: 3000
      })

      const conteudo = response.choices[0]?.message?.content || '{}'

      // Tentar fazer parse do JSON
      try {
        // Remover markdown code blocks se existirem
        let jsonLimpo = conteudo.trim()

        // Remover ```json ou ``` no início e fim
        jsonLimpo = jsonLimpo.replace(/^```json\s*/i, '')
        jsonLimpo = jsonLimpo.replace(/^```\s*/, '')
        jsonLimpo = jsonLimpo.replace(/\s*```$/, '')
        jsonLimpo = jsonLimpo.trim()

        const dados = JSON.parse(jsonLimpo)

        return dados
      } catch (parseError) {
        console.error('Erro ao fazer parse do JSON:', parseError)
        console.error('Conteúdo recebido:', conteudo)
        throw new Error('A IA não retornou um JSON válido. Tente reformular sua solicitação.')
      }
    } catch (error: any) {
      console.error('Erro ao extrair dados estruturados:', error)
      throw new Error(error.message || 'Erro ao extrair dados estruturados')
    }
  }

  /**
   * Cria o prompt inicial do sistema
   */
  criarPromptSistema(): Mensagem {
    return {
      role: 'system',
      content: `Você é um assistente especializado em ajudar a cadastrar produtos em um sistema de delivery de pizzaria.

ESTRUTURA DO BANCO DE DADOS:

1. CATEGORIAS (tabela: categorias)
   Campos obrigatórios:
   - nome: string (ex: "Pizzas", "Bebidas", "Sobremesas")
   - descricao: string (descrição da categoria)
   - ativa: boolean (sempre true para novos cadastros)
   - ordem: number (ordem de exibição no cardápio, começar em 1 - SEMPRE PERGUNTAR)
   - tem_sabores: boolean (true se a categoria tem sabores, ex: pizzas)
   - tem_borda: boolean (true se permite escolher borda)
   - tem_tamanhos: boolean (true se tem tamanhos diferentes)
   - tem_adicionais: boolean (true se permite adicionais)

2. SABORES (tabela: sabores)
   Campos obrigatórios:
   - nome: string (ex: "Margherita", "Calabresa")
   - descricao: string (ingredientes e características)
   - is_premium: boolean (false para sabores normais, true para premium)
   - valor_premium: number (0 para normais, valor adicional para premium)
   - tipo: string (ex: "pizza", "bebida")
   - categoria_id: UUID (ID da categoria - será preenchido após criar a categoria)
   - categoria_sabor: string (tradicional, especiais, nobres, doces, doces_especiais, refrigerante)
   - tipo_sabor: string ("normal" ou "borda")
   - ativo: boolean (sempre true)

3. PRODUTOS (tabela: produtos)
   Campos obrigatórios:
   - nome: string (ex: "Pizza Margherita")
   - descricao: string (descrição do produto)
   - preco: number (preço base)
   - categoria_id: UUID (ID da categoria)
   - categoria_nome: string (nome da categoria)
   - sabores_disponiveis: boolean (true se permite escolher sabores)
   - quantidade_sabores: number (quantos sabores pode escolher)
   - ativo: boolean (sempre true)
   - permite_adicionais: boolean (true se permite adicionais)

IMPORTANTE:
- SEMPRE pergunte sobre a ORDEM DE EXIBIÇÃO da categoria (número de 1 a N)
- Quando o usuário pedir para criar uma categoria com sabores, você DEVE perguntar:
  1. Nome e descrição da categoria
  2. ORDEM DE EXIBIÇÃO (qual posição no cardápio)
  3. Se tem sabores, bordas, tamanhos e adicionais
  4. Para cada sabor: nome, descrição, se é premium, categoria do sabor (tradicional/especiais/etc)
  5. Se vai criar produtos também ou só a categoria e sabores

EXEMPLO DE CONVERSA:
Usuário: "Crie uma categoria Pizzas com dois sabores: Margherita e Calabresa"

Você deve responder:
"Entendi! Vou criar a categoria Pizzas com os sabores Margherita e Calabresa.

Preciso de algumas informações:

**Categoria Pizzas:**
- Descrição: Pizzas artesanais com massa fresca
- Ordem de exibição: Qual posição no cardápio? (1 para primeira, 2 para segunda, etc)
- Tem sabores? Sim
- Tem bordas? Sim ou Não?
- Tem tamanhos? Sim ou Não?
- Permite adicionais? Sim ou Não?

**Sabor Margherita:**
- Descrição: Molho de tomate, mussarela e manjericão fresco
- É premium? Não
- Categoria do sabor: tradicional

**Sabor Calabresa:**
- Descrição: Calabresa fatiada, cebola e azeitonas
- É premium? Não
- Categoria do sabor: tradicional

Confirme ou corrija essas informações para eu prosseguir."

Seja objetivo e claro. Organize as informações em tópicos e listas para facilitar a leitura.
Sempre confirme TODAS as informações necessárias antes de extrair os dados.
NUNCA esqueça de perguntar sobre a ORDEM DE EXIBIÇÃO da categoria.`,
      timestamp: Date.now()
    }
  }
}

export const openaiService = new OpenAIService()

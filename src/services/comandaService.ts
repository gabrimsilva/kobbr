import { supabase } from '@/lib/supabase'
import { comTenant, tenantId } from './tenant'
import type { ComandaSupabase } from '@/types/supabase'

/**
 * Interface para o serviço de comandas
 * Gerencia operações CRUD e lógica de negócio para comandas
 */
export interface IComandaService {
  buscarAbertaPorNumero(numeroComanda: number): Promise<ComandaSupabase | null>
  buscarAbertas(): Promise<ComandaSupabase[]>
  buscarPorId(id: string): Promise<ComandaSupabase | null>
  criar(comanda: {
    numero_comanda: number
    itens: any[]
    subtotal: number
    total: number
    desconto?: number
    tipo_desconto?: 'valor' | 'percentual'
    criado_por?: string
    observacoes?: string
  }): Promise<ComandaSupabase>
  atualizar(id: string, dados: {
    itens?: any[]
    subtotal?: number
    total?: number
    desconto?: number
    tipo_desconto?: 'valor' | 'percentual'
    observacoes?: string
  }): Promise<ComandaSupabase>
  finalizar(
    id: string, 
    formaPagamento?: string,
    splitPaymentData?: {
      formaPagamentoDividido: boolean
      pagamento1Tipo?: string
      pagamento1Valor?: number
      pagamento2Tipo?: string
      pagamento2Valor?: number
    }
  ): Promise<ComandaSupabase>
  cancelar(id: string): Promise<ComandaSupabase>
  excluir(id: string): Promise<void>
  moverParaHistorico(comanda: ComandaSupabase): Promise<void>
  enriquecerItensComCusto(itens: any[]): Promise<any[]>
  salvarOuAtualizar(comanda: {
    numero_comanda: number
    itens: any[]
    subtotal: number
    total: number
    desconto?: number
    tipo_desconto?: 'valor' | 'percentual'
    observacoes?: string
  }): Promise<ComandaSupabase>
}

/**
 * Implementação do serviço de comandas
 */
const comandaServiceImpl: IComandaService = {
  /**
   * Buscar comanda aberta por número
   * @param numeroComanda - Número da comanda
   * @returns Comanda encontrada ou null
   */
  async buscarAbertaPorNumero(numeroComanda: number): Promise<ComandaSupabase | null> {
    const { data, error } = await supabase
      .from('comandas')
      .select('*')
      .eq('numero_comanda', numeroComanda)
      .eq('status', 'aberta')
      .eq('estabelecimento_id', tenantId())
      .order('criado_em', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (error && error.code !== 'PGRST116') {
      console.error('Erro ao buscar comanda:', error)
      throw new Error(`Erro ao buscar comanda: ${error.message}`)
    }

    return data
  },

  /**
   * Buscar todas as comandas abertas
   * @returns Array de comandas abertas
   */
  async buscarAbertas(): Promise<ComandaSupabase[]> {
    const { data, error } = await supabase
      .from('comandas')
      .select('*')
      .eq('status', 'aberta')
      .eq('estabelecimento_id', tenantId())
      .order('numero_comanda', { ascending: true })

    if (error) {
      console.error('Erro ao buscar comandas abertas:', error)
      throw new Error(`Erro ao buscar comandas abertas: ${error.message}`)
    }

    return data || []
  },

  /**
   * Buscar comanda por ID
   * @param id - ID da comanda
   * @returns Comanda encontrada ou null
   */
  async buscarPorId(id: string): Promise<ComandaSupabase | null> {
    const { data, error } = await supabase
      .from('comandas')
      .select('*')
      .eq('id', id)
      .single()

    if (error && error.code !== 'PGRST116') {
      console.error('Erro ao buscar comanda:', error)
      throw new Error(`Erro ao buscar comanda: ${error.message}`)
    }

    return data
  },

  /**
   * Criar nova comanda
   * @param comanda - Dados da comanda a ser criada
   * @returns Comanda criada
   */
  async criar(comanda: {
    numero_comanda: number
    itens: any[]
    subtotal: number
    total: number
    desconto?: number
    tipo_desconto?: 'valor' | 'percentual'
    criado_por?: string
    observacoes?: string
  }): Promise<ComandaSupabase> {
    const { data: session } = await supabase.auth.getSession()
    const userId = session?.session?.user?.id

    const { data, error } = await supabase
      .from('comandas')
      .insert(comTenant({
        ...comanda,
        desconto: comanda.desconto ?? 0,
        tipo_desconto: comanda.tipo_desconto ?? 'valor',
        criado_por: comanda.criado_por || userId,
        status: 'aberta'
      }))
      .select()
      .single()

    if (error) {
      console.error('Erro ao criar comanda:', error)
      throw new Error(`Erro ao criar comanda: ${error.message}`)
    }

    return data
  },

  /**
   * Atualizar comanda
   * @param id - ID da comanda
   * @param dados - Dados a serem atualizados
   * @returns Comanda atualizada
   */
  async atualizar(id: string, dados: {
    itens?: any[]
    subtotal?: number
    total?: number
    desconto?: number
    tipo_desconto?: 'valor' | 'percentual'
    observacoes?: string
  }): Promise<ComandaSupabase> {
    const { data: session } = await supabase.auth.getSession()
    const userId = session?.session?.user?.id

    // Preparar dados de atualização, garantindo valores padrão para desconto
    const updateData: any = {
      ...dados,
      editado_por: userId
    }

    // Se desconto não foi informado mas outros campos foram, manter desconto existente
    // Se desconto foi explicitamente informado, usar o valor fornecido
    if (dados.desconto !== undefined) {
      updateData.desconto = dados.desconto
      updateData.tipo_desconto = dados.tipo_desconto ?? 'valor'
    }

    const { data, error } = await supabase
      .from('comandas')
      .update(updateData)
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Erro ao atualizar comanda:', error)
      throw new Error(`Erro ao atualizar comanda: ${error.message}`)
    }

    return data
  },

  /**
   * Finalizar comanda
   * @param id - ID da comanda
   * @param formaPagamento - Forma de pagamento utilizada
   * @param splitPaymentData - Dados de pagamento dividido (opcional)
   * @returns Comanda finalizada
   */
  async finalizar(
    id: string, 
    formaPagamento?: string,
    splitPaymentData?: {
      formaPagamentoDividido: boolean
      pagamento1Tipo?: string
      pagamento1Valor?: number
      pagamento2Tipo?: string
      pagamento2Valor?: number
    }
  ): Promise<ComandaSupabase> {
    const { data: session } = await supabase.auth.getSession()
    const userId = session?.session?.user?.id

    const updateData: any = {
      status: 'finalizada',
      forma_pagamento: formaPagamento,
      finalizado_por: userId,
      finalizado_em: new Date().toISOString()
    }

    // Adicionar campos de pagamento dividido se fornecidos
    if (splitPaymentData?.formaPagamentoDividido) {
      updateData.forma_pagamento_dividido = true
      updateData.pagamento_1_tipo = splitPaymentData.pagamento1Tipo
      updateData.pagamento_1_valor = splitPaymentData.pagamento1Valor
      updateData.pagamento_2_tipo = splitPaymentData.pagamento2Tipo
      updateData.pagamento_2_valor = splitPaymentData.pagamento2Valor
    } else {
      updateData.forma_pagamento_dividido = false
    }

    const { data, error } = await supabase
      .from('comandas')
      .update(updateData)
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Erro ao finalizar comanda:', error)
      throw new Error(`Erro ao finalizar comanda: ${error.message}`)
    }

    return data
  },

  /**
   * Cancelar comanda
   * @param id - ID da comanda
   * @returns Comanda cancelada
   */
  async cancelar(id: string): Promise<ComandaSupabase> {
    const { data: session } = await supabase.auth.getSession()
    const userId = session?.session?.user?.id

    const { data, error } = await supabase
      .from('comandas')
      .update({
        status: 'cancelada',
        finalizado_por: userId,
        finalizado_em: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single()

    if (error) {
      console.error('Erro ao cancelar comanda:', error)
      throw new Error(`Erro ao cancelar comanda: ${error.message}`)
    }

    return data
  },

  /**
   * Excluir comanda
   * @param id - ID da comanda
   */
  async excluir(id: string): Promise<void> {
    const { error } = await supabase
      .from('comandas')
      .delete()
      .eq('id', id)

    if (error) {
      console.error('Erro ao excluir comanda:', error)
      throw new Error(`Erro ao excluir comanda: ${error.message}`)
    }
  },

  /**
   * Mover comanda para histórico ao finalizar
   * @param comanda - Comanda a ser movida para o histórico
   */
  async moverParaHistorico(comanda: ComandaSupabase): Promise<void> {
    // Pegar usuário atual
    const { data: session } = await supabase.auth.getSession()
    const userId = session?.session?.user?.id

    // Mapear forma de pagamento para formato padrão
    const mapearFormaPagamento = (formaPagamento: string): 'DEBIT' | 'CREDIT' | 'PIX' | 'CASH' => {
      const mapa: { [key: string]: 'DEBIT' | 'CREDIT' | 'PIX' | 'CASH' } = {
        'dinheiro': 'CASH',
        'cartaoDebito': 'DEBIT',
        'cartaoCredito': 'CREDIT',
        'cartao_debito': 'DEBIT',
        'cartao_credito': 'CREDIT',
        'pix': 'PIX',
        'CASH': 'CASH',
        'DEBIT': 'DEBIT',
        'CREDIT': 'CREDIT',
        'PIX': 'PIX'
      }
      return mapa[formaPagamento] || 'CASH'
    }

    // ✅ Enriquecer items com custo atual dos produtos
    const itensEnriquecidos = await this.enriquecerItensComCusto(comanda.itens || [])

    const historicoData: any = {
      numero_comanda: comanda.numero_comanda,
      itens: itensEnriquecidos,
      subtotal: comanda.subtotal,
      desconto: comanda.desconto || 0,
      tipo_desconto: comanda.tipo_desconto || 'valor',
      total: comanda.total,
      forma_pagamento: mapearFormaPagamento(comanda.forma_pagamento || 'dinheiro'),
      criado_por: comanda.criado_por,
      finalizado_por: userId, // Usar usuário atual
      criado_em: comanda.criado_em,
      finalizado_em: new Date().toISOString(),
      observacoes: comanda.observacoes
    }

    // Incluir campos de pagamento dividido se existirem
    if (comanda.forma_pagamento_dividido) {
      historicoData.forma_pagamento_dividido = comanda.forma_pagamento_dividido
      historicoData.pagamento_1_tipo = mapearFormaPagamento(comanda.pagamento_1_tipo || 'dinheiro')
      historicoData.pagamento_1_valor = comanda.pagamento_1_valor
      historicoData.pagamento_2_tipo = mapearFormaPagamento(comanda.pagamento_2_tipo || 'dinheiro')
      historicoData.pagamento_2_valor = comanda.pagamento_2_valor
    }

    const { error } = await supabase
      .from('historico_comandas')
      .insert(comTenant(historicoData))

    if (error) {
      console.error('Erro ao mover comanda para histórico:', error)
      throw new Error(`Erro ao mover comanda para histórico: ${error.message}`)
    }
  },

  /**
   * Enriquece os items com o custo atual dos produtos
   * Busca o custo na tabela produtos para garantir cálculo correto do lucro
   */
  async enriquecerItensComCusto(itens: any[]): Promise<any[]> {
    if (!itens || itens.length === 0) return []

    try {
      // Extrair IDs únicos dos produtos
      const produtoIds = [...new Set(itens.map(item => item.produto?.id).filter(Boolean))]

      if (produtoIds.length === 0) return itens

      // Buscar custos dos produtos
      const { data: produtos, error } = await supabase
        .from('produtos')
        .select('id, custo')
        .in('id', produtoIds)

      if (error) {
        console.error('⚠️ Erro ao buscar custos dos produtos:', error)
        return itens // Retornar items originais em caso de erro
      }

      // Criar mapa de custos
      const custosMap = new Map<string, number>()
      produtos?.forEach(p => {
        custosMap.set(p.id, p.custo || 0)
      })

      // Enriquecer items com custo
      return itens.map(item => {
        if (!item.produto) return item

        const custo = custosMap.get(item.produto.id) || 0
        return {
          ...item,
          produto: {
            ...item.produto,
            custo
          }
        }
      })
    } catch (error) {
      console.error('⚠️ Erro ao enriquecer items com custo:', error)
      return itens // Retornar items originais em caso de erro
    }
  },

  /**
   * Salvar ou atualizar comanda (verifica se já existe uma aberta com o mesmo número)
   * @param comanda - Dados da comanda
   * @returns Comanda criada ou atualizada
   */
  async salvarOuAtualizar(comanda: {
    numero_comanda: number
    itens: any[]
    subtotal: number
    total: number
    desconto?: number
    tipo_desconto?: 'valor' | 'percentual'
    observacoes?: string
  }): Promise<ComandaSupabase> {
    try {
      // Buscar se já existe uma comanda aberta com esse número
      const comandaExistente = await this.buscarAbertaPorNumero(comanda.numero_comanda)

      if (comandaExistente) {
        // Atualizar comanda existente
        return await this.atualizar(comandaExistente.id, {
          itens: comanda.itens,
          subtotal: comanda.subtotal,
          total: comanda.total,
          desconto: comanda.desconto ?? 0,
          tipo_desconto: comanda.tipo_desconto ?? 'valor',
          observacoes: comanda.observacoes
        })
      } else {
        // Criar nova comanda apenas se não existir
        return await this.criar(comanda)
      }
    } catch (error) {
      console.error('❌ Erro em salvarOuAtualizar:', error)
      throw error
    }
  }
}

// Export nomeado
export { comandaServiceImpl as comandaService }

// Export default
export default comandaServiceImpl

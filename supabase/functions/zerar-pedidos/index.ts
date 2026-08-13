import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      },
      db: {
        schema: 'public'
      }
    })

    console.log('🚀 Iniciando processo de zerar pedidos...')

    // 1. Buscar todos os pedidos ativos
    console.log('📡 Buscando pedidos na tabela pedidos...')
    
    // Primeiro, vamos tentar uma busca simples para ver se conseguimos acessar a tabela
    console.log('🔍 Testando acesso à tabela pedidos...')
    const { data: testAccess, error: testError } = await supabase
      .from('pedidos')
      .select('pedido_id')
      .limit(1)
    
    console.log('🧪 Teste de acesso:', {
      success: !testError,
      error: testError,
      hasData: !!testAccess?.length
    })
    
    // Agora buscar todos os pedidos
    console.log('📋 Buscando pedidos para mover...')
    const { data: pedidos, error: errorBuscar } = await supabase
      .from('pedidos')
      .select('*')
      .order('criado_em', { ascending: true })

    console.log(`📊 Resultado da busca detalhada:`, {
      pedidosEncontrados: pedidos?.length || 0,
      error: errorBuscar?.message || 'Nenhum erro',
      errorCode: errorBuscar?.code || 'N/A',
      primeiroPedido: pedidos?.[0]?.pedido_id || 'Nenhum'
    })

    if (errorBuscar) {
      console.error('❌ Erro ao buscar pedidos:', errorBuscar)
      throw errorBuscar
    }

    if (!pedidos || pedidos.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'Nenhum pedido encontrado para mover.',
          pedidosMovidos: 0
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200
        }
      )
    }

    console.log(`📋 Encontrados ${pedidos.length} pedidos para mover`)

    // 2. Mover cada pedido para o histórico geral
    let pedidosMovidos = 0
    const agora = new Date().toISOString()

    for (const pedido of pedidos) {
      try {
        console.log(`🔄 Processando pedido ${pedido.pedido_id} (código: ${pedido.codigo_pedido})`)
        
        // Atualizar status para "Finalizado" antes de mover
        const { error: errorAtualizar } = await supabase
          .from('pedidos')
          .update({ status: 'Finalizado' })
          .eq('pedido_id', pedido.pedido_id)

        if (errorAtualizar) {
          console.error(`❌ Erro ao atualizar status do pedido ${pedido.pedido_id}:`, errorAtualizar)
        } else {
          console.log(`✅ Status atualizado para Finalizado`)
        }

        // Preparar dados para o histórico geral (com status Finalizado)
        const dadosHistorico = {
          pedido_id: pedido.pedido_id,
          codigo_pedido: pedido.codigo_pedido, // PRESERVAR o código original
          cliente_nome: pedido.cliente_nome,
          cliente_sobrenome: pedido.cliente_sobrenome,
          cliente_telefone: pedido.cliente_telefone,
          cliente_email: pedido.cliente_email,
          cliente_endereco: pedido.cliente_endereco,
          cliente_numero: pedido.cliente_numero,
          cliente_complemento: pedido.cliente_complemento,
          cliente_bairro: pedido.cliente_bairro,
          cliente_cidade: pedido.cliente_cidade,
          cliente_estado: pedido.cliente_estado,
          entrega_domicilio: pedido.entrega_domicilio,
          forma_pagamento: pedido.forma_pagamento,
          precisa_troco: pedido.precisa_troco,
          valor_troco: pedido.valor_troco,
          subtotal: pedido.subtotal,
          taxa_entrega: pedido.taxa_entrega,
          taxa_extra_km: pedido.taxa_extra_km || 0,
          desconto: pedido.desconto || 0,
          tipo_desconto: pedido.tipo_desconto || 'valor',
          total: pedido.total,
          itens: pedido.itens,
          status: 'Finalizado', // Sempre salvar como Finalizado no histórico
          observacoes: pedido.observacoes,
          criado_em: pedido.criado_em,
          movido_em: agora,
          // Multi-estabelecimento: preservar o estabelecimento de origem do pedido
          estabelecimento_id: pedido.estabelecimento_id,
          // Split payment fields
          forma_pagamento_dividido: pedido.forma_pagamento_dividido || false,
          pagamento_1_tipo: pedido.pagamento_1_tipo || null,
          pagamento_1_valor: pedido.pagamento_1_valor || null,
          pagamento_2_tipo: pedido.pagamento_2_tipo || null,
          pagamento_2_valor: pedido.pagamento_2_valor || null
        }

        // Inserir no histórico geral
        console.log(`💾 Inserindo no histórico geral...`)
        const { error: errorInserir } = await supabase
          .from('historico_geral')
          .insert(dadosHistorico)

        if (errorInserir) {
          console.error(`❌ Erro ao inserir pedido ${pedido.pedido_id} no histórico:`, errorInserir)
          console.error(`📋 Dados que tentamos inserir:`, JSON.stringify(dadosHistorico, null, 2))
          continue
        }
        console.log(`✅ Inserido no histórico geral`)

        // Remover da tabela de pedidos ativos
        console.log(`🗑️ Removendo da tabela pedidos...`)
        const { error: errorRemover } = await supabase
          .from('pedidos')
          .delete()
          .eq('pedido_id', pedido.pedido_id)

        if (errorRemover) {
          console.error(`❌ Erro ao remover pedido ${pedido.pedido_id}:`, errorRemover)
          continue
        }
        console.log(`✅ Removido da tabela pedidos`)

        pedidosMovidos++
        console.log(`✅ Pedido ${pedido.codigo_pedido || pedido.pedido_id} movido com sucesso`)

      } catch (error) {
        console.error(`❌ Erro ao processar pedido ${pedido.pedido_id}:`, error)
        continue
      }
    }

    console.log(`🎉 Processo concluído: ${pedidosMovidos}/${pedidos.length} pedidos movidos`)

    return new Response(
      JSON.stringify({
        success: true,
        message: `${pedidosMovidos} pedidos movidos para o histórico com sucesso.`,
        pedidosMovidos,
        totalPedidos: pedidos.length
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('❌ Erro geral na função:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Erro interno do servidor'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})
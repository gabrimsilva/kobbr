import type { PedidoSupabase } from "@/services"

/**
 * Filtra pedidos ativos, excluindo cancelados e finalizados antigos
 * 
 * @param pedidos - Lista de todos os pedidos
 * @param horasLimite - Número de horas para considerar pedidos finalizados (padrão: 24)
 * @returns Lista de pedidos ativos
 */
export function filtrarPedidosAtivos(
  pedidos: PedidoSupabase[],
  horasLimite: number = 24
): PedidoSupabase[] {
  const agora = new Date()
  const limiteData = new Date(agora.getTime() - horasLimite * 60 * 60 * 1000)

  return pedidos.filter(p => {
    // Excluir cancelados sempre
    if (p.status === 'Cancelado') return false

    // Para pedidos finalizados, mostrar apenas os recentes
    if (['Finalizado', 'Entregue', 'Retirado'].includes(p.status)) {
      const criadoEm = new Date(p.criado_em)
      return criadoEm > limiteData
    }

    // Mostrar todos os outros status
    return true
  })
}

/**
 * Filtra pedidos por termo de busca
 * 
 * Busca por:
 * - Nome do cliente (case insensitive)
 * - Telefone (com ou sem formatação)
 * - ID do pedido (com ou sem #)
 * 
 * @param pedidos - Lista de pedidos
 * @param searchTerm - Termo de busca
 * @returns Lista de pedidos filtrados
 */
export function filtrarPedidosPorBusca(
  pedidos: PedidoSupabase[],
  searchTerm: string
): PedidoSupabase[] {
  const termo = searchTerm.toLowerCase().trim()

  if (!termo) return pedidos

  return pedidos.filter(pedido => {
    // Busca por nome
    const nomeMatch = pedido.cliente_nome.toLowerCase().includes(termo)

    // Busca por telefone (remove formatação)
    const telefoneOriginal = pedido.cliente_telefone || ''
    const telefoneNumeros = telefoneOriginal.replace(/\D/g, '')
    const termoNumeros = termo.replace(/\D/g, '')
    const telefoneMatch = telefoneOriginal.toLowerCase().includes(termo) ||
      (termoNumeros && telefoneNumeros.includes(termoNumeros))

    // Busca por ID do pedido
    const pedidoId = pedido.pedido_id || ''
    const codigoPedido = pedido.codigo_pedido || ''
    const termoSemHash = termo.replace('#', '')
    const idMatch = pedidoId.toLowerCase().includes(termo) ||
      pedidoId.toLowerCase().includes(termoSemHash) ||
      codigoPedido.toLowerCase().includes(termo) ||
      codigoPedido.toLowerCase().includes(termoSemHash)

    return nomeMatch || telefoneMatch || idMatch
  })
}

/**
 * Agrupa pedidos por status, mapeando status antigos para novos
 * 
 * @param pedidos - Lista de pedidos
 * @param status - Status desejado
 * @returns Lista de pedidos com o status especificado
 */
export function getPedidosPorStatus(
  pedidos: PedidoSupabase[],
  status: string
): PedidoSupabase[] {
  if (status === 'Liberado') {
    return pedidos.filter(pedido =>
      pedido.status === 'Liberado' ||
      pedido.status === 'Pronto para retirada' ||
      pedido.status === 'Saiu para entrega'
    )
  }

  if (status === 'Finalizado') {
    return pedidos.filter(pedido =>
      pedido.status === 'Finalizado' ||
      pedido.status === 'Entregue' ||
      pedido.status === 'Retirado'
    )
  }

  return pedidos.filter(pedido => pedido.status === status)
}

/**
 * Exports centralizados para hooks customizados
 */

// Hooks de formatação e validação
export { useFormatacao } from './useFormatacao'
export { useValidacao } from './useValidacao'
export { useBuscaCEP } from './useBuscaCEP'

// Hooks de carrinho
export { useCarrinho } from './useCarrinho'
export { useCarrinhoPDV } from './useCarrinhoPDV'

// Hooks de checkout
export { useValidacaoCheckout } from './useValidacaoCheckout'

// Hooks de pedidos
export { useRealtimePedidos } from './useRealtimePedidos'
export { useGerenciarPedidos } from './useGerenciarPedidos'
export { usePedidoExpandido } from './usePedidoExpandido'
export { useAutoArquivarPedidos } from './useAutoArquivarPedidos'

// Hooks de finalização
export { useFinalizarPedido } from './useFinalizarPedido'
export { useFinalizarPedidoPDV } from './useFinalizarPedidoPDV'

// Hooks de filtros e busca
export { useFiltrosProdutos } from './useFiltrosProdutos'

// Hooks de configurações
export { useConfiguracoesLoja } from './useConfiguracoesLoja'
export { useLojaStatus } from './useLojaStatus'

// Hooks de notificação
export { useNotificacao } from './useNotificacao'

// Hooks de UI
export { useImageUpload } from './useImageUpload'
export { useFavicon } from './useFavicon'
export { useIsMobile as useMobile } from './use-mobile'

// Hooks de permissões
export { usePermissoes } from './usePermissoes'
export type { Permissoes, Funcao } from './usePermissoes'

// Hooks de perfil de administrador
export { useProfile } from './useProfile'

// Hooks de cache
export { useCachedProdutos, useCachedCategorias, useCachedCombos, useCachedPDVData } from './useCachedData'

// Hooks de persistência de formulário
export { useFormPersist } from './useFormPersist'

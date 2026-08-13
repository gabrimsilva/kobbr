import { useLojaStatus } from '@/hooks/useLojaStatus'

interface LojaStatusBadgeProps {
  className?: string
}

export default function LojaStatusBadge({ className = '' }: LojaStatusBadgeProps) {
  const { isAberta, loading } = useLojaStatus()

  if (loading) {
    return (
      <div className={`text-xs px-2 py-1 rounded bg-gray-100 text-gray-500 ${className}`}>
        Carregando...
      </div>
    )
  }

  return (
    <div 
      className={`
        text-xs px-2 py-1 rounded font-medium transition-colors
        ${isAberta 
          ? 'bg-green-100 text-green-700 border border-green-200' 
          : 'bg-red-100 text-red-700 border border-red-200'
        }
        ${className}
      `}
    >
      <div className="flex items-center gap-1">
        <div 
          className={`
            w-2 h-2 rounded-full
            ${isAberta ? 'bg-green-500' : 'bg-red-500'}
          `}
        />
        {isAberta ? 'Loja Aberta' : 'Loja Fechada'}
      </div>
    </div>
  )
}
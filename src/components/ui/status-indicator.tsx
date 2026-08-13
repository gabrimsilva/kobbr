import { Wifi, WifiOff, Loader2 } from 'lucide-react'

/**
 * StatusIndicator Component
 * 
 * A reusable status indicator component for displaying connection states.
 * Shows different icons and colors for online, offline, and connecting states.
 * 
 * @example
 * ```tsx
 * <StatusIndicator 
 *   status="online"
 *   label="Conectado"
 *   showIcon={true}
 * />
 * 
 * <StatusIndicator 
 *   status="connecting"
 *   label="Reconectando..."
 * />
 * ```
 */

export type ConnectionStatus = 'online' | 'offline' | 'connecting'

interface StatusIndicatorProps {
  /** Current connection status */
  status: ConnectionStatus
  /** Optional label text to display */
  label?: string
  /** Whether to show the status icon */
  showIcon?: boolean
  /** Optional CSS class name */
  className?: string
  /** Size variant */
  size?: 'sm' | 'md' | 'lg'
}

/**
 * StatusIndicator component for displaying connection status
 */
export const StatusIndicator = ({
  status,
  label,
  showIcon = true,
  className = '',
  size = 'md'
}: StatusIndicatorProps) => {
  const getStatusConfig = () => {
    switch (status) {
      case 'online':
        return {
          icon: Wifi,
          color: 'text-green-600',
          bgColor: 'bg-green-100',
          defaultLabel: 'Online'
        }
      case 'offline':
        return {
          icon: WifiOff,
          color: 'text-orange-600',
          bgColor: 'bg-orange-100',
          defaultLabel: 'Offline'
        }
      case 'connecting':
        return {
          icon: Loader2,
          color: 'text-indigo-600',
          bgColor: 'bg-indigo-100',
          defaultLabel: 'Conectando...',
          animate: true
        }
    }
  }

  const config = getStatusConfig()
  const Icon = config.icon
  const displayLabel = label || config.defaultLabel

  const sizeClasses = {
    sm: {
      icon: 'h-3 w-3',
      text: 'text-xs',
      padding: 'px-2 py-1',
      gap: 'gap-1'
    },
    md: {
      icon: 'h-4 w-4',
      text: 'text-sm',
      padding: 'px-3 py-1.5',
      gap: 'gap-1.5'
    },
    lg: {
      icon: 'h-5 w-5',
      text: 'text-base',
      padding: 'px-4 py-2',
      gap: 'gap-2'
    }
  }

  const sizes = sizeClasses[size]

  return (
    <div 
      className={`
        inline-flex items-center rounded-full
        ${sizes.gap} ${sizes.padding}
        ${config.bgColor} ${config.color}
        ${className}
      `}
      role="status"
      aria-label={displayLabel}
    >
      {showIcon && (
        <Icon 
          className={`
            ${sizes.icon}
            ${config.animate ? 'animate-spin' : ''}
          `}
        />
      )}
      {displayLabel && (
        <span className={`font-medium ${sizes.text}`}>
          {displayLabel}
        </span>
      )}
    </div>
  )
}

/**
 * Simple dot indicator variant for compact displays
 */
export const StatusDot = ({
  status,
  size = 'md',
  className = ''
}: {
  status: ConnectionStatus
  size?: 'sm' | 'md' | 'lg'
  className?: string
}) => {
  const getStatusColor = () => {
    switch (status) {
      case 'online':
        return 'bg-green-500'
      case 'offline':
        return 'bg-orange-500'
      case 'connecting':
        return 'bg-indigo-500'
    }
  }

  const sizeClasses = {
    sm: 'h-2 w-2',
    md: 'h-3 w-3',
    lg: 'h-4 w-4'
  }

  return (
    <span
      className={`
        inline-block rounded-full
        ${getStatusColor()}
        ${sizeClasses[size]}
        ${status === 'connecting' ? 'animate-pulse' : ''}
        ${className}
      `}
      role="status"
      aria-label={status}
    />
  )
}

export default StatusIndicator

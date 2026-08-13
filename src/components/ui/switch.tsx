/**
 * Switch Component
 * 
 * A reusable toggle switch component with optional label and description.
 * 
 * @example
 * ```tsx
 * <Switch 
 *   checked={isEnabled} 
 *   onChange={setIsEnabled}
 *   label="Enable notifications"
 *   description="Receive alerts when new orders arrive"
 * />
 * ```
 */

interface SwitchProps {
  /** Optional ID for the switch element */
  id?: string
  /** Whether the switch is in the checked (on) state */
  checked: boolean
  /** Callback function called when the switch state changes */
  onChange: (checked: boolean) => void
  /** Whether the switch is disabled */
  disabled?: boolean
  /** Optional label text displayed next to the switch */
  label?: string
  /** Optional description text displayed below the label */
  description?: string
  /** Optional CSS class name for custom styling */
  className?: string
}

/**
 * Switch component for toggling boolean states
 */
export const Switch = ({ 
  id,
  checked, 
  onChange, 
  disabled = false,
  label,
  description,
  className = ''
}: SwitchProps) => {
  const switchButton = (
    <button
      id={id}
      type="button"
      onClick={() => !disabled && onChange(!checked)}
      disabled={disabled}
      className={`
        relative inline-flex h-6 w-11 items-center rounded-full transition-colors
        ${checked ? 'bg-indigo-600' : 'bg-gray-400'}
        ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
      `}
      role="switch"
      aria-checked={checked}
      aria-label={label || 'Toggle switch'}
    >
      <span
        className={`
          inline-block h-4 w-4 transform rounded-full bg-white transition-transform shadow-sm
          ${checked ? 'translate-x-6' : 'translate-x-1'}
        `}
      />
    </button>
  )

  // If no label or description, return just the switch
  if (!label && !description) {
    return <div className={className}>{switchButton}</div>
  }

  // Return switch with label and description
  return (
    <div className={`flex items-start gap-3 ${className}`}>
      {switchButton}
      <div className="flex-1">
        {label && (
          <label className={`text-sm font-medium ${disabled ? 'text-gray-400' : 'text-gray-700'}`}>
            {label}
          </label>
        )}
        {description && (
          <p className={`text-sm ${disabled ? 'text-gray-300' : 'text-gray-500'}`}>
            {description}
          </p>
        )}
      </div>
    </div>
  )
}

export default Switch

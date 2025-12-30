import { createContext, useContext, useState, useCallback, type ReactNode } from 'react'
import type { ToastData, ToastType } from '../components/Toast'

interface ToastContextValue {
  toasts: ToastData[]
  addToast: (type: ToastType, title: string, message?: string, duration?: number) => void
  removeToast: (id: string) => void
  success: (title: string, message?: string) => void
  error: (title: string, message?: string) => void
  info: (title: string, message?: string) => void
  warning: (title: string, message?: string) => void
}

const ToastContext = createContext<ToastContextValue | null>(null)

interface ToastProviderProps {
  children: ReactNode
}

export function ToastProvider({ children }: ToastProviderProps) {
  const [toasts, setToasts] = useState<ToastData[]>([])

  const addToast = useCallback((
    type: ToastType,
    title: string,
    message?: string,
    duration?: number
  ) => {
    const id = Date.now().toString()
    setToasts(prev => [...prev, { id, type, title, message, duration }])
  }, [])

  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(t => t.id !== id))
  }, [])

  const success = useCallback((title: string, message?: string) => {
    addToast('success', title, message, 5000)
  }, [addToast])

  const error = useCallback((title: string, message?: string) => {
    // Errors have longer duration (8s)
    addToast('error', title, message, 8000)
  }, [addToast])

  const info = useCallback((title: string, message?: string) => {
    addToast('info', title, message, 5000)
  }, [addToast])

  const warning = useCallback((title: string, message?: string) => {
    addToast('warning', title, message, 6000)
  }, [addToast])

  return (
    <ToastContext.Provider value={{
      toasts,
      addToast,
      removeToast,
      success,
      error,
      info,
      warning
    }}>
      {children}
    </ToastContext.Provider>
  )
}

export function useToast() {
  const context = useContext(ToastContext)
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider')
  }
  return context
}

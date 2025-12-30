import Toast, { ToastData } from './Toast'

interface ToastContainerProps {
  toasts: ToastData[]
  onDismiss: (id: string) => void
}

export default function ToastContainer({ toasts, onDismiss }: ToastContainerProps) {
  return (
    <div
      className="fixed bottom-12 right-4 z-50 flex flex-col gap-2 w-full max-w-sm px-4 sm:px-0"
      aria-live="polite"
      aria-atomic="false"
    >
      {toasts.map(toast => (
        <Toast key={toast.id} toast={toast} onDismiss={onDismiss} />
      ))}
    </div>
  )
}

import { createContext, useContext, useState, useCallback, useMemo, type ReactNode } from 'react'
import { useNetworkStatus } from '../hooks/useNetworkStatus'

type DataSaverMode = 'auto' | 'on' | 'off'

interface DataSaverState {
  mode: DataSaverMode
  isActive: boolean  // Computed: true when data saving should be active
  connectionType: string
  setMode: (mode: DataSaverMode) => void
}

const DataSaverContext = createContext<DataSaverState | null>(null)

const STORAGE_KEY = 'vidkeep-data-saver-mode'

interface DataSaverProviderProps {
  children: ReactNode
}

export function DataSaverProvider({ children }: DataSaverProviderProps) {
  const { isMetered, connectionType } = useNetworkStatus()

  // Load saved mode from localStorage
  const [mode, setModeState] = useState<DataSaverMode>(() => {
    if (typeof window === 'undefined') return 'auto'
    const saved = localStorage.getItem(STORAGE_KEY)
    if (saved === 'on' || saved === 'off' || saved === 'auto') {
      return saved
    }
    return 'auto'
  })

  // Persist mode changes to localStorage
  const setMode = useCallback((newMode: DataSaverMode) => {
    setModeState(newMode)
    localStorage.setItem(STORAGE_KEY, newMode)
  }, [])

  // Compute if data saver is currently active
  const isActive = useMemo(() => {
    let active: boolean
    if (mode === 'on') active = true
    else if (mode === 'off') active = false
    else active = isMetered // Auto mode: active when network is metered

    console.log('[DataSaver] Mode applied:', {
      mode,
      isMetered,
      isActive: active,
      connectionType,
      result: active ? 'SLOW POLLING (60s)' : 'FAST POLLING (10s)'
    })

    return active
  }, [mode, isMetered, connectionType])

  const value = useMemo(() => ({
    mode,
    isActive,
    connectionType,
    setMode
  }), [mode, isActive, connectionType, setMode])

  return (
    <DataSaverContext.Provider value={value}>
      {children}
    </DataSaverContext.Provider>
  )
}

export function useDataSaver(): DataSaverState {
  const context = useContext(DataSaverContext)
  if (!context) {
    throw new Error('useDataSaver must be used within a DataSaverProvider')
  }
  return context
}

import { useState, useEffect } from 'react'

interface NetworkStatus {
  isMetered: boolean
  connectionType: string
  saveData: boolean
}

// Extend Navigator type for Network Information API
interface NetworkInformation extends EventTarget {
  type?: 'bluetooth' | 'cellular' | 'ethernet' | 'none' | 'wifi' | 'wimax' | 'other' | 'unknown'
  effectiveType?: 'slow-2g' | '2g' | '3g' | '4g'
  saveData?: boolean
  addEventListener(type: 'change', listener: () => void): void
  removeEventListener(type: 'change', listener: () => void): void
}

interface NavigatorWithConnection extends Navigator {
  connection?: NetworkInformation
  mozConnection?: NetworkInformation
  webkitConnection?: NetworkInformation
}

/**
 * Hook to detect network connection type and metered status.
 * Uses the Network Information API where available.
 * Falls back to assuming non-metered if API not supported.
 */
export function useNetworkStatus(): NetworkStatus {
  const [status, setStatus] = useState<NetworkStatus>({
    isMetered: false,
    connectionType: 'unknown',
    saveData: false
  })

  useEffect(() => {
    const nav = navigator as NavigatorWithConnection
    const connection = nav.connection || nav.mozConnection || nav.webkitConnection

    if (!connection) {
      // Network Information API not supported
      // Default to non-metered
      return
    }

    const updateStatus = () => {
      const type = connection.type || connection.effectiveType || 'unknown'
      const saveData = connection.saveData || false
      const isMetered = saveData || type === 'cellular'

      console.log('[DataSaver] Network API detected:', {
        type,
        effectiveType: connection.effectiveType,
        saveData,
        isMetered,
        raw: {
          'connection.type': connection.type,
          'connection.effectiveType': connection.effectiveType,
          'connection.saveData': connection.saveData
        }
      })

      setStatus({
        isMetered,
        connectionType: type,
        saveData
      })
    }

    // Set initial status
    updateStatus()

    // Listen for changes
    connection.addEventListener('change', updateStatus)

    return () => {
      connection.removeEventListener('change', updateStatus)
    }
  }, [])

  return status
}

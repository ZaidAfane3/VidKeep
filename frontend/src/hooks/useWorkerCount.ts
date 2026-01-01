import { useState, useEffect, useCallback } from 'react'
import { fetchRedisHealth } from '../api/client'
import { useDataSaver } from '../contexts/DataSaverContext'

const POLL_INTERVAL_NORMAL = 30000 // 30 seconds
const POLL_INTERVAL_DATA_SAVER = 60000 // 60 seconds

export function useWorkerCount() {
    const [workerCount, setWorkerCount] = useState<number>(0)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)
    const { isActive: isDataSaver } = useDataSaver()

    const fetchWorkers = useCallback(async () => {
        try {
            const data = await fetchRedisHealth()
            setWorkerCount(data.workers.active)
            setError(null)
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to fetch worker count')
        } finally {
            setLoading(false)
        }
    }, [])

    useEffect(() => {
        // Initial fetch
        fetchWorkers()

        // Poll for updates
        const interval = isDataSaver ? POLL_INTERVAL_DATA_SAVER : POLL_INTERVAL_NORMAL
        const pollId = setInterval(fetchWorkers, interval)

        return () => clearInterval(pollId)
    }, [fetchWorkers, isDataSaver])

    return { workerCount, loading, error }
}

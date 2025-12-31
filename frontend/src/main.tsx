import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

// Disable StrictMode in production to avoid double-mounts
// StrictMode intentionally double-invokes components in dev to help find bugs
const isDev = import.meta.env.DEV

ReactDOM.createRoot(document.getElementById('root')!).render(
  isDev ? (
    <React.StrictMode>
      <App />
    </React.StrictMode>
  ) : (
    <App />
  ),
)

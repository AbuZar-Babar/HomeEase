import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

// Mandatory Tier-1 Google Maps Platform quota & auth failure defense
(window as unknown as { gm_authFailure?: () => void }).gm_authFailure = () => {
  window.dispatchEvent(new CustomEvent('gmp-quota-exceeded'));
};

const originalConsoleError = console.error.bind(console);
console.error = (...args: unknown[]) => {
  const combined = args
    .map((item) => (typeof item === 'string' ? item : String(item)))
    .join(' ');
  if (
    combined.includes('OverQuotaMapError') ||
    combined.includes('QuotaExceededError') ||
    combined.includes('OVER_QUERY_LIMIT')
  ) {
    window.dispatchEvent(new CustomEvent('gmp-quota-exceeded'));
  }
  originalConsoleError(...args);
};

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

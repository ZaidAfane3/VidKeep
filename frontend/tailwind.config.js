/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Phosphor Console Terminal Colors (from Design.md Section 2.1)
        'term': {
          'bg': '#050505',        // Term Black - Main page background
          'card': '#0a0a0a',      // Term Card - Component backgrounds
          'primary': '#00ff41',   // Phosphor Green - Primary text, borders, active states
          'dim': '#004611',       // Dim Green - Inactive borders, separators
          'dark': '#001a05',      // Dark Green - Highlighted section backgrounds
          'error': '#cc0000',     // Retro Red - Errors, delete actions
          'warning': '#d69e00',   // Amber - Warnings, pending states
        }
      },
      fontFamily: {
        // VT323 for retro terminal feel (from Design.md Section 2.2)
        'terminal': ['VT323', 'monospace'],
      },
      fontSize: {
        // Typography scale (from Design.md Section 2.2)
        'display': ['3rem', { lineHeight: '1.0' }],     // 48px - Display/H1
        'heading': ['1.5rem', { lineHeight: '1.2' }],   // 24px - H2
        'h3': ['1.125rem', { lineHeight: '1.3' }],      // 18px - H3/Video Titles
        'body': ['1.125rem', { lineHeight: '1.5' }],    // 18px - Body text
        'mono': ['0.875rem', { lineHeight: '1.4' }],    // 14px - Metadata
      },
      spacing: {
        // Strict 4px grid (from Design.md Section 2.3)
        'xs': '4px',
        'sm': '8px',
        'md': '16px',
        'lg': '24px',
        'xl': '32px',
        '2xl': '48px',
      },
      borderRadius: {
        // CRITICAL: 0px globally for hard edges (from Design.md)
        'none': '0px',
        DEFAULT: '0px',
      },
      animation: {
        // Blinking cursor for logo (from Design.md Section 5.1)
        'blink': 'blink 1s step-end infinite',
        'pulse-slow': 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
      keyframes: {
        blink: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0' },
        }
      },
      boxShadow: {
        // Phosphor glow effects (from Design.md Section 4.3)
        'term-glow': '0 0 8px rgba(0, 255, 65, 0.4)',
        'term-glow-lg': '0 0 30px rgba(0, 255, 65, 0.2)',
      },
      letterSpacing: {
        'widest': '0.2em',
        'wider': '0.1em',
        'wide': '0.05em',
      }
    },
  },
  plugins: [],
}

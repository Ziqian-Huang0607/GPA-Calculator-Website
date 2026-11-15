import { createApp } from 'vue'
import './style.css'
import App from './App.vue'

const THEME_KEY = 'idx-gpa-theme'
const darkMediaQuery = window.matchMedia('(prefers-color-scheme: dark)')

function getStoredTheme(): 'dark' | 'light' | null {
  try {
    const v = localStorage.getItem(THEME_KEY)
    return v === 'dark' || v === 'light' ? v : null
  } catch {
    return null
  }
}

function applyTheme(theme: 'dark' | 'light') {
  document.documentElement.classList.toggle('dark', theme === 'dark')
}

function syncUniversalTheme(e: MediaQueryList | MediaQueryListEvent) {
  if (getStoredTheme()) return
  applyTheme(e.matches ? 'dark' : 'light')
}

applyTheme(getStoredTheme() ?? (darkMediaQuery.matches ? 'dark' : 'light'))
darkMediaQuery.addEventListener('change', syncUniversalTheme)

window.addEventListener('idx-theme-changed', (e: Event) => {
  const theme = (e as CustomEvent).detail as 'dark' | 'light'
  applyTheme(theme)
  try {
    localStorage.setItem(THEME_KEY, theme)
  } catch {
    // Ignore storage errors.
  }
})

createApp(App).mount('#app')

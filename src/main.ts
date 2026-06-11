import { createApp } from 'vue'
import './style.css'
import App from './App.vue'

// Universal system dark mode observer
const darkMediaQuery = window.matchMedia('(prefers-color-scheme: dark)')

function syncUniversalTheme(e: MediaQueryList | MediaQueryListEvent) {
  if (e.matches) {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }
}

// Initial sync
syncUniversalTheme(darkMediaQuery)

// Listen for system dark/light theme toggle events
darkMediaQuery.addEventListener('change', syncUniversalTheme)

createApp(App).mount('#app')
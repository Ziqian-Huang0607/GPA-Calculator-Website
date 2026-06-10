import { createApp } from 'vue'
import './style.css'
import App from './App.vue'

// ── Dark mode: detect system preference, watch for changes ──
function applyDarkMode() {
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
  document.documentElement.classList.toggle('dark', prefersDark)
}

applyDarkMode()
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', applyDarkMode)

createApp(App).mount('#app')

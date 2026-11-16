import { ref, watch } from 'vue'

const GRADIENT_KEY = 'idx-gpa-dynamic-gradients'

function isMobile() {
  return !window.matchMedia('(min-width: 768px)').matches
}

function getStoredGradientPreference(): boolean | null {
  try {
    const raw = localStorage.getItem(GRADIENT_KEY)
    if (raw === null) return null
    return raw === 'true'
  } catch {
    return null
  }
}

const stored = getStoredGradientPreference()
const dynamicGradients = ref(stored ?? !isMobile())

function applyGradients(enabled: boolean) {
  document.documentElement.classList.toggle('dynamic-gradients', enabled)
}

watch(dynamicGradients, (enabled) => {
  applyGradients(enabled)
  try {
    localStorage.setItem(GRADIENT_KEY, String(enabled))
  } catch {
    // Ignore storage errors.
  }
}, { immediate: true })

export function useAppearance() {
  return {
    dynamicGradients,
  }
}

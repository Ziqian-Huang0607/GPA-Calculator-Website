<script setup lang="ts">
import { onMounted, ref, onBeforeUnmount } from 'vue'
import { useBackend } from './useBackend'
import SubjectRow from './components/SubjectRow.vue'
import CustomizeView from './components/CustomizeView.vue'

const backend = useBackend()
const showCustomize = ref(false)

const isWide = ref(false)
let mql: MediaQueryList | null = null
function checkWide() { isWide.value = mql?.matches ?? false }

// Install menu
const showInstallMenu = ref(false)
const deferredPrompt = ref<any>(null)
const installMenuRef = ref<HTMLElement | null>(null)

function handleBeforeInstallPrompt(e: Event) {
  e.preventDefault()
  deferredPrompt.value = e
}

function isIOS() {
  return /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)
}

function handleInstallClick(option: 'app') {
  showInstallMenu.value = false
  if (isIOS()) {
    alert('On iOS: tap the Share button in Safari, then choose "Add to Home Screen".')
    return
  }
  if (deferredPrompt.value) {
    deferredPrompt.value.prompt()
    deferredPrompt.value.userChoice.then(() => { deferredPrompt.value = null })
  }
}

function handleOutsideInstallClick(e: MouseEvent) {
  if (installMenuRef.value && !installMenuRef.value.contains(e.target as Node)) {
    showInstallMenu.value = false
  }
}

onMounted(() => {
  backend.loadInitialData()
  mql = window.matchMedia('(min-width: 768px)')
  checkWide()
  mql.addEventListener('change', checkWide)
  window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt)
  document.addEventListener('mousedown', handleOutsideInstallClick)
})
onBeforeUnmount(() => {
  mql?.removeEventListener('change', checkWide)
  window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt)
  document.removeEventListener('mousedown', handleOutsideInstallClick)
})

// Resizable sidebar
const sidebarWidth = ref(380)
const MIN_SIDEBAR = 280
const MAX_SIDEBAR = 600
let dragging = false
let startX = 0
let startWidth = 0

function onDragStart(e: MouseEvent) {
  dragging = true
  startX = e.clientX
  startWidth = sidebarWidth.value
  document.addEventListener('mousemove', onDragMove)
  document.addEventListener('mouseup', onDragEnd)
  document.body.style.cursor = 'col-resize'
  document.body.style.userSelect = 'none'
}

function onDragMove(e: MouseEvent) {
  if (!dragging) return
  const delta = startX - e.clientX
  sidebarWidth.value = Math.min(MAX_SIDEBAR, Math.max(MIN_SIDEBAR, startWidth + delta))
}

function onDragEnd() {
  dragging = false
  document.removeEventListener('mousemove', onDragMove)
  document.removeEventListener('mouseup', onDragEnd)
  document.body.style.cursor = ''
  document.body.style.userSelect = ''
}
</script>

<template>
  <!-- Loading State -->
  <div
    v-if="backend.isLoading.value"
    class="min-h-screen flex items-center justify-center bg-white dark:bg-gray-900"
  >
    <div class="text-center flex flex-col items-center">
      <!-- Apple Loading Animation -->
      <div class="apple-spinner mb-5" role="progressbar" aria-label="Loading">
        <div></div><div></div><div></div><div></div><div></div><div></div>
        <div></div><div></div><div></div><div></div><div></div><div></div>
      </div>
      <p class="text-[13px] text-gray-500 dark:text-gray-400 font-medium">Loading catalog...</p>
    </div>
  </div>

  <!-- Main Layout -->
  <div v-else class="app-layout">
    <!-- Main Content -->
    <div class="main-content">
      <div class="px-4 pt-8 pb-0 max-w-2xl mx-auto">
        <div class="flex items-center justify-center gap-3">
          <img
            src="/indexademics-logo.png"
            alt="Indexademics"
            class="w-10 h-10 object-contain"
          />
          <div class="text-left">
            <h1 class="text-[28px] font-semibold leading-tight text-black dark:text-white">Indexademics GPA Calculator</h1>
            <p class="text-[13px] text-gray-500 dark:text-gray-400">SHSID course planner</p>
          </div>
        </div>
      </div>

      <div class="px-4 pb-8 max-w-2xl mx-auto">
        <!-- Desktop result card -->
        <div v-if="isWide" class="result-card mt-6 mb-4 rounded-2xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-5 shadow-sm">
          <div class="flex items-center justify-between gap-6">
            <div class="flex-1 grid grid-cols-2 gap-6 text-center">
              <div>
                <div class="text-[12px] font-medium uppercase tracking-wider text-gray-500 dark:text-gray-400">SHSID Weighted</div>
                <div
                  class="gpa-value text-[34px] font-semibold leading-tight"
                  :class="backend.isInvalidated.value ? 'text-red-500' : 'text-black dark:text-white'"
                >
                  {{ backend.weightedGPA.value !== null ? backend.weightedGPA.value.toFixed(3) : '—' }}
                </div>
              </div>
              <div>
                <div class="text-[12px] font-medium uppercase tracking-wider text-gray-500 dark:text-gray-400">
                  {{ backend.unweightedRegion.value }} Unweighted
                </div>
                <div
                  class="gpa-value text-[34px] font-semibold leading-tight"
                  :class="backend.isInvalidated.value ? 'text-red-500' : 'text-black dark:text-white'"
                >
                  {{ backend.unweightedGPA.value !== null ? backend.unweightedGPA.value.toFixed(3) : '—' }}
                </div>
              </div>
            </div>
            <button
              class="text-[12px] font-medium px-3 py-1.5 rounded-full transition-colors border-none cursor-pointer shrink-0 bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
              @click="backend.resetAllLevelsAndScores()"
            >
              Reset
            </button>
          </div>
          <div class="text-center mt-2 text-[12px] text-gray-500 dark:text-gray-400">
            {{ backend.gradesEntered.value }}/{{ backend.totalSubjects.value }} grades entered
            <span v-if="backend.gradesEntered.value === 0" class="block mt-1 text-gray-400 dark:text-gray-500">
              Select a grade for each course to calculate your GPA
            </span>
          </div>
        </div>

        <!-- Mobile result card -->
        <div v-else class="result-card mt-5 mb-5 rounded-2xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-4 shadow-sm">
          <div class="text-center mb-3 text-[12px] text-gray-500 dark:text-gray-400">
            {{ backend.gradesEntered.value }}/{{ backend.totalSubjects.value }} grades entered
            <span v-if="backend.gradesEntered.value === 0" class="block mt-1 text-gray-400 dark:text-gray-500">
              Select grades to calculate your GPA
            </span>
          </div>
          <div class="grid grid-cols-2 gap-4 text-center mb-4">
            <div>
              <div class="text-[11px] font-medium uppercase tracking-wider text-gray-500 dark:text-gray-400">SHSID Weighted</div>
              <div
                class="gpa-value text-[28px] font-semibold leading-tight"
                :class="backend.isInvalidated.value ? 'text-red-500' : 'text-black dark:text-white'"
              >
                {{ backend.weightedGPA.value !== null ? backend.weightedGPA.value.toFixed(3) : '—' }}
              </div>
            </div>
            <div>
              <div class="text-[11px] font-medium uppercase tracking-wider text-gray-500 dark:text-gray-400">
                {{ backend.unweightedRegion.value }} Unweighted
              </div>
              <div
                class="gpa-value text-[28px] font-semibold leading-tight"
                :class="backend.isInvalidated.value ? 'text-red-500' : 'text-black dark:text-white'"
              >
                {{ backend.unweightedGPA.value !== null ? backend.unweightedGPA.value.toFixed(3) : '—' }}
              </div>
            </div>
          </div>
          <div class="flex gap-3 max-w-xs mx-auto">
            <button
              class="flex-1 px-3.5 py-2 text-[14px] font-medium rounded-xl border border-gray-300 dark:border-gray-600 text-black dark:text-white bg-white dark:bg-gray-800 cursor-pointer transition-colors hover:bg-gray-50 dark:hover:bg-gray-700 active:bg-gray-100 dark:active:bg-gray-600"
              @click="showCustomize = !showCustomize"
            >
              Customize
            </button>
            <button
              class="flex-1 px-3.5 py-2 text-[14px] font-medium rounded-xl border border-gray-300 dark:border-gray-600 text-black dark:text-white bg-white dark:bg-gray-800 cursor-pointer transition-colors hover:bg-gray-50 dark:hover:bg-gray-700 active:bg-gray-100 dark:active:bg-gray-600"
              @click="backend.resetAllLevelsAndScores()"
            >
              Reset
            </button>
            <div class="flex-1 relative" ref="installMenuRef">
              <button
                class="w-full px-3.5 py-2 text-[14px] font-medium rounded-xl border border-gray-300 dark:border-gray-600 text-black dark:text-white bg-white dark:bg-gray-800 cursor-pointer transition-colors hover:bg-gray-50 dark:hover:bg-gray-700 active:bg-gray-100 dark:active:bg-gray-600"
                @click="showInstallMenu = !showInstallMenu"
              >
                Install
              </button>
              <div
                v-if="showInstallMenu"
                class="absolute top-full left-0 mt-1 min-w-[180px] bg-white/90 dark:bg-gray-800/90 backdrop-blur-xl border border-gray-200 dark:border-gray-700 rounded-xl shadow-lg overflow-hidden z-50"
              >
                <button
                  class="w-full text-left px-4 py-2.5 text-[13px] font-medium text-black dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors border-none bg-transparent cursor-pointer"
                  @click="handleInstallClick('app')"
                >
                  Add to Home Screen
                </button>
              </div>
            </div>
          </div>
        </div>

        <div class="space-y-3">
          <SubjectRow
            v-for="(subj, idx) in backend.activeSubjects.value"
            :key="subj.id || subj.name"
            :subject="subj"
            :index="idx"
          />
        </div>
      </div>
    </div>

    <!-- Resizable divider (desktop only) -->
    <div
      v-if="isWide"
      class="resize-divider"
      @mousedown.prevent="onDragStart"
    />

    <!-- Sidebar (desktop) / Sheet (mobile) -->
    <CustomizeView
      :show="showCustomize"
      :is-wide="isWide"
      :sidebar-width="isWide ? sidebarWidth : undefined"
      @close="showCustomize = false"
    />
  </div>
</template>

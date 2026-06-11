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

function handleInstallClick(option: 'appstore' | 'webpage') {
  showInstallMenu.value = false
  if (option === 'webpage' && deferredPrompt.value) {
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
      <p class="text-[13px] text-gray-500 dark:text-gray-400 font-medium">Downloading catalog...</p>
    </div>
  </div>

  <!-- Main Layout -->
  <div v-else class="app-layout">
    <!-- Main Content -->
    <div class="main-content">
      <div class="px-4 pt-6 pb-0 max-w-2xl mx-auto">
        <h1 class="text-[32px] font-semibold text-center text-black dark:text-white">Indexademics GPA Calculator</h1>
      </div>

      <div class="px-4 pb-8 max-w-2xl mx-auto">
        <!-- Desktop Layout: GPA Result + Reset pill next to it -->
        <div v-if="isWide" class="text-center py-3">
          <div class="flex items-center justify-center gap-2">
            <p
              class="text-[16px] font-normal"
              :class="backend.isInvalidated.value ? 'text-red-500' : 'text-gray-500 dark:text-gray-400'"
            >
              {{ backend.calculationResultText.value }}
            </p>
            <button
              class="text-[12px] font-medium px-2.5 py-1 rounded-full transition-colors border-none cursor-pointer shrink-0 bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400 hover:bg-gray-300 dark:hover:bg-gray-600"
              @click="backend.resetAllLevelsAndScores()"
            >
              Reset
            </button>
          </div>
        </div>

        <!-- Mobile Layout: GPA result on top, Customize & Reset side-by-side below -->
        <div v-else class="text-center pt-2 pb-5">
          <p
            class="text-[19px] font-medium mb-3.5"
            :class="backend.isInvalidated.value ? 'text-red-500' : 'text-gray-500 dark:text-gray-400'"
          >
            {{ backend.calculationResultText.value }}
          </p>
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
                class="absolute top-full left-0 mt-1 min-w-[160px] bg-white/90 dark:bg-gray-800/90 backdrop-blur-xl border border-gray-200 dark:border-gray-700 rounded-xl shadow-lg overflow-hidden z-50"
              >
                <button
                  class="w-full text-left px-4 py-2.5 text-[13px] font-medium text-black dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors border-none bg-transparent cursor-pointer"
                  :class="{ 'opacity-40 pointer-events-none': !deferredPrompt }"
                  @click="handleInstallClick('webpage')"
                >
                  Webpage
                </button>
                <button
                  class="w-full text-left px-4 py-2.5 text-[13px] font-medium text-black dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors border-none bg-transparent cursor-pointer"
                  @click="handleInstallClick('appstore')"
                >
                  App Store
                </button>
              </div>
            </div>
          </div>
        </div>

        <div class="space-y-4">
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

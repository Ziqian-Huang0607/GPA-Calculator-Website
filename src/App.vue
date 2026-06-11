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

onMounted(() => {
  backend.loadInitialData()
  mql = window.matchMedia('(min-width: 768px)')
  checkWide()
  mql.addEventListener('change', checkWide)
})
onBeforeUnmount(() => { mql?.removeEventListener('change', checkWide) })

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
  <!-- Authentic Apple Spoke Loading State -->
  <div
    v-if="backend.isLoading.value"
    class="min-h-screen flex flex-col items-center justify-center bg-white dark:bg-gray-900"
  >
    <div class="text-center flex flex-col items-center">
      <!-- iOS Segmented Activity Spoke Spinner -->
      <svg class="apple-spinner mb-6" viewBox="0 0 100 100" width="36" height="36">
        <g transform="translate(50,50)">
          <g v-for="i in 12" :key="i" class="spoke" :style="{ transform: `rotate(${i * 30}deg)`, opacity: 1 - (i * 0.08) }">
            <line x1="0" y1="-35" x2="0" y2="-20" stroke="currentColor" stroke-width="8" stroke-linecap="round"/>
          </g>
        </g>
      </svg>
      <p class="text-[13px] text-gray-400 dark:text-gray-500 font-medium">Downloading catalog...</p>
    </div>
  </div>

  <!-- Main Layout -->
  <div v-else class="app-layout">
    <!-- Main Content -->
    <div class="main-content">
      <div class="px-4 pt-6 pb-0 max-w-2xl mx-auto">
        <h1 class="text-[32px] font-semibold text-center text-black dark:text-white">GPA Calculator</h1>
      </div>

      <div class="px-4 pb-8 max-w-2xl mx-auto">
        <!-- Desktop Layout: GPA Result + Reset pill next to it (Unbolded Label) -->
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

        <!-- Mobile Layout: GPA result (Unbolded) + Compact sizing buttons side-by-side below -->
        <div v-else class="text-center pt-2 pb-5">
          <p
            class="text-[18px] font-normal mb-3 text-gray-500 dark:text-gray-400"
            :class="backend.isInvalidated.value ? 'text-red-500' : ''"
          >
            {{ backend.calculationResultText.value }}
          </p>
          <div class="flex gap-3 max-w-xs mx-auto">
            <button
              class="flex-1 px-3 py-2 text-[14px] font-medium rounded-lg border border-gray-300 dark:border-gray-600 text-black dark:text-white bg-white dark:bg-gray-800 cursor-pointer transition-colors hover:bg-gray-50 dark:hover:bg-gray-700 active:bg-gray-100 dark:active:bg-gray-600"
              @click="showCustomize = !showCustomize"
            >
              {{ showCustomize ? 'Hide Customize' : 'Customize' }}
            </button>
            <button
              class="flex-1 px-3 py-2 text-[14px] font-medium rounded-lg border border-gray-300 dark:border-gray-600 text-black dark:text-white bg-white dark:bg-gray-800 cursor-pointer transition-colors hover:bg-gray-50 dark:hover:bg-gray-700 active:bg-gray-100 dark:active:bg-gray-600"
              @click="backend.resetAllLevelsAndScores()"
            >
              Reset
            </button>
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
      :sidebar-width="isWide ? sidebarWidth : undefined"
      @close="showCustomize = false"
    />
  </div>
</template>

<style>
.apple-spinner {
  animation: apple-spin 1s steps(12) infinite;
  color: #8e8e93;
}
.dark .apple-spinner {
  color: #ebebed;
}
@keyframes apple-spin {
  to { transform: rotate(360deg); }
}
</style>
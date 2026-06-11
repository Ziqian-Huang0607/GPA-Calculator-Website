<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import type { Module } from '../types'
import { useBackend } from '../useBackend'
import { ChevronRight } from 'lucide-vue-next'

const props = defineProps<{
  module: Module
  modIndex: number
}>()

const backend = useBackend()
const expanded = ref(false)

const isLocked = computed(() => backend.publishedEffectiveLimit(props.modIndex) === 0)
const isRequiredModule = computed(() => backend.modulesRequiringSelection.value.has(props.modIndex))
const statusText = computed(() => backend.moduleStatusText(props.modIndex))
const statusColor = computed(() => backend.moduleStatusColor(props.modIndex))

function toggle() {
  if (isLocked.value) return
  expanded.value = !expanded.value
}

function toggleSubject(sIdx: number) {
  backend.toggleSelection(props.modIndex, sIdx)
}

// Watch locked state to animate-collapse the panel instantly when disabled
watch(isLocked, (lockedVal) => {
  if (lockedVal) {
    expanded.value = false
  }
})
</script>

<template>
  <div
    class="module-selector bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 transition-all duration-300"
    :class="[
      isLocked ? 'opacity-40 pointer-events-none' : '',
      expanded ? 'border-blue-500/50 shadow-md shadow-blue-500/5 dark:border-blue-500/40' : ''
    ]"
  >
    <!-- Header -->
    <button
      class="w-full flex items-center justify-between px-4 py-4 text-left bg-transparent border-none cursor-pointer"
      @click="toggle"
    >
      <div class="flex-1 min-w-0">
        <div
          class="text-[17px] font-bold transition-colors duration-200"
          :class="isRequiredModule ? 'text-red-500' : isLocked ? 'text-gray-400' : 'text-black dark:text-white'"
        >
          {{ module.name || 'Module' }}
        </div>
        <div class="text-[13px]" :class="statusColor">
          {{ statusText }}
        </div>
      </div>
      <ChevronRight
        :size="16"
        class="text-gray-400 flex-shrink-0 ml-2 chevron-rotate"
        :class="{ open: expanded }"
      />
    </button>

    <!-- Accordion Grid height animation wrapper -->
    <div
      class="collapse-wrapper"
      :class="{ collapsed: !expanded }"
    >
      <div class="collapse-inner border-t border-gray-200 dark:border-gray-700">
        <div
          v-for="(subj, sIdx) in module.subjects"
          :key="sIdx"
        >
          <button
            class="w-full flex items-center justify-between px-4 py-3.5 text-left border-none cursor-pointer transition-colors"
            :class="[
              backend.isDisabled(modIndex, sIdx)
                ? 'bg-transparent text-gray-400 opacity-50 pointer-events-none'
                : 'bg-transparent text-black dark:text-white hover:bg-gray-50 dark:hover:bg-gray-700 active:bg-gray-100 dark:active:bg-gray-600',
            ]"
            :disabled="backend.isDisabled(modIndex, sIdx)"
            @click="toggleSubject(sIdx)"
          >
            <span class="text-[15px]">{{ subj.name }}</span>
            <span v-if="backend.isSelected(modIndex, sIdx)" class="text-blue-500">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
              </svg>
            </span>
            <span v-else-if="backend.isDisabled(modIndex, sIdx)" class="text-gray-400">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
              </svg>
            </span>
            <span v-else class="text-gray-400">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/>
              </svg>
            </span>
          </button>
          <div
            v-if="sIdx < (module.subjects.length - 1)"
            class="list-separator"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.module-selector {
  transition: border-color 0.3s ease, box-shadow 0.3s ease, opacity 0.3s ease;
}

/* Accordion collapse transition */
.collapse-wrapper {
  display: grid;
  grid-template-rows: 1fr;
  transition: grid-template-rows 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.collapse-wrapper.collapsed {
  grid-template-rows: 0fr;
}

.collapse-inner {
  overflow: hidden;
}
</style>
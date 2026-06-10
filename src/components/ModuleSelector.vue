<script setup lang="ts">
import { ref, computed } from 'vue'
import type { Module } from '../types'
import { useBackend } from '../logic/useBackend'
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
</script>

<template>
  <div
    class="bg-white dark:bg-ios-dark-surface-2 rounded-xl overflow-hidden"
    :class="isLocked ? 'opacity-50 pointer-events-none' : ''"
  >
    <!-- Header -->
    <button
      class="w-full flex items-center justify-between px-4 py-4 text-left bg-transparent border-none cursor-pointer"
      @click="toggle"
    >
      <div class="flex-1 min-w-0">
        <div
          class="text-[17px] font-bold"
          :class="isRequiredModule ? 'text-red-500' : isLocked ? 'text-gray-400' : 'text-ios-light-label dark:text-ios-dark-label'"
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

    <!-- Expanded list -->
    <div v-if="expanded" class="border-t border-ios-light-separator dark:border-ios-dark-separator">
      <div
        v-for="(subj, sIdx) in module.subjects"
        :key="sIdx"
      >
        <button
          class="w-full flex items-center justify-between px-4 py-3.5 text-left border-none cursor-pointer transition-colors"
          :class="[
            backend.isDisabled(modIndex, sIdx)
              ? 'bg-transparent text-gray-400 opacity-50 pointer-events-none'
              : 'bg-transparent text-ios-light-label dark:text-ios-dark-label hover:bg-ios-light-secondary-grouped dark:hover:bg-ios-dark-secondary-grouped active:bg-ios-light-tertiary-grouped dark:active:bg-ios-dark-tertiary-grouped',
          ]"
          :disabled="backend.isDisabled(modIndex, sIdx)"
          @click="toggleSubject(sIdx)"
        >
          <span class="text-[15px]">{{ subj.name }}</span>
          <span v-if="backend.isSelected(modIndex, sIdx)" class="text-ios-light-tint dark:text-ios-dark-tint">
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
</template>

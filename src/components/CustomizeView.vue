<script setup lang="ts">
import { computed } from 'vue'
import { useBackend } from '../logic/useBackend'
import SegmentedControl from './SegmentedControl.vue'
import ModuleSelector from './ModuleSelector.vue'
import { kSheet, kToolbar, kToolbarPane, kLink, kBlock } from 'konsta/vue'

defineProps<{
  show: boolean
}>()

const emit = defineEmits<{
  close: []
}>()

const backend = useBackend()

const scoreFormatIndex = computed(() =>
  backend.scoreDisplay.value === 'percentage' ? 0 : 1
)

function setScoreFormat(idx: number) {
  backend.scoreDisplay.value = idx === 0 ? 'percentage' : 'letter'
}

const presets = computed(() => backend.root.value?.presets ?? [])
const catalogInfo = computed(() => {
  const r = backend.root.value
  if (!r) return ''
  return `${r.catalogName ?? 'Unspecified catalog'}\nVersion ${r.version ?? '??'}, last updated ${r.lastUpdated ?? 'idk'}\n${r.credit ?? 'Original project by Michel'}`
})
</script>

<template>
  <k-sheet
    :opened="show"
    class="pb-safe"
    @backdropclick="emit('close')"
  >
    <k-toolbar top class="justify-end ios:pt-4">
      <div class="ios:hidden" />
      <k-toolbar-pane>
        <k-link icon-only @click="emit('close')">Close</k-link>
      </k-toolbar-pane>
    </k-toolbar>

    <k-block>
      <!-- Score Format -->
      <div class="bg-ios-light-surface-1 dark:bg-ios-dark-surface-1 rounded-xl p-4 flex items-center gap-3 shadow-sm mb-4">
        <span class="text-[15px] font-semibold text-ios-light-label dark:text-ios-dark-label flex-shrink">
          Score Format
        </span>

        <!-- Track toggle -->
        <button
          v-if="backend.currentPreset.value?.track"
          class="text-[13px] font-medium px-3 py-1.5 rounded-full transition-colors"
          :class="backend.trackActive.value
            ? 'bg-ios-light-tint dark:bg-ios-dark-tint text-white'
            : 'bg-ios-light-secondary-grouped dark:bg-ios-dark-secondary-grouped text-ios-light-label dark:text-ios-dark-label'"
          @click="backend.setTrackActive(!backend.trackActive.value)"
        >
          Use {{ backend.currentPreset.value.track.displayName }}
        </button>

        <div class="flex-1 min-w-0">
          <SegmentedControl
            :items="['Percentage', 'Letter']"
            :model-value="scoreFormatIndex"
            @update:model-value="setScoreFormat"
          />
        </div>
      </div>

      <!-- Requirement warning -->
      <div
        v-if="backend.requirementWarning.value"
        class="text-red-500 text-[15px] px-2 mb-4"
      >
        {{ backend.requirementWarning.value }}
      </div>

      <!-- Preset Grid -->
      <div class="preset-grid mb-4">
        <button
          v-for="p in presets"
          :key="p.id"
          class="p-4 rounded-xl border-2 cursor-pointer transition-all min-h-[80px] flex items-center text-left"
          :class="backend.currentPreset.value?.id === p.id
            ? 'bg-ios-light-tint dark:bg-ios-dark-tint border-ios-light-tint dark:border-ios-dark-tint text-white'
            : 'bg-ios-light-secondary-grouped dark:bg-ios-dark-secondary-grouped border-transparent text-ios-light-label dark:text-ios-dark-label'"
          @click="backend.selectPreset(p.id)"
        >
          <div class="flex items-center gap-3 w-full">
            <div class="flex-1 min-w-0">
              <div
                class="text-[18px] font-semibold"
                :class="backend.currentPreset.value?.id === p.id ? 'text-white' : 'text-ios-light-tint dark:text-ios-dark-tint'"
              >
                {{ p.name }}
              </div>
              <div
                class="text-[13px]"
                :class="backend.currentPreset.value?.id === p.id ? 'text-white/80' : 'text-ios-light-secondary-label dark:text-ios-dark-secondary-label'"
              >
                {{
                  p.subtitle ||
                  `${p.modules.reduce((acc, m) => acc + m.subjects.length, 0)} items`
                }}
              </div>
            </div>
            <div
              class="flex-shrink-0"
              :class="backend.currentPreset.value?.id === p.id ? 'text-white' : 'text-gray-400'"
            >
              <svg
                v-if="backend.currentPreset.value?.id === p.id"
                width="20" height="20" viewBox="0 0 24 24" fill="currentColor"
              >
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
              </svg>
              <svg
                v-else
                width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
              >
                <circle cx="12" cy="12" r="10" />
              </svg>
            </div>
          </div>
        </button>
      </div>

      <!-- Module Selectors -->
      <div class="space-y-4">
        <ModuleSelector
          v-for="mod in backend.choiceModules.value"
          :key="mod.modIndex"
          :module="mod.module"
          :mod-index="mod.modIndex"
        />
      </div>

      <!-- Catalog Info -->
      <div class="text-center text-[12px] font-semibold text-ios-light-secondary-label dark:text-ios-dark-secondary-label whitespace-pre-line px-4 pt-4 mt-4">
        {{ catalogInfo }}
      </div>
    </k-block>
  </k-sheet>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useBackend } from '../logic/useBackend'
import SegmentedControl from './SegmentedControl.vue'
import ModuleSelector from './ModuleSelector.vue'

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
  <!-- Backdrop -->
  <Teleport to="body">
    <Transition name="modal">
      <div
        v-if="show"
        class="fixed inset-0 z-50 flex items-end justify-center"
      >
        <!-- Backdrop -->
        <div
          class="absolute inset-0 bg-black/40"
          @click="emit('close')"
        />

        <!-- Sheet -->
        <div class="relative w-full max-w-2xl bg-white dark:bg-gray-900 rounded-t-2xl max-h-[85vh] overflow-y-auto pb-8 z-10">
          <!-- Handle -->
          <div class="flex justify-center pt-3 pb-2">
            <div class="w-9 h-1 rounded-full bg-gray-300 dark:bg-gray-600" />
          </div>

          <!-- Close button -->
          <div class="flex justify-end px-4 pb-2">
            <button
              class="text-[15px] font-medium text-blue-500 dark:text-blue-400 bg-transparent border-none cursor-pointer"
              @click="emit('close')"
            >
              Close
            </button>
          </div>

          <div class="px-4">
            <!-- Score Format -->
            <div class="bg-gray-100 dark:bg-gray-800 rounded-xl p-4 flex items-center gap-3 mb-4">
              <span class="text-[15px] font-semibold text-black dark:text-white flex-shrink">
                Score Format
              </span>

              <!-- Track toggle -->
              <button
                v-if="backend.currentPreset.value?.track"
                class="text-[13px] font-medium px-3 py-1.5 rounded-full transition-colors border-none cursor-pointer"
                :class="backend.trackActive.value
                  ? 'bg-blue-500 text-white'
                  : 'bg-gray-200 dark:bg-gray-700 text-black dark:text-white'"
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
                  ? 'bg-blue-500 border-blue-500 text-white'
                  : 'bg-gray-100 dark:bg-gray-800 border-transparent text-black dark:text-white'"
                @click="backend.selectPreset(p.id)"
              >
                <div class="flex items-center gap-3 w-full">
                  <div class="flex-1 min-w-0">
                    <div
                      class="text-[18px] font-semibold"
                      :class="backend.currentPreset.value?.id === p.id ? 'text-white' : 'text-blue-500'"
                    >
                      {{ p.name }}
                    </div>
                    <div
                      class="text-[13px]"
                      :class="backend.currentPreset.value?.id === p.id ? 'text-white/80' : 'text-gray-500 dark:text-gray-400'"
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
            <div class="text-center text-[12px] font-semibold text-gray-400 dark:text-gray-500 whitespace-pre-line px-4 pt-4 mt-4">
              {{ catalogInfo }}
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s ease;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
</style>

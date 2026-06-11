<script setup lang="ts">
import { computed } from 'vue'
import { useBackend } from '../useBackend'
import SegmentedControl from './SegmentedControl.vue'
import ModuleSelector from './ModuleSelector.vue'

defineProps<{
  show: boolean
  sidebarWidth?: number
  isWide: boolean
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
</script>

<template>
  <!-- Desktop: Always-visible sidebar -->
  <aside
    v-if="isWide"
    class="sidebar"
    :style="{ width: (sidebarWidth ?? 380) + 'px' }"
  >
    <div class="sidebar-inner">
      <div class="flex items-center justify-between px-4 py-3 border-b border-gray-200 dark:border-gray-700">
        <h2 class="text-[17px] font-semibold text-black dark:text-white">Customize</h2>
      </div>
      <div class="overflow-y-auto flex-1 px-4 py-4 space-y-4 flex flex-col justify-between">
        <div class="space-y-4">
          <!-- Score Format -->
          <div class="bg-gray-100 dark:bg-gray-800 rounded-xl p-4 flex items-center gap-3">
            <span class="text-[15px] font-semibold text-black dark:text-white flex-shrink">
              Score Format
            </span>
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

          <div
            v-if="backend.requirementWarning.value"
            class="text-red-500 text-[15px] px-2"
          >
            {{ backend.requirementWarning.value }}
          </div>

          <div class="preset-grid">
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
                      p.modules.reduce((acc: number, m: any) => acc + m.subjects.length, 0) + ' items'
                    }}
                  </div>
                </div>
                <div
                  class="flex-shrink-0"
                  :class="backend.currentPreset.value?.id === p.id ? 'text-white' : 'text-gray-400'"
                >
                  <svg v-if="backend.currentPreset.value?.id === p.id" width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
                  </svg>
                  <svg v-else width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10" />
                  </svg>
                </div>
              </div>
            </button>
          </div>

          <ModuleSelector
            v-for="mod in backend.choiceModules.value"
            :key="mod.modIndex"
            :module="mod.module"
            :mod-index="mod.modIndex"
          />
        </div>

        <!-- Custom Credits Area (Desktop) -->
        <div class="flex items-start justify-between pt-6 border-t border-gray-100 dark:border-gray-800 text-left text-[11px] text-gray-400 dark:text-gray-500 font-normal leading-normal select-none">
          <div class="space-y-1">
            <div class="font-medium text-gray-500 dark:text-gray-400">
              {{ backend.root.value?.catalogName ?? 'Unspecified catalog' }}
            </div>
            <div class="text-[10px] text-gray-400 dark:text-gray-500 pb-1">
              Version {{ backend.root.value?.version ?? '??' }}, last updated {{ backend.root.value?.lastUpdated ?? 'idk' }}
            </div>
            <div class="pt-1">
              Indexademics team (<a href="https://github.com/ziqian-huang0607" target="_blank" class="text-blue-500 dark:text-blue-400 hover:underline">Ziqian Huang</a>)
            </div>
            <div>
              Data Science club (<a href="https://github.com/willuhd" target="_blank" class="text-blue-500 dark:text-blue-400 hover:underline">Will Chen</a>)
            </div>
            <div>
              Original project by <a href="https://github.com/michelg10" target="_blank" class="text-blue-500 dark:text-blue-400 hover:underline">Michel</a>.
            </div>
            <div>
              This is an unofficial tool unaffiliated with SHSID. All content is derived from the Course Catalog and is for internal reference purposes only. Course availability and policies are subject to change by the school administration.
            </div>
          </div>
          <div class="flex flex-col shrink-0 ml-3 gap-1">
            <img src="../assets/idx-icon.png" alt="IDX" class="w-11 h-11 rounded-lg object-cover" />
            <img src="../assets/ds-icon.png" alt="DS" class="w-11 h-11 rounded-lg object-cover" />
          </div>
        </div>
      </div>
    </div>
  </aside>

  <!-- Mobile: Bottom Sheet -->
  <Teleport v-if="!isWide" to="body">
    <Transition name="sheet">
      <div v-if="show" class="fixed inset-0 z-50 flex items-end justify-center">
        <div class="absolute inset-0 bg-black/40" @click="emit('close')" />
        <div class="relative w-full max-w-2xl bg-white dark:bg-gray-900 rounded-t-2xl max-h-[85vh] overflow-y-auto pb-8 z-10">
          
          <!-- Sticky Mobile Header -->
          <div class="sticky top-0 z-20 flex items-center justify-between px-4 py-4 border-b border-gray-200 dark:border-gray-700 bg-white/90 dark:bg-gray-900/90 backdrop-blur-md mb-4">
            <button
              class="px-4 py-1.5 text-[13px] font-semibold rounded-full bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-700 border-none cursor-pointer transition-colors"
              @click="emit('close')"
            >
              Close
            </button>
            <span class="absolute left-1/2 -translate-x-1/2 text-[17px] font-semibold text-black dark:text-white">
              Customize
            </span>
            <div class="w-[60px]" aria-hidden="true" />
          </div>

          <div class="px-4 space-y-4">
            <div class="bg-gray-100 dark:bg-gray-800 rounded-xl p-4 flex items-center gap-3">
              <span class="text-[15px] font-semibold text-black dark:text-white flex-shrink">Score Format</span>
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

            <div v-if="backend.requirementWarning.value" class="text-red-500 text-[15px] px-2">
              {{ backend.requirementWarning.value }}
            </div>

            <div class="preset-grid">
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
                    <div class="text-[18px] font-semibold" :class="backend.currentPreset.value?.id === p.id ? 'text-white' : 'text-blue-500'">
                      {{ p.name }}
                    </div>
                    <div class="text-[13px]" :class="backend.currentPreset.value?.id === p.id ? 'text-white/80' : 'text-gray-500 dark:text-gray-400'">
                      {{ p.subtitle || p.modules.reduce((acc: number, m: any) => acc + m.subjects.length, 0) + ' items' }}
                    </div>
                  </div>
                  <div class="flex-shrink-0" :class="backend.currentPreset.value?.id === p.id ? 'text-white' : 'text-gray-400'">
                    <svg v-if="backend.currentPreset.value?.id === p.id" width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
                    </svg>
                    <svg v-else width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <circle cx="12" cy="12" r="10" />
                    </svg>
                  </div>
                </div>
              </button>
            </div>

            <ModuleSelector
              v-for="mod in backend.choiceModules.value"
              :key="mod.modIndex"
              :module="mod.module"
              :mod-index="mod.modIndex"
            />

            <!-- Custom Credits Area (Mobile) -->
            <div class="flex items-start justify-between pt-6 border-t border-gray-100 dark:border-gray-800 text-left text-[11px] text-gray-400 dark:text-gray-500 font-normal leading-normal select-none">
              <div class="space-y-1">
                <div class="font-medium text-gray-500 dark:text-gray-400">
                  {{ backend.root.value?.catalogName ?? 'Unspecified catalog' }}
                </div>
                <div class="text-[10px] text-gray-400 dark:text-gray-500 pb-1">
                  Version {{ backend.root.value?.version ?? '??' }}, last updated {{ backend.root.value?.lastUpdated ?? 'idk' }}
                </div>
                <div class="pt-1">
                  Indexademics team (<a href="https://github.com/ziqian-huang0607" target="_blank" class="text-blue-500 dark:text-blue-400 hover:underline">Ziqian Huang</a>)
                </div>
                <div>
                  Data Science club (<a href="https://github.com/willuhd" target="_blank" class="text-blue-500 dark:text-blue-400 hover:underline">Will Chen</a>)
                </div>
                <div>
                  Original project by <a href="https://github.com/michelg10" target="_blank" class="text-blue-500 dark:text-blue-400 hover:underline">Michel</a>.
                </div>
                <div>
                  This is an unofficial tool unaffiliated with SHSID. All content is derived from the Course Catalog and is for internal reference purposes only. Course availability and policies are subject to change by the school administration.
                </div>
              </div>
              <div class="flex flex-col shrink-0 ml-3 gap-1">
                <img src="../assets/idx-icon.png" alt="IDX" class="w-11 h-11 rounded-lg object-cover" />
                <img src="../assets/ds-icon.png" alt="DS" class="w-11 h-11 rounded-lg object-cover" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.sidebar {
  height: 100vh;
  overflow: hidden;
  background: white;
  flex-shrink: 0;
  position: sticky;
  top: 0;
}

.dark .sidebar {
  background: #1c1c1e;
}

.sidebar-inner {
  display: flex;
  flex-direction: column;
  height: 100%;
  overflow: hidden;
}

/* Mobile SwiftUI panel transitions */
.sheet-enter-active,
.sheet-leave-active {
  transition: opacity 0.25s ease;
}
.sheet-enter-active > div:last-child,
.sheet-leave-active > div:last-child {
  transition: transform 0.35s cubic-bezier(0.15, 0.85, 0.35, 1);
}
.sheet-enter-from,
.sheet-leave-to {
  opacity: 0;
}
.sheet-enter-from > div:last-child {
  transform: translateY(100%);
}
.sheet-leave-to > div:last-child {
  transform: translateY(100%);
}
</style>
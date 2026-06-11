<script setup lang="ts">
import { computed, ref, onMounted, onBeforeUnmount } from 'vue'
import { useBackend } from '../useBackend'
import SegmentedControl from './SegmentedControl.vue'
import ModuleSelector from './ModuleSelector.vue'

const props = defineProps<{
  show: boolean
  sidebarWidth?: number
}>()

const emit = defineEmits<{
  close: []
}>()

const backend = useBackend()

const isWide = ref(false)
let mql: MediaQueryList | null = null
function checkWide() { isWide.value = mql?.matches ?? false }

onMounted(() => {
  mql = window.matchMedia('(min-width: 768px)')
  checkWide()
  mql.addEventListener('change', checkWide)
})
onBeforeUnmount(() => { mql?.removeEventListener('change', checkWide) })

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
      <div class="overflow-y-auto flex-1 px-4 py-4 space-y-4">
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

        <!-- Desktop Catalog Credits Footer -->
        <div class="border-t border-gray-200 dark:border-gray-700 pt-6 mt-6 flex justify-between items-start text-left gap-4">
          <div class="text-[12px] font-normal text-gray-400 dark:text-gray-500 leading-relaxed flex-1">
            <div>
              Indexademics team (<a href="https://github.com/willuhd" target="_blank" class="text-blue-500 hover:underline">Will Chen</a>, <a href="https://github.com/ziqian-huang0607" target="_blank" class="text-blue-500 hover:underline">Ziqian Huang</a>)
            </div>
            <div class="mt-1">
              Original project by <a href="https://github.com/michelg10" target="_blank" class="text-blue-500 hover:underline">Michel</a>. For reference only.
            </div>
            <div class="mt-1">
              <a href="https://apps.apple.com/us/app/gpa-calculator-by-michel/id1540111715" target="_blank" class="text-blue-500 hover:underline">Download on the App Store</a>
            </div>
          </div>
          <img src="/src/assets/idx-icon.png" class="w-10 h-10 object-contain rounded-lg flex-shrink-0 bg-transparent" />
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
          
          <!-- Pinned Top Header Container (Menu Header & Score Formats are static) -->
          <div class="sticky top-0 bg-white dark:bg-gray-900 z-20 pb-3 border-b border-gray-150 dark:border-gray-800 shadow-sm">
            <!-- Pinned Header -->
            <div class="relative flex items-center justify-between px-4 py-4">
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

            <!-- Pinned Score Format Block -->
            <div class="px-4">
              <div class="bg-gray-100 dark:bg-gray-800 rounded-xl p-3 flex items-center gap-3">
                <span class="text-[14px] font-semibold text-black dark:text-white flex-shrink">Score Format</span>
                <button
                  v-if="backend.currentPreset.value?.track"
                  class="text-[12px] font-medium px-2.5 py-1 rounded-full transition-colors border-none cursor-pointer"
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
            </div>
          </div>

          <!-- Scrollable body content -->
          <div class="px-4 space-y-4 pt-4">
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

            <!-- Mobile Catalog Credits Footer (Left Aligned + IDX Right Icon) -->
            <div class="border-t border-gray-200 dark:border-gray-700 pt-6 flex justify-between items-start text-left gap-4">
              <div class="text-[12px] font-normal text-gray-400 dark:text-gray-500 leading-relaxed flex-1">
                <div>
                  Indexademics team (<a href="https://github.com/willuhd" target="_blank" class="text-blue-500 hover:underline">Will Chen</a>, <a href="https://github.com/ziqian-huang0607" target="_blank" class="text-blue-500 hover:underline">Ziqian Huang</a>)
                </div>
                <div class="mt-1">
                  Original project by <a href="https://github.com/michelg10" target="_blank" class="text-blue-500 hover:underline">Michel</a>. For reference only.
                </div>
                <div class="mt-1">
                  <a href="https://apps.apple.com/us/app/gpa-calculator-by-michel/id1540111715" target="_blank" class="text-blue-500 hover:underline">Download on the App Store</a>
                </div>
              </div>
              <img src="/src/assets/idx-icon.png" class="w-10 h-10 object-contain rounded-lg flex-shrink-0 bg-transparent" />
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

/* Kinetic SwiftUI bottom sheet spring-like layout transitions */
.sheet-enter-active,
.sheet-leave-active {
  transition: opacity 0.3s cubic-bezier(0.15, 0.85, 0.35, 1);
}
.sheet-enter-active > div:last-child,
.sheet-leave-active > div:last-child {
  transition: transform 0.32s cubic-bezier(0.15, 0.85, 0.35, 1);
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
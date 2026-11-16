<script setup lang="ts">
import { computed, ref } from 'vue'
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
const isDark = ref(document.documentElement.classList.contains('dark'))
const scheduleMenuOpen = ref(false)

function toggleTheme() {
  isDark.value = !isDark.value
  window.dispatchEvent(new CustomEvent('idx-theme-changed', { detail: isDark.value ? 'dark' : 'light' }))
}

const scoreFormatIndex = computed(() =>
  backend.scoreDisplay.value === 'percentage' ? 0 : 1
)
function setScoreFormat(idx: number) {
  backend.scoreDisplay.value = idx === 0 ? 'percentage' : 'letter'
}

const unweightedRegions = ['UC', 'US', 'Canada', 'England', 'Australia'] as const

const presets = computed(() => backend.root.value?.presets ?? [])
const groupedPresets = computed(() => {
  const groups: Record<string, typeof presets.value> = {}
  for (const p of presets.value) {
    const grade = p.name.replace(/Grade\s*/i, '') || p.name
    if (!groups[grade]) groups[grade] = []
    groups[grade].push(p)
  }
  return Object.entries(groups).sort(([a], [b]) => Number(a) - Number(b))
})

const currentPresetLabel = computed(() => {
  const p = backend.currentPreset.value
  return p ? `${p.name} · ${p.subtitle}` : 'Select schedule'
})

function onPresetChange(event: Event) {
  const target = event.target as HTMLSelectElement
  backend.selectPreset(target.value)
}

function selectMobilePreset(id: string) {
  backend.selectPreset(id)
  scheduleMenuOpen.value = false
}
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
            <div class="flex-1 min-w-0">
              <SegmentedControl
                :items="['Percentage', 'Letter']"
                :model-value="scoreFormatIndex"
                @update:model-value="setScoreFormat"
              />
            </div>
          </div>

          <!-- Unweighted Scale -->
          <div class="bg-gray-100 dark:bg-gray-800 rounded-xl p-4 flex items-center gap-3">
            <span class="text-[15px] font-semibold text-black dark:text-white flex-shrink">
              Unweighted Scale
            </span>
            <div class="flex-1 min-w-0">
              <SegmentedControl
                :items="unweightedRegions"
                :model-value="unweightedRegions.indexOf(backend.unweightedRegion.value)"
                @update:model-value="backend.setUnweightedRegion(unweightedRegions[$event])"
              />
            </div>
          </div>

          <!-- Appearance -->
          <div class="bg-gray-100 dark:bg-gray-800 rounded-xl p-4 flex items-center justify-between gap-3">
            <span class="text-[15px] font-semibold text-black dark:text-white">Appearance</span>
            <button
              class="text-[13px] font-medium px-3 py-1.5 rounded-full transition-colors border-none cursor-pointer bg-gray-200 dark:bg-gray-700 text-black dark:text-white hover:bg-gray-300 dark:hover:bg-gray-600"
              @click="toggleTheme"
            >
              {{ isDark ? 'Light' : 'Dark' }}
            </button>
          </div>

          <div
            v-if="backend.requirementWarning.value"
            class="text-red-500 text-[15px] px-2"
          >
            {{ backend.requirementWarning.value }}
          </div>

          <div>
            <label class="block text-[13px] font-medium text-gray-500 dark:text-gray-400 mb-2">Schedule</label>
            <select
              :value="backend.currentPreset.value?.id"
              class="w-full text-[15px] font-medium rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-black dark:text-white px-4 py-3 cursor-pointer appearance-none"
              @change="onPresetChange"
            >
              <optgroup
                v-for="[grade, group] in groupedPresets"
                :key="grade"
                :label="`Grade ${grade}`"
              >
                <option
                  v-for="p in group"
                  :key="p.id"
                  :value="p.id"
                >
                  {{ p.name }} · {{ p.subtitle }}
                </option>
              </optgroup>
            </select>
          </div>

          <ModuleSelector
            v-for="mod in backend.choiceModules.value"
            :key="mod.modIndex"
            :module="mod.module"
            :mod-index="mod.modIndex"
          />
        </div>

        <!-- Custom Credits Area (Desktop) -->
        <div class="pt-6 border-t border-gray-100 dark:border-gray-800 text-[11px] text-gray-400 dark:text-gray-500 font-normal leading-normal select-none">
          <div class="flex items-start justify-between text-left">
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
                Calculation rules adapted from <a href="https://github.com/okArelene/shsid-gpa-calculator" target="_blank" class="text-blue-500 dark:text-blue-400 hover:underline">okArelene</a>.
              </div>
              <div>
                Original iOS concept by <a href="https://github.com/michelg10" target="_blank" class="text-blue-500 dark:text-blue-400 hover:underline">Michel</a>.
              </div>
              <div>
                <a href="https://github.com/Ziqian-Huang0607/GPA-Calculator-Website" target="_blank" class="text-blue-500 dark:text-blue-400 hover:underline">View source on GitHub</a>
              </div>
            </div>
            <div class="flex flex-col shrink-0 ml-3 gap-1">
              <img src="../assets/idx-icon.png" alt="IDX" class="w-11 h-11 rounded-lg object-cover" />
            </div>
          </div>
          <div class="text-center pt-2">
            This is an unofficial tool unaffiliated with SHSID. All content is derived from the Course Catalog and is for internal reference purposes only. Course availability and policies are subject to change by the school administration.
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
              <div class="flex-1 min-w-0">
                <SegmentedControl
                  :items="['Percentage', 'Letter']"
                  :model-value="scoreFormatIndex"
                  @update:model-value="setScoreFormat"
                />
              </div>
            </div>

            <div class="bg-gray-100 dark:bg-gray-800 rounded-xl p-4 flex items-center gap-3">
              <span class="text-[15px] font-semibold text-black dark:text-white flex-shrink">Unweighted Scale</span>
              <div class="flex-1 min-w-0">
                <SegmentedControl
                  :items="unweightedRegions"
                  :model-value="unweightedRegions.indexOf(backend.unweightedRegion.value)"
                  @update:model-value="backend.setUnweightedRegion(unweightedRegions[$event])"
                />
              </div>
            </div>

            <div class="bg-gray-100 dark:bg-gray-800 rounded-xl p-4 flex items-center justify-between gap-3">
              <span class="text-[15px] font-semibold text-black dark:text-white">Appearance</span>
              <button
                class="text-[13px] font-medium px-3 py-1.5 rounded-full transition-colors border-none cursor-pointer bg-gray-200 dark:bg-gray-700 text-black dark:text-white hover:bg-gray-300 dark:hover:bg-gray-600"
                @click="toggleTheme"
              >
                {{ isDark ? 'Light' : 'Dark' }}
              </button>
            </div>

            <div v-if="backend.requirementWarning.value" class="text-red-500 text-[15px] px-2">
              {{ backend.requirementWarning.value }}
            </div>

            <div>
              <label class="block text-[13px] font-medium text-gray-500 dark:text-gray-400 mb-2">Schedule</label>
              <div>
                <button
                  class="w-full text-left text-[15px] font-medium rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-black dark:text-white px-4 py-3 cursor-pointer"
                  @click="scheduleMenuOpen = !scheduleMenuOpen"
                >
                  <span class="block">{{ currentPresetLabel }}</span>
                </button>
                <div
                  v-if="scheduleMenuOpen"
                  class="mt-2 w-full max-h-72 overflow-y-auto rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 shadow-lg"
                >
                  <div v-for="[grade, group] in groupedPresets" :key="grade">
                    <div class="px-4 py-2 text-[12px] font-semibold text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-900 sticky top-0">
                      Grade {{ grade }}
                    </div>
                    <button
                      v-for="p in group"
                      :key="p.id"
                      class="w-full text-left px-4 py-3 text-[14px] border-none cursor-pointer transition-colors"
                      :class="backend.currentPreset.value?.id === p.id
                        ? 'bg-blue-500 text-white'
                        : 'bg-transparent text-black dark:text-white hover:bg-gray-100 dark:hover:bg-gray-700'"
                      @click="selectMobilePreset(p.id)"
                    >
                      <span class="block font-medium">{{ p.name }}</span>
                      <span
                        class="block text-[12px] mt-0.5"
                        :class="backend.currentPreset.value?.id === p.id ? 'text-white/80' : 'text-gray-500 dark:text-gray-400'"
                      >
                        {{ p.subtitle }}
                      </span>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <ModuleSelector
              v-for="mod in backend.choiceModules.value"
              :key="mod.modIndex"
              :module="mod.module"
              :mod-index="mod.modIndex"
            />

            <!-- Custom Credits Area (Mobile) -->
            <div class="pt-6 border-t border-gray-100 dark:border-gray-800 text-[11px] text-gray-400 dark:text-gray-500 font-normal leading-normal select-none">
              <div class="flex items-start justify-between text-left">
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
                    Calculation rules adapted from <a href="https://github.com/okArelene/shsid-gpa-calculator" target="_blank" class="text-blue-500 dark:text-blue-400 hover:underline">okArelene</a>.
                  </div>
                  <div>
                    Original iOS concept by <a href="https://github.com/michelg10" target="_blank" class="text-blue-500 dark:text-blue-400 hover:underline">Michel</a>.
                  </div>
                  <div>
                    <a href="https://github.com/Ziqian-Huang0607/GPA-Calculator-Website" target="_blank" class="text-blue-500 dark:text-blue-400 hover:underline">View source on GitHub</a>
                  </div>
                </div>
                <div class="flex flex-col shrink-0 ml-3 gap-1">
                  <img src="../assets/idx-icon.png" alt="IDX" class="w-11 h-11 rounded-lg object-cover" />
                </div>
              </div>
              <div class="text-center pt-2">
                This is an unofficial tool unaffiliated with SHSID. All content is derived from the Course Catalog and is for internal reference purposes only. Course availability and policies are subject to change by the school administration.
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
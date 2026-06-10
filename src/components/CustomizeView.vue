<script setup lang="ts">
import { computed } from 'vue'
import { useBackend } from '../logic/useBackend'
import SegmentedControl from './SegmentedControl.vue'
import ModuleSelector from './ModuleSelector.vue'
import { X } from 'lucide-vue-next'

const props = defineProps<{
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
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="show" class="modal-overlay" @click.self="emit('close')">
        <div class="modal-sheet p-6">
          <!-- Navbar -->
          <div class="navbar !bg-transparent !border-none mb-4">
            <div />
            <span class="text-[17px] font-semibold">Customize</span>
            <button @click="emit('close')" class="text-primary">
              Close
            </button>
          </div>

          <div class="space-y-6">
            <!-- Score Format Bar -->
            <div class="bg-card rounded-[var(--radius)] p-4 flex items-center gap-3 shadow-sm">
              <span class="text-[15px] font-semibold text-foreground flex-shrink">
                Score Format
              </span>

              <!-- Track toggle -->
              <button
                v-if="backend.currentPreset.value?.track"
                class="btn-small rounded-[var(--radius-sm)] text-[13px]"
                :class="backend.trackActive.value ? 'btn-filled' : 'btn-gray'"
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
              class="text-destructive text-[15px] px-4"
            >
              {{ backend.requirementWarning.value }}
            </div>

            <!-- Preset Grid -->
            <div class="preset-grid">
              <button
                v-for="p in presets"
                :key="p.id"
                class="preset-card"
                :class="{
                  'preset-selected':
                    backend.currentPreset.value?.id === p.id,
                }"
                @click="backend.selectPreset(p.id)"
              >
                <div class="flex items-center gap-3 w-full">
                  <div class="flex-1 min-w-0">
                    <div
                      class="text-[18px] font-semibold"
                      :class="
                        backend.currentPreset.value?.id === p.id
                          ? 'text-white'
                          : 'text-primary'
                      "
                    >
                      {{ p.name }}
                    </div>
                    <div
                      class="text-[13px] preset-subtitle"
                      :class="
                        backend.currentPreset.value?.id === p.id
                          ? 'text-white/80'
                          : 'text-tertiary-foreground'
                      "
                    >
                      {{
                        p.subtitle ||
                        `${p.modules.reduce(
                          (acc, m) => acc + m.subjects.length,
                          0
                        )} items`
                      }}
                    </div>
                  </div>
                  <div
                    class="flex-shrink-0"
                    :class="
                      backend.currentPreset.value?.id === p.id
                        ? 'text-white'
                        : 'text-gray-400'
                    "
                  >
                    <svg
                      v-if="backend.currentPreset.value?.id === p.id"
                      width="20"
                      height="20"
                      viewBox="0 0 24 24"
                      fill="currentColor"
                    >
                      <path
                        d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"
                      />
                    </svg>
                    <svg
                      v-else
                      width="20"
                      height="20"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                    >
                      <circle cx="12" cy="12" r="10" />
                    </svg>
                  </div>
                </div>
              </button>
            </div>

            <!-- Module Selectors -->
            <div class="space-y-4 px-0">
              <ModuleSelector
                v-for="mod in backend.choiceModules.value"
                :key="mod.modIndex"
                :module="mod.module"
                :mod-index="mod.modIndex"
              />
            </div>

            <!-- Catalog Info -->
            <div
              class="text-center text-[12px] font-semibold text-tertiary-foreground whitespace-pre-line px-4 pt-2"
            >
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
  transition: opacity 0.25s ease;
}
.modal-enter-active .modal-sheet,
.modal-leave-active .modal-sheet {
  transition: transform 0.25s cubic-bezier(0.23, 1, 0.32, 1);
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
.modal-enter-from .modal-sheet,
.modal-leave-to .modal-sheet {
  transform: translateY(20px);
}

@media (min-width: 640px) {
  .modal-enter-from .modal-sheet,
  .modal-leave-to .modal-sheet {
    transform: scale(0.95);
  }
}
</style>

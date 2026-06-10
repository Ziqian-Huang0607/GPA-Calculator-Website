<script setup lang="ts">
import { computed } from 'vue'
import type { Subject } from '../types'
import { useBackend } from '../logic/useBackend'
import SegmentedControl from './SegmentedControl.vue'

const props = defineProps<{
  subject: Subject
  index: number
}>()

const backend = useBackend()

const isRequired = computed(() =>
  backend.requiredSubjectIDs.value.has(props.subject.id || props.subject.name)
)

const levelIndex = computed(() => backend.getLevelIndex(props.subject))
const scoreIndex = computed(() => backend.getScoreIndex(props.subject))
const levelItems = computed(() => props.subject.levels.map((l) => l.name))
const scoreItems = computed(() => {
  const map = backend.scoreMapForSubject(props.subject)
  return map.map((s) =>
    backend.scoreDisplay.value === 'percentage' ? s.percent : s.letter
  )
})

function setLevel(idx: number) {
  backend.setLevelIndex(idx, props.index)
}

function setScore(idx: number) {
  backend.setScoreIndex(idx, props.index)
}
</script>

<template>
  <div class="bg-white dark:bg-ios-dark-surface-2 rounded-xl p-4 shadow-sm">
    <div class="flex items-center gap-3 mb-3">
      <span
        class="text-[17px] font-normal leading-tight flex-shrink min-w-0"
        :class="isRequired ? 'text-red-500' : 'text-ios-light-label dark:text-ios-dark-label'"
      >
        {{ subject.name }}
      </span>
      <div class="flex-1 min-w-0">
        <SegmentedControl
          :items="levelItems"
          :model-value="levelIndex"
          @update:model-value="setLevel"
        />
      </div>
    </div>
    <SegmentedControl
      :items="scoreItems"
      :model-value="scoreIndex"
      @update:model-value="setScore"
    />
  </div>
</template>

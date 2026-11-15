<script setup lang="ts">
import { computed } from 'vue'
import type { Subject } from '../types'
import { useBackend } from '../useBackend'
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
const nameChoice = computed(() => backend.getNameChoice(props.subject))
const levelItems = computed(() => props.subject.levels.map((l) => l.name))
const scoreItems = computed(() => {
  const map = backend.scoreMapForSubject(props.subject)
  return map.map((s) =>
    backend.scoreDisplay.value === 'percentage' ? s.percent : s.letter
  )
})
const nameChoices = computed(() => props.subject.alternateNames ?? [])
const displayName = computed(() => {
  const idx = nameChoice.value
  if (idx >= 0 && nameChoices.value[idx]) return nameChoices.value[idx].compact
  return props.subject.name
})
const currentCredit = computed(() => {
  const idx = levelIndex.value
  return props.subject.levels[idx]?.weightOverride ?? props.subject.weight ?? 0
})

function setLevel(idx: number) {
  backend.setLevelIndex(idx, props.index)
}

function setScore(idx: number) {
  backend.setScoreIndex(idx, props.index)
}

function setNameChoice(idx: number) {
  backend.setNameChoice(idx, props.index)
}
</script>

<template>
  <div class="subject-card bg-white dark:bg-gray-800 rounded-2xl p-4 shadow-sm border border-gray-100 dark:border-gray-800">
    <div class="flex items-center justify-between gap-2 mb-3">
      <span
        class="text-[17px] font-medium leading-tight"
        :class="isRequired ? 'text-red-500' : 'text-black dark:text-white'"
      >
        {{ displayName }}
      </span>
      <span class="text-[11px] font-medium text-gray-400 dark:text-gray-500 whitespace-nowrap">
        {{ currentCredit }} credits
      </span>
    </div>
    <div class="mb-3">
      <SegmentedControl
        :items="levelItems"
        :model-value="levelIndex"
        @update:model-value="setLevel"
      />
    </div>
    <select
      v-if="nameChoices.length > 0"
      :value="nameChoice"
      class="w-full mb-3 text-[14px] font-medium rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-black dark:text-white px-3 py-2.5 cursor-pointer appearance-none"
      @change="setNameChoice(Number(($event.target as HTMLSelectElement).value))"
    >
      <option value="-1">{{ subject.name }}</option>
      <option
        v-for="(choice, idx) in nameChoices"
        :key="idx"
        :value="idx"
      >
        {{ choice.compact }}
      </option>
    </select>
    <SegmentedControl
      :items="scoreItems"
      :model-value="scoreIndex"
      @update:model-value="setScore"
    />
  </div>
</template>

<script setup lang="ts">
import { kSegmented, kSegmentedButton } from 'konsta/vue'

defineProps<{
  items: string[]
  modelValue: number
}>()

const emit = defineEmits<{
  'update:modelValue': [value: number]
}>()
</script>

<template>
  <k-segmented strong>
    <k-segmented-button
      v-for="(item, idx) in items"
      :key="idx"
      :active="modelValue === idx"
      @click="emit('update:modelValue', idx)"
    >
      {{ item }}
    </k-segmented-button>
  </k-segmented>
</template>

<script setup lang="ts">
defineProps<{
  items: string[]
  modelValue: number
}>()

const emit = defineEmits<{
  'update:modelValue': [value: number]
}>()
</script>

<template>
  <div class="inline-flex rounded-lg bg-gray-100 dark:bg-gray-800 p-0.5 gap-0.5">
    <button
      v-for="(item, idx) in items"
      :key="idx"
      class="flex-1 px-3 py-1.5 text-[13px] font-medium rounded-md transition-all cursor-pointer border-none"
      :class="modelValue === idx
        ? 'bg-white dark:bg-gray-600 text-black dark:text-white shadow-sm'
        : 'bg-transparent text-gray-500 dark:text-gray-400'"
      @click="emit('update:modelValue', idx)"
    >
      {{ item }}
    </button>
  </div>
</template>

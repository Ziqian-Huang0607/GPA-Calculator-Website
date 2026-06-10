<script setup lang="ts">
import { ref, watch, onMounted, nextTick } from 'vue'
// Import ciderui tabs JS for segmented control animation
import 'ciderui/cider.js'

const props = defineProps<{
  items: string[]
  modelValue: number
}>()

const emit = defineEmits<{
  'update:modelValue': [value: number]
}>()

const containerRef = ref<HTMLElement>()

function handleClick(index: number) {
  emit('update:modelValue', index)
}

function initTabs() {
  if (containerRef.value && window.CiderUI?.tabs) {
    window.CiderUI.tabs.init()
  }
}

onMounted(() => {
  nextTick(initTabs)
})

watch(
  () => props.modelValue,
  () => {
    nextTick(initTabs)
  }
)
</script>

<template>
  <div
    ref="containerRef"
    class="segmented-control"
    data-tabs
  >
    <div data-tab-list>
      <div data-tab-indicator />
      <button
        v-for="(item, i) in items"
        :key="i"
        data-tab
        :data-active="modelValue === i ? '' : undefined"
        @click="handleClick(i)"
      >
        {{ item }}
      </button>
    </div>
  </div>
</template>

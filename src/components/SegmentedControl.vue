<script setup lang="ts">
import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick } from 'vue'

const props = defineProps<{
  items: string[]
  modelValue: number
}>()

const emit = defineEmits<{
  'update:modelValue': [value: number]
}>()

const containerRef = ref<HTMLElement | null>(null)
const containerWidth = ref(0)
const useDropdown = ref(false)
const measureRef = ref<HTMLElement | null>(null)

const FONT_SIZE = 13
const ITEM_H_PADDING = 12
const INTER_ITEM_SPACING = 4
const CONTAINER_OUTER_MARGIN = 8
const COMPONENT_HEIGHT = 32
const EVEN_MODE_PADDING = 24

function measureTextWidth(text: string): number {
  if (!measureRef.value) return text.length * 7
  measureRef.value.textContent = text
  return measureRef.value.offsetWidth
}

const textWidths = computed(() => props.items.map(measureTextWidth))
const totalTextWidth = computed(() => textWidths.value.reduce((a, b) => a + b, 0))
const totalPadding = computed(() => props.items.length * ITEM_H_PADDING)
const totalSpacing = computed(() => Math.max(0, props.items.length - 1) * INTER_ITEM_SPACING)
const minRequiredWidth = computed(() => totalTextWidth.value + totalPadding.value + totalSpacing.value + CONTAINER_OUTER_MARGIN)
const maxTextWidth = computed(() => Math.max(...textWidths.value, 0))
const evenWidth = computed(() => (maxTextWidth.value + EVEN_MODE_PADDING) * props.items.length + CONTAINER_OUTER_MARGIN)
const evenlySpaced = computed(() => containerWidth.value >= evenWidth.value)
const canFit = computed(() => containerWidth.value >= minRequiredWidth.value && props.items.length > 1)

const indicatorStyle = computed(() => {
  if (!canFit.value || evenlySpaced.value) {
    const segWidth = props.items.length > 0 ? containerWidth.value / props.items.length : 0
    return {
      width: `${segWidth}px`,
      transform: `translateX(${props.modelValue * segWidth}px)`,
    }
  }
  return { width: '0px', transform: 'translateX(0px)' }
})

let resizeObserver: ResizeObserver | null = null

onMounted(() => {
  if (containerRef.value) {
    containerWidth.value = containerRef.value.offsetWidth
    resizeObserver = new ResizeObserver((entries) => {
      for (const entry of entries) {
        containerWidth.value = entry.contentRect.width
      }
    })
    resizeObserver.observe(containerRef.value)
  }
  updateDropdown()
})

onBeforeUnmount(() => {
  resizeObserver?.disconnect()
})

watch(() => props.items.length, async () => {
  await nextTick()
  updateDropdown()
})

watch(containerWidth, () => {
  updateDropdown()
})

function updateDropdown() {
  useDropdown.value = !canFit.value && props.items.length > 1
}
</script>

<template>
  <div ref="measureRef" class="pointer-events-none absolute opacity-0 text-[13px] font-medium px-3 whitespace-nowrap" aria-hidden="true" />
  <div
    ref="containerRef"
    class="segmented-root"
    :style="{ height: COMPONENT_HEIGHT + 'px' }"
  >
    <!-- Dropdown fallback -->
    <select
      v-if="useDropdown"
      class="segmented-select"
      :value="modelValue"
      @change="emit('update:modelValue', Number(($event.target as HTMLSelectElement).value))"
    >
      <option
        v-for="(item, idx) in items"
        :key="idx"
        :value="idx"
      >
        {{ item }}
      </option>
    </select>

    <!-- Segmented control -->
    <div v-else class="segmented-track">
      <div
        v-if="items.length > 0 && canFit"
        class="segmented-indicator"
        :style="indicatorStyle"
      />
      <button
        v-for="(item, idx) in items"
        :key="idx"
        class="segmented-item"
        :class="{ 'segmented-item--active': modelValue === idx, 'segmented-item--even': evenlySpaced }"
        @click="emit('update:modelValue', idx)"
      >
        {{ item }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.segmented-root {
  position: relative;
  width: 100%;
}

.segmented-track {
  display: flex;
  position: relative;
  width: 100%;
  height: 100%;
  border-radius: 8px;
  background: #e5e5ea;
  padding: 2px;
  gap: 0;
}

:root.dark .segmented-track,
.dark .segmented-track {
  background: #3a3a3c;
}

.segmented-indicator {
  position: absolute;
  top: 2px;
  left: 2px;
  height: calc(100% - 4px);
  background: white;
  border-radius: 6px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.06);
  transition: transform 0.2s cubic-bezier(0.25, 0.1, 0.25, 1),
              width 0.2s cubic-bezier(0.25, 0.1, 0.25, 1);
  z-index: 1;
}

:root.dark .segmented-indicator,
.dark .segmented-indicator {
  background: #636366;
}

.segmented-item {
  position: relative;
  z-index: 2;
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 12px;
  border: none;
  background: transparent;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  line-height: 1;
  color: #3c3c43;
  transition: color 0.2s ease;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  -webkit-tap-highlight-color: transparent;
  user-select: none;
}

.segmented-item--even {
  padding: 0;
}

:root.dark .segmented-item {
  color: #ebebed;
}

.segmented-item--active {
  color: #000;
}

:root.dark .segmented-item--active {
  color: white;
}

.segmented-select {
  width: 100%;
  height: 100%;
  padding: 0 10px;
  border-radius: 8px;
  border: 1px solid #d1d5db;
  background: #f2f2f7;
  color: #1c1c1e;
  font-size: 13px;
  font-weight: 500;
  appearance: none;
  cursor: pointer;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%236b7280' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 10px center;
  padding-right: 30px;
}

:root.dark .segmented-select {
  background: #2c2c2e;
  border-color: #48484a;
  color: #e5e5ea;
}
</style>

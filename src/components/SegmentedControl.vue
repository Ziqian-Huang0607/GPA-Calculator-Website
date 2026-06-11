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

const COMPONENT_HEIGHT = 32
const TRACK_PADDING = 2
const ITEM_H_PADDING = 24 // 12px left + 12px right padding

const textWidths = ref<number[]>([])

function measureTextWidth(text: string): number {
  if (!measureRef.value) return text.length * 7
  measureRef.value.textContent = text
  return measureRef.value.offsetWidth
}

function measureAll() {
  textWidths.value = props.items.map(measureTextWidth)
}

const totalTextWidth = computed(() => textWidths.value.reduce((a, b) => a + b, 0))
const totalPadding = computed(() => props.items.length * ITEM_H_PADDING)
const minRequiredWidth = computed(() => totalTextWidth.value + totalPadding.value + 8)
const maxTextWidth = computed(() => Math.max(...textWidths.value, 0))
const evenWidth = computed(() => (maxTextWidth.value + 24) * props.items.length + 8)
const evenlySpaced = computed(() => containerWidth.value >= evenWidth.value)
const canFit = computed(() => containerWidth.value >= minRequiredWidth.value && props.items.length > 1)

// Shared calculation for content-proportional mode
const proportionalLayout = computed(() => {
  const availableWidth = containerWidth.value - (TRACK_PADDING * 2)
  const totalContentWidth = totalTextWidth.value + totalPadding.value
  const scale = availableWidth / totalContentWidth

  const widths: number[] = []
  const positions: number[] = []
  let left = TRACK_PADDING

  for (let i = 0; i < props.items.length; i++) {
    positions.push(left)
    const btnWidth = (textWidths.value[i] + ITEM_H_PADDING) * scale
    widths.push(btnWidth)
    left += btnWidth
  }

  return { widths, positions, scale }
})

// Each button's width for content-proportional mode
const buttonStyles = computed(() => {
  if (!canFit.value || evenlySpaced.value) {
    return props.items.map(() => ({}))
  }

  const { widths } = proportionalLayout.value
  return widths.map((w) => ({
    width: `${w}px`,
    flex: 'none',
    padding: '0',
  }))
})

const indicatorStyle = computed(() => {
  if (!canFit.value || props.items.length === 0) {
    return { width: '0px', opacity: '0' }
  }

  if (evenlySpaced.value) {
    const availableWidth = containerWidth.value - (TRACK_PADDING * 2)
    const segWidth = availableWidth / props.items.length
    const left = TRACK_PADDING + props.modelValue * segWidth
    return { width: `${segWidth}px`, transform: `translateX(${left}px)`, opacity: '1' }
  } else {
    const { widths, positions } = proportionalLayout.value
    const left = positions[props.modelValue] ?? TRACK_PADDING
    const width = widths[props.modelValue] ?? 0
    return { width: `${width}px`, transform: `translateX(${left}px)`, opacity: '1' }
  }
})

let resizeObserver: ResizeObserver | null = null

onMounted(() => {
  measureAll()
  if (containerRef.value) {
    containerWidth.value = containerRef.value.offsetWidth
    resizeObserver = new ResizeObserver((entries) => {
      for (const entry of entries) {
        const width = entry.contentRect.width
        // If container transitions from hidden (0px) to visible, trigger full measurements
        if (width > 0 && containerWidth.value === 0) {
          containerWidth.value = width
          measureAll()
          updateDropdown()
        } else {
          containerWidth.value = width
        }
      }
    })
    resizeObserver.observe(containerRef.value)
  }
  updateDropdown()
})

onBeforeUnmount(() => {
  resizeObserver?.disconnect()
})

watch(() => props.items, () => {
  measureAll()
  updateDropdown()
}, { deep: true })

watch(() => [props.items.length, props.modelValue], async () => {
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
  <div
    ref="measureRef"
    class="pointer-events-none absolute opacity-0 text-[13px] font-medium whitespace-nowrap"
    style="font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, Helvetica, Arial, sans-serif !important;"
    aria-hidden="true"
  />
  <div
    ref="containerRef"
    class="segmented-root"
    :style="{ height: COMPONENT_HEIGHT + 'px' }"
  >
    <select
      v-if="useDropdown"
      class="segmented-select"
      :value="modelValue"
      @change="emit('update:modelValue', Number(($event.target as HTMLSelectElement).value))"
    >
      <option v-for="(item, idx) in items" :key="idx" :value="idx">{{ item }}</option>
    </select>

    <div v-else class="segmented-track">
      <div class="segmented-indicator" :style="indicatorStyle" />
      <button
        v-for="(item, idx) in items"
        :key="idx"
        class="segmented-item"
        :class="{ 'segmented-item--active': modelValue === idx }"
        :style="buttonStyles[idx]"
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
  left: 0;
  height: calc(100% - 4px);
  background: white;
  border-radius: 6px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.06);
  transition: transform 0.2s cubic-bezier(0.25, 0.1, 0.25, 1),
              width 0.15s cubic-bezier(0.25, 0.1, 0.25, 1);
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
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
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
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, Helvetica, Arial, sans-serif !important;
  font-size: 13px;
  font-weight: 500;
  appearance: none;
  cursor: pointer;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%236b7280' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 10px center;
  padding-right: 30px;
}

.segmented-select option {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, Helvetica, Arial, sans-serif !important;
  font-size: 13px;
  font-weight: 500;
  background: white;
  color: black;
}

:root.dark .segmented-select {
  background: #2c2c2e;
  border-color: #48484a;
  color: #e5e5ea;
}

:root.dark .segmented-select option,
.dark .segmented-select option {
  background: #1c1c1e;
  color: white;
}
</style>
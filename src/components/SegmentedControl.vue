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
const dropdownRef = ref<HTMLElement | null>(null)
const containerWidth = ref(0)
const useDropdown = ref(false)
const isDropdownOpen = ref(false)
const measureRef = ref<HTMLElement | null>(null)

const COMPONENT_HEIGHT = 32
const TRACK_PADDING = 2
const ITEM_H_PADDING = 24 // 12px left + 12px right padding

const textWidths = ref<number[]>([])
const activeIndicatorStyle = ref({ width: '0px', transform: 'translateX(0px)', opacity: '0' })

function measureTextWidth(text: string): number {
  if (!measureRef.value) return text.length * 7
  measureRef.value.textContent = text
  return measureRef.value.offsetWidth
}

function measureAll() {
  textWidths.value = props.items.map(measureTextWidth)
}

function selectItem(idx: number) {
  emit('update:modelValue', idx)
  isDropdownOpen.value = false
}

function handleOutsideClick(e: MouseEvent) {
  if (dropdownRef.value && !dropdownRef.value.contains(e.target as Node)) {
    isDropdownOpen.value = false
  }
}

async function updateIndicator() {
  if (!containerRef.value) return
  const track = containerRef.value.querySelector('.segmented-track')
  if (!track) {
    activeIndicatorStyle.value = { width: '0px', transform: 'translateX(0px)', opacity: '0' }
    return
  }

  const itemsList = track.querySelectorAll('.segmented-item')
  const activeItem = itemsList[props.modelValue] as HTMLElement
  if (!activeItem) {
    activeIndicatorStyle.value = { width: '0px', transform: 'translateX(0px)', opacity: '0' }
    return
  }

  // Exact coordinates rendered by the browser
  const width = activeItem.offsetWidth
  const left = activeItem.offsetLeft

  activeIndicatorStyle.value = {
    width: `${width}px`,
    transform: `translateX(${left}px)`,
    opacity: '1'
  }
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
  for (let i = 0; i < props.items.length; i++) {
    const btnWidth = (textWidths.value[i] + ITEM_H_PADDING) * scale
    widths.push(btnWidth)
  }
  return { widths }
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

let resizeObserver: ResizeObserver | null = null

onMounted(async () => {
  measureAll()
  document.addEventListener('mousedown', handleOutsideClick)
  if (containerRef.value) {
    containerWidth.value = containerRef.value.offsetWidth
    resizeObserver = new ResizeObserver(async (entries) => {
      for (const entry of entries) {
        const width = entry.contentRect.width
        if (width > 0 && containerWidth.value === 0) {
          containerWidth.value = width
          measureAll()
          updateDropdown()
          await nextTick()
          updateIndicator()
        } else {
          containerWidth.value = width
          await nextTick()
          updateIndicator()
        }
      }
    })
    resizeObserver.observe(containerRef.value)
  }
  updateDropdown()
  await nextTick()
  updateIndicator()
})

onBeforeUnmount(() => {
  document.removeEventListener('mousedown', handleOutsideClick)
  resizeObserver?.disconnect()
})

watch(() => props.items, async () => {
  measureAll()
  updateDropdown()
  await nextTick()
  updateIndicator()
}, { deep: true })

watch(() => [props.items.length, props.modelValue], async () => {
  await nextTick()
  updateDropdown()
  updateIndicator()
})

watch(containerWidth, async () => {
  updateDropdown()
  await nextTick()
  updateIndicator()
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
    <!-- Premium Custom Dropdown Panel Mode -->
    <div v-if="useDropdown" class="custom-select-wrapper" ref="dropdownRef">
      <div
        class="custom-select-display"
        @click="isDropdownOpen = !isDropdownOpen"
      >
        <span>{{ items[modelValue] }}</span>
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          class="chevron-icon"
          :class="{ open: isDropdownOpen }"
        >
          <polyline points="6 9 12 15 18 9"></polyline>
        </svg>
      </div>
      <div class="custom-select-menu" :class="{ open: isDropdownOpen }">
        <div
          v-for="(item, idx) in items"
          :key="idx"
          class="custom-select-option"
          :class="{ selected: modelValue === idx }"
          @click="selectItem(idx)"
        >
          {{ item }}
        </div>
      </div>
    </div>

    <!-- Segmented Multi-Button Control Mode -->
    <div v-else class="segmented-track">
      <div class="segmented-indicator" :style="activeIndicatorStyle" />
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

/* Custom Dropdown CSS exactly based on index.html styling specifications */
.custom-select-wrapper {
  position: relative;
  font-size: 13px;
  width: 100%;
  height: 32px;
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, Helvetica, Arial, sans-serif !important;
}

.custom-select-display {
  border: 1px solid #d1d5db;
  padding: 0 12px;
  border-radius: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  background: #ffffff;
  color: #000000;
  height: 100%;
  transition: border-color 0.2s, background-color 0.2s;
  font-weight: 500;
}

.dark .custom-select-display {
  border-color: #4b5563;
  background: #1f2937;
  color: #ffffff;
}

.custom-select-display:hover {
  border-color: #9ca3af;
}

.dark .custom-select-display:hover {
  border-color: #6b7280;
}

.chevron-icon {
  width: 12px;
  height: 12px;
  transition: transform 0.2s;
  color: #6b7280;
}
.dark .chevron-icon {
  color: #9ca3af;
}
.chevron-icon.open {
  transform: rotate(180deg);
}

.custom-select-menu {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  margin-top: 4px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  opacity: 0;
  transform: translateY(-10px);
  pointer-events: none;
  transition: opacity 0.2s, transform 0.2s;
  z-index: 100;
  max-height: 200px;
  overflow-y: auto;
  padding: 4px;
}

.dark .custom-select-menu {
  background: rgba(31, 41, 55, 0.9);
  border-color: #374151;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.custom-select-menu.open {
  opacity: 1;
  transform: translateY(0);
  pointer-events: auto;
}

.custom-select-option {
  padding: 6px 10px;
  margin-bottom: 2px;
  cursor: pointer;
  border-radius: 6px;
  color: #374151;
  font-weight: 500;
  transition: background-color 0.15s;
}

.dark .custom-select-option {
  color: #e5e7eb;
}

.custom-select-option:last-child {
  margin-bottom: 0;
}

.custom-select-option.selected {
  background: #e5e7eb;
  color: #000000;
  font-weight: 600;
}

.dark .custom-select-option.selected {
  background: #4b5563;
  color: #ffffff;
}

.custom-select-option:hover {
  background: #f3f4f6;
}

.dark .custom-select-option:hover:not(.selected) {
  background: #374151;
}
</style>
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
const measureRef = ref<HTMLElement | null>(null)

const COMPONENT_HEIGHT = 32
const TRACK_PADDING = 2
const ITEM_H_PADDING = 24 // 12px left + 12px right padding

const textWidths = ref<number[]>([])
const activeIndicatorStyle = ref({ width: '0px', transform: 'translateX(0px)', opacity: '0' })
const dragging = ref(false)

function measureTextWidth(text: string): number {
  if (!measureRef.value) return text.length * 7
  measureRef.value.textContent = text
  return measureRef.value.offsetWidth
}

function measureAll() {
  textWidths.value = props.items.map(measureTextWidth)
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

  const width = activeItem.offsetWidth
  const left = activeItem.offsetLeft

  activeIndicatorStyle.value = {
    width: `${width}px`,
    transform: `translateX(${left}px)`,
    opacity: '1'
  }
}

function getIndexFromCoords(clientX: number): number {
  if (!containerRef.value) return props.modelValue
  const track = containerRef.value.querySelector('.segmented-track')
  if (!track) return props.modelValue
  const rect = track.getBoundingClientRect()
  const relativeX = clientX - rect.left - TRACK_PADDING
  const clampedX = Math.max(0, Math.min(rect.width - TRACK_PADDING * 2, relativeX))

  if (evenlySpaced.value) {
    const availableWidth = rect.width - (TRACK_PADDING * 2)
    const chunkWidth = availableWidth / props.items.length
    const idx = Math.floor(clampedX / chunkWidth)
    return Math.max(0, Math.min(props.items.length - 1, idx))
  } else {
    const { widths } = proportionalLayout.value
    let accumulated = 0
    for (let i = 0; i < props.items.length; i++) {
      const nextBound = accumulated + widths[i]
      if (clampedX >= accumulated && clampedX <= nextBound) {
        return i
      }
      accumulated = nextBound
    }
    return props.items.length - 1
  }
}

function onDragStart(e: MouseEvent | TouchEvent) {
  if (useDropdown.value) return
  dragging.value = true
  const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX
  const targetIdx = getIndexFromCoords(clientX)
  emit('update:modelValue', targetIdx)

  if ('touches' in e) {
    window.addEventListener('touchmove', onDragMove, { passive: false })
    window.addEventListener('touchend', onDragEnd)
  } else {
    window.addEventListener('mousemove', onDragMove)
    window.addEventListener('mouseup', onDragEnd)
  }
}

function onDragMove(e: MouseEvent | TouchEvent) {
  if (!dragging.value) return
  if (e.cancelable) e.preventDefault()
  const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX
  const targetIdx = getIndexFromCoords(clientX)
  if (targetIdx !== props.modelValue) {
    emit('update:modelValue', targetIdx)
  }
}

function onDragEnd() {
  dragging.value = false
  window.removeEventListener('mousemove', onDragMove)
  window.removeEventListener('mouseup', onDragEnd)
  window.removeEventListener('touchmove', onDragMove)
  window.removeEventListener('touchend', onDragEnd)
}

const totalTextWidth = computed(() => textWidths.value.reduce((a, b) => a + b, 0))
const totalPadding = computed(() => props.items.length * ITEM_H_PADDING)
const minRequiredWidth = computed(() => totalTextWidth.value + totalPadding.value + 8)
const maxTextWidth = computed(() => Math.max(...textWidths.value, 0))
const evenWidth = computed(() => (maxTextWidth.value + 24) * props.items.length + 8)
const evenlySpaced = computed(() => containerWidth.value >= evenWidth.value)
const canFit = computed(() => containerWidth.value >= minRequiredWidth.value && props.items.length > 1)

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
  if (containerRef.value) {
    containerWidth.value = containerRef.value.offsetWidth
    resizeObserver = new ResizeObserver(async (entries) => {
      for (const entry of entries) {
        const width = entry.contentRect.width
        containerWidth.value = width
        if (width > 0 && textWidths.value.length === 0) {
          measureAll()
        }
        await nextTick()
        updateIndicator()
      }
    })
    resizeObserver.observe(containerRef.value)
  }
  await nextTick()
  updateIndicator()
})

onBeforeUnmount(() => {
  resizeObserver?.disconnect()
})

watch(() => props.items, async () => {
  measureAll()
  await nextTick()
  updateIndicator()
}, { deep: true })

watch(() => [props.items.length, props.modelValue], async () => {
  await nextTick()
  updateIndicator()
})

watch(containerWidth, async () => {
  await nextTick()
  updateIndicator()
})
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
    <!-- Segmented Control Mode with Drag/Slide Touch Interactions -->
    <div
      class="segmented-track select-none cursor-default"
      @mousedown="onDragStart"
      @touchstart="onDragStart"
    >
      <div class="segmented-indicator" :style="activeIndicatorStyle" />
      <button
        v-for="(item, idx) in items"
        :key="idx"
        class="segmented-item"
        :class="{ 'segmented-item--active': modelValue === idx }"
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
  -webkit-user-select: none;
  user-select: none;
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
  /* SwiftUI kinetic spring-like curves */
  transition: transform 0.28s cubic-bezier(0.15, 0.85, 0.35, 1),
              width 0.22s cubic-bezier(0.15, 0.85, 0.35, 1);
  z-index: 1;
}

:root.dark .segmented-indicator,
.dark .segmented-indicator {
  background: #636366;
}

.segmented-item {
  position: relative;
  z-index: 2;
  flex: 1 0 auto;
  min-width: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 12px;
  border: none;
  background: transparent;
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

.segmented-track {
  overflow-x: auto;
  scrollbar-width: none;
}

.segmented-track::-webkit-scrollbar {
  display: none;
}
</style>
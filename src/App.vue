<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useBackend } from './logic/useBackend'
import SubjectRow from './components/SubjectRow.vue'
import CustomizeView from './components/CustomizeView.vue'

const backend = useBackend()
const showCustomize = ref(false)

onMounted(() => {
  backend.loadInitialData()
})
</script>

<template>
  <!-- Loading State -->
  <div
    v-if="backend.isLoading.value"
    class="min-h-screen flex items-center justify-center bg-white dark:bg-gray-900"
  >
    <div class="text-center">
      <div
        class="activity-indicator mb-4"
        role="progressbar"
        aria-label="Loading"
      />
      <p class="text-[13px] text-gray-500 dark:text-gray-400 font-medium">
        Loading catalog...
      </p>
    </div>
  </div>

  <!-- Main Layout -->
  <div v-else class="app-layout">
    <!-- Main Content -->
    <div class="main-content">
      <header class="sticky top-0 z-30 bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b border-gray-200 dark:border-gray-800">
        <div class="px-4 py-3 max-w-2xl mx-auto">
          <h1 class="text-[17px] font-semibold text-center text-black dark:text-white">GPA Calculator</h1>
        </div>
      </header>

      <div class="px-4 pb-8 max-w-2xl mx-auto">
        <div class="text-center py-6">
          <p
            class="text-[16px] mt-1 font-medium"
            :class="backend.isInvalidated.value ? 'text-red-500' : 'text-gray-500 dark:text-gray-400'"
          >
            {{ backend.calculationResultText.value }}
          </p>
        </div>

        <div class="flex gap-4 mb-6">
          <button
            class="flex-1 px-4 py-2.5 text-[15px] font-medium rounded-xl border border-gray-300 dark:border-gray-600 text-black dark:text-white bg-white dark:bg-gray-800 cursor-pointer transition-colors hover:bg-gray-50 dark:hover:bg-gray-700 active:bg-gray-100 dark:active:bg-gray-600"
            @click="showCustomize = !showCustomize"
          >
            {{ showCustomize ? 'Hide Customize' : 'Customize' }}
          </button>
          <button
            class="flex-1 px-4 py-2.5 text-[15px] font-medium rounded-xl border border-gray-300 dark:border-gray-600 text-black dark:text-white bg-white dark:bg-gray-800 cursor-pointer transition-colors hover:bg-gray-50 dark:hover:bg-gray-700 active:bg-gray-100 dark:active:bg-gray-600"
            @click="backend.resetAllLevelsAndScores()"
          >
            Reset
          </button>
        </div>

        <div class="space-y-4">
          <SubjectRow
            v-for="(subj, idx) in backend.activeSubjects.value"
            :key="subj.id || subj.name"
            :subject="subj"
            :index="idx"
          />
        </div>
      </div>
    </div>

    <!-- Sidebar (desktop) / Sheet (mobile) -->
    <CustomizeView
      :show="showCustomize"
      @close="showCustomize = false"
    />
  </div>
</template>

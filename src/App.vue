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
  <div class="cider min-h-screen bg-grouped">
    <!-- Loading State -->
    <div
      v-if="backend.isLoading.value"
      class="min-h-screen flex items-center justify-center"
    >
      <div class="text-center">
        <div
          class="activity-indicator mb-4"
          role="progressbar"
          aria-label="Loading"
        />
        <p class="text-[13px] text-tertiary-foreground font-medium">
          Loading catalog...
        </p>
      </div>
    </div>

    <!-- Main Content -->
    <div v-else class="min-h-screen">
      <!-- Navbar — no title, heading below handles it -->
      <div class="navbar sticky top-0 z-40">
        <div />
        <div />
        <div />
      </div>

      <!-- Content Area -->
      <div class="px-4 pb-8 max-w-2xl mx-auto">
        <!-- Header: Title + Result -->
        <div class="text-center py-6">
          <h1 class="text-[28px] font-semibold text-foreground tracking-tight">
            GPA Calculator
          </h1>
          <p
            class="text-[16px] mt-1"
            :class="backend.isInvalidated.value ? 'text-destructive' : 'text-tertiary-foreground'"
          >
            {{ backend.calculationResultText.value }}
          </p>
        </div>

        <!-- Action Buttons: Customize + Reset -->
        <div class="flex gap-4 mb-6">
          <button
            class="btn-gray flex-1"
            @click="showCustomize = true"
          >
            Customize
          </button>
          <button
            class="btn-gray flex-1"
            @click="backend.resetAllLevelsAndScores()"
          >
            Reset
          </button>
        </div>

        <!-- Subject Rows -->
        <div class="space-y-4">
          <SubjectRow
            v-for="(subj, idx) in backend.activeSubjects.value"
            :key="subj.id || subj.name"
            :subject="subj"
            :index="idx"
          />
        </div>
      </div>

      <!-- Customize Modal -->
      <CustomizeView
        :show="showCustomize"
        @close="showCustomize = false"
      />
    </div>
  </div>
</template>

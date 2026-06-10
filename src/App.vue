<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useBackend } from './logic/useBackend'
import SubjectRow from './components/SubjectRow.vue'
import CustomizeView from './components/CustomizeView.vue'
import { kApp, kPage, kNavbar } from 'konsta/vue'

const backend = useBackend()
const showCustomize = ref(false)

onMounted(() => {
  backend.loadInitialData()
})
</script>

<template>
  <k-app theme="ios">
    <!-- Loading State -->
    <div
      v-if="backend.isLoading.value"
      class="k-ios min-h-screen flex items-center justify-center bg-ios-light-surface dark:bg-ios-dark-surface"
    >
      <div class="text-center">
        <div
          class="activity-indicator mb-4"
          role="progressbar"
          aria-label="Loading"
        />
        <p class="text-[13px] text-ios-light-secondary-label dark:text-ios-dark-secondary-label font-medium">
          Loading catalog...
        </p>
      </div>
    </div>

    <!-- Main Content -->
    <k-page v-else>
      <k-navbar
        title="GPA Calculator"
        class="top-0 sticky"
      />

      <div class="px-4 pb-8 max-w-2xl mx-auto">
        <!-- GPA Result -->
        <div class="text-center py-6">
          <p
            class="text-[16px] mt-1"
            :class="backend.isInvalidated.value ? 'text-red-500' : 'text-ios-light-secondary-label dark:text-ios-dark-secondary-label'"
          >
            {{ backend.calculationResultText.value }}
          </p>
        </div>

        <!-- Action Buttons -->
        <div class="flex gap-4 mb-6">
          <k-button
            class="flex-1"
            outline
            @click="showCustomize = true"
          >
            Customize
          </k-button>
          <k-button
            class="flex-1"
            outline
            @click="backend.resetAllLevelsAndScores()"
          >
            Reset
          </k-button>
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
    </k-page>
  </k-app>
</template>

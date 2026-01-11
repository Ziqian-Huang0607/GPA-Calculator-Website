<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useStorage } from '@vueuse/core'
import { Zap, ShieldCheck, Sparkles, ExternalLink } from 'lucide-vue-next'
import gsap from 'gsap'

// --- TYPES ---
export interface ScoreMap { percentageName: string; letterName: string; baseGPA: number; }
export interface Level { name: string; offset: number; weightOverride?: number; }
export interface Subject { name: string; weight: number; levels: Level[]; customScoreToBaseGPAMap?: ScoreMap[]; }
export interface Module { type: 'core' | 'choice'; name?: string; selectionLimit?: number; subjects: Subject[]; }
export interface Preset { id: string; name: string; subtitle?: string; modules: Module[]; }
export interface RootData { commonScoreMap: ScoreMap[]; presets: Preset[]; lastUpdated?: string; }

// --- STATE ---
const data = ref<RootData | null>(null)
const selectedPreset = ref<Preset | null>(null)
const scoreMode = useStorage<'percentage' | 'letter'>('shsid-v9-mode', 'percentage')
const moduleChoices = useStorage<Record<string, number[]>>('shsid-v9-choices', {})
const userSelections = useStorage<Record<string, { levelIdx: number; scoreIdx: number }>>('shsid-v9-selections', {})

const gpaDisplay = ref(0)
const isLoading = ref(true)

// --- PARSER ---
const parsePlist = (xml: string): RootData => {
  const parser = new DOMParser();
  const xmlDoc = parser.parseFromString(xml, "text/xml");
  const rootDict = xmlDoc.getElementsByTagName("dict")[0] as Element;
  
  const parseNode = (node: Element): any => {
    const tag = node.tagName;
    if (tag === "dict") {
      const obj: Record<string, any> = {};
      const keys = Array.from(node.querySelectorAll(":scope > key"));
      const values = Array.from(node.querySelectorAll(":scope > key + *"));
      keys.forEach((k, i) => { 
        if (k.textContent) obj[k.textContent] = parseNode(values[i] as Element); 
      });
      return obj;
    } else if (tag === "array") {
      return Array.from(node.children).map(c => parseNode(c as Element));
    } else if (tag === "string") return node.textContent || "";
    else if (tag === "real" || tag === "integer") return Number(node.textContent || 0);
    else if (tag === "true") return true;
    else if (tag === "false") return false;
    return null;
  };
  return parseNode(rootDict);
};

// --- LOGIC ---
onMounted(async () => {
  try {
    const res = await fetch("https://edgeone.gh-proxy.org/https://raw.githubusercontent.com/WillUHD/GPAResources/refs/heads/main/presets.plist");
    const xml = await res.text();
    const parsed = parsePlist(xml);
    data.value = parsed;
    if (parsed && parsed.presets && parsed.presets.length > 0) {
      selectedPreset.value = parsed.presets[0];
    }
    isLoading.value = false;
  } catch (e) {
    isLoading.value = false;
  }
});

const activeSubjects = computed(() => {
  if (!selectedPreset.value) return [];
  const list: Subject[] = [];
  selectedPreset.value.modules.forEach((mod, modIdx) => {
    if (mod.type === 'core') {
      list.push(...mod.subjects);
    } else {
      const key = `${selectedPreset.value?.id}_${modIdx}`;
      const chosen = moduleChoices.value[key] || [];
      chosen.forEach(idx => {
        if (mod.subjects[idx]) list.push(mod.subjects[idx]);
      });
    }
  });
  return list;
});

const gpa = computed(() => {
  if (!data.value || !selectedPreset.value) return 0;
  let pts = 0, crd = 0;
  activeSubjects.value.forEach(s => {
    const selKey = `${selectedPreset.value?.id}_${s.name}`;
    const sel = userSelections.value[selKey] || { levelIdx: 0, scoreIdx: 0 };
    const level = s.levels[sel.levelIdx] || s.levels[0] || { name: 'S', offset: 0 };
    const map = s.customScoreToBaseGPAMap || data.value?.commonScoreMap || [];
    const baseGPA = map[sel.scoreIdx]?.baseGPA || 0;
    const minOff = Math.min(...s.levels.map(l => l.offset));
    const subGPA = Math.max(0, baseGPA - Math.max(0, level.offset - minOff));
    pts += (subGPA * (level.weightOverride ?? s.weight));
    crd += s.weight;
  });
  return crd > 0 ? pts / crd : 0;
});

watch(gpa, (v) => gsap.to(gpaDisplay, { duration: 0.6, value: v, ease: "power2.out" }));

const toggleMod = (mIdx: number, sIdx: number, limit: number) => {
  if (!selectedPreset.value) return;
  const key = `${selectedPreset.value.id}_${mIdx}`;
  const cur = [...(moduleChoices.value[key] || [])];
  if (cur.includes(sIdx)) {
    moduleChoices.value[key] = cur.filter(i => i !== sIdx);
  } else {
    cur.push(sIdx);
    if (cur.length > limit) cur.shift();
    moduleChoices.value[key] = cur;
  }
};
</script>

<template>
  <div class="neural-bg"></div>
  <div class="noise-overlay"></div>

  <div v-if="isLoading" class="min-h-screen flex flex-col items-center justify-center font-black text-blue-500 uppercase tracking-widest animate-pulse">
    Syncing Indexademics Engine...
  </div>

  <div v-else class="min-h-screen p-4 md:p-12 text-white">
    <nav class="max-w-7xl mx-auto flex justify-between items-center mb-16">
      <div class="flex items-center gap-4">
        <img src="/indexademics-logo.png" alt="Logo" class="w-12 h-12" />
        <div class="leading-none">
          <h1 class="text-2xl font-black uppercase italic tracking-tighter">Indexademics</h1>
          <p class="text-[9px] text-blue-400 font-bold tracking-[0.4em] ml-1">SHSID PRO ENGINE</p>
        </div>
      </div>
    </nav>

    <main class="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-10">
      <aside class="lg:col-span-4 space-y-8">
        <div class="gpa-card glass-panel p-10 text-center rounded-[2rem]">
          <span class="text-[10px] font-black text-blue-400 uppercase tracking-widest block mb-2">Weighted GPA</span>
          <div class="text-7xl font-black font-mono tracking-tighter mb-4">{{ gpaDisplay.toFixed(3) }}</div>
          <div class="flex justify-center gap-3">
            <div class="text-[10px] font-black text-blue-400 bg-blue-500/10 px-3 py-1 rounded-full flex items-center gap-1"><Zap :size="12"/> FAST</div>
            <div class="text-[10px] font-black text-green-500 bg-green-500/10 px-3 py-1 rounded-full flex items-center gap-1"><ShieldCheck :size="12"/> PRECISE</div>
          </div>
        </div>

        <!-- Presets -->
        <div class="glass-panel p-8 rounded-[2rem]">
          <h3 class="text-xs font-black text-slate-500 uppercase mb-6 tracking-widest">Academic Preset</h3>
          <div class="space-y-3">
            <button v-for="p in data?.presets" :key="p.id" @click="selectedPreset = p"
              :class="['w-full p-5 rounded-2xl text-left border-2 font-black transition-all', selectedPreset?.id === p.id ? 'bg-blue-600 border-blue-400 text-white' : 'bg-white/5 border-transparent text-slate-500']">
              {{ p.name }}
            </button>
          </div>
        </div>

        <!-- Electives -->
        <div v-if="selectedPreset" class="space-y-4">
          <div v-for="(mod, mIdx) in selectedPreset.modules" :key="mIdx">
            <div v-if="mod.type === 'choice'" class="glass-panel p-8 rounded-[2rem]">
              <h4 class="text-[10px] font-black text-blue-500 uppercase mb-4 tracking-widest">{{ mod.name || 'Elective' }}</h4>
              <div class="grid grid-cols-1 gap-2">
                <button v-for="(subj, sIdx) in mod.subjects" :key="sIdx"
                  @click="toggleMod(mIdx, sIdx, mod.selectionLimit || 1)"
                  :class="['p-4 rounded-xl text-xs font-black border-2 flex justify-between items-center', (moduleChoices[`${selectedPreset?.id}_${mIdx}`] || []).includes(sIdx) ? 'bg-blue-600 border-blue-400 text-white shadow-lg' : 'bg-black/40 border-transparent text-slate-600']">
                  {{ subj.name }}
                  <div v-if="(moduleChoices[`${selectedPreset?.id}_${mIdx}`] || []).includes(sIdx)" class="w-2 h-2 bg-blue-400 rounded-full animate-pulse"></div>
                </button>
              </div>
            </div>
          </div>
        </div>
      </aside>

      <!-- Calculator Section -->
      <section class="lg:col-span-8 space-y-6">
        <div class="mb-12">
          <div class="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-[10px] font-black mb-6 uppercase tracking-widest">
            <Sparkles :size="14" /> EXCLUSIVELY FOR SHSID STUDENTS
          </div>
          <h2 class="text-7xl font-black tracking-tighter leading-none">SHSID GPA <br><span class="text-blue-500">Calculator Online</span></h2>
        </div>

        <div class="flex p-2 bg-slate-900/80 rounded-2xl border border-white/5 backdrop-blur-xl sticky top-8 z-50">
          <button @click="scoreMode = 'percentage'" :class="['flex-1 py-4 text-xs font-black rounded-xl transition-all', scoreMode === 'percentage' ? 'bg-white text-black' : 'text-slate-500']">PERCENTAGE</button>
          <button @click="scoreMode = 'letter'" :class="['flex-1 py-4 text-xs font-black rounded-xl transition-all', scoreMode === 'letter' ? 'bg-white text-black' : 'text-slate-500']">LETTER GRADE</button>
        </div>

        <!-- Subjects List -->
        <div class="space-y-6 pb-20">
          <div v-for="subj in activeSubjects" :key="subj.name" class="glass-panel p-8 md:p-12 rounded-[3rem] hover:border-blue-500/20">
            <div class="flex flex-col md:flex-row justify-between md:items-center gap-6 mb-12">
              <h4 class="text-4xl font-black tracking-tight">{{ subj.name }}</h4>
              
              <div class="flex bg-black/60 p-1.5 rounded-2xl border border-white/10 no-scrollbar overflow-x-auto">
                <button v-for="(lvl, lIdx) in subj.levels" :key="lvl.name" 
                  @click="userSelections[`${selectedPreset?.id}_${subj.name}`] = { 
                    scoreIdx: userSelections[`${selectedPreset?.id}_${subj.name}`]?.scoreIdx ?? 0,
                    levelIdx: lIdx 
                  }"
                  :class="['px-5 py-2.5 rounded-xl text-[10px] font-black transition-all uppercase whitespace-nowrap', (userSelections[`${selectedPreset?.id}_${subj.name}`]?.levelIdx || 0) === lIdx ? 'bg-white text-black shadow-2xl' : 'text-slate-600']">
                  {{ lvl.name }}
                </button>
              </div>
            </div>

            <div class="grid grid-cols-4 md:grid-cols-8 gap-3">
              <button v-for="(score, sIdx) in (subj.customScoreToBaseGPAMap || data?.commonScoreMap || [])" :key="sIdx"
                @click="userSelections[`${selectedPreset?.id}_${subj.name}`] = { 
                   levelIdx: userSelections[`${selectedPreset?.id}_${subj.name}`]?.levelIdx ?? 0,
                   scoreIdx: sIdx 
                }"
                :class="['grade-btn py-4 text-xs', (userSelections[`${selectedPreset?.id}_${subj.name}`]?.scoreIdx || 0) === sIdx ? 'active' : '']">
                {{ scoreMode === 'percentage' ? score.percentageName : score.letterName }}
              </button>
            </div>
          </div>
        </div>
      </section>
    </main>

    <footer class="max-w-7xl mx-auto mt-24 pb-20 border-t border-white/10 pt-16 flex flex-col md:flex-row justify-between items-start gap-8">
      <div class="space-y-4">
        <h4 class="font-black text-2xl tracking-tighter uppercase italic bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-500">SHSID GPA Online</h4>
        <p class="text-[12px] text-slate-500 uppercase tracking-widest font-bold leading-relaxed max-w-md">
          Propagated by Indexademics Developer Team. Senior Developer: Ziqian Huang. Original Project: WillUHD & Michel.
        </p>
      </div>
      <div class="flex gap-12 text-right">
        <div class="space-y-2">
          <span class="text-[10px] font-black text-slate-600 uppercase tracking-widest block">Maintainer</span>
          <a href="https://github.com/Ziqian-Huang0607" target="_blank" class="flex items-center gap-2 text-sm font-black text-blue-400 hover:text-white transition-all">ZIQIAN HUANG <ExternalLink :size="14" /></a>
        </div>
      </div>
    </footer>
  </div>
</template>
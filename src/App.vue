<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useStorage } from '@vueuse/core'
import { Zap, RefreshCcw, ShieldCheck, Sparkles, Github, ChevronRight, ExternalLink } from 'lucide-vue-next'
import gsap from 'gsap'

// --- 1. DATA MODELS ---
interface ScoreMap { percentageName: string; letterName: string; baseGPA: number; }
interface Level { name: string; offset: number; weightOverride?: number; }
interface Subject { name: string; weight: number; levels: Level[]; customScoreToBaseGPAMap?: ScoreMap[]; }
interface Module { type: 'core' | 'choice'; name?: string; selectionLimit?: number; subjects: Subject[]; }
interface Preset { id: string; name: string; subtitle?: string; modules: Module[]; }
interface RootData { commonScoreMap: ScoreMap[]; presets: Preset[]; lastUpdated?: string; }

// --- 2. ENGINE STATE ---
const data = ref<RootData | null>(null)
const selectedPreset = ref<Preset | null>(null)
const scoreMode = useStorage<'percentage' | 'letter'>('shsid-v6-mode', 'percentage')
const moduleChoices = useStorage<Record<string, number[]>>('shsid-v6-module-choices', {})
const userSelections = useStorage<Record<string, { levelIdx: number; scoreIdx: number }>>('shsid-v6-user-selections', {})

const gpaDisplay = ref(0)
const isLoading = ref(true)

// --- 3. PLIST PARSER ---
const parsePlist = (xml: string) => {
  const parser = new DOMParser();
  const xmlDoc = parser.parseFromString(xml, "text/xml");
  const parseNode = (node: Element): any => {
    const tag = node.tagName;
    if (tag === "dict") {
      const obj: any = {};
      const keys = Array.from(node.querySelectorAll(":scope > key"));
      const values = Array.from(node.querySelectorAll(":scope > key + *"));
      keys.forEach((k, i) => { obj[k.textContent!] = parseNode(values[i]); });
      return obj;
    } else if (tag === "array") return Array.from(node.children).map(c => parseNode(c as Element));
    else if (tag === "string") return node.textContent;
    else if (tag === "real" || tag === "integer") return Number(node.textContent);
    else if (tag === "true") return true;
    else if (tag === "false") return false;
    return null;
  };
  return parseNode(xmlDoc.getElementsByTagName("dict")[0]);
};

// --- 4. ENGINE LOGIC & SYNC ---
onMounted(async () => {
  try {
    const res = await fetch("https://edgeone.gh-proxy.org/https://raw.githubusercontent.com/WillUHD/GPAResources/refs/heads/main/presets.plist");
    const xml = await res.text();
    data.value = parsePlist(xml);
    if (data.value && !selectedPreset.value) {
      selectedPreset.value = data.value.presets[0];
    }
    isLoading.value = false;
  } catch (e) { isLoading.value = false; }
});

const activeSubjects = computed(() => {
  if (!selectedPreset.value) return [];
  const list: Subject[] = [];
  selectedPreset.value.modules.forEach((mod, modIdx) => {
    if (mod.type === 'core') {
      list.push(...mod.subjects);
    } else {
      const key = `${selectedPreset.value!.id}_${modIdx}`;
      const chosenIndices = moduleChoices.value[key] || [];
      chosenIndices.forEach(idx => {
        if (mod.subjects[idx]) list.push(mod.subjects[idx]);
      });
    }
  });
  return list;
});

const calculateGPA = () => {
  if (!data.value || !selectedPreset.value) return 0;
  let pts = 0, crd = 0;
  activeSubjects.value.forEach(s => {
    const selKey = `${selectedPreset.value!.id}_${s.name}`;
    const sel = userSelections.value[selKey] || { levelIdx: 0, scoreIdx: 0 };
    const level = s.levels[sel.levelIdx] || s.levels[0];
    const map = s.customScoreToBaseGPAMap || data.value!.commonScoreMap;
    const baseGPA = map[sel.scoreIdx]?.baseGPA || 0;

    const minOff = Math.min(...s.levels.map(l => l.offset));
    const effOff = Math.max(0, level.offset - minOff);
    const subjectGPA = Math.max(0, baseGPA - effOff);

    pts += (subjectGPA * (level.weightOverride ?? s.weight));
    crd += s.weight;
  });
  return crd > 0 ? pts / crd : 0;
};

const gpa = computed(calculateGPA);
watch(gpa, (v) => gsap.to(gpaDisplay, { duration: 0.6, value: v, ease: "expo.out" }));

const toggleMod = (mIdx: number, sIdx: number, limit: number) => {
  const key = `${selectedPreset.value!.id}_${mIdx}`;
  let current = [...(moduleChoices.value[key] || [])];
  if (current.includes(sIdx)) {
    current = current.filter(i => i !== sIdx);
  } else {
    current.push(sIdx);
    if (current.length > limit) current.shift();
  }
  moduleChoices.value[key] = current;
};
</script>

<template>
  <div class="neural-bg"></div>
  <div class="noise-overlay"></div>

  <div v-if="isLoading" class="min-h-screen flex flex-col items-center justify-center">
    <div class="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mb-6"></div>
    <p class="text-blue-500 font-black tracking-widest animate-pulse uppercase">Syncing Indexademics Engine...</p>
  </div>

  <div v-else class="min-h-screen p-4 md:p-12 text-white selection:bg-blue-500/30">
    <!-- Navbar -->
    <nav class="max-w-7xl mx-auto flex justify-between items-center mb-16">
      <div class="flex items-center gap-5 group cursor-pointer">
        <!-- IMAGE LOGO INTEGRATION -->
        <div class="relative">
          <div class="absolute -inset-2 bg-blue-600/20 blur-xl rounded-full opacity-0 group-hover:opacity-100 transition-opacity"></div>
          <img 
            src="/indexademics-logo.png" 
            alt="Indexademics Logo" 
            class="w-14 h-14 object-contain relative group-hover:scale-110 transition-transform duration-500"
          />
        </div>
        <div class="leading-none">
          <h1 class="text-3xl font-black tracking-tighter uppercase italic bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-400">Indexademics</h1>
          <p class="text-[9px] text-blue-400 font-bold tracking-[0.5em] ml-1">SHSID PRO ENGINE</p>
        </div>
      </div>
      <div class="hidden md:flex gap-4">
        <div class="px-6 py-2 glass-panel rounded-full text-[10px] font-black uppercase tracking-widest text-slate-500 border-white/5 bg-white/5">
          SHSID Official Utility
        </div>
      </div>
    </nav>

    <main class="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-10">
      <!-- Sidebar -->
      <aside class="lg:col-span-4 space-y-8">
        <div class="gpa-card glass-panel p-12 text-center border-white/10">
          <span class="text-[10px] font-black text-blue-400 uppercase tracking-[0.3em] mb-2 block">Weighted GPA Index</span>
          <div class="text-8xl font-black font-mono tracking-tighter text-white gpa-number-glow leading-none my-4">
            {{ gpaDisplay.toFixed(3) }}
          </div>
          <div class="flex justify-center gap-4">
            <div class="flex items-center gap-1.5 text-[10px] font-black text-blue-400 bg-blue-500/10 px-3 py-1 rounded-full border border-blue-500/20 tracking-tighter"><Zap size="12"/> INSTANT</div>
            <div class="flex items-center gap-1.5 text-[10px] font-black text-green-500 bg-green-500/10 px-3 py-1 rounded-full border border-green-500/20 tracking-tighter"><ShieldCheck size="12"/> PRECISE</div>
          </div>
        </div>

        <div class="glass-panel p-8 rounded-[2rem] border-white/5">
          <h3 class="text-xs font-black text-slate-500 uppercase mb-6 tracking-widest">Academic Grade Preset</h3>
          <div class="space-y-3">
            <button v-for="p in data?.presets" :key="p.id" @click="selectedPreset = p"
              :class="['w-full p-5 rounded-2xl text-left border-2 font-black transition-all group relative overflow-hidden', selectedPreset?.id === p.id ? 'bg-blue-600 border-blue-400 text-white shadow-2xl' : 'bg-white/5 border-transparent text-slate-500 hover:bg-white/10']">
              <div class="text-lg relative z-10">{{ p.name }}</div>
              <div class="text-[10px] uppercase opacity-40 group-hover:opacity-100 transition-opacity relative z-10">{{ p.subtitle || 'General Curriculum' }}</div>
            </button>
          </div>
        </div>

        <!-- Elective Module Logic -->
        <div v-if="selectedPreset" class="space-y-4">
          <div v-for="(mod, mIdx) in selectedPreset.modules" :key="mIdx">
            <div v-if="mod.type === 'choice'" class="glass-panel p-8 rounded-[2rem] border-white/5">
              <h4 class="text-[10px] font-black text-blue-500 uppercase mb-5 tracking-[0.2em]">{{ mod.name || 'Elective Choice' }}</h4>
              <div class="grid grid-cols-1 gap-3">
                <button v-for="(subj, sIdx) in mod.subjects" :key="sIdx"
                  @click="toggleMod(mIdx, sIdx, mod.selectionLimit || 1)"
                  :class="['p-4 rounded-xl text-xs font-black text-left border-2 transition-all flex justify-between items-center', (moduleChoices[`${selectedPreset.id}_${mIdx}`] || []).includes(sIdx) ? 'bg-blue-600 border-blue-400 text-white' : 'bg-black/40 border-transparent text-slate-600 hover:text-white']">
                  {{ subj.name }}
                  <div v-if="(moduleChoices[`${selectedPreset.id}_${mIdx}`] || []).includes(sIdx)" class="w-2.5 h-2.5 bg-blue-400 rounded-full shadow-[0_0_12px_#60a5fa] animate-pulse"></div>
                </button>
              </div>
            </div>
          </div>
        </div>
      </aside>

      <!-- Main Calculator Section -->
      <section class="lg:col-span-8 space-y-6">
        <div class="mb-12">
          <div class="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-[10px] font-black mb-6 uppercase tracking-widest">
            <Sparkles size="14" /> FASTEST CONVENIENTEST POWERFULEST
          </div>
          <h2 class="text-7xl font-black tracking-tighter leading-[0.9] text-white">
            Propagated Predictive <br><span class="text-blue-500">Intelligence Tool.</span>
          </h2>
        </div>

        <!-- Mode Toggle -->
        <div class="flex p-2 bg-slate-900/80 rounded-[1.5rem] border border-white/5 backdrop-blur-xl sticky top-8 z-50 shadow-2xl">
          <button @click="scoreMode = 'percentage'" :class="['flex-1 py-4 text-xs font-black rounded-xl transition-all', scoreMode === 'percentage' ? 'bg-white text-black shadow-xl' : 'text-slate-500 hover:text-white']">PERCENTAGE MODE</button>
          <button @click="scoreMode = 'letter'" :class="['flex-1 py-4 text-xs font-black rounded-xl transition-all', scoreMode === 'letter' ? 'bg-white text-black shadow-xl' : 'text-slate-500 hover:text-white']">LETTER GRADE MODE</button>
        </div>

        <!-- Render List -->
        <div class="space-y-6 pb-20">
          <div v-for="subj in activeSubjects" :key="subj.name" class="glass-panel p-8 md:p-12 rounded-[3rem] hover:border-blue-500/30 transition-all group">
            <div class="flex flex-col md:flex-row justify-between md:items-center gap-6 mb-12">
              <h4 class="text-4xl font-black group-hover:text-blue-400 transition-colors tracking-tight">{{ subj.name }}</h4>
              
              <div class="flex bg-black/60 p-1.5 rounded-2xl border border-white/10 overflow-x-auto no-scrollbar">
                <button v-for="(lvl, lIdx) in subj.levels" :key="lvl.name" 
                  @click="userSelections[`${selectedPreset!.id}_${subj.name}`] = { ...userSelections[`${selectedPreset!.id}_${subj.name}`], levelIdx: lIdx }"
                  :class="['px-5 py-2.5 rounded-xl text-[10px] font-black transition-all uppercase tracking-widest whitespace-nowrap', (userSelections[`${selectedPreset!.id}_${subj.name}`]?.levelIdx || 0) === lIdx ? 'bg-white text-black shadow-2xl' : 'text-slate-600 hover:text-slate-300']">
                  {{ lvl.name }}
                </button>
              </div>
            </div>

            <div class="grid grid-cols-4 md:grid-cols-8 gap-3">
              <button v-for="(score, sIdx) in (subj.customScoreToBaseGPAMap || data?.commonScoreMap || [])" :key="sIdx"
                @click="userSelections[`${selectedPreset!.id}_${subj.name}`] = { ...userSelections[`${selectedPreset!.id}_${subj.name}`], scoreIdx: sIdx }"
                :class="['grade-btn py-4 text-xs', (userSelections[`${selectedPreset!.id}_${subj.name}`]?.scoreIdx || 0) === sIdx ? 'active' : '']">
                {{ scoreMode === 'percentage' ? score.percentageName : score.letterName }}
              </button>
            </div>
          </div>
        </div>
      </section>
    </main>

    <!-- Professional Credits Footer -->
    <footer class="max-w-7xl mx-auto mt-24 pb-20 border-t border-white/10 pt-16">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-16 items-start">
        <div class="space-y-6">
          <div class="flex items-center gap-4">
            <img src="/indexademics-logo.png" alt="Indexademics Logo" class="w-10 h-10 object-contain" />
            <h4 class="font-black text-2xl tracking-tighter uppercase italic bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-500">SHSID GPA Calculator Online</h4>
          </div>
          <p class="text-[12px] text-slate-500 uppercase tracking-[0.2em] font-bold leading-relaxed max-w-md">
            The official predictive academic utility powered by the <span class="text-white">Indexademics Developer Team</span>. 
            Providing SHSID students with verified GPA analytics.
          </p>
        </div>
        
        <div class="flex flex-col md:items-end gap-10">
          <div class="flex flex-wrap gap-x-12 gap-y-6 justify-start md:justify-end text-right">
             <div class="space-y-3">
               <span class="text-[10px] font-black text-slate-600 uppercase tracking-widest block">Senior Developer & Maintainer</span>
               <a href="https://github.com/Ziqian-Huang0607" target="_blank" class="flex items-center gap-2 text-sm font-black text-blue-400 hover:text-white transition-all justify-end">
                 ZIQIAN HUANG <ExternalLink :size="14" />
               </a>
             </div>
             <div class="space-y-3">
               <span class="text-[10px] font-black text-slate-600 uppercase tracking-widest block">Original System & Core</span>
               <div class="flex gap-6 text-sm font-black text-slate-400 uppercase">
                 <span>WillUHD</span>
                 <span>Michel</span>
               </div>
             </div>
          </div>
          <div class="text-[10px] font-mono text-slate-800 font-black bg-white/5 px-4 py-1.5 rounded-full border border-white/5">
            PLATFORM // V2.5.0-SHSID-STABLE
          </div>
        </div>
      </div>
    </footer>
  </div>
</template>

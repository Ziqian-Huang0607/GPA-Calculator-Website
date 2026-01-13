<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useStorage } from '@vueuse/core'
import { Zap, ShieldCheck, Sparkles, ExternalLink, AlertTriangle } from 'lucide-vue-next'
import gsap from 'gsap'

// --- 1. LOCAL BACKUP IMPORT ---
// Vite's ?raw suffix imports the file content as a string at build time
import localPlist from './presets.plist?raw'

// --- 2. DATA MODELS ---
interface ScoreMap { percentageName: string; letterName: string; baseGPA: number; }
interface Level { name: string; offset: number; weightOverride?: number; }
interface Subject { name: string; weight: number; levels: Level[]; customScoreToBaseGPAMap?: ScoreMap[]; }
interface Module { type: 'core' | 'choice'; name?: string; selectionLimit?: number; subjects: Subject[]; }
interface Preset { id: string; name: string; subtitle?: string; modules: Module[]; }
interface RootData { commonScoreMap: ScoreMap[]; presets: Preset[]; lastUpdated?: string; }

// --- 3. ENGINE STATE ---
const data = ref<RootData | null>(null)
const selectedPreset = ref<Preset | null>(null)
const scoreMode = useStorage<'percentage' | 'letter' | 'ib'>('shsid-v-final-release-mode', 'percentage')
const moduleChoices = useStorage<Record<string, number[]>>('shsid-v-final-release-choices', {})
const userSelections = useStorage<Record<string, { levelIdx: number; scoreIdx: number }>>('shsid-v-final-release-selections', {})

const gpaDisplay = ref(0)
const isLoading = ref(true)
const isUsingLocalBackup = ref(false)

// --- 4. TYPESAFE PLIST PARSER ---
const parsePlist = (xml: string): any => {
  const parser = new DOMParser();
  const xmlDoc = parser.parseFromString(xml, "text/xml");
  const rootDict = xmlDoc.getElementsByTagName("dict")[0];
  const parseNode = (node: any): any => {
    const tag = node.tagName;
    if (tag === "dict") {
      const obj: any = {};
      const keys = Array.from(node.querySelectorAll(":scope > key"));
      const values = Array.from(node.querySelectorAll(":scope > key + *"));
      keys.forEach((k: any, i) => { obj[k.textContent] = parseNode(values[i]); });
      return obj;
    } else if (tag === "array") return Array.from(node.children).map(c => parseNode(c));
    else if (tag === "string") return node.textContent || "";
    else if (tag === "real" || tag === "integer") return Number(node.textContent || 0);
    else if (tag === "true") return true;
    else if (tag === "false") return false;
    return null;
  };
  return parseNode(rootDict);
};

// --- 5. DUAL-BOOT SYNC LOGIC ---
const initializeEngine = async () => {
  try {
    // Attempt 1: Fetch Live Data (CDN)
    const res = await fetch("https://edgeone.gh-proxy.org/https://raw.githubusercontent.com/WillUHD/GPAResources/refs/heads/main/presets.plist", {
        cache: 'no-store'
    });
    if (!res.ok) throw new Error("CDN Offline");
    
    const xml = await res.text();
    data.value = parsePlist(xml);
    console.log("Indexademics: Live Sync Successful");
  } catch (e) {
    // Attempt 2: Failover to Local Backup
    console.warn("Indexademics: CDN Sync Failed. Activating Local Backup...");
    data.value = parsePlist(localPlist);
    isUsingLocalBackup.value = true;
  } finally {
    if (data.value && data.value.presets) {
      selectedPreset.value = data.value.presets[0];
    }
    isLoading.value = false;
  }
};

onMounted(initializeEngine);

// --- 6. THE CORE ENGINE ---
const activeSubjects = computed(() => {
  if (!selectedPreset.value) return [];
  const list: Subject[] = [];
  selectedPreset.value.modules.forEach((mod, mIdx) => {
    if (mod.type === 'core') list.push(...mod.subjects);
    else if (mod.type === 'choice') {
      const key = `${selectedPreset.value?.id}_${mIdx}`;
      const chosen = moduleChoices.value[key] || [];
      chosen.forEach(idx => { if (mod.subjects[idx]) list.push(mod.subjects[idx]); });
    }
  });
  return list;
});

const calculateGPA = () => {
  if (!data.value || !selectedPreset.value) return 0;
  let pts = 0, crd = 0;
  activeSubjects.value.forEach(s => {
    const selKey = `${selectedPreset.value?.id}_${s.name}`;
    const sel = userSelections.value[selKey] || { levelIdx: 0, scoreIdx: 0 };
    const level = s.levels[sel.levelIdx] || s.levels[0] || { name: 'S', offset: 0 };
    const map = s.customScoreToBaseGPAMap || data.value?.commonScoreMap || [];
    const base = map[sel.scoreIdx]?.baseGPA || 0;
    const minOff = Math.min(...s.levels.map(l => l.offset));
    const subGPA = Math.max(0, base - Math.max(0, level.offset - minOff));
    pts += (subGPA * (level.weightOverride ?? s.weight));
    crd += s.weight;
  });
  return crd > 0 ? pts / crd : 0;
};

const gpaValue = computed(calculateGPA);
watch(gpaValue, (v) => gsap.to(gpaDisplay, { duration: 0.6, value: v, ease: "power2.out" }));

const toggleMod = (mIdx: number, sIdx: number, limit: number) => {
  if (!selectedPreset.value) return;
  const key = `${selectedPreset.value.id}_${mIdx}`;
  let cur = [...(moduleChoices.value[key] || [])];
  if (cur.includes(sIdx)) moduleChoices.value[key] = cur.filter(i => i !== sIdx);
  else { cur.push(sIdx); if (cur.length > limit) cur.shift(); moduleChoices.value[key] = cur; }
};
</script>

<template>
  <div class="neural-bg"></div>
  <div class="noise-overlay"></div>

  <div v-if="isLoading" class="min-h-screen flex items-center justify-center">
    <p class="text-blue-500 font-black animate-pulse uppercase tracking-[0.3em]">Propagating SHSID Intelligence...</p>
  </div>

  <div v-else class="min-h-screen p-4 md:p-12 text-white selection:bg-blue-500/30">
    <!-- Navbar -->
    <nav class="max-w-7xl mx-auto flex justify-between items-center mb-16">
      <div class="flex items-center gap-5 group cursor-pointer">
        <img src="/indexademics-logo.png" alt="Indexademics Logo" class="w-14 h-14 object-contain group-hover:scale-110 transition-transform duration-500" />
        <div class="leading-none">
          <h1 class="text-3xl font-black uppercase italic tracking-tighter bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-500">Indexademics</h1>
          <p class="text-[9px] text-blue-400 font-bold tracking-[0.5em] ml-1">SHSID PRO ENGINE</p>
        </div>
      </div>
      <div class="hidden md:flex gap-4">
        <div v-if="isUsingLocalBackup" class="px-4 py-2 bg-yellow-500/10 border border-yellow-500/20 rounded-full text-[9px] font-black uppercase text-yellow-500">
            Local Backup Mode
        </div>
        <div class="px-6 py-2 glass-panel rounded-full text-[10px] font-black uppercase tracking-widest text-slate-500 border-white/5 bg-white/5">
          SHSID Official Utility // V2.5.0
        </div>
      </div>
    </nav>

    <main class="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-10">
      <!-- Left Sidebar -->
      <aside class="lg:col-span-4 space-y-8">
        <!-- GPA Card + Disclaimer -->
        <div class="gpa-card glass-panel p-10 text-center rounded-[2.5rem] border-white/10">
          <span class="text-[10px] font-black text-blue-400 uppercase tracking-[0.3em] mb-2 block">Weighted GPA Index</span>
          <div class="text-8xl font-black font-mono tracking-tighter text-white gpa-number-glow leading-none my-4">
            {{ gpaDisplay.toFixed(3) }}
          </div>
          
          <!-- OFFICIAL DISCLAIMER BLOCK -->
          <div class="mt-6 mb-6 px-4 py-3 bg-blue-500/5 border border-blue-500/20 rounded-2xl text-left">
            <div class="flex items-center gap-2 text-blue-400 mb-1">
              <AlertTriangle :size="14" />
              <span class="text-[9px] font-black uppercase tracking-widest">Unofficial Reference</span>
            </div>
            <p class="text-[9px] text-slate-500 font-bold uppercase leading-relaxed">
              SHSID does not propose GPA scores to universities. This result is an inofficial prediction only.
            </p>
          </div>

          <div class="flex justify-center gap-3">
            <div class="flex items-center gap-1.5 text-[10px] font-black text-blue-400 bg-blue-500/10 px-3 py-1 rounded-full border border-blue-500/20 tracking-tighter uppercase"><Zap size="12"/> Instant</div>
            <div class="flex items-center gap-1.5 text-[10px] font-black text-green-500 bg-green-500/10 px-3 py-1 rounded-full border border-green-500/20 tracking-tighter uppercase"><ShieldCheck size="12"/> Precise</div>
          </div>
        </div>

        <!-- Curriculum Presets -->
        <div class="glass-panel p-8 rounded-[2rem] border-white/5">
          <h3 class="text-xs font-black text-slate-500 uppercase mb-6 tracking-widest">Academic Curriculum</h3>
          <div class="space-y-3">
            <button v-for="p in data?.presets" :key="p.id" @click="selectedPreset = p"
              :class="['w-full p-5 rounded-2xl text-left border-2 font-black transition-all group relative overflow-hidden', selectedPreset?.id === p.id ? 'bg-blue-600 border-blue-400 text-white shadow-2xl' : 'bg-white/5 border-transparent text-slate-500 hover:bg-white/10']">
              <div class="text-lg">{{ p.name }}</div>
              <div class="text-[10px] uppercase opacity-40 group-hover:opacity-100 transition-opacity">{{ p.subtitle || 'General Curriculum' }}</div>
            </button>
          </div>
        </div>

        <!-- Choice Electives -->
        <div v-if="selectedPreset" class="space-y-4">
          <div v-for="(mod, mIdx) in selectedPreset.modules" :key="mIdx">
            <div v-if="mod.type === 'choice'" class="glass-panel p-8 rounded-[2rem] border-white/5">
              <h4 class="text-[10px] font-black text-blue-500 uppercase mb-5 tracking-[0.2em]">{{ mod.name || 'Elective Choice' }}</h4>
              <div class="grid grid-cols-1 gap-3">
                <button v-for="(subj, sIdx) in mod.subjects" :key="sIdx"
                  @click="toggleMod(mIdx, sIdx, mod.selectionLimit || 1)"
                  :class="['p-4 rounded-xl text-xs font-black text-left border-2 transition-all flex justify-between items-center', (moduleChoices[`${selectedPreset.id}_${mIdx}`] || []).includes(sIdx) ? 'bg-blue-600 border-blue-400 text-white shadow-lg' : 'bg-black/40 border-transparent text-slate-600 hover:text-white hover:bg-white/5']">
                  {{ subj.name }}
                  <div v-if="(moduleChoices[`${selectedPreset.id}_${mIdx}`] || []).includes(sIdx)" class="w-2.5 h-2.5 bg-blue-400 rounded-full shadow-[0_0_12px_#60a5fa] animate-pulse"></div>
                </button>
              </div>
            </div>
          </div>
        </div>
      </aside>

      <!-- Main Calculator -->
      <section class="lg:col-span-8 space-y-6">
        <div class="mb-12">
          <div class="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-[10px] font-black mb-6 uppercase tracking-widest">
            <Sparkles size="14" /> FASTEST CONVENIENTEST POWERFULEST
          </div>
          <h2 class="text-7xl font-black tracking-tighter leading-[0.9] text-white">
            Propagated Predictive <br><span class="text-blue-500">Intelligence Tool.</span>
          </h2>
        </div>

        <!-- Mode Toggles -->
        <div class="flex p-2 bg-slate-900/80 rounded-[1.5rem] border border-white/5 backdrop-blur-xl sticky top-8 z-50 shadow-2xl">
          <button @click="scoreMode = 'percentage'" :class="['flex-1 py-4 text-[10px] md:text-xs font-black rounded-xl transition-all', scoreMode === 'percentage' ? 'bg-white text-black shadow-xl' : 'text-slate-500 hover:text-white']">PERCENTAGE</button>
          <button @click="scoreMode = 'letter'" :class="['flex-1 py-4 text-[10px] md:text-xs font-black rounded-xl transition-all', scoreMode === 'letter' ? 'bg-white text-black shadow-xl' : 'text-slate-500 hover:text-white']">LETTER GRADE</button>
          <button @click="scoreMode = 'ib'" :class="['flex-1 py-4 text-[10px] md:text-xs font-black rounded-xl transition-all', scoreMode === 'ib' ? 'bg-white text-black shadow-xl' : 'text-slate-500 hover:text-white']">IB GRADE (1-7)</button>
        </div>

        <!-- Subject Rows -->
        <div class="space-y-6 pb-20">
          <div v-for="subj in activeSubjects" :key="subj.name" class="glass-panel p-8 md:p-12 rounded-[3rem] hover:border-blue-500/30 transition-all group">
            <div class="flex flex-col md:flex-row justify-between md:items-center gap-6 mb-12">
              <h4 class="text-4xl font-black group-hover:text-blue-400 transition-colors tracking-tight leading-none">{{ subj.name }}</h4>
              <div class="flex bg-black/60 p-1.5 rounded-2xl border border-white/10 overflow-x-auto no-scrollbar">
                <button v-for="(lvl, lIdx) in subj.levels" :key="lvl.name" 
                  @click="userSelections[`${selectedPreset?.id}_${subj.name}`] = { 
                    scoreIdx: userSelections[`${selectedPreset?.id}_${subj.name}`]?.scoreIdx ?? 0,
                    levelIdx: lIdx 
                  }"
                  :class="['px-5 py-2.5 rounded-xl text-[10px] font-black transition-all uppercase whitespace-nowrap tracking-widest', (userSelections[`${selectedPreset?.id}_${subj.name}`]?.levelIdx || 0) === lIdx ? 'bg-white text-black shadow-2xl' : 'text-slate-600 hover:text-slate-300']">
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

    <!-- Professional Footer -->
    <footer class="max-w-7xl mx-auto mt-24 pb-20 border-t border-white/10 pt-16">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-16 items-start">
        <div class="space-y-6">
          <div class="flex items-center gap-4">
            <img src="/indexademics-logo.png" alt="Indexademics Logo" class="w-10 h-10 object-contain" />
            <h4 class="font-black text-2xl tracking-tighter uppercase italic bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-500 leading-none">SHSID GPA Online</h4>
          </div>
          <p class="text-[11px] text-slate-500 uppercase tracking-[0.2em] font-bold leading-relaxed max-w-md">
            The official academic intelligence utility powered by the <span class="text-white">Indexademics Developer Team</span>. 
            Providing SHSID students with verified academic reference tools.
          </p>
        </div>
        
        <div class="flex flex-col md:items-end gap-10">
          <div class="flex flex-wrap gap-x-12 gap-y-6 justify-start md:justify-end text-right">
             <div class="space-y-3">
               <span class="text-[10px] font-black text-slate-600 uppercase tracking-widest block mb-1">Chief Maintainer</span>
               <a href="https://github.com/Ziqian-Huang0607" target="_blank" class="flex items-center gap-2 text-sm font-black text-blue-400 hover:text-white transition-all justify-end">
                 ZIQIAN HUANG <ExternalLink :size="14" />
               </a>
             </div>
             <div class="space-y-3">
               <span class="text-[10px] font-black text-slate-600 uppercase tracking-widest block mb-1">Original Project Foundations</span>
               <div class="flex gap-6 text-sm font-black text-slate-400 uppercase">
                 <span>WillUHD</span>
                 <span>Michel</span>
               </div>
             </div>
          </div>
          <div class="text-[10px] font-mono text-slate-800 font-black bg-white/5 px-4 py-1.5 rounded-full border border-white/5">
            PLATFORM // V2.5.0-SHSID-PRO
          </div>
        </div>
      </div>
    </footer>
  </div>
</template>
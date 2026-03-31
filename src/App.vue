<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useStorage } from '@vueuse/core'
import { Zap, ShieldCheck, Sparkles, ExternalLink, AlertTriangle } from 'lucide-vue-next'
import gsap from 'gsap'

// --- 1. LOCAL FALLBACK IMPORT ---
// Imports the XML plist as a raw string for fallback purposes
import localPlistRaw from './presets.plist?raw'

// --- 2. DATA MODELS ---
interface ScoreMap { percentageName: string; letterName: string; baseGPA: number; }
interface Level { name: string; offset: number; weightOverride?: number; tags?: string[]; }
interface Subject { name: string; weight: number; levels: Level[]; customScoreToBaseGPAMap?: ScoreMap[]; }
interface Module { type: 'core' | 'choice'; name?: string; selectionLimit?: number; subjects: Subject[]; }
interface Preset { id: string; name: string; subtitle?: string; modules: Module[]; }
interface RootData { 
  catalogName?: string;
  version?: string;
  commonScoreMap: ScoreMap[]; 
  extendedScoreMaps?: Record<string, ScoreMap[]>; 
  presets: Preset[]; 
}

// --- 3. ENGINE STATE ---
const data = ref<RootData | null>(null)
const selectedPreset = ref<Preset | null>(null)
const scoreMode = useStorage<'percentage' | 'letter' | 'ib'>('indexademics-mode', 'percentage')
const moduleChoices = useStorage<Record<string, number[]>>('indexademics-choices', {})
const userSelections = useStorage<Record<string, { levelIdx: number; scoreIdx: number }>>('indexademics-selections', {})

const gpaDisplay = ref(0)
const isLoading = ref(true)
const dataSourceDebug = ref<string>('INITIALIZING...')

// --- 4. PARSERS ---

// A. Advanced DSL Parser (for your remote course.gpa file)
const parseGpaFormat = (rawText: string): RootData => {
  const cleanJson = rawText
    .replace(/\/\/.*$/gm, '') 
    .replace(/\/\*[\s\S]*?\*\//g, '') 
    .replace(/,\s*([\]}])/g, '$1'); 

  const gpaData = JSON.parse(cleanJson);

  const mapScoreMap = (smArray: any[]) => (smArray || []).map((sm: any) => ({
    percentageName: sm.percent,
    letterName: sm.letter,
    baseGPA: sm.gpa
  }));

  const extendedScoreMaps = {
    AP: mapScoreMap(gpaData.scoreMaps?.AP),
    ASA2: mapScoreMap(gpaData.scoreMaps?.ASA2),
    IB: mapScoreMap(gpaData.scoreMaps?.IB)
  };

  const templates: any = {};
  if (gpaData.templates) {
    gpaData.templates.forEach((t: any) => { templates[t.id] = t; });
  }

  const presets = (gpaData.presets || []).map((p: any) => ({
    id: p.id,
    name: p.name,
    subtitle: p.subtitle || p.track?.displayName || '',
    modules: (p.modules || []).map((m: any) => ({
      type: m.type,
      name: m.name,
      selectionLimit: m.limit || m.selectionLimit || 1,
      subjects: (m.subjects || []).map((s: any) => {
        const tpl = s.template ? templates[s.template] : null;
        const weight = s.weight !== undefined ? s.weight : (tpl?.weight || 0);
        const rawLevels = s.levels || tpl?.levels || [];
        
        return {
          name: s.name,
          weight: weight,
          levels: rawLevels.map((l: any) => ({
            name: l.name,
            offset: l.offset,
            weightOverride: l.weightOverride,
            tags: l.tags || tpl?.levels?.[0]?.tags
          }))
        };
      })
    }))
  }));

  return {
    catalogName: gpaData.catalogName || 'Indexademics Catalog',
    version: gpaData.version || '4.0',
    commonScoreMap: mapScoreMap(gpaData.scoreMaps?.default),
    extendedScoreMaps,
    presets
  };
};

// B. Plist Parser (for the local fallback presets.plist)
const parsePlist = (xml: string): RootData => {
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

// --- 5. INITIALIZE ENGINE (DUAL BOOT LOGIC) ---
const initializeEngine = async () => {
  try {
    dataSourceDebug.value = 'FETCHING REMOTE REPO...';
    // Attempt to load from YOUR Github repo
    const res = await fetch("https://edgeone.gh-proxy.org/https://raw.githubusercontent.com/Ziqian-Huang0607/GPA-Calc-Resources/main/course.gpa", {
        cache: 'no-store'
    });
    
    if (!res.ok) throw new Error("CDN HTTP Error: " + res.status);
    
    const rawText = await res.text();
    data.value = parseGpaFormat(rawText);
    dataSourceDebug.value = 'REMOTE: github.com/Ziqian-Huang0607/.../course.gpa (SUCCESS)';
    console.log("Indexademics: Remote source loaded successfully.");

  } catch (e) {
    console.warn("Indexademics: Remote fetch failed. Activating local Plist fallback.", e);
    try {
      dataSourceDebug.value = 'FALLBACK: local presets.plist (LOADING...)';
      data.value = parsePlist(localPlistRaw);
      dataSourceDebug.value = 'FALLBACK: local presets.plist (SUCCESS)';
    } catch (plistErr) {
      console.error("Indexademics: Local fallback failed to parse.", plistErr);
      dataSourceDebug.value = 'FATAL ERROR: BOTH SOURCES FAILED';
    }
  } finally {
    if (data.value && data.value.presets && data.value.presets.length > 0) {
      selectedPreset.value = data.value.presets.find(p => p.name === 'Grade 11') || data.value.presets[0];
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

const getScoreMapForSubject = (presetId: string, subj: Subject) => {
  const sel = userSelections.value[`${presetId}_${subj.name}`] || { levelIdx: 0, scoreIdx: 0 };
  const level = subj.levels[sel.levelIdx] || subj.levels[0];
  
  if (level?.tags?.includes('AP') && data.value?.extendedScoreMaps?.AP) return data.value.extendedScoreMaps.AP;
  if (level?.tags?.includes('ASA2') && data.value?.extendedScoreMaps?.ASA2) return data.value.extendedScoreMaps.ASA2;
  if (level?.tags?.includes('IB') && data.value?.extendedScoreMaps?.IB) return data.value.extendedScoreMaps.IB;
  
  return subj.customScoreToBaseGPAMap || data.value?.commonScoreMap || [];
};

const calculateGPA = () => {
  if (!data.value || !selectedPreset.value) return 0;
  let pts = 0, crd = 0;
  activeSubjects.value.forEach(s => {
    const presetId = selectedPreset.value!.id;
    const selKey = `${presetId}_${s.name}`;
    const sel = userSelections.value[selKey] || { levelIdx: 0, scoreIdx: 0 };
    
    const level = s.levels[sel.levelIdx] || s.levels[0] || { name: 'S', offset: 0 };
    const map = getScoreMapForSubject(presetId, s);
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
    <div class="text-center">
      <p class="text-blue-500 font-black animate-pulse uppercase tracking-[0.3em] mb-4">Propagating Indexademics Core...</p>
      <p class="text-[10px] text-slate-500 font-mono">{{ dataSourceDebug }}</p>
    </div>
  </div>

  <div v-else class="min-h-screen p-4 md:p-12 text-white selection:bg-blue-500/30">
    <!-- Navbar -->
    <nav class="max-w-7xl mx-auto flex justify-between items-center mb-16">
      <div class="flex items-center gap-5 group cursor-pointer">
        <img src="/indexademics-logo.png" alt="Indexademics Logo" class="w-14 h-14 object-contain group-hover:scale-110 transition-transform duration-500" />
        <div class="leading-none">
          <h1 class="text-3xl font-black uppercase italic tracking-tighter bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-500">Indexademics</h1>
          <p class="text-[9px] text-blue-400 font-bold tracking-[0.5em] ml-1">PRO ENGINE EDITION</p>
        </div>
      </div>
      <div class="hidden md:flex gap-4">
        <div class="px-6 py-2 glass-panel rounded-full text-[10px] font-black uppercase tracking-widest text-blue-400 border-blue-500/20 bg-blue-500/5 shadow-[0_0_15px_rgba(59,130,246,0.15)]">
          Self-Hosted Core // V{{ data?.version || '4.0' }}
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
              This result is a predictive calculation powered exclusively by Indexademics.
            </p>
          </div>

          <div class="flex justify-center gap-3">
            <div class="flex items-center gap-1.5 text-[10px] font-black text-blue-400 bg-blue-500/10 px-3 py-1 rounded-full border border-blue-500/20 tracking-tighter uppercase"><Zap size="12"/> Instant</div>
            <div class="flex items-center gap-1.5 text-[10px] font-black text-green-500 bg-green-500/10 px-3 py-1 rounded-full border border-green-500/20 tracking-tighter uppercase"><ShieldCheck size="12"/> Independent</div>
          </div>
        </div>

        <!-- Curriculum Presets -->
        <div class="glass-panel p-8 rounded-[2rem] border-white/5">
          <h3 class="text-xs font-black text-slate-500 uppercase mb-6 tracking-widest">Academic Curriculum</h3>
          <div class="space-y-3">
            <button v-for="p in data?.presets" :key="p.id" @click="selectedPreset = p"
              :class="['w-full p-5 rounded-2xl text-left border-2 font-black transition-all group relative overflow-hidden', selectedPreset?.id === p.id ? 'bg-blue-600 border-blue-400 text-white shadow-[0_0_20px_rgba(59,130,246,0.3)]' : 'bg-white/5 border-transparent text-slate-500 hover:bg-white/10']">
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
            <Sparkles size="14" /> INDEXADEMICS ULTIMATE ARCHITECTURE
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
                    scoreIdx: 0, 
                    levelIdx: lIdx 
                  }"
                  :class="['px-5 py-2.5 rounded-xl text-[10px] font-black transition-all uppercase whitespace-nowrap tracking-widest', (userSelections[`${selectedPreset?.id}_${subj.name}`]?.levelIdx || 0) === lIdx ? 'bg-white text-black shadow-2xl' : 'text-slate-600 hover:text-slate-300']">
                  {{ lvl.name }}
                </button>
              </div>
            </div>

            <div class="grid grid-cols-4 md:grid-cols-8 gap-3">
              <button v-for="(score, sIdx) in getScoreMapForSubject(selectedPreset?.id || '', subj)" :key="sIdx"
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
    <footer class="max-w-7xl mx-auto mt-24 pb-10 border-t border-white/10 pt-16">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-16 items-start">
        <div class="space-y-6">
          <div class="flex items-center gap-4">
            <img src="/indexademics-logo.png" alt="Indexademics Logo" class="w-10 h-10 object-contain" />
            <h4 class="font-black text-2xl tracking-tighter uppercase italic bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-500 leading-none">Indexademics Online</h4>
          </div>
          <p class="text-[11px] text-slate-500 uppercase tracking-[0.2em] font-bold leading-relaxed max-w-md">
            The independent academic intelligence utility powered entirely by the <span class="text-white">Indexademics Developer Team</span>. 
            Built for ultimate reliability and scale.
          </p>
        </div>
        
        <div class="flex flex-col md:items-end gap-10">
          <div class="flex flex-wrap gap-x-12 gap-y-6 justify-start md:justify-end text-right">
             <div class="space-y-3">
               <span class="text-[10px] font-black text-slate-600 uppercase tracking-widest block mb-1">Chief Architect</span>
               <a href="https://github.com/Ziqian-Huang0607" target="_blank" class="flex items-center gap-2 text-sm font-black text-blue-400 hover:text-white transition-all justify-end">
                 ZIQIAN HUANG <ExternalLink :size="14" />
               </a>
             </div>
          </div>
          <div class="text-[10px] font-mono text-slate-800 font-black bg-white/5 px-4 py-1.5 rounded-full border border-white/5">
            PLATFORM // V{{ data?.version || '4.0.0' }}-ULTIMATE
          </div>
        </div>
      </div>
      
      <!-- DEBUG STATEMENT SECTION -->
      <div class="mt-16 text-center text-[9px] text-slate-700 font-mono uppercase tracking-widest border-t border-white/5 pt-6">
        [ SYSTEM METRIC // DATA SOURCE: {{ dataSourceDebug }} ]
      </div>
    </footer>
  </div>
</template>

<style scoped>
.grade-btn {
  @apply bg-black/40 border-2 border-transparent text-slate-500 rounded-xl font-black transition-all hover:bg-white/5 hover:text-slate-300;
}
.grade-btn.active {
  @apply bg-blue-500 text-white border-blue-400 shadow-[0_0_15px_rgba(59,130,246,0.4)];
}
.glass-panel {
  @apply bg-white/[0.02] backdrop-blur-3xl border;
}
.gpa-number-glow {
  text-shadow: 0 0 40px rgba(255, 255, 255, 0.2);
}
.no-scrollbar::-webkit-scrollbar {
  display: none;
}
.no-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>

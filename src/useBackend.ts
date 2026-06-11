import { ref, computed } from 'vue'
import type {
  CourseModel,
  Preset,
  Subject,
  Module,
  ScoreEntry,
  Level,
  Template,
} from './types'
import { fetchCatalog } from './updater'

function subjectKey(subj: Subject): string {
  return subj.id || subj.name
}

function safeGet<T>(arr: T[] | undefined, idx: number): T | undefined {
  return arr && idx >= 0 && idx < arr.length ? arr[idx] : undefined
}

function deepClone<T>(obj: T): T {
  return JSON.parse(JSON.stringify(obj))
}

// ── Reactive State (module-level singletons) ──
const root = ref<CourseModel | null>(null)
const currentPreset = ref<Preset | null>(null)
const activeSubjects = ref<Subject[]>([])
const calculationResultText = ref('Loading...')
const isInvalidated = ref(false)
const isLoading = ref(true)
const scoreMapsById = ref<Record<string, ScoreEntry[]>>({})
const defaultScoreMapId = ref('default')
const scoreDisplay = ref<'percentage' | 'letter'>('percentage')
const trackActive = ref(true)
const trackToggleByPreset = ref<Record<string, boolean>>({})
const selectedLevelIndicesBySubject = ref<Record<string, number>>({})
const selectedScoreIndicesBySubject = ref<Record<string, number>>({})
const selectedScoreMapIdBySubject = ref<Record<string, string>>({})
const selectionsByModule = ref<
  Record<number, { itemIndex: number; subjectId: string }[]>
>({})
const disabledIndicesByModule = ref<Record<number, Set<number>>>({})
const effectiveLimitsByModule = ref<Record<number, number>>({})
const requirementWarning = ref<string | null>(null)
const requiredSubjectIDs = ref<Set<string>>(new Set())
const modulesRequiringSelection = ref<Set<number>>(new Set())

// ── Persistence ──
function persistSelections() {
  try {
    const p = currentPreset.value
    if (!p) return
    const allIds = new Set(p.modules.flatMap((m) => m.subjects.map(subjectKey)))
    const filterValid = (dict: Record<string, number>) => {
      const out: Record<string, number> = {}
      for (const [k, v] of Object.entries(dict)) {
        if (allIds.has(k)) out[k] = v
      }
      return out
    }
    selectedLevelIndicesBySubject.value = filterValid(selectedLevelIndicesBySubject.value)
    selectedScoreIndicesBySubject.value = filterValid(selectedScoreIndicesBySubject.value)
    selectedScoreMapIdBySubject.value = filterValid(selectedScoreMapIdBySubject.value)
    localStorage.setItem(`config_${p.id}_levels`, JSON.stringify(selectedLevelIndicesBySubject.value))
    localStorage.setItem(`config_${p.id}_scores`, JSON.stringify(selectedScoreIndicesBySubject.value))
    localStorage.setItem(`config_${p.id}_scoreMapChoice`, JSON.stringify(selectedScoreMapIdBySubject.value))
    localStorage.setItem(`config_${p.id}_trackToggle`, JSON.stringify(trackToggleByPreset.value[p.id] ?? true))
    for (let i = 0; i < p.modules.length; i++) {
      const entries = selectionsByModule.value[i] || []
      localStorage.setItem(`config_${p.id}_mod_ids_${i}`, JSON.stringify(entries.map((e) => e.subjectId)))
    }
  } catch (e) {
    console.warn('[persistSelections] error:', e)
  }
}

function loadPersistedSelections(presetId: string, modules: Module[]) {
  const loadDict = (key: string): Record<string, number> => {
    try {
      const raw = localStorage.getItem(key)
      return raw ? JSON.parse(raw) : {}
    } catch {
      return {}
    }
  }
  selectedLevelIndicesBySubject.value = loadDict(`config_${presetId}_levels`)
  selectedScoreIndicesBySubject.value = loadDict(`config_${presetId}_scores`)
  selectedScoreMapIdBySubject.value = loadDict(`config_${presetId}_scoreMapChoice`)
  selectionsByModule.value = {}
  for (let i = 0; i < modules.length; i++) {
    const idsRaw = localStorage.getItem(`config_${presetId}_mod_ids_${i}`)
    if (idsRaw) {
      try {
        const ids: string[] = JSON.parse(idsRaw)
        selectionsByModule.value[i] = ids
          .map((sid) => {
            const idx = modules[i].subjects.findIndex((s) => subjectKey(s) === sid)
            return idx >= 0 ? { itemIndex: idx, subjectId: sid } : null
          })
          .filter(Boolean) as { itemIndex: number; subjectId: string }[]
      } catch {
        selectionsByModule.value[i] = []
      }
    } else {
      selectionsByModule.value[i] = []
    }
  }
  const trackRaw = localStorage.getItem(`config_${presetId}_trackToggle`)
  trackToggleByPreset.value[presetId] = trackRaw !== null ? JSON.parse(trackRaw) : true
  trackActive.value = trackToggleByPreset.value[presetId] ?? true
}

function ensureDefaultIndices(subjects: Subject[]) {
  for (const subj of subjects) {
    const key = subjectKey(subj)
    if (selectedLevelIndicesBySubject.value[key] === undefined)
      selectedLevelIndicesBySubject.value[key] = 0
    if (selectedScoreIndicesBySubject.value[key] === undefined)
      selectedScoreIndicesBySubject.value[key] = 0
  }
}

function rebuildActiveSubjects() {
  const p = currentPreset.value
  if (!p) {
    activeSubjects.value = []
    return
  }
  const list: Subject[] = []
  for (let mIdx = 0; mIdx < p.modules.length; mIdx++) {
    const m = p.modules[mIdx]
    if (m.type === 'core') {
      list.push(...m.subjects)
    } else {
      const entries = selectionsByModule.value[mIdx] || []
      for (const entry of entries) {
        if (m.subjects[entry.itemIndex]) list.push(m.subjects[entry.itemIndex])
      }
    }
  }
  activeSubjects.value = list
  ensureDefaultIndices(list)
}

function scoreMapForSubject(subj: Subject): ScoreEntry[] {
  if (subj.customMap && subj.customMap.length > 0) return subj.customMap
  const p = currentPreset.value
  if (p?.track && trackActive.value) {
    const key = subjectKey(subj)
    const lvlIdx = selectedLevelIndicesBySubject.value[key] ?? 0
    const lvl = safeGet(subj.levels, lvlIdx)
    if (lvl?.tags?.includes(p.track.id)) {
      const trackMap = scoreMapsById.value[p.track.scoreMapId]
      if (trackMap) return trackMap
    }
  }
  return scoreMapsById.value[subj.scoreMapId ?? ''] ?? scoreMapsById.value[defaultScoreMapId.value] ?? []
}

function evaluateRulesInternal() {
  const p = currentPreset.value
  if (!p) return
  const allIds = new Set<string>()
  const activeTagCounts: Record<string, number> = {}
  for (const subj of activeSubjects.value) {
    allIds.add(subjectKey(subj))
    const key = subjectKey(subj)
    const lvlIdx = selectedLevelIndicesBySubject.value[key] ?? 0
    const lvl = safeGet(subj.levels, lvlIdx)
    const tags = new Set(subj.tags ?? [])
    if (lvl?.tags) lvl.tags.forEach((t) => tags.add(t))
    for (const t of tags) activeTagCounts[t] = (activeTagCounts[t] ?? 0) + 1
  }
  const modCounts: Record<number, number> = {}
  for (let i = 0; i < p.modules.length; i++) {
    const m = p.modules[i]
    modCounts[i] = m.type === 'core' ? m.subjects.length : (selectionsByModule.value[i]?.length ?? 0)
  }
  const effLimits: Record<number, number> = {}
  for (let i = 0; i < p.modules.length; i++) effLimits[i] = p.modules[i].limit ?? 1
  const excludedTags = new Set<string>()
  const excludedIds = new Set<string>()
  const cappedTags = new Set<string>()
  const rules = p.rules
  if (rules) {
    if (rules.exclusionTags) {
      for (const group of rules.exclusionTags) {
        if (group.some((t) => (activeTagCounts[t] ?? 0) > 0)) {
          group.filter((t) => (activeTagCounts[t] ?? 0) === 0).forEach((t) => excludedTags.add(t))
        }
      }
    }
    if (rules.exclusionIds) {
      for (const group of rules.exclusionIds) {
        if (group.some((id) => allIds.has(id))) {
          group.filter((id) => !allIds.has(id)).forEach((id) => excludedIds.add(id))
        }
      }
    }
    if (rules.tagLimits) {
      for (const tl of rules.tagLimits) {
        if (tl.limit > 1 && (activeTagCounts[tl.tag] ?? 0) >= tl.limit) cappedTags.add(tl.tag)
      }
    }
    if (rules.dynamicLimits) {
      for (const dl of rules.dynamicLimits) {
        const count = modCounts[dl.triggerModuleIndex] ?? 0
        let condMet = false
        if (dl.triggerCondition.startsWith('>=')) {
          condMet = count >= parseInt(dl.triggerCondition.slice(2).trim())
        } else if (dl.triggerCondition.startsWith('==')) {
          condMet = count === parseInt(dl.triggerCondition.slice(2).trim())
        }
        if (condMet) {
          for (const target of dl.targetModuleIndices) effLimits[target] = dl.newLimit
        }
      }
    }
    if (rules.requirements) {
      for (const req of rules.requirements) {
        if (
          (activeTagCounts[req.triggerTag] ?? 0) > 0 &&
          !req.requiredAnyTag.some((t) => (activeTagCounts[t] ?? 0) > 0)
        ) {
          requirementWarning.value = req.errorMessage
        }
      }
    }
    if (rules.conditionalRequirements) {
      for (const cond of rules.conditionalRequirements) {
        const trigger = cond.trigger
        let idTrig = false
        let modTrig = false
        if (trigger.selectedSubjectIds) idTrig = trigger.selectedSubjectIds.some((id) => allIds.has(id))
        if (trigger.moduleConditions) {
          modTrig = trigger.moduleConditions.every((mc) => {
            const c = modCounts[mc.moduleIndex] ?? 0
            if (mc.exactCount !== undefined && c !== mc.exactCount) return false
            if (mc.minSelected !== undefined && c < mc.minSelected) return false
            return true
          })
        }
        const triggered =
          trigger.selectedSubjectIds && trigger.moduleConditions
            ? idTrig && modTrig
            : trigger.selectedSubjectIds
              ? idTrig
              : modTrig
        if (triggered) {
          if (cond.enforceModuleLimits) {
            for (const ml of cond.enforceModuleLimits) effLimits[ml.moduleIndex] = ml.newLimit
          }
          if (cond.requiresAnyOfSubjectIds && cond.requiresAnyOfSubjectIds.length > 0) {
            if (!cond.requiresAnyOfSubjectIds.some((id) => allIds.has(id))) {
              if (!requirementWarning.value) requirementWarning.value = cond.errorMessage ?? 'Requirement not met'
            }
          }
        }
      }
    }
  }
  for (let i = 0; i < p.modules.length; i++) {
    const m = p.modules[i]
    if ((m.minSelection ?? 0) > (selectionsByModule.value[i]?.length ?? 0)) {
      modulesRequiringSelection.value.add(i)
    }
  }
  const disabled: Record<number, Set<number>> = {}
  for (let mIdx = 0; mIdx < p.modules.length; mIdx++) {
    const m = p.modules[mIdx]
    const d = new Set<number>()
    const sel = new Set((selectionsByModule.value[mIdx] ?? []).map((e) => e.itemIndex))
    for (let sIdx = 0; sIdx < m.subjects.length; sIdx++) {
      if (sel.has(sIdx)) continue
      const subj = m.subjects[sIdx]
      const key = subjectKey(subj)
      if (effLimits[mIdx] === 0 || excludedIds.has(key) || allIds.has(key)) {
        d.add(sIdx)
        continue
      }
      const tags = subj.tags ?? []
      if (tags.some((t) => excludedTags.has(t) || cappedTags.has(t))) d.add(sIdx)
    }
    disabled[mIdx] = d
  }
  disabledIndicesByModule.value = disabled
  effectiveLimitsByModule.value = effLimits
}

function recomputeGPA() {
  if (!currentPreset.value) {
    calculationResultText.value = 'No preset selected'
    return
  }
  let pts = 0
  let wgt = 0
  for (const subj of activeSubjects.value) {
    const key = subjectKey(subj)
    const lvlIdx = selectedLevelIndicesBySubject.value[key] ?? 0
    const lvl: Level = safeGet(subj.levels, lvlIdx) ?? { name: '', offset: 0 }
    const map = scoreMapForSubject(subj)
    const scoreIdx = selectedScoreIndicesBySubject.value[key] ?? 0
    const baseGPA = safeGet(map, scoreIdx)?.gpa ?? 0
    const w = lvl.weightOverride ?? subj.weight ?? 0
    pts += Math.max(0, baseGPA - Math.max(0, lvl.offset)) * w
    wgt += w
  }
  calculationResultText.value = wgt > 0 ? `Your GPA: ${(pts / wgt).toFixed(3)}` : 'No GPA data'
}

function evaluateRulesAndRecompute() {
  requirementWarning.value = null
  requiredSubjectIDs.value = new Set()
  modulesRequiringSelection.value = new Set()
  isInvalidated.value = false
  evaluateRulesInternal()
  let needsRebuild = true
  let loops = 0
  while (needsRebuild && loops < 5) {
    needsRebuild = false
    loops++
    for (const [modStr, limit] of Object.entries(effectiveLimitsByModule.value)) {
      const mod = parseInt(modStr)
      const entries = selectionsByModule.value[mod] ?? []
      const safeLimit = Math.max(0, limit)
      if (entries.length > safeLimit) {
        selectionsByModule.value[mod] = entries.slice(0, safeLimit)
        needsRebuild = true
      }
    }
    if (needsRebuild) {
      persistSelections()
      rebuildActiveSubjects()
      evaluateRulesInternal()
    }
  }
  if (requirementWarning.value || modulesRequiringSelection.value.size > 0) {
    isInvalidated.value = true
  }
  recomputeGPA()
}

function selectPreset(id: string) {
  const p = root.value?.presets?.find((pr) => pr.id === id)
  if (!p) return
  currentPreset.value = p
  loadPersistedSelections(p.id, p.modules)
  rebuildActiveSubjects()
  ensureDefaultIndices(activeSubjects.value)
  evaluateRulesAndRecompute()
}

function applyRoot(newRoot: CourseModel) {
  const prevId = currentPreset.value?.id
  const r = deepClone(newRoot)

  // Apply templates to subjects
  const tpls: Record<string, Template> = {}
  if (r.templates) {
    for (const t of r.templates) tpls[t.id] = t
  }
  for (const pr of r.presets ?? []) {
    for (const m of pr.modules) {
      for (const s of m.subjects) {
        if (!Array.isArray(s.levels)) s.levels = []
        if (!Array.isArray(s.tags)) s.tags = []
        const t = tpls[s.template ?? '']
        if (t) {
          s.weight = s.weight ?? t.weight
          s.levels = s.levels.length > 0 ? s.levels : (t.levels ?? [])
          s.tags = s.tags.length === 0 ? (t.tags ?? []) : s.tags
          s.scoreMapId = !s.scoreMapId || s.scoreMapId.length === 0 ? t.scoreMapId : s.scoreMapId
        }
      }
    }
  }

  root.value = r

  // Build score maps
  if (r.scoreMaps) {
    scoreMapsById.value = r.scoreMaps
  } else if (r.scoreMap) {
    scoreMapsById.value = { default: r.scoreMap }
  } else {
    scoreMapsById.value = {}
  }
  defaultScoreMapId.value = scoreMapsById.value['default'] ? 'default' : Object.keys(scoreMapsById.value).sort()[0] ?? 'default'

  // Select first preset
  const preset = r.presets?.find((pr) => pr.id === prevId) ?? r.presets?.[0]
  if (preset) {
    selectPreset(preset.id)
  } else {
    currentPreset.value = null
    activeSubjects.value = []
    calculationResultText.value = 'No presets in catalog'
  }
}

// ── Load Data ──
async function loadInitialData() {
  isLoading.value = true

  try {
    const catalog = await fetchCatalog()

    if (!catalog) {
      console.error('[GPA] fetchCatalog returned null')
      calculationResultText.value = 'Failed to load catalog'
      return
    }

    applyRoot(catalog)

  } catch (err) {
    console.error('[GPA] loadInitialData error:', err)
    root.value = null
    calculationResultText.value = 'Failed to load catalog'
  } finally {
    isLoading.value = false
  }
}

export function useBackend() {
  return {
    root,
    currentPreset,
    activeSubjects,
    calculationResultText,
    isInvalidated,
    isLoading,
    scoreDisplay,
    trackActive,
    requirementWarning,
    requiredSubjectIDs,
    modulesRequiringSelection,
    choiceModules: computed(() => {
      const p = currentPreset.value
      if (!p) return []
      return p.modules.map((m, i) => ({ modIndex: i, module: m })).filter(({ module }) => module.type === 'choice')
    }),
    loadInitialData,
    selectPreset,
    setLevelIndex,
    setScoreIndex,
    getLevelIndex,
    getScoreIndex,
    toggleSelection,
    isSelected,
    isDisabled,
    publishedEffectiveLimit,
    setTrackActive,
    resetAllLevelsAndScores,
    moduleStatusText,
    moduleStatusColor,
    scoreMapForSubject,
  }
}

function setLevelIndex(idx: number, forSubjectIndex: number) {
  const subj = activeSubjects.value[forSubjectIndex]
  if (!subj) return
  const key = subjectKey(subj)
  selectedLevelIndicesBySubject.value[key] = idx
  const map = scoreMapForSubject(subj)
  const currentScore = selectedScoreIndicesBySubject.value[key]
  if (currentScore !== undefined && currentScore >= map.length) {
    selectedScoreIndicesBySubject.value[key] = Math.max(0, map.length - 1)
  }
  persistSelections()
  rebuildActiveSubjects()
  evaluateRulesAndRecompute()
}

function setScoreIndex(idx: number, forSubjectIndex: number) {
  const subj = activeSubjects.value[forSubjectIndex]
  if (!subj) return
  selectedScoreIndicesBySubject.value[subjectKey(subj)] = idx
  persistSelections()
  recomputeGPA()
}

function getLevelIndex(subj: Subject): number {
  return selectedLevelIndicesBySubject.value[subjectKey(subj)] ?? 0
}

function getScoreIndex(subj: Subject): number {
  return selectedScoreIndicesBySubject.value[subjectKey(subj)] ?? 0
}

function toggleSelection(modIndex: number, itemIndex: number) {
  const p = currentPreset.value
  if (!p) return
  const module = p.modules[modIndex]
  if (!module) return
  if ((effectiveLimitsByModule.value[modIndex] ?? module.limit ?? 1) === 0) return
  let entries = [...(selectionsByModule.value[modIndex] ?? [])]
  const existingIdx = entries.findIndex((e) => e.itemIndex === itemIndex)
  if (existingIdx >= 0) {
    entries.splice(existingIdx, 1)
  } else {
    const subj = module.subjects[itemIndex]
    if (!subj) return
    entries.push({ itemIndex, subjectId: subjectKey(subj) })
    const dryLimit = Math.max(0, effectiveLimitsByModule.value[modIndex] ?? module.limit ?? 1)
    if (entries.length > dryLimit) entries = entries.slice(entries.length - dryLimit)
  }
  selectionsByModule.value[modIndex] = entries
  persistSelections()
  rebuildActiveSubjects()
  evaluateRulesAndRecompute()
}

function isSelected(modIndex: number, itemIndex: number): boolean {
  return selectionsByModule.value[modIndex]?.some((e) => e.itemIndex === itemIndex) ?? false
}

function isDisabled(modIndex: number, itemIndex: number): boolean {
  const p = currentPreset.value
  if (!p) return true
  const m = p.modules[modIndex]
  if (!m || !m.subjects[itemIndex]) return true
  if ((effectiveLimitsByModule.value[modIndex] ?? m.limit ?? 1) === 0 || disabledIndicesByModule.value[modIndex]?.has(itemIndex)) return true
  const key = subjectKey(m.subjects[itemIndex])
  const allIds = new Set<string>()
  for (const [modStr, entries] of Object.entries(selectionsByModule.value)) {
    const modIdx = parseInt(modStr)
    const mod = p.modules[modIdx]
    if (mod?.type === 'core') mod.subjects.forEach((s) => allIds.add(subjectKey(s)))
    else entries.forEach((e) => allIds.add(e.subjectId))
  }
  return !isSelected(modIndex, itemIndex) && allIds.has(key)
}

function publishedEffectiveLimit(modIndex: number): number {
  return effectiveLimitsByModule.value[modIndex] ?? currentPreset.value?.modules[modIndex]?.limit ?? 1
}

function setTrackActive(isActive: boolean) {
  const p = currentPreset.value
  if (!p || !p.track) { trackActive.value = false; return }
  trackToggleByPreset.value[p.id] = isActive
  trackActive.value = isActive
  for (const subj of activeSubjects.value) {
    const key = subjectKey(subj)
    const map = scoreMapForSubject(subj)
    const cur = selectedScoreIndicesBySubject.value[key]
    if (cur !== undefined && cur >= map.length) selectedScoreIndicesBySubject.value[key] = Math.max(0, map.length - 1)
  }
  persistSelections()
  recomputeGPA()
}

function resetAllLevelsAndScores() {
  selectedLevelIndicesBySubject.value = {}
  selectedScoreIndicesBySubject.value = {}
  selectedScoreMapIdBySubject.value = {}
  ensureDefaultIndices(activeSubjects.value)
  persistSelections()
  rebuildActiveSubjects()
  evaluateRulesAndRecompute()
}

function moduleStatusText(modIndex: number): string {
  const p = currentPreset.value
  if (!p) return ''
  const m = p.modules[modIndex]
  if (!m) return ''
  const sel = selectionsByModule.value[modIndex]?.length ?? 0
  if (publishedEffectiveLimit(modIndex) === 0) return 'Disabled'
  if (m.minSelection && m.minSelection > 0) return `${sel} selected (min ${m.minSelection})`
  return `${sel} selected`
}

function moduleStatusColor(modIndex: number): string {
  if (publishedEffectiveLimit(modIndex) === 0) return 'text-gray-400'
  return modulesRequiringSelection.value.has(modIndex) ? 'text-red-500' : 'text-gray-500'
}

export interface ScoreEntry {
  percent: string
  letter: string
  gpa: number
}

export interface Level {
  name: string
  offset: number
  weightOverride?: number
  tags?: string[]
}

export interface Template {
  id: string
  weight: number
  levels: Level[]
  tags?: string[]
  scoreMapId?: string
}

export interface Subject {
  id: string
  name: string
  weight?: number
  levels: Level[]
  customMap?: ScoreEntry[]
  tags?: string[]
  scoreMapId?: string
  template?: string
}

export interface Module {
  type: 'core' | 'choice'
  name?: string
  limit?: number
  minSelection?: number
  subjects: Subject[]
}

export interface TagLimit {
  tag: string
  limit: number
}

export interface DynamicLimit {
  triggerModuleIndex: number
  triggerCondition: string
  targetModuleIndices: number[]
  newLimit: number
}

export interface PresetRequirement {
  triggerTag: string
  requiredAnyTag: string[]
  errorMessage: string
}

export interface PresetTriggerCondition {
  moduleIndex: number
  minSelected?: number
  exactCount?: number
  requireTag?: string
}

export interface PresetTrigger {
  selectedSubjectIds?: string[]
  moduleConditions?: PresetTriggerCondition[]
}

export interface PresetModuleLimit {
  moduleIndex: number
  newLimit: number
}

export interface PresetConditional {
  id?: string
  trigger: PresetTrigger
  requiresAnyOfSubjectIds?: string[]
  enforceModuleLimits?: PresetModuleLimit[]
  errorMessage?: string
}

export interface PresetRules {
  exclusionTags?: string[][]
  exclusionIds?: string[][]
  tagLimits?: TagLimit[]
  dynamicLimits?: DynamicLimit[]
  requirements?: PresetRequirement[]
  conditionalRequirements?: PresetConditional[]
}

export interface PresetTrack {
  id: string
  scoreMapId: string
  displayName: string
}

export interface Preset {
  id: string
  name: string
  subtitle?: string
  modules: Module[]
  rules?: PresetRules
  track?: PresetTrack
}

export interface CourseModel {
  catalogName?: string
  version?: string
  lastUpdated?: string
  credit?: string
  scoreMap?: ScoreEntry[]
  scoreMaps?: Record<string, ScoreEntry[]>
  templates?: Template[]
  presets?: Preset[]
}

export type ScoreDisplay = 'percentage' | 'letter'

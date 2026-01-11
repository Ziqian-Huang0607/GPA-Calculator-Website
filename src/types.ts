export interface ScoreMap { percentageName: string; letterName: string; baseGPA: number; }
export interface Level { name: string; offset: number; weightOverride?: number; }
export interface Subject { name: string; weight: number; levels: Level[]; customScoreToBaseGPAMap?: ScoreMap[]; }
export interface Module { type: 'core' | 'choice'; name?: string; selectionLimit?: number; subjects: Subject[]; }
export interface Preset { id: string; name: string; subtitle?: string; modules: Module[]; }
export interface RootData { commonScoreMap: ScoreMap[]; presets: Preset[]; lastUpdated?: string; }
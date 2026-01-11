// Types based on the Plist structure
export interface ScoreMap {
  percentageName: string;
  letterName: string;
  baseGPA: number;
}

export interface Level {
  name: string;
  offset: number;
  weightOverride?: number;
}

export interface Subject {
  name: string;
  weight: number;
  levels: Level[];
  customScoreToBaseGPAMap?: ScoreMap[];
}

export interface Module {
  type: 'core' | 'choice';
  name?: string;
  selectionLimit?: number;
  subjects: Subject[];
}

export interface Preset {
  id: string;
  name: string;
  subtitle?: string;
  modules: Module[];
}

export interface RootData {
  commonScoreMap: ScoreMap[];
  presets: Preset[];
  lastUpdated?: string;
}

/**
 * Enhanced GPA Calculation
 * Ported and improved from ViewController.swift
 */
export function calculateFinalGPA(
  activeSubjects: Subject[],
  selections: Record<string, { levelIdx: number; scoreIdx: number }>,
  commonMap: ScoreMap[]
) {
  let totalWeightedPoints = 0;
  let totalWeight = 0;

  activeSubjects.forEach((subj) => {
    const sel = selections[subj.name] || { levelIdx: 0, scoreIdx: 0 };
    const level = subj.levels[sel.levelIdx] || subj.levels[0];
    const map = subj.customScoreToBaseGPAMap || commonMap;
    const baseGPA = map[sel.scoreIdx]?.baseGPA || 0;

    // Logic enhancement: Calculate relative difficulty offset
    const minOffset = Math.min(...subj.levels.map(l => l.offset));
    const effectiveOffset = Math.max(0, level.offset - minOffset);
    
    // The GPA for this specific subject
    const subjectGPA = Math.max(0, baseGPA - effectiveOffset);
    
    // Weight logic: weightOverride (for points) vs subject weight (for credits)
    const weightForPoints = level.weightOverride ?? subj.weight;
    const weightForCredits = subj.weight;

    totalWeightedPoints += (subjectGPA * weightForPoints);
    totalWeight += weightForCredits;
  });

  return totalWeight > 0 ? totalWeightedPoints / totalWeight : 0;
}
import type { CourseModel } from './types'

const FILE_NAME = 'Courses'
const FILE_EXT = 'gpa'
const REMOTE_URL =
  'https://edgeone.gh-proxy.org/https://raw.githubusercontent.com/WillUHD/GPAResources/refs/heads/main/Courses.gpa'

function parseGpaFormat(raw: string): CourseModel {
  // Strip // comments (line-level)
  const withoutComments = raw
    .split('\n')
    .filter((line) => !line.trimStart().startsWith('//'))
    .join('\n')
  // Remove trailing commas before ] or } — the .gpa dialect allows them
  const cleanJson = withoutComments
    .replace(/,\s*([\]}])/g, '$1')
  return JSON.parse(cleanJson)
}

function getLocalCatalog(): string | null {
  return localStorage.getItem(`${FILE_NAME}.${FILE_EXT}`)
}

function saveToLocal(rawData: string) {
  localStorage.setItem(`${FILE_NAME}.${FILE_EXT}`, rawData)
}

export async function fetchRemoteCatalog(
  currentVersion?: string
): Promise<CourseModel | null> {
  try {
    const res = await fetch(REMOTE_URL, { cache: 'no-store' })

    if (!res.ok) {
      console.error('Updater: fetch failed:', res.status, res.statusText)
      return null
    }

    const rawData = await res.text()
    const parsed = parseGpaFormat(rawData)

    saveToLocal(rawData)

    console.log('Updater: downloaded version', parsed.version ?? 'unknown')

    if (parsed.version !== currentVersion) {
      return parsed
    }
    return null
  } catch (err) {
    console.error('Updater: fetch error:', err)
    return null
  }
}

export function loadLocalCatalog(): CourseModel | null {
  const saved = getLocalCatalog()
  if (saved) {
    try {
      return parseGpaFormat(saved)
    } catch {
      localStorage.removeItem(`${FILE_NAME}.${FILE_EXT}`)
    }
  }
  return null
}

export function checkForUpdates(currentVersion?: string) {
  fetchRemoteCatalog(currentVersion).then((newRoot) => {
    if (newRoot) {
      window.dispatchEvent(
        new CustomEvent('courses-updated', { detail: newRoot })
      )
    }
  })
}

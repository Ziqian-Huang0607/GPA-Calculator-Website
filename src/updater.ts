import type { CourseModel } from './types'

const FILE_NAME = 'Courses'
const FILE_EXT = 'gpa'
const REMOTE_URL =
  'https://edgeone.gh-proxy.org/https://raw.githubusercontent.com/WillUHD/GPAResources/refs/heads/main/Courses.gpa'

function stripCommentLines(data: string): string {
  return data
    .split('\n')
    .filter((line) => !line.trimStart().startsWith('//'))
    .join('\n')
}

function getLocalFileURL(): string | null {
  // On web, we use localStorage to simulate the document directory
  const saved = localStorage.getItem(`${FILE_NAME}.${FILE_EXT}`)
  if (saved) return saved
  return null
}

function saveToLocal(rawData: string) {
  localStorage.setItem(`${FILE_NAME}.${FILE_EXT}`, rawData)
}

export function fetchRemoteCatalog(
  currentVersion?: string
): Promise<CourseModel | null> {
  return new Promise((resolve) => {
    const xhr = new XMLHttpRequest()
    xhr.open('GET', REMOTE_URL, true)
    xhr.cache = 'no-store'
    xhr.timeout = 30000

    xhr.onload = function () {
      if (xhr.status !== 200) {
        console.error('Updater: fetch failed:', xhr.status)
        resolve(null)
        return
      }

      try {
        const rawData = xhr.responseText
        const stripped = stripCommentLines(rawData)
        const parsed: CourseModel = JSON.parse(stripped)

        // Save raw (unstripped) data to local storage
        saveToLocal(rawData)

        console.log(
          'Updater: downloaded version',
          parsed.version ?? 'unknown'
        )

        // If version changed, notify the app
        if (parsed.version !== currentVersion) {
          resolve(parsed)
        } else {
          resolve(null) // no update needed
        }
      } catch (err) {
        console.error('Updater: invalid data received:', err)
        resolve(null)
      }
    }

    xhr.onerror = function () {
      console.error('Updater: network error')
      resolve(null)
    }

    xhr.ontimeout = function () {
      console.error('Updater: request timed out')
      resolve(null)
    }

    xhr.send()
  })
}

export function loadLocalCatalog(): CourseModel | null {
  const saved = getLocalFileURL()
  if (saved) {
    try {
      const stripped = stripCommentLines(saved)
      return JSON.parse(stripped) as CourseModel
    } catch {
      // corrupted, remove
      localStorage.removeItem(`${FILE_NAME}.${FILE_EXT}`)
    }
  }
  return null
}

export function checkForUpdates(currentVersion?: string) {
  fetchRemoteCatalog(currentVersion).then((newRoot) => {
    if (newRoot) {
      // Dispatch custom event so the backend can pick it up
      window.dispatchEvent(
        new CustomEvent('courses-updated', { detail: newRoot })
      )
    }
  })
}

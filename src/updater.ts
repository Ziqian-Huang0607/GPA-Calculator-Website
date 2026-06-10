import type { CourseModel } from './types'

const REMOTE_URL =
  'https://edgeone.gh-proxy.org/https://raw.githubusercontent.com/WillUHD/GPAResources/refs/heads/main/Courses.gpa'

export async function fetchCatalog(): Promise<CourseModel | null> {
  try {
    const res = await fetch(REMOTE_URL, { cache: 'no-store' })
    if (!res.ok) {
      console.error('Fetch failed:', res.status)
      return null
    }
    const raw = await res.text()
    // Strip // comment lines, then strip trailing commas (the .gpa dialect allows them)
    const cleaned = raw
      .split('\n')
      .filter((l) => !l.trimStart().startsWith('//'))
      .join('\n')
      .replace(/,\s*([\]}])/g, '$1')
    return JSON.parse(cleaned) as CourseModel
  } catch (err) {
    console.error('fetchCatalog error:', err)
    return null
  }
}

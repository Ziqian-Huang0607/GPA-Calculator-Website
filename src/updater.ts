import type { CourseModel } from './types'

const LOCAL_CATALOG_URL = '/catalog.json'

export async function fetchCatalog(): Promise<CourseModel | null> {
  try {
    const res = await fetch(LOCAL_CATALOG_URL, { cache: 'no-store' })
    if (!res.ok) return null
    return (await res.json()) as CourseModel
  } catch {
    return null
  }
}

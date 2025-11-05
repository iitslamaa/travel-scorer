import path from 'path';
import { promises as fs } from 'fs';
import { Advisory } from '@/app/api/advisories/route';

export type VisaEase = 'visa_free' | 'eta' | 'voa' | 'visa_required' | 'unknown';

export type CountryFacts = {
  iso2: string;
  advisoryLevel?: 1|2|3|4;
  advisorySummary?: string;
  advisoryUrl?: string;
  homicidesPer100k?: number;     // lower is better
  gdpPppPerCapita?: number;      // lower is cheaper
  englishProficiency?: number;   // 0..100 higher is better
  visaEaseUS?: VisaEase;
};

type AdvisoryMap = Record<string, Advisory>;

function readJson<T>(rel: string): Promise<T> {
  const p = path.join(process.cwd(), 'data', 'sources', rel);
  return fs.readFile(p, 'utf8').then(JSON.parse);
}

export async function loadFacts(iso2List: string[], advisories: Advisory[]): Promise<Record<string, CountryFacts>> {
  // Build advisory lookup by iso2
  const advByIso: AdvisoryMap = {};
  for (const a of advisories) {
    if (a.iso2) advByIso[a.iso2.toUpperCase()] = a;
  }

  const [homicides, gdp, epi, visa] = await Promise.all([
    readJson<Record<string, number>>('homicides.json').catch(
      () => ({} as Record<string, number>)
    ),
    readJson<Record<string, number>>('gdp_ppp.json').catch(
      () => ({} as Record<string, number>)
    ),
    readJson<Record<string, number>>('english_epi.json').catch(
      () => ({} as Record<string, number>)
    ),
    readJson<Record<string, VisaEase>>('visa_us.json').catch(
      () => ({} as Record<string, VisaEase>)
    ),
  ]);

  const out: Record<string, CountryFacts> = {};
  for (const iso2Raw of iso2List) {
    const iso2 = iso2Raw.toUpperCase();
    const adv = advByIso[iso2];
    out[iso2] = {
      iso2,
      advisoryLevel: adv?.level,
      advisorySummary: adv?.summary,
      advisoryUrl: adv?.url,
      homicidesPer100k: homicides[iso2],
      gdpPppPerCapita: gdp[iso2],
      englishProficiency: epi[iso2],
      visaEaseUS: (visa[iso2] ?? 'unknown') as VisaEase,
    };
  }
  return out;
}
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { headers } from 'next/headers';
import Image from 'next/image';
import type { CountryFacts } from '@travel-af/shared';
import { AdvisoryBadge } from '@/lib/display/AdvisoryBadge';
import { ScorePill } from '@/lib/display/ScorePill';
import { VisaSection } from './components/VisaSection';
import { Seasonality } from './components/Seasonality';
import { buildRows } from '@travel-af/domain';
import type { FactRow } from '@travel-af/domain';
import InteractiveScoring from './InteractiveScoring';

function toPct(n: number) {
  return `${Math.round(n * 100)}%`;
}

function factorNumbersFromRows(rows: FactRow[], key: FactRow['key']) {
  const r = rows.find((rr) => rr.key === key);
  if (!r) return null;
  const normalized = typeof r.raw === 'number' ? Math.round(r.raw) : null;
  const weightPct = Math.round((r.weight ?? 0) * 100);
  const presentSum = rows
    .filter((x) => typeof x.raw === 'number')
    .reduce((a, x) => a + (x.weight ?? 0), 0);
  const effW = presentSum > 0 ? (r.weight ?? 0) / presentSum : 0;
  const contribution = normalized != null ? Math.round(normalized * effW) : null;
  return { normalized, weightPct, contribution };
}

function renderFactorBreakdown(rows: FactRow[], key: FactRow['key']) {
  const n = factorNumbersFromRows(rows, key);
  if (!n) return null;
  return (
    <div className="mt-3 text-xs muted grid grid-cols-3 gap-3">
      <div><span className="font-medium">Normalized:</span> {n.normalized ?? '—'}</div>
      <div><span className="font-medium">Weight:</span> {n.weightPct}%</div>
      <div><span className="font-medium">Contribution:</span> {n.contribution ?? '—'}</div>
    </div>
  );
}

type AdvisoryLite = { level?: 1|2|3|4; url?: string; summary?: string; updatedAt?: string };

type CountryRowLite = {
  iso2: string;
  name?: string;
  m49?: number | string;
  region?: string;
  subregion?: string;
  advisory?: AdvisoryLite;
  facts?: CountryFacts;
};

type CountriesLiteResponse = { countries: CountryRowLite[] };

function isCountriesLiteResponse(json: unknown): json is CountriesLiteResponse {
  return (
    typeof json === 'object' &&
    json !== null &&
    Array.isArray((json as CountriesLiteResponse).countries)
  );
}

function explainAdvisory(name: string, level?: 1|2|3|4, updatedAt?: string) {
  if (!level) return `${name}: no advisory on record.`;
  const when = updatedAt ? ` (updated ${new Date(updatedAt).toLocaleDateString()})` : '';
  const text = {
    1: `Level 1 (Exercise normal precautions)${when}.`,
    2: `Level 2 (Increased caution)${when}.`,
    3: `Level 3 (Reconsider travel)${when}.`,
    4: `Level 4 (Do not travel)${when}.`,
  } as const;
  return text[level];
}

type PageProps = { params: Promise<{ iso2?: string }> };

export default async function CountryPage({ params }: PageProps) {
  const { iso2: iso2Raw } = await params;
  const iso2 = (iso2Raw || "").toUpperCase();
  if (!iso2) notFound();

  const flagPng = `https://flagcdn.com/w80/${iso2.toLowerCase()}.png`;

  const h = await headers();
  const host = h.get('x-forwarded-host') ?? h.get('host') ?? '';
  const protocol = h.get('x-forwarded-proto') ?? 'http';
  const base = process.env.NEXT_PUBLIC_BASE_URL || (host ? `${protocol}://${host}` : 'http://localhost:3000');
  const apiUrl = `${base}/api/countries`;

  let all: CountryRowLite[] = [];
  try {
    const res = await fetch(apiUrl, { cache: 'no-store' });
    if (res.ok) {
      const json: CountriesLiteResponse | CountryRowLite[] | unknown = await res.json();
      if (Array.isArray(json)) all = json as CountryRowLite[];
      else if (isCountriesLiteResponse(json)) all = json.countries;
    }
  } catch {}

  const row = all.find((c) => ((c.iso2 || '').toUpperCase()) === iso2);
  if (!row) notFound();

  const facts: CountryFacts = { iso2, ...(row.facts ?? {}) };

  return (
    <>
      <div className="mb-6">
        <Link href="/" className="text-sm text-blue-600 hover:underline">← Back</Link>
      </div>

      <div className="flex items-center gap-3 mt-1 mb-4">
        <Image
          src={flagPng}
          alt={`${row.name ?? iso2} flag`}
          width={48}
          height={36}
          className="rounded shadow-sm ring-1 ring-black/10 dark:ring-white/10 bg-white"
          unoptimized
        />
        <h1 className="h1">{row.name ?? iso2}</h1>
      </div>

      <InteractiveScoring facts={facts} row={row} />
    </>
  );
}
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { headers } from 'next/headers';
import Image from 'next/image';
import type { CountryFacts } from '@/lib/facts';
import { AdvisoryBadge } from '@/lib/display/AdvisoryBadge';
import { VisaBadge } from '@/lib/display/VisaBadge';
import { TravelSafeSection } from '@/lib/display/TravelSafeSection';
import { SoloFemaleSection } from '@/lib/display/SoloFemaleSection';
import { SeasonalitySection } from '@/lib/display/SeasonalitySection';
import { ScorePill } from '@/lib/display/ScorePill';

// --- helpers hoisted to module scope to avoid defining components during render
function factorNumbersFromRows(rows: FactRow[], key: FactRow['key']) {
  const r = rows.find((rr) => rr.key === key);
  if (!r) return null;
  const normalized = typeof r.raw === 'number' ? Math.round(r.raw) : null; // 0..100 already
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

// Minimal advisory shape from /api/countries
type AdvisoryLite = { level?: 1|2|3|4; url?: string; summary?: string; updatedAt?: string };

// Shape attached by the API for estimated daily spend (hotel traveler)
type DailySpendLocal = {
  foodUsd: number;
  activitiesUsd: number;
  hotelUsd: number;
  totalUsd: number;
  basis?: { col?: number; food?: number };
  notes?: string[];
};

// Extra optional fields we may have in our dataset for derived metrics
type FactsExtra = CountryFacts & {
  costOfLivingIndex?: number;
  foodCostIndex?: number;
  gdpPerCapitaUsd?: number;
  fxLocalPerUSD?: number;
  localPerUSD?: number;
  usdToLocalRate?: number;
  redditThemes?: string[];
  redditSummary?: string;
  affordability?: number;
  // Computed by API from COL/food/FX
  dailySpend?: DailySpendLocal;
  // Visa enrichments (from visa provider)
  visaType?: 'visa_free' | 'voa' | 'evisa' | 'visa_required' | 'ban';
  visaAllowedDays?: number;
  visaFeeUsd?: number;
  visaNotes?: string;
  visaSource?: string;
  // Frequent Miler seasonality enrichments
  fmSeasonalityBestMonths?: number[];            // 1..12
  fmSeasonalityAreas?: { area?: string; months: number[] }[];
  fmSeasonalityHasDualPeak?: boolean;
  fmSeasonalityTodayScore?: number;              // 0..100
  fmSeasonalityTodayLabel?: 'best' | 'good' | 'shoulder' | 'poor';
  fmSeasonalitySource?: string;
};

function monthName(n: number) {
  return ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][Math.max(1, Math.min(12, n)) - 1];
}
function listMonths(ms: number[]) {
  const uniq = Array.from(new Set(ms.filter(m => m>=1 && m<=12))).sort((a,b)=>a-b);
  return uniq.map(monthName).join(', ');
}
function describeSeasonalityFM(f: Partial<FactsExtra>) {
  const best = f.fmSeasonalityBestMonths;
  const label = f.fmSeasonalityTodayLabel;
  const dual = f.fmSeasonalityHasDualPeak;
  const areas = f.fmSeasonalityAreas;
  const parts: string[] = [];
  if (best && best.length) parts.push(`Best months: ${listMonths(best)}.`);
  if (label) parts.push(`If you go now: ${label}.`);
  if (dual) parts.push('There appear to be two distinct peak seasons.');
  if (areas && areas.length) {
    const top = areas.slice(0, 3).map(a => a.area ? `${a.area} (${listMonths(a.months)})` : listMonths(a.months));
    parts.push(`Popular regions/windows: ${top.join('; ')}.`);
  }
  return parts.join(' ');
}

function titleForVisaType(t?: FactsExtra['visaType']) {
  switch (t) {
    case 'visa_free': return 'Visa-free';
    case 'voa': return 'Visa on arrival';
    case 'evisa': return 'eVisa';
    case 'visa_required': return 'Visa required';
    case 'ban': return 'Entry not permitted';
    default: return undefined;
  }
}
function describeVisa(f: Partial<FactsExtra>, raw?: number) {
  const rounded = typeof raw === 'number' ? Math.round(raw) : undefined;
  const baseType = titleForVisaType(f.visaType);
  let kind = baseType;

  // Infer free/paid wording for VOA/eVisa using fee or score bands
  const hasFee = typeof f.visaFeeUsd === 'number' && f.visaFeeUsd > 0;
  const isFree = typeof f.visaFeeUsd === 'number' && f.visaFeeUsd === 0;

  if (f.visaType === 'voa') {
    if (isFree || (!hasFee && typeof rounded === 'number' && rounded >= 90)) {
      kind = 'Visa on arrival — free';
    } else if (hasFee) {
      kind = 'Visa on arrival — paid';
    }
  } else if (f.visaType === 'evisa') {
    if (isFree || (!hasFee && typeof rounded === 'number' && rounded >= 60)) {
      kind = 'Free eVisa/ETA';
    } else if (hasFee) {
      kind = 'eVisa/ETA — paid';
    }
  }

  const days = typeof f.visaAllowedDays === 'number' ? `${Math.round(f.visaAllowedDays)} days` : undefined;
  const fee = hasFee ? `fee about $${Math.round(f.visaFeeUsd as number)}` : undefined;
  const bits = [kind, days, fee].filter(Boolean).join(' · ');
  const fallback = typeof rounded === 'number' ? `Visa ease score ${rounded}` : 'Visa info not available';
  const note = f.visaNotes ? ` ${f.visaNotes}` : '';
  return (bits || fallback) + note;
}

function scoreBadgeClass(n?: number) {
  if (typeof n !== 'number') return 'bg-zinc-100 text-zinc-700 border-zinc-200';
  if (n >= 80) return 'bg-green-100 text-green-800 border-green-300';
  if (n >= 60) return 'bg-yellow-100 text-yellow-800 border-yellow-300';
  if (n > 0)   return 'bg-red-100 text-red-800 border-red-300';
  return 'bg-black text-white border-black';
}

// Minimal shape returned by /api/countries that we use on this page
type CountryRowLite = {
  iso2: string;
  name?: string;
  m49?: number | string;
  region?: string;
  subregion?: string;
  advisory?: AdvisoryLite;
  facts?: CountryFacts;
};

// Your final weights from earlier (sum = 1.0)
const W = {
  travelGov: 0.30,
  travelSafe: 0.15,
  sfti: 0.10,
  reddit: 0.20,
  seasonality: 0.05,
  visa: 0.05,
  affordability: 0.05,
  directFlight: 0.05,
  infrastructure: 0.05,
} as const;

type FactRow = {
  key: keyof typeof W;
  label: string;
  raw?: number;       // 0..100
  weight: number;     // 0..1
  contrib: number;    // raw * (weight / sumPresentWeights)
};

function toPct(n: number) {
  return `${Math.round(n * 100)}%`;
}

function clamp01(x: number) {
  return Math.max(0, Math.min(1, x));
}

function toNumber(x: unknown): number | undefined {
  const n = Number(x);
  return Number.isFinite(n) ? n : undefined;
}

// Linear scale to 0..100, clamped.
function scaleTo100(value: number, min: number, max: number, invert = false) {
  if (min === max) return 50;
  const t = clamp01((value - min) / (max - min));
  const y = invert ? 1 - t : t;
  return Math.round(y * 100);
}

// Derive an affordability score if one isn't provided.
function computeAffordability(facts: FactsExtra): number | undefined {
  const f = facts;
  const col = toNumber(f.costOfLivingIndex);
  const food = toNumber(f.foodCostIndex);
  const gdp = toNumber(f.gdpPerCapitaUsd);
  const fxLocalPerUsd = toNumber(f.fxLocalPerUSD ?? f.localPerUSD ?? f.usdToLocalRate);
  const parts: number[] = [];

  if (col != null) parts.push(scaleTo100(col, 30, 120, true));
  if (food != null) parts.push(scaleTo100(food, 20, 200, true));
  if (gdp != null) parts.push(scaleTo100(gdp, 2000, 80000, true));
  if (fxLocalPerUsd != null) parts.push(scaleTo100(fxLocalPerUsd, 0.2, 400, false));

  if (parts.length === 0) return 50;
  return Math.round(parts.reduce((a, b) => a + b, 0) / parts.length);
}

// Basic advisory-level → 0..100 mapping (Level 1 best, 4 worst)
function advisoryToScore(level?: 1|2|3|4) {
  if (!level) return 50;
  return ((5 - level) / 4) * 100;
}

function buildRows(facts: CountryFacts): { rows: FactRow[]; total: number } {
  const signals: { key: FactRow['key']; label: string; value?: number }[] = [
    { key: 'travelGov',     label: 'Travel.gov advisory',    value: advisoryToScore(facts.advisoryLevel) },
    { key: 'travelSafe',    label: 'TravelSafe Abroad',      value: facts.travelSafeOverall },
    { key: 'sfti',          label: 'Solo Female Travelers',  value: facts.soloFemaleIndex },
    { key: 'reddit',        label: 'Reddit sentiment',       value: facts.redditComposite },
    { key: 'seasonality',   label: 'Seasonality (now)',      value: facts.seasonality },
    { key: 'visa',          label: 'Visa ease (US passport)',value: facts.visaEase },
    { key: 'affordability', label: 'Affordability',          value: (facts as FactsExtra).affordability ?? computeAffordability(facts as FactsExtra) },
    { key: 'directFlight',  label: 'Direct flight',          value: facts.directFlight },
    { key: 'infrastructure',label: 'Tourist infrastructure', value: facts.infrastructure },
  ];

  // only count weights for present signals
  const presentWeightSum = signals
    .filter(s => Number.isFinite(s.value))
    .reduce((acc, s) => acc + (W[s.key] ?? 0), 0);

  const rows: FactRow[] = signals.map(s => {
    const raw = Number.isFinite(s.value as number) ? (s.value as number) : undefined;
    const w = (W[s.key] ?? 0);
    const effW = presentWeightSum > 0 ? w / presentWeightSum : 0; // reweight by present
    const contrib = raw != null ? raw * effW : 0;
    return { key: s.key, label: s.label, raw, weight: w, contrib };
  });

  const total = Math.round(rows.reduce((a, r) => a + r.contrib, 0));
  return { rows, total };
}

function explain(facts: CountryFacts, rows: FactRow[]): string {
  const parts: string[] = [];

  // Lead with advisory
  if (facts.advisoryLevel) {
    parts.push(`Travel.gov lists this country at Level ${facts.advisoryLevel}.`);
  }

  const get = (k: FactRow['key']) => rows.find(r => r.key === k);
  const ts = get('travelSafe')?.raw;
  if (ts != null) parts.push(`TravelSafe Abroad score is ${Math.round(ts)}.`);

  const sfti = get('sfti')?.raw;
  if (sfti != null) parts.push(`Solo Female Travelers index is ${Math.round(sfti)}.`);

  const rd = get('reddit')?.raw;
  if (rd != null) parts.push(`Reddit sentiment sits around ${Math.round(rd)}.`);
  if (rd != null) {
    parts.push('This score summarizes recent subreddit discussions about travel safety, costs, and logistics, normalized to 0–100 (≈50 is neutral).');
  }

  const infra = get('infrastructure')?.raw;
  if (infra != null) parts.push(`Tourist infrastructure is rated ${Math.round(infra)}.`);

  const visa = get('visa')?.raw;
  if (visa != null) parts.push(`Visa ease is ${Math.round(visa)} for US passport holders.`);

  const flight = get('directFlight')?.raw;
  if (flight != null) {
    const hasDirect = Number(flight) >= 100; // our data encodes direct as 100
    parts.push(`${hasDirect ? 'Direct' : 'No direct'} flight from NYC considered in score.`);
  }

  // Affordability narrative
  const aff = get('affordability')?.raw;
  if (aff != null) {
    const f = facts as FactsExtra;
    const drivers: string[] = [];
    if (f.costOfLivingIndex != null) drivers.push(`cost-of-living index ${Math.round(Number(f.costOfLivingIndex))}`);
    if (f.foodCostIndex != null) drivers.push(`food cost index ${Math.round(Number(f.foodCostIndex))}`);
    if (f.gdpPerCapitaUsd != null) drivers.push(`GDP per capita ${Math.round(Number(f.gdpPerCapitaUsd))} USD`);
    if (f.fxLocalPerUSD != null || f.localPerUSD != null || f.usdToLocalRate != null) drivers.push('favorable USD exchange rate');

    if (drivers.length) {
      parts.push(`Affordability reflects ${drivers.join(', ')} and the current USD exchange rate where available.`);
    } else {
      parts.push('Affordability is estimated from limited available indicators and shown as a neutral baseline until we add GDP, FX, and cost-of-living data.');
    }
  }

  // Reddit narrative
  const themes: string[] | undefined = (facts as FactsExtra).redditThemes;
  if (themes && themes.length) {
    const top = themes.slice(0, 3).join(', ');
    parts.push(`Reddit themes frequently mentioned: ${top}.`);
  }

  if (parts.length === 0) return 'We do not have enough data points yet. Scores default to a neutral baseline.';
  return parts.join(' ');
}

// --- Country-specific explainer helpers -----------------------------------
function fmtUSD(n?: number) {
  return typeof n === 'number' && Number.isFinite(n) ? `$${Math.round(n).toLocaleString()}` : '—';
}
function pick<T>(...vals: (T | undefined)[]) { return vals.find((v) => v !== undefined); }

function explainAdvisory(name: string, level?: 1|2|3|4, updatedAt?: string) {
  if (!level) return `${name}: no advisory on record, treated as neutral.`;
  const when = updatedAt ? ` (updated ${new Date(updatedAt).toLocaleDateString()})` : '';
  const text = {
    1: `Level 1 (Exercise normal precautions)${when}. This boosts the score strongly for ${name}.`,
    2: `Level 2 (Increased caution)${when}. This modestly reduces the score for ${name}.`,
    3: `Level 3 (Reconsider travel)${when}. This heavily reduces the score for ${name}.`,
    4: `Level 4 (Do not travel)${when}. This nearly floors the score for ${name}.`,
  } as const;
  return text[level];
}

function explainAffordability(fx: Partial<FactsExtra>){
  const col = fx.costOfLivingIndex; const food = fx.foodCostIndex; const gdp = fx.gdpPerCapitaUsd; const rate = pick(fx.fxLocalPerUSD, fx.localPerUSD, fx.usdToLocalRate);
  const parts: string[] = [];
  if (col != null) parts.push(`cost-of-living index ≈ ${Math.round(col)}`);
  if (food != null) parts.push(`food cost index ≈ ${Math.round(food)}`);
  if (gdp != null) parts.push(`GDP per capita ≈ ${fmtUSD(gdp)}`);
  if (rate != null) parts.push(`about ${rate} local units per USD`);
  if (!parts.length) return 'Using a neutral affordability baseline (need COL/GDP/FX inputs for a better estimate).';
  return `Estimated using ${parts.join(', ')}. Lower COL/food and stronger USD rate improve affordability; higher GDP per capita reduces it.`;
}

function explainReddit(themes?: string[], summary?: string){
  if (summary) return summary;
  if (themes && themes.length) return `Common themes: ${themes.slice(0,5).join(', ')}.`;
  return 'Reddit coverage looks thin for this destination; we fall back to a neutral sentiment.';
}

function explainSeasonality(val?: number){
  if (typeof val !== 'number') return 'No seasonality data; treated as neutral timing.';
  if (val >= 80) return 'Great timing to visit based on typical weather and crowd patterns.';
  if (val >= 60) return 'Generally good timing to visit.';
  if (val >= 40) return 'Okay timing; expect some tradeoffs with weather or crowds.';
  return 'Less ideal timing; consider shoulder or peak months for better conditions.';
}

function explainVisa(val?: number){
  if (typeof val !== 'number') return 'Visa information missing; treated as neutral.';
  if (val >= 80) return 'Visa is straightforward or visa-free for most travelers.';
  if (val >= 60) return 'Visa may require some paperwork but is manageable.';
  return 'Visa is restrictive or slow for many travelers.';
}

function explainInfra(val?: number){
  if (typeof val !== 'number') return 'Infrastructure data missing; treated as neutral.';
  if (val >= 80) return 'Tourist infrastructure is strong (transport, lodging, services).';
  if (val >= 60) return 'Infrastructure is decent with some gaps.';
  return 'Infrastructure can be spotty; plan logistics carefully.';
}

function explainFlights(val?: number){
  if (typeof val !== 'number') return 'No direct-flight data; treated as neutral.';
  if (val >= 80) return 'Direct flight access is excellent from major hubs.';
  if (val >= 60) return 'There is some direct connectivity; alternatives may require a connection.';
  return 'Direct options are limited; expect one or more connections.';
}

function explainTravelSafe(val?: number){
  if (typeof val !== 'number') return 'No TravelSafe Abroad data; treated as neutral.';
  if (val >= 80) return 'Community safety indicators are strong for visitors.';
  if (val >= 60) return 'General safety indicators are acceptable with usual precautions.';
  return 'Safety indicators suggest extra caution for visitors.';
}

function explainSFTI(val?: number){
  if (typeof val !== 'number') return 'No Solo Female Travelers index here; treated as neutral.';
  if (val >= 80) return 'Reports from solo female travelers are very positive overall.';
  if (val >= 60) return 'Reports are mixed-to-positive with common-sense precautions.';
  return 'Reports indicate notable concerns; plan carefully.';
}

// Normalize daily-spend payload that might come from different server shapes
type LegacyDailySpendFlat = {
  dailyFoodUsd?: number;
  foodPerDayUsd?: number;
  dailyActivitiesUsd?: number;
  activitiesPerDayUsd?: number;
  dailyHotelUsd?: number;
  hotelNightUsd?: number;
  dailyTotalUsd?: number;
  totalPerDayUsd?: number;
};

function pickDailySpend(fx: Partial<FactsExtra> | undefined): DailySpendLocal | undefined {
  if (!fx) return undefined;

  // Preferred nested shape { dailySpend: { ... } }
  const withDaily = fx as Partial<{ dailySpend: DailySpendLocal }>;
  const nested = withDaily.dailySpend;
  if (nested && typeof nested.totalUsd === 'number' && Number.isFinite(nested.totalUsd)) {
    return nested;
  }

  // Legacy/alternate flat shapes (fallbacks)
  const legacy = fx as LegacyDailySpendFlat;
  const food = legacy.dailyFoodUsd ?? legacy.foodPerDayUsd;
  const acts = legacy.dailyActivitiesUsd ?? legacy.activitiesPerDayUsd;
  const hotel = legacy.dailyHotelUsd ?? legacy.hotelNightUsd;
  const total = legacy.dailyTotalUsd ?? legacy.totalPerDayUsd;

  const hasAny =
    [food, acts, hotel, total].some(
      (v) => typeof v === 'number' && Number.isFinite(v as number)
    );

  if (!hasAny) return undefined;

  const safeNum = (x: unknown): number | undefined =>
    typeof x === 'number' && Number.isFinite(x) ? x : undefined;

  const dd: DailySpendLocal = {
    foodUsd: safeNum(food) ?? 0,
    activitiesUsd: safeNum(acts) ?? 0,
    hotelUsd: safeNum(hotel) ?? 0,
    totalUsd:
      safeNum(total) ??
      ((safeNum(food) ?? 0) + (safeNum(acts) ?? 0) + (safeNum(hotel) ?? 0)),
    notes: [],
  };
  return dd;
}

type PageProps = { params: { iso2?: string } };
export default async function CountryPage({ params }: PageProps) {
  const iso2 = (params.iso2 || '').toUpperCase();
  const flagPng = `https://flagcdn.com/w80/${iso2.toLowerCase()}.png`;
  if (!iso2) {
    notFound();
  }

  // Build an absolute URL for SSR so fetch works on the server as well as the client.
  const h = await headers();
  const host = h.get('x-forwarded-host') ?? h.get('host') ?? '';
  const protocol = h.get('x-forwarded-proto') ?? 'http';
  const base = process.env.NEXT_PUBLIC_BASE_URL || (host ? `${protocol}://${host}` : 'http://localhost:3000');
  const apiUrl = `${base}/api/countries`;

  let all: CountryRowLite[] = [];
  try {
    const res = await fetch(apiUrl, { cache: 'no-store' });
    if (res.ok) {
      all = await res.json();
    }
  } catch (_) {
    // fall through to notFound below
  }
  const row = all.find((c) => ((c.iso2 || '').toUpperCase()) === iso2);
  if (!row) {
    notFound();
  }

  const facts: CountryFacts = { iso2, ...(row.facts ?? {}) };
  const { rows, total } = buildRows(facts);
  // Prefer server-computed canonical score from /api/countries
  const providedTotal = (facts as unknown as { scoreTotal?: number }).scoreTotal;
  const displayTotal = Number.isFinite(providedTotal as number)
    ? Math.round(providedTotal as number)
    : total;

  const fxFacts: Partial<FactsExtra> = facts as Partial<FactsExtra>;
  const daily = pickDailySpend(fxFacts);

  return (
    <>
      <div className="mb-6">
        <Link href="/" className="text-sm text-blue-600 hover:underline">← Back</Link>
      </div>

      <div className="flex items-center gap-3 mt-1 mb-4">
        <div className="relative">
          <Image
            src={flagPng}
            alt={`${row.name ?? iso2} flag`}
            width={48}
            height={36}
            className="rounded shadow-sm ring-1 ring-black/10 dark:ring-white/10 bg-white"
            unoptimized
          />
        </div>
        <h1 className="h1">{row.name ?? iso2}</h1>
      </div>
      <p className="text-sm muted mb-8 tracking-wide">
        {iso2} • M49: {row.m49 ?? '—'}
        {row.region ? ` • ${row.region}` : ''}{row.subregion ? ` • ${row.subregion}` : ''}
      </p>

      <div className="lg:grid lg:grid-cols-12 lg:gap-6 mb-8">
        <div className="lg:col-span-8 space-y-4">
          <div className="card p-5">
            <div className="flex items-baseline justify-between mb-2">
              <h2 className="font-medium">Overall Travelability Score</h2>
              <div className="text-3xl font-bold">{displayTotal}</div>
            </div>
            <p className="text-sm muted">
              Weighted by your current formula. Missing signals are ignored and the remaining weights are re-normalized.
            </p>
          </div>
        </div>
        <aside className="hidden lg:block lg:col-span-4 lg:self-start lg:sticky lg:top-24">
          <div className="card p-5">
            <div className="text-sm font-semibold mb-2 tracking-wider uppercase">Advisory</div>
            {row.advisory ? (
              <div className="text-sm space-y-2">
                <div className="flex items-center gap-2">
                  <AdvisoryBadge level={row.advisory.level as 1|2|3|4|undefined} />
                </div>
                <p className="mt-1 text-xs italic muted">
                  {explainAdvisory(row.name ?? iso2, row.advisory.level as 1|2|3|4|undefined, row.advisory.updatedAt)}
                </p>
                {row.advisory.summary && (
                  <p className="mt-1 text-xs italic muted line-clamp-3 break-words max-w-full">
                    {(row.advisory.summary as string).replace(/<[^>]+>/g, '')}
                  </p>
                )}
                {row.advisory.url ? (
                  <a
                    className="text-blue-600 hover:underline inline-block"
                    href={row.advisory.url}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    travel.state.gov
                  </a>
                ) : null}
              </div>
            ) : (
              <div className="text-sm muted">No advisory found.</div>
            )}
          </div>
        </aside>
      </div>

      <div className="card p-5 mb-8 overflow-x-auto">
        <h3 className="font-medium mb-3">Score Breakdown</h3>
        <table className="w-full text-sm">
          <thead className="muted">
            <tr>
              <th className="text-left p-2">Factor</th>
              <th className="text-right p-2">Raw</th>
              <th className="text-right p-2">Weight</th>
              <th className="text-right p-2">Contribution</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.key} className="border-t">
                <td className="p-2">{r.label}</td>
                <td className="p-2 text-right">
                  <ScorePill value={typeof r.raw === 'number' ? Math.round(r.raw) : undefined} />
                </td>
                <td className="p-2 text-right">{toPct(r.weight)}</td>
                <td className="p-2 text-right">{Math.round(r.contrib)}</td>
              </tr>
            ))}
          </tbody>
          <tfoot className="border-t">
            <tr>
              <td className="p-2 font-medium">Total</td>
              <td />
              <td />
              <td className="p-2 text-right font-semibold">{displayTotal}</td>
            </tr>
          </tfoot>
        </table>
      </div>

      {/* Deep Dive */}
      <section className="mt-10">
        <div className="flex gap-6">
          {/* Sticky nav */}
          <nav className="hidden md:block w-60 shrink-0 sticky top-24 self-start card p-3">
            <div className="text-sm font-semibold mb-2 tracking-wider uppercase">Deep Dive</div>
            <ul className="space-y-2 text-sm">
              <li><a className="hover:underline" href="#overview">Overview</a></li>
              <li><a className="hover:underline" href="#advisory">Travel.gov advisory</a></li>
              <li><a className="hover:underline" href="#travelsafe">TravelSafe Abroad</a></li>
              <li><a className="hover:underline" href="#solofemale">Solo Female Travelers</a></li>
              <li><a className="hover:underline" href="#reddit">Reddit sentiment</a></li>
              <li><a className="hover:underline" href="#seasonality">Seasonality</a></li>
              <li><a className="hover:underline" href="#visa">Visa ease (US passport)</a></li>
              <li><a className="hover:underline" href="#affordability">Affordability</a></li>
              <li><a className="hover:underline" href="#flight">Direct flight</a></li>
              <li><a className="hover:underline" href="#infrastructure">Tourist infrastructure</a></li>
            </ul>
          </nav>

          {/* Content column */}
          <div className="grow space-y-8">
            {/* Overview */}
            <section id="overview" className="scroll-mt-24 card p-4">
              <h3 className="text-lg font-semibold mb-2">Why this score?</h3>
              <p className="text-sm leading-6">{explain(facts, rows)}</p>
            </section>

            {/* Advisory */}
            <section id="advisory" className="scroll-mt-24 card p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Travel.gov advisory</h4>
                <div className="text-sm muted">
                  Raw: {Math.round(advisoryToScore(row.advisory?.level as 1|2|3|4|undefined)) ?? '—'}
                </div>
              </header>
              <p className="mt-2 text-sm leading-6">
                {explainAdvisory(row.name ?? iso2, row.advisory?.level as 1|2|3|4|undefined, row.advisory?.updatedAt)}
              </p>
              {renderFactorBreakdown(rows, 'travelGov')}
              {row.advisory?.url ? (
                <p className="mt-2 text-sm"><a className="underline" href={row.advisory.url} target="_blank" rel="noopener noreferrer">Read the full advisory</a></p>
              ) : null}
            </section>

            {/* TravelSafe */}
            <section id="travelsafe" className="scroll-mt-24 card p-4">
              <h4 className="sr-only">TravelSafe Abroad</h4>
              <TravelSafeSection raw={rows.find(r=>r.key==='travelSafe')?.raw} />
              {renderFactorBreakdown(rows, 'travelSafe')}
            </section>

            {/* Solo Female */}
            <section id="solofemale" className="scroll-mt-24 card p-4">
              <header className="flex items-baseline justify-between">
                {/* Hide duplicate title; keep metrics on the right */}
                <h4 className="font-medium sr-only">Solo Female Travelers</h4>
                <div className="text-sm muted">
                  Raw: {rows.find(r=>r.key==='sfti')?.raw ?? '—'} · Weight: {Math.round((rows.find(r=>r.key==='sfti')?.weight ?? 0)*100)}%
                </div>
              </header>

              {/* Single headline + summary comes from the component */}
              <SoloFemaleSection raw={rows.find(r=>r.key==='sfti')?.raw} />

              {renderFactorBreakdown(rows, 'sfti')}
            </section>

            {/* Reddit */}
            <section id="reddit" className="scroll-mt-24 card p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Reddit sentiment</h4>
                <div className="text-sm muted">Raw: {rows.find(r=>r.key==='reddit')?.raw ?? '—'} · Weight: {Math.round((rows.find(r=>r.key==='reddit')?.weight ?? 0)*100)}%</div>
              </header>
              <div className="mt-2 flex items-center gap-2">
                <ScorePill value={typeof rows.find(r=>r.key==='reddit')?.raw === 'number' ? Math.round(rows.find(r=>r.key==='reddit')!.raw as number) : undefined} />
                <span className="text-sm font-semibold">🧵 Reddit</span>
              </div>
              <p className="mt-2 text-sm leading-6">{explainReddit((facts as FactsExtra)?.redditThemes, (facts as FactsExtra)?.redditSummary)}</p>
              {renderFactorBreakdown(rows, 'reddit')}
              {(facts as FactsExtra)?.redditSummary && (
                <p className="mt-2 text-sm leading-6 italic">Summary: {(facts as FactsExtra).redditSummary}</p>
              )}
              {(facts as FactsExtra)?.redditThemes?.length ? (
                <ul className="mt-2 text-sm list-disc ml-6">
                  {(facts as FactsExtra).redditThemes!.slice(0,5).map((t, i) => (
                    <li key={i}>{t}</li>
                  ))}
                </ul>
              ) : null}
            </section>

            {/* Seasonality */}
            <section id="seasonality" className="scroll-mt-24 card p-4">
              <header className="flex items-baseline justify-between">
                {/* Hide duplicate title; keep metrics on the right */}
                <h4 className="font-medium sr-only">Seasonality (now)</h4>
                <div className="text-sm muted">
                  Raw: {rows.find(r=>r.key==='seasonality')?.raw ?? '—'} · Weight: {Math.round((rows.find(r=>r.key==='seasonality')?.weight ?? 0)*100)}%
                </div>
              </header>

              {/* Single headline + summary comes from the component */}
              <SeasonalitySection
                raw={rows.find(r=>r.key==='seasonality')?.raw}
                fm={{
                  best: fxFacts?.fmSeasonalityBestMonths,
                  todayLabel: fxFacts?.fmSeasonalityTodayLabel,
                  hasDual: fxFacts?.fmSeasonalityHasDualPeak,
                  areas: fxFacts?.fmSeasonalityAreas,
                  source: fxFacts?.fmSeasonalitySource,
                }}
              />

              {renderFactorBreakdown(rows, 'seasonality')}
            </section>

            {/* Visa */}
            <section id="visa" className="scroll-mt-24 card p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Visa ease (US passport)</h4>
                <div className="text-sm muted">Raw: {rows.find(r=>r.key==='visa')?.raw ?? '—'} · Weight: {Math.round((rows.find(r=>r.key==='visa')?.weight ?? 0)*100)}%</div>
              </header>
              {(() => {
                const raw = rows.find(r=>r.key==='visa')?.raw;
                const easeNum = typeof raw === 'number' ? Math.round(raw) : undefined;
                return (
                  <div className="mt-2 flex items-center gap-2">
                    <span className="pill" title="Visa ease score">{easeNum ?? '—'}</span>
                    <span className="muted" aria-hidden="true">|</span>
                    <VisaBadge
                      visaType={(facts as FactsExtra)?.visaType}
                      ease={easeNum}
                      feeUsd={typeof (facts as FactsExtra)?.visaFeeUsd === 'number' ? Number((facts as FactsExtra).visaFeeUsd) : undefined}
                    />
                  </div>
                );
              })()}
              <p className="mt-2 text-sm leading-6">
                {describeVisa(facts as Partial<FactsExtra>, rows.find(r=>r.key==='visa')?.raw)}
                {(facts as FactsExtra)?.visaSource ? (
                  <> {' '}<a className="underline" href={(facts as FactsExtra).visaSource} target="_blank" rel="noopener noreferrer">Source</a></>
                ) : null}
              </p>
              <ul className="mt-2 text-sm list-disc ml-6">
                {(facts as FactsExtra)?.visaType && (<li>Type: {titleForVisaType((facts as FactsExtra).visaType)}</li>)}
                {typeof (facts as FactsExtra)?.visaAllowedDays === 'number' && (<li>Allowed stay: {Math.round(Number((facts as FactsExtra).visaAllowedDays))} days</li>)}
                {typeof (facts as FactsExtra)?.visaFeeUsd === 'number' && (<li>Approx. fee: {'$' + Math.round(Number((facts as FactsExtra).visaFeeUsd)).toLocaleString()}</li>)}
                {(facts as FactsExtra)?.visaNotes && (<li>Notes: {(facts as FactsExtra).visaNotes}</li>)}
              </ul>
              {renderFactorBreakdown(rows, 'visa')}
            </section>

            {/* Affordability */}
            <section id="affordability" className="scroll-mt-24 card p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Affordability</h4>
                <div className="text-sm muted">Raw: {rows.find(r=>r.key==='affordability')?.raw ?? '—'} · Weight: {Math.round((rows.find(r=>r.key==='affordability')?.weight ?? 0)*100)}%</div>
              </header>
              <div className="mt-2 flex items-center gap-2">
                <ScorePill value={typeof rows.find(r=>r.key==='affordability')?.raw === 'number' ? Math.round(rows.find(r=>r.key==='affordability')!.raw as number) : undefined} />
                <span className="text-sm font-semibold">💵 Costs</span>
              </div>
              <p className="mt-2 text-sm leading-6">{explainAffordability(facts as Partial<FactsExtra>)}</p>
              {renderFactorBreakdown(rows, 'affordability')}
              {(() => {
                const daily = pickDailySpend(facts as Partial<FactsExtra>);
                return daily ? (
                  <ul className="mt-2 text-sm list-disc ml-6">
                    <li>Food (daily): {fmtUSD(daily.foodUsd)}</li>
                    <li>Activities (daily): {fmtUSD(daily.activitiesUsd)}</li>
                    <li>Hotel (mid-range, nightly): {fmtUSD(daily.hotelUsd)}</li>
                    <li className="font-medium">Estimated daily total: {fmtUSD(daily.totalUsd)}</li>
                  </ul>
                ) : null;
              })()}
            </section>

            {/* Flight */}
            <section id="flight" className="scroll-mt-24 card p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Direct flight</h4>
                <div className="text-sm muted">Raw: {rows.find(r=>r.key==='directFlight')?.raw ?? '—'} · Weight: {Math.round((rows.find(r=>r.key==='directFlight')?.weight ?? 0)*100)}%</div>
              </header>
              <div className="mt-2 flex items-center gap-2">
                <ScorePill value={typeof rows.find(r=>r.key==='directFlight')?.raw === 'number' ? Math.round(rows.find(r=>r.key==='directFlight')!.raw as number) : undefined} />
                <span className="text-sm font-semibold">✈️ Flights</span>
              </div>
              <p className="mt-2 text-sm leading-6">{explainFlights(rows.find(r=>r.key==='directFlight')?.raw)}</p>
              {renderFactorBreakdown(rows, 'directFlight')}
            </section>

            {/* Infrastructure */}
            <section id="infrastructure" className="scroll-mt-24 card p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Tourist infrastructure</h4>
                <div className="text-sm muted">Raw: {rows.find(r=>r.key==='infrastructure')?.raw ?? '—'} · Weight: {Math.round((rows.find(r=>r.key==='infrastructure')?.weight ?? 0)*100)}%</div>
              </header>
              <div className="mt-2 flex items-center gap-2">
                <ScorePill value={typeof rows.find(r=>r.key==='infrastructure')?.raw === 'number' ? Math.round(rows.find(r=>r.key==='infrastructure')!.raw as number) : undefined} />
                <span className="text-sm font-semibold">🏨 Infrastructure</span>
              </div>
              <p className="mt-2 text-sm leading-6">{explainInfra(rows.find(r=>r.key==='infrastructure')?.raw)}</p>
              {renderFactorBreakdown(rows, 'infrastructure')}
            </section>
          </div>
        </div>
      </section>
    </>
  );
}
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
    <div className="mt-3 text-xs text-zinc-600 dark:text-zinc-400 grid grid-cols-3 gap-3">
      <div><span className="font-medium">Normalized:</span> {n.normalized ?? '—'}</div>
      <div><span className="font-medium">Weight:</span> {n.weightPct}%</div>
      <div><span className="font-medium">Contribution:</span> {n.contribution ?? '—'}</div>
    </div>
  );
}
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { headers } from 'next/headers';
import Image from 'next/image';
import type { CountryFacts } from '@/lib/facts';

type AdvisoryLite = { level?: 1|2|3|4; url?: string; summary?: string; updatedAt?: string };

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
  if (f.visaType === 'voa') {
    if ((typeof f.visaFeeUsd === 'number' && f.visaFeeUsd === 0) || (rounded != null && rounded >= 90)) {
      kind = 'Visa on arrival — free';
    } else if (typeof f.visaFeeUsd === 'number' && f.visaFeeUsd > 0) {
      kind = 'Visa on arrival — paid';
    }
  } else if (f.visaType === 'evisa') {
    if ((typeof f.visaFeeUsd === 'number' && f.visaFeeUsd === 0) || (rounded != null && rounded >= 60)) {
      kind = 'Free eVisa/ETA';
    } else if (typeof f.visaFeeUsd === 'number' && f.visaFeeUsd > 0) {
      kind = 'eVisa/ETA — paid';
    }
  }

  const days = typeof f.visaAllowedDays === 'number' ? `${Math.round(f.visaAllowedDays)} days` : undefined;
  const fee = typeof f.visaFeeUsd === 'number' && f.visaFeeUsd > 0 ? `fee about $${Math.round(f.visaFeeUsd)}` : undefined;
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

// --- Visa badge (strictly typed, no `any`) ----------------------------------
type VisaTypeLocal = FactsExtra['visaType'];

function resolveVisaBadge(
  visaType?: VisaTypeLocal,
  ease?: number,
  feeUsd?: number
): { label: string; emoji: string; tone: 'green' | 'yellow' | 'red' | 'black' } | null {
  const rounded = typeof ease === 'number' && Number.isFinite(ease) ? Math.round(ease) : undefined;

  // Helper flags
  const hasFee = typeof feeUsd === 'number' && Number.isFinite(feeUsd) && feeUsd > 0;
  const isFree = (typeof feeUsd === 'number' && feeUsd === 0);

  // --- Explicit type rules first
  if (visaType === 'visa_free' || rounded === 100) {
    return { label: 'Visa free', emoji: '✅', tone: 'green' };
  }

  if (visaType === 'voa') {
    // Treat unknown fee but very high ease as free; otherwise paid.
    if (isFree || (!hasFee && typeof rounded === 'number' && rounded >= 90)) {
      return { label: 'Visa on arrival — free', emoji: '✅', tone: 'green' };
    }
    if (hasFee) {
      return { label: 'Visa on arrival — paid', emoji: '⚠️', tone: 'yellow' };
    }
    // default when we don't know fee and ease isn’t clearly "free"
    return { label: 'Visa on arrival', emoji: '⚠️', tone: 'yellow' };
  }

  if (visaType === 'evisa') {
    if (isFree || (!hasFee && typeof rounded === 'number' && rounded >= 60)) {
      return { label: 'Free eVisa/ETA', emoji: '✅', tone: 'green' };
    }
    if (hasFee) {
      return { label: 'eVisa/ETA — paid', emoji: '⚠️', tone: 'yellow' };
    }
    return { label: 'eVisa/ETA', emoji: '⚠️', tone: 'yellow' };
  }

  if (visaType === 'visa_required') {
    return { label: 'Visa required', emoji: '⛔️', tone: 'red' };
  }

  if (visaType === 'ban' || rounded === 0) {
    return { label: 'Not allowed', emoji: '☠️', tone: 'black' };
  }

  // --- Score-only fallbacks
  if (typeof rounded === 'number') {
    if (rounded >= 80) return { label: 'Visa free', emoji: '✅', tone: 'green' };
    if (rounded >= 50) return { label: 'eVisa/VOA', emoji: '⚠️', tone: 'yellow' };
    if (rounded > 0)   return { label: 'Visa required', emoji: '⛔️', tone: 'red' };
    return { label: 'Not allowed', emoji: '☠️', tone: 'black' };
  }

  return null;
}

function VisaBadge({ visaType, ease, feeUsd }: { visaType?: VisaTypeLocal; ease?: number; feeUsd?: number }) {
  const badge = resolveVisaBadge(visaType, ease, feeUsd);
  if (!badge) return null;
  const toneClass =
    badge.tone === 'green'
      ? 'text-green-700'
      : badge.tone === 'yellow'
      ? 'text-yellow-700'
      : badge.tone === 'red'
      ? 'text-red-700'
      : 'text-zinc-800';
  return (
    <span className={`inline-flex items-center gap-2 text-sm ${toneClass}`}>
      <strong className="whitespace-nowrap font-semibold">{badge.label}</strong>
      <span className="ml-1" aria-hidden>
        {badge.emoji}
      </span>
    </span>
  );
}

// Minimal shape returned by /api/countries that we use on this page
type CountryRowLite = {
  iso2: string;
  name?: string;
  m49?: number | string;
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

// Derive an affordability score from common macro signals if an explicit one isn't provided.
// Higher = more affordable to a US traveler.
function computeAffordability(facts: FactsExtra): number | undefined {
  const f = facts;

  // Common fields we might have in the dataset
  const col = toNumber(f.costOfLivingIndex);    // e.g., Numbeo 0..120 (higher = more expensive)
  const food = toNumber(f.foodCostIndex);       // optional; higher = more expensive
  const gdp = toNumber(f.gdpPerCapitaUsd);      // 2k..80k typical

  // FX: local currency per 1 USD (higher → stronger USD → cheaper locally)
  const fxLocalPerUsd = toNumber(f.fxLocalPerUSD ?? f.localPerUSD ?? f.usdToLocalRate);

  const parts: number[] = [];

  if (col != null) {
    // Invert: lower COL → higher affordability. Typical 30..120
    parts.push(scaleTo100(col, 30, 120, /*invert*/ true));
  }
  if (food != null) {
    parts.push(scaleTo100(food, 20, 200, /*invert*/ true));
  }
  if (gdp != null) {
    // Lower GDP per capita often correlates with cheaper travel; invert.
    parts.push(scaleTo100(gdp, 2000, 80000, /*invert*/ true));
  }
  if (fxLocalPerUsd != null) {
    // More local units per USD → more purchasing power. 0.2..400 typical range across currencies.
    parts.push(scaleTo100(fxLocalPerUsd, 0.2, 400, /*invert*/ false));
  }

  if (parts.length === 0) return 50; // neutral fallback so UI shows an estimated value
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

type PageProps = { params: Promise<{ iso2?: string }> };
export default async function CountryPage({ params }: PageProps) {
  const { iso2: iso2Raw } = await params;
  const iso2 = (iso2Raw || "").toUpperCase();
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
  // Helper to fetch a row by key for the deep‑dive sections
  const getRow = (k: string) => rows.find(r => r.key === k);

  const fxFacts: Partial<FactsExtra> = facts as Partial<FactsExtra>;

  return (
    <div className="scribble max-w-4xl mx-auto px-6 py-8">
      <div className="mb-6">
        <Link href="/" className="text-sm text-blue-600 hover:underline">← Back</Link>
      </div>

      <div className="flex items-center gap-3 mb-2">
        <div className="relative">
          <span className="tape left" />
          <Image
            src={flagPng}
            alt={`${row.name ?? iso2} flag`}
            width={48}
            height={36}
            className="rounded shadow-sm ring-1 ring-black/10 dark:ring-white/10 bg-white"
            unoptimized
          />
        </div>
        <h1 className="text-3xl font-semibold">{row.name ?? iso2}</h1>
      </div>
      <p className="text-sm text-zinc-500 mb-6 tracking-wide">{iso2} • M49: {row.m49 ?? '—'}</p>

      <div className="grid md:grid-cols-3 gap-6 mb-8">
        <div className="md:col-span-2 paper paper--lined paper--tilt-sm p-5">
          <div className="flex items-baseline justify-between mb-2">
            <h2 className="font-medium">Overall Travelability Score</h2>
            <div className="text-3xl font-bold">{displayTotal}</div>
          </div>
          <p className="text-sm text-zinc-600">
            Weighted by your current formula. Missing signals are ignored and the remaining weights are re-normalized.
          </p>
        </div>

        <div className="paper paper--grid p-5">
          <h3 className="font-medium mb-2">Advisory</h3>
          <span className="tape right" />
          {row.advisory ? (
            <div className="text-sm">
              <div>Level {row.advisory.level}</div>
              {row.advisory.url ? (
                <a
                  className="text-blue-600 hover:underline"
                  href={row.advisory.url}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  travel.state.gov
                </a>
              ) : null}
              <div className="mt-2 text-zinc-600 line-clamp-5" dangerouslySetInnerHTML={{ __html: row.advisory.summary ?? '' }} />
            </div>
          ) : (
            <div className="text-sm text-zinc-500">No advisory found.</div>
          )}
        </div>
      </div>

      <div className="paper paper--lined p-5 mb-8 overflow-x-auto">
        <h3 className="font-medium mb-3">Score Breakdown</h3>
        <table className="w-full text-sm">
          <thead className="text-zinc-500">
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
                  {r.key === 'visa' ? (
                    <span className="inline-flex items-center justify-end gap-2">
                      <span>{r.raw != null ? Math.round(r.raw) : '—'}</span>
                      <span className="text-zinc-300" aria-hidden="true">|</span>
                      <VisaBadge
                        visaType={fxFacts?.visaType}
                        ease={typeof r.raw === 'number' ? Math.round(r.raw) : undefined}
                        feeUsd={typeof fxFacts?.visaFeeUsd === 'number' ? Number(fxFacts.visaFeeUsd) : undefined}
                      />
                    </span>
                  ) : (
                    r.raw != null ? Math.round(r.raw) : '—'
                  )}
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

      {/* Deep Dive: scrollable in‑depth explanation */}
      <section className="mt-10">
        <div className="flex gap-6">
          {/* Sticky in‑page nav */}
          <nav className="hidden md:block w-60 shrink-0 sticky top-24 self-start index-card index-card__ruled p-3">
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
            <section id="overview" className="scroll-mt-24 paper p-4">
              <h3 className="text-lg font-semibold mb-2">Why this score?</h3>
              <span className="tape left" />
              <p className="text-sm leading-6 text-zinc-700 dark:text-zinc-300">{explain(facts, rows)}</p>
            </section>

            {/* Advisory */}
            <section id="advisory" className="scroll-mt-24 paper p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Travel.gov advisory</h4>
                <div className="text-sm text-zinc-500">Raw: {getRow('travelGov')?.raw ?? '—'} · Weight: {Math.round((getRow('travelGov')?.weight ?? 0)*100)}%</div>
              </header>
              <p className="mt-2 text-sm leading-6">{explainAdvisory(row.name ?? iso2, row.advisory?.level as 1|2|3|4|undefined, row.advisory?.updatedAt)}</p>
              {renderFactorBreakdown(rows, 'travelGov')}
              <p className="mt-2 text-sm">This page is using Level {getRow('travelGov')?.raw ?? '—'} from the latest advisory.</p>
              {row.advisory?.url ? (
                <p className="mt-2 text-sm"><a className="underline" href={row.advisory.url} target="_blank" rel="noopener noreferrer">Read the full advisory</a></p>
              ) : null}
            </section>

            {/* TravelSafe */}
            <section id="travelsafe" className="scroll-mt-24 paper p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">TravelSafe Abroad</h4>
                <div className="text-sm text-zinc-500">Raw: {getRow('travelSafe')?.raw ?? '—'} · Weight: {Math.round((getRow('travelSafe')?.weight ?? 0)*100)}%</div>
              </header>
              <p className="mt-2 text-sm leading-6">{explainTravelSafe(getRow('travelSafe')?.raw)}</p>
              {renderFactorBreakdown(rows, 'travelSafe')}
            </section>

            {/* Solo Female */}
            <section id="solofemale" className="scroll-mt-24 paper p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Solo Female Travelers</h4>
                <div className="text-sm text-zinc-500">Raw: {getRow('sfti')?.raw ?? '—'} · Weight: {Math.round((getRow('sfti')?.weight ?? 0)*100)}%</div>
              </header>
              <p className="mt-2 text-sm leading-6">{explainSFTI(getRow('sfti')?.raw)}</p>
              {renderFactorBreakdown(rows, 'sfti')}
            </section>

            {/* Reddit */}
            <section id="reddit" className="scroll-mt-24 paper p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Reddit sentiment</h4>
                <div className="text-sm text-zinc-500">Raw: {getRow('reddit')?.raw ?? '—'} · Weight: {Math.round((getRow('reddit')?.weight ?? 0)*100)}%</div>
              </header>
              <span className="tape right" />
              <p className="mt-2 text-sm leading-6">{explainReddit((facts as FactsExtra)?.redditThemes, fxFacts?.redditSummary)}</p>
              {renderFactorBreakdown(rows, 'reddit')}
              {fxFacts?.redditSummary && (
                <p className="mt-2 text-sm leading-6 italic">Summary: {fxFacts.redditSummary}</p>
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
            <section id="seasonality" className="scroll-mt-24 paper p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Seasonality (now)</h4>
                <div className="text-sm text-zinc-500">Raw: {getRow('seasonality')?.raw ?? '—'} · Weight: {Math.round((getRow('seasonality')?.weight ?? 0)*100)}%</div>
              </header>
              <p className="mt-2 text-sm leading-6">
                {(() => {
                  const fm = fxFacts as Partial<FactsExtra>;
                  if (fm.fmSeasonalityBestMonths?.length || fm.fmSeasonalityTodayLabel) {
                    const text = describeSeasonalityFM(fm);
                    const src = fm.fmSeasonalitySource;
                    return (
                      <>
                        {text}
                        {src ? (
                          <> {' '}<a className="underline" href={src} target="_blank" rel="noopener noreferrer">Source: Frequent Miler</a></>
                        ) : null}
                      </>
                    );
                  }
                  return explainSeasonality(getRow('seasonality')?.raw);
                })()}
              </p>
              {fxFacts?.fmSeasonalityAreas?.length ? (
                <ul className="mt-2 text-sm list-disc ml-6">
                  {fxFacts.fmSeasonalityAreas.slice(0,3).map((a, i) => (
                    <li key={i}>{a.area ? `${a.area}: ` : ''}{listMonths(a.months)}</li>
                  ))}
                </ul>
              ) : null}
              {renderFactorBreakdown(rows, 'seasonality')}
            </section>

            {/* Visa */}
            <section id="visa" className="scroll-mt-24 paper p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Visa ease (US passport)</h4>
                <div className="text-sm text-zinc-500">Raw: {getRow('visa')?.raw ?? '—'} · Weight: {Math.round((getRow('visa')?.weight ?? 0)*100)}%</div>
              </header>
              {(() => {
                const raw = getRow('visa')?.raw;
                const easeNum = typeof raw === 'number' ? Math.round(raw) : undefined;
                return (
                  <div className="mt-2 flex items-center gap-2">
                    <span
                      className={`inline-flex h-7 min-w-[2.25rem] items-center justify-center rounded-full border px-2 text-sm font-semibold ${scoreBadgeClass(easeNum)}`}
                      title="Visa ease score"
                    >
                      {easeNum ?? '—'}
                    </span>
                    <span className="text-zinc-300" aria-hidden="true">|</span>
                    <VisaBadge
                      visaType={fxFacts?.visaType}
                      ease={easeNum}
                      feeUsd={typeof fxFacts?.visaFeeUsd === 'number' ? Number(fxFacts.visaFeeUsd) : undefined}
                    />
                  </div>
                );
              })()}
              <p className="mt-2 text-sm leading-6">
                {describeVisa(fxFacts, getRow('visa')?.raw)}
                {fxFacts?.visaSource ? (
                  <> {' '}<a className="underline" href={fxFacts.visaSource} target="_blank" rel="noopener noreferrer">Source</a></>
                ) : null}
              </p>
              <ul className="mt-2 text-sm list-disc ml-6">
                {fxFacts?.visaType && (<li>Type: {titleForVisaType(fxFacts.visaType)}</li>)}
                {typeof fxFacts?.visaAllowedDays === 'number' && (<li>Allowed stay: {Math.round(Number(fxFacts.visaAllowedDays))} days</li>)}
                {typeof fxFacts?.visaFeeUsd === 'number' && (<li>Approx. fee: {'$' + Math.round(Number(fxFacts.visaFeeUsd)).toLocaleString()}</li>)}
                {fxFacts?.visaNotes && (<li>Notes: {fxFacts.visaNotes}</li>)}
              </ul>
              {renderFactorBreakdown(rows, 'visa')}
            </section>

            {/* Affordability */}
            <section id="affordability" className="scroll-mt-24 paper p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Affordability</h4>
                <div className="text-sm text-zinc-500">Raw: {getRow('affordability')?.raw ?? '—'} · Weight: {Math.round((getRow('affordability')?.weight ?? 0)*100)}%</div>
              </header>
              <span className="tape right" />
              <p className="mt-2 text-sm leading-6">{explainAffordability(fxFacts)}</p>
              {renderFactorBreakdown(rows, 'affordability')}
              <ul className="mt-2 text-sm list-disc ml-6">
                {fxFacts?.costOfLivingIndex != null && (
                  <li>Cost-of-living index: {Math.round(Number(fxFacts.costOfLivingIndex))}</li>
                )}
                {fxFacts?.foodCostIndex != null && (
                  <li>Food cost index: {Math.round(Number(fxFacts.foodCostIndex))}</li>
                )}
                {fxFacts?.gdpPerCapitaUsd != null && (
                  <li>GDP per capita: {'$' + Math.round(Number(fxFacts.gdpPerCapitaUsd)).toLocaleString()}</li>
                )}
                {fxFacts?.fxLocalPerUSD != null && (
                  <li>Local currency per USD: {Number(fxFacts.fxLocalPerUSD)}</li>
                )}
                {(fxFacts?.costOfLivingIndex == null && fxFacts?.gdpPerCapitaUsd == null && fxFacts?.fxLocalPerUSD == null) && (
                  <li>Using neutral baseline until we enrich GDP/FX/COL inputs for this country.</li>
                )}
              </ul>
            </section>

            {/* Flight */}
            <section id="flight" className="scroll-mt-24 paper p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Direct flight</h4>
                <div className="text-sm text-zinc-500">Raw: {getRow('directFlight')?.raw ?? '—'} · Weight: {Math.round((getRow('directFlight')?.weight ?? 0)*100)}%</div>
              </header>
              <p className="mt-2 text-sm leading-6">{explainFlights(getRow('directFlight')?.raw)}</p>
              {renderFactorBreakdown(rows, 'directFlight')}
            </section>

            {/* Infrastructure */}
            <section id="infrastructure" className="scroll-mt-24 paper p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Tourist infrastructure</h4>
                <div className="text-sm text-zinc-500">Raw: {getRow('infrastructure')?.raw ?? '—'} · Weight: {Math.round((getRow('infrastructure')?.weight ?? 0)*100)}%</div>
              </header>
              <p className="mt-2 text-sm leading-6">{explainInfra(getRow('infrastructure')?.raw)}</p>
              {renderFactorBreakdown(rows, 'infrastructure')}
            </section>
          </div>
        </div>
      </section>
    </div>
  );
}
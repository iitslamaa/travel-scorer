import Link from 'next/link';
import { notFound } from 'next/navigation';
import { headers } from 'next/headers';
import Image from 'next/image';
import type { CountryFacts } from '@travel-af/shared';
import { AdvisoryBadge } from '@/lib/display/AdvisoryBadge';
import { VisaBadge } from '@/lib/display/VisaBadge';
import { TravelSafeSection } from '@/lib/display/TravelSafeSection';
import { SoloFemaleSection } from '@/lib/display/SoloFemaleSection';
import { ScorePill } from '@/lib/display/ScorePill';
import { VisaSection } from './components/VisaSection';
import { Seasonality } from './components/Seasonality';
import { AffordabilitySection } from "./components/AffordabilitySection";
import { buildRows } from '@travel-af/domain';
import type { FactRow } from '@travel-af/domain';

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

function toPct(n: number) {
  return `${Math.round(n * 100)}%`;
}

// Minimal advisory shape from /api/countries
type AdvisoryLite = { level?: 1|2|3|4; url?: string; summary?: string; updatedAt?: string };

// Shape attached by the API for estimated daily spend (hotel/hostel/transport breakdown)
type DailySpendLocal = {
  foodUsd: number;
  activitiesUsd: number;
  hotelUsd: number;
  totalUsd: number;
  hostelUsd?: number;
  transportUsd?: number;
  basis?: { col?: number; food?: number };
  notes?: string[];
};

// Extra optional fields we may have in our dataset for derived metrics
type FactsExtra = CountryFacts & {
  costOfLivingIndex?: number;
  foodCostIndex?: number;
  housingCostIndex?: number;
  transportCostIndex?: number;
  gdpPerCapitaUsd?: number;
  fxLocalPerUSD?: number;
  localPerUSD?: number;
  usdToLocalRate?: number;
  redditThemes?: string[];
  redditSummary?: string;
  affordability?: number;            // 0–100, cheap = 100
  affordabilityCategory?: number;    // 1 = cheapest, 10 = most expensive
  averageDailyCostUsd?: number;      // per-person daily cost in USD
  // Computed by API or estimator
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
  fmSeasonalityNotes?: string;
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

type CountriesLiteResponse = {
  countries: CountryRowLite[];
};

function isCountriesLiteResponse(json: unknown): json is CountriesLiteResponse {
  return (
    typeof json === 'object' &&
    json !== null &&
    Array.isArray((json as CountriesLiteResponse).countries)
  );
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
  const parts: string[] = [];

  const cat = fx.affordabilityCategory;
  const daily = fx.averageDailyCostUsd;

  if (typeof cat === 'number') {
    if (cat === 1) {
      parts.push('This is among the cheapest destinations in the dataset (cost level 1 out of 10).');
    } else if (cat === 10) {
      parts.push('This is among the most expensive destinations in the dataset (cost level 10 out of 10).');
    } else {
      parts.push(`Overall cost level is ${cat} out of 10 compared with other countries.`);
    }
  }

  if (typeof daily === 'number' && Number.isFinite(daily)) {
    parts.push(`Typical daily spend for one traveler lands around ${fmtUSD(daily)} when you combine housing, food, and local transport.`);
  }

  // Fall back to macro indicators if we don't have good direct cost data
  if (!parts.length) {
    const col = fx.costOfLivingIndex;
    const food = fx.foodCostIndex;
    const gdp = fx.gdpPerCapitaUsd;
    const rate = pick(fx.fxLocalPerUSD, fx.localPerUSD, fx.usdToLocalRate);
    const macro: string[] = [];
    if (col != null) macro.push(`cost-of-living index ≈ ${Math.round(col)}`);
    if (food != null) macro.push(`food cost index ≈ ${Math.round(food)}`);
    if (gdp != null) macro.push(`GDP per capita ≈ ${fmtUSD(gdp)}`);
    if (rate != null) macro.push(`about ${rate} local units per USD`);
    if (!macro.length) return 'Using a neutral affordability baseline until we have better cost-of-living and price data.';
    return `Estimated using ${macro.join(', ')}. Lower COL/food and a stronger USD generally make a destination feel cheaper on the ground.`;
  }

  return parts.join(' ');
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
      const json: CountriesLiteResponse | CountryRowLite[] | unknown = await res.json();
      if (Array.isArray(json)) {
        all = json as CountryRowLite[];
      } else if (isCountriesLiteResponse(json)) {
        all = json.countries;
      } else {
        all = [];
      }
    }
  } catch (_) {
    // fall through to notFound below
  }
  const row = all.find((c) => ((c.iso2 || '').toUpperCase()) === iso2);
  if (!row) {
    notFound();
  }

  const facts: CountryFacts = { iso2, ...(row.facts ?? {}) };
  const { rows, total }: { rows: FactRow[]; total: number } = buildRows(facts);
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
                  Raw: {rows.find(r => r.key === 'travelGov')?.raw ?? '—'}
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
                <h4 className="font-medium flex items-center gap-2">
                  <span>📅 Seasonality</span>
                </h4>
                <div className="text-sm muted">
                  Raw: {rows.find(r=>r.key==='seasonality')?.raw ?? '—'} · Weight:{' '}
                  {Math.round((rows.find(r=>r.key==='seasonality')?.weight ?? 0) * 100)}%
                </div>
              </header>

              {/* Single headline + summary comes from the component */}
              <Seasonality
                rows={rows}
                fm={{
                  best: fxFacts?.fmSeasonalityBestMonths,
                  todayLabel: fxFacts?.fmSeasonalityTodayLabel,
                  hasDual: fxFacts?.fmSeasonalityHasDualPeak,
                  areas: fxFacts?.fmSeasonalityAreas,
                  source: fxFacts?.fmSeasonalitySource,
                  notes: fxFacts?.fmSeasonalityNotes,
                }}
              />

              {renderFactorBreakdown(rows, 'seasonality')}
            </section>

            {/* Visa */}
            <section id="visa" className="scroll-mt-24 card p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium flex items-center gap-2">
                  <span>🛂 Visa ease (US passport)</span>
                </h4>
                <div className="text-sm muted">
                  Raw: {rows.find((r) => r.key === 'visa')?.raw ?? '—'} · Weight:{' '}
                  {Math.round((rows.find((r) => r.key === 'visa')?.weight ?? 0) * 100)}%
                </div>
              </header>
              <VisaSection rows={rows} facts={facts} />
              {renderFactorBreakdown(rows, 'visa')}
            </section>

            {/* Affordability */}
            <section id="affordability" className="scroll-mt-24 card p-4">
              <header className="flex items-baseline justify-between">
                <h4 className="font-medium">Affordability</h4>
                <div className="text-sm muted">
                  Raw: {rows.find(r=>r.key==='affordability')?.raw ?? '—'} · Weight:{' '}
                  {Math.round((rows.find(r=>r.key==='affordability')?.weight ?? 0)*100)}%
                </div>
              </header>

              <div className="mt-2 flex items-center gap-2">
                <ScorePill
                  value={
                    typeof rows.find(r=>r.key==='affordability')?.raw === 'number'
                      ? Math.round(rows.find(r=>r.key==='affordability')!.raw as number)
                      : undefined
                  }
                />
                <span className="text-sm font-semibold">💵 Costs</span>
              </div>

              <p className="mt-2 text-sm leading-6">
                {explainAffordability(facts as Partial<FactsExtra>)}
              </p>

              {renderFactorBreakdown(rows, 'affordability')}

              {(() => {
                const daily = pickDailySpend(facts as Partial<FactsExtra>);
                if (!daily) return null;

                return (
                  <ul className="mt-2 text-sm list-disc ml-6">
                    {daily.hotelUsd != null && (
                      <li>Hotel (mid-range, nightly): {fmtUSD(daily.hotelUsd)}</li>
                    )}
                    {daily.hostelUsd != null && (
                      <li>Hostel (budget, nightly): {fmtUSD(daily.hostelUsd)}</li>
                    )}
                    {daily.foodUsd != null && (
                      <li>Food (daily): {fmtUSD(daily.foodUsd)}</li>
                    )}
                    {daily.transportUsd != null && (
                      <li>Transport (daily): {fmtUSD(daily.transportUsd)}</li>
                    )}
                    {daily.activitiesUsd != null && (
                      <li>Activities / extras (daily): {fmtUSD(daily.activitiesUsd)}</li>
                    )}
                    <li className="font-medium">Estimated daily total: {fmtUSD(daily.totalUsd)}</li>
                  </ul>
                );
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
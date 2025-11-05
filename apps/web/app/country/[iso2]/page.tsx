import Link from 'next/link';
import { notFound } from 'next/navigation';
import { headers } from 'next/headers';
import type { CountryFacts } from '@/lib/facts';

type AdvisoryLite = { level?: 1|2|3|4; url?: string; summary?: string };

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
    { key: 'affordability', label: 'Affordability',          value: facts.affordability },
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

  const infra = get('infrastructure')?.raw;
  if (infra != null) parts.push(`Tourist infrastructure is rated ${Math.round(infra)}.`);

  const visa = get('visa')?.raw;
  if (visa != null) parts.push(`Visa ease is ${Math.round(visa)} for US passport holders.`);

  const flight = get('directFlight')?.raw;
  if (flight != null) {
    const hasDirect = Number(flight) >= 100; // our data encodes direct as 100
    parts.push(`${hasDirect ? 'Direct' : 'No direct'} flight from NYC considered in score.`);
  }

  if (parts.length === 0) return 'We do not have enough data points yet. Scores default to a neutral baseline.';
  return parts.join(' ');
}

type PageProps = { params: Promise<{ iso2?: string }> };
export default async function CountryPage({ params }: PageProps) {
  const { iso2: iso2Raw } = await params;
  const iso2 = (iso2Raw || "").toUpperCase();
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

  return (
    <div className="max-w-4xl mx-auto px-6 py-8">
      <div className="mb-6">
        <Link href="/" className="text-sm text-blue-600 hover:underline">← Back</Link>
      </div>

      <h1 className="text-3xl font-semibold mb-1">{row.name ?? iso2}</h1>
      <p className="text-sm text-zinc-500 mb-6">{iso2} • M49: {row.m49 ?? '—'}</p>

      <div className="grid md:grid-cols-3 gap-6 mb-8">
        <div className="md:col-span-2 rounded-lg border p-5">
          <div className="flex items-baseline justify-between mb-2">
            <h2 className="font-medium">Overall Travelability Score</h2>
            <div className="text-3xl font-bold">{total}</div>
          </div>
          <p className="text-sm text-zinc-600">
            Weighted by your current formula. Missing signals are ignored and the remaining weights are re-normalized.
          </p>
        </div>

        <div className="rounded-lg border p-5">
          <h3 className="font-medium mb-2">Advisory</h3>
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

      <div className="rounded-lg border p-5 mb-8 overflow-x-auto">
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
                <td className="p-2 text-right">{r.raw != null ? Math.round(r.raw) : '—'}</td>
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
              <td className="p-2 text-right font-semibold">{total}</td>
            </tr>
          </tfoot>
        </table>
      </div>

      <div className="rounded-lg border p-5">
        <h3 className="font-medium mb-2">Why this score?</h3>
        <p className="text-sm text-zinc-700">{explain(facts, rows)}</p>
      </div>
    </div>
  );
}
import { ScorePill } from '@/lib/display/ScorePill';

type FM = {
  best?: number[];
  todayLabel?: 'best' | 'good' | 'shoulder' | 'poor';
  hasDual?: boolean;
  areas?: { area?: string; months: number[] }[];
  source?: string;
  notes?: string;
};

type Props = { raw?: number; fm?: FM };

function monthName(n: number) {
  return ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][
    Math.max(1, Math.min(12, n)) - 1
  ];
}

function listMonths(ms: number[]) {
  const uniq = Array.from(new Set(ms.filter((m) => m >= 1 && m <= 12))).sort((a, b) => a - b);
  return uniq.map(monthName).join(', ');
}

function fallbackSummary(raw?: number) {
  if (typeof raw !== 'number') return 'No seasonality data; treated as neutral timing.';
  if (raw >= 80) return 'Perfect timing! Weather and crowd patterns are ideal right now.';
  if (raw >= 60) return 'Shoulder season — could be fun! Expect decent conditions with mild tradeoffs.';
  if (raw >= 40) return 'Reconsider going during this time — conditions may not be ideal.';
  return 'Reconsider going during this time — this is generally a low‑season period.';
}

export function SeasonalitySection({ raw, fm }: Props) {
  // Emoji + short verdict based strictly on our todayLabel buckets
  let override: string | null = null;
  if (fm?.todayLabel === 'best') {
    override = 'Perfect timing! Weather and crowd patterns are ideal right now.';
  } else if (fm?.todayLabel === 'shoulder') {
    override = 'Shoulder season — could be fun! Expect decent conditions with mild tradeoffs.';
  } else if (fm?.todayLabel === 'good' || fm?.todayLabel === 'poor') {
    override = 'Reconsider going during this time — conditions may not be ideal.';
  }

  const parts: string[] = [];

  if (fm?.best?.length) parts.push(`Best months: ${listMonths(fm.best)}.`);
  if (fm?.todayLabel) parts.push(`If you go now: ${fm.todayLabel}.`);
  if (fm?.hasDual) parts.push('There appear to be two distinct peak seasons.');
  if (fm?.areas?.length) {
    const top = fm.areas
      .slice(0, 3)
      .map((a) => (a.area ? `${a.area} (${listMonths(a.months)})` : listMonths(a.months)));
    parts.push(`Popular regions/windows: ${top.join('; ')}.`);
  }

  const base = parts.length ? parts.join(' ') : fallbackSummary(raw);
  const text = override
    ? `${override} ${
        fm?.best?.length && fm.todayLabel !== 'best'
          ? ` Peak months: ${listMonths(fm.best)}.`
          : ''
      }`
    : base;

  const note = fm?.notes ? ` ${fm.notes}` : '';

  const label =
    fm?.todayLabel === 'best'
      ? 'Peak time to go'
      : fm?.todayLabel === 'shoulder'
        ? 'Shoulder season'
        : fm?.todayLabel === 'good' || fm?.todayLabel === 'poor'
          ? 'Not ideal visiting time'
          : 'No seasonality data';

  const labelColor =
    fm?.todayLabel === 'best'
      ? 'text-green-800'
      : fm?.todayLabel === 'shoulder'
        ? 'text-green-800'
        : fm?.todayLabel === 'good' || fm?.todayLabel === 'poor'
          ? 'text-red-700'
          : 'text-zinc-900';

  const labelEmoji =
    fm?.todayLabel === 'best'
      ? '✅'
      : fm?.todayLabel === 'shoulder'
        ? '✅'
        : fm?.todayLabel === 'good'
          ? '⚠️'
          : fm?.todayLabel === 'poor'
            ? '🛑'
            : undefined;

  return (
    <>
      {/* headline row: pill + label, Visa-style */}
      <div className="mt-2 flex items-center gap-3">
        <ScorePill value={typeof raw === 'number' ? Math.round(raw) : undefined} />
        <span className="text-xs text-zinc-300" aria-hidden="true">
          |
        </span>
        <span className={`text-sm font-semibold inline-flex items-center gap-1 ${labelColor}`}>
          {label}
          {labelEmoji && <span aria-hidden="true">{labelEmoji}</span>}
        </span>
      </div>
      <p className="mt-2 text-sm leading-6">
        {text}
        {note ? (
          <>
            {' '}
            <span className="font-medium">{note}</span>
          </>
        ) : null}
      </p>
    </>
  );
}
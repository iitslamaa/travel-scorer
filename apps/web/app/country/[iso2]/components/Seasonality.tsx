import { SeasonalitySection as SeasonalityCard } from '@/lib/display/SeasonalitySection';
import type { FactRow } from '@travel-af/domain';

type SeasonalityFM = {
  best?: number[];
  todayLabel?: 'best' | 'good' | 'shoulder' | 'poor';
  hasDual?: boolean;
  areas?: { area?: string; months: number[] }[];
  source?: string;
  notes?: string;
};

type SeasonalityProps = {
  rows: FactRow[];
  fm: SeasonalityFM;
};

export function Seasonality({ rows, fm }: SeasonalityProps) {
  const row = rows.find((r) => r.key === 'seasonality');
  const raw = row?.raw;

  // Treat FM data as "present" only if we actually have some months, label, or area entries
  const hasFM =
    (fm?.best && fm.best.length > 0) ||
    typeof fm?.todayLabel === 'string' ||
    (fm?.areas && fm.areas.length > 0);

  // If there is no numeric seasonality score AND no FM metadata,
  // show a clear fallback instead of pretending we have data.
  if (!hasFM && typeof raw !== 'number') {
    return (
      <div className="space-y-2">
        <div className="flex items-center gap-2">
          <span className="text-xl">📅</span>
          <div>
            <div className="text-sm font-semibold">Seasonality</div>
            <p className="text-sm muted">
              We don&apos;t yet have seasonality data from Frequent Miler for this destination.
              For now this factor is treated as neutral in the overall Travelability score.
            </p>
          </div>
        </div>
      </div>
    );
  }

  // Normal case: delegate to the shared Seasonality display card,
  // passing through the canonical score row + FM enrichments.
  return <SeasonalityCard raw={raw} fm={fm} />;
}
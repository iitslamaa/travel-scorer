import { ScorePill } from '@/lib/display/ScorePill';
import { VisaBadge } from '@/lib/display/VisaBadge';
import type { CountryFacts } from '@/lib/facts';
import type { FactRow } from '../page';

type VisaFacts = CountryFacts & {
  visaType?: 'visa_free' | 'voa' | 'evisa' | 'visa_required' | 'ban';
  visaAllowedDays?: number;
  visaFeeUsd?: number;
  visaNotes?: string;
  visaSource?: string;
};

function titleForVisaType(t?: VisaFacts['visaType']) {
  switch (t) {
    case 'visa_free': return 'Visa-free';
    case 'voa': return 'Visa on arrival';
    case 'evisa': return 'eVisa';
    case 'visa_required': return 'Visa required';
    case 'ban': return 'Entry not permitted';
    default: return undefined;
  }
}

function describeVisa(f: Partial<VisaFacts>, raw?: number) {
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

  const days = typeof f.visaAllowedDays === 'number'
    ? `${Math.round(f.visaAllowedDays)} days`
    : undefined;
  const fee = hasFee ? `fee about $${Math.round(f.visaFeeUsd as number)}` : undefined;
  const bits = [kind, days, fee].filter(Boolean).join(' · ');
  const fallback = typeof rounded === 'number'
    ? `Visa ease score ${rounded}`
    : 'Visa info not available';
  const note = f.visaNotes ? ` ${f.visaNotes}` : '';
  return (bits || fallback) + note;
}

type VisaSectionProps = {
  rows: FactRow[];
  facts: CountryFacts;
};

export function VisaSection({ rows, facts }: VisaSectionProps) {
  const visaFacts = facts as VisaFacts;
  const row = rows.find((r) => r.key === 'visa');
  const raw = row?.raw;
  const easeNum = typeof raw === 'number' ? Math.round(raw) : undefined;

  return (
    <>
      <div className="mt-2 flex items-center gap-3">
        <ScorePill value={easeNum} />
        <span
          className="text-xs text-zinc-300"
          aria-hidden="true"
        >
          |
        </span>
        <span
          className={`text-sm font-semibold inline-flex items-center gap-2 ${
            easeNum == null
              ? 'text-zinc-700'
              : easeNum >= 80
                ? 'text-emerald-800'
                : easeNum >= 60
                  ? 'text-amber-700'
                  : 'text-red-700'
          }`}
        >
          <VisaBadge
            visaType={visaFacts.visaType}
            ease={easeNum}
            feeUsd={
              typeof visaFacts.visaFeeUsd === 'number'
                ? Number(visaFacts.visaFeeUsd)
                : undefined
            }
          />
        </span>
      </div>
      <p className="mt-2 text-sm leading-6">
        {describeVisa(visaFacts, raw)}
        {visaFacts.visaSource ? (
          <>
            {' '}
            <a
              className="underline"
              href={visaFacts.visaSource}
              target="_blank"
              rel="noopener noreferrer"
            >
              Source
            </a>
          </>
        ) : null}
      </p>
      <ul className="mt-2 text-sm list-disc ml-6">
        {visaFacts.visaType && (
          <li>Type: {titleForVisaType(visaFacts.visaType)}</li>
        )}
        {typeof visaFacts.visaAllowedDays === 'number' && (
          <li>
            Allowed stay:{' '}
            {Math.round(Number(visaFacts.visaAllowedDays))} days
          </li>
        )}
        {typeof visaFacts.visaFeeUsd === 'number' && (
          <li>
            Approx. fee:{' '}
            {'$' + Math.round(Number(visaFacts.visaFeeUsd)).toLocaleString()}
          </li>
        )}
        {visaFacts.visaNotes && <li>Notes: {visaFacts.visaNotes}</li>}
      </ul>
    </>
  );
}
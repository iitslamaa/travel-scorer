import { NextResponse } from 'next/server';
import { headers } from 'next/headers';

export const dynamic = 'force-dynamic';

type AdvisoryLite = {
  iso2?: string; // 2‑letter ISO code if present
};

export async function GET() {
  // Build a safe base URL for both local dev and deployed environments
  const h = await headers();
  const envBase = process.env.NEXT_PUBLIC_BASE_URL?.replace(/\/+$/, '');
  const host = h.get('x-forwarded-host') ?? h.get('host') ?? 'localhost:3000';
  const proto = h.get('x-forwarded-proto') ?? (host.includes('localhost') ? 'http' : 'https');
  const base = envBase || `${proto}://${host}`;

  let advisories: AdvisoryLite[] = [];
  try {
    const advRes = await fetch(`${base}/api/advisories`, { cache: 'no-store' });
    if (advRes.ok) {
      const json = await advRes.json();
      if (Array.isArray(json)) {
        advisories = json as AdvisoryLite[];
      }
    }
  } catch {
    // swallow — this endpoint is for debugging; return zeros below
  }

  const isIso2 = (v: unknown): v is string => typeof v === 'string' && v.length === 2;

  const missingIso2 = advisories.filter(a => !isIso2(a?.iso2)).length;

  const iso2Upper = new Set(
    advisories
      .map(a => (isIso2(a?.iso2) ? (a.iso2 as string).toUpperCase() : null))
      .filter(Boolean) as string[]
  );

  return NextResponse.json({
    advisories: advisories.length,
    missingIso2,
    distinctIso2: iso2Upper.size,
    sample: advisories.slice(0, 3), // tiny sample to eyeball shape
    baseUsed: base,
  });
}
// apps/web/app/api/country/[iso2]/route.ts
import { NextResponse } from 'next/server';
import { countries } from '@travel-af/data';

// If you already compute richer fields elsewhere, you can merge them here.
export async function GET(
  _req: Request,
  { params }: { params: { iso2: string } }
) {
  const code = (params.iso2 || '').toUpperCase();
  const base = countries.find(c => c.iso2 === code);
  if (!base) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  // TODO (optional): merge richer data here if you have a separate source
  // const rich = await loadRicherCountryData(code);

  return NextResponse.json({
    ...base,
    // ...rich,
  });
}
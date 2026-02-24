// apps/web/app/api/country/[iso2]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { COUNTRY_SEEDS } from '@/lib/seed';
import { loadFacts } from '@/lib/facts';
import type { CountryFacts } from '@travel-af/shared';
import { buildVisaIndex } from '@/lib/providers/visa';
import { gdpPerCapitaUSDMap } from '@/lib/providers/worldbank';
import { fxLocalPerUSDMapByIso2 } from '@/lib/providers/fx';
import { estimateDailySpendHotel } from '@/lib/providers/costs';
import type { DailySpend } from '@/lib/providers/costs';
import { buildRows, DEFAULT_WEIGHTS } from '@travel-af/domain/src/scoring';
import { createServerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';

export async function GET(
  _req: NextRequest,
  ctx: { params: Promise<{ iso2: string }> }
) {
  const { iso2 } = await ctx.params;
  const isoUpper = iso2.toUpperCase();

  const seed = COUNTRY_SEEDS.find(c => c.iso2.toUpperCase() === isoUpper);
  if (!seed) {
    return NextResponse.json({ error: 'Country not found' }, { status: 404 });
  }

  // --- Load user weights (same logic as list endpoint)
  let userWeights = DEFAULT_WEIGHTS;
  try {
    const cookieStore = await cookies();
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          get(name: string) {
            return cookieStore.get(name)?.value;
          },
        },
      }
    );

    const { data: { user } } = await supabase.auth.getUser();

    if (user) {
      const { data } = await supabase
        .from('user_score_preferences')
        .select('advisory, seasonality, visa, affordability')
        .eq('user_id', user.id)
        .maybeSingle();

      if (data) {
        userWeights = {
          travelGov: (data as any).advisory ?? DEFAULT_WEIGHTS.travelGov,
          seasonality: (data as any).seasonality ?? DEFAULT_WEIGHTS.seasonality,
          visa: (data as any).visa ?? DEFAULT_WEIGHTS.visa,
          affordability: (data as any).affordability ?? DEFAULT_WEIGHTS.affordability,
        };
      }
    }
  } catch {}

  // --- Heavy enrichment for ONE country only
  const isoList = [isoUpper];

  const factsByIso2 = await loadFacts(isoList, []);
  const visaIndex = await buildVisaIndex();
  const [gdpMap, fxMap] = await Promise.all([
    gdpPerCapitaUSDMap(isoList),
    fxLocalPerUSDMapByIso2(isoList),
  ]);

  const facts = factsByIso2[isoUpper] as CountryFacts | undefined;

  const enriched: any = {
    ...seed,
    facts: facts ?? {},
  };

  const visa = visaIndex.get(isoUpper);
  if (visa) {
    enriched.facts = {
      ...enriched.facts,
      visaEase: visa.visaEase,
      visaType: visa.visaType,
      visaAllowedDays: visa.allowedDays,
      visaFeeUsd: visa.feeUsd,
      visaNotes: visa.notes,
      visaSource: visa.sourceUrl,
    };
  }

  if (gdpMap[isoUpper]) {
    enriched.facts.gdpPerCapitaUsd = gdpMap[isoUpper];
  }

  if (fxMap[isoUpper]) {
    enriched.facts.fxLocalPerUSD = fxMap[isoUpper];
  }

  // Compute daily spend (lightweight single-country version)
  try {
    const spend: DailySpend | undefined = estimateDailySpendHotel({
      costOfLivingIndex: enriched.facts.costOfLivingIndex,
      foodCostIndex: enriched.facts.foodCostIndex,
      housingCostIndex: enriched.facts.housingCostIndex,
      transportCostIndex: enriched.facts.transportCostIndex,
      fxLocalPerUSD: enriched.facts.fxLocalPerUSD,
      gdpPerCapitaUsd: enriched.facts.gdpPerCapitaUsd,
    });

    if (spend) {
      enriched.facts.dailySpend = spend;
    }
  } catch {}

  // --- Compute total score with user weights
  try {
    const { total } = buildRows(enriched.facts as CountryFacts, userWeights);
    enriched.scoreTotal = total;
  } catch {
    enriched.scoreTotal = 50;
  }

  return NextResponse.json(enriched);
}
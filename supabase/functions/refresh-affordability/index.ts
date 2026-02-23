import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type WdiItem = {
  country?: { id?: string };
  date?: string;
  value?: number | null;
};

function labelForCategory(cat: number) {
  if (cat <= 2) return "Extremely Affordable";
  if (cat <= 4) return "Affordable";
  if (cat <= 6) return "Moderate";
  if (cat <= 8) return "Expensive";
  return "Very Expensive";
}

// Fixed absolute range buckets
function categoryFromMetric(metric: number) {
  const MIN = 0.2;
  const MAX = 2.7;
  const width = (MAX - MIN) / 10;

  const clamped = Math.max(MIN, Math.min(MAX, metric));
  const idx = Math.floor((clamped - MIN) / width) + 1;
  return Math.max(1, Math.min(10, idx === 11 ? 10 : idx));
}

async function fetchLatestWdiIndicator(indicator: string) {
  const url =
    `https://api.worldbank.org/v2/country/all/indicator/${indicator}?format=json&per_page=20000`;

  const res = await fetch(url);
  if (!res.ok) throw new Error(`WorldBank fetch failed: ${res.status}`);
  const json = await res.json();
  const data: WdiItem[] = Array.isArray(json) ? json[1] : [];
  return data;
}

serve(async () => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const sb = createClient(supabaseUrl, serviceKey);

    const priceLevel = await fetchLatestWdiIndicator("PA.NUS.PPPC.RF");

    const latestByIso2 = new Map<string, { year: number; value: number }>();

    for (const item of priceLevel) {
      const iso2 = item.country?.id;
      const year = Number(item.date);
      const value = item.value;

      if (!iso2 || !Number.isFinite(year) || value == null) continue;

      const prev = latestByIso2.get(iso2);
      if (!prev || year > prev.year) {
        latestByIso2.set(iso2, { year, value });
      }
    }

    const sourceRows: any[] = [];
    const derivedRows: any[] = [];

    for (const [iso2, data] of latestByIso2.entries()) {
      const category = categoryFromMetric(data.value);

      sourceRows.push({
        iso2,
        price_level_ratio_ppp_to_fx: data.value,
        source_year: data.year,
        source_updated_at: new Date().toISOString(),
      });

      derivedRows.push({
        iso2,
        category,
        label: labelForCategory(category),
        metric: data.value,
        metric_year: data.year,
        version: 1,
        computed_at: new Date().toISOString(),
      });
    }

    await sb.from("country_affordability_source").upsert(sourceRows, {
      onConflict: "iso2",
    });

    await sb.from("country_affordability").upsert(derivedRows, {
      onConflict: "iso2",
    });

    return new Response(JSON.stringify({ ok: true, countries: derivedRows.length }), {
      headers: { "content-type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 500,
      headers: { "content-type": "application/json" },
    });
  }
});
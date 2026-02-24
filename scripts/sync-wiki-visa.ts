require('dotenv').config({ override: true });

const cheerio = require("cheerio");
const { createClient } = require("@supabase/supabase-js");

console.log("Starting visa sync script...");

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const WIKI_URL =
  "https://en.wikipedia.org/wiki/Visa_requirements_for_United_States_citizens";

function normalize(text) {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/&/g, "and")
    .replace(/[^\w\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function extractAliases(visitorToRaw) {
  const aliases = [];
  let parentNorm = null;
  let isSpecialSubregion = false;

  const raw = visitorToRaw.trim();

  // Detect "Parent - Subregion"
  if (raw.includes(" - ")) {
    const parts = raw.split(" - ");
    if (parts.length === 2) {
      parentNorm = normalize(parts[0]);
      isSpecialSubregion = true;
      aliases.push(parts[1]);
    }
  }

  // Extract names inside parentheses
  const parenMatch = raw.match(/\(([^)]+)\)/);
  if (parenMatch) {
    const inside = parenMatch[1];
    inside
      .split(/,| and /)
      .map((s) => s.trim())
      .forEach((name) => {
        if (name) aliases.push(name);
      });
  }

  return {
    aliasesNorm: aliases.map(normalize),
    parentNorm,
    isSpecialSubregion,
  };
}

async function fetchWikiTable() {
  const res = await fetch(WIKI_URL);
  const html = await res.text();
  const $ = cheerio.load(html);

  const rows = [];

  $("table.wikitable tbody tr").each((_, row) => {
    const cells = $(row).find("td");

    if (cells.length >= 4) {
      const rawName = $(cells[0]).text().trim();
      // Remove citation markers like [478][479]
      const visitorTo = rawName.replace(/\[\d+\]/g, '').trim();
      const requirement = $(cells[1]).text().trim();
      const allowedStay = $(cells[2]).text().trim();
      const notes = $(cells[3]).text().trim();

      if (visitorTo) {
        const { aliasesNorm, parentNorm, isSpecialSubregion } =
          extractAliases(visitorTo);

        rows.push({
          visitorToRaw: visitorTo,
          visitorToNorm: normalize(visitorTo),
          requirement,
          allowedStay,
          notes,
          aliasesNorm,
          parentNorm,
          isSpecialSubregion,
        });
      }
    }
  });

  return rows;
}

async function run() {
  console.log("Inside run()");
  console.log("Fetching Wikipedia...");

  const rows = await fetchWikiTable();

  console.log(`Parsed ${rows.length} rows`);

  const { data: latestRun } = await supabase
    .from("visa_sync_runs")
    .select("version")
    .order("version", { ascending: false })
    .limit(1)
    .maybeSingle();

  const newVersion = (latestRun?.version ?? 0) + 1;

  await supabase.from("visa_sync_runs").insert({
    version: newVersion,
    row_count: rows.length,
  });

  const inserts = rows.map((row) => ({
    visitor_to_raw: row.visitorToRaw,
    visitor_to_norm: row.visitorToNorm,
    requirement: row.requirement,
    allowed_stay: row.allowedStay,
    notes: row.notes,
    aliases_norm: row.aliasesNorm,
    parent_norm: row.parentNorm,
    is_special_subregion: row.isSpecialSubregion,
    version: newVersion,
    source: "wikipedia",
  }));

  const { error } = await supabase
    .from("visa_requirements")
    .insert(inserts);

  if (error) {
    console.error("Insert error:", error);
    process.exit(1);
  }

  console.log("Sync complete. Version:", newVersion);
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
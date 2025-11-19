#!/usr/bin/env python3
import csv
import json
from pathlib import Path

# Repo root = travel-af/
ROOT = Path(__file__).resolve().parents[2]

SEEDS_JSON = ROOT / "apps/web/data/seeds/countries.json"
BASE_CSV   = ROOT / "data/raw/affordability_base.csv"

# Columns we expect in the affordability base CSV
FIELDNAMES = ["iso2", "icp_pli", "icp_pli_us", "food_rel", "housing_rel", "transport_rel"]

# Neutral defaults for countries we don't have ICP-style data for yet
DEFAULT_ROW = {
    "icp_pli": "100",
    "icp_pli_us": "100",
    "food_rel": "1.00",
    "housing_rel": "1.00",
    "transport_rel": "1.00",
}


def load_iso2_from_seeds() -> list[str]:
    with SEEDS_JSON.open(encoding="utf-8") as f:
        seeds = json.load(f)

    iso2s: set[str] = set()
    for s in seeds:
        code = (s.get("iso2") or "").strip().upper()
        if len(code) == 2:
            iso2s.add(code)

    sorted_iso2s = sorted(iso2s)
    print(f"[expand] found {len(sorted_iso2s)} iso2 codes in COUNTRY_SEEDS")
    return sorted_iso2s


def load_affordability_base() -> dict[str, dict[str, str]]:
    if not BASE_CSV.exists():
        print(f"[expand] {BASE_CSV} does not exist yet, starting from empty")
        return {}

    rows: dict[str, dict[str, str]] = {}
    with BASE_CSV.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames:
            missing_cols = [c for c in FIELDNAMES if c not in reader.fieldnames]
            if missing_cols:
                print(f"[expand] WARNING: base CSV missing columns: {missing_cols}")

        for row in reader:
            iso2 = (row.get("iso2") or "").strip().upper()
            if not iso2:
                continue
            # Normalize / ensure all expected fields exist
            normalized = {k: (row.get(k) or "").strip() for k in FIELDNAMES}
            normalized["iso2"] = iso2
            rows[iso2] = normalized

    print(f"[expand] loaded {len(rows)} existing affordability rows from {BASE_CSV}")
    return rows


def main() -> None:
    iso2s = load_iso2_from_seeds()
    rows = load_affordability_base()

    before_count = len(rows)

    for iso2 in iso2s:
        if iso2 in rows:
            continue
        # Create a neutral baseline row for this country
        new_row = {"iso2": iso2}
        new_row.update(DEFAULT_ROW)
        rows[iso2] = new_row

    after_count = len(rows)
    added = after_count - before_count

    print(f"[expand] added {added} new iso2 rows (total now {after_count})")

    # Write back in a stable, sorted order
    with BASE_CSV.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDNAMES)
        writer.writeheader()
        for iso in sorted(rows.keys()):
            writer.writerow(rows[iso])

    print(f"[expand] wrote merged affordability base to {BASE_CSV}")


if __name__ == "__main__":
    main()
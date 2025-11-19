#!/usr/bin/env python3
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

RAW_DIR = ROOT / "data" / "raw"
OUT_DIR = ROOT / "apps" / "web" / "data" / "sources"

AFFORDABILITY_BASE_CSV = RAW_DIR / "affordability_base.csv"

COST_OF_LIVING_JSON = OUT_DIR / "cost_of_living.json"
FOOD_INDEX_JSON = OUT_DIR / "food_index.json"
HOUSING_INDEX_JSON = OUT_DIR / "housing_index.json"
TRANSPORT_INDEX_JSON = OUT_DIR / "transport_index.json"


def build_indices() -> None:
    col_map: dict[str, float] = {}
    food_map: dict[str, float] = {}
    housing_map: dict[str, float] = {}
    transport_map: dict[str, float] = {}

    with AFFORDABILITY_BASE_CSV.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)

        # Column names as defined in data/raw/affordability_base.csv
        col_field = "col"  # overall cost-of-living index (ICP-based, normalized)
        food_field = "food_rel"  # relative food index vs global baseline
        housing_field = "housing_rel"  # relative housing index
        transport_field = "transport_rel"  # relative transport index

        for row in reader:
            iso2 = (row.get("iso2") or "").strip().upper()
            if not iso2:
                continue

            # cost of living baseline (ICP-based)
            col_val = row.get(col_field)
            if col_val not in (None, ""):
                try:
                    col_map[iso2] = float(col_val)
                except ValueError:
                    pass

            # optional sub-indexes
            food_val = row.get(food_field)
            if food_val not in (None, ""):
                try:
                    food_map[iso2] = float(food_val)
                except ValueError:
                    pass

            housing_val = row.get(housing_field)
            if housing_val not in (None, ""):
                try:
                    housing_map[iso2] = float(housing_val)
                except ValueError:
                    pass

            transport_val = row.get(transport_field)
            if transport_val not in (None, ""):
                try:
                    transport_map[iso2] = float(transport_val)
                except ValueError:
                    pass

    # Simple diagnostics so we can see how many countries got each index
    col_count = len(col_map)
    food_count = len(food_map)
    housing_count = len(housing_map)
    transport_count = len(transport_map)
    all_iso2s = set(col_map) | set(food_map) | set(housing_map) | set(transport_map)
    total_countries = len(all_iso2s)

    print(
        f"Built affordability indices for {total_countries} countries "
        f"(COL: {col_count}, food: {food_count}, housing: {housing_count}, transport: {transport_count})"
    )

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    def dump_json(path: Path, obj: dict[str, float]) -> None:
        with path.open("w", encoding="utf-8") as f:
            json.dump(obj, f, ensure_ascii=False, indent=2, sort_keys=True)
        print(f"Wrote {path} items={len(obj)}")

    dump_json(COST_OF_LIVING_JSON, col_map)
    dump_json(FOOD_INDEX_JSON, food_map)
    dump_json(HOUSING_INDEX_JSON, housing_map)
    dump_json(TRANSPORT_INDEX_JSON, transport_map)


def main() -> None:
    print(f"Reading base CSV: {AFFORDABILITY_BASE_CSV}")
    build_indices()


if __name__ == "__main__":
    main()
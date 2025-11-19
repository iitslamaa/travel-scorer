import csv
from pathlib import Path

input_path = Path("data/raw/API_PA.NUS.PPPC.RF_DS2_en_csv_v2_6595.csv")
output_path = Path("data/raw/icp_latest.csv")

with input_path.open() as f:
    rows = list(csv.reader(f))

# Skip metadata rows until we reach the header row
header_idx = None
for i, row in enumerate(rows):
    if row and row[0] == "Country Name":
        header_idx = i
        break

if header_idx is None:
    raise RuntimeError("Could not find 'Country Name' header row in CSV")

data = rows[header_idx:]
header = data[0]

# Extract only valid year columns (numeric column headers)
year_cols = []
year_indices = []
for idx, col in enumerate(header):
    if col.isdigit():
        year_cols.append(col)
        year_indices.append(idx)

result = []

for row in data[1:]:
    name = row[0]
    iso3 = row[1]
    if not iso3 or len(iso3) != 3:
        continue

    # Extract only the values corresponding to actual year columns
    values = [row[i] for i in year_indices]
    latest_val = None

    # Iterate years from newest → oldest
    for val in reversed(values):
        try:
            num = float(val)
            latest_val = num
            break
        except:
            continue

    if latest_val is not None:
        result.append((name, iso3, latest_val))

# Write output
with output_path.open("w") as f:
    w = csv.writer(f)
    w.writerow(["name", "iso3", "col"])
    for r in result:
        w.writerow(r)

print("Wrote", output_path, "rows:", len(result))
# Plant Operations: Data Cleaning & Dashboard

An end-to-end practice project: cleaning a deliberately messy production and operations dataset in **MySQL**, then building a dashboard in **Tableau Public**.

The company, **Sparkle Foods**, is fictional: a bottling plant in Abuja that makes water, juices, zobo, tigernut drink, malt drink and ginger shots on 4 production lines and 3 shifts. The data is synthetic (Jan 2025 to Oct 2026).


## What this project shows

- Cleaning 5 related tables with SQL (dates, text, numbers, duplicates, invalid values, broken links between tables)
- A `data_issues` column that records every problem found, so nothing is silently deleted
- Turning clean data into a dashboard a plant manager could use

## The data

| Table | Rows (approx.) | What it records |
|---|---|---|
| `production_runs` | 6,300 | Each production run: product, line, shift, planned vs actual output, rejects, supervisor, unit cost |
| `downtime_log` | 2,600 | Machine stoppages: reason, duration, estimated loss (NGN) |
| `quality_checks` | 4,300 | QC readings per run, with pass/fail |
| `inventory_movements` | 4,800 | Raw material and packaging receipts and issues |
| `machines` | 25 | Machine register by production line |

Relationships: `downtime_log.machine_id` → `machines.machine_id`, and `quality_checks.run_id` → `production_runs.run_id`.

## Repository structure

```
data_raw/        original messy CSV files
data_cleaned/    cleaned CSV files exported from MySQL
sql/             cleaning scripts (run in numbered order)
dashboard/       Tableau workbook (.twbx)
images/          dashboard screenshot
```

## How to reproduce

1. Run `sql/00_create_raw_tables.sql` to create the database and empty raw tables.
2. Import each CSV from `data_raw/` into its table (MySQL Workbench: right-click the table → **Table Data Import Wizard**).
3. Run the cleaning scripts **in numbered order**:

| Order | Script | Creates | Notes |
|---|---|---|---|
| 1 | `01_machines2.sql` | `machines2` | Standardizes names and install dates |
| 2 | `02_production_runs2.sql` | `production_runs2` | The largest script. Must run before 03 |
| 3 | `03_quality_checks2.sql` | `quality_checks2` | Checks `run_id` against `production_runs2` |
| 4 | `04_downtime_log2.sql` | `downtime_log2` | Checks `machine_id` against `machines` |
| 5 | `05_inventory_movements2.sql` | `inventory_movements2` | Independent of the others |

4. Export the `*2` tables as CSV (comma separated) and open them in Tableau.

Each script copies the original table (`CREATE TABLE ... AS SELECT DISTINCT *`) and works on the copy, so the raw data is never changed.

## Cleaning approach

1. **Copy first.** Work on `<table>2`, which also removes exact duplicate rows.
2. **Flag, then clean.** Every problem is written to the `data_issues` column before the value is changed, so the reason is never lost. A row can carry several labels, separated by `; `.
3. **Standardize, then convert types.** Text and formats are fixed first, and the column type (`DATE`, `INT`, `DECIMAL`, `TIME`) is changed last.
4. **Flag, don't delete, when unsure.** Values that might be real but unusual (e.g. actual output more than 2x planned) are flagged so the business can decide.

## Problems found and fixed

| Table | Main issues | Fix |
|---|---|---|
| `production_runs` | 7+ date formats, product/line/shift/supervisor name variants, quantities stored as text (`"3,402 units"`), negative actual quantities, `₦`/`NGN` in costs, mixed time formats, actual output far above plan | Standardized names and dates, stripped text from numbers, flagged negatives and missing values before setting them to `NULL`, flagged actual > 2x planned |
| `downtime_log` | Reason variants (`NEPA`, `Power cut`, `Grid failure`), durations as `45 mins` or `1h 15m`, negative and zero durations, negative/missing losses, machine IDs like `M-007` or `M999` | Grouped reasons, converted durations to minutes, flagged then nulled invalid losses, flagged unknown machines |
| `quality_checks` | `run_id` in mixed case or missing from production, inspector name variants, non-numeric readings, pass/fail written many ways, `Fail` results marked `Ok` | Matched IDs, merged names, flagged bad readings and contradictions |
| `inventory_movements` | Material typos (`Sugars`, `Sugar (new)`), mixed units, negative quantities, `₦` in prices, zero prices, blank suppliers and locations | Merged names and units, flagged unit/material mismatches, flagged then nulled negatives and zero prices |
| `machines` | Duplicate row, line and status spellings, mixed date formats | Removed duplicate, standardized values, converted dates |

## Dashboard

Built in Tableau Public from the cleaned CSV files. Efficiency is total actual output divided by total planned output, with the runs flagged as "actual more than 2x planned" excluded.

### Findings

- **Output vs plan:** all 4 lines and all 3 shifts run at about **83% to 85%** of planned output. No line or shift is clearly behind.
  - By line: Line 1 84.4%, Line 2 85.1%, Line 3 84.9%, Line 4 83.4%
  - By shift: Afternoon 85.4%, Night 84.1%, Morning 83.9%
- **Quality:** pass rates range from **86.6%** (temperature) to **90.5%** (cap torque) across the 8 QC parameters.
- **Downtime cost:** recorded losses total about **₦378.7M**. Four reasons make up roughly **63%** of that:
  - Power outage: ₦71,368,311
  - Scheduled maintenance: ₦65,093,563
  - Changeover: ₦54,601,720
  - Mechanical failure: ₦47,488,419
- **Downtime cost by line:** Line 1 loses the most (**₦134,343,629**, about 35% of the total), followed by Line 3 (₦102,689,578), Line 2 (₦77,948,851) and Line 4 (₦60,836,542).

## Limitations

- **Loss totals are understated.** Loss values that were missing, negative or zero were set to `NULL`, so they are not counted.
- **Efficiency is slightly understated.** Runs with a missing or negative actual quantity (roughly 4% of runs) have no actual figure, but their planned quantity is still counted in the denominator.
- **Flagged runs are excluded.** Runs where actual output was more than 2x planned are left out of the efficiency charts. If the business confirms they are valid, they should be added back.
- **Unmatched machines.** Downtime rows with a missing or unknown machine ID show as `Null` in the loss-by-line chart (about ₦2.9M).
- **Snapshot, not live.** Tableau Public cannot connect to MySQL, so the dashboard uses exported CSV files.
- Synthetic data: the findings describe the practice dataset, not a real company.

## Tools

MySQL 8 / MySQL Workbench, Tableau Public.

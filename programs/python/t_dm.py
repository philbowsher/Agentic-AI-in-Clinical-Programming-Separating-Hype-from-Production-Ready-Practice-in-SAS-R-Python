# Program: t_dm.py
# Purpose: Demographics table (intent-to-treat population, as sop/table-standards.md
#          says) in Python, from the same
#          ADSL file the R steps use. Shows that parquet works in any language.
# Input:   data/adam/adsl.parquet (built in SAS, saved as parquet in R)
# Output:  output/tables/t_dm_python.html
# Run from the project folder: python programs/python/t_dm.py
# Packages: polars (data), great_tables (table, from Posit)

from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

import polars as pl
from great_tables import GT, md

adsl = pl.read_parquet("data/adam/adsl.parquet").filter(pl.col("ITTFL") == "Y")
arms = ["Placebo", "Xanomeline Low Dose", "Xanomeline High Dose"]
n_arm = {a: adsl.filter(pl.col("TRT01P") == a).height for a in arms}


def fmt(x, digits=1):
    # Round half away from zero, the way SAS does (6.25 -> 6.3).
    # Python's round() rounds half to even, like R's.
    q = Decimal(1).scaleb(-digits)
    return str(Decimal(str(x)).quantize(q, rounding=ROUND_HALF_UP))


rows = []
for a in arms:
    age = adsl.filter(pl.col("TRT01P") == a)["AGE"]
    rows += [
        ("Age (years)", "n", a, str(age.len())),
        ("Age (years)", "Mean (SD)", a, f"{fmt(age.mean())} ({fmt(age.std(), 2)})"),
        ("Age (years)", "Median", a, fmt(age.median())),
        ("Age (years)", "Min, Max", a, f"{int(age.min())}, {int(age.max())}"),
    ]

for var, label, levels in [
    ("AGEGR1", "Age group (years)", ["<65", "65-80", ">80"]),
    ("SEX", "Sex", ["F", "M"]),
    ("RACE", "Race", sorted(adsl["RACE"].unique().to_list())),
]:
    for lvl in levels:
        for a in arms:
            n = adsl.filter((pl.col("TRT01P") == a) & (pl.col(var) == lvl)).height
            rows.append((label, lvl, a, f"{n} ({fmt(100 * n / n_arm[a])}%)"))

long = pl.DataFrame(rows, schema=["group", "stat", "arm", "value"], orient="row")
wide = long.pivot(on="arm", index=["group", "stat"], values="value", maintain_order=True)

table = (
    GT(wide, rowname_col="stat", groupname_col="group")
    .tab_header(
        title="Table 14-2.01 Summary of Demographic Characteristics",
        subtitle="Intent-to-Treat Population",
    )
    .cols_label(**{a: md(f"{a}<br>(N={n_arm[a]})") for a in arms})
    .cols_align("right", columns=arms)
    .tab_source_note("Source: data/adam/adsl.parquet. Made in Python with polars and Great Tables.")
)

Path("output/tables").mkdir(parents=True, exist_ok=True)
Path("output/tables/t_dm_python.html").write_text(table.as_raw_html(), encoding="utf-8")
print(f"Wrote output/tables/t_dm_python.html: {adsl.height} subjects, {wide.height} rows")

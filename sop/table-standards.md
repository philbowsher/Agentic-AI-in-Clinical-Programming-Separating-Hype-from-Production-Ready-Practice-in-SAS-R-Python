# SOP-TLF-001: Summary table standards (example)

This procedure tells programmers how to build summary tables for clinical study reports. It applies to every summary table in the study.

## Population and columns

- Use the population named in the table title. For demographics, use the intent-to-treat population (ITTFL = "Y").
- Show one column per planned treatment (TRT01P), in this order: Placebo, Xanomeline Low Dose, Xanomeline High Dose, then a Total column.
- Show the number of subjects in each column header as "(N=xx)".

## Statistics

- Continuous variables: n, Mean (SD), Median, and Min, Max, each on its own row.
- Categorical variables: n (%), where the percentage uses the column N as the denominator.
- Mean, median and percentages have one decimal place. SD has two decimal places. Min and max have the same decimals as the raw data.
- Round half away from zero, the way SAS does: 6.25 becomes 6.3. Note that R's round() rounds half to even, so do not use it on its own for display values.
- Keep trailing zeros: show 76.0, not 76.

## Layout

- Title on two lines: the table number (for example "Table 14-2.01"), then the table name.
- First footnote: the program name and the date the table was run.
- Save each table as HTML and RTF in `output/tables/`, named after the table number, for example `t_14_2_01.html` and `t_14_2_01.rtf`.

## Review

- The programmer reviews every table before it is shared.
- A table built with AI help is a draft until a programmer has checked it.

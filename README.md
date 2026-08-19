# HadCRUT Temperature Regression Analysis

This program analyzes linear temperature trends across continuous year ranges (7 to 50 years) from the UK Met Office HadCRUT datasets (HadCRUT4 and HadCRUT5).

By testing all continuous year ranges within an **upside-down cone** geometry, the analysis demonstrates how temperature trends behave across different time horizons, highlighting multi-decadal oscillations and long-term warming.

---

## 3-Way Comparative Overview

The analysis compares three configurations across window sizes of 7–50 years:
1. **HadCRUT4 (1850–2021)**: Retired baseline dataset (172 years).
2. **HadCRUT5 (1850–2021)**: Modern dataset over the identical historical period for direct baseline comparison.
3. **HadCRUT5 (1850–2026)**: Full contemporary series (177 years).

### Summary Statistics (Upside-Down Cone)

| Category | HadCRUT4 (1850–2021) | HadCRUT5 (1850–2021) | HadCRUT5 (1850–2026) |
|---|---|---|---|
| **Total Ranges in Cone** | 3,850 | 3,850 | 4,070 |
| **Statistically Sig. Warming ($p < 0.05$)** | 1,526 (39.6%) | 1,606 (41.7%) | 1,754 (43.1%) |
| **Non-Sig. Warming ($p \ge 0.05$)** | 1,085 (28.2%) | 1,044 (27.1%) | 1,093 (26.9%) |
| **Non-Sig. Cooling ($p \ge 0.05$)** | 1,055 (27.4%) | 955 (24.8%) | 978 (24.0%) |
| **Statistically Sig. Cooling ($p < 0.05$)** | 184 (4.8%) | 245 (6.4%) | 245 (6.0%) |

---

## Distribution Comparison

![Barchart Comparison](barchart-comparison.png)

---

## Upside-Down Cone Regression Charts

In the interval charts below, each horizontal segment represents a linear regression over a specific time window. 
- **Vertical Axis:** Window length (7 to 50 years).
- **Horizontal Axis:** Year.
- **Upside-Down Cone Geometry:** Boundaries slope inward symmetrically on both sides as window length increases (`i_start = len`, `i_end = samples - 2 * len`).
- **Colors:**
  - **Red:** Statistically significant warming ($p < 0.05$)
  - **Orange:** Non-significant warming ($p \ge 0.05$)
  - **Cyan:** Non-significant cooling ($p \ge 0.05$)
  - **Blue:** Statistically significant cooling ($p < 0.05$)

Statistically most significant ranges are plotted on top.

![Chart Comparison](chart-comparison.png)

---

## How to Run

The script is implemented in standard R without external library dependencies:

```bash
Rscript HadCRUT-analysis.R
```

Outputs generated:
- `chart-hadcrut4.png` / `barchart-hadcrut4.png`
- `chart-hadcrut5-2021.png` / `barchart-hadcrut5-2021.png`
- `chart-hadcrut5-2026.png` / `barchart-hadcrut5-2026.png`
- `chart-comparison.png` / `barchart-comparison.png`

---

## Data Source
- UK Met Office Hadley Centre HadCRUT4 / HadCRUT5 Open Data.


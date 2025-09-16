# RFM Segmentation – Logic & Visuals

## Snapshot approach (fast)
- `CustomerRFM` with **RecencyDays / Frequency / Monetary** (calculated at refresh).
- Scores 1..3 using global P33/P66.
- `RFM_Category` labels and `CategorySortKey` for legend order.

## Visuals
- Scatter (F×M), stacked revenue by RFM, Recency/Frequency histograms, bar by segment.

## Assumption
Global thresholds; per-state thresholds need state-aware logic (`ALLEXCEPT`).

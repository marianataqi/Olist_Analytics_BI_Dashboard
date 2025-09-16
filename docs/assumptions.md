# Assumptions & Limitations

- Data window ~2016–2018.
- Revenue definition may vary (price vs price+freight); keep consistent per report.
- RFM thresholds are global at refresh (snapshot).
- Fact grain: item-level; use DISTINCTCOUNT(order_id) for order-level KPIs where needed.

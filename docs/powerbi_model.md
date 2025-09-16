# After opening the PBIX go to Transform data → Manage Parameters and set DataFolder to your local .../Olist_Analytics/data/ path, then Refresh
# Power BI Model – Star Schema, RLS, Performance

## Tables & grain
- **FactOrders** (order-line grain)
- **DimCustomer**, **DimSeller**, **DimProduct**, **DimDate**

## Modeling choices
- Auto Date/Time OFF; single-direction relationships.
- Measures centralized in `_Measures` with Display folders.

## RLS (seller state)
Role filter limits data by `USERPRINCIPALNAME()` with a state mapping table.

## Performance tips
- Snapshot RFM as columns; Top N on dense visuals; "Show items with no data" off.

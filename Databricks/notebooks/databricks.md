# Databricks — How to Run the Olist ETL

This folder contains notebooks to read the public **Olist** dataset from **Azure Blob Storage**, build a unified view, and expose a simple **star schema** for BI.

> ⚠️ **Never commit secrets.** Use **Databricks Secrets** at runtime. All tokens in code must remain **placeholders**.

---

## 📦 Contents

- `00_bootstrap_conf.py` — sets Spark config to authenticate to Blob with **SAS** (reads the token from a Secret Scope in real runs).
- `01_etl_olist.sql` — reads CSVs, builds the unified view `olist_raw_data`, and creates **Temp Views** for `FactOrders` and the `Dim*` tables.
- *(optional)* `02_export_gold.py` — writes Gold views out as CSV (not required for this repo).

---

## 🚀 Quick Start (TL;DR)

1. Create a **Cluster** (DBR 13.x+ or 16.x).
2. Create a **Secret Scope** (e.g., `olist-secrets`) and store your SAS token under key `adls-sas`.
3. **Import** the notebooks into your Databricks workspace.
4. **Run** `00_bootstrap_conf.py` (sets SAS in `spark.conf`).
5. **Run** `01_etl_olist.sql` (creates the Temp Views and sanity checks).


---

## 🔐 Secrets / Authentication

Create a Secret Scope once, then read the token at runtime.

```python
# 00_bootstrap_conf.py (snippet)
# NOTE: never commit real secrets. Use Secret Scopes at runtime.

account   = "olistdatalake2025"
container = "olist-raw"

# Real run:
# sas_token = dbutils.secrets.get(scope="olist-secrets", key="adls-sas")
sas_token = "<YOUR_SAS_TOKEN_AT_RUNTIME>"  # placeholder for local demo only

spark.conf.set(
    f"fs.azure.sas.{container}.{account}.blob.core.windows.net",
    sas_token
)

print("✅ SAS conf set. Now run: 01_etl_olist.sql")
```

---

## 🧱 ETL (SQL) — What `01_etl_olist.sql` Does

- Reads CSVs into **Temp Views** (`orders`, `order_items`, `customers`, `sellers`, `products`, `order_payments`, `order_reviews`, `product_category_translation`, `geolocation`).
- Builds a unified view **`olist_raw_data`** (joins orders, items, customers, sellers, products, payments, reviews).
- Creates **Temp Views** for a simple star schema:
  - `DimCustomer`, `DimSeller`, `DimProduct`, `DimDate`
  - `FactOrders`

**Sanity checks** (end of the notebook):

```sql
SELECT 'FactOrders' AS tbl, COUNT(*) AS cnt FROM FactOrders;

SELECT order_status, COUNT(*) AS total_orders
FROM olist_raw_data
GROUP BY order_status
ORDER BY total_orders DESC;
```

> Want persistent objects instead of Temp Views? See the next section.

---

## 🧮 Persistent Option (Optional)

If you prefer objects that survive cluster restarts and are friendlier for direct BI connectivity:

```sql
-- One-time schemas
CREATE SCHEMA IF NOT EXISTS olist_raw;
CREATE SCHEMA IF NOT EXISTS olist_gold;

-- Example external table (CSV on Blob)
CREATE TABLE IF NOT EXISTS olist_raw.orders
USING CSV
OPTIONS (header 'true', inferSchema 'true')
LOCATION 'wasbs://olist-raw@olistdatalake2025.blob.core.windows.net/olist_orders_dataset.csv';

-- Then build olist_gold.olist_raw_data (VIEW) + olist_gold.Dim*/FactOrders (VIEW)
-- … (same SELECTs as in the Temp View version)
```

> For production, consider **ADLS Gen2 + `abfss://`** and **Delta Lake** (Bronze/Silver/Gold).

---

## 🔗 Connecting Power BI

### Option A — Local CSVs (included in this repo)
- The PBIX is configured to load from the `data/` folder via a Power Query parameter **`DataFolder`**.
- After opening the PBIX: **Transform data → Manage Parameters → `DataFolder`** → point it to your local `.../Olist_Analytics/data/` (trailing slash required), then **Refresh**.

### Option B — Direct to Databricks
- Power BI Desktop → **Get Data → Azure Databricks**
- Authenticate (Token/SSO) and choose a **SQL Warehouse** (recommended) or a cluster.
- Select your schema (e.g., `olist_gold`) and load the views.

---

## 🛠️ Troubleshooting

- **403 / FileNotFound for `wasbs://…`**
  - SAS token expired or missing permissions (`sp=` must include `r` at minimum).
  - `00_bootstrap_conf.py` not executed → `spark.conf.set(...)` not set.

- **Column/encoding mismatches**
  - Ensure `header=true`, `inferSchema=true`, and correct encoding on CSV reads.

- **Object already exists**
  - Use `CREATE OR REPLACE VIEW` (already used in the SQL notebook).

- **Slow queries**
  - Move to **Delta Lake** on **`abfss://`** and use a **SQL Warehouse** for BI workloads.

---

## 🔒 Security Hygiene

- Keep all tokens/keys **out of source**.
- In this repo, search before commits (or after pushing, inside GitHub):
  - `sv=`, `sig=`, `SharedAccess`, `AccountKey=`, `sas_token=`
- If a secret leaks: **rotate** in Azure and **purge history** (BFG / `git filter-repo`).

---

## 🔭 Roadmap (nice-to-have)

- Persistent Gold schema + **Delta Lake** (Bronze/Silver/Gold) on `abfss://`.
- **Per-state** RFM thresholds (computed in ETL).
- **Jobs** with parameters for scheduled runs (e.g., `asof_date`).
- **Data Quality checks** (Null/Duplicate/Domain).
- Power BI **DirectQuery** to SQL Warehouse.

---

## ▶️ Order of Execution

1. `00_bootstrap_conf.py`  
2. `01_etl_olist.sql`  


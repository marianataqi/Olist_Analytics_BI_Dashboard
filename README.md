
## Demo

![Olist demo](assets/videos/Olist-demo.gif)

# Olist Ecommerce Analytics — Azure Databricks + Power BI

**End-to-end retail analytics on the public Olist dataset.**  
Ingest & model in **Azure Databricks**, store curated data in **Azure Blob (SAS)**, and deliver insights with **Power BI** (KPI, **RFM segmentation**, drill-through).

> ⚠️ All secrets are **redacted**. Replace placeholders with your own credentials (Databricks **Secret Scope** or environment variables).

---

## TL;DR

-  **Business:** growth levers via **RFM cohorts**, top sellers/customers/categories, YoY trends.  
-  **Tech:** Notebooks → **star schema** → PBIX; fast visuals; RLS sanity page.  
-  **60-sec demo:** open `powerbi/Olist-Dashboard.pbix`, point to `data/*/*.csv`, **Refresh**.


---



```

.
├─ Databricks/
│  └─ notebooks/
│     ├─ 00_bootstrap_conf.py         # Spark SAS auth (use Secret Scope in real runs)
│     └─ 01_etl_olist.sql             # SQL notebook: unify Olist & create star views
├─ data/                              # curated star-schema CSVs for local demo
│  ├─ Dim_Customer.csv
│  ├─ Dim_Date.csv
│  ├─ Dim_Product.csv
│  ├─ Dim_Seller.csv
│  ├─ Seller_State_Emails.csv         # RLS demo mapping
│  └─ Fact_order.csv                  
├─ powerbi/
│  └─ Olist-Dashboard.pbix
├─ assets/
│  ├─ azure/                          # redacted infra screenshots (SAS, containers, CSVs)
│  ├─ dashboards/                     # dashboard page screenshots
│  ├─ databricks/                     # sanitized notebook screenshot
│  └─ videos/                         # Olist-demo.gif + .mp4 
├─ docs/                              # deep dives (model, RFM, measures, security, roadmap)
│  ├─ engineering.md
│  ├─ powerbi_model.md
│  ├─ rfm.md
│  ├─ measures.md
│  ├─ security.md
│  ├─ roadmap.md
│  └─ assumptions.md
├─ config.template.json               # example config 
├─ .gitignore
└─ LICENSE

---
```

## Architecture

**Raw (Blob/SAS) → Curated (Star schema in Databricks) → BI (Power BI)**  


---

## Quickstart

### Option A — Local (no Azure needed)

1. Clone this repo.  
2. Open **`powerbi/Olist-Dashboard.pbix`**.  
3. If prompted, browse to `data/*/*.csv` and **Refresh**.

### Option B — Full pipeline (Azure)

1. Create an Azure Storage Account & container `olist-raw` (HTTPS-only SAS).  
2. Import `databricks/notebooks/etl_olist.py` into Databricks.  
3. Store your SAS in a **Secret Scope** and run the notebook to export the star schema back to Blob.  
4. Open the PBIX and connect to those CSVs (Blob or local copy).



Example (sanitized):

```python
# NOTE: the real token is stored in a Secret Scope in Databricks.
# sas_token = dbutils.secrets.get(scope="olist-secrets", key="adls-sas")
sas_token = "<SAS_AT_RUNTIME>"
account   = "olistdatalake2025"
container = "olist-raw"

spark.conf.set(
    f"fs.azure.sas.{container}.{account}.blob.core.windows.net",
    sas_token
)

```

## Data Source
- Public **Olist** e-commerce dataset (Brazil).
- This repo includes curated **star-schema CSVs** for local demo:
  - `FactOrders`
  - `DimCustomer`
  - `DimProduct`
  - `DimSeller`
  - `DimDate`
- Please check the original dataset license for re-use and attribution guidelines. See [`LICENSE`](LICENSE).

- Download PBIX: [`powerbi/Olist-Dashboard.pbix`](powerbi/Olist-Dashboard.pbix)
- Sample data (CSV): [`data/`](data/)




## Findings & Recommendations

**What we learned (high level)**  
- Revenue growth is driven by a few categories (e.g., *health_beauty*) and a handful of seller states.  
- Customer base is wide but **low-frequency**; repeat purchase rate is modest (~10–11% in our sample run).  
- Review score and delivery performance move together: weaker delivery windows → lower review score.  
- A small set of customers contributes a big share of revenue (power-law).  

**What to do next (actions)**  
- **Retention lift:** launch targeted CRM for *Best/Loyal* & *At Risk* segments (RFM) with tailored offers.  
- **Category focus:** double down on top categories/regions; test cross-sell bundles to raise AOV.  
- **Delivery SLAs:** prioritize lanes with low review scores; set SLA+fee rules and track improvement weekly.  
- **Top-N playbook:** build playbooks for Top sellers/customers (white-glove ops, faster returns, priority stock).  
- **Measure health:** add cohort retention and incremental refresh to keep KPIs fresh and comparable.


### Dashboards (screenshots)

<p align="center">
  <img src="assets/dashboards/Performance_overview.png" width="45%"/>
  <img src="assets/dashboards/Performance_overview2.png" width="45%"/>
</p>

<p align="center">
  <img src="assets/dashboards/Customer_segmentation%20(RFM).png" width="45%"/>
  <img src="assets/dashboards/drillthrough%201%20seller%20insight.png" width="45%"/>
</p>

<p align="center">
  <img src="assets/dashboards/drillthrough%202%20customers%20performance.png" width="45%"/>
  <img src="assets/dashboards/drillthrough3%20Productcategory%20details.png" width="45%"/>
</p>

<p align="center">
  <img src="assets/dashboards/RLS%20check1.png" width="45%"/>
  <img src="assets/dashboards/RLS%20check2.png" width="45%"/>
</p>

## Azure proofs (redacted)

<p align="center">
  <img src="assets/azure/azure-sas-settings.png" width="45%"/>
  <img src="assets/azure/azure-containers-list.png" width="45%"/>
</p>

<p align="center">
  <img src="assets/azure/azure-csv_data.png" width="45%"/>
</p>

## Data & License
- **Source:** Public *Olist* e-commerce dataset (Brazil).
- This repo includes curated **star-schema CSVs** for local demo.
- See [`LICENSE`](LICENSE) and the original Olist license for re-use/attribution.

## Security Notes
- No secrets in this repo. Use **Databricks Secrets** or environment variables.
- Prefer **HTTPS-only SAS**; rotate tokens; restrict IPs where possible.
- If you fork this repo, double-check you didn’t commit any local credentials.

## Roadmap
- Per-state RFM thresholds
- CLTV v1 (ARPU × Margin × Retention / (1–Retention))
- 100% stacked “RFM Mix %”
- Incremental refresh & cohort/time-dynamic RFM
- Delta Lake (Bronze/Silver/Gold) via `abfss://`
- Data quality checks & parameterized pipelines


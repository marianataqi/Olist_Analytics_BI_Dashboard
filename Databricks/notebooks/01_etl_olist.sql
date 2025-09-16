Databricks notebook source
-- MAGIC %python

-- MAGIC storage_account_name = "olistdatalake2025"
-- MAGIC container_name = "olist-raw"

# NOTE: real token is stored in a Databricks Secret Scope (never committed).
# sas_token = dbutils.secrets.get(scope="olist-secrets", key="adls-sas")
sas_token = "<YOUR_SAS_TOKEN_AT_RUNTIME>"
-- MAGIC
-- MAGIC # Configure Spark to use the SAS token for authentication against Blob Storage
-- MAGIC spark.conf.set(
-- MAGIC     f"fs.azure.sas.{container_name}.{storage_account_name}.blob.core.windows.net",
-- MAGIC     sas_token
-- MAGIC )
-- MAGIC
-- MAGIC try:
-- MAGIC     print("Loading data and creating temporary views for Olist datasets...")
-- MAGIC
-- MAGIC     # Create temporary views for each file
-- MAGIC     spark.read.csv(f"wasbs://{container_name}@{storage_account_name}.blob.core.windows.net/olist_orders_dataset.csv", header=True, inferSchema=True).createOrReplaceTempView("orders")
-- MAGIC     spark.read.csv(f"wasbs://{container_name}@{storage_account_name}.blob.core.windows.net/olist_order_items_dataset.csv", header=True, inferSchema=True).createOrReplaceTempView("order_items")
-- MAGIC     spark.read.csv(f"wasbs://{container_name}@{storage_account_name}.blob.core.windows.net/olist_customers_dataset.csv", header=True, inferSchema=True).createOrReplaceTempView("customers")
-- MAGIC     spark.read.csv(f"wasbs://{container_name}@{storage_account_name}.blob.core.windows.net/olist_sellers_dataset.csv", header=True, inferSchema=True).createOrReplaceTempView("sellers")
-- MAGIC     spark.read.csv(f"wasbs://{container_name}@{storage_account_name}.blob.core.windows.net/olist_products_dataset.csv", header=True, inferSchema=True).createOrReplaceTempView("products")
-- MAGIC     spark.read.csv(f"wasbs://{container_name}@{storage_account_name}.blob.core.windows.net/olist_geolocation_dataset.csv", header=True, inferSchema=True).createOrReplaceTempView("geolocation")
-- MAGIC     spark.read.csv(f"wasbs://{container_name}@{storage_account_name}.blob.core.windows.net/olist_order_payments_dataset.csv", header=True, inferSchema=True).createOrReplaceTempView("order_payments")
-- MAGIC     spark.read.csv(f"wasbs://{container_name}@{storage_account_name}.blob.core.windows.net/olist_order_reviews_dataset.csv", header=True, inferSchema=True).createOrReplaceTempView("order_reviews")
-- MAGIC     spark.read.csv(f"wasbs://{container_name}@{storage_account_name}.blob.core.windows.net/product_category_name_translation.csv", header=True, inferSchema=True).createOrReplaceTempView("product_category_translation")
-- MAGIC
-- MAGIC     print("\nCreating final view 'olist_raw_data' using SQL...")
-- MAGIC     spark.sql("""
-- MAGIC         CREATE OR REPLACE TEMPORARY VIEW olist_raw_data AS
-- MAGIC         SELECT
-- MAGIC             o.order_id,
-- MAGIC             o.customer_id,
-- MAGIC             o.order_status,
-- MAGIC             o.order_purchase_timestamp,
-- MAGIC             o.order_delivered_customer_date,
-- MAGIC             o.order_estimated_delivery_date,
-- MAGIC             oi.order_item_id,
-- MAGIC             oi.product_id,
-- MAGIC             oi.seller_id,
-- MAGIC             oi.price,
-- MAGIC             oi.freight_value,
-- MAGIC             c.customer_unique_id,
-- MAGIC             c.customer_zip_code_prefix,
-- MAGIC             c.customer_city,
-- MAGIC             c.customer_state,
-- MAGIC             s.seller_zip_code_prefix,
-- MAGIC             s.seller_city,
-- MAGIC             s.seller_state,
-- MAGIC             p.product_category_name,
-- MAGIC             p.product_weight_g,
-- MAGIC             p.product_length_cm,
-- MAGIC             p.product_height_cm,
-- MAGIC             p.product_width_cm,
-- MAGIC             pct.product_category_name_english,
-- MAGIC             op.payment_type,
-- MAGIC             op.payment_installments,
-- MAGIC             op.payment_value,
-- MAGIC             orv.review_score
-- MAGIC         FROM orders o
-- MAGIC         INNER JOIN order_items oi ON o.order_id = oi.order_id
-- MAGIC         INNER JOIN customers c ON o.customer_id = c.customer_id
-- MAGIC         INNER JOIN sellers s ON oi.seller_id = s.seller_id
-- MAGIC         INNER JOIN products p ON oi.product_id = p.product_id
-- MAGIC         LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
-- MAGIC         INNER JOIN order_payments op ON o.order_id = op.order_id
-- MAGIC         INNER JOIN order_reviews orv ON o.order_id = orv.order_id;
-- MAGIC     """).show()
-- MAGIC
-- MAGIC     print("\nSuccessfully created 'olist_raw_data' view.")
-- MAGIC     
-- MAGIC except Exception as e:
-- MAGIC    print(f"An error occurred while loading or joining the data. Please check the file paths or SAS token. Error: {e}")

-- COMMAND ----------

-- MAGIC %md

-- COMMAND ----------

SELECT order_status, COUNT(*) AS total_orders
FROM olist_raw_data
GROUP BY order_status
ORDER BY total_orders DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Top 10 customers by order

-- COMMAND ----------

SELECT customer_unique_id, COUNT(*) AS total_orders
FROM olist_raw_data
GROUP BY customer_unique_id
ORDER BY total_orders DESC
LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC DimCustomer

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW DimCustomer AS
SELECT DISTINCT
    customer_unique_id      AS CustomerKey,
    customer_city           AS CustomerCity,
    customer_state          AS CustomerState,
    customer_zip_code_prefix AS CustomerZipPrefix
FROM olist_raw_data;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC DimProduct

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW DimProduct AS
SELECT DISTINCT
    product_id              AS ProductKey,
    product_category_name_english AS ProductCategory,
    product_weight_g        AS WeightGrams,
    product_length_cm       AS LengthCM,
    product_height_cm       AS HeightCM,
    product_width_cm        AS WidthCM
FROM olist_raw_data;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC DimSeller

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW DimSeller AS
SELECT DISTINCT
    seller_id               AS SellerKey,
    seller_city             AS SellerCity,
    seller_state            AS SellerState,
    seller_zip_code_prefix  AS SellerZipPrefix
FROM olist_raw_data;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC DimDate

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW DimDate AS
SELECT DISTINCT
    CAST(order_purchase_timestamp AS DATE) AS DateKey,
    year(order_purchase_timestamp)         AS Year,
    month(order_purchase_timestamp)        AS Month,
    day(order_purchase_timestamp)          AS Day,
    date_format(order_purchase_timestamp, 'EEEE') AS WeekDay,
    weekofyear(order_purchase_timestamp)   AS WeekOfYear,
    quarter(order_purchase_timestamp)      AS Quarter
FROM olist_raw_data;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC FactOrders

-- COMMAND ----------

CREATE OR REPLACE TEMPORARY VIEW FactOrders AS
SELECT
    order_id,
    customer_unique_id,
    product_id,
    seller_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    order_item_id,
    price,
    freight_value,
    payment_type,
    payment_installments,
    payment_value,
    review_score
FROM olist_raw_data;

-- COMMAND ----------

SELECT 
    c.CustomerState,
    ROUND(SUM(f.price + f.freight_value), 2) AS total_sales,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM FactOrders f
JOIN DimCustomer c ON f.customer_unique_id = c.CustomerKey
GROUP BY c.CustomerState
ORDER BY total_sales DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Order count by product category

-- COMMAND ----------

SELECT 
    p.ProductCategory AS category,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.price + f.freight_value), 2) AS total_sales
FROM FactOrders f
JOIN DimProduct p ON f.product_id = p.ProductKey
GROUP BY p.ProductCategory
ORDER BY total_sales DESC
LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Avg review score by seller state

-- COMMAND ----------

SELECT 
    s.SellerState AS state,
    ROUND(AVG(f.review_score), 2) AS avg_review_score,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM FactOrders f
JOIN DimSeller s ON f.seller_id = s.SellerKey
GROUP BY s.SellerState
ORDER BY avg_review_score DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Order count by YearMonth

-- COMMAND ----------

SELECT 
    d.Year,
    d.Month,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM FactOrders f
JOIN DimDate d ON CAST(f.order_purchase_timestamp AS DATE) = d.DateKey
GROUP BY d.Year, d.Month
ORDER BY d.Year, d.Month;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC Export Fact and Dim tables as CSV to Blob Storage

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # Azure Blob Storage config
-- MAGIC storage_account_name = "olistdatalake2025"
-- MAGIC container_name = "olist-raw"  # could use a separate container for output
# NOTE: real token is stored in a Databricks Secret Scope (never committed).
# sas_token = dbutils.secrets.get(scope="olist-secrets", key="adls-sas")
sas_token = "<YOUR_SAS_TOKEN_AT_RUNTIME>"

-- MAGIC
-- MAGIC # Configure Spark with SAS token
-- MAGIC spark.conf.set(
-- MAGIC     f"fs.azure.sas.{container_name}.{storage_account_name}.blob.core.windows.net",
-- MAGIC     sas_token
-- MAGIC )
-- MAGIC
-- MAGIC # Fact and Dim tables
-- MAGIC tables = ["FactOrders", "DimCustomer", "DimProduct", "DimSeller", "DimDate"]
-- MAGIC
-- MAGIC # Dict for storing SAS links
-- MAGIC sas_links = {}
-- MAGIC
-- MAGIC for table in tables:
-- MAGIC     df = spark.sql(f"SELECT * FROM {table}")
-- MAGIC     out_path = f"wasbs://{container_name}@{storage_account_name}.blob.core.windows.net/{table}/"
-- MAGIC     
-- MAGIC     # Save as CSV
-- MAGIC     df.coalesce(1).write.mode("overwrite").option("header", True).csv(out_path)
-- MAGIC     
-- MAGIC     files = dbutils.fs.ls(out_path)
-- MAGIC     part_file = [f.path for f in files if f.name.startswith("part-") and f.name.endswith(".csv")][0]
-- MAGIC     
-- MAGIC     file_name = part_file.split("/")[-1]
-- MAGIC     sas_link = f"https://{storage_account_name}.blob.core.windows.net/{container_name}/{table}/{file_name}?{sas_token}"
-- MAGIC     sas_links[table] = sas_link
-- MAGIC
-- MAGIC # Print SAS links
-- MAGIC print("SAS links for direct CSV download:")
-- MAGIC for table, link in sas_links.items():
-- MAGIC     print(f"{table} : {link}")

-- COMMAND ----------

-- MAGIC %python
-- MAGIC tables = ["FactOrders", "DimCustomer", "DimProduct", "DimSeller", "DimDate"]
-- MAGIC
-- MAGIC for table in tables:
-- MAGIC     df = spark.sql(f"SELECT * FROM {table}")
-- MAGIC     print(f"\nOur Table: {table}")
-- MAGIC     print(f"Row count: {df.count()}")
-- MAGIC     print("Top 5 rows:")
-- MAGIC     df.show(5)

# NOTE: never commit real secrets. Use Secret Scopes at runtime.
account   = "olistdatalake2025"
container = "olist-raw"

# Real run:
# sas_token = dbutils.secrets.get(scope="olist-secrets", key="adls-sas")
sas_token = "<SAS_AT_RUNTIME>"

spark.conf.set(
    f"fs.azure.sas.{container}.{account}.blob.core.windows.net",
    sas_token
)

print("Spark conf for SAS set. Now run the SQL notebook: 01_etl_olist.sql")

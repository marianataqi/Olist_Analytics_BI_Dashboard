# Security Notes – SAS, Secrets, RLS

- SAS minimal scope (Blob only, Object/Container), HTTPS only, short expiry, IP-restricted.
- No secrets in repo; use Databricks Secret Scopes / Key Vault.
- RLS validated with an "RLS Check" page (whoami, visible states/orders).
- If a secret is leaked: rotate in Azure, purge from git history, force-push.

# Doca on Railway

One-click Railway template for [Doca](https://github.com/workhold/doca) 0.2.32 (MIT): a self-hosted workspace for real-time co-edited docs, sheets, slides, canvas and knowledge bases, with an optional AI assistant and MCP tools.

Deploy button: added after the template is generated.

## What this repo adds

The image `ghcr.io/onepush-dev/doca:0.2.32` is `smartdoca/doca:0.2.32` (pinned by digest), unchanged except for:

- `railway/railway-start.sh`: fixes ownership of the Railway volume at `/data` (Doca runs as `node`), sets `DOCA_ORIGIN` from the service's public domain when unset, maps Railway's `PORT` to `DOCA_PORT`, starts Doca, and once `/health` is up creates the first administrator from `DOCA_ADMIN_LOGIN` / `DOCA_ADMIN_PASSWORD` (upstream needs an interactive `docker compose exec doca bash docker/admin.sh bootstrap`). If an administrator already exists it does nothing.
- `railway/patch-health-host.mjs`: Doca rejects any Host header other than `DOCA_ORIGIN` with 421, which breaks Railway's healthcheck. The patch lets only `GET /health` and `GET /live` through for other hosts. Everything else is unchanged.
- Defaults baked into the image: SQLite at `/data/doca.db`, AI database `/data/ai.db`, plugin database `/data/doca.db.plugins.db`, plugins `/data/plugins`, local file store `/data/storage`, `DOCA_TRUST_PROXY` set to private ranges so login rate limits see the real client IP behind Railway's proxy.

## Template variables

| Variable | Value |
| --- | --- |
| `DOCA_ORIGIN` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` |
| `DOCA_CREDENTIAL_MASTER_KEY` | `${{secret(64, "abcdef0123456789")}}` (keep it forever; it encrypts stored credentials) |
| `DOCA_ADMIN_PASSWORD` | `${{secret(24)}}` (first administrator; login `admin`) |

Optional: `DOCA_ADMIN_LOGIN` (default `admin`), `DOCA_DATABASE=postgres` + `DOCA_DATABASE_URL`, `DOCA_REDIS_URL`, S3 storage through `DOCA_FILE_STORE_ID` / `DOCA_FILE_STORES_JSON`. See upstream `docker.env.example`.

## After deploy

Open the public URL and sign in as `admin` with `DOCA_ADMIN_PASSWORD` from the service Variables. Change the password in settings. AI features need a model provider key, added in the admin area.

Back up the `/data` volume and `DOCA_CREDENTIAL_MASTER_KEY` together.

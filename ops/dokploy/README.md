# Dokploy Environment Templates

This folder contains environment templates for Grenoble Roller on Dokploy
with staging/production separation.

## Layout

- `env/staging.env.example`: staging app environment template
- `env/production.env.example`: production app environment template

## Usage model

1. Copy env template per Dokploy environment and fill values in Dokploy UI.
2. Configure environment variables and secrets in Dokploy UI.
3. Configure health checks and rollback behavior in Dokploy Advanced settings.
4. Configure database and volume backups directly in Dokploy (S3 destination).

## Security notes

- Never commit real secrets.
- Keep `RAILS_MASTER_KEY` in Dokploy secrets only.
- Keep DB and MinIO internal (no public ports unless explicitly required).

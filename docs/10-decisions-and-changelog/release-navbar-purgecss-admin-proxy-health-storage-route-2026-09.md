# Release note — Navbar PurgeCSS + admin image proxy, health, storage purge, route form validation (v2.4.10)

**Date:** 2026-09-12  
**Branch:** `Dev` (local only, not pushed)  
**Scope:** Navbar PurgeCSS, UI Audit Logs, route form validation, health check for Rails 8.1, idempotent Active Storage purge, admin image previews via app proxy.

## Problem

1. **Navbar PurgeCSS not applied** — Although PurgeCSS was configured, the build step was not writing the purged CSS, resulting in ~1.8MiB of unused Bootstrap CSS being served.
2. **UI Audit Logs missing** — The audit log feature for attendance changes was not exposed in the UI, making it inaccessible to administrators.
3. **Route form blocking image upload** — The route form rejected legacy image values, so image upload was failing.
4. **Health check returning 503 on Rails 8.1** — The HealthController was using the pre-8.1 migration API, which changed in Rails 8.1, causing the health endpoint to report migrations as pending.
5. **Active Storage purge not idempotent** — Purging a blob whose S3 object was already missing raised an exception instead of completing.
6. **Admin image previews exposing internal storage URLs** — Admin panel previews rendered raw storage URLs instead of going through the application.

## Solution

**1. Navbar PurgeCSS** — `purgecss.config.js`, `scripts/purge-css.mjs`: the PurgeCSS build step now writes the purged CSS back, shrinking the public CSS bundle from ~1.8MiB to ~344KiB.

**2. Audit Logs UI** — `app/controllers/admin_panel/audit_logs_controller.rb`, `app/views/admin_panel/audit_logs/_logs_table.html.erb`, `app/views/admin_panel/audit_logs/index.html.erb`, `app/views/admin_panel/audit_logs/show.html.erb`, `app/views/admin/shared/_menu_items.html.erb`, `config/routes.rb`: added the audit log screens plus their sidebar entry (superadmin only, `can_access_admin_panel?(70)`, via `admin_panel_audit_logs_path`).

**3. Route form / image upload** — `app/views/admin_panel/routes/edit.html.erb`, `app/views/admin_panel/routes/new.html.erb`: accept the legacy image form values, unblocking route image upload.

**4. Health check (Rails 8.1)** — `app/controllers/health_controller.rb`: uses the Rails 8.1 migration API (`ActiveRecord::MigrationContext`) to count pending migrations, so `GET /health` returns 503 only when migrations are genuinely pending.

**5. Idempotent Active Storage purge** — `app/services/active_storage/s3_service_wrapper.rb`, `config/initializers/s3_wrapper.rb`: `ActiveStorage::S3ServiceWrapper` wraps the S3 service and rescues `Aws::S3::Errors::NoSuchKey` on `delete`, so purging an already-absent object succeeds. Wired by `config/initializers/s3_wrapper.rb`, which patches `ActiveStorage::Service.build` to wrap S3 services.

**6. Admin image previews via the application proxy** — `app/views/admin_panel/events/show.html.erb`, `app/views/admin_panel/homepage_carousels/_form.html.erb`, `app/views/admin_panel/homepage_carousels/index.html.erb`, `app/views/admin_panel/homepage_carousels/show.html.erb`, `app/views/admin_panel/product_variants/edit.html.erb`, `app/views/admin_panel/products/_image_upload.html.erb`, `app/views/admin_panel/products/show.html.erb`, `app/views/admin_panel/routes/edit.html.erb`, `app/views/admin_panel/routes/show.html.erb`, `app/views/admin_panel/users/show.html.erb`: every admin Active Storage preview now renders through `rails_storage_proxy_path` / `rails_representation_path`, so images are served by the application instead of exposing raw storage URLs.

## Migrations / ENV

No migrations.

Staging only: email delivery and cron are disabled through environment flags — `config/environments/staging.rb`, `bin/docker-entrypoint`.

## Tests

`spec/requests/health_spec.rb`, `spec/services/active_storage/s3_service_idempotent_delete_spec.rb`, `spec/system/admin_route_map_image_replacement_spec.rb`, `spec/requests/admin_panel/audit_logs_spec.rb`, `spec/factories/audit_logs.rb`.

Measured on `Dev` @ `1eef5d30`, run alone (no concurrent suite): 518 examples, 0 failures.

## QA

- [ ] Verify that `npm run build:css` produces a purged CSS file under `app/assets/builds/`.
- [ ] Check that the admin panel sidebar includes an "Audit Logs" entry (superadmin) and that it loads the audit log index.
- [ ] Test that image upload works from the route form (legacy values).
- [ ] Confirm that `GET /health` returns 200 when migrations are up to date and 503 when they are not.
- [ ] Test that purging a missing S3 object does not raise and is treated as success.
- [ ] Verify that admin previews (events, products, carousels, routes, users) route through the application proxy and do not leak internal storage URLs.

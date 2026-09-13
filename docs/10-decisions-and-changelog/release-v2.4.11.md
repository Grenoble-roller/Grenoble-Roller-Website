# Release note — ActiveStorage S3 service identity fix (v2.4.11)

**Date:** 2026-09-13  
**Branch:** `staging` (merged from `Dev` via #283)  
**Scope:** Preserve the wrapped S3 service identity so Active Storage validation and uploads continue to work with the idempotent-delete wrapper introduced in v2.4.10.

## Problem

The `ActiveStorage::S3ServiceWrapper` introduced for idempotent S3 deletes did not preserve the underlying service identity correctly.

The wrapper returned its own `service_name` instead of delegating to the wrapped S3 service. Active Storage validation therefore received an unexpected service identity, which could invalidate blobs and block new uploads.

The wrapper also needed to be loaded explicitly to guarantee that the S3 service configurator patch was applied.

## Solution

**1. Preserve S3 service identity** — `app/services/active_storage/s3_service_wrapper.rb`

- Delegate `service_name` to the wrapped service.
- Delegate `name` to the wrapped service.
- Preserve the wrapped service identity required by Active Storage validation.

**2. Preserve idempotent delete behaviour**

The wrapper continues to rescue `Aws::S3::Errors::NoSuchKey` during deletion, so purging an object that is already absent from S3 remains successful.

**3. Ensure wrapper initialization** — `config/initializers/s3_wrapper.rb`

Explicitly load the S3 service wrapper so the Active Storage service configurator patch is consistently installed.

## Migrations / ENV

No migrations.

No new environment variables.

## Tests

Validation performed before merge:

- 37 specs executed
- 0 failures
- Active Storage blob validation confirmed with the wrapped S3 service
- Browser/system coverage included for route map image handling
- Idempotent S3 purge behaviour covered

## Deployment

Merged from `Dev` to `staging` via PR #283.

Staging merge commit:

`3677a97b8e9ae747464bcc9b383fb78de300d645`

## QA

- [ ] Upload a new image through an Active Storage-backed form.
- [ ] Confirm the resulting blob validates successfully.
- [ ] Confirm S3-backed images continue to render normally.
- [ ] Purge a blob whose S3 object is already absent and confirm no exception is raised.
- [ ] Confirm `/health` remains healthy after deployment.

## Rollback

Revert the v2.4.11 Active Storage wrapper changes or redeploy the previous staging release if upload validation regresses.

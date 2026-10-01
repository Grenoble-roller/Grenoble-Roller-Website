# Release note — Contact Discord webhook UI + embed (v2.4.13)

**Date:** 2026-10-01  
**Branch:** `Dev`  
**Scope:** Admin UX to configure a dedicated Discord webhook for contact form messages, plus an improved `contact_message.received` embed. Reuses DR-002 (`NotificationChannel` / `NotificationDispatchService`). No payment or HelloAsso changes.

## Summary

Admins (≥ 60) can enable Discord alerts for new `/contact` submissions from the contact messages page. The embed layout (variant F, validated with Florian) shows emoji identity fields without text labels and puts the message body in a code fence at the bottom.

## Changes

### Admin UI (`/admin-panel/contact-messages`)

- Header actions: **Tester** (when webhook configured) + **Discord ON/OFF** opens a Bootstrap modal.
- Modal (`_discord_settings_modal.html.erb`): webhook URL (encrypted at rest), enable switch, save, test (supports unsaved URL in the form).
- Routes: `PATCH …/update_discord_settings`, `POST …/test_discord`.
- Policy: `configure_discord?` / `test_discord?` for admin level ≥ 60.

### Data model

- Migration `AddPurposeToNotificationChannels` — nullable unique `purpose`.
- `NotificationChannel.contact_messages_channel` / `ensure_contact_messages_subscription!` / `contact_messages_notifications_active?`.
- Dedicated channel name: « Messages de contact », event key: `contact_message.received` (already dispatched on public create).

### Embed (`NotificationEventRegistry#contact_message_received_payload`)

- Title: `📩 Nouveau message contact`
- Color: `#E67E22`
- Fields (emoji inside value, zero-width names so Discord does not break emoji onto its own line):
  - `👤 Name` · `✉️ \`email\``
  - `📝 **Subject**`
  - Message body in a plain ``` code fence (no 💬 emoji)
- Footer: `Grenoble Roller Admin · #<id>` + embed timestamp

### Gate

Unchanged DR-002 gate: production always; staging/dev requires `ALLOW_DISCORD_NOTIFICATIONS=true`.

## Migrations / ENV

- Migration: `20261001204047_add_purpose_to_notification_channels.rb`
- Optional ENV (non-prod): `ALLOW_DISCORD_NOTIFICATIONS=true`

## Tests

- `spec/requests/admin_panel/contact_messages_spec.rb` — index modal, create/update Discord settings, test with stored or submitted URL
- `spec/services/notification_event_registry_spec.rb` — still green

## QA

- [ ] Open `/admin-panel/contact-messages` → Discord modal → paste webhook → enable → Enregistrer
- [ ] Header **Tester** or modal **Tester le webhook** posts a `test.ping`
- [ ] Submit `/contact` (or dispatch sample) → Discord shows F layout (code fence message, no message emoji)
- [ ] Staging: set `ALLOW_DISCORD_NOTIFICATIONS=true` when real dispatches are desired

## Rollback

Disable the contact Discord channel in admin, or unset `ALLOW_DISCORD_NOTIFICATIONS` on staging. Revert this release if the migration / UI must be removed.

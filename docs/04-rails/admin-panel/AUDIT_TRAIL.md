# Audit Trail Implementation Guide

This document describes the audit trail mechanism implemented in the Grenoble-Roller application.

## Overview

An audit trail (or audit log) provides an immutable record of changes to critical business objects. It answers the questions: who did what, when, and what were the values before and after the change.

## Implementation

We use a concern `Auditable` (`app/models/concerns/auditable.rb`) that adds `after_create`, `after_update`, and `after_destroy` callbacks to include an entry in the `audit_logs` table.

The `AuditLog` model already exists and is used for email confirmation audits.

Each model that includes `Auditable` must implement:
- `audit_actor`: returns the `User` responsible for the change (or `nil` if unknown).
- `audit_attributes`: returns a hash of attributes to store in the audit log's `metadata` field.

## Candidates for Audit Trail

Based on the domain, the following models would benefit from an audit trail:

| Model | Reason | Key Fields to Audit |
|-------|--------|---------------------|
| `Attendance` | Inscriptions, désinscriptions, changements de statut, liste d’attente | `user_id`, `event_id`, `status`, `child_membership_id`, `is_volunteer`, `free_trial_used`, `wants_reminder`, `needs_equipment`, `roller_size`, `payment_id` |
| `Event` | Modification du titre, date, statut, capacité, visibilité SEO/GEO | `title`, `start_at`, `duration_min`, `status`, `max_participants`, `location_text`, `cover_image` (via attachment), `published_at` |
| `User` | Changement de rôle, confirmation e-mail, modification de profil | `role_id`, `confirmed_at`, `email`, `first_name`, `last_name`, `skill_level` |
| `Membership` | Statut, renouvellement, utilisation d’essai gratuit | `status`, `starts_at`, `expires_at`, `is_child_membership`, `free_trial_used`, `payment_id` |
| `Payment` | Succès/échec de transaction, montants, références | `provider`, `provider_payment_id`, `amount_cents`, `currency`, `status` |
| `WaitlistEntry` | Entrée en liste d’attente, notification, conversion, refus | `event_id`, `user_id`, `child_membership_id`, `status` (`pending`, `notified`, `converted`, `cancelled`) |
| `CartLine` (panier unifié) | Ajout/suppression, changement de quantité, passage à l’achat | `line_type`, `reference_id`, `quantity`, `status` |
| `Checkout` (session HelloAsso) | Création, statut, completion/échec | `status`, `amount_cents`, `currency`, `helloasso_session_id` |
| `NotificationChannel` | Création/modification/suppression de webhooks Discord | `url`, `events` (liste), `active` |
| `NotificationDelivery` | Envoi/échec de notifications | `notification_channel_id`, `delivered_at`, `error_message` |

## Currently Audited Models

- `Attendance` (implemented)

## How to Add Auditing to a New Model

1. Generate the concern if it doesn’t exist (already done).
2. Include `Auditable` in the model:
   ```ruby
   class Event < ApplicationRecord
     include Auditable
     # ...
   end
   ```
3. Implement `audit_actor` (usually `creator_user` or a relevant user).
4. Implement `audit_attributes` returning the hash of fields you want to track.
5. Add tests to verify that create, update, and destroy produce audit log entries.

## Accessing Audit Logs

Audit logs are accessible via the admin panel at `/admin-panel/audit_logs` (requires admin or super‑admin role). The interface allows filtering by action, target type, target ID, actor user, and date range.

## Testing

Audit trail behavior should be tested with RSpec. See `spec/models/attendance_spec.rb` for an example.

## Notes

- The `audit_update` callback logs every update; if a model has frequent updates on irrelevant fields, consider overriding `audit_update` to skip logging when no relevant attributes changed.
- The `metadata` field is stored as JSONB (if using PostgreSQL) or serialized text; you can query it with PostgreSQL JSON functions.
# Release note — Dual waitlist initiations member/discovery (v2.4.14)

**Date:** 2026-10-02  
**Branch:** `Dev`  
**Scope:** Separate waitlist queues for initiation **member** vs **discovery** pools when `allow_non_member_discovery` is enabled. No HelloAsso / cart changes.

## Summary

Initiations with discovery slots now maintain two FIFO waitlists. Joining is gated on the user's own pool being full (`full_for_members?` / `full_for_non_members?`). When a seat frees, only the matching pool's head is notified — no cross-pool FIFO.

## Changes

### Data model

- Migration `AddPoolToWaitlistEntries` — `waitlist_entries.pool` (`member` | `discovery`, default `member`).
- `WaitlistEntry.pool_for`, `pool_full?`, `pool_has_available_spot?`, `notify_next_in_queue(..., pool:)`.
- Positions reorganized **per pool**.

### Policy / UI

- `Event::InitiationPolicy#join_waitlist?` pool-aware; discovery waitlist allowed for eligible non-members (unused free trial).
- Initiation show: CTA for member or discovery waitlist; registration blocked when the user's pool is full even if the other pool still has seats.

### Callbacks

- `Attendance` destroy/cancel notifies the freed attendance's pool.
- Admin initiation convert / volunteer toggle pass pool (or detect available pools).

## Migrations / ENV

| Item | Value |
| --- | --- |
| Migration | `20261001214912_add_pool_to_waitlist_entries.rb` |
| New ENV | none |

Existing staging safety ENV unchanged: `MAIL_DELIVERY_METHOD=test`, `MAIL_DELIVERY_ENABLED=false`, `SUPERCRONIC_ENABLED=false`.

## Tests

- `spec/models/event/initiation_dual_waitlist_spec.rb` — capacity, join, notify per pool, destroy callback
- `spec/policies/event/initiation_policy_spec.rb` — dual-pool join cases
- `spec/requests/waitlist_entries_spec.rb` — discovery / member join when pool full
- `spec/models/waitlist_entry_spec.rb` — still green

## QA staging

- [ ] Initiation with discovery: fill **member** slots only → member sees waitlist CTA, not direct register
- [ ] Fill **discovery** slots only → non-member (unused trial) can join discovery waitlist
- [ ] Cancel a discovery attendance → discovery waiter notified (not a member ahead in global order)
- [ ] Cancel a member attendance → member waiter notified
- [ ] Initiation **without** discovery: member-only waitlist when `full?` (unchanged)

## Rollback

Redeploy previous staging image / revert merge. Migration adds a non-null column with default — reverse by removing `pool` if a full rollback of the feature is required.

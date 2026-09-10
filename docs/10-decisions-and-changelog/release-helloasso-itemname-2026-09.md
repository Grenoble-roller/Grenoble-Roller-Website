# Release note — HelloAsso itemName clamp (v2.4.8)

**Date:** 2026-09-10  
**Branch:** `fix/helloasso-itemname-max-length` → `Dev`  
**Scope:** P0 fix for multi-membership HelloAsso checkout init (HTTP 400).

## Problem

HelloAsso checkout-intent rejects `itemName` longer than **250 characters** with HTTP 400.

Unified carts that concatenate every line label (parent + several children memberships) could exceed that limit (~284 chars observed). Payment init failed with a generic UI error; the unified path did not log the HelloAsso response body.

Single-membership checkouts under 250 chars continued to succeed.

## Solution

| Change | Detail |
|--------|--------|
| `HelloassoService.clamp_item_name` | Join labels when ≤250; otherwise use a short panier/cotisation fallback (truncate fallback if needed) |
| Payload builders | Unified, legacy Order, single membership, multi-membership all go through the clamp |
| Observability | `create_unified_checkout_intent` logs ERROR + response body on non-success |

Line details remain in checkout-intent **metadata** (`items`), not only in `itemName`.

## Migrations / ENV

None.

## QA

- [ ] `bundle exec rspec spec/services/helloasso_service_spec.rb`
- [ ] Staging: cart with 4 memberships (adult + 3 children) → HelloAsso redirect OK
- [ ] Staging: single membership → detailed `itemName` when ≤250
- [ ] On failure: log contains `create_unified_checkout_intent ERROR`

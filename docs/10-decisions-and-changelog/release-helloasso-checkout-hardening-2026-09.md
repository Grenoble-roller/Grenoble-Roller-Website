# Release note — HelloAsso checkout hardening (v2.4.9)

**Date:** 2026-09-10  
**Branch:** `fix/helloasso-checkout-hardening` → `Dev`  
**Depends on:** v2.4.8 itemName clamp (`fix/helloasso-itemname-max-length`)  
**Scope:** Block legacy Order payment when a unified Checkout is open; compact HA metadata; cap line labels.

## Problem

1. **Partial / double payment risk:** Unified checkout creates a pending product `Order`. `orders/show` still offered “Finaliser le paiement”, which called legacy `create_checkout_intent` for products only while a unified Checkout remained open.
2. **Oversized metadata:** Dense carts can push HelloAsso checkout-intent metadata past practical size limits.
3. **Long labels:** Unbounded cart/checkout labels feed into payloads and UI.

## Solution

| Change | Detail |
|--------|--------|
| `Order#open_unified_checkout` | Find pending/processing Checkout with `metadata.order_id` |
| `Orders::PaymentsController` | Resume HA intent or redirect to `/checkout`; never create legacy intent in that case |
| `orders/show` | CTA “Finaliser via le panier” when unified checkout is open |
| `compact_checkout_metadata` | Soft ~18KB limit: slim items, then drop `items` if still too large |
| Label cap | `CartLine` / `CheckoutLine` max 200; truncate on cart + checkout create |

## Migrations / ENV

None.

## QA

- [ ] `bundle exec rspec spec/services/helloasso_service_spec.rb spec/models/cart_line_spec.rb spec/requests/orders_spec.rb`
- [ ] Product+membership cart → abandon HA → order show shows “Finaliser via le panier”; POST payments does not create legacy intent
- [ ] Pure legacy pending order (no checkout link) still pays via HelloAsso

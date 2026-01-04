# Domain Models

This document describes the current domain models and their relationships in the Grenoble Roller application.

## Overview

The application implements:
- **Phase 1** (✅ Complete): E-commerce system with user authentication and role-based access control
- **Phase 2** (🔄 In Progress): Event management features (models and migrations created, controllers and views pending)

## Core Models

### User

Authentication and user profile management using Devise.

**Attributes:**
- `email` (string, unique, required)
- `encrypted_password` (string, required)
- `first_name` (string)
- `last_name` (string)
- `bio` (text)
- `phone` (string, limit: 10)
- `avatar_url` (string)
- `email_verified` (boolean, default: false)
- `role_id` (integer, foreign key, required)

**Relationships:**
- `belongs_to :role`
- `has_many :orders`
- `has_many :created_events` (Event, as creator_user)
- `has_many :attendances`
- `has_many :events, through: :attendances`
- `has_many :organizer_applications`
- `has_many :reviewed_applications` (OrganizerApplication, as reviewed_by)
- `has_many :audit_logs` (AuditLog, as actor_user)

**Indexes:**
- `email` (unique)
- `reset_password_token` (unique, for Devise)

### Role

7-level permission system for access control.

**Attributes:**
- `code` (string, limit: 50, unique, required)
- `name` (string)
- `description` (text)
- `level` (integer, limit: 2, required)

**Roles (by level):**
1. `USER` (10) - Basic user
2. `REGISTERED` (20) - Registered member
3. `INITIATION` (30) - Initiation level
4. `ORGANIZER` (40) - Can create events (Phase 2)
5. `MODERATOR` (50) - Can moderate content (Phase 2)
6. `ADMIN` (60) - Full administrative access
7. `SUPERADMIN` (70) - Highest level access

**Relationships:**
- `has_many :users`

**Indexes:**
- `code` (unique)

## E-commerce Models

### ProductCategory

Product categorization.

**Attributes:**
- `name` (string, limit: 100, required)
- `slug` (string, limit: 120, unique, required)

**Relationships:**
- `has_many :products`

**Current Categories:**
- Rollers
- Protections
- Accessoires

### Product

Main product entity.

**Attributes:**
- `name` (string, limit: 140, required)
- `slug` (string, limit: 160, unique, required)
- `description` (text)
- `price_cents` (integer, required)
- `currency` (string, limit: 3, default: "EUR")
- `stock_qty` (integer, default: 0)
- `is_active` (boolean, default: true)
- `image_url` (string, limit: 255)
- `category_id` (bigint, foreign key, required)

**Relationships:**
- `belongs_to :category` (ProductCategory)
- `has_many :variants` (ProductVariant)

**Indexes:**
- `slug` (unique)
- `is_active, slug` (composite)

### ProductVariant

Product variations (size, color, etc.).

**Attributes:**
- `sku` (string, limit: 80, unique, required)
- `price_cents` (integer, required)
- `currency` (string, limit: 3, default: "EUR")
- `stock_qty` (integer, default: 0)
- `is_active` (boolean, default: true)
- `product_id` (bigint, foreign key, required)

**Relationships:**
- `belongs_to :product`
- `has_many :variant_option_values`
- `has_many :option_values, through: :variant_option_values`
- `has_many :order_items`

**Indexes:**
- `sku` (unique)
- `product_id`

### OptionType

Type of product option (e.g., "size", "color").

**Attributes:**
- `name` (string, limit: 50, unique, required)
- `presentation` (string, limit: 100)

**Relationships:**
- `has_many :option_values`

**Current Types:**
- `size` - Product sizes
- `color` - Product colors

### OptionValue

Specific option values (e.g., "S", "M", "L" for size).

**Attributes:**
- `value` (string, limit: 50, required)
- `presentation` (string, limit: 100)
- `option_type_id` (bigint, foreign key, required)

**Relationships:**
- `belongs_to :option_type`
- `has_many :variant_option_values`
- `has_many :variants, through: :variant_option_values`

### VariantOptionValue

Join table linking variants to their option values.

**Attributes:**
- `variant_id` (bigint, foreign key, required)
- `option_value_id` (bigint, foreign key, required)

**Relationships:**
- `belongs_to :variant` (ProductVariant)
- `belongs_to :option_value`

**Indexes:**
- `variant_id, option_value_id` (unique composite)

## Order Management Models

### Order

Customer order.

**Attributes:**
- `status` (string, default: "pending", required)
  - Values: `pending`, `paid`, `shipped`, `cancelled`
- `total_cents` (integer, default: 0, required)
- `currency` (string, limit: 3, default: "EUR", required)
- `user_id` (bigint, foreign key, required)
- `payment_id` (bigint, foreign key, optional)

**Relationships:**
- `belongs_to :user`
- `belongs_to :payment` (optional)
- `has_many :order_items`

**Indexes:**
- `user_id`
- `payment_id`

### OrderItem

Individual items in an order.

**Attributes:**
- `quantity` (integer, default: 1, required)
- `unit_price_cents` (integer, required)
- `order_id` (bigint, foreign key, required)
- `variant_id` (integer, foreign key, required)

**Relationships:**
- `belongs_to :order`
- `belongs_to :variant` (ProductVariant)

**Indexes:**
- `order_id`
- `variant_id`

### Payment

Payment record (multi-provider ready).

**Attributes:**
- `provider` (string, limit: 20, required)
  - Values: `stripe`, `paypal`, `mollie`, `helloasso`, `free`
- `provider_payment_id` (string) - External payment ID
- `amount_cents` (integer, default: 0, required)
- `currency` (string, limit: 3, default: "EUR", required)
- `status` (string, limit: 20, default: "succeeded", required)
  - Values: `succeeded`, `pending`, `failed`

**Relationships:**
- `has_many :orders`
- `has_many :attendances`

## Entity Relationship Diagram

### Phase 1 - E-commerce
```
User ──┬──> Role
       │
       └──> Order ──┬──> Payment
                    │
                    └──> OrderItem ──> ProductVariant ──┬──> Product ──> ProductCategory
                                                         │
                                                         └──> VariantOptionValue ──> OptionValue ──> OptionType
```

### Phase 2 - Events & Admin
```
User ──┬──> Event (creator_user_id)
       │
       ├──> Attendance ──┬──> Event
       │                 └──> Payment (optional)
       │
       ├──> OrganizerApplication ──> User (reviewed_by)
       │
       └──> AuditLog (actor_user_id)

Event ──> Route (optional)

Partner (standalone)
ContactMessage (standalone)
```

## Event Management Models (Phase 2)

### Route

Predefined routes with GPX data and safety information.

**Attributes:**
- `name` (string, limit: 140, required)
- `description` (text)
- `distance_km` (decimal, precision: 5, scale: 2)
- `elevation_m` (integer)
- `difficulty` (string, limit: 20) - Values: `easy`, `medium`, `hard`
- `gpx_url` (string, limit: 255)
- `map_image_url` (string, limit: 255)
- `safety_notes` (text)

**Relationships:**
- `has_many :events`

**Validations:**
- `name` presence, length max 140
- `difficulty` inclusion in ['easy', 'medium', 'hard'], allow_nil
- `distance_km` numericality >= 0, allow_nil
- `elevation_m` numericality integer >= 0, allow_nil

### Event

Rollerblading events/outings organized by users.

**Attributes:**
- `creator_user_id` (bigint, foreign key, required)
- `route_id` (bigint, foreign key, optional)
- `status` (string, limit: 20, default: "draft", required)
  - Values: `draft`, `published`, `canceled`
- `start_at` (timestamptz, required)
- `duration_min` (integer, required) - Must be > 0 and multiple of 5
- `title` (string, limit: 140, required) - Length 5..140
- `description` (text, required) - Length 20..1000
- `price_cents` (integer, default: 0, required) - >= 0
- `currency` (string, limit: 3, default: "EUR", required)
- `location_text` (string, limit: 255, required)
- `meeting_lat` (decimal, precision: 9, scale: 6)
- `meeting_lng` (decimal, precision: 9, scale: 6)
- `cover_image_url` (string, limit: 255)

**Relationships:**
- `belongs_to :creator_user` (User)
- `belongs_to :route` (optional)
- `has_many :attendances`
- `has_many :users, through: :attendances`

**Scopes:**
- `upcoming` - Events with start_at > now
- `past` - Events with start_at <= now
- `published` - Events with status: 'published'

**Validations:**
- `status` presence, enum with validate: true
- `start_at` presence
- `duration_min` presence, integer > 0, multiple_of: 5
- `title` presence, length 5..140
- `description` presence, length 20..1000
- `price_cents` presence, >= 0
- `currency` presence, length 3
- `location_text` presence, length max 255

**Indexes:**
- `creator_user_id`
- `route_id`
- `status, start_at` (composite)

### Attendance

User registrations for events.

**Attributes:**
- `user_id` (bigint, foreign key, required)
- `event_id` (bigint, foreign key, required)
- `status` (string, limit: 20, default: "registered", required)
  - Values: `registered`, `paid`, `canceled`, `present`, `no_show`
- `payment_id` (bigint, foreign key, optional)
- `stripe_customer_id` (string, limit: 255)

**Relationships:**
- `belongs_to :user`
- `belongs_to :event`
- `belongs_to :payment` (optional)

**Validations:**
- `status` presence, enum with validate: true
- `user_id` uniqueness scope event_id (one registration per user per event)

**Scopes:**
- `active` - Attendances not canceled
- `canceled` - Attendances canceled

**Indexes:**
- `user_id`
- `event_id`
- `payment_id`
- `user_id, event_id` (unique composite)

### OrganizerApplication

User applications to become event organizers.

**Attributes:**
- `user_id` (bigint, foreign key, required)
- `reviewed_by_id` (bigint, foreign key, optional) - Admin/moderator who reviewed
- `motivation` (text)
- `status` (string, limit: 20, default: "pending", required)
  - Values: `pending`, `approved`, `rejected`
- `reviewed_at` (timestamp)

**Relationships:**
- `belongs_to :user`
- `belongs_to :reviewed_by` (User, optional)

**Validations:**
- `status` presence, enum with validate: true
- `motivation` presence if status == 'pending'

### Partner

Business partners and sponsors.

**Attributes:**
- `name` (string, limit: 140, required)
- `url` (string, limit: 255)
- `logo_url` (string, limit: 255)
- `description` (text)
- `is_active` (boolean, default: true, required)

**Relationships:**
- None

**Validations:**
- `name` presence, length max 140
- `url` format URL, allow_blank
- `is_active` inclusion in [true, false]

**Scopes:**
- `active` - Active partners
- `inactive` - Inactive partners

### ContactMessage

Contact form messages from users.

**Attributes:**
- `name` (string, limit: 140, required)
- `email` (string, limit: 255, required)
- `subject` (string, limit: 140, required)
- `message` (text, required)

**Relationships:**
- None

**Validations:**
- `name` presence, length max 140
- `email` presence, format email
- `subject` presence, length max 140
- `message` presence, length min 10

### AuditLog

Audit trail for admin/moderator actions.

**Attributes:**
- `actor_user_id` (bigint, foreign key, required)
- `action` (string, limit: 80, required) - e.g., "event.publish", "user.promote"
- `target_type` (string, limit: 50, required) - Polymorphic target type
- `target_id` (integer, required) - Polymorphic target ID
- `metadata` (jsonb) - Additional flexible data

**Relationships:**
- `belongs_to :actor_user` (User)

**Validations:**
- `action` presence, length max 80
- `target_type` presence, length max 50
- `target_id` presence, integer

**Scopes:**
- `by_action(action)` - Filter by action
- `by_target(type, id)` - Filter by target
- `by_actor(user_id)` - Filter by actor
- `recent` - Order by created_at desc

**Indexes:**
- `actor_user_id`
- `target_type, target_id` (composite)

## Database Migrations

All migrations are located in `db/migrate/`. Current schema version: `2025_11_07_164412` (includes Phase 2).

**Phase 1 migrations** (13 migrations):
- Users, Roles, Products, Orders, Payments, etc.

**Phase 2 migrations** (7 migrations):
- Routes, Events, Attendances, OrganizerApplications, Partners, ContactMessages, AuditLogs

To view the complete schema:

```bash
cat db/schema.rb
```

See `docs/02-shape-up/building/phase2-migrations-models.md` for detailed Phase 2 migration documentation.

## Seed Data

The `db/seeds.rb` file creates:

### Phase 1 - E-commerce
- 7 roles (USER to SUPERADMIN)
- 1 admin user
- 1 superadmin user (Florian)
- 5 test client users
- 5 payments (various providers and statuses)
- 5 orders
- 3 product categories
- Multiple products with variants and options
- 10-13 order items

### Phase 2 - Events & Admin
- 5 routes (parcours prédéfinis)
- 6 events (4 published, 1 draft, 1 canceled)
- 11-12 attendances (inscriptions)
- 3 organizer applications (pending, approved, rejected)
- 4 partners (3 active, 1 inactive)
- 4 contact messages
- 5 audit logs

Run seeds:

```bash
docker exec grenoble-roller-dev bin/rails db:seed
```


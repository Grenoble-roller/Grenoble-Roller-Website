# 📊 Phase 2 - Migrations et Modèles

**Date** : 2025-01-20  
**Statut** : ✅ Migrations appliquées et modèles créés

---

## ✅ MIGRATIONS CRÉÉES

### Tables Phase 2

1. **Routes** - Parcours roller
2. **Events** - Événements et initiations (STI)
3. **Attendances** - Inscriptions aux événements
4. **EventLoopRoutes** - Parcours multiples pour un événement
5. **WaitlistEntries** - Liste d'attente pour événements complets
6. **OrganizerApplications** - Candidatures organisateurs
7. **Partners** - Partenaires
8. **ContactMessages** - Messages de contact
9. **AuditLogs** - Journal d'audit

---

## ✅ MODÈLES PHASE 2

### Route (`app/models/route.rb`)

**Associations** :
- `has_many :events, dependent: :nullify`
- `has_many :event_loop_routes, dependent: :destroy`

**Colonnes principales** :
- name, description, distance_km, elevation_m, difficulty
- gpx_url, map_image_url, safety_notes

### Event (`app/models/event.rb`)

**Associations** :
- `belongs_to :creator_user, class_name: 'User'`
- `belongs_to :route, optional: true`
- `has_many :attendances, dependent: :destroy` (counter_cache: true)
- `has_many :users, through: :attendances`
- `has_many :event_loop_routes, dependent: :destroy`
- `has_many :loop_routes, through: :event_loop_routes`
- `has_many :waitlist_entries, dependent: :destroy`

**Colonnes principales** :
- creator_user_id, status, start_at, duration_min
- title, description, price_cents, currency
- location_text, meeting_lat, meeting_lng
- route_id, level, distance_km
- max_participants, attendances_count (counter cache)
- type (STI pour Event::Initiation)
- is_recurring, loops_count, season
- allow_non_member_discovery, non_member_discovery_slots

**Enums** :
- `status` : draft, published, rejected, canceled
- `level` : beginner, intermediate, advanced, all_levels

**Scopes principaux** :
- `upcoming`, `past`, `published`, `visible`
- `not_initiations`, `pending_validation`, `rejected`

### Attendance (`app/models/attendance.rb`)

**Associations** :
- `belongs_to :user`
- `belongs_to :event, counter_cache: true`
- `belongs_to :payment, optional: true`
- `belongs_to :child_membership, optional: true`

**Colonnes principales** :
- user_id, event_id, status
- payment_id, child_membership_id
- wants_reminder, reminder_sent_at
- is_volunteer, needs_equipment, roller_size
- equipment_note, free_trial_used

**Enums** :
- `status` : pending, registered, paid, canceled, present, no_show

**Scopes principaux** :
- `active`, `canceled`, `volunteers`, `participants`
- `for_parent`, `for_children`

### EventLoopRoute (`app/models/event_loop_route.rb`)

**Associations** :
- `belongs_to :event`
- `belongs_to :route`

**Colonnes principales** :
- event_id, route_id, loop_number, distance_km

### WaitlistEntry (`app/models/waitlist_entry.rb`)

**Associations** :
- `belongs_to :user`
- `belongs_to :event`
- `belongs_to :child_membership, optional: true`

**Colonnes principales** :
- user_id, event_id, status, position
- child_membership_id, notified_at
- needs_equipment, roller_size, wants_reminder
- use_free_trial

### OrganizerApplication (`app/models/organizer_application.rb`)

**Associations** :
- `belongs_to :user`
- `belongs_to :reviewed_by, class_name: 'User', optional: true`

**Colonnes principales** :
- user_id, motivation, status
- reviewed_by_id, reviewed_at

**Enums** :
- `status` : pending, approved, rejected

### Partner (`app/models/partner.rb`)

**Associations** : Aucune

**Colonnes principales** :
- name, url, logo_url, description, is_active

**Scopes** :
- `active`

### ContactMessage (`app/models/contact_message.rb`)

**Associations** : Aucune

**Colonnes principales** :
- name, email, subject, message

### AuditLog (`app/models/audit_log.rb`)

**Associations** :
- `belongs_to :actor_user, class_name: 'User'`

**Colonnes principales** :
- actor_user_id, action, target_type, target_id
- metadata (jsonb)

**Scopes principaux** :
- `by_action`, `by_target`, `by_actor`, `recent`

---

## ✅ MODÈLES MIS À JOUR (Phase 2)

### User (`app/models/user.rb`)

**Associations ajoutées** :
- `has_many :created_events, class_name: 'Event', foreign_key: 'creator_user_id'`
- `has_many :attendances, dependent: :destroy`
- `has_many :events, through: :attendances`
- `has_many :organizer_applications, dependent: :destroy`
- `has_many :reviewed_applications, class_name: 'OrganizerApplication', foreign_key: 'reviewed_by_id'`
- `has_many :audit_logs, class_name: 'AuditLog', foreign_key: 'actor_user_id'`

### Payment (`app/models/payment.rb`)

**Associations ajoutées** :
- `has_many :attendances, dependent: :nullify`

---

## 📚 RESSOURCES

- **Documentation modèles complète** : `docs/03-architecture/domain/models.md`
- **Schema DB actuel** : `db/schema.rb`
- **Migrations** : `db/migrate/`

---

**Document créé le** : 2025-01-20  
**Dernière mise à jour** : 2025-01-30

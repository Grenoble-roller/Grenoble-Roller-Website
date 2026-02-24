# RSpec – Tests et corrections

- **Méthodologie** : [METHODE.md](METHODE.md)
- **Audit des échecs** : [spec-failures-audit.md](spec-failures-audit.md)
- **Template fiche d’erreur** : [errors/TEMPLATE.md](errors/TEMPLATE.md)

## Fiches d’erreur (errors/)

| Fiche | Titre | Spec(s) concerné(s) |
|-------|--------|----------------------|
| [001](errors/001-dashboard-html-diff.md) ✅ | Dashboard GET /admin-panel – diff HTML | dashboard_spec.rb:21 (résolu) |
| [002](errors/002-inventory-variant-ransack.md) ✅ | Inventory variant déjà utilisé + Ransack | inventory_spec.rb (résolu) |
| [003](errors/003-initiation-policy-index-update.md) ✅ | InitiationPolicy index? / update? | initiation_policy_spec.rb (résolu) |
| [004](errors/004-admin-initiations-redirect.md) ✅ | Admin initiations 302 et redirect | initiations_spec.rb, base_controller_spec.rb (résolu) |
| [005](errors/005-attendance-free-trial-can-register.md) ✅ | Attendance free_trial / can_register | attendance_spec.rb (résolu) |
| [006](errors/006-waitlist-notify-child-trial.md) ✅ | WaitlistEntry notify! child free trial | waitlist_entry_spec.rb (résolu) |
| [007](errors/007-initiation-registration.md) ✅ | Initiation registration Free Trial, member_participants_count | initiation_registration_spec.rb:109, 1407, 1437 (résolu) |
| [008](errors/008-memberships-renew-child.md) ✅ | Memberships renouvellement enfant, GET new?type=child | memberships_spec.rb:293, 586, 620 (résolu) |
| [009](errors/009-products-variant-options.md) ✅ | Products variantes options catégorisation | products_spec.rb:41 (résolu) |
| [010](errors/010-registrations-welcome-email.md) | Registrations welcome email deliver_later | registrations_spec.rb:70 |

## Lancer les specs dans le conteneur dev

```bash
docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec spec/
```

Pour un fichier ou une ligne : ajouter le chemin et optionnellement `:LIGNE`.

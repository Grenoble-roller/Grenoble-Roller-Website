# RSpec – Tests et corrections

**Dernière mise à jour** : 2026-08-14


- **Méthodologie** : [METHODE.md](METHODE.md)
- **Audit des échecs** : [spec-failures-audit.md](spec-failures-audit.md)
- **Template fiche d’erreur** : [errors/TEMPLATE.md](errors/TEMPLATE.md)
- **Plan RSpec & refactoring** : [PLAN.md](PLAN.md)
- **Templates refactoring** : [refactoring/](refactoring/)

> Les fiches d'erreur résolues (`errors/001`–`012`, `RESUME_ANALYSES.md`), le rapport
> d'audit (`RSPEC_AUDIT_REPORT.md`) et le rapport de refactoring
> (`refactoring/REFACTORING_REPORT.md`) ont été archivés (résolus dans le code).
> Le statut détaillé vit dans [PLAN.md](PLAN.md).

## Lancer les specs dans le conteneur dev

```bash
docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec spec/
```

Pour un fichier ou une ligne : ajouter le chemin et optionnellement `:LIGNE`.

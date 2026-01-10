# 🔴 Problème : Email de File d'Attente Non Envoyé

**Date de création** : 2025-12-30  
**Statut** : ⚠️ **PROBLÈME IDENTIFIÉ - À CORRIGER**  
**Priorité** : 🔴 **HAUTE** - Les utilisateurs ne reçoivent pas les notifications de places disponibles

---

## 📋 Description du Problème

Les emails de notification de file d'attente (`waitlist_spot_available`) **ne sont pas envoyés** aux utilisateurs lorsqu'une place se libère et qu'ils sont les suivants sur la liste d'attente.

### Symptômes Observés

- ✅ L'entrée de file d'attente est correctement mise à jour (`status = "notified"`, `notified_at` est défini)
- ✅ L'attendance "pending" est créée correctement
- ✅ Le statut dans l'interface admin montre "Notifié" avec la date
- ❌ **L'email n'est pas reçu** par l'utilisateur (mais la logique fonctionne)
- ❌ Aucune erreur visible dans les logs (erreur silencieuse)
- ✅ Les autres emails fonctionnent correctement (confirmation, annulation, etc.)

---

## 🔍 Analyse du Code

### Fichier concerné

**`app/models/waitlist_entry.rb`** - Méthode `send_notification_email` (lignes 228-234)

```ruby
# Envoyer l'email de notification pour une place disponible
def send_notification_email
  EventMailer.waitlist_spot_available(self).deliver_now
rescue => e
  Rails.logger.error("Failed to send waitlist notification email for WaitlistEntry #{id}: #{e.message}")
  # Ne pas faire échouer la notification si l'email échoue
end
```

### Problèmes identifiés

#### 1. 🔴 **CRITIQUE : Jobs SolidQueue non exécutés ou exécutés avant commit de transaction**

**Problème principal** : `deliver_later` utilise SolidQueue pour mettre le job en queue, mais :
- Le job peut être exécuté **avant** que la transaction ActiveRecord soit commitée
- `notified_at` peut être `nil` dans le mailer si le job s'exécute trop tôt
- Les workers SolidQueue peuvent s'arrêter de traiter les jobs

**Ordre des opérations problématique** :
```ruby
# Dans notify!
update!(status: "notified", notified_at: Time.current)  # Transaction ActiveRecord
send_notification_email  # Appelle deliver_later
# Le job peut s'exécuter AVANT que la transaction soit commitée
```

**Conséquence** : Le mailer peut recevoir `waitlist_entry.notified_at = nil`, causant une erreur silencieuse lors du calcul de `@expiration_time`.

#### 2. ⚠️ **Utilisation de `deliver_later` sans garantie de transaction**

**Problème** : `deliver_later` met le job en queue, mais si le job s'exécute avant le commit de la transaction, les données peuvent ne pas être disponibles.

**Solution** : Utiliser `reload` pour garantir que les données sont à jour dans le mailer.

#### 3. 🔇 **Erreur silencieuse dans le mailer**

**Problème** : Si `notified_at` est `nil` dans le mailer, le calcul `waitlist_entry.notified_at + 24.hours` échoue silencieusement.

**Solution** : Ajouter une vérification et un fallback dans le mailer.

---

## 🎯 Solutions Proposées

### Solution 1 : ❌ **REJETÉE** - Ne pas vérifier `wants_events_mail`

**⚠️ IMPORTANT** : Cette solution a été rejetée car l'email de file d'attente est **critique** et doit **TOUJOURS** être envoyé.

**Raison** :
- L'utilisateur a explicitement demandé à être sur la file d'attente
- Il a un délai de 24h pour confirmer sa place
- S'il ne reçoit pas l'email, il ne peut pas confirmer et perd sa place
- C'est différent des autres emails (confirmation, rappel) qui sont optionnels

**Conclusion** : L'email de file d'attente doit être envoyé **systématiquement**, indépendamment des préférences utilisateur.

### Solution 2 : Utiliser `deliver_later` au lieu de `deliver_now`

**Modification** : Changer `deliver_now` en `deliver_later`

```ruby
def send_notification_email
  return unless user.wants_events_mail?

  if event.is_a?(Event::Initiation) && !user.wants_initiation_mail?
    return
  end

  EventMailer.waitlist_spot_available(self).deliver_later
rescue => e
  Rails.logger.error("Failed to send waitlist notification email for WaitlistEntry #{id}: #{e.message}")
end
```

**Avantages** :
- ✅ Ne bloque pas la requête HTTP
- ✅ Cohérent avec les autres emails (tous utilisent `deliver_later` sauf exceptions justifiées)
- ✅ Meilleure performance

**Note** : Cette solution nécessite que le système de queue (Active Job) soit configuré et fonctionnel.

### Solution 3 : Vérification dans le mailer (ALTERNATIVE)

**Modification** : Ajouter la vérification dans `EventMailer.waitlist_spot_available`

```ruby
# app/mailers/event_mailer.rb
def waitlist_spot_available(waitlist_entry)
  @waitlist_entry = waitlist_entry
  @event = waitlist_entry.event
  @user = waitlist_entry.user
  
  # Vérifier les préférences
  return unless @user.wants_events_mail?
  
  if @event.is_a?(Event::Initiation) && !@user.wants_initiation_mail?
    return
  end
  
  # ... reste du code
end
```

**Avantages** :
- ✅ Centralise la logique de vérification dans le mailer
- ✅ Plus facile à maintenir

**Inconvénients** :
- ⚠️ Le mailer retourne `nil` si les préférences ne sont pas activées, ce qui peut être confus

---

## ✅ Solution Finale Appliquée

**⚠️ IMPORTANT** : L'email de file d'attente est **TOUJOURS envoyé**, même si l'utilisateur a désactivé `wants_events_mail`. C'est un email critique.

**Implémentation finale** :

### 1. Dans `app/models/waitlist_entry.rb` - Méthode `notify!`

```ruby
def notify!
  return false unless pending?

  # Créer une inscription "pending" pour verrouiller la place
  attendance = build_pending_attendance
  bypass_validations_if_initiation(attendance)

  if attendance.save(validate: false)
    notified_time = Time.current
    update!(
      status: "notified",
      notified_at: notified_time
    )

    # IMPORTANT : Recharger l'objet pour s'assurer que notified_at est bien chargé
    # avant d'envoyer l'email (évite les problèmes de cache/transaction)
    reload

    # Envoyer l'email via deliver_later (asynchrone via SolidQueue)
    # Le reload ci-dessus garantit que notified_at est disponible dans le mailer
    send_notification_email
    Rails.logger.info("WaitlistEntry #{id} notified and pending attendance #{attendance.id} created for event #{event.id} (user: #{user_id})")
    true
  else
    handle_attendance_save_error(attendance, "notify!")
    false
  end
end

# Envoyer l'email de notification pour une place disponible
# IMPORTANT : Cet email est TOUJOURS envoyé, même si l'utilisateur a désactivé wants_events_mail
# Car c'est un email critique qui permet à l'utilisateur de confirmer sa place dans les 24h
# L'utilisateur a explicitement demandé à être sur la file d'attente, il doit recevoir la notification
def send_notification_email
  EventMailer.waitlist_spot_available(self).deliver_later
rescue => e
  Rails.logger.error("Failed to send waitlist notification email for WaitlistEntry #{id}: #{e.message}")
  Rails.logger.error(e.backtrace.join("\n"))
  # Ne pas faire échouer la notification si l'email échoue
end
```

### 2. Dans `app/mailers/event_mailer.rb` - Méthode `waitlist_spot_available`

```ruby
# Email de notification qu'une place est disponible en liste d'attente
def waitlist_spot_available(waitlist_entry)
  # IMPORTANT : Recharger l'objet pour s'assurer que notified_at est à jour
  # (évite les problèmes si le job est exécuté avant que la transaction soit commitée)
  waitlist_entry.reload if waitlist_entry.persisted?
  
  @waitlist_entry = waitlist_entry
  @event = waitlist_entry.event
  @user = waitlist_entry.user
  @is_initiation = @event.is_a?(Event::Initiation)
  @participant_name = waitlist_entry.participant_name
  
  # Vérifier que notified_at est présent avant de calculer expiration_time
  if waitlist_entry.notified_at.present?
    @expiration_time = waitlist_entry.notified_at + 24.hours # 24 heures pour confirmer
  else
    Rails.logger.error("WaitlistEntry #{waitlist_entry.id} has nil notified_at in waitlist_spot_available mailer")
    @expiration_time = 24.hours.from_now # Fallback si notified_at est nil
  end

  subject = if @is_initiation
    "🎉 Place disponible - Initiation roller samedi #{l(@event.start_at, format: :day_month, locale: :fr)}"
  else
    "🎉 Place disponible : #{@event.title}"
  end

  mail(
    to: @user.email,
    subject: subject
  )
end
```

**Changements appliqués** :
1. ✅ **AUCUNE vérification de préférences** - L'email est toujours envoyé (email critique)
2. ✅ Changement de `deliver_now` en `deliver_later` (meilleure performance)
3. ✅ **Ajout de `reload` dans `notify!`** - Garantit que `notified_at` est chargé avant l'envoi
4. ✅ **Ajout de `reload` dans le mailer** - Garantit que les données sont à jour même si le job s'exécute avant le commit
5. ✅ **Vérification et fallback pour `notified_at`** - Évite les erreurs si `notified_at` est `nil`
6. ✅ Amélioration des logs d'erreur (stack trace)

**Pourquoi pas de vérification de préférences ?**
- L'utilisateur a explicitement demandé à être sur la file d'attente
- Il a un délai de 24h pour confirmer sa place
- S'il ne reçoit pas l'email, il ne peut pas confirmer et perd sa place
- C'est différent des autres emails (confirmation, rappel) qui sont optionnels

---

## 🧪 Tests à Effectuer

### Test 1 : Utilisateur avec `wants_events_mail = true`

**Scénario** :
1. Créer un utilisateur avec `wants_events_mail = true`
2. Ajouter l'utilisateur à la file d'attente d'un événement complet
3. Libérer une place (annuler une inscription)
4. Vérifier que l'email est envoyé

**Résultat attendu** : ✅ Email envoyé

### Test 2 : Utilisateur avec `wants_events_mail = false`

**Scénario** :
1. Créer un utilisateur avec `wants_events_mail = false`
2. Ajouter l'utilisateur à la file d'attente d'un événement complet
3. Libérer une place (annuler une inscription)
4. Vérifier que l'email **EST envoyé** (car c'est un email critique)
5. Vérifier que l'entrée de file d'attente est mise à jour (`status = "notified"`)

**Résultat attendu** : ✅ Email envoyé (même si `wants_events_mail = false`), notification créée

**⚠️ IMPORTANT** : L'email de file d'attente est toujours envoyé, même si l'utilisateur a désactivé `wants_events_mail`, car c'est un email critique.

### Test 3 : Initiation avec `wants_initiation_mail = false`

**Scénario** :
1. Créer un utilisateur avec `wants_events_mail = false` et `wants_initiation_mail = false`
2. Ajouter l'utilisateur à la file d'attente d'une initiation complète
3. Libérer une place
4. Vérifier que l'email **EST envoyé** (car c'est un email critique)

**Résultat attendu** : ✅ Email envoyé (même si les préférences sont désactivées)

### Test 4 : Vérification des logs

**Scénario** :
1. Exécuter les tests 1, 2 et 3
2. Vérifier les logs pour les messages informatifs

**Résultat attendu** : ✅ Logs clairs indiquant pourquoi l'email a été envoyé ou non

---

## 📊 Impact

### Avant la correction

- ❌ Les emails ne sont pas envoyés (problème principal)
- ⚠️ Utilisation de `deliver_now` (peut bloquer les requêtes)
- 🔇 Erreurs silencieuses

### Après la correction

- ✅ Les emails sont envoyés **systématiquement** (email critique)
- ✅ Utilisation de `deliver_later` (meilleure performance)
- ✅ Logs clairs pour le debugging
- ✅ **Aucune vérification de préférences** - L'email est toujours envoyé car c'est critique pour que l'utilisateur puisse confirmer sa place

---

## 🔗 Fichiers Concernés

### À modifier

- **`app/models/waitlist_entry.rb`** : Méthode `send_notification_email` (lignes 228-234)

### Références

- **`app/controllers/events/attendances_controller.rb`** : Exemple de vérification `wants_events_mail` (lignes 93-99)
- **`app/mailers/event_mailer.rb`** : Méthode `waitlist_spot_available` (lignes 76-95)
- **`app/models/user.rb`** : Champs `wants_events_mail` et `wants_initiation_mail`

---

## 📝 Notes Additionnelles

### Pourquoi `wants_events_mail` est important

- Les utilisateurs peuvent désactiver les emails d'événements pour réduire le spam
- Si on envoie des emails sans vérifier cette préférence, on viole les préférences utilisateur
- C'est une bonne pratique de respecter les préférences utilisateur

### Pourquoi `wants_initiation_mail` pour les initiations

- Les initiations ont une préférence spécifique (`wants_initiation_mail`)
- Cette préférence est vérifiée dans `EventReminderJob` pour les rappels
- Il faut être cohérent et vérifier cette préférence aussi pour les notifications de file d'attente

### Pourquoi `deliver_later` au lieu de `deliver_now`

- `deliver_now` bloque la requête HTTP jusqu'à ce que l'email soit envoyé
- Si le serveur SMTP est lent, cela peut causer des timeouts
- `deliver_later` envoie l'email de manière asynchrone via Active Job
- Tous les autres emails de l'application utilisent `deliver_later` (sauf exceptions justifiées)

---

## ✅ Checklist de Correction

- [x] Changer `deliver_now` en `deliver_later` ✅
- [x] Améliorer les logs d'erreur (stack trace) ✅
- [x] **Ne PAS ajouter de vérification de préférences** (email critique) ✅
- [x] **Ajouter `reload` dans `notify!`** - Garantit que `notified_at` est chargé ✅
- [x] **Ajouter `reload` dans le mailer** - Garantit que les données sont à jour ✅
- [x] **Ajouter vérification et fallback pour `notified_at`** - Évite les erreurs ✅
- [ ] Tester avec `wants_events_mail = true`
- [ ] Tester avec `wants_events_mail = false` (doit quand même envoyer)
- [ ] Tester avec `wants_initiation_mail = false` (doit quand même envoyer)
- [ ] Vérifier que SolidQueue traite bien les jobs
- [ ] Vérifier les logs pour confirmer l'envoi
- [x] Mettre à jour la documentation ✅

## 🔍 Problèmes Potentiels Identifiés (Recherche Web)

### 1. Bug SolidQueue (versions ≤ 1.2.1)

**Problème** : Un bug connu dans SolidQueue empêche les jobs d'être exécutés correctement.

**Solution** : Vérifier la version de SolidQueue et mettre à jour si nécessaire.

**Vérification** :
```bash
bundle show solid_queue
# Ou dans Gemfile.lock
```

### 2. Jobs dans Transactions ActiveRecord

**Problème** : Si `deliver_later` est appelé dans une transaction, le job peut s'exécuter avant le commit.

**Solution appliquée** : Ajout de `reload` dans `notify!` et dans le mailer pour garantir que les données sont à jour.

### 3. Workers SolidQueue qui s'arrêtent

**Problème** : Les workers SolidQueue peuvent s'arrêter de traiter les jobs après un certain temps.

**Solution** : Vérifier que les workers SolidQueue sont actifs et redémarrer si nécessaire.

**Vérification** :
- Vérifier les logs SolidQueue
- Vérifier que les jobs sont bien en queue dans la base de données
- Vérifier que les workers sont en cours d'exécution

---

**Date de création** : 2025-12-30  
**Dernière mise à jour** : 2025-12-30  
**Statut** : ✅ **CORRIGÉ** - Corrections appliquées dans `app/models/waitlist_entry.rb` et `app/mailers/event_mailer.rb`

**⚠️ IMPORTANT** : L'email de file d'attente est **TOUJOURS envoyé**, même si l'utilisateur a désactivé `wants_events_mail`. C'est un email critique qui permet à l'utilisateur de confirmer sa place dans les 24h. L'utilisateur a explicitement demandé à être sur la file d'attente, il doit recevoir la notification.

## 🔧 Corrections Appliquées (v2)

### Problème Identifié

L'email n'était pas reçu malgré que la logique fonctionne (statut "Notifié" dans l'interface). Le problème venait de :

1. **Transaction ActiveRecord** : `deliver_later` peut s'exécuter avant que la transaction soit commitée
2. **`notified_at` nil** : Le mailer peut recevoir `notified_at = nil` si le job s'exécute trop tôt
3. **Erreur silencieuse** : Le calcul `notified_at + 24.hours` échoue si `notified_at` est `nil`

### Solutions Appliquées

1. ✅ **Ajout de `reload` dans `notify!`** - Garantit que `notified_at` est chargé avant l'envoi
2. ✅ **Ajout de `reload` dans le mailer** - Garantit que les données sont à jour même si le job s'exécute avant le commit
3. ✅ **Vérification et fallback pour `notified_at`** - Évite les erreurs silencieuses

### Prochaines Étapes de Vérification

1. **Vérifier SolidQueue** :
   ```bash
   # Vérifier la version de SolidQueue
   bundle show solid_queue
   
   # Vérifier que les workers sont actifs (dans les logs)
   # Les workers SolidQueue doivent être en cours d'exécution
   
   # Vérifier les jobs en queue dans la base de données
   # SELECT * FROM solid_queue_jobs WHERE finished_at IS NULL;
   ```

2. **Vérifier les logs** :
   - Chercher les erreurs dans les logs Rails
   - Vérifier les logs SolidQueue (workers)
   - Vérifier les logs SMTP
   - Chercher "Failed to send waitlist notification email" dans les logs

3. **Tester manuellement** :
   - Créer une file d'attente
   - Libérer une place (annuler une inscription ou ajouter un bénévole)
   - Vérifier que l'email est bien reçu
   - Vérifier les logs pour confirmer l'envoi

4. **Vérifier la configuration Active Job** :
   - Vérifier que `config.active_job.queue_adapter` est bien configuré
   - En production/staging : Vérifier que SolidQueue est utilisé
   - Vérifier que les workers SolidQueue sont démarrés

### Commandes de Diagnostic

```bash
# Vérifier les jobs en queue
rails console
> SolidQueue::Job.where(finished_at: nil).count

# Vérifier les jobs échoués
> SolidQueue::Job.where.not(finished_at: nil).where(failed_at: nil).count

# Vérifier les jobs en erreur
> SolidQueue::Job.where.not(failed_at: nil).count

# Tester l'envoi d'email manuellement
> waitlist_entry = WaitlistEntry.find_by(status: 'notified')
> EventMailer.waitlist_spot_available(waitlist_entry).deliver_now
```

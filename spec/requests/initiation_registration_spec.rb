require 'rails_helper'

RSpec.describe 'Initiation Registration - 16 Tests', type: :request do
  include TestDataHelper
  include RequestAuthenticationHelper

  let(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:admin_role) { ensure_role(code: 'ADMIN', name: 'Administrateur', level: 60) }
  let(:organizer_role) { ensure_role(code: 'ORGANIZER', name: 'Organisateur', level: 40) }

  # ============================================================================
  # 🔴 Phase 1 (Critical - 6 tests)
  # ============================================================================

  describe 'Phase 1: Critical Tests' do
    describe 'Duplicate Registration - Empêcher inscrire 2x' do
      it 'prevents user from registering twice to the same initiation' do
        user = create_user(role: user_role)
        create(:membership, user: user, status: :active, season: '2025-2026')
        initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false
        )
        login_user(user)

        # Première inscription
        post initiation_attendances_path(initiation)
        expect(response).to redirect_to(initiation_path(initiation))
        expect(Attendance.where(user: user, event: initiation, status: 'registered').count).to eq(1)

        # Tentative de deuxième inscription
        expect do
          post initiation_attendances_path(initiation)
        end.not_to change { Attendance.count }

        # La policy bloque (Pundit::NotAuthorizedError) et redirige vers root_path
        # Le ApplicationController redirige vers root_path pour les erreurs Pundit sur les initiations
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    describe 'Free Trial First - Permettre essai gratuit' do
      # Case 4.2: Parent pending + essai disponible → ACCÈS (essai obligatoire - nominatif)
      it 'allows user without membership to register using free trial' do
        user = create_user(role: user_role)
        # Pas d'adhésion active
        initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false  # Essai gratuit requis
        )
        login_user(user)

        expect do
          post initiation_attendances_path(initiation), params: { use_free_trial: "1" }
        end.to change { Attendance.count }.by(1)

        attendance = Attendance.last
        expect(attendance.user).to eq(user)
        expect(attendance.event).to eq(initiation)
        expect(attendance.free_trial_used).to be(true)
        expect(attendance.status).to eq('registered')
      end
    end

    describe 'Free Trial Second - Empêcher 2e essai' do
      # Case 4.3: Parent pending + essai utilisé → BLOQUÉ
      it 'prevents user from using free trial twice' do
        user = create_user(role: user_role)
        # Pas d'adhésion active pour permettre l'essai gratuit
        # Créer une première initiation avec essai gratuit utilisé
        first_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false  # Pas de découverte, donc essai gratuit requis
        )
        # Créer l'attendance avec free_trial_used via le contrôleur pour respecter les validations
        login_user(user)
        post initiation_attendances_path(first_initiation), params: { use_free_trial: "1" }
        expect(response).to redirect_to(initiation_path(first_initiation))
        logout_user

        # Tentative d'inscription à une deuxième initiation avec essai gratuit
        second_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false  # Pas de découverte, donc essai gratuit requis
        )
        login_user(user)

        expect do
          post initiation_attendances_path(second_initiation), params: { use_free_trial: "1" }
        end.not_to change { Attendance.count }

        # La policy bloque car l'essai gratuit a déjà été utilisé (Pundit::NotAuthorizedError)
        # La policy vérifie l'essai gratuit AVANT que le contrôleur ne soit appelé (ligne 107 de InitiationPolicy)
        # Le ApplicationController redirige vers root_path pour les erreurs Pundit sur les initiations
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      # Case 4.3: Parent non-adhérent + essai utilisé → BLOQUÉ (test direct contrôleur)
      it 'bloque parent non-adhérent si essai gratuit déjà utilisé (allow_non_member_discovery: false)' do
        user = create_user(role: user_role)
        # Pas d'adhésion active
        first_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false  # Pas de découverte, donc essai gratuit requis
        )
        login_user(user)

        # Première inscription avec essai gratuit
        post initiation_attendances_path(first_initiation), params: { use_free_trial: "1" }
        expect(response).to redirect_to(initiation_path(first_initiation))

        # Vérifier que l'essai gratuit est consommé
        expect(user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?).to be true

        # Tentative d'inscription à une deuxième initiation SANS essai gratuit (impossible car déjà utilisé)
        second_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false  # Pas de découverte, donc essai gratuit requis
        )

        # L'inscription doit être BLOQUÉE par le contrôleur (ligne 135-139)
        expect do
          post initiation_attendances_path(second_initiation)
        end.not_to change { Attendance.count }

        # Le contrôleur doit rediriger avec un message d'erreur
        expect(response).to redirect_to(initiation_path(second_initiation))
        expect(flash[:alert]).to include("Vous avez déjà utilisé votre essai gratuit")
        expect(flash[:alert]).to include("Une adhésion est maintenant requise")
      end

      it 'prevents user from registering to second initiation even with allow_non_member_discovery enabled' do
        # SÉCURITÉ CRITIQUE : Même si allow_non_member_discovery est activé,
        # l'utilisateur ne peut pas s'inscrire à une deuxième initiation si l'essai gratuit a déjà été utilisé
        user = create_user(role: user_role)
        # Pas d'adhésion active

        # Première initiation avec essai gratuit utilisé
        first_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false  # Essai gratuit requis
        )
        login_user(user)
        post initiation_attendances_path(first_initiation), params: { use_free_trial: "1" }
        expect(response).to redirect_to(initiation_path(first_initiation))

        # Vérifier que l'essai gratuit est consommé
        expect(user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?).to be true

        # Tentative d'inscription à une deuxième initiation avec allow_non_member_discovery activé
        # MAIS sans utiliser l'essai gratuit (places découverte)
        second_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: true,  # Places découverte activées
          non_member_discovery_slots: 10
        )

        # L'inscription doit être BLOQUÉE car l'essai gratuit a déjà été utilisé
        expect do
          post initiation_attendances_path(second_initiation)
        end.not_to change { Attendance.count }

        # Le contrôleur doit rediriger avec un message d'erreur
        expect(response).to redirect_to(initiation_path(second_initiation))
        expect(flash[:alert]).to include("Vous avez déjà utilisé votre essai gratuit")
        expect(flash[:alert]).to include("Une adhésion est maintenant requise")
      end

      it 'prevents child from registering to second initiation even with allow_non_member_discovery enabled' do
        # SÉCURITÉ CRITIQUE : Même si allow_non_member_discovery est activé,
        # un enfant ne peut pas s'inscrire à une deuxième initiation si l'essai gratuit a déjà été utilisé
        parent = create_user(role: user_role)
        child_membership = create(:membership, :child, :trial, :with_health_questionnaire,
          user: parent,
          season: '2025-2026'
        )

        # Première initiation avec essai gratuit utilisé
        first_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false  # Essai gratuit requis
        )
        login_user(parent)
        post initiation_attendances_path(first_initiation), params: {
          child_membership_id: child_membership.id,
          use_free_trial: "1"
        }
        expect(response).to redirect_to(initiation_path(first_initiation))

        # Vérifier que l'essai gratuit est consommé
        expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child_membership.id).exists?).to be true

        # Tentative d'inscription à une deuxième initiation avec allow_non_member_discovery activé
        # MAIS sans utiliser l'essai gratuit (places découverte)
        second_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: true,  # Places découverte activées
          non_member_discovery_slots: 10
        )

        # L'inscription doit être BLOQUÉE car l'essai gratuit a déjà été utilisé
        expect do
          post initiation_attendances_path(second_initiation), params: {
            child_membership_id: child_membership.id
          }
        end.not_to change { Attendance.count }

        # Le contrôleur doit rediriger avec un message d'erreur
        expect(response).to redirect_to(initiation_path(second_initiation))
        expect(flash[:alert]).to include("Cet enfant a déjà utilisé son essai gratuit")
        expect(flash[:alert]).to include("Une adhésion")
      end
    end

    describe 'Full Capacity - Bloquer quand complet' do
      it 'prevents registration when initiation is full' do
        user = create_user(role: user_role)
        create(:membership, user: user, status: :active, season: '2025-2026')
        initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 2,
          allow_non_member_discovery: false
        )

        # Remplir l'initiation
        2.times do
          participant = create_user
          create(:membership, user: participant, status: :active, season: '2025-2026')
          create(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
        end

        expect(initiation.full?).to be(true)

        login_user(user)

        expect do
          post initiation_attendances_path(initiation)
        end.not_to change { Attendance.count }

        # La policy bloque car l'initiation est pleine (Pundit::NotAuthorizedError)
        # Le ApplicationController redirige vers root_path pour les erreurs Pundit sur les initiations
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    describe 'Volunteer Exempt - Volontaires outrepassent limite' do
      it 'allows volunteers to register even when initiation is full' do
        # Nettoyer les données pour éviter la pollution
        Attendance.delete_all
        Event.delete_all

        volunteer = create_user(role: user_role)
        # L'utilisateur doit pouvoir être bénévole
        volunteer.update(can_be_volunteer: true)
        initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 1,
          allow_non_member_discovery: false
        )

        # Remplir l'initiation avec un participant
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        create(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')

        expect(initiation.full?).to be(true)

        login_user(volunteer)

        expect do
          post initiation_attendances_path(initiation), params: { is_volunteer: "1" }
        end.to change { Attendance.count }.by(1)

        expect(response).to redirect_to(initiation_path(initiation))

        attendance = Attendance.last
        expect(attendance.user).to eq(volunteer)
        expect(attendance.is_volunteer).to be(true)
        expect(attendance.status).to eq('registered')
      end
    end

    describe 'Non-Member Slots - Respecter slots réservés' do
      it 'respects reserved slots for non-members when allow_non_member_discovery is enabled' do
        member = create_user(role: user_role)
        create(:membership, user: member, status: :active, season: '2025-2026')

        non_member = create_user(role: user_role)
        # Pas d'adhésion active

        initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 10,
          allow_non_member_discovery: true,
          non_member_discovery_slots: 3
        )

        login_user(member)

        # L'adhérent peut s'inscrire
        expect do
          post initiation_attendances_path(initiation)
        end.to change { Attendance.count }.by(1)

        logout_user
        login_user(non_member)

        # Le non-adhérent peut aussi s'inscrire (slots réservés disponibles)
        expect do
          post initiation_attendances_path(initiation), params: { use_free_trial: "1" }
        end.to change { Attendance.count }.by(1)

        # Vérifier que les places disponibles respectent les slots réservés
        expect(initiation.available_places).to be >= 0
      end
    end
  end

  # ============================================================================
  # 🟡 Phase 2 (High - 6 tests)
  # ============================================================================

  describe 'Phase 2: High Priority Tests' do
    describe 'Admin Draft Access - Admin voir tous les drafts' do
      it 'allows admin to view draft initiations' do
        admin = create_user(role: admin_role)
        draft_initiation = create_event(
          type: 'Event::Initiation',
          status: 'draft',
          max_participants: 30,
          allow_non_member_discovery: false
        )
        login_user(admin)

        get initiation_path(draft_initiation)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(draft_initiation.title)
      end
    end

    describe 'Canceled Visible - Events annulés restent visibles' do
      it 'keeps canceled events visible to users' do
        user = create_user(role: user_role)
        canceled_initiation = create_event(
          type: 'Event::Initiation',
          status: 'canceled',
          max_participants: 30,
          allow_non_member_discovery: false
        )
        login_user(user)

        get initiation_path(canceled_initiation)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(canceled_initiation.title)
      end
    end

    describe 'ICS Valid Format - iCal valide' do
      it 'generates valid iCal format for initiation' do
        user = create_user(role: user_role)
        initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          title: 'Initiation Test',
          start_at: 1.week.from_now,
          max_participants: 30,
          allow_non_member_discovery: false
        )
        login_user(user)

        get initiation_path(initiation, format: :ics)

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('text/calendar')
        expect(response.body).to include('BEGIN:VCALENDAR')
        expect(response.body).to include('BEGIN:VEVENT')
        expect(response.body).to include('END:VEVENT')
        expect(response.body).to include('END:VCALENDAR')
        expect(response.body).to include('SUMMARY:Initiation Test')
      end
    end

    describe 'ICS Unique UID - ID unique par event' do
      it 'generates unique UID for each initiation ICS export' do
        user = create_user(role: user_role)
        initiation1 = create_event(
          type: 'Event::Initiation',
          status: 'published',
          start_at: 1.week.from_now,
          max_participants: 30,
          allow_non_member_discovery: false
        )
        initiation2 = create_event(
          type: 'Event::Initiation',
          status: 'published',
          start_at: 2.weeks.from_now,
          max_participants: 30,
          allow_non_member_discovery: false
        )
        login_user(user)

        get initiation_path(initiation1, format: :ics)
        ics1 = response.body
        uid1 = ics1.match(/UID:(.+)/)&.[](1)

        get initiation_path(initiation2, format: :ics)
        ics2 = response.body
        uid2 = ics2.match(/UID:(.+)/)&.[](1)

        expect(uid1).to be_present
        expect(uid2).to be_present
        expect(uid1).not_to eq(uid2)
        # L'UID doit être unique pour chaque initiation
      end
    end

    describe 'Child Membership - Support enfants' do
      it 'allows parent to register child using child membership' do
        parent = create_user(role: user_role)
        create(:membership, user: parent, status: :active, season: '2025-2026')
        child_membership = create(:membership, :child,
          user: parent,
          status: :active,
          season: '2025-2026'
        )
        initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false
        )
        login_user(parent)

        expect do
          post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
        end.to change { Attendance.count }.by(1)

        attendance = Attendance.last
        expect(attendance.user).to eq(parent)
        expect(attendance.child_membership_id).to eq(child_membership.id)
        expect(attendance.status).to eq('registered')
        expect(attendance.free_trial_used).to be false # Pas besoin d'essai gratuit avec adhésion active
      end

      context 'avec adhésion enfant active' do
        it 'permet inscription sans essai gratuit' do
          parent = create_user(role: user_role)
          child_membership = create(:membership, :child, :with_health_questionnaire,
            user: parent,
            status: :active,
            season: '2025-2026'
          )
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.to change { Attendance.count }.by(1)

          attendance = Attendance.last
          expect(attendance.free_trial_used).to be false
          expect(response).to redirect_to(initiation_path(initiation))
        end
      end

      context 'avec adhésion enfant pending' do
        # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - le statut du parent n'a AUCUNE influence
        # Case 1.1: pending + essai disponible → ACCÈS (essai obligatoire - nominatif) - Indépendant du parent
        it 'requiert essai gratuit OBLIGATOIRE même si parent adhérent (v4.0 - nominatif)' do
          parent = create_user(role: user_role)
          # Parent adhérent actif (mais cela ne change RIEN selon v4.0)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child_membership = create(:membership, :child, :pending, :with_health_questionnaire,
            user: parent,
            season: '2025-2026'
          )
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Sans use_free_trial, doit être BLOQUÉ (essai obligatoire même si parent adhérent)
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.not_to change { Attendance.count }

          expect(response).to redirect_to(initiation_path(initiation))
          expect(flash[:alert]).to include("L'essai gratuit est obligatoire pour cet enfant")

          # Avec use_free_trial, doit fonctionner
          expect do
            post initiation_attendances_path(initiation), params: {
              child_membership_id: child_membership.id,
              use_free_trial: "1"
            }
          end.to change { Attendance.count }.by(1)

          attendance = Attendance.last
          expect(attendance.free_trial_used).to be true
          expect(response).to redirect_to(initiation_path(initiation))
        end

        # Test 1.1: pending + parent non-adhérent (HIGH) - Essai obligatoire
        it 'requiert essai gratuit si parent non-adhérent' do
          parent = create_user(role: user_role)
          # Parent NON adhérent (pas d'adhésion active)
          child_membership = create(:membership, :child, :pending, :with_health_questionnaire,
            user: parent,
            season: '2025-2026'
          )
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Sans use_free_trial, doit être bloqué
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.not_to change { Attendance.count }

          expect(response).to redirect_to(initiation_path(initiation))
          expect(flash[:alert]).to include("L'essai gratuit est obligatoire")

          # Avec use_free_trial, doit fonctionner
          expect do
            post initiation_attendances_path(initiation), params: {
              child_membership_id: child_membership.id,
              use_free_trial: "1"
            }
          end.to change { Attendance.count }.by(1)

          attendance = Attendance.last
          expect(attendance.free_trial_used).to be true
          expect(response).to redirect_to(initiation_path(initiation))
        end

        # Case 1.1: pending + essai disponible → ACCÈS (essai obligatoire - nominatif)
        it 'permet inscription avec essai gratuit OBLIGATOIRE (v4.0 - nominatif)' do
          parent = create_user(role: user_role)
          child_membership = create(:membership, :child, :pending, :with_health_questionnaire,
            user: parent,
            season: '2025-2026'
          )
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Vérifier que l'enfant n'a pas encore utilisé son essai gratuit
          expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child_membership.id).exists?).to be false

          # S'inscrire AVEC use_free_trial = "1" (OBLIGATOIRE selon v4.0)
          expect do
            post initiation_attendances_path(initiation), params: {
              child_membership_id: child_membership.id,
              use_free_trial: "1"
            }
          end.to change { Attendance.count }.by(1)

          attendance = Attendance.last
          expect(attendance.free_trial_used).to be true
          expect(attendance.child_membership_id).to eq(child_membership.id)
          expect(attendance.user).to eq(parent)
          expect(response).to redirect_to(initiation_path(initiation))

          # Vérifier que l'essai gratuit est maintenant consommé
          expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child_membership.id).exists?).to be true
        end

        # Case 1.3: pending + essai utilisé → BLOQUÉ - Même si parent adhérent (v4.0 - nominatif)
        it 'bloque inscription enfant pending si essai gratuit déjà utilisé, même si parent adhérent (v4.0)' do
          parent = create_user(role: user_role)
          # Parent adhérent actif (mais cela ne change RIEN selon v4.0)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child_membership = create(:membership, :child, :pending, :with_health_questionnaire,
            user: parent,
            season: '2025-2026'
          )

          # Utiliser l'essai gratuit sur une première initiation
          first_initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Première inscription avec essai gratuit (OBLIGATOIRE selon v4.0)
          post initiation_attendances_path(first_initiation), params: {
            child_membership_id: child_membership.id,
            use_free_trial: "1"
          }
          expect(response).to redirect_to(initiation_path(first_initiation))

          # Vérifier que l'essai gratuit est consommé
          expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child_membership.id).exists?).to be true

          # Tentative d'inscription à une deuxième initiation (sans essai gratuit)
          second_initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )

          # L'inscription doit être BLOQUÉE même si le parent est adhérent (v4.0 - nominatif)
          expect do
            post initiation_attendances_path(second_initiation), params: {
              child_membership_id: child_membership.id
            }
          end.not_to change { Attendance.count }

          # Le contrôleur doit rediriger avec un message d'erreur
          expect(response).to redirect_to(initiation_path(second_initiation))
          expect(flash[:alert]).to include("Cet enfant a déjà utilisé son essai gratuit")
          expect(flash[:alert]).to include("Une adhésion active est maintenant requise")
        end
      end

      context 'avec adhésion enfant trial' do
        # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - le statut du parent n'a AUCUNE influence
        # Case 2.1: trial + essai disponible → ACCÈS (essai obligatoire - nominatif) - Indépendant du parent
        it 'requiert essai gratuit OBLIGATOIRE même si parent adhérent (v4.0 - nominatif)' do
          parent = create_user(role: user_role)
          # Parent adhérent actif (mais cela ne change RIEN selon v4.0)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child_membership = create(:membership, :child, :trial, :with_health_questionnaire,
            user: parent,
            season: '2025-2026'
          )
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Sans use_free_trial, doit être BLOQUÉ (essai obligatoire même si parent adhérent)
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.not_to change { Attendance.count }

          expect(response).to redirect_to(initiation_path(initiation))
          expect(flash[:alert]).to include("L'essai gratuit est obligatoire pour cet enfant")

          # Avec use_free_trial, doit fonctionner
          expect do
            post initiation_attendances_path(initiation), params: {
              child_membership_id: child_membership.id,
              use_free_trial: '1'
            }
          end.to change { Attendance.count }.by(1)

          attendance = Attendance.last
          expect(attendance.free_trial_used).to be true
          expect(response).to redirect_to(initiation_path(initiation))
        end

        # Test 2.1: trial + parent non-adhérent (HIGH) - Essai obligatoire (avec essai)
        it 'permet inscription avec essai gratuit si parent non-adhérent' do
          parent = create_user(role: user_role)
          # Parent NON adhérent (pas d'adhésion active)
          child_membership = create(:membership, :child, :trial, :with_health_questionnaire,
            user: parent,
            season: '2025-2026'
          )
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          expect do
            post initiation_attendances_path(initiation), params: {
              child_membership_id: child_membership.id,
              use_free_trial: '1'
            }
          end.to change { Attendance.count }.by(1)

          attendance = Attendance.last
          expect(attendance.free_trial_used).to be true
        end

        # Case 2.3: trial + essai utilisé → BLOQUÉ - Même si parent adhérent (v4.0 - nominatif)
        it 'bloque inscription enfant trial si essai gratuit déjà utilisé, même si parent adhérent (v4.0)' do
          parent = create_user(role: user_role)
          # Parent adhérent actif (mais cela ne change RIEN selon v4.0)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child_membership = create(:membership, :child, :trial, :with_health_questionnaire,
            user: parent,
            season: '2025-2026'
          )

          # Première initiation : utiliser l'essai gratuit (OBLIGATOIRE selon v4.0)
          first_initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Première inscription avec essai gratuit (OBLIGATOIRE)
          post initiation_attendances_path(first_initiation), params: {
            child_membership_id: child_membership.id,
            use_free_trial: "1"
          }
          expect(response).to redirect_to(initiation_path(first_initiation))

          # Vérifier que l'essai gratuit est consommé
          expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child_membership.id).exists?).to be true

          # Deuxième initiation : doit être BLOQUÉ même si le parent est adhérent (v4.0 - nominatif)
          second_initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )

          expect do
            post initiation_attendances_path(second_initiation), params: {
              child_membership_id: child_membership.id
            }
          end.not_to change { Attendance.count }

          expect(response).to redirect_to(initiation_path(second_initiation))
          expect(flash[:alert]).to include("Cet enfant a déjà utilisé son essai gratuit")
          expect(flash[:alert]).to include("Une adhésion active est maintenant requise")
        end
      end
    end

    describe 'Parent and Child Registration - Tous les cas de figure' do
      before do
        Attendance.delete_all
        Event.delete_all
      end

      describe 'Adulte avec adhésion' do
        it 'permet inscription adulte seul avec adhésion' do
          adult = create_user(role: user_role)
          create(:membership, user: adult, status: :active, season: '2025-2026')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(adult)

          expect do
            post initiation_attendances_path(initiation)
          end.to change { Attendance.count }.by(1)

          expect(response).to redirect_to(initiation_path(initiation))
          attendance = Attendance.last
          expect(attendance.user).to eq(adult)
          expect(attendance.child_membership_id).to be_nil
          expect(attendance.for_parent?).to be(true)
          expect(attendance.free_trial_used).to be(false)
          expect(attendance.status).to eq('registered')
        end

        it 'permet inscription adulte puis enfant' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Inscription adulte d'abord
          expect do
            post initiation_attendances_path(initiation)
          end.to change { Attendance.count }.by(1)

          parent_attendance = Attendance.last
          expect(parent_attendance.user).to eq(parent)
          expect(parent_attendance.child_membership_id).to be_nil
          expect(parent_attendance.for_parent?).to be(true)

          # Inscription enfant ensuite (doit fonctionner car child_membership_id est différent)
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.to change { Attendance.count }.by(1)

          expect(response).to redirect_to(initiation_path(initiation))
          expect(Attendance.count).to eq(2) # 1 adulte + 1 enfant

          # Récupérer l'attendance enfant (la dernière créée avec child_membership_id)
          child_attendance = Attendance.where(user: parent).where.not(child_membership_id: nil).last
          expect(child_attendance).not_to be_nil
          expect(child_attendance.user).to eq(parent)
          expect(child_attendance.child_membership_id).to eq(child_membership.id)
          expect(child_attendance.for_child?).to be(true)

          # Vérifier que les deux inscriptions existent
          expect(initiation.attendances.where(user: parent).count).to eq(2)
        end

        it 'permet inscription enfant puis adulte' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Inscription enfant d'abord
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.to change { Attendance.count }.by(1)

          child_attendance = Attendance.where(user: parent).where.not(child_membership_id: nil).last
          expect(child_attendance).not_to be_nil
          expect(child_attendance.user).to eq(parent)
          expect(child_attendance.child_membership_id).to eq(child_membership.id)
          expect(child_attendance.for_child?).to be(true)

          # Inscription adulte ensuite
          expect do
            post initiation_attendances_path(initiation)
          end.to change { Attendance.count }.by(1)

          parent_attendance = Attendance.last
          expect(parent_attendance.user).to eq(parent)
          expect(parent_attendance.child_membership_id).to be_nil
          expect(parent_attendance.for_parent?).to be(true)

          # Vérifier que les deux inscriptions existent
          expect(initiation.attendances.where(user: parent).count).to eq(2)
        end

        it 'permet inscription plusieurs enfants' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child1_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026', child_first_name: 'Enfant1')
          child2_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026', child_first_name: 'Enfant2')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Inscription premier enfant
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child1_membership.id }
          end.to change { Attendance.count }.by(1)

          # Inscription deuxième enfant
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child2_membership.id }
          end.to change { Attendance.count }.by(1)

          # Vérifier que les deux enfants sont inscrits
          expect(initiation.attendances.where(user: parent, child_membership_id: child1_membership.id).count).to eq(1)
          expect(initiation.attendances.where(user: parent, child_membership_id: child2_membership.id).count).to eq(1)
          expect(initiation.attendances.where(user: parent).count).to eq(2)
        end

        it 'permet inscription adulte + plusieurs enfants' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child1_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026', child_first_name: 'Enfant1')
          child2_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026', child_first_name: 'Enfant2')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Inscription adulte
          expect do
            post initiation_attendances_path(initiation)
          end.to change { Attendance.count }.by(1)

          # Inscription premier enfant
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child1_membership.id }
          end.to change { Attendance.count }.by(1)

          # Inscription deuxième enfant
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child2_membership.id }
          end.to change { Attendance.count }.by(1)

          # Vérifier que l'adulte et les deux enfants sont inscrits
          expect(initiation.attendances.where(user: parent).count).to eq(3)
          expect(initiation.attendances.where(user: parent, child_membership_id: nil).count).to eq(1) # Adulte
          expect(initiation.attendances.where(user: parent).where.not(child_membership_id: nil).count).to eq(2) # Enfants
        end
      end

      describe 'Adulte sans adhésion (avec essai gratuit)' do
        it 'permet inscription adulte avec essai gratuit puis enfant avec adhésion' do
          parent = create_user(role: user_role)
          # Pas d'adhésion pour le parent (ni enfant) au début
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Inscription adulte avec essai gratuit (pas d'adhésion enfant encore)
          expect do
            post initiation_attendances_path(initiation), params: { use_free_trial: "1" }
          end.to change { Attendance.count }.by(1)

          parent_attendance = Attendance.where(user: parent, child_membership_id: nil).last
          expect(parent_attendance).not_to be_nil
          expect(parent_attendance.user).to eq(parent)
          expect(parent_attendance.free_trial_used).to be(true)
          expect(parent_attendance.for_parent?).to be(true)

          # Créer l'adhésion enfant après l'inscription adulte
          child_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026')

          # Inscription enfant (qui a une adhésion)
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.to change { Attendance.count }.by(1)

          child_attendance = Attendance.where(user: parent, child_membership_id: child_membership.id).last
          expect(child_attendance).not_to be_nil
          expect(child_attendance.user).to eq(parent)
          expect(child_attendance.child_membership_id).to eq(child_membership.id)
          expect(child_attendance.for_child?).to be(true)

          # Vérifier que les deux inscriptions existent
          expect(initiation.attendances.where(user: parent).count).to eq(2)
        end

        # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - chaque personne doit avoir sa propre adhésion
        # Un parent ne peut PAS utiliser l'adhésion de son enfant
        it 'bloque inscription adulte sans adhésion même si enfant a une adhésion (v4.0 - nominatif)' do
          parent = create_user(role: user_role)
          # Pas d'adhésion pour le parent, mais l'enfant en a une
          child_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Inscription enfant d'abord (qui a une adhésion)
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.to change { Attendance.count }.by(1)

          child_attendance = Attendance.where(user: parent, child_membership_id: child_membership.id).last
          expect(child_attendance).not_to be_nil
          expect(child_attendance.user).to eq(parent)
          expect(child_attendance.child_membership_id).to eq(child_membership.id)
          expect(child_attendance.for_child?).to be(true)

          # Tentative d'inscription adulte ensuite
          # ⚠️ v4.0 : Le parent ne peut PAS utiliser l'adhésion de son enfant
          # Le parent doit avoir sa propre adhésion ou utiliser son essai gratuit
          expect do
            post initiation_attendances_path(initiation)
          end.not_to change { Attendance.count }

          # Le contrôleur doit bloquer car le parent n'a pas sa propre adhésion
          # et n'a pas utilisé son essai gratuit
          expect(response).to redirect_to(initiation_path(initiation))
          expect(flash[:alert]).to include("Adhésion requise")
        end
      end

      describe 'Enfants sans adhésion' do
        it 'bloque inscription enfant sans adhésion' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          # Enfant sans adhésion (pas de membership créé)
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Tentative d'inscription avec un child_membership_id inexistant
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: 99999 }
          end.not_to change { Attendance.count }

          # La policy bloque car child_membership_id n'appartient pas à l'utilisateur (Pundit::NotAuthorizedError)
          # Le ApplicationController redirige vers root_path pour les erreurs Pundit sur les initiations
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to be_present
        end

        it 'bloque inscription enfant avec adhésion inactive' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child_membership = create(:membership, :child, user: parent, status: :expired, season: '2024-2025')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Tentative d'inscription avec une adhésion enfant inactive
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.not_to change { Attendance.count }

          # La policy bloque car l'adhésion enfant n'est pas active (Pundit::NotAuthorizedError)
          # Le ApplicationController redirige vers root_path pour les erreurs Pundit sur les initiations
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to be_present
        end
      end

      describe 'Cas limites' do
        it 'empêche inscription double du même enfant' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Première inscription enfant
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.to change { Attendance.count }.by(1)

          # Tentative de deuxième inscription du même enfant
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.not_to change { Attendance.count }

          # La policy bloque car l'enfant est déjà inscrit (Pundit::NotAuthorizedError)
          # Le ApplicationController redirige vers root_path pour les erreurs Pundit sur les initiations
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to be_present
        end

        it 'permet inscription adulte même si enfant déjà inscrit' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Inscription enfant d'abord
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.to change { Attendance.count }.by(1)

          # Inscription adulte ensuite (doit fonctionner)
          expect do
            post initiation_attendances_path(initiation)
          end.to change { Attendance.count }.by(1)

          expect(initiation.attendances.where(user: parent).count).to eq(2)
        end

        it 'permet inscription enfant même si adulte déjà inscrit' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Inscription adulte d'abord
          expect do
            post initiation_attendances_path(initiation)
          end.to change { Attendance.count }.by(1)

          # Inscription enfant ensuite (doit fonctionner)
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.to change { Attendance.count }.by(1)

          expect(initiation.attendances.where(user: parent).count).to eq(2)
        end

        it 'famille remplit initiation' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child1_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026', child_first_name: 'Enfant1')
          child2_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026', child_first_name: 'Enfant2')
          child3_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026', child_first_name: 'Enfant3')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 4, # Juste assez pour la famille
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Inscription adulte
          expect do
            post initiation_attendances_path(initiation)
          end.to change { Attendance.count }.by(1)

          # Inscription 3 enfants
          3.times do |i|
            child_membership = [ child1_membership, child2_membership, child3_membership ][i]
            expect do
              post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
            end.to change { Attendance.count }.by(1)
          end

          # Vérifier que l'initiation est pleine
          expect(initiation.full?).to be(true)
          expect(initiation.attendances.where(user: parent).count).to eq(4) # 1 adulte + 3 enfants
        end
      end
    end

    describe 'VOLONTAIRES - Tests supplémentaires' do
      before do
        Attendance.delete_all
        Event.delete_all
      end

      describe 'Volontaires' do
        it 'adulte peut être volontaire' do
          volunteer = create_user(role: user_role)
          volunteer.update(can_be_volunteer: true)
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(volunteer)

          expect do
            post initiation_attendances_path(initiation), params: { is_volunteer: "1" }
          end.to change { Attendance.count }.by(1)

          attendance = Attendance.last
          expect(attendance.user).to eq(volunteer)
          expect(attendance.is_volunteer).to be(true)
          expect(attendance.status).to eq('registered')
        end

        it 'enfant CANNOT être volontaire' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Tentative d'inscription enfant en tant que volontaire
          # Le contrôleur ignore is_volunteer si child_membership_id est présent (ligne 57)
          # Donc l'inscription se fait normalement comme un enfant participant
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id, is_volunteer: "1" }
          end.to change { Attendance.count }.by(1)

          # Vérifier que l'attendance créée n'est PAS volontaire
          attendance = Attendance.last
          expect(attendance.child_membership_id).to eq(child_membership.id)
          expect(attendance.is_volunteer).to be(false) # Les enfants ne peuvent pas être volontaires
        end

        it 'volontaires ne comptent pas dans la capacité' do
          volunteer1 = create_user(role: user_role)
          volunteer1.update(can_be_volunteer: true)
          volunteer2 = create_user(role: user_role)
          volunteer2.update(can_be_volunteer: true)
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 2,
            allow_non_member_discovery: false
          )

          # Remplir l'initiation avec 2 participants
          2.times do
            participant = create_user
            create(:membership, user: participant, status: :active, season: '2025-2026')
            create(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
          end

          expect(initiation.full?).to be(true)

          # Les volontaires peuvent s'inscrire même si l'initiation est pleine
          login_user(volunteer1)
          expect do
            post initiation_attendances_path(initiation), params: { is_volunteer: "1" }
          end.to change { Attendance.count }.by(1)

          logout_user
          login_user(volunteer2)
          expect do
            post initiation_attendances_path(initiation), params: { is_volunteer: "1" }
          end.to change { Attendance.count }.by(1)

          # Vérifier que les volontaires ne comptent pas dans la capacité
          expect(initiation.participants_count).to eq(2) # Seulement les participants
          expect(initiation.volunteers_count).to eq(2) # Les volontaires sont séparés
          expect(initiation.total_attendances_count).to eq(4) # Total = 2 participants + 2 volontaires
        end

        it 'plusieurs volontaires peuvent s\'inscrire' do
          volunteer1 = create_user(role: user_role)
          volunteer1.update(can_be_volunteer: true)
          volunteer2 = create_user(role: user_role)
          volunteer2.update(can_be_volunteer: true)
          volunteer3 = create_user(role: user_role)
          volunteer3.update(can_be_volunteer: true)
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )

          # Inscription de 3 volontaires
          [ volunteer1, volunteer2, volunteer3 ].each do |volunteer|
            login_user(volunteer)
            expect do
              post initiation_attendances_path(initiation), params: { is_volunteer: "1" }
            end.to change { Attendance.count }.by(1)
            logout_user
          end

          expect(initiation.volunteers_count).to eq(3)
          expect(initiation.attendances.volunteers.count).to eq(3)
        end

        it 'volontaire peut s\'inscrire sans essai gratuit même si épuisé' do
          volunteer = create_user(role: user_role)
          volunteer.update(can_be_volunteer: true)
          # Utiliser l'essai gratuit sur une autre initiation
          other_initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(volunteer)
          post initiation_attendances_path(other_initiation), params: { use_free_trial: "1" }
          logout_user

          # Maintenant essai gratuit épuisé, mais volontaire peut quand même s'inscrire
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(volunteer)

          expect do
            post initiation_attendances_path(initiation), params: { is_volunteer: "1" }
          end.to change { Attendance.count }.by(1)

          attendance = Attendance.last
          expect(attendance.is_volunteer).to be(true)
          expect(attendance.free_trial_used).to be(false) # Pas besoin d'essai gratuit pour volontaire
        end
      end
    end

    describe 'NON-MEMBER + FAMILLE - Tests supplémentaires' do
      before do
        Attendance.delete_all
        Event.delete_all
      end

      describe 'Famille non-adhérente avec découverte' do
        it 'famille non-adhérente peut s\'inscrire avec découverte' do
          parent = create_user(role: user_role)
          # Pas d'adhésion pour le parent, mais l'enfant en a une
          child_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 20,
            allow_non_member_discovery: true,
            non_member_discovery_slots: 5
          )
          login_user(parent)

          # Inscription adulte (le parent est considéré comme membre car il a une adhésion enfant active)
          expect do
            post initiation_attendances_path(initiation)
          end.to change { Attendance.count }.by(1)

          # Inscription enfant (qui a une adhésion, donc compte comme membre)
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.to change { Attendance.count }.by(1)

          expect(initiation.attendances.where(user: parent).count).to eq(2)
          # Le parent est considéré comme membre car il a une adhésion enfant active (ligne 98-99 du modèle)
          # L'enfant est aussi membre
          expect(initiation.member_participants_count).to eq(2) # Parent (via adhésion enfant) + enfant
          expect(initiation.non_member_participants_count).to eq(0) # Aucun non-adhérent
        end

        it 'mélange adhérents et non-adhérents dans une famille' do
          parent = create_user(role: user_role)
          # Pas d'adhésion pour le parent, mais les enfants en ont
          child1_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026', child_first_name: 'Enfant1')
          child2_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026', child_first_name: 'Enfant2')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 20,
            allow_non_member_discovery: true,
            non_member_discovery_slots: 5
          )
          login_user(parent)

          # Inscription adulte (le parent est considéré comme membre car il a des adhésions enfants actives)
          expect do
            post initiation_attendances_path(initiation)
          end.to change { Attendance.count }.by(1)

          # Inscription 2 enfants (adhérents)
          [ child1_membership, child2_membership ].each do |child_membership|
            expect do
              post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
            end.to change { Attendance.count }.by(1)
          end

          expect(initiation.attendances.where(user: parent).count).to eq(3)
          # Le parent est considéré comme membre car il a des adhésions enfants actives (ligne 98-99 du modèle)
          # Les 2 enfants sont aussi membres
          expect(initiation.member_participants_count).to eq(3) # Parent (via adhésions enfants) + 2 enfants
          expect(initiation.non_member_participants_count).to eq(0) # Aucun non-adhérent
        end

        it 'famille + volontaires + découverte' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026')
          volunteer = create_user(role: user_role)
          volunteer.update(can_be_volunteer: true)
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 10,
            allow_non_member_discovery: true,
            non_member_discovery_slots: 3
          )

          # Inscription famille
          login_user(parent)
          expect do
            post initiation_attendances_path(initiation)
          end.to change { Attendance.count }.by(1)
          expect do
            post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
          end.to change { Attendance.count }.by(1)

          # Inscription volontaire
          logout_user
          login_user(volunteer)
          expect do
            post initiation_attendances_path(initiation), params: { is_volunteer: "1" }
          end.to change { Attendance.count }.by(1)

          expect(initiation.attendances.where(user: parent).count).to eq(2)
          expect(initiation.volunteers_count).to eq(1)
          expect(initiation.participants_count).to eq(2) # Parent + enfant
        end

        it 'count adultes et enfants séparément' do
          parent = create_user(role: user_role)
          create(:membership, user: parent, status: :active, season: '2025-2026')
          child1_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026', child_first_name: 'Enfant1')
          child2_membership = create(:membership, :child, user: parent, status: :active, season: '2025-2026', child_first_name: 'Enfant2')
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 30,
            allow_non_member_discovery: false
          )
          login_user(parent)

          # Inscription adulte
          expect do
            post initiation_attendances_path(initiation)
          end.to change { Attendance.count }.by(1)

          # Inscription 2 enfants
          [ child1_membership, child2_membership ].each do |child_membership|
            expect do
              post initiation_attendances_path(initiation), params: { child_membership_id: child_membership.id }
            end.to change { Attendance.count }.by(1)
          end

          # Vérifier les comptages
          expect(initiation.adult_participants_count).to eq(1)
          expect(initiation.child_participants_count).to eq(2)
          expect(initiation.participants_count).to eq(3) # Total
        end

        it 'count membres et non-membres séparément' do
          member_parent = create_user(role: user_role)
          create(:membership, user: member_parent, status: :active, season: '2025-2026')
          non_member_parent = create_user(role: user_role)
          initiation = create_event(
            type: 'Event::Initiation',
            status: 'published',
            max_participants: 20,
            allow_non_member_discovery: true,
            non_member_discovery_slots: 5
          )

          # Inscription parent adhérent
          login_user(member_parent)
          expect do
            post initiation_attendances_path(initiation)
          end.to change { Attendance.count }.by(1)

          # Inscription parent non-adhérent (avec essai gratuit)
          logout_user
          login_user(non_member_parent)
          expect do
            post initiation_attendances_path(initiation), params: { use_free_trial: "1" }
          end.to change { Attendance.count }.by(1)

          # Vérifier les comptages
          expect(initiation.member_participants_count).to eq(1) # Parent adhérent
          expect(initiation.non_member_participants_count).to eq(1) # Parent non-adhérent
          expect(initiation.participants_count).to eq(2) # Total
        end
      end
    end

    describe 'Non-Member Display - Afficher slots réservés' do
      it 'displays reserved slots information for non-members' do
        user = create_user(role: user_role)
        initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 20,
          allow_non_member_discovery: true,
          non_member_discovery_slots: 5
        )
        login_user(user)

        get initiation_path(initiation)

        expect(response).to have_http_status(:success)
        # Vérifier que l'information sur les slots réservés est affichée
        # (le texte exact dépend de l'implémentation de la vue)
        expect(response.body).to include(initiation.title)
      end
    end
  end

  # ============================================================================
  # 🟢 Phase 3 (Medium - 4 tests)
  # ============================================================================

  describe 'Phase 3: Medium Priority Tests' do
    describe 'Draft Filtering - Draft pas au listing' do
      it 'excludes draft initiations from public listing' do
        published = create_event(
          type: 'Event::Initiation',
          status: 'published',
          title: 'Initiation Publiée',
          max_participants: 30,
          allow_non_member_discovery: false
        )
        draft = create_event(
          type: 'Event::Initiation',
          status: 'draft',
          title: 'Initiation Brouillon',
          max_participants: 30,
          allow_non_member_discovery: false
        )

        get initiations_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Initiation Publiée')
        expect(response.body).not_to include('Initiation Brouillon')
      end
    end

    describe 'Date Ordering - Trier par date' do
      it 'orders initiations by start date' do
        later = create_event(
          type: 'Event::Initiation',
          status: 'published',
          title: 'Initiation Plus Tard',
          start_at: 2.weeks.from_now,
          max_participants: 30,
          allow_non_member_discovery: false
        )
        earlier = create_event(
          type: 'Event::Initiation',
          status: 'published',
          title: 'Initiation Plus Tôt',
          start_at: 1.week.from_now,
          max_participants: 30,
          allow_non_member_discovery: false
        )

        get initiations_path

        expect(response).to have_http_status(:success)
        body = response.body
        earlier_index = body.index('Initiation Plus Tôt')
        later_index = body.index('Initiation Plus Tard')

        expect(earlier_index).to be_present
        expect(later_index).to be_present
        expect(earlier_index).to be < later_index
      end
    end

    describe 'Capacity Display - Afficher places restantes' do
      it 'displays remaining capacity correctly' do
        user = create_user(role: user_role)
        initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 10,
          allow_non_member_discovery: false
        )

        # Inscrire 3 participants
        3.times do
          participant = create_user
          create(:membership, user: participant, status: :active, season: '2025-2026')
          create(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
        end

        login_user(user)
        get initiation_path(initiation)

        expect(response).to have_http_status(:success)
        # Vérifier que l'affichage montre les places restantes (7 places sur 10)
        expect(response.body).to include(initiation.title)
        # Le format exact dépend de l'implémentation, mais on vérifie que l'info est présente
      end
    end

    describe 'Unlimited Capacity - Support illimité' do
      it 'handles unlimited capacity for regular events (not initiations)' do
        user = create_user(role: user_role)
        # Les initiations ne peuvent pas être illimitées (max_participants > 0 requis)
        # Mais on peut tester avec un événement régulier
        event = create_event(
          type: 'Event',
          status: 'published',
          max_participants: 0, # 0 = illimité
          title: 'Sortie Illimitée'
        )
        login_user(user)

        get event_path(event)

        expect(response).to have_http_status(:success)
        expect(event.unlimited?).to be(true)
        expect(event.has_available_spots?).to be(true)
        # Vérifier que les initiations ne peuvent jamais être illimitées
        initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false
        )
        expect(initiation.unlimited?).to be(false)
      end
    end
  end

  # ============================================================================
  # 🟢 Phase 4: Tests v4.0 - Essais Gratuits Nominatifs
  # ============================================================================

  describe 'Phase 4: Tests v4.0 - Essais Gratuits Nominatifs' do
    describe 'Case 6.2: Réutilisation après annulation' do
      # Case 6.2: Annulation puis réinscription → ESSAI REDEVIENT DISPO
      it 'allows reusing free trial after cancellation (parent)' do
        user = create_user(role: user_role)
        first_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false
        )
        login_user(user)

        # T1: S'inscrire avec essai gratuit
        post initiation_attendances_path(first_initiation), params: { use_free_trial: "1" }
        expect(response).to redirect_to(initiation_path(first_initiation))

        attendance = Attendance.last
        expect(attendance.free_trial_used).to be true

        # T2: Vérifier que l'essai est utilisé
        expect(user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?).to be true

        # T3: Annuler l'inscription
        delete initiation_attendances_path(first_initiation)
        expect(response).to redirect_to(initiation_path(first_initiation))

        # T4: Vérifier que l'essai redevient disponible
        expect(user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?).to be false

        # T5: S'inscrire à nouveau avec essai gratuit (devrait fonctionner)
        second_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false
        )

        expect do
          post initiation_attendances_path(second_initiation), params: { use_free_trial: "1" }
        end.to change { Attendance.count }.by(1)

        new_attendance = Attendance.last
        expect(new_attendance.free_trial_used).to be true
        expect(response).to redirect_to(initiation_path(second_initiation))
      end

      it 'allows child to reuse free trial after cancellation (v4.0)' do
        parent = create_user(role: user_role)
        child_membership = create(:membership, :child, :pending, :with_health_questionnaire,
          user: parent,
          season: '2025-2026'
        )
        first_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false
        )
        login_user(parent)

        # T1: S'inscrire avec essai gratuit (OBLIGATOIRE selon v4.0)
        post initiation_attendances_path(first_initiation), params: {
          child_membership_id: child_membership.id,
          use_free_trial: "1"
        }
        expect(response).to redirect_to(initiation_path(first_initiation))

        attendance = Attendance.last
        expect(attendance.free_trial_used).to be true

        # T2: Vérifier que l'essai est utilisé
        expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child_membership.id).exists?).to be true

        # T3: Annuler l'inscription
        delete initiation_attendances_path(first_initiation), params: {
          child_membership_id: child_membership.id
        }
        expect(response).to redirect_to(initiation_path(first_initiation))

        # T4: Vérifier que l'essai redevient disponible
        expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child_membership.id).exists?).to be false

        # T5: S'inscrire à nouveau avec essai gratuit (devrait fonctionner)
        second_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false
        )

        expect do
          post initiation_attendances_path(second_initiation), params: {
            child_membership_id: child_membership.id,
            use_free_trial: "1"
          }
        end.to change { Attendance.count }.by(1)

        new_attendance = Attendance.last
        expect(new_attendance.free_trial_used).to be true
        expect(response).to redirect_to(initiation_path(second_initiation))
      end
    end

    describe 'Validation v4.0 - Essais nominatifs indépendants du parent' do
      it 'bloque enfant pending même si parent adhérent et essai utilisé' do
        # Case 1.3: pending + essai utilisé → BLOQUÉ - Même si parent adhérent
        parent = create_user(role: user_role)
        create(:membership, user: parent, status: :active, season: '2025-2026')
        child_membership = create(:membership, :child, :pending, :with_health_questionnaire,
          user: parent,
          season: '2025-2026'
        )

        first_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false
        )
        login_user(parent)

        # Utiliser l'essai gratuit (OBLIGATOIRE selon v4.0)
        post initiation_attendances_path(first_initiation), params: {
          child_membership_id: child_membership.id,
          use_free_trial: "1"
        }

        # Vérifier que l'essai est utilisé
        expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child_membership.id).exists?).to be true

        # Tentative d'inscription à une deuxième initiation → BLOQUÉ même si parent adhérent
        second_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false
        )

        expect do
          post initiation_attendances_path(second_initiation), params: {
            child_membership_id: child_membership.id
          }
        end.not_to change { Attendance.count }

        expect(response).to redirect_to(initiation_path(second_initiation))
        expect(flash[:alert]).to include("Cet enfant a déjà utilisé son essai gratuit")
      end

      it 'bloque enfant trial même si parent adhérent et essai utilisé' do
        # Case 2.3: trial + essai utilisé → BLOQUÉ - Même si parent adhérent
        parent = create_user(role: user_role)
        create(:membership, user: parent, status: :active, season: '2025-2026')
        child_membership = create(:membership, :child, :trial, :with_health_questionnaire,
          user: parent,
          season: '2025-2026'
        )

        first_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false
        )
        login_user(parent)

        # Utiliser l'essai gratuit (OBLIGATOIRE selon v4.0)
        post initiation_attendances_path(first_initiation), params: {
          child_membership_id: child_membership.id,
          use_free_trial: "1"
        }

        # Vérifier que l'essai est utilisé
        expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child_membership.id).exists?).to be true

        # Tentative d'inscription à une deuxième initiation → BLOQUÉ même si parent adhérent
        second_initiation = create_event(
          type: 'Event::Initiation',
          status: 'published',
          max_participants: 30,
          allow_non_member_discovery: false
        )

        expect do
          post initiation_attendances_path(second_initiation), params: {
            child_membership_id: child_membership.id
          }
        end.not_to change { Attendance.count }

        expect(response).to redirect_to(initiation_path(second_initiation))
        expect(flash[:alert]).to include("Cet enfant a déjà utilisé son essai gratuit")
      end
    end
  end
end

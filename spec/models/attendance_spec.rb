require 'rails_helper'

RSpec.describe Attendance, type: :model do
  let(:user) { create_user }
  let(:event) { create_event(creator_user: create_user) }

  describe 'validations' do
    it 'is valid with default attributes' do
      # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
      create(:membership, user: user, status: :active, season: '2025-2026')
      attendance = build_attendance(user: user, event: event)
      expect(attendance).to be_valid
    end

    it 'requires a status' do
      attendance = build_attendance(user: user, event: event, status: nil)
      expect(attendance).to be_invalid
      expect(attendance.errors[:status]).to be_present
    end

    it 'enforces uniqueness of user scoped to event' do
      # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
      create(:membership, user: user, status: :active, season: '2025-2026')
      create_attendance(user: user, event: event)
      duplicate = build_attendance(user: user, event: event)

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:user_id]).to include('a déjà une inscription pour cet événement avec ce statut')
    end
  end

  describe 'associations' do
    it 'accepts an optional payment' do
      # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
      create(:membership, user: user, status: :active, season: '2025-2026')
      payment = Payment.create!(provider: 'stripe', provider_payment_id: 'pi_123', amount_cents: 1000, currency: 'EUR', status: 'succeeded')
      attendance = build_attendance(user: user, event: event, payment: payment, status: 'paid')

      expect(attendance).to be_valid
      attendance.save!
      expect(attendance.payment).to eq(payment)
    end

    describe 'counter cache' do
      it 'increments event.attendances_count when attendance is created' do
        # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
        create(:membership, user: user, status: :active, season: '2025-2026')
        expect(event.attendances_count).to eq(0)

        create_attendance(user: user, event: event)
        event.reload

        expect(event.attendances_count).to eq(1)
      end

      it 'decrements event.attendances_count when attendance is destroyed' do
        # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
        create(:membership, user: user, status: :active, season: '2025-2026')
        attendance = create_attendance(user: user, event: event)
        event.reload
        expect(event.attendances_count).to eq(1)

        attendance.destroy
        event.reload

        expect(event.attendances_count).to eq(0)
      end

      it 'does not increment counter when attendance creation fails' do
        invalid_attendance = build_attendance(user: user, event: event, status: nil)
        initial_count = event.attendances_count

        expect { invalid_attendance.save }.not_to change { event.reload.attendances_count }
      end
    end

    describe 'max_participants validation' do
      let(:limited_event) { create_event(creator_user: create_user, max_participants: 2) }

      it 'allows attendance when event has available spots' do
        # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
        create(:membership, user: user, status: :active, season: '2025-2026')
        attendance = build_attendance(user: user, event: limited_event)
        expect(attendance).to be_valid
      end

      it 'allows attendance when event is unlimited (max_participants = 0)' do
        # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
        create(:membership, user: user, status: :active, season: '2025-2026')
        unlimited_event = create_event(creator_user: create_user, max_participants: 0)
        attendance = build_attendance(user: user, event: unlimited_event)
        expect(attendance).to be_valid
      end

      it 'prevents attendance when event is full' do
        # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
        create(:membership, user: user, status: :active, season: '2025-2026')
        # Fill the event to capacity (créer des adhésions pour les autres utilisateurs aussi)
        other_user1 = create_user
        other_user2 = create_user
        create(:membership, user: other_user1, status: :active, season: '2025-2026')
        create(:membership, user: other_user2, status: :active, season: '2025-2026')
        create_attendance(event: limited_event, user: other_user1, status: 'registered')
        create_attendance(event: limited_event, user: other_user2, status: 'registered')
        limited_event.reload

        # Try to create another attendance
        attendance = build_attendance(user: user, event: limited_event)
        expect(attendance).to be_invalid
        expect(attendance.errors[:event]).to include(match(/complet/))
      end

      it 'does not count canceled attendances when checking capacity' do
        # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
        create(:membership, user: user, status: :active, season: '2025-2026')
        # Fill with one active and one canceled (créer des adhésions pour les autres utilisateurs aussi)
        other_user1 = create_user
        other_user2 = create_user
        create(:membership, user: other_user1, status: :active, season: '2025-2026')
        create(:membership, user: other_user2, status: :active, season: '2025-2026')
        create_attendance(event: limited_event, user: other_user1, status: 'registered')
        create_attendance(event: limited_event, user: other_user2, status: 'canceled')
        limited_event.reload

        # Should still allow new attendance (only 1 active)
        attendance = build_attendance(user: user, event: limited_event)
        expect(attendance).to be_valid
      end
    end
  end

  describe 'scopes' do
    # Nettoyer les anciennes données d'attendance (seeds, tests précédents)
    before do
      Attendance.delete_all
    end
    it 'returns non-canceled attendances for active scope' do
      # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
      user1 = create_user
      user2 = create_user
      create(:membership, user: user1, status: :active, season: '2025-2026')
      create(:membership, user: user2, status: :active, season: '2025-2026')
      active = create_attendance(user: user1, status: 'registered')
      create_attendance(user: user2, status: 'canceled')

      expect(Attendance.active).to contain_exactly(active)
    end

    it 'returns canceled attendances for canceled scope' do
      # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
      user1 = create_user
      user2 = create_user
      create(:membership, user: user1, status: :active, season: '2025-2026')
      create(:membership, user: user2, status: :active, season: '2025-2026')
      canceled = create_attendance(user: user1, status: 'canceled')
      create_attendance(user: user2, status: 'registered')

      expect(Attendance.canceled).to contain_exactly(canceled)
    end

    describe '.volunteers' do
      it 'returns only volunteer attendances' do
        # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
        user1 = create_user
        user2 = create_user
        create(:membership, user: user1, status: :active, season: '2025-2026')
        create(:membership, user: user2, status: :active, season: '2025-2026')
        volunteer = create_attendance(user: user1, is_volunteer: true)
        participant = create_attendance(user: user2, is_volunteer: false)

        expect(Attendance.volunteers).to contain_exactly(volunteer)
        expect(Attendance.volunteers).not_to include(participant)
      end
    end

    describe '.participants' do
      it 'returns only non-volunteer attendances' do
        # Pour les événements normaux, créer une adhésion active ou utiliser essai gratuit
        user1 = create_user
        user2 = create_user
        create(:membership, user: user1, status: :active, season: '2025-2026')
        create(:membership, user: user2, status: :active, season: '2025-2026')
        volunteer = create_attendance(user: user1, is_volunteer: true)
        participant = create_attendance(user: user2, is_volunteer: false)

        expect(Attendance.participants).to contain_exactly(participant)
        expect(Attendance.participants).not_to include(volunteer)
      end
    end
  end

  describe 'initiation-specific validations' do
    # Utiliser le helper générique pour créer une initiation,
    # en bypassant les validations complexes d'Event::Initiation
    let(:initiation) { create_event(type: 'Event::Initiation', max_participants: 1, allow_non_member_discovery: false) }
    let(:user) { create_user }

    describe 'when initiation is full' do
      before do
        # Créer un participant avec une adhésion active pour que l'inscription initiale soit valide
        member_user = create_user
        create(:membership, user: member_user, status: :active, season: '2025-2026')
        create_attendance(event: initiation, user: member_user, is_volunteer: false, status: 'registered')
      end

      it 'prevents non-volunteer registration' do
        attendance = build_attendance(event: initiation, is_volunteer: false, status: 'registered')
        expect(attendance).to be_invalid
        expect(attendance.errors[:event]).to include(match(/complet/))
      end

      it 'allows volunteer registration even if full' do
        attendance = build_attendance(event: initiation, is_volunteer: true, status: 'registered')
        expect(attendance).to be_valid # Bénévoles bypass
      end
    end

    describe 'free_trial_used validation' do
      it 'prevents using free trial twice' do
        user = create_user
        first_initiation = create_event(type: 'Event::Initiation', max_participants: 30, allow_non_member_discovery: false)
        create_attendance(user: user, free_trial_used: true, event: first_initiation)

        second_initiation = create_event(type: 'Event::Initiation', max_participants: 30, allow_non_member_discovery: false)
        attendance = build_attendance(user: user, free_trial_used: true, event: second_initiation)
        expect(attendance).to be_invalid
        expect(attendance.errors[:free_trial_used]).to include("Vous avez déjà utilisé votre essai gratuit")
      end

      it 'allows free trial if never used' do
        user = create_user
        initiation = create_event(type: 'Event::Initiation', max_participants: 30, allow_non_member_discovery: false)
        attendance = build_attendance(user: user, free_trial_used: true, event: initiation)
        expect(attendance).to be_valid
      end

      it 'allows reusing free trial after cancellation' do
        # Selon la documentation 01-regles-generales.md (section 1.3) :
        # "Si un utilisateur se désinscrit d'une initiation où il avait utilisé son essai gratuit :
        # - L'essai gratuit redevient disponible
        # - Il peut s'inscrire à nouveau à une initiation en utilisant son essai gratuit
        # - Seules les attendances avec status = 'canceled' sont exclues des vérifications"
        # Timeline : T0: Enfant créé → T1: Inscription Initiation A (essai utilisé) → T2: Essai bloqué
        # → T3: Annulation Initiation A → T4: Essai redevient disponible → T5: Inscription Initiation B (essai utilisé)

        user = create_user
        first_initiation = create_event(type: 'Event::Initiation', max_participants: 30, allow_non_member_discovery: false)

        # T1: S'inscrire à Initiation A avec essai gratuit
        first_attendance = create_attendance(user: user, free_trial_used: true, event: first_initiation)
        expect(first_attendance.free_trial_used).to be true
        expect(first_attendance.status).to eq('registered')

        # T2: Vérifier que l'essai gratuit est maintenant "utilisé" (bloqué)
        expect(user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?).to be true

        # T3: Annuler l'inscription (destroy)
        first_attendance.destroy
        expect(first_attendance.destroyed?).to be true

        # T4: Vérifier que l'essai gratuit redevient disponible
        # Le scope .active exclut les attendances annulées (destroyed)
        # Donc la requête ne trouve plus l'attendance annulée
        expect(user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?).to be false

        # T5: S'inscrire à Initiation B avec essai gratuit (devrait fonctionner)
        second_initiation = create_event(type: 'Event::Initiation', max_participants: 30, allow_non_member_discovery: false)
        second_attendance = build_attendance(user: user, free_trial_used: true, event: second_initiation)

        # La validation devrait passer car l'essai gratuit est redevenu disponible
        expect(second_attendance).to be_valid
        expect(second_attendance.errors[:free_trial_used]).to be_empty
      end

      it 'allows child to reuse free trial after cancellation' do
        # Test pour un enfant (avec child_membership_id)
        user = create_user
        # Utiliser la factory pour créer un membership trial (qui gère les validations)
        child_membership = create(:membership, :child, :trial, user: user, season: '2025-2026')

        first_initiation = create_event(type: 'Event::Initiation', max_participants: 30, allow_non_member_discovery: false)

        # T1: S'inscrire à Initiation A avec essai gratuit
        first_attendance = create_attendance(
          user: user,
          free_trial_used: true,
          event: first_initiation,
          child_membership_id: child_membership.id
        )
        expect(first_attendance.free_trial_used).to be true
        expect(first_attendance.child_membership_id).to eq(child_membership.id)

        # T2: Vérifier que l'essai gratuit est maintenant "utilisé" (bloqué)
        expect(user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership.id).exists?).to be true

        # T3: Annuler l'inscription
        first_attendance.destroy
        expect(first_attendance.destroyed?).to be true

        # T4: Vérifier que l'essai gratuit redevient disponible
        expect(user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership.id).exists?).to be false

        # T5: S'inscrire à Initiation B avec essai gratuit (devrait fonctionner)
        second_initiation = create_event(type: 'Event::Initiation', max_participants: 30, allow_non_member_discovery: false)
        second_attendance = build_attendance(
          user: user,
          free_trial_used: true,
          event: second_initiation,
          child_membership_id: child_membership.id
        )

        # La validation devrait passer car l'essai gratuit est redevenu disponible
        expect(second_attendance).to be_valid
        expect(second_attendance.errors[:free_trial_used]).to be_empty
      end

      # Cas limite 5.1 et 5.2 : Double inscription avant annulation / Essai réutilisé avant première annulation
      # (Déjà testé par "prevents using free trial twice" ligne 219-228)

      # Cas limite 5.4 : Tentative de contournement (modification paramètres)
      it 'prevents bypassing free trial requirement for trial child by modifying params' do
        # Selon la documentation 05-cas-limites.md (section 5.4) :
        # "Utilisateur modifie les paramètres HTTP pour ne pas envoyer use_free_trial"
        # Protection : Validation modèle vérifie l'état (free_trial_used), pas les paramètres

        user = create_user
        child_membership = create(:membership, :child, :trial, user: user, season: '2025-2026')
        initiation = create_event(type: 'Event::Initiation', max_participants: 30, allow_non_member_discovery: false)

        # Tentative de contournement : créer une attendance avec free_trial_used = false
        # pour un enfant trial (devrait être bloqué par la validation modèle)
        attendance = build_attendance(
          user: user,
          event: initiation,
          child_membership_id: child_membership.id,
          free_trial_used: false # Tentative de contournement
        )

        # La validation modèle devrait bloquer car pour trial, free_trial_used DOIT être true
        expect(attendance).to be_invalid
        expect(attendance.errors[:free_trial_used]).to include("L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante.")
      end

      # Cas limite 5.5 : JavaScript désactivé
      it 'prevents registration without free trial when JavaScript is disabled for trial child' do
        # Selon la documentation 05-cas-limites.md (section 5.5) :
        # "Utilisateur désactive JavaScript et essaie de soumettre sans cocher la checkbox"
        # Protection : Validation contrôleur ET modèle

        user = create_user
        child_membership = create(:membership, :child, :trial, user: user, season: '2025-2026')
        initiation = create_event(type: 'Event::Initiation', max_participants: 30, allow_non_member_discovery: false)

        # Simuler JavaScript désactivé : params[:use_free_trial] = nil
        # La validation modèle devrait bloquer même si le contrôleur est contourné
        attendance = build_attendance(
          user: user,
          event: initiation,
          child_membership_id: child_membership.id,
          free_trial_used: false # JavaScript désactivé, checkbox non cochée
        )

        # La validation modèle devrait bloquer
        expect(attendance).to be_invalid
        expect(attendance.errors[:free_trial_used]).to include("L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante.")
      end

      # Cas limite 5.6 : Réinscription même initiation après annulation
      it 'allows re-registration to same initiation after cancellation with free trial' do
        # Selon la documentation 05-cas-limites.md (section 5.6) :
        # "Enfant annule puis essaie de s'inscrire à nouveau à la même initiation"
        # Protection : Contrainte unicité autorise réinscription après annulation
        # Essai gratuit redevient disponible (scope .active exclut canceled)

        user = create_user
        child_membership = create(:membership, :child, :trial, user: user, season: '2025-2026')
        initiation = create_event(type: 'Event::Initiation', max_participants: 30, allow_non_member_discovery: false)

        # T1: S'inscrire à Initiation A avec essai gratuit
        first_attendance = create_attendance(
          user: user,
          event: initiation,
          child_membership_id: child_membership.id,
          free_trial_used: true
        )
        expect(first_attendance.free_trial_used).to be true
        expect(first_attendance.status).to eq('registered')

        # T2: Annuler l'inscription
        first_attendance.destroy
        expect(first_attendance.destroyed?).to be true

        # T3: Vérifier que l'essai gratuit redevient disponible
        expect(user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership.id).exists?).to be false

        # T4: S'inscrire à nouveau à la MÊME initiation avec essai gratuit (devrait fonctionner)
        # La contrainte unicité autorise la réinscription car l'ancienne attendance est destroyed
        second_attendance = build_attendance(
          user: user,
          event: initiation, # MÊME initiation
          child_membership_id: child_membership.id,
          free_trial_used: true
        )

        # La validation devrait passer car :
        # 1. L'essai gratuit est redevenu disponible (scope .active exclut destroyed)
        # 2. La contrainte unicité autorise la réinscription (ancienne attendance destroyed)
        expect(second_attendance).to be_valid
        expect(second_attendance.errors[:free_trial_used]).to be_empty
        expect(second_attendance.errors[:user_id]).to be_empty
      end
    end

    describe 'can_register_to_initiation' do
      # Par défaut, on ne permet PAS la découverte non-adhérents,
      # pour tester le comportement "adhésion requise"
      # On utilise build pour ne pas dépendre de la persistance en base de l'événement
      let(:initiation) { build(:event_initiation, max_participants: 30, allow_non_member_discovery: false) }
      let(:user) { create_user }

      context 'when user has active membership' do
        before do
          create(:membership, user: user, status: :active, season: '2025-2026')
        end

        it 'allows registration without free trial' do
          attendance = build_attendance(user: user, event: initiation, free_trial_used: false)
          expect(attendance).to be_valid
        end
      end

      context 'when user has child membership' do
        before do
          # Utiliser le trait :child pour respecter toutes les validations des adhésions enfants
          create(:membership, :child, user: user, status: :active, season: '2025-2026')
        end

        it 'allows registration with child membership' do
          attendance = build_attendance(user: user, event: initiation, free_trial_used: false)
          expect(attendance).to be_valid
        end
      end

      context 'when user has no membership and no free trial' do
        it 'prevents registration' do
          # S'assurer que l'utilisateur n'a pas d'adhésion active
          user.memberships.destroy_all
          attendance = build_attendance(user: user, event: initiation, free_trial_used: false)
          expect(attendance).to be_invalid
          expect(attendance.errors[:base]).to include(match(/Adhésion requise/))
        end
      end

      context 'when user uses free trial' do
        it 'allows registration with free trial' do
          # S'assurer que l'utilisateur n'a pas d'adhésion active et n'a pas utilisé l'essai gratuit
          user.memberships.destroy_all
          user.attendances.where(free_trial_used: true).destroy_all
          attendance = build_attendance(user: user, event: initiation, free_trial_used: true)
          expect(attendance).to be_valid
        end
      end
    end
  end

  describe 'can_register_to_event (regular events/randos)' do
    let(:regular_event) { build(:event, max_participants: 30) }
    let(:user) { create_user }

    context 'when registering a child' do
      context 'with active membership' do
        let(:child_membership) { create(:membership, :child, user: user, status: :active, season: '2025-2026') }

        it 'allows registration' do
          attendance = build_attendance(user: user, event: regular_event, child_membership_id: child_membership.id)
          expect(attendance).to be_valid
        end
      end

      context 'with expired membership' do
        let(:child_membership) { create(:membership, :child, user: user, status: :expired, season: '2024-2025') }

        it 'allows registration' do
          attendance = build_attendance(user: user, event: regular_event, child_membership_id: child_membership.id)
          expect(attendance).to be_valid
        end
      end

      context 'with trial membership' do
        let(:child_membership) { create(:membership, :child, user: user, status: :trial, season: '2025-2026') }

        it 'allows registration' do
          attendance = build_attendance(user: user, event: regular_event, child_membership_id: child_membership.id)
          expect(attendance).to be_valid
        end
      end

      context 'with pending membership' do
        let(:child_membership) { create(:membership, :child, user: user, status: :pending, season: '2025-2026') }

        it 'allows registration' do
          attendance = build_attendance(user: user, event: regular_event, child_membership_id: child_membership.id)
          expect(attendance).to be_valid
        end
      end

      context 'when child membership does not belong to user' do
        let(:other_user) { create_user }
        let(:other_child_membership) { create(:membership, :child, user: other_user, status: :active, season: '2025-2026') }

        it 'prevents registration' do
          attendance = build_attendance(user: user, event: regular_event, child_membership_id: other_child_membership.id)
          expect(attendance).to be_invalid
          expect(attendance.errors[:child_membership_id]).to include("Cette adhésion enfant ne vous appartient pas")
        end
      end
    end

    context 'when registering as parent' do
      context 'with active membership' do
        before do
          create(:membership, user: user, status: :active, season: '2025-2026')
        end

        it 'allows registration' do
          attendance = build_attendance(user: user, event: regular_event, child_membership_id: nil)
          expect(attendance).to be_valid
        end
      end

      context 'with active child membership' do
        before do
          create(:membership, :child, user: user, status: :active, season: '2025-2026')
        end

        it 'allows registration' do
          attendance = build_attendance(user: user, event: regular_event, child_membership_id: nil)
          expect(attendance).to be_valid
        end
      end

      context 'with no membership and no free trial' do
        before do
          user.memberships.destroy_all
          user.attendances.where(free_trial_used: true).destroy_all
        end

        it 'allows registration (events are open to everyone)' do
          attendance = build_attendance(user: user, event: regular_event, child_membership_id: nil, free_trial_used: false)
          expect(attendance).to be_valid
        end
      end

      context 'with free trial available' do
        before do
          user.memberships.destroy_all
          user.attendances.where(free_trial_used: true).destroy_all
        end

        it 'allows registration with free trial' do
          attendance = build_attendance(user: user, event: regular_event, child_membership_id: nil, free_trial_used: true)
          expect(attendance).to be_valid
        end
      end
    end
  end
end

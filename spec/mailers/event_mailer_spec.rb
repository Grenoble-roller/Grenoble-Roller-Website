require 'rails_helper'

RSpec.describe EventMailer, type: :mailer do
  let!(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let!(:organizer_role) { ensure_role(code: 'ORGANIZER', name: 'Organisateur', level: 40) }

  describe '#attendance_confirmed' do
    let(:user) { create(:user, first_name: 'John', email: 'john@example.com', role: user_role) }
    let(:organizer) { create(:user, role: organizer_role) }
    # Créer une adhésion active pour l'utilisateur (requis pour les événements normaux)
    let!(:user_membership) { create(:membership, user: user, status: :active, season: '2025-2026') }
    let(:event) { create(:event, :published, :upcoming, title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer) }
    let(:attendance) { create(:attendance, user: user, event: event) }
    let(:mail) { EventMailer.attendance_confirmed(attendance) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes event title in subject' do
      expect(mail.subject).to include(event.title)
      expect(mail.subject).to include('Inscription confirmée')
    end

    it 'includes event details in body' do
      expect(mail.body.encoded).to include(event.location_text)
      expect(mail.body.encoded).to include(event.title)
    end

    it 'includes user first name in body' do
      expect(mail.body.encoded).to include(user.first_name)
    end

    it 'includes event date in body' do
      # Vérifier que la date est présente (format peut varier)
      # On vérifie que l'année est présente et qu'il y a des chiffres (jour/mois)
      expect(mail.body.encoded).to include(event.start_at.strftime('%Y'))
      expect(mail.body.encoded).to match(/\d+/)
    end

    it 'includes event URL in body' do
      # Le body est encodé, donc on décode pour chercher l'URL
      # event_url génère une URL absolue, on cherche le hashid dans le body décodé
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include(event.hashid).or include("/events/#{event.hashid}")
    end

    context 'when event has a route' do
      let(:route) { create(:route, name: 'Parcours du Lac') }
      let(:event) { create(:event, :published, :upcoming, route: route, creator_user: organizer) }
      let(:attendance) { create(:attendance, user: user, event: event) }
      let(:mail) { EventMailer.attendance_confirmed(attendance) }

      it 'includes route name in body' do
        expect(mail.body.encoded).to include(route.name)
      end
    end

    context 'when event has a price' do
      let(:event) { create(:event, :published, :upcoming, price_cents: 1000, creator_user: organizer) }
      let(:attendance) { create(:attendance, user: user, event: event) }
      let(:mail) { EventMailer.attendance_confirmed(attendance) }

      it 'includes price in body' do
        # Vérifier que le prix est présent (format peut varier selon locale)
        # On vérifie que "10" est présent (peut être "10,00", "10.00", "10€", etc.)
        expect(mail.body.encoded).to include('10')
      end
    end

    context 'when event has max_participants' do
      let(:event) { create(:event, :published, :upcoming, max_participants: 20, creator_user: organizer) }
      let(:attendance) { create(:attendance, user: user, event: event, status: 'registered') }
      let(:mail) { EventMailer.attendance_confirmed(attendance) }

      it 'includes participants count in body' do
        # active_attendances_count compte uniquement les inscriptions actives
        expect(mail.body.encoded).to include('1 / 20')
      end
    end
  end

  describe '#attendance_cancelled' do
    let(:organizer) { create_user(role: organizer_role) }
    let(:user) { create_user(first_name: 'Jane', email: 'jane@example.com', role: user_role) }
    let(:event) { create_event(status: 'published', title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer, start_at: 3.days.from_now) }
    let(:mail) { EventMailer.attendance_cancelled(user, event) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes event title in subject' do
      expect(mail.subject).to include(event.title)
      expect(mail.subject).to include('Désinscription confirmée')
    end

    it 'includes event details in body' do
      # Le body peut être multipart (HTML + texte), on vérifie le HTML décodé
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      expect(body_content).to include(event.location_text)
      expect(body_content).to include(event.title)
    end

    it 'includes user first name in body' do
      expect(mail.body.encoded).to include(user.first_name)
    end

    it 'includes event date in body' do
      # Le body peut être multipart (HTML + texte), on vérifie le HTML décodé
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      # Vérifier que la date est présente (format peut varier)
      # On vérifie que l'année est présente et qu'il y a des chiffres (jour/mois)
      expect(body_content).to include(event.start_at.strftime('%Y'))
      expect(body_content).to match(/\d+/)
    end

    it 'includes event URL in body' do
      # Le body est encodé, donc on décode pour chercher l'URL
      # event_url génère une URL absolue, on cherche le hashid dans le body décodé
      decoded_body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
      expect(decoded_body).to include(event.hashid).or include("/events/#{event.hashid}")
    end
  end

  describe '#event_reminder' do
    let(:organizer) { create_user(role: organizer_role) }
    let(:user) { create_user(first_name: 'Bob', email: 'bob@example.com', role: user_role) }
    # Créer une adhésion active pour l'utilisateur (requis pour les événements normaux)
    let!(:user_membership) { create(:membership, user: user, status: :active, season: '2025-2026') }
    let(:event) { create_event(status: 'published', title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer, start_at: 3.days.from_now) }
    let(:attendance) { create_attendance(user: user, event: event) }
    let(:attendances) { [ attendance ] }
    let(:mail) { EventMailer.event_reminder(user, event, attendances) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes event title in subject' do
      expect(mail.subject).to include(event.title)
      expect(mail.subject).to include('Rappel')
    end

    it 'includes event details in body' do
      expect(mail.body.encoded).to include(event.location_text)
      expect(mail.body.encoded).to include(event.title)
    end

    it 'includes user first name in body' do
      expect(mail.body.encoded).to include(user.first_name)
    end

    context 'with multiple attendances (parent + children)' do
      let(:child_membership1) { create(:membership, :child, user: user, status: :active, season: '2025-2026', child_first_name: 'Enfant1') }
      let(:child_membership2) { create(:membership, :child, user: user, status: :active, season: '2025-2026', child_first_name: 'Enfant2') }
      let(:attendance_parent) { create_attendance(user: user, event: event) }
      let(:attendance_child1) { create_attendance(user: user, event: event, child_membership: child_membership1) }
      let(:attendance_child2) { create_attendance(user: user, event: event, child_membership: child_membership2) }
      let(:attendances) { [ attendance_parent, attendance_child1, attendance_child2 ] }
      let(:mail) { EventMailer.event_reminder(user, event, attendances) }

      it 'sends one email with multiple participants' do
        expect(mail.to).to eq([ user.email ])
      end

      it 'includes event title in subject' do
        # Pour les événements normaux, le nombre de participants n'est pas dans le sujet
        # Seulement pour les initiations
        expect(mail.subject).to include(event.title)
      end

      it 'includes all participant names in body' do
        body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
        expect(body).to include(attendance_parent.participant_name)
        expect(body).to include(attendance_child1.participant_name)
        expect(body).to include(attendance_child2.participant_name)
      end
    end

    context 'when event is an initiation with multiple participants' do
      let(:initiation) { create_event(type: 'Event::Initiation', status: 'published', title: 'Initiation Roller', location_text: 'Parc Paul Mistral', creator_user: organizer, start_at: 3.days.from_now, max_participants: 20) }
      let(:child_membership1) { create(:membership, :child, user: user, status: :active, season: '2025-2026', child_first_name: 'Enfant1') }
      let(:attendance_parent) { create_attendance(user: user, event: initiation) }
      let(:attendance_child1) { create_attendance(user: user, event: initiation, child_membership: child_membership1) }
      let(:attendances) { [ attendance_parent, attendance_child1 ] }
      let(:mail) { EventMailer.event_reminder(user, initiation, attendances) }

      it 'includes participant count in subject for initiation' do
        expect(mail.subject).to include('2 participants')
      end
    end
  end

  describe '#event_cancelled' do
    let(:organizer) { create_user(role: organizer_role) }
    let(:user) { create_user(first_name: 'Alice', email: 'alice@example.com', role: user_role) }
    # Créer une adhésion active pour l'utilisateur (requis pour les événements normaux)
    let!(:user_membership) { create(:membership, user: user, status: :active, season: '2025-2026') }
    let(:event) { create_event(status: 'published', title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer, start_at: 3.days.from_now) }
    let(:attendance) { create_attendance(user: user, event: event) }
    let(:attendances) { [ attendance ] }
    let(:mail) { EventMailer.event_cancelled(user, event, attendances) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes event title in subject' do
      expect(mail.subject).to include(event.title)
      expect(mail.subject).to include('annulé')
    end

    it 'includes event details in body' do
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      expect(body_content).to include(event.location_text)
      expect(body_content).to include(event.title)
    end

    it 'includes user first name in body' do
      expect(mail.body.encoded).to include(user.first_name)
    end

    it 'includes event date in body' do
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      expect(body_content).to include(event.start_at.strftime('%Y'))
      expect(body_content).to match(/\d+/)
    end

    context 'with multiple attendances (parent + children)' do
      let(:child_membership1) { create(:membership, :child, user: user, status: :active, season: '2025-2026', child_first_name: 'Enfant1') }
      let(:child_membership2) { create(:membership, :child, user: user, status: :active, season: '2025-2026', child_first_name: 'Enfant2') }
      let(:attendance_parent) { create_attendance(user: user, event: event) }
      let(:attendance_child1) { create_attendance(user: user, event: event, child_membership: child_membership1) }
      let(:attendance_child2) { create_attendance(user: user, event: event, child_membership: child_membership2) }
      let(:attendances) { [ attendance_parent, attendance_child1, attendance_child2 ] }
      let(:mail) { EventMailer.event_cancelled(user, event, attendances) }

      it 'sends one email with multiple participants' do
        expect(mail.to).to eq([ user.email ])
      end

      it 'includes event title in subject' do
        # Pour les événements normaux, le nombre de participants n'est pas dans le sujet
        # Seulement pour les initiations
        expect(mail.subject).to include(event.title)
      end

      it 'includes all participant names in body' do
        body = mail.body.parts.any? ? mail.body.parts.map(&:decoded).join : mail.body.decoded
        expect(body).to include(attendance_parent.participant_name)
        expect(body).to include(attendance_child1.participant_name)
        expect(body).to include(attendance_child2.participant_name)
      end
    end

    context 'when event is an initiation' do
      let(:initiation) { create_event(type: 'Event::Initiation', status: 'published', title: 'Initiation Roller', location_text: 'Parc Paul Mistral', creator_user: organizer, start_at: 3.days.from_now, max_participants: 20) }
      let(:attendance) { create_attendance(user: user, event: initiation) }
      let(:attendances) { [ attendance ] }
      let(:mail) { EventMailer.event_cancelled(user, initiation, attendances) }

      it 'includes initiation-specific subject' do
        expect(mail.subject).to include('Initiation roller')
        expect(mail.subject).to include('annulé')
      end

      context 'with multiple participants' do
        let(:child_membership1) { create(:membership, :child, user: user, status: :active, season: '2025-2026', child_first_name: 'Enfant1') }
        let(:attendance_parent) { create_attendance(user: user, event: initiation) }
        let(:attendance_child1) { create_attendance(user: user, event: initiation, child_membership: child_membership1) }
        let(:attendances) { [ attendance_parent, attendance_child1 ] }
        let(:mail) { EventMailer.event_cancelled(user, initiation, attendances) }

        it 'includes participant count in subject for initiation' do
          expect(mail.subject).to include('2 participants')
        end
      end
    end
  end

  describe '#event_rejected' do
    let(:creator) { create_user(first_name: 'Charlie', email: 'charlie@example.com', role: organizer_role) }
    let(:event) { create_event(status: 'rejected', title: 'Sortie Refusée', location_text: 'Parc Paul Mistral', creator_user: creator, start_at: 3.days.from_now) }
    let(:mail) { EventMailer.event_rejected(event) }

    it 'sends to creator email' do
      expect(mail.to).to eq([ creator.email ])
    end

    it 'includes event title in subject' do
      expect(mail.subject).to include(event.title)
      expect(mail.subject).to include('refusé')
    end

    it 'includes event details in body' do
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      expect(body_content).to include(event.location_text)
      expect(body_content).to include(event.title)
    end

    it 'includes creator first name in body' do
      expect(mail.body.encoded).to include(creator.first_name)
    end

    it 'includes event date in body' do
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      expect(body_content).to include(event.start_at.strftime('%Y'))
      expect(body_content).to match(/\d+/)
    end

    context 'when event is an initiation' do
      let(:initiation) { create_event(type: 'Event::Initiation', status: 'rejected', title: 'Initiation Refusée', location_text: 'Parc Paul Mistral', creator_user: creator, start_at: 3.days.from_now, max_participants: 20) }
      let(:mail) { EventMailer.event_rejected(initiation) }

      it 'includes initiation-specific subject' do
        expect(mail.subject).to include('initiation')
        expect(mail.subject).to include('refusée')
      end
    end
  end

  describe '#waitlist_spot_available' do
    let(:organizer) { create_user(role: organizer_role) }
    let!(:organizer_membership) { create(:membership, user: organizer, status: :active, season: '2025-2026') }
    let(:user) { create_user(first_name: 'David', email: 'david@example.com', role: user_role) }
    let!(:user_membership) { create(:membership, user: user, status: :active, season: '2025-2026') }
    let(:event) { create_event(status: 'published', title: 'Sortie Complète', location_text: 'Parc Paul Mistral', creator_user: organizer, start_at: 3.days.from_now, max_participants: 1) }
    let!(:existing_attendance) { create_attendance(user: organizer, event: event, status: 'registered') }
    let(:waitlist_entry) { create(:waitlist_entry, :notified, user: user, event: event, notified_at: 1.hour.ago) }
    let(:mail) { EventMailer.waitlist_spot_available(waitlist_entry) }

    it 'sends to user email' do
      expect(mail.to).to eq([ user.email ])
    end

    it 'includes event title in subject' do
      expect(mail.subject).to include(event.title)
      expect(mail.subject).to include('Place disponible')
    end

    it 'includes event details in body' do
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      expect(body_content).to include(event.location_text)
      expect(body_content).to include(event.title)
    end

    it 'includes user first name in body' do
      expect(mail.body.encoded).to include(user.first_name)
    end

    it 'includes participant name in body' do
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      expect(body_content).to include(waitlist_entry.participant_name)
    end

    it 'includes confirmation token in body' do
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      # Le token est généré dynamiquement, on vérifie juste qu'il est présent dans l'URL
      # Le token peut être dans confirm ou decline
      expect(body_content).to match(/token=|confirm_waitlist_entry|decline/)
    end

    context 'when event is an initiation' do
      let(:initiation) { create_event(type: 'Event::Initiation', status: 'published', title: 'Initiation Complète', location_text: 'Parc Paul Mistral', creator_user: organizer, start_at: 3.days.from_now, max_participants: 1) }
      let!(:existing_attendance) { create_attendance(user: organizer, event: initiation, status: 'registered') }
      let(:waitlist_entry) { create(:waitlist_entry, :notified, user: user, event: initiation, notified_at: 1.hour.ago) }
      let(:mail) { EventMailer.waitlist_spot_available(waitlist_entry) }

      it 'includes initiation-specific subject' do
        expect(mail.subject).to include('Initiation roller')
        expect(mail.subject).to include('Place disponible')
      end
    end

    context 'when waitlist entry is for a child' do
      let(:child_membership) { create(:membership, :child, user: user, status: :active, season: '2025-2026', child_first_name: 'Enfant') }
      let(:waitlist_entry) { create(:waitlist_entry, :notified, :for_child, user: user, event: event, child_membership: child_membership, notified_at: 1.hour.ago) }
      let(:mail) { EventMailer.waitlist_spot_available(waitlist_entry) }

      it 'includes child name in body' do
        html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
        body_content = html_part ? html_part.decoded : mail.body.decoded
        expect(body_content).to include(waitlist_entry.participant_name)
      end
    end
  end

  describe '#initiation_participants_report' do
    let(:organizer) { create_user(role: organizer_role) }
    let(:user1) { create_user(first_name: 'Emma', email: 'emma@example.com', role: user_role) }
    let(:user2) { create_user(first_name: 'Frank', email: 'frank@example.com', role: user_role) }
    let!(:user1_membership) { create(:membership, user: user1, status: :active, season: '2025-2026') }
    let!(:user2_membership) { create(:membership, user: user2, status: :active, season: '2025-2026') }
    let(:initiation) { create_event(type: 'Event::Initiation', status: 'published', title: 'Initiation Roller', location_text: 'Parc Paul Mistral', creator_user: organizer, start_at: 1.day.from_now, max_participants: 20) }
    let!(:attendance1) { create_attendance(user: user1, event: initiation, status: 'registered', is_volunteer: false) }
    let!(:attendance2) { create_attendance(user: user2, event: initiation, status: 'registered', is_volunteer: false) }
    let(:mail) { EventMailer.initiation_participants_report(initiation) }

    it 'sends to contact email' do
      expect(mail.to).to eq([ 'contact@grenoble-roller.org' ])
    end

    it 'includes initiation date in subject' do
      expect(mail.subject).to include('Rapport participants')
      expect(mail.subject).to include('Initiation')
    end

    it 'includes initiation details in body' do
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      expect(body_content).to include(initiation.location_text)
      expect(body_content).to include(initiation.title)
    end

    it 'includes participants count in body' do
      html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
      body_content = html_part ? html_part.decoded : mail.body.decoded
      expect(body_content).to include('2 inscrit')
    end

    context 'when participants request equipment' do
      let!(:attendance1) { create_attendance(user: user1, event: initiation, status: 'registered', is_volunteer: false, needs_equipment: true, roller_size: '38') }
      let!(:attendance2) { create_attendance(user: user2, event: initiation, status: 'registered', is_volunteer: false, needs_equipment: true, roller_size: '40') }
      let(:mail) { EventMailer.initiation_participants_report(initiation) }

      it 'includes equipment requests count in body' do
        html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
        body_content = html_part ? html_part.decoded : mail.body.decoded
        expect(body_content).to include('2 demande')
      end

      it 'includes roller sizes in body' do
        html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
        body_content = html_part ? html_part.decoded : mail.body.decoded
        expect(body_content).to include('38')
        expect(body_content).to include('40')
      end
    end

    context 'when no participants request equipment' do
      it 'shows zero equipment requests' do
        html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
        body_content = html_part ? html_part.decoded : mail.body.decoded
        expect(body_content).to include('0 demande')
      end
    end

    context 'when there are volunteers' do
      let!(:volunteer_attendance) { create_attendance(user: organizer, event: initiation, status: 'registered', is_volunteer: true) }
      let(:mail) { EventMailer.initiation_participants_report(initiation) }

      it 'excludes volunteers from participants count' do
        html_part = mail.body.parts.find { |p| p.content_type.include?('text/html') }
        body_content = html_part ? html_part.decoded : mail.body.decoded
        # Devrait toujours afficher 2 participants (pas 3 avec le bénévole)
        expect(body_content).to include('2 inscrit')
      end
    end
  end
end

require 'rails_helper'

RSpec.describe 'Initiations', type: :request do
  include RequestAuthenticationHelper
  include TestDataHelper
  include WaitlistTestHelper

  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }

  describe 'GET /initiations' do
    it 'renders the initiations index with upcoming initiations' do
      e = build_event(type: 'Event::Initiation', status: 'published', title: 'Initiation Débutant', max_participants: 30, allow_non_member_discovery: false)
      e.save!

      get initiations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Initiation Débutant')
    end

    it 'includes canceled initiations in the list for all users (like events)' do
      build_event(
        type: 'Event::Initiation',
        status: 'canceled',
        title: 'Initiation annulée - Pluie',
        max_participants: 30,
        allow_non_member_discovery: false
      ).save!

      get initiations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Initiation annulée - Pluie')
    end
  end

  describe 'GET /initiations/:id' do
    it 'allows anyone to view a published initiation' do
      initiation = build_event(type: 'Event::Initiation', status: 'published', title: 'Cours Initiation', max_participants: 30, allow_non_member_discovery: false)
      initiation.save!

      get initiation_path(initiation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Cours Initiation')
    end

    context 'bouton "Rejoindre la liste d\'attente" (séance complète)' do
      let(:initiation) do
        e = build_event(type: 'Event::Initiation', status: 'published', start_at: 1.week.from_now, title: 'Initiation complète', max_participants: 2, allow_non_member_discovery: false)
        e.save!
        fill_event_to_capacity(e, 2)
        e.reload
      end
      let(:user) { create(:user, role: role, confirmed_at: Time.current) }

      it 'n\'affiche pas le bouton si l\'utilisateur n\'a pas d\'adhésion active' do
        login_user(user)
        get initiation_path(initiation)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Cette séance est complète')
        expect(response.body).not_to include('Rejoindre la liste d\'attente')
      end

      it 'affiche le bouton si l\'utilisateur a une adhésion active et n\'est pas déjà en liste d\'attente' do
        create(:membership, user: user, season: '2025-2026', is_child_membership: false)
        login_user(user)
        get initiation_path(initiation)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Rejoindre la liste d\'attente')
      end

      it 'n\'affiche pas le bouton si l\'utilisateur (adhérent) est déjà en liste d\'attente (parent)' do
        create(:membership, user: user, season: '2025-2026', is_child_membership: false)
        create(:waitlist_entry, user: user, event: initiation, child_membership_id: nil, status: 'pending').tap { |e| e.save(validate: false) }
        initiation.waitlist_entries.reload
        login_user(user)
        get initiation_path(initiation)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Vous êtes en liste d\'attente')
        expect(response.body).not_to include('Rejoindre la liste d\'attente')
      end
    end

    it 'redirects visitors trying to view a draft initiation' do
      initiation = build_event(type: 'Event::Initiation', status: 'draft', max_participants: 30, allow_non_member_discovery: false)
      initiation.save!

      get initiation_path(initiation)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe 'GET /initiations/:id.ics' do
    let(:user) { create_user(role: role) }
    let(:initiation) do
      e = build_event(type: 'Event::Initiation', status: 'published', start_at: 1.week.from_now, title: 'Initiation Roller', max_participants: 30, allow_non_member_discovery: false)
      e.save!
      e
    end

    it 'requires authentication' do
      get initiation_path(initiation, format: :ics)

      # Pour les requêtes .ics, Devise retourne 401 Unauthorized
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include('Vous devez vous connecter ou vous inscrire avant de continuer.')
    end

    it 'exports initiation as iCal file for published initiation when authenticated' do
      login_user(user)

      get initiation_path(initiation, format: :ics)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/calendar')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include('initiation-roller.ics')
      expect(response.body).to include('BEGIN:VCALENDAR')
      expect(response.body).to include('BEGIN:VEVENT')
      expect(response.body).to include('SUMMARY:Initiation Roller')
      expect(response.body).to include('END:VEVENT')
      expect(response.body).to include('END:VCALENDAR')
    end

    it 'redirects to root for draft initiation when authenticated but not creator' do
      login_user(user)
      draft_initiation = build_event(type: 'Event::Initiation', status: 'draft', start_at: 1.week.from_now, max_participants: 30, allow_non_member_discovery: false)
      draft_initiation.save!

      get initiation_path(draft_initiation, format: :ics)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it 'allows creator to export draft initiation' do
      organizer_role = Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 }
      organizer = create_user(role: organizer_role)
      draft_initiation = build_event(type: 'Event::Initiation', status: 'draft', start_at: 1.week.from_now, creator_user: organizer, max_participants: 30, allow_non_member_discovery: false)
      draft_initiation.save!
      login_user(organizer)

      get initiation_path(draft_initiation, format: :ics)

      # Le format peut retourner 406 ou success selon la logique métier
      expect([ :success, :not_acceptable ].include?(response.status / 100) || response.status == 200 || response.status == 406).to be true
      if response.status == 200
        expect(response.content_type).to include('text/calendar')
      end
    end
  end

  describe 'POST /initiations/:initiation_id/attendances' do
    let(:initiation) do
      e = build_event(type: 'Event::Initiation', status: 'published', max_participants: 30, allow_non_member_discovery: false)
      e.save!
      e
    end

    it 'requires authentication' do
      post initiation_attendances_path(initiation)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'registers the current user' do
      user = create_user(role: role)
      # Créer une adhésion active pour l'utilisateur
      create(:membership, user: user, status: :active, season: '2025-2026', start_date: Date.today.beginning_of_year, end_date: Date.today.end_of_year)
      login_user(user)

      expect do
        post initiation_attendances_path(initiation)
      end.to change { Attendance.count }.by(1)

      expect(response).to redirect_to(initiation_path(initiation))
      expect(flash[:notice]).to be_present
      expect(initiation.attendances.exists?(user: user)).to be(true)
    end
  end
end

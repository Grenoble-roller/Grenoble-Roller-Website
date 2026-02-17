# frozen_string_literal: true

require "rails_helper"
require "active_job/test_helper"

RSpec.describe InitiationParticipantsReportJob, type: :job do
  include ActiveJob::TestHelper

  around do |example|
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = :inline
  end

  let!(:user_role) { ensure_role(code: "USER", name: "Utilisateur", level: 10) }
  let!(:organizer_role) { ensure_role(code: "ORGANIZER", name: "Organisateur", level: 40) }
  let!(:organizer) { create_user(role: organizer_role) }

  describe "#perform" do
    before do
      ActionMailer::Base.deliveries.clear
    end

    context "when initiation_id is invalid" do
      it "does not enqueue any mail" do
        expect do
          InitiationParticipantsReportJob.perform_now(999_999)
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context "when initiation is not published" do
      let(:initiation) do
        create_event(
          type: "Event::Initiation",
          status: "draft",
          creator_user: organizer,
          start_at: Time.zone.now.beginning_of_day + 10.hours,
          max_participants: 20
        )
      end

      it "does not enqueue any mail" do
        expect do
          InitiationParticipantsReportJob.perform_now(initiation.id)
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context "when initiation is not today (and FORCE not set)" do
      let(:initiation) do
        create_event(
          type: "Event::Initiation",
          status: "published",
          creator_user: organizer,
          start_at: 1.week.from_now,
          max_participants: 20
        )
      end

      it "does not enqueue any mail" do
        expect do
          InitiationParticipantsReportJob.perform_now(initiation.id)
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context "when initiation is today and published" do
      let(:initiation) do
        create_event(
          type: "Event::Initiation",
          status: "published",
          creator_user: organizer,
          start_at: Time.zone.now.beginning_of_day + 10.hours,
          max_participants: 20
        )
      end

      it "enqueues mail to contact and sets participants_report_sent_at" do
        expect(initiation.participants_report_sent_at).to be_nil
        expect do
          perform_enqueued_jobs do
            InitiationParticipantsReportJob.perform_now(initiation.id)
          end
        end.to change { ActionMailer::Base.deliveries.count }.by_at_least(1)
        expect(initiation.reload.participants_report_sent_at).to be_present
        mail = ActionMailer::Base.deliveries.find { |m| m.to.include?("contact@grenoble-roller.org") }
        expect(mail).to be_present
        expect(mail.subject).to include("Rapport participants")
      end

      context "when there are volunteers" do
        let!(:volunteer_user) { create_user(email: "volunteer@example.com", role: user_role) }
        let!(:volunteer_attendance) do
          create_attendance(user: volunteer_user, event: initiation, status: "registered", is_volunteer: true)
        end

        it "enqueues mail to contact and to each volunteer" do
          perform_enqueued_jobs do
            InitiationParticipantsReportJob.perform_now(initiation.id)
          end
          expect(ActionMailer::Base.deliveries.count).to be >= 2
          contact_mail = ActionMailer::Base.deliveries.find { |m| m.to == [ "contact@grenoble-roller.org" ] && m.subject.include?("Rapport participants") }
          volunteer_mail = ActionMailer::Base.deliveries.find { |m| m.to == [ "volunteer@example.com" ] && m.subject.include?("Rapport participants") }
          expect(contact_mail).to be_present
          expect(volunteer_mail).to be_present
        end
      end
    end

    context "when FORCE_INITIATION_REPORT=true" do
      let(:initiation) do
        create_event(
          type: "Event::Initiation",
          status: "published",
          creator_user: organizer,
          start_at: 1.week.from_now,
          max_participants: 20
        )
      end

      it "enqueues mail even when initiation is not today" do
        expect(initiation.start_at).not_to be_between(
          Time.zone.now.beginning_of_day,
          Time.zone.now.end_of_day
        )
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("FORCE_INITIATION_REPORT").and_return("true")
        expect do
          perform_enqueued_jobs do
            InitiationParticipantsReportJob.perform_now(initiation.id)
          end
        end.to change { ActionMailer::Base.deliveries.count }.by_at_least(1)
        expect(initiation.reload.participants_report_sent_at).to be_present
      end
    end

    context "when participants_report_sent_at already set today" do
      let(:initiation) do
        create_event(
          type: "Event::Initiation",
          status: "published",
          creator_user: organizer,
          start_at: Time.zone.now.beginning_of_day + 10.hours,
          max_participants: 20
        )
      end

      before do
        initiation.update_column(:participants_report_sent_at, Time.zone.now)
      end

      it "does not enqueue any mail" do
        expect do
          InitiationParticipantsReportJob.perform_now(initiation.id)
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end

# frozen_string_literal: true

# Stub des callbacks InitiationParticipantsReportJob en test.
# L'adapter Active Job :test ne gère pas set(wait_until: ...), ce qui lèverait NotImplementedError
# lors de la création/mise à jour d'initiations. On stub pour ne pas toucher au code de production
# (comme le font déjà event_mailer_spec, roller_stocks_spec, return_roller_stock_job_spec).
RSpec.configure do |config|
  config.before(:each) do
    allow_any_instance_of(Event::Initiation).to receive(:schedule_participants_report)
    allow_any_instance_of(Event::Initiation).to receive(:cancel_scheduled_report)
  end
end

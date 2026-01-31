# frozen_string_literal: true

# Publie automatiquement les slides du carrousel dont la date de publication (published_at)
# est atteinte ou dépassée. Exécuté périodiquement via cron (ex. toutes les heures).
class PublishScheduledHomepageCarouselsJob < ApplicationJob
  queue_as :default

  def perform
    count = HomepageCarousel.scheduled_to_publish.update_all(published: true)

    Rails.logger.info("[PublishScheduledHomepageCarouselsJob] #{count} slide(s) publié(s) automatiquement.") if count.positive?
  end
end

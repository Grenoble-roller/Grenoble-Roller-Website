# Job pour remettre automatiquement les rollers en stock après qu'une initiation soit terminée
# Exécuté quotidiennement pour traiter les initiations qui viennent de se terminer
class ReturnRollerStockJob < ApplicationJob
  queue_as :default

  # Remet en stock les rollers pour toutes les initiations terminées
  # qui n'ont pas encore eu leur stock remis en place.
  # Une initiation est "terminée" quand start_at + duration_min <= now.
  def perform
    now = Time.current

    # Toutes les initiations déjà terminées (end_at <= now) et pas encore remises en stock.
    # Pas de fenêtre 24h : on traite tout le passé pour rattraper les oublis et les initiations anciennes.
    finished_initiations = Event::Initiation
      .published
      .where("start_at + INTERVAL '1 minute' * duration_min <= ?", now)
      .where(stock_returned_at: nil)
      .includes(:attendances)

    count_processed = 0
    total_rollers_returned = 0

    finished_initiations.find_each do |initiation|
      # Vérifier qu'il y a des attendances avec matériel prêté
      has_equipment_loaned = initiation.attendances
        .where(needs_equipment: true)
        .where.not(roller_size: nil)
        .where.not(status: "canceled")
        .exists?

      next unless has_equipment_loaned

      # Remettre le stock en place
      rollers_returned = initiation.return_roller_stock
      rollers_returned = 0 if rollers_returned.nil?
      if rollers_returned > 0
        count_processed += 1
        total_rollers_returned += rollers_returned
        Rails.logger.info("[ReturnRollerStockJob] Initiation ##{initiation.id} traitée : #{rollers_returned} roller(s) remis en stock")
      end
    end

    Rails.logger.info("[ReturnRollerStockJob] Traitement terminé : #{count_processed} initiation(s) traitée(s), #{total_rollers_returned} roller(s) remis en stock au total")
  end
end

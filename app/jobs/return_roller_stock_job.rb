# Job pour remettre automatiquement les rollers en stock après qu'une initiation soit terminée
# Exécuté quotidiennement pour traiter les initiations qui viennent de se terminer
class ReturnRollerStockJob < ApplicationJob
  queue_as :default

  # Remet en stock les rollers pour toutes les initiations terminées
  # qui n'ont pas encore eu leur stock remis en place
  def perform
    # Trouver toutes les initiations terminées dans les dernières 24 heures
    # pour éviter de traiter plusieurs fois les mêmes initiations
    # et pour gérer les initiations qui viennent de se terminer
    one_day_ago = 1.day.ago
    now = Time.current

    # Trouver les initiations terminées dans les dernières 24 heures
    # qui n'ont pas encore eu leur stock remis en place (sécurité anti-doublon)
    # On utilise une requête SQL pour calculer end_at = start_at + duration_min minutes
    # On charge aussi les attendances pour éviter les requêtes N+1
    finished_initiations = Event::Initiation
      .published
      .where("start_at >= ?", one_day_ago)
      .where("start_at + INTERVAL '1 minute' * duration_min <= ?", now)
      .where("start_at + INTERVAL '1 minute' * duration_min >= ?", one_day_ago) # Seulement celles terminées dans les dernières 24h
      .where(stock_returned_at: nil) # Sécurité : ne pas retraiter celles déjà traitées
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
      if rollers_returned > 0
        count_processed += 1
        total_rollers_returned += rollers_returned
        Rails.logger.info("[ReturnRollerStockJob] Initiation ##{initiation.id} traitée : #{rollers_returned} roller(s) remis en stock")
      end
    end

    Rails.logger.info("[ReturnRollerStockJob] Traitement terminé : #{count_processed} initiation(s) traitée(s), #{total_rollers_returned} roller(s) remis en stock au total")
  end
end

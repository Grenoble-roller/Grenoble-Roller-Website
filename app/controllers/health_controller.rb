# frozen_string_literal: true

# HealthController - Monitoring avancé avec vérification DB + migrations
#
# Complément de /up (Rails standard) qui vérifie juste que l'app boot.
# Ce endpoint est plus complet mais plus lent (requête DB).
#
# Usage :
# - Monitoring Prometheus/Grafana
# - Alertes PagerDuty/OpsGenie
# - Health checks load balancer avancés
#
# Retourne :
# - 200 OK : Application saine, aucune migration en attente
# - 503 Service Unavailable : Migrations en attente ou DB inaccessible
class HealthController < ApplicationController
  # Pas besoin d'authentification pour les health checks
  skip_before_action :verify_authenticity_token

  # GET /health
  #
  # Exemple de réponse OK :
  # {
  #   "status": "ok",
  #   "database": "connected",
  #   "migrations": {
  #     "pending_count": 0,
  #     "status": "up_to_date"
  #   },
  #   "timestamp": "2025-01-20T10:30:00Z"
  # }
  #
  # Exemple de réponse dégradée :
  # {
  #   "status": "degraded",
  #   "database": "connected",
  #   "migrations": {
  #     "pending_count": 1,
  #     "status": "pending",
  #     "pending_migrations": [
  #       "20251124020634_add_confirmable_to_users"
  #     ]
  #   },
  #   "timestamp": "2025-01-20T10:30:00Z"
  # }
  def check
    health_data = {
      status: "ok",
      database: "unknown",
      migrations: {
        pending_count: 0,
        status: "unknown"
      },
      timestamp: Time.current.iso8601
    }

    # Vérifier la connexion à la base de données
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      health_data[:database] = "connected"
    rescue StandardError => e
      health_data[:database] = "disconnected"
      health_data[:status] = "degraded"
      health_data[:error] = e.message
      render json: health_data, status: :service_unavailable
      return
    end

    # Vérifier les migrations en attente
    begin
      migration_context = ActiveRecord::Base.connection_pool.migration_context
      migrator = migration_context.open
      pending_migrations = migrator.pending_migrations

      health_data[:migrations][:pending_count] = pending_migrations.count

      if pending_migrations.any?
        health_data[:migrations][:status] = "pending"
        health_data[:migrations][:pending_migrations] = pending_migrations.map do |migration|
          {
            version: migration.version,
            name: migration.name,
            filename: migration.filename
          }
        end
        health_data[:status] = "degraded"

        # Retourner 503 pour signaler un problème nécessitant une intervention
        render json: health_data, status: :service_unavailable
        return
      else
        health_data[:migrations][:status] = "up_to_date"
      end
    rescue StandardError => e
      health_data[:migrations][:status] = "error"
      health_data[:migrations][:error] = e.message
      health_data[:status] = "degraded"
      render json: health_data, status: :service_unavailable
      return
    end

    # Tout est OK
    render json: health_data, status: :ok
  end
end

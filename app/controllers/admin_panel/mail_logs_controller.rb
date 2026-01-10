# frozen_string_literal: true

module AdminPanel
  class MailLogsController < BaseController
    # Accès réservé aux SUPERADMIN uniquement (level >= 70)
    before_action :ensure_superadmin

    def index
      # Base query : uniquement les jobs ActionMailer
      @jobs = SolidQueue::Job.where(class_name: "ActionMailer::MailDeliveryJob")
                             .order(created_at: :desc)

      # Filtre par mailer (EventMailer, MembershipMailer, etc.)
      if params[:mailer].present?
        @jobs = @jobs.where("arguments::text LIKE ?", "%#{params[:mailer]}%")
      end

      # Filtre par statut
      case params[:status]
      when "pending"
        @jobs = @jobs.where(finished_at: nil)
      when "finished"
        @jobs = @jobs.where.not(finished_at: nil)
      when "failed"
        @jobs = @jobs.joins("INNER JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id")
                     .distinct
      end

      # Filtre par date (depuis)
      if params[:since].present?
        since_date = Date.parse(params[:since]) rescue nil
        @jobs = @jobs.where("created_at >= ?", since_date.beginning_of_day) if since_date
      end

      # Pagination avec Pagy
      @pagy, @jobs = pagy(@jobs, items: 50)

      # Statistiques pour le header
      base_query = SolidQueue::Job.where(class_name: "ActionMailer::MailDeliveryJob")
      @stats = {
        total: base_query.count,
        pending: base_query.where(finished_at: nil).count,
        finished: base_query.where.not(finished_at: nil).count,
        failed: base_query.joins("INNER JOIN solid_queue_failed_executions ON solid_queue_failed_executions.job_id = solid_queue_jobs.id").count
      }

      # Liste des mailers disponibles pour le filtre
      @available_mailers = extract_mailers_from_jobs
    end

    def show
      @job = SolidQueue::Job.find(params[:id])

      # Vérifier que c'est bien un job ActionMailer
      unless @job.class_name == "ActionMailer::MailDeliveryJob"
        redirect_to admin_panel_mail_logs_path, alert: "Ce job n'est pas un email"
        return
      end

      # Parser les arguments pour extraire les infos du mailer
      @mailer_info = parse_mailer_arguments(@job.arguments)

      # Vérifier s'il y a une erreur
      @failed_execution = SolidQueue::FailedExecution.find_by(job_id: @job.id)
    end

    private

    def ensure_superadmin
      # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
      # Level 70 = SUPERADMIN uniquement
      unless current_user&.role&.level.to_i >= 70
        redirect_to admin_panel_initiations_path, alert: "Accès réservé aux super-administrateurs"
      end
    end

    # Extraire la liste des mailers uniques depuis les jobs
    def extract_mailers_from_jobs
      jobs = SolidQueue::Job.where(class_name: "ActionMailer::MailDeliveryJob")
                           .limit(1000) # Limiter pour performance

      mailers = Set.new
      jobs.find_each do |job|
        mailer_info = parse_mailer_arguments(job.arguments)
        mailers.add(mailer_info[:mailer]) if mailer_info[:mailer]
      end

      mailers.sort
    end

    # Parser les arguments JSON pour extraire mailer et méthode
    # SolidQueue peut stocker les arguments comme String JSON ou déjà désérialisés (Array/Hash)
    # Format ActiveJob: { "arguments": ["MailerClass", "method_name", "deliver_now", {...}] }
    # Format direct: ["MailerClass", "method_name", "deliver_now", {...}]
    def parse_mailer_arguments(arguments_data)
      return { mailer: nil, method: nil, args: [] } if arguments_data.blank?

      begin
        # Parser si c'est une String JSON
        parsed_data = if arguments_data.is_a?(String)
          JSON.parse(arguments_data)
        else
          arguments_data
        end

        # Si c'est un Hash avec la clé "arguments" (format ActiveJob)
        if parsed_data.is_a?(Hash) && parsed_data["arguments"].is_a?(Array)
          args = parsed_data["arguments"]
        # Si c'est directement un Array
        elsif parsed_data.is_a?(Array)
          args = parsed_data
        else
          return { mailer: nil, method: nil, args: [] }
        end

        # Format ActionMailer::MailDeliveryJob arguments:
        # ["MailerClass", "method_name", "deliver_now", {...}]
        # ou ["MailerClass", "method_name", "deliver_later", {...}]
        if args.is_a?(Array) && args.length >= 2
          mailer_class = args[0]
          method_name = args[1]

          return {
            mailer: mailer_class,
            method: method_name,
            args: args[2..-1] || []
          }
        end
      rescue JSON::ParserError => e
        Rails.logger.error("Failed to parse mailer arguments: #{e.message}")
      rescue => e
        Rails.logger.error("Error parsing mailer arguments: #{e.class} - #{e.message}")
        Rails.logger.error("Arguments data: #{arguments_data.inspect[0..200]}")
      end

      { mailer: nil, method: nil, args: [] }
    end
  end
end

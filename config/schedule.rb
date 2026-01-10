# Use this file to define cron jobs with Whenever
# Learn more: http://github.com/javan/whenever

set :output, "log/cron.log"
set :environment, :production

# Sync HelloAsso payments toutes les 5 minutes
every 5.minutes do
  runner 'Rails.application.load_tasks; Rake::Task["helloasso:sync_payments"].invoke'
end

# Job de rappel la veille à 19h pour les événements du lendemain
every 1.day, at: "7:00 pm" do
  runner "EventReminderJob.perform_now"
end

# Rapport participants initiation (tous les jours à 7h, uniquement en production)
# Note: La vérification de l'environnement se fait dans le job lui-même
# pour éviter les problèmes de chargement de Rails lors de la génération du crontab
every 1.day, at: "7:00 am" do
  runner "InitiationParticipantsReportJob.perform_now"
end

# Mettre à jour les adhésions expirées (tous les jours à minuit)
every 1.day, at: "12:00 am" do
  runner 'Rails.application.load_tasks; Rake::Task["memberships:update_expired"].invoke'
end

# Envoyer les rappels de renouvellement (tous les jours à 9h)
every 1.day, at: "9:00 am" do
  runner 'Rails.application.load_tasks; Rake::Task["memberships:send_renewal_reminders"].invoke'
end

# Remettre les rollers en stock après les initiations terminées (tous les jours à 2h du matin)
# DÉSACTIVÉ : Le retour de matériel se fait maintenant manuellement via le bouton "Matériel rendu" dans la page Présences
# every 1.day, at: "2:00 am" do
#   runner "ReturnRollerStockJob.perform_now"
# end

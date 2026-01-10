class User < ApplicationRecord
  include Hashid::Rails

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable, :confirmable
  # Relation avec Role
  belongs_to :role
  has_many :orders, dependent: :nullify
  has_many :memberships, dependent: :destroy

  # Active Storage attachments
  has_one_attached :avatar

  # Phase 2 - Events associations
  has_many :created_events, class_name: "Event", foreign_key: "creator_user_id", dependent: :restrict_with_error
  has_many :attendances, dependent: :destroy
  has_many :events, through: :attendances

  # Phase 2 - Organizer applications
  has_many :organizer_applications, dependent: :destroy
  has_many :reviewed_applications, class_name: "OrganizerApplication", foreign_key: "reviewed_by_id", dependent: :nullify

  # Phase 2 - Audit logs
  has_many :audit_logs, class_name: "AuditLog", foreign_key: "actor_user_id", dependent: :nullify

  before_validation :set_default_role, on: :create
  after_create :send_welcome_email_and_confirmation

  # Validation pour empêcher l'assignation de rôles supérieurs
  # Cette validation est complémentaire aux vérifications dans les controllers
  # Elle utilise un contexte pour recevoir l'utilisateur qui fait la modification
  # Ne s'applique que si assigner_user est défini (dans les controllers)
  validate :role_level_not_higher_than_assigner, if: -> { role_id_changed? && role_id.present? && assigner_user.present? }

  # Bloquer l'authentification si l'email n'est pas confirmé
  # En développement/test, on permet quand même pour faciliter les tests
  def active_for_authentication?
    return super if Rails.env.development? || Rails.env.test?
    super && confirmed?
  end

  # Message personnalisé si compte non actif
  def inactive_message
    if !confirmed?
      :unconfirmed_email
    else
      super
    end
  end

  # Formater le nom pour l'affichage public (prénom + première lettre du nom)
  # Exemple: "Florian A." au lieu de "Florian Astier"
  def display_name
    return first_name if last_name.blank?
    "#{first_name} #{last_name.first.upcase}."
  end

  # Méthode utilisée par Active Admin pour afficher l'utilisateur
  # Affiche "Prénom Nom" pour faciliter l'identification (prêts de rollers, etc.)
  def to_s
    if first_name.present? && last_name.present?
      "#{first_name} #{last_name}"
    elsif first_name.present?
      first_name
    elsif last_name.present?
      last_name
    else
      email # Fallback sur email si pas de nom/prénom
    end
  end

  # Vérifier si le token de confirmation est expiré
  def confirmation_token_expired?
    return false if confirmed_at.present?
    return false unless confirmation_sent_at.present?
    return false unless Devise.confirm_within

    confirmation_sent_at < Devise.confirm_within.ago
  end

  # Skill levels disponibles
  SKILL_LEVELS = %w[beginner intermediate advanced].freeze

  # Validations: skill_level obligatoire à l'inscription
  validates :skill_level, presence: true, inclusion: { in: SKILL_LEVELS }

  # Validations: prénom obligatoire (important pour personnaliser les événements)
  validates :first_name, presence: true, length: { maximum: 50 }
  # Validation téléphone : uniquement 10 chiffres (format français) et doit commencer par 0
  validates :phone, format: { with: /\A[0-9]{10}\z/, message: "doit contenir exactement 10 chiffres (ex: 0612345678)" }, allow_blank: true
  validate :phone_must_start_with_zero, if: -> { phone.present? }

  # Normaliser le téléphone avant validation (enlever espaces, tirets, etc.)
  before_validation :normalize_phone, if: :phone_changed?

  def self.ransackable_attributes(_auth_object = nil)
    %w[id email unconfirmed_email first_name last_name phone role_id created_at updated_at confirmed_at date_of_birth city address postal_code can_be_volunteer]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[orders created_events attendances events organizer_applications reviewed_applications audit_logs role memberships]
  end

  # Helpers pour vérifier adhésion active
  def has_active_membership?
    memberships.personal.active_now.exists?
  end

  # Obtenir l'adhésion active actuelle (personnelle)
  def current_membership
    memberships.personal.active_now.order(start_date: :desc).first
  end

  # Obtenir toutes les adhésions enfants actives
  def active_children_memberships
    memberships.children.active_now.order(created_at: :desc)
  end

  # Vérifier si l'utilisateur a des adhésions enfants actives
  def has_active_children_memberships?
    active_children_memberships.exists?
  end

  # Profil parent complet pour pouvoir créer une adhésion enfant
  # Champs requis : prénom, nom, téléphone, adresse complète (adresse, code postal, ville) + date de naissance
  REQUIRED_CHILD_PROFILE_FIELDS = %i[
    first_name
    last_name
    phone
    address
    postal_code
    city
    date_of_birth
  ].freeze

  def child_profile_complete_for_membership?
    REQUIRED_CHILD_PROFILE_FIELDS.all? { |attr| self.send(attr).present? }
  end

  def missing_child_profile_fields_for_membership
    REQUIRED_CHILD_PROFILE_FIELDS.select { |attr| self.send(attr).blank? }
  end

  # Obtenir toutes les adhésions (personnelle + enfants)
  def all_active_memberships
    memberships.active_now.order(is_child_membership: :asc, created_at: :desc)
  end

  # Vérifier si l'utilisateur peut être bénévole
  def can_be_volunteer?
    can_be_volunteer == true
  end

  # Calculer l'âge de l'utilisateur
  def age
    return nil unless date_of_birth.present?
    ((Date.today - date_of_birth) / 365.25).floor
  end

  # Vérifier si l'utilisateur est mineur
  def is_minor?
    return false unless date_of_birth.present?
    age < 18
  end

  # Vérifier si l'utilisateur est un enfant (< 16 ans)
  def is_child?
    return false unless date_of_birth.present?
    age < 16
  end

  # Attribut virtuel pour stocker l'utilisateur qui fait la modification (utilisé pour la validation)
  attr_accessor :assigner_user

  private

  def set_default_role
    # Priorité au code stable, fallback sur un libellé courant
    self.role ||= Role.find_by(code: "USER") || Role.find_by(name: "Utilisateur") || Role.first
  end

  def role_level_not_higher_than_assigner
    return unless assigner_user
    return unless assigner_user.role&.level
    return unless role&.level

    # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
    assigner_level = assigner_user.role.level.to_i
    new_role_level = role.level.to_i

    # Si le nouveau rôle est supérieur au rôle de l'assigneur, c'est une erreur
    if new_role_level > assigner_level
      errors.add(:role_id, "Vous ne pouvez pas assigner un rôle supérieur au vôtre")
    end
  end

  def normalize_phone
    return if phone.blank?
    # Enlever tous les caractères non numériques
    self.phone = phone.gsub(/[^0-9]/, "")
    # Si le numéro commence par +33, remplacer par 0
    self.phone = "0#{phone[2..-1]}" if phone.start_with?("33") && phone.length == 11
    # Si le numéro commence par 0033, remplacer par 0
    self.phone = "0#{phone[3..-1]}" if phone.start_with?("0033") && phone.length == 12
    # Limiter à 10 chiffres maximum
    self.phone = phone[0..9] if phone.length > 10
  end

  def phone_must_start_with_zero
    return if phone.blank?

    # Vérifier que le numéro normalisé commence par 0
    unless phone.start_with?("0")
      errors.add(:phone, "doit commencer par 0 (format français, ex: 0612345678)")
    end
  end

  def send_welcome_email_and_confirmation
    # Envoyer uniquement l'email de bienvenue
    # Devise envoie automatiquement l'email de confirmation via :confirmable
    # Il ne faut donc PAS appeler send_confirmation_instructions ici
    UserMailer.welcome_email(self).deliver_later
  end
end

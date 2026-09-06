class Membership < ApplicationRecord
  include Hashid::Rails
  include Auditable
include Auditable

  belongs_to :user
  belongs_to :payment, optional: true
  belongs_to :tshirt_variant, class_name: "ProductVariant", optional: true

  # Certificat médical (si requis par le questionnaire de santé)
  has_one_attached :medical_certificate

  enum :status, {
    pending: 0,
    active: 1,
    expired: 2,
    trial: 3  # Essai gratuit (uniquement pour enfants)
  }

  enum :category, {
    standard: 0,    # 10€ - Cotisation Adhérent Grenoble Roller
    with_ffrs: 1    # 56.55€ - Cotisation + Licence FFRS
  }

  enum :health_questionnaire_status, {
    ok: "ok",
    medical_required: "medical_required"
  }

  # Validation : un utilisateur ne peut avoir qu'une adhésion personnelle par saison
  # Mais peut avoir plusieurs adhésions enfants
  validate :unique_personal_membership_per_season
  # Pour les essais gratuits (trial), on n'exige pas les dates et montants
  validates :start_date, :end_date, :amount_cents, :category, presence: true, unless: -> { status == "trial" }
  validates :start_date, comparison: { less_than: :end_date }, if: -> { start_date.present? && end_date.present? }

  # Validations pour adhésions enfants
  validates :child_first_name, :child_last_name, :child_date_of_birth, presence: true, if: :is_child_membership?
  validates :parent_authorization, inclusion: { in: [ true ] }, if: -> { is_child_membership? && child_age < 16 }

  # Validation : trial uniquement pour les enfants
  validate :trial_only_for_children

  # Scopes
  scope :active_now, -> { active.where("end_date > ?", Date.current) }
  scope :expiring_soon, -> { active.where("end_date BETWEEN ? AND ?", Date.current, 30.days.from_now) }
  scope :pending_payment, -> { pending }
  scope :personal, -> { where(is_child_membership: false) }
  scope :children, -> { where(is_child_membership: true) }
  scope :goodies_pending, -> { where(goodies_distributed: false) }

  # Ransack pour ActiveAdmin
  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id payment_id tshirt_variant_id category status season start_date end_date
       amount_cents currency is_child_membership is_minor child_first_name child_last_name
       child_date_of_birth parent_authorization parent_authorization_date parent_name
       parent_email parent_phone rgpd_consent legal_notices_accepted ffrs_data_sharing_consent
       health_questionnaire_status health_q1 health_q2 health_q3 health_q4 health_q5
       health_q6 health_q7 health_q8 health_q9 goodies_distributed created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[medical_certificate_attachment medical_certificate_blob payment tshirt_variant user]
  end

  # Calcul automatique du prix selon la catégorie
  def self.price_for_category(category)
    case category.to_s
    when "standard" then 1000      # 10€ en centimes
    when "with_ffrs" then 5655      # 56.55€ en centimes
    else 0
    end
  end

  # Calculer le prix total (adhésion + T-shirt si présent)
  def total_amount_cents
    base = amount_cents || 0

    # Nouveau système simplifié : with_tshirt + tshirt_qty
    if with_tshirt && tshirt_qty.to_i > 0
      tshirt_total = tshirt_qty.to_i * 1400 # 14€ par T-shirt
      return base + tshirt_total
    end

    # Ancien système (rétrocompatibilité) : tshirt_variant_id
    if tshirt_variant_id.present?
      tshirt = tshirt_price_cents || 1400
      return base + tshirt
    end

    base
  end

  # Vérifie si le questionnaire de santé est complètement rempli (toutes les 9 questions)
  def health_questionnaire_complete?
    (1..9).all? { |i| send("health_q#{i}").present? }
  end

  # Season calendar: 1 Sep – 31 Aug.
  # Next season sales open 1 Aug (aligned with J-30 renewal reminder emails).
  NEXT_SEASON_SALE_OPENS_MONTH = 8
  NEXT_SEASON_SALE_OPENS_DAY = 1

  # Running season (calendar): which season we are in today (initiations, active checks).
  def self.current_season_dates(on = Date.current)
    running_season_dates(on)
  end

  def self.current_season_name(on = Date.current)
    season_name_for_start_year(season_start_year_for_running(on))
  end

  # Sale season: which season new memberships / cart lines use (opens next season from 1 Aug).
  def self.sale_season_dates(on = Date.current)
    dates_for_season_start_year(season_start_year_for_sale(on))
  end

  def self.sale_season_name(on = Date.current)
    season_name_for_start_year(season_start_year_for_sale(on))
  end

  def self.season_start_year_for_running(on)
    on >= Date.new(on.year, 9, 1) ? on.year : on.year - 1
  end

  def self.season_start_year_for_sale(on)
    if on >= Date.new(on.year, 9, 1)
      on.year
    elsif on >= Date.new(on.year, NEXT_SEASON_SALE_OPENS_MONTH, NEXT_SEASON_SALE_OPENS_DAY)
      on.year
    else
      season_start_year_for_running(on)
    end
  end

  def self.dates_for_season_start_year(start_year)
    [ Date.new(start_year, 9, 1), Date.new(start_year + 1, 8, 31) ]
  end

  def self.season_name_for_start_year(start_year)
    start_date, end_date = dates_for_season_start_year(start_year)
    "#{start_date.year}-#{end_date.year}"
  end

  def self.running_season_dates(on = Date.current)
    dates_for_season_start_year(season_start_year_for_running(on))
  end

  def align_to_sale_season!
    return unless pending? || trial?

    expected_start, expected_end = self.class.sale_season_dates
    expected_season = self.class.sale_season_name
    return if season == expected_season && start_date == expected_start && end_date == expected_end

    update!(
      season: expected_season,
      start_date: expected_start,
      end_date: expected_end
    )
  end

  def sale_season_aligned?
    expected_start, expected_end = self.class.sale_season_dates
    season == self.class.sale_season_name &&
      start_date == expected_start &&
      end_date == expected_end
  end

  # Callback pour mettre à jour le statut après paiement et envoyer les emails
  after_update :activate_if_paid, if: :saved_change_to_status?

  # Vérifier si l'adhésion est active (payée ET dans la période de validité)
  def active?
    status == "active" && end_date >= Date.current
  end

  # Vérifier si l'adhésion est expirée
  # Note: Les adhésions pending ou trial ne sont jamais considérées comme expirées, même si end_date est dans le passé
  def expired?
    return false if pending? || trial? # Les adhésions en attente ou en essai ne sont jamais expirées
    return false unless end_date.present? # Pas de date = pas expirée
    end_date < Date.current
  end

  # True when the member can start next-season renewal (expired, or active within 30 days of end).
  # Hidden once a paid/pending sale-season membership already exists for the same person.
  # Trial alone does not count (child may still upgrade to a paid renewal).
  def renewable_now?
    return false if successor_sale_season_membership?
    return true if expired?
    return false unless status == "active" && end_date.present?

    end_date <= 30.days.from_now.to_date
  end

  # Paid sale-season membership already created for this adult / child (active or pending payment).
  def successor_sale_season_membership?
    return false unless user_id.present?

    sale = self.class.sale_season_name
    return false if season == sale

    scope = user.memberships.where(season: sale).where(status: [ :active, :pending ])
    if is_child_membership?
      scope.where(
        is_child_membership: true,
        child_first_name: child_first_name,
        child_last_name: child_last_name,
        child_date_of_birth: child_date_of_birth
      ).exists?
    else
      scope.personal.exists?
    end
  end

  # Form type for renewal links (email CTA, index/show buttons).
  def renewal_form_type
    return "child" if is_child_membership?

    user_age = user&.age
    user_age.present? && user_age < 18 ? "teen" : "adult"
  end

  # Méthode publique pour vérifier si c'est une adhésion enfant
  def is_child_membership?
    is_child_membership == true
  end

  # Nom complet de l'enfant
  def child_full_name
    return nil unless is_child_membership?
    "#{child_first_name} #{child_last_name}".strip
  end

  # Calculer l'âge de l'enfant
  def child_age
    return 0 unless child_date_of_birth.present?
    ((Date.today - child_date_of_birth) / 365.25).floor
  end

  private

  def trial_only_for_children
    if status == "trial" && !is_child_membership?
      errors.add(:status, "Le statut 'trial' est uniquement disponible pour les adhésions enfants")
    end
  end

  def unique_personal_membership_per_season
    return if is_child_membership? # Pas de validation pour les enfants
    return if status == "trial" # Les essais gratuits ne sont pas concernés par cette validation

    existing = Membership.where(
      user_id: user_id,
      season: season,
      is_child_membership: false
    ).where.not(id: id)

    # Empêcher plusieurs adhésions pending pour la même saison
    if status == "pending" && existing.where(status: "pending").exists?
      errors.add(:base, "Vous avez déjà une adhésion en attente de paiement pour cette saison")
      return
    end

    # Empêcher une nouvelle adhésion si une adhésion active existe déjà
    if existing.where(status: "active").where("end_date > ?", Date.current).exists?
      errors.add(:base, "Vous avez déjà une adhésion active pour cette saison")
      nil
    end
  end

  def activate_if_paid
    # Si le statut vient de passer à 'active', envoyer l'email
    if status == "active" && saved_change_to_status? && saved_change_to_status[0] == "pending"
      MembershipMailer.activated(self).deliver_later
    end
  end

    # Auditable concern methods
    def audit_actor
      user
    end

    def audit_attributes
      {
        user_id: user_id,
        payment_id: payment_id,
        tshirt_variant_id: tshirt_variant_id,
        status: status,
        category: category,
        season: season,
        start_date: start_date,
        end_date: end_date,
        amount_cents: amount_cents,
        currency: currency,
        is_child_membership: is_child_membership,
        child_first_name: child_first_name,
        child_last_name: child_last_name,
        child_date_of_birth: child_date_of_birth,
        parent_authorization: parent_authorization,
        rgpd_consent: rgpd_consent,
        legal_notices_accepted: legal_notices_accepted,
        ffrs_data_sharing_consent: ffrs_data_sharing_consent,
        health_questionnaire_status: health_questionnaire_status,
        goodies_distributed: goodies_distributed
      }
    end

  # Calculer les jours restants avant expiration
  def days_until_expiry
    return 0 if expired?
    (end_date - Date.current).to_i
  end

  # Vérifier si l'adhésion est pour un mineur
  def is_minor?
    if is_child_membership?
      return false unless child_date_of_birth.present?
      child_age < 18
    else
      return false unless user.date_of_birth.present?
      age = ((Date.today - user.date_of_birth) / 365.25).floor
      age < 18
    end
  end

  # Vérifier si l'adhésion nécessite une autorisation parentale
  def requires_parent_authorization?
    if is_child_membership?
      return false unless child_date_of_birth.present?
      child_age < 16
    else
      return false unless user.date_of_birth.present?
      age = ((Date.today - user.date_of_birth) / 365.25).floor
      age < 16
    end
  end
end

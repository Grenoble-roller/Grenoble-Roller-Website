require 'securerandom'

module TestDataHelper
  def ensure_role(code: 'USER', name: nil, level: 10)
    Role.find_or_create_by!(code: code) do |role|
      role.name = name || code.capitalize
      role.level = level
    end
  end

  def build_user(attrs = {})
    role = attrs.delete(:role) || ensure_role(code: 'USER', name: 'User', level: 10)
    defaults = {
      first_name: 'Alex',
      last_name: 'Rider',
      email: "user#{SecureRandom.hex(4)}@example.com",
      password: 'password12345',
      skill_level: 'intermediate',
      role: role
    }

    User.new(defaults.merge(attrs))
  end

  def create_user(attrs = {})
    user = build_user(attrs)
    user.save!
    user
  end

  def build_route(attrs = {})
    defaults = {
      name: 'Boucle Bastille',
      difficulty: 'easy',
      distance_km: 12.5,
      elevation_m: 150
    }
    Route.new(defaults.merge(attrs))
  end

  def create_route(attrs = {})
    route = build_route(attrs)
    route.save!
    route
  end

  def build_event(attrs = {})
    creator = attrs.delete(:creator_user) || create_user
    route   = attrs.key?(:route) ? attrs.delete(:route) : create_route
    type = attrs.delete(:type) || 'Event'

    defaults = {
      creator_user: creator,
      route: route,
      status: 'draft',
      start_at: 2.days.from_now,
      duration_min: 60,
      title: 'Evening Ride',
      description: 'An engaging rollerblading event description.',
      price_cents: 0,
      currency: 'EUR',
      location_text: 'Grenoble City Center',
      level: 'beginner',
      distance_km: 10.0
    }

    event_class = type.constantize
    event_class.new(defaults.merge(attrs))
  end

  def create_event(attrs = {})
    event = build_event(attrs)
    event.save!
    event
  end

  def build_attendance(attrs = {})
    user = attrs.delete(:user) || create_user
    event = attrs.delete(:event) || create_event

    defaults = {
      user: user,
      event: event,
      status: 'registered',
      stripe_customer_id: 'cus_123',
      free_trial_used: false # Ensure default doesn't bypass validation
    }
    Attendance.new(defaults.merge(attrs))
  end

  def create_attendance(attrs = {})
    attendance = build_attendance(attrs)
    attendance.save!
    attendance
  end

  def create_active_membership(user, attrs = {})
    create(:membership, {
      user: user,
      status: :active,
      category: :standard,
      start_date: 1.month.ago,
      end_date: 1.year.from_now,
      season: '2025-2026'
    }.merge(attrs))
  end
end

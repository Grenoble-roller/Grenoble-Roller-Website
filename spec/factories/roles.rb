FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    sequence(:code) { |n| "ROLE_#{n}_#{SecureRandom.hex(2)}" }
    level { 10 }

    # Factories pour les rôles standards (codes fixes)
    factory :role_user do
      code { 'USER' }
      name { 'Utilisateur' }
      level { 10 }
    end

    factory :role_initiation do
      code { 'INITIATION' }
      name { 'Initiation' }
      level { 30 }
    end

    factory :role_organizer do
      code { 'ORGANIZER' }
      name { 'Organisateur' }
      level { 40 }
    end

    factory :role_moderator do
      code { 'MODERATOR' }
      name { 'Modérateur' }
      level { 50 }
    end

    factory :role_admin do
      code { 'ADMIN' }
      name { 'Administrateur' }
      level { 60 }
    end

    factory :role_superadmin do
      code { 'SUPERADMIN' }
      name { 'Super Administrateur' }
      level { 70 }
    end

    # Traits pour compatibilité avec le code existant
    trait :initiation do
      code { 'INITIATION' }
      name { 'Initiation' }
      level { 30 }
    end

    trait :organizer do
      code { 'ORGANIZER' }
      name { 'Organisateur' }
      level { 40 }
    end

    trait :moderator do
      code { 'MODERATOR' }
      name { 'Modérateur' }
      level { 50 }
    end

    trait :admin do
      code { 'ADMIN' }
      name { 'Administrateur' }
      level { 60 }
    end

    trait :superadmin do
      code { 'SUPERADMIN' }
      name { 'Super Administrateur' }
      level { 70 }
    end
  end
end

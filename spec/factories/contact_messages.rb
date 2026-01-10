# frozen_string_literal: true

FactoryBot.define do
  factory :contact_message do
    sequence(:name) { |n| "Contact #{n}" }
    sequence(:email) { |n| "contact#{n}@example.com" }
    sequence(:subject) { |n| "Sujet du message #{n}" }
    sequence(:message) { |n| "Message de contact numéro #{n}. Ceci est un message de test avec suffisamment de caractères pour valider." }
  end
end

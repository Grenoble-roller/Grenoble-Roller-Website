# frozen_string_literal: true

class NotificationEventRegistry
  EventDefinition = Data.define(:key, :label, :group, :default_on, :builder)

  GROUPS = {
    "paiements" => "Paiements & HelloAsso",
    "entrant" => "Entrant public",
    "candidatures" => "Candidatures organisateur",
    "boutique" => "Boutique",
    "adhesions" => "Adhésions",
    "evenements" => "Événements & randos",
    "initiations" => "Initiations & stock rollers",
    "homepage" => "Page d'accueil & partenaires",
    "utilisateurs" => "Utilisateurs & système",
    "meta" => "Meta"
  }.freeze

  class << self
    def all
      @all ||= build_registry.freeze
    end

    def event_keys
      all.map(&:key)
    end

    def find(key)
      all_by_key[key.to_s]
    end

    def default_on_keys
      all.select(&:default_on).map(&:key)
    end

    def grouped
      all.group_by(&:group)
    end

    def build_payload(event_key, source:, actor: nil)
      definition = find(event_key)
      return nil unless definition

      definition.builder.call(source, actor: actor)
    end

    private

    def all_by_key
      @all_by_key ||= all.index_by(&:key)
    end

    def build_registry
      [
        # Paiements & HelloAsso
        event("order.paid", "Nouvelle commande payée", "paiements", true) { |order, **| order_paid_payload(order) },
        event("membership.activated", "Adhésion activée", "paiements", true) { |membership, **| membership_activated_payload(membership) },
        event("event_registration.paid", "Inscription rando payée", "paiements", true) { |attendance, **| event_registration_paid_payload(attendance) },
        event("membership.activated_manual", "Adhésion activée (manuel)", "paiements", false) { |membership, actor:, **| membership_activated_manual_payload(membership, actor) },
        event("order.paid_manual", "Commande payée (manuel)", "paiements", false) { |order, actor:, **| order_paid_manual_payload(order, actor) },
        event("payment.failed", "Paiement échoué", "paiements", false) { |payment, **| payment_failed_payload(payment) },
        event("payment.abandoned", "Paiement abandonné", "paiements", false) { |payment, **| payment_abandoned_payload(payment) },
        event("membership.payment_failed", "Échec paiement adhésion", "paiements", false) { |membership, **| membership_payment_failed_payload(membership) },

        # Entrant public
        event("contact_message.received", "Nouveau message contact", "entrant", true) { |msg, **| contact_message_received_payload(msg) },
        event("organizer_application.submitted", "Candidature organisateur", "entrant", true) { |app, **| organizer_application_submitted_payload(app) },
        event("user.registered", "Nouveau compte utilisateur", "entrant", false) { |user, **| user_registered_payload(user) },

        # Candidatures organisateur
        event("organizer_application.approved", "Candidature approuvée", "candidatures", false) { |app, actor:, **| organizer_application_approved_payload(app, actor) },
        event("organizer_application.rejected", "Candidature refusée", "candidatures", false) { |app, actor:, **| organizer_application_rejected_payload(app, actor) },

        # Boutique
        event("order.created", "Commande créée", "boutique", false) { |order, **| order_created_payload(order) },
        event("order.updated", "Commande modifiée", "boutique", false) { |order, actor:, **| order_updated_payload(order, actor) },
        event("order.status_changed", "Statut commande modifié", "boutique", false) { |order, **| order_status_changed_payload(order) },
        event("product.created", "Produit créé", "boutique", false) { |product, actor:, **| product_created_payload(product, actor) },
        event("product.updated", "Produit modifié", "boutique", false) { |product, actor:, **| product_updated_payload(product, actor) },
        event("product.destroyed", "Produit supprimé", "boutique", false) { |product, actor:, **| product_destroyed_payload(product, actor) },
        event("product_variant.created", "Variante créée", "boutique", false) { |variant, actor:, **| product_variant_created_payload(variant, actor) },
        event("product_variant.updated", "Variante modifiée", "boutique", false) { |variant, actor:, **| product_variant_updated_payload(variant, actor) },
        event("product_variant.destroyed", "Variante supprimée", "boutique", false) { |variant, actor:, **| product_variant_destroyed_payload(variant, actor) },
        event("product_variant.status_toggled", "Variante activée/désactivée", "boutique", false) { |variant, actor:, **| product_variant_status_toggled_payload(variant, actor) },

        # Adhésions
        event("membership.created", "Adhésion créée", "adhesions", false) { |membership, **| membership_created_payload(membership) },
        event("membership.updated", "Adhésion modifiée", "adhesions", false) { |membership, actor:, **| membership_updated_payload(membership, actor) },
        event("membership.destroyed", "Adhésion supprimée", "adhesions", false) { |membership, actor:, **| membership_destroyed_payload(membership, actor) },

        # Événements & randos
        event("event.cancelled", "Événement annulé", "evenements", false) { |event, actor:, **| event_cancelled_payload(event, actor) },
        event("event.destroyed", "Événement supprimé", "evenements", false) { |event, actor:, **| event_destroyed_payload(event, actor) },
        event("event.waitlist_notified", "Liste d'attente notifiée", "evenements", false) { |event, **| event_waitlist_notified_payload(event) },
        event("event.waitlist_converted", "Liste d'attente convertie", "evenements", false) { |event, **| event_waitlist_converted_payload(event) },
        event("attendance.created", "Inscription créée", "evenements", false) { |attendance, actor:, **| attendance_created_payload(attendance, actor) },
        event("attendance.updated", "Inscription modifiée", "evenements", false) { |attendance, actor:, **| attendance_updated_payload(attendance, actor) },
        event("attendance.destroyed", "Inscription supprimée", "evenements", false) { |attendance, actor:, **| attendance_destroyed_payload(attendance, actor) },
        event("route.created", "Parcours créé", "evenements", false) { |route, actor:, **| route_created_payload(route, actor) },
        event("route.updated", "Parcours modifié", "evenements", false) { |route, actor:, **| route_updated_payload(route, actor) },
        event("route.destroyed", "Parcours supprimé", "evenements", false) { |route, actor:, **| route_destroyed_payload(route, actor) },
        event("event_organizer.created", "Organisateur créé", "evenements", false) { |organizer, actor:, **| event_organizer_created_payload(organizer, actor) },
        event("event_organizer.updated", "Organisateur modifié", "evenements", false) { |organizer, actor:, **| event_organizer_updated_payload(organizer, actor) },
        event("event_organizer.destroyed", "Organisateur supprimé", "evenements", false) { |organizer, actor:, **| event_organizer_destroyed_payload(organizer, actor) },

        # Initiations & stock rollers
        event("initiation.presences_updated", "Présences initiation mises à jour", "initiations", false) { |event, actor:, **| initiation_presences_updated_payload(event, actor) },
        event("initiation.volunteer_toggled", "Bénévole basculé", "initiations", false) { |attendance, actor:, **| initiation_volunteer_toggled_payload(attendance, actor) },
        event("initiation.waitlist_notified", "Liste d'attente initiation notifiée", "initiations", false) { |event, **| initiation_waitlist_notified_payload(event) },
        event("initiation.waitlist_converted", "Liste d'attente initiation convertie", "initiations", false) { |event, **| initiation_waitlist_converted_payload(event) },
        event("initiation.material_returned", "Matériel retourné", "initiations", false) { |event, actor:, **| initiation_material_returned_payload(event, actor) },
        event("roller_stock.created", "Stock roller créé", "initiations", false) { |stock, actor:, **| roller_stock_created_payload(stock, actor) },
        event("roller_stock.updated", "Stock roller modifié", "initiations", false) { |stock, actor:, **| roller_stock_updated_payload(stock, actor) },
        event("roller_stock.destroyed", "Stock roller supprimé", "initiations", false) { |stock, actor:, **| roller_stock_destroyed_payload(stock, actor) },
        event("roller_stock.return_all", "Prêts rollers clôturés", "initiations", false) { |source, actor:, **| roller_stock_return_all_payload(source, actor) },

        # Page d'accueil & partenaires
        event("homepage_carousel.created", "Slide carousel créée", "homepage", false) { |slide, actor:, **| homepage_carousel_created_payload(slide, actor) },
        event("homepage_carousel.updated", "Slide carousel modifiée", "homepage", false) { |slide, actor:, **| homepage_carousel_updated_payload(slide, actor) },
        event("homepage_carousel.destroyed", "Slide carousel supprimée", "homepage", false) { |slide, actor:, **| homepage_carousel_destroyed_payload(slide, actor) },
        event("homepage_carousel.settings_updated", "Paramètres carousel modifiés", "homepage", false) { |settings, actor:, **| homepage_carousel_settings_updated_payload(settings, actor) },
        event("partner.created", "Partenaire créé", "homepage", false) { |partner, actor:, **| partner_created_payload(partner, actor) },
        event("partner.updated", "Partenaire modifié", "homepage", false) { |partner, actor:, **| partner_updated_payload(partner, actor) },
        event("partner.destroyed", "Partenaire supprimé", "homepage", false) { |partner, actor:, **| partner_destroyed_payload(partner, actor) },

        # Utilisateurs & système
        event("user.created", "Utilisateur créé (admin)", "utilisateurs", false) { |user, actor:, **| user_created_payload(user, actor) },
        event("user.updated", "Utilisateur modifié", "utilisateurs", false) { |user, actor:, **| user_updated_payload(user, actor) },
        event("user.destroyed", "Utilisateur supprimé", "utilisateurs", false) { |user, actor:, **| user_destroyed_payload(user, actor) },
        event("role.created", "Rôle créé", "utilisateurs", false) { |role, actor:, **| role_created_payload(role, actor) },
        event("role.updated", "Rôle modifié", "utilisateurs", false) { |role, actor:, **| role_updated_payload(role, actor) },
        event("role.destroyed", "Rôle supprimé", "utilisateurs", false) { |role, actor:, **| role_destroyed_payload(role, actor) },
        event("maintenance.toggled", "Mode maintenance basculé", "utilisateurs", false) { |_, **| maintenance_toggled_payload },
        event("payment.destroyed", "Paiement supprimé", "utilisateurs", false) { |payment, actor:, **| payment_destroyed_payload(payment, actor) },
        event("contact_message.destroyed", "Message contact supprimé", "utilisateurs", false) { |msg, actor:, **| contact_message_destroyed_payload(msg, actor) },

        # Meta
        event("test.ping", "Test notification", "meta", false) { |channel, **| test_ping_payload(channel) }
      ]
    end

    def event(key, label, group, default_on, &builder)
      EventDefinition.new(key: key, label: label, group: group, default_on: default_on, builder: builder)
    end

    # --- Payload helpers ---

    def embed(title:, color: 5_814_783, fields: [], url: nil, description: nil, timestamp: nil, footer_text: "Grenoble Roller Admin")
      embed_object = {
        title: title,
        color: color,
        fields: fields,
        footer: { text: footer_text }
      }
      embed_object[:url] = url if url.present?
      embed_object[:description] = description if description.present?
      embed_object[:timestamp] = timestamp if timestamp.present?

      { embeds: [ embed_object ] }
    end

    def format_money(cents, currency = "EUR")
      amount = cents.to_i / 100.0
      "#{format('%.2f', amount).tr('.', ',')} €"
    end

    def user_label(user)
      return "—" unless user

      name = [ user.try(:first_name), user.try(:last_name) ].compact.join(" ").presence
      name || user.try(:email) || "##{user.id}"
    end

    def actor_field(actor)
      return [] unless actor

      [ { name: "Par", value: user_label(actor), inline: true } ]
    end

    def admin_url(path)
      host = ActionMailer::Base.default_url_options[:host] || "localhost:3000"
      protocol = ActionMailer::Base.default_url_options[:protocol] || (Rails.env.production? ? "https" : "http")
      "#{protocol}://#{host}#{path}"
    end

    def record_id_label(record)
      hashid = record.try(:hashid)
      hashid ? "##{record.id} (#{hashid})" : "##{record.id}"
    end

    # --- Event payloads ---

    def order_paid_payload(order)
      embed(
        title: "Nouvelle commande payée",
        fields: [
          { name: "Commande", value: record_id_label(order), inline: true },
          { name: "Montant", value: format_money(order.total_cents), inline: true },
          { name: "Client", value: user_label(order.user), inline: true }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_order_path(order))
      )
    end

    def membership_activated_payload(membership)
      embed(
        title: "Adhésion activée",
        fields: [
          { name: "Adhésion", value: record_id_label(membership), inline: true },
          { name: "Montant", value: format_money(membership.amount_cents), inline: true },
          { name: "Membre", value: user_label(membership.user), inline: true }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_membership_path(membership))
      )
    end

    def event_registration_paid_payload(attendance)
      embed(
        title: "Inscription rando payée",
        fields: [
          { name: "Inscription", value: record_id_label(attendance), inline: true },
          { name: "Événement", value: attendance.event&.title.to_s.presence || "—", inline: true },
          { name: "Participant", value: user_label(attendance.user), inline: true }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_event_path(attendance.event_id))
      )
    end

    def membership_activated_manual_payload(membership, actor)
      embed(
        title: "Adhésion activée (manuel)",
        color: 16_776_960,
        fields: [
          { name: "Adhésion", value: record_id_label(membership), inline: true },
          { name: "Membre", value: user_label(membership.user), inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_membership_path(membership))
      )
    end

    def order_paid_manual_payload(order, actor)
      embed(
        title: "Commande payée (manuel)",
        color: 16_776_960,
        fields: [
          { name: "Commande", value: record_id_label(order), inline: true },
          { name: "Montant", value: format_money(order.total_cents), inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_order_path(order))
      )
    end

    def payment_failed_payload(payment)
      embed(
        title: "Paiement échoué",
        color: 16_711_680,
        fields: [
          { name: "Paiement", value: "##{payment.id}", inline: true },
          { name: "Montant", value: format_money(payment.amount_cents), inline: true },
          { name: "Statut", value: payment.status.to_s, inline: true }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_payment_path(payment))
      )
    end

    def payment_abandoned_payload(payment)
      embed(
        title: "Paiement abandonné",
        color: 16_711_680,
        fields: [
          { name: "Paiement", value: "##{payment.id}", inline: true },
          { name: "Montant", value: format_money(payment.amount_cents), inline: true }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_payment_path(payment))
      )
    end

    def membership_payment_failed_payload(membership)
      embed(
        title: "Échec paiement adhésion",
        color: 16_711_680,
        fields: [
          { name: "Adhésion", value: record_id_label(membership), inline: true },
          { name: "Membre", value: user_label(membership.user), inline: true }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_membership_path(membership))
      )
    end

    def contact_message_received_payload(message)
      # Discord renders field `name` above `value`. Keep emoji+info on one line by
      # putting the emoji inside `value` and using a zero-width name.
      blank = "\u200b"
      preview = message.message.to_s.truncate(400)

      embed(
        title: "📩 Nouveau message contact",
        color: 0xE67E22,
        fields: [
          { name: blank, value: "👤 #{message.name}", inline: true },
          { name: "#{blank} ", value: "✉️ `#{message.email}`", inline: true },
          { name: "#{blank}#{blank}", value: "📝 **#{message.subject.to_s.truncate(80)}**", inline: false },
          { name: "#{blank}#{blank}#{blank}", value: contact_message_code_block(preview), inline: false }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_contact_message_path(message)),
        timestamp: message.created_at&.utc&.iso8601,
        footer_text: "Grenoble Roller Admin · ##{message.id}"
      )
    end

    def contact_message_code_block(preview)
      text = preview.to_s.strip
      text = "—" if text.blank?
      # Fence without a language tag — Discord renders a plain code frame.
      "```\n#{text.gsub('```', "'''")}\n```"
    end

    def organizer_application_submitted_payload(application)
      embed(
        title: "Candidature organisateur",
        fields: [
          { name: "Candidat", value: user_label(application.user), inline: true },
          { name: "Statut", value: application.status.to_s, inline: true }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_organizer_application_path(application))
      )
    end

    def user_registered_payload(user)
      embed(
        title: "Nouveau compte utilisateur",
        fields: [
          { name: "Utilisateur", value: user_label(user), inline: true },
          { name: "Email", value: user.email.to_s, inline: true }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_user_path(user))
      )
    end

    def organizer_application_approved_payload(application, actor)
      embed(
        title: "Candidature organisateur approuvée",
        color: 5_763_719,
        fields: [
          { name: "Candidat", value: user_label(application.user), inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_organizer_application_path(application))
      )
    end

    def organizer_application_rejected_payload(application, actor)
      embed(
        title: "Candidature organisateur refusée",
        color: 16_711_680,
        fields: [
          { name: "Candidat", value: user_label(application.user), inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_organizer_application_path(application))
      )
    end

    def order_created_payload(order)
      embed(
        title: "Commande créée",
        fields: [
          { name: "Commande", value: record_id_label(order), inline: true },
          { name: "Statut", value: order.status.to_s, inline: true },
          { name: "Client", value: user_label(order.user), inline: true }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_order_path(order))
      )
    end

    def order_updated_payload(order, actor)
      embed(
        title: "Commande modifiée",
        fields: [
          { name: "Commande", value: record_id_label(order), inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_order_path(order))
      )
    end

    def order_status_changed_payload(order)
      embed(
        title: "Statut commande modifié",
        fields: [
          { name: "Commande", value: record_id_label(order), inline: true },
          { name: "Statut", value: order.status.to_s, inline: true }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_order_path(order))
      )
    end

    def product_created_payload(product, actor)
      generic_admin_payload("Produit créé", product, actor, :admin_panel_product_path, name: product.name)
    end

    def product_updated_payload(product, actor)
      generic_admin_payload("Produit modifié", product, actor, :admin_panel_product_path, name: product.name)
    end

    def product_destroyed_payload(product, actor)
      generic_admin_payload("Produit supprimé", product, actor, :admin_panel_products_path, name: product.name, color: 16_711_680)
    end

    def product_variant_created_payload(variant, actor)
      generic_admin_payload("Variante créée", variant, actor, :admin_panel_product_product_variant_path,
                            name: variant.try(:sku).to_s, parent: variant.product)
    end

    def product_variant_updated_payload(variant, actor)
      generic_admin_payload("Variante modifiée", variant, actor, :admin_panel_product_product_variant_path,
                            name: variant.try(:sku).to_s, parent: variant.product)
    end

    def product_variant_destroyed_payload(variant, actor)
      generic_admin_payload("Variante supprimée", variant, actor, :admin_panel_product_path,
                            name: variant.try(:sku).to_s, parent: variant.product, color: 16_711_680)
    end

    def product_variant_status_toggled_payload(variant, actor)
      embed(
        title: "Variante activée/désactivée",
        fields: [
          { name: "SKU", value: variant.try(:sku).to_s, inline: true },
          { name: "Actif", value: variant.try(:active).to_s, inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_product_product_variant_path(variant.product, variant))
      )
    end

    def membership_created_payload(membership)
      embed(
        title: "Adhésion créée",
        fields: [
          { name: "Adhésion", value: record_id_label(membership), inline: true },
          { name: "Membre", value: user_label(membership.user), inline: true },
          { name: "Statut", value: membership.status.to_s, inline: true }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_membership_path(membership))
      )
    end

    def membership_updated_payload(membership, actor)
      generic_admin_payload("Adhésion modifiée", membership, actor, :admin_panel_membership_path,
                            name: user_label(membership.user))
    end

    def membership_destroyed_payload(membership, actor)
      generic_admin_payload("Adhésion supprimée", membership, actor, :admin_panel_memberships_path,
                            name: user_label(membership.user), color: 16_711_680)
    end

    def event_cancelled_payload(event, actor)
      generic_admin_payload("Événement annulé", event, actor, :admin_panel_event_path,
                            name: event.title, color: 16_711_680)
    end

    def event_destroyed_payload(event, actor)
      generic_admin_payload("Événement supprimé", event, actor, :admin_panel_events_path,
                            name: event.title, color: 16_711_680)
    end

    def event_waitlist_notified_payload(event)
      embed(
        title: "Liste d'attente notifiée",
        fields: [ { name: "Événement", value: event.title.to_s, inline: true } ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_event_path(event))
      )
    end

    def event_waitlist_converted_payload(event)
      embed(
        title: "Liste d'attente convertie",
        fields: [ { name: "Événement", value: event.title.to_s, inline: true } ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_event_path(event))
      )
    end

    def attendance_created_payload(attendance, actor)
      embed(
        title: "Inscription créée",
        fields: [
          { name: "Participant", value: user_label(attendance.user), inline: true },
          { name: "Événement", value: attendance.event&.title.to_s, inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_event_path(attendance.event_id))
      )
    end

    def attendance_updated_payload(attendance, actor)
      attendance_created_payload(attendance, actor).tap do |payload|
        payload[:embeds][0][:title] = "Inscription modifiée"
      end
    end

    def attendance_destroyed_payload(attendance, actor)
      attendance_created_payload(attendance, actor).tap do |payload|
        payload[:embeds][0][:title] = "Inscription supprimée"
        payload[:embeds][0][:color] = 16_711_680
      end
    end

    def route_created_payload(route, actor)
      generic_admin_payload("Parcours créé", route, actor, :admin_panel_route_path, name: route.name)
    end

    def route_updated_payload(route, actor)
      generic_admin_payload("Parcours modifié", route, actor, :admin_panel_route_path, name: route.name)
    end

    def route_destroyed_payload(route, actor)
      generic_admin_payload("Parcours supprimé", route, actor, :admin_panel_routes_path, name: route.name, color: 16_711_680)
    end

    def event_organizer_created_payload(organizer, actor)
      generic_admin_payload("Organisateur créé", organizer, actor, :admin_panel_event_organizer_path, name: organizer.name)
    end

    def event_organizer_updated_payload(organizer, actor)
      generic_admin_payload("Organisateur modifié", organizer, actor, :admin_panel_event_organizer_path, name: organizer.name)
    end

    def event_organizer_destroyed_payload(organizer, actor)
      generic_admin_payload("Organisateur supprimé", organizer, actor, :admin_panel_event_organizers_path,
                            name: organizer.name, color: 16_711_680)
    end

    def initiation_presences_updated_payload(event, actor)
      embed(
        title: "Présences initiation mises à jour",
        fields: [
          { name: "Initiation", value: event.title.to_s, inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_initiation_path(event))
      )
    end

    def initiation_volunteer_toggled_payload(attendance, actor)
      embed(
        title: "Bénévole basculé",
        fields: [
          { name: "Participant", value: user_label(attendance.user), inline: true },
          { name: "Bénévole", value: attendance.is_volunteer.to_s, inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_initiation_path(attendance.event_id))
      )
    end

    def initiation_waitlist_notified_payload(event)
      embed(
        title: "Liste d'attente initiation notifiée",
        fields: [ { name: "Initiation", value: event.title.to_s, inline: true } ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_initiation_path(event))
      )
    end

    def initiation_waitlist_converted_payload(event)
      embed(
        title: "Liste d'attente initiation convertie",
        fields: [ { name: "Initiation", value: event.title.to_s, inline: true } ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_initiation_path(event))
      )
    end

    def initiation_material_returned_payload(event, actor)
      embed(
        title: "Matériel retourné",
        fields: [
          { name: "Initiation", value: event.title.to_s, inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_initiation_path(event))
      )
    end

    def roller_stock_created_payload(stock, actor)
      generic_admin_payload("Stock roller créé", stock, actor, :admin_panel_roller_stock_path, name: stock.size.to_s)
    end

    def roller_stock_updated_payload(stock, actor)
      generic_admin_payload("Stock roller modifié", stock, actor, :admin_panel_roller_stock_path, name: stock.size.to_s)
    end

    def roller_stock_destroyed_payload(stock, actor)
      generic_admin_payload("Stock roller supprimé", stock, actor, :admin_panel_roller_stocks_path,
                            name: stock.size.to_s, color: 16_711_680)
    end

    def roller_stock_return_all_payload(source, actor)
      label = source.is_a?(Event) ? source.title.to_s : "Batch"
      embed(
        title: "Prêts rollers clôturés",
        fields: [
          { name: "Contexte", value: label, inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_roller_stocks_path)
      )
    end

    def homepage_carousel_created_payload(slide, actor)
      generic_admin_payload("Slide carousel créée", slide, actor, :admin_panel_homepage_carousel_path,
                            name: slide.try(:title).to_s.presence || "##{slide.id}")
    end

    def homepage_carousel_updated_payload(slide, actor)
      generic_admin_payload("Slide carousel modifiée", slide, actor, :admin_panel_homepage_carousel_path,
                            name: slide.try(:title).to_s.presence || "##{slide.id}")
    end

    def homepage_carousel_destroyed_payload(slide, actor)
      generic_admin_payload("Slide carousel supprimée", slide, actor, :admin_panel_homepage_carousels_path,
                            name: slide.try(:title).to_s.presence || "##{slide.id}", color: 16_711_680)
    end

    def homepage_carousel_settings_updated_payload(settings, actor)
      embed(
        title: "Paramètres carousel modifiés",
        fields: actor_field(actor),
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_homepage_carousels_path)
      )
    end

    def partner_created_payload(partner, actor)
      generic_admin_payload("Partenaire créé", partner, actor, :admin_panel_partner_path, name: partner.name)
    end

    def partner_updated_payload(partner, actor)
      generic_admin_payload("Partenaire modifié", partner, actor, :admin_panel_partner_path, name: partner.name)
    end

    def partner_destroyed_payload(partner, actor)
      generic_admin_payload("Partenaire supprimé", partner, actor, :admin_panel_partners_path,
                            name: partner.name, color: 16_711_680)
    end

    def user_created_payload(user, actor)
      generic_admin_payload("Utilisateur créé", user, actor, :admin_panel_user_path, name: user_label(user))
    end

    def user_updated_payload(user, actor)
      generic_admin_payload("Utilisateur modifié", user, actor, :admin_panel_user_path, name: user_label(user))
    end

    def user_destroyed_payload(user, actor)
      generic_admin_payload("Utilisateur supprimé", user, actor, :admin_panel_users_path,
                            name: user_label(user), color: 16_711_680)
    end

    def role_created_payload(role, actor)
      generic_admin_payload("Rôle créé", role, actor, :admin_panel_role_path, name: role.name)
    end

    def role_updated_payload(role, actor)
      generic_admin_payload("Rôle modifié", role, actor, :admin_panel_role_path, name: role.name)
    end

    def role_destroyed_payload(role, actor)
      generic_admin_payload("Rôle supprimé", role, actor, :admin_panel_roles_path,
                            name: role.name, color: 16_711_680)
    end

    def maintenance_toggled_payload
      embed(
        title: "Mode maintenance basculé",
        fields: [ { name: "Statut", value: MaintenanceMode.status, inline: true } ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_root_path)
      )
    end

    def payment_destroyed_payload(payment, actor)
      embed(
        title: "Paiement supprimé",
        color: 16_711_680,
        fields: [
          { name: "Paiement", value: "##{payment.id}", inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_payments_path)
      )
    end

    def contact_message_destroyed_payload(message, actor)
      embed(
        title: "Message contact supprimé",
        color: 16_711_680,
        fields: [
          { name: "Sujet", value: message.subject.to_s.truncate(80), inline: true },
          *actor_field(actor)
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_contact_messages_path)
      )
    end

    def test_ping_payload(channel)
      name = channel.is_a?(NotificationChannel) ? channel.name : channel.to_s
      embed(
        title: "Test Grenoble Roller",
        fields: [
          { name: "Canal", value: name, inline: true },
          { name: "Horodatage", value: I18n.l(Time.current, format: :long), inline: true }
        ],
        url: admin_url(Rails.application.routes.url_helpers.admin_panel_root_path)
      )
    end

    def generic_admin_payload(title, record, actor, path_helper, name:, parent: nil, color: 5_814_783)
      helpers = Rails.application.routes.url_helpers
      path = if parent
               helpers.public_send(path_helper, parent, record)
      elsif record.persisted?
               helpers.public_send(path_helper, record)
      else
               helpers.public_send(path_helper)
      end

      embed(
        title: title,
        color: color,
        fields: [
          { name: "Référence", value: name.presence || record_id_label(record), inline: true },
          *actor_field(actor)
        ],
        url: admin_url(path)
      )
    end
  end
end

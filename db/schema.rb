# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_05_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attendances", force: :cascade do |t|
    t.bigint "child_membership_id"
    t.datetime "created_at", null: false
    t.text "equipment_note"
    t.bigint "event_id", null: false
    t.boolean "free_trial_used", default: false, null: false
    t.boolean "is_volunteer", default: false, null: false
    t.boolean "needs_equipment", default: false, null: false
    t.bigint "payment_id"
    t.datetime "reminder_sent_at"
    t.string "roller_size"
    t.string "status", limit: 20, default: "registered", null: false
    t.string "stripe_customer_id", limit: 255
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "wants_reminder", default: false, null: false
    t.index ["child_membership_id"], name: "index_attendances_on_child_membership_id"
    t.index ["event_id", "is_volunteer"], name: "index_attendances_on_event_id_and_is_volunteer"
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["payment_id"], name: "index_attendances_on_payment_id"
    t.index ["user_id", "child_membership_id"], name: "index_attendances_unique_free_trial_child_active", unique: true, where: "((free_trial_used = true) AND ((status)::text <> 'canceled'::text) AND (child_membership_id IS NOT NULL))"
    t.index ["user_id", "event_id", "child_membership_id", "is_volunteer"], name: "index_attendances_on_user_event_child_volunteer", unique: true
    t.index ["user_id", "free_trial_used"], name: "index_attendances_on_user_id_and_free_trial_used"
    t.index ["user_id"], name: "index_attendances_on_user_id"
    t.index ["user_id"], name: "index_attendances_unique_free_trial_parent_active", unique: true, where: "((free_trial_used = true) AND ((status)::text <> 'canceled'::text) AND (child_membership_id IS NULL))"
    t.index ["wants_reminder"], name: "index_attendances_on_wants_reminder"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", limit: 80, null: false
    t.bigint "actor_user_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata"
    t.integer "target_id", null: false
    t.string "target_type", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_user_id"], name: "index_audit_logs_on_actor_user_id"
    t.index ["target_type", "target_id"], name: "index_audit_logs_on_target_type_and_target_id"
  end

  create_table "contact_messages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", limit: 255, null: false
    t.text "message", null: false
    t.string "name", limit: 140, null: false
    t.string "subject", limit: 140, null: false
    t.datetime "updated_at", null: false
  end

  create_table "event_loop_routes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "distance_km", precision: 5, scale: 1
    t.bigint "event_id", null: false
    t.integer "loop_number", null: false
    t.bigint "route_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "loop_number"], name: "index_event_loop_routes_on_event_id_and_loop_number", unique: true
    t.index ["event_id"], name: "index_event_loop_routes_on_event_id"
    t.index ["route_id"], name: "index_event_loop_routes_on_route_id"
  end

  create_table "events", force: :cascade do |t|
    t.boolean "allow_non_member_discovery", default: false, null: false
    t.integer "attendances_count", default: 0, null: false
    t.string "cover_image_url", limit: 255
    t.datetime "created_at", null: false
    t.bigint "creator_user_id", null: false
    t.string "currency", limit: 3, default: "EUR", null: false
    t.text "description", null: false
    t.decimal "distance_km", precision: 6, scale: 2
    t.integer "duration_min", null: false
    t.boolean "is_recurring", default: false
    t.string "level", limit: 20
    t.string "location_text", limit: 255, null: false
    t.integer "loops_count", default: 1, null: false
    t.integer "max_participants", default: 0, null: false
    t.decimal "meeting_lat", precision: 9, scale: 6
    t.decimal "meeting_lng", precision: 9, scale: 6
    t.integer "non_member_discovery_slots", default: 0
    t.datetime "participants_report_sent_at"
    t.integer "price_cents", default: 0, null: false
    t.string "recurring_day"
    t.date "recurring_end_date"
    t.date "recurring_start_date"
    t.string "recurring_time"
    t.bigint "route_id"
    t.string "season"
    t.timestamptz "start_at", null: false
    t.string "status", limit: 20, default: "draft", null: false
    t.datetime "stock_returned_at"
    t.string "title", limit: 140, null: false
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["creator_user_id"], name: "index_events_on_creator_user_id"
    t.index ["participants_report_sent_at"], name: "index_events_on_participants_report_sent_at"
    t.index ["route_id"], name: "index_events_on_route_id"
    t.index ["status", "start_at"], name: "index_events_on_status_and_start_at"
    t.index ["type", "season"], name: "index_events_on_type_and_season"
    t.index ["type"], name: "index_events_on_type"
  end

  create_table "homepage_carousels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "link_url"
    t.integer "position", default: 0
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.string "subtitle"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_homepage_carousels_on_position"
    t.index ["published", "expires_at"], name: "index_homepage_carousels_on_published_and_expires_at"
    t.index ["published"], name: "index_homepage_carousels_on_published"
  end

  create_table "inventories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_variant_id", null: false
    t.integer "reserved_qty", default: 0, null: false
    t.integer "stock_qty", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["product_variant_id"], name: "index_inventories_on_product_variant_id", unique: true
  end

  create_table "inventory_movements", force: :cascade do |t|
    t.integer "before_qty", null: false
    t.datetime "created_at", null: false
    t.bigint "inventory_id", null: false
    t.integer "quantity", null: false
    t.string "reason", null: false
    t.string "reference"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["created_at"], name: "index_inventory_movements_on_created_at"
    t.index ["inventory_id"], name: "index_inventory_movements_on_inventory_id"
    t.index ["user_id"], name: "index_inventory_movements_on_user_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.integer "category", null: false
    t.date "child_date_of_birth"
    t.string "child_first_name"
    t.string "child_last_name"
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.date "end_date", null: false
    t.datetime "expired_email_sent_at"
    t.boolean "ffrs_data_sharing_consent", default: false
    t.string "health_q1"
    t.string "health_q2"
    t.string "health_q3"
    t.string "health_q4"
    t.string "health_q5"
    t.string "health_q6"
    t.string "health_q7"
    t.string "health_q8"
    t.string "health_q9"
    t.string "health_questionnaire_status"
    t.boolean "is_child_membership", default: false, null: false
    t.boolean "is_minor", default: false
    t.boolean "legal_notices_accepted", default: false
    t.boolean "medical_certificate_provided", default: false
    t.string "medical_certificate_url"
    t.jsonb "metadata"
    t.boolean "parent_authorization", default: false
    t.date "parent_authorization_date"
    t.string "parent_email"
    t.string "parent_name"
    t.string "parent_phone"
    t.bigint "payment_id"
    t.string "provider_order_id"
    t.datetime "renewal_reminder_sent_at"
    t.boolean "rgpd_consent", default: false
    t.string "season"
    t.date "start_date", null: false
    t.integer "status", default: 0, null: false
    t.integer "tshirt_price_cents", default: 1400
    t.integer "tshirt_qty", default: 0, null: false
    t.string "tshirt_size"
    t.bigint "tshirt_variant_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "wants_email_info", default: true
    t.boolean "wants_whatsapp", default: false
    t.boolean "with_tshirt", default: false, null: false
    t.index ["payment_id"], name: "index_memberships_on_payment_id"
    t.index ["provider_order_id"], name: "index_memberships_on_provider_order_id"
    t.index ["status", "end_date"], name: "index_memberships_on_status_and_end_date"
    t.index ["tshirt_variant_id"], name: "index_memberships_on_tshirt_variant_id"
    t.index ["user_id", "is_child_membership", "season"], name: "idx_on_user_id_is_child_membership_season_0aa4f85c42"
    t.index ["user_id", "season"], name: "index_memberships_on_user_id_and_season"
    t.index ["user_id", "season"], name: "index_memberships_on_user_id_and_season_unique_personal", unique: true, where: "(is_child_membership = false)"
    t.index ["user_id", "status"], name: "index_memberships_on_user_id_and_status"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "option_types", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "presentation", limit: 100
    t.index ["name"], name: "index_option_types_on_name", unique: true
  end

  create_table "option_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "option_type_id", null: false
    t.string "presentation", limit: 100
    t.datetime "updated_at", null: false
    t.string "value", limit: 50, null: false
    t.index ["option_type_id"], name: "index_option_values_on_option_type_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at"
    t.bigint "order_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price_cents", null: false
    t.integer "variant_id", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["variant_id"], name: "index_order_items_on_variant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "EUR", null: false
    t.integer "donation_cents", default: 0, null: false
    t.bigint "payment_id"
    t.string "status", default: "pending", null: false
    t.integer "total_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["payment_id"], name: "index_orders_on_payment_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "organizer_applications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "motivation"
    t.datetime "reviewed_at", precision: nil
    t.bigint "reviewed_by_id"
    t.string "status", limit: 20, default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["reviewed_by_id"], name: "index_organizer_applications_on_reviewed_by_id"
    t.index ["user_id"], name: "index_organizer_applications_on_user_id"
  end

  create_table "partners", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.string "logo_url", limit: 255
    t.string "name", limit: 140, null: false
    t.datetime "updated_at", null: false
    t.string "url", limit: 255
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents", default: 0, null: false
    t.datetime "created_at"
    t.string "currency", limit: 3, default: "EUR", null: false
    t.string "provider", limit: 20, null: false
    t.string "provider_payment_id"
    t.string "status", limit: 20, default: "succeeded", null: false
  end

  create_table "product_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", limit: 100, null: false
    t.string "slug", limit: 120, null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_product_categories_on_slug", unique: true
  end

  create_table "product_variants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "EUR", null: false
    t.string "image_url"
    t.boolean "is_active", default: true, null: false
    t.integer "price_cents", null: false
    t.bigint "product_id", null: false
    t.string "sku", limit: 80, null: false
    t.integer "stock_qty", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_variants_on_product_id"
    t.index ["sku"], name: "index_product_variants_on_sku", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "EUR", null: false
    t.text "description"
    t.string "image_url", limit: 255
    t.boolean "is_active", default: true, null: false
    t.string "name", limit: 140, null: false
    t.integer "price_cents", null: false
    t.string "slug", limit: 160, null: false
    t.integer "stock_qty", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["is_active", "slug"], name: "index_products_on_is_active_and_slug"
    t.index ["slug"], name: "index_products_on_slug", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.string "code", limit: 50, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "level", limit: 2, null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_roles_on_code", unique: true
  end

  create_table "roller_stocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true, null: false
    t.integer "quantity", default: 0, null: false
    t.string "size", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_roller_stocks_on_is_active"
    t.index ["size"], name: "index_roller_stocks_on_size", unique: true
  end

  create_table "routes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "difficulty", limit: 20
    t.decimal "distance_km", precision: 5, scale: 2
    t.integer "elevation_m"
    t.string "gpx_url", limit: 255
    t.string "map_image_url", limit: 255
    t.string "name", limit: 140, null: false
    t.text "safety_notes"
    t.datetime "updated_at", null: false
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "address"
    t.string "avatar_url"
    t.text "bio"
    t.boolean "can_be_volunteer", default: false, null: false
    t.string "city"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmation_token_last_used_at"
    t.datetime "confirmed_at"
    t.string "confirmed_ip"
    t.text "confirmed_user_agent"
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone", limit: 10
    t.string "postal_code"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role_id", null: false
    t.string "skill_level"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.boolean "wants_email_info", default: true
    t.boolean "wants_events_mail", default: true, null: false
    t.boolean "wants_initiation_mail", default: true, null: false
    t.boolean "wants_whatsapp", default: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["confirmed_ip"], name: "index_users_on_confirmed_ip"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["skill_level"], name: "index_users_on_skill_level"
  end

  create_table "variant_option_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "option_value_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "variant_id", null: false
    t.index ["option_value_id"], name: "index_variant_option_values_on_option_value_id"
    t.index ["variant_id", "option_value_id"], name: "index_variant_option_values_on_variant_id_and_option_value_id", unique: true
    t.index ["variant_id"], name: "index_variant_option_values_on_variant_id"
  end

  create_table "waitlist_entries", force: :cascade do |t|
    t.bigint "child_membership_id"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.boolean "needs_equipment"
    t.datetime "notified_at"
    t.integer "position", default: 0, null: false
    t.string "roller_size"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.boolean "use_free_trial", default: false
    t.bigint "user_id", null: false
    t.boolean "wants_reminder"
    t.index ["child_membership_id"], name: "index_waitlist_entries_on_child_membership_id"
    t.index ["event_id", "status", "position"], name: "index_waitlist_entries_on_event_id_and_status_and_position"
    t.index ["event_id"], name: "index_waitlist_entries_on_event_id"
    t.index ["user_id", "event_id", "child_membership_id"], name: "index_waitlist_entries_on_user_event_child", unique: true
    t.index ["user_id"], name: "index_waitlist_entries_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "memberships", column: "child_membership_id"
  add_foreign_key "attendances", "payments"
  add_foreign_key "attendances", "users"
  add_foreign_key "audit_logs", "users", column: "actor_user_id"
  add_foreign_key "event_loop_routes", "events"
  add_foreign_key "event_loop_routes", "routes"
  add_foreign_key "events", "routes"
  add_foreign_key "events", "users", column: "creator_user_id"
  add_foreign_key "inventories", "product_variants"
  add_foreign_key "inventory_movements", "inventories"
  add_foreign_key "inventory_movements", "users"
  add_foreign_key "memberships", "payments"
  add_foreign_key "memberships", "product_variants", column: "tshirt_variant_id"
  add_foreign_key "memberships", "users"
  add_foreign_key "option_values", "option_types"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "product_variants", column: "variant_id"
  add_foreign_key "orders", "payments"
  add_foreign_key "orders", "users"
  add_foreign_key "organizer_applications", "users"
  add_foreign_key "organizer_applications", "users", column: "reviewed_by_id"
  add_foreign_key "product_variants", "products"
  add_foreign_key "products", "product_categories", column: "category_id"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "users", "roles"
  add_foreign_key "variant_option_values", "option_values"
  add_foreign_key "variant_option_values", "product_variants", column: "variant_id"
  add_foreign_key "waitlist_entries", "events"
  add_foreign_key "waitlist_entries", "memberships", column: "child_membership_id"
  add_foreign_key "waitlist_entries", "users"
end

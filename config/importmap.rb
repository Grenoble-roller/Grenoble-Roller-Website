# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.bundle.min.js"
pin "stats_counter", to: "stats_counter.js"
pin "membership_form_validation", to: "membership_form_validation.js"
pin "admin_panel_navbar", to: "admin_panel_navbar.js"

# frozen_string_literal: true

# Pagy configuration (version 43+)
# Note: Les extras Bootstrap sont chargés automatiquement via le module Loader
# Les helpers bootstrap_series_nav sont disponibles directement sans require

# Configuration via Pagy.options (nouvelle API Pagy 43)
Pagy.options[:items] = 25 # Items par page par défaut
Pagy.options[:size] = [ 1, 4, 4, 1 ] # [first, page, gap, last]
# Note: overflow n'est plus nécessaire dans Pagy 43, géré automatiquement

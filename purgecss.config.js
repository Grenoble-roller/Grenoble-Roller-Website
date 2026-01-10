module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/views/**/*.html.haml',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/javascript/**/*.jsx',
    './app/javascript/**/*.ts',
    './app/javascript/**/*.tsx',
    './config/initializers/**/*.rb'
  ],
  css: ['./app/assets/builds/*.css'],
  safelist: [
    // Classes Bootstrap dynamiques
    /^dropdown-/,
    /^nav-/,
    /^navbar-/,
    /^btn-/,
    /^alert-/,
    /^badge-/,
    /^modal-/,
    /^offcanvas-/,
    /^carousel-/,
    // Classes ActiveAdmin
    /^active_admin/,
    // Classes Stimulus
    /^data-controller/,
    /^data-action/,
    /^data-target/,
    // Classes dynamiques avec interpolation
    /^bg-/,
    /^text-/,
    /^border-/,
    // Classes pour les états
    /^show$/,
    /^active$/,
    /^disabled$/,
    /^collapsed$/
  ],
  defaultExtractor: content => content.match(/[\w-/:]+(?<!:)/g) || []
};


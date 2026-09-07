/**
 * PurgeCSS config for public CSS (application.bootstrap.css only).
 *
 * IMPORTANT: the CLI `purgecss --config` does not reliably write results back
 * for this project — use `node scripts/purge-css.mjs` (see package.json).
 *
 * Do NOT safelist broad Bootstrap utility prefixes (/^btn-/, /^bg-/, /^text-/, …):
 * that kept nearly the entire framework. Scan views/helpers/JS instead; only
 * safelist classes injected at runtime (Bootstrap JS, Stimulus, Pagy, PhotoSwipe).
 */
const path = require("path")
const { execSync } = require("child_process")

function pagyLibGlob() {
  try {
    const gemPath = execSync("bundle show pagy", { encoding: "utf8" }).trim()
    return path.join(gemPath, "lib/**/*.rb")
  } catch {
    return null
  }
}

const content = [
  "./app/views/**/*.html.erb",
  "./app/helpers/**/*.rb",
  "./app/javascript/**/*.js",
  "./config/initializers/**/*.rb",
  "./vendor/javascript/**/*.js"
]

const pagyGlob = pagyLibGlob()
if (pagyGlob) content.push(pagyGlob)

module.exports = {
  content,
  // Public site only — ActiveAdmin CSS is a separate legacy build; leave it unpurged.
  css: ["./app/assets/builds/application.bootstrap.css"],
  safelist: {
    standard: [
      // Bootstrap JS runtime states / backdrops
      "show",
      "fade",
      "collapsing",
      "collapse",
      "active",
      "disabled",
      "collapsed",
      "modal-open",
      "modal-backdrop",
      "modal-static",
      "offcanvas-backdrop",
      "was-validated",
      "is-valid",
      "is-invalid",
      "invalid-feedback",
      "valid-feedback",
      "carousel-item-start",
      "carousel-item-end",
      "carousel-item-next",
      "carousel-item-prev",
      // App / Stimulus toggles
      "d-none",
      "navbar-open",
      "lazy-skeleton",
      "lazy-loaded",
      "border-primary",
      "bg-light",
      "text-muted",
      "text-warning",
      "text-danger",
      "text-success",
      "alert",
      "alert-info",
      "alert-danger",
      "alert-dismissible",
      "btn-close",
      "badge-liquid-success",
      "badge-liquid-danger",
      "badge-liquid-warning",
      "badge-liquid-primary",
      "badge-liquid-secondary",
      "is-active",
      "is-modified",
      "is-saving",
      "qty-invalid",
      "qty-changed",
      "selected",
      "drag-over",
      "cookie-banner-visible",
      "password-strength-meter",
      "password-strength-weak",
      "password-strength-medium",
      "password-strength-strong",
      // Pagy bootstrap nav (also scanned via gem path; keep explicit)
      "pagination",
      "page-item",
      "page-link",
      "prev",
      "next",
      "gap",
      // Icons swapped at runtime
      "bi-eye",
      "bi-eye-slash"
    ],
    deep: [/^pswp/, /^carousel-item-/],
    greedy: [/^tooltip/, /^popover/, /^bs-tooltip/, /^bs-popover/]
  },
  defaultExtractor: (content) => content.match(/[\w-/:]+(?<!:)/g) || []
}

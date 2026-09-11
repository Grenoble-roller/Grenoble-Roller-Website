require 'rails_helper'

# GARDE-FOU DE RÉGRESSION — remplacement de Route#map_image depuis
# /admin-panel/routes/:id/edit, dans un vrai navigateur (Chrome headless + Turbo).
#
# Historique : les champs legacy `map_image_url` et `gpx_url` étaient rendus en
# `type="url"`. Dès qu'une valeur non absolue était stockée en base, le formulaire
# devenait invalide au sens HTML5 : le navigateur refusait le submit SANS message
# visible (simple infobulle native), remontait en haut de page, et AUCUNE requête
# réseau n'était émise — l'image n'était donc jamais uploadée. Ces deux champs sont
# désormais des champs texte (`inputmode: url`).
#
# CAS A : image seule (aucun autre champ) → doit remplacer.
# CAS B : image + distance_km → doit remplacer.
# CAS C : `map_image_url` non absolue stockée → ne doit PLUS bloquer.
# CAS D : `gpx_url` non absolue stockée → ne doit PLUS bloquer.
# CAS E : `distance_km` à 2 décimales (step="0.1") → ne doit PLUS bloquer.
RSpec.describe 'Admin Route#map_image replacement (browser)', type: :system, js: true do
  include SystemAuthenticationHelper

  let(:admin) { create(:user, :superadmin) }
  let(:old_image) { Rails.root.join('app/assets/images/favicon-512.png') }
  let(:new_image) { Rails.root.join('app/assets/images/img/image1.png') }

  # Construit une Route persistée portant déjà une map_image (scénario "remplacement").
  def build_route(**attrs)
    record = create(:route, **attrs)
    record.map_image.attach(io: File.open(old_image), filename: 'old-map.png', content_type: 'image/png')
    record.save!
    refresh_record(record)
  end

  # Recharge la ligne (les écritures faites par la page passent par un autre contexte).
  def refresh_record(record)
    Route.unscoped.find_by(id: record.id)
  end

  def sign_in_as(user)
    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'password12345'
    click_button 'Se connecter'
    expect(page).to have_no_content('Email ou mot de passe invalide')
  end

  # Instrumente le navigateur : événements submit (capture + bubble), fetch/XHR,
  # FormData. Persiste dans sessionStorage pour survivre à une navigation.
  def instrument_browser!
    page.execute_script(<<~JS)
      window.__repro = { submits: [], prevented: [], requests: [] };
      window.__persist = function () {
        try { sessionStorage.setItem('__repro', JSON.stringify(window.__repro)); } catch (e) {}
      };
      document.addEventListener('submit', function (e) {
        window.__repro.submits.push({ phase: 'capture', action: e.target && e.target.getAttribute('action'), defaultPrevented: e.defaultPrevented });
        window.__persist();
      }, true);
      document.addEventListener('submit', function (e) {
        window.__repro.prevented.push({ phase: 'bubble', action: e.target && e.target.getAttribute('action'), defaultPrevented: e.defaultPrevented });
        window.__persist();
      }, false);
      if (!window.__netPatched) {
        var origFetch = window.fetch;
        window.fetch = function () {
          try {
            var args = Array.prototype.slice.call(arguments);
            var url = (args[0] && args[0].url) || args[0];
            var init = args[1] || {};
            var files = null;
            if (init.body instanceof FormData) {
              files = Array.from(init.body.entries()).filter(function (p) { return p[1] instanceof File; })
                .map(function (p) { return p[0] + '=' + p[1].name + '(' + p[1].size + ')'; });
            }
            window.__repro.requests.push({ via: 'fetch', url: String(url), method: init.method || 'GET', files: files });
            window.__persist();
          } catch (err) { window.__repro.requests.push({ via: 'fetch', error: String(err) }); }
          return origFetch.apply(this, arguments);
        };
        var origOpen = XMLHttpRequest.prototype.open;
        var origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function (m, u) { this.__m = m; this.__u = u; return origOpen.apply(this, arguments); };
        XMLHttpRequest.prototype.send = function (body) {
          var files = null;
          if (body instanceof FormData) {
            files = Array.from(body.entries()).filter(function (p) { return p[1] instanceof File; })
              .map(function (p) { return p[0] + '=' + p[1].name + '(' + p[1].size + ')'; });
          }
          window.__repro.requests.push({ via: 'xhr', url: String(this.__u), method: this.__m, files: files });
          window.__persist();
          return origSend.apply(this, arguments);
        };
        window.__netPatched = true;
      }
    JS
  end

  def form_snapshot
    page.evaluate_script(<<~JS)
      (function () {
        var form = document.querySelector('form[action*="admin-panel/routes"]');
        if (!form) { return { formPresent: false, url: document.location.href }; }
        var fields = Array.prototype.slice.call(form.querySelectorAll('input, select, textarea')).map(function (el) {
          return { name: el.name, type: el.type, value: (el.type === 'file') ? null : String(el.value == null ? '' : el.value).slice(0, 40),
                   required: !!el.required, valid: el.checkValidity ? el.checkValidity() : null, message: el.validationMessage || null };
        });
        var fd = [];
        try {
          fd = Array.from(new FormData(form).entries()).map(function (p) {
            return (p[1] instanceof File) ? p[0] + '=[File ' + p[1].name + ' ' + p[1].size + ']' : p[0] + '=' + String(p[1]).slice(0, 40);
          });
        } catch (e) { fd = ['FormData error: ' + e]; }
        return { formPresent: true, url: document.location.href, formAction: form.getAttribute('action'),
                 enctype: form.getAttribute('enctype'), dataTurbo: form.getAttribute('data-turbo'),
                 hasFileInFormData: fd.some(function (s) { return s.indexOf('[File ') !== -1; }),
                 formValidity: form.checkValidity(),
                 invalidFields: fields.filter(function (f) { return f.valid === false; }),
                 formData: fd };
      })()
    JS
  end

  def repro_state
    page.evaluate_script("JSON.parse(sessionStorage.getItem('__repro') || 'null') || window.__repro || null")
  rescue StandardError
    nil
  end

  def current_blob_id(record)
    fresh = refresh_record(record)
    fresh&.map_image&.blob&.id
  end

  def wait_for_replacement(record, previous_blob_id, timeout: 10)
    deadline = Time.now + timeout
    loop do
      current = current_blob_id(record)
      return true if current && current != previous_blob_id
      return false if Time.now > deadline

      sleep 0.3
    end
  end

  def report_attachment(record)
    fresh = refresh_record(record)
    blob = fresh.map_image.blob
    exists = blob ? ActiveStorage::Blob.services.fetch(:test).exist?(blob.key) : nil
    download =
      if blob
        begin
          bytes = blob.download.bytesize
          "OK bytes=#{bytes} matches_size=#{bytes == blob.byte_size}"
        rescue StandardError => e
          "RAISED #{e.class}: #{e.message}"
        end
      else
        'n/a'
      end
    puts "  attachment_filename=#{blob&.filename.nil? ? 'nil' : blob.filename}"
    puts "  blob_id=#{blob&.id} object_exists=#{exists} download=#{download}"
    { blob_id: blob&.id, filename: blob&.filename&.to_s, object_exists: exists, download: download }
  end

  # Retourne [replaced?, snapshot, state]
  def attempt_replacement(record, label:, modify_distance: false)
    sign_in_as(admin)
    visit edit_admin_panel_route_path(record)
    instrument_browser!

    before_blob_id = current_blob_id(record)
    snapshot_before = form_snapshot

    attach_file 'route_map_image', new_image.to_s
    snapshot_after = form_snapshot

    fill_in 'route_distance_km', with: '99.9' if modify_distance

    puts "\n===== #{label} ====="
    puts "  before_blob_id=#{before_blob_id}"
    puts "  form_valid_before_attach=#{snapshot_before['formValidity']} invalid=#{snapshot_before['invalidFields'].inspect}"
    puts "  form_valid_after_attach=#{snapshot_after['formValidity']} invalid=#{snapshot_after['invalidFields'].inspect}"
    puts "  file_in_formdata=#{snapshot_after['hasFileInFormData']}"
    puts "  enctype=#{snapshot_after['enctype']} data-turbo=#{snapshot_after['dataTurbo'].inspect}"

    click_button 'Mettre à jour'

    replaced = wait_for_replacement(record, before_blob_id)
    sleep 1.0
    state = repro_state

    puts "  url_after_click=#{(page.current_path rescue 'n/a')}"
    puts "  submit_events=#{(state && state['submits']).inspect}"
    puts "  network_requests=#{(state && state['requests']).inspect}"
    puts "  replacement_detected=#{replaced}"
    report_attachment(record)
    replaced
  end

  it 'CASE A — image seule, aucun autre champ modifié' do
    record = build_route
    replaced = attempt_replacement(record, label: 'CASE A (image seule)')
    puts "  >>> CASE_A_REPLACED=#{replaced}"
    expect(replaced).to be(true)
  end

  it 'CASE B — image + distance_km' do
    record = build_route
    replaced = attempt_replacement(record, label: 'CASE B (image + distance_km)', modify_distance: true)
    puts "  >>> CASE_B_REPLACED=#{replaced}"
    expect(replaced).to be(true)
  end

  it 'CASE C — map_image_url non absolue ne doit plus bloquer' do
    record = build_route(map_image_url: '/uploads/map.png')
    replaced = attempt_replacement(record, label: 'CASE C (map_image_url="/uploads/map.png")')
    puts "  >>> CASE_C_REPLACED=#{replaced}"
    expect(replaced).to be(true)
  end

  it 'CASE D — gpx_url non absolue ne doit plus bloquer' do
    record = build_route(gpx_url: 'trace.gpx')
    replaced = attempt_replacement(record, label: 'CASE D (gpx_url="trace.gpx")')
    puts "  >>> CASE_D_REPLACED=#{replaced}"
    expect(replaced).to be(true)
  end

  it 'CASE E — distance_km à 2 décimales ne doit plus bloquer' do
    record = build_route(distance_km: 12.55)
    replaced = attempt_replacement(record, label: 'CASE E (distance_km=12.55, image seule)')
    puts "  >>> CASE_E_REPLACED=#{replaced}"
    expect(replaced).to be(true)
  end
end

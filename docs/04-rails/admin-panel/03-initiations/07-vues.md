# 🎨 VUES - Initiations

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Description

Vues ERB pour initiations et stock rollers.

### ⚠️ Helpers de traduction

Les statuts sont traduits en français via les helpers `attendance_status_fr` et `waitlist_status_fr` définis dans `app/helpers/admin_panel_helper.rb` :
- `attendance_status_fr(status)` : Traduit les statuts d'attendance (pending → "En attente", registered → "Inscrit", etc.)
- `waitlist_status_fr(status)` : Traduit les statuts de waitlist (pending → "En attente", notified → "Notifié", converted → "Converti", etc.)

---

## ✅ Vue 1 : Index Initiations

**Fichier** : `app/views/admin_panel/initiations/index.html.erb`

```erb
<% 
  breadcrumb_items = [
    { label: "Initiations", url: nil }
  ]
%>

<%= render 'admin_panel/shared/breadcrumb', breadcrumb_items: breadcrumb_items %>

<div class="d-flex justify-content-between align-items-center mb-4">
  <h1>Initiations</h1>
  <% if current_user&.role&.code.in?(%w[ADMIN SUPERADMIN]) %>
    <%= link_to new_initiation_path, class: "btn btn-primary", target: "_blank" do %>
      <i class="bi bi-plus-circle me-2"></i>
      Créer une initiation
    <% end %>
  <% end %>
</div>

<!-- Filtres et recherche -->
<div class="card mb-4">
  <div class="card-body">
    <%= search_form_for @q, url: admin_panel_initiations_path, method: :get, class: "row g-3" do |f| %>
      <div class="col-md-4">
        <%= f.label :title_cont, "Titre", class: "form-label" %>
        <%= f.search_field :title_cont, class: "form-control", placeholder: "Rechercher..." %>
      </div>
      <div class="col-md-2">
        <%= f.label :status_eq, "Statut", class: "form-label" %>
        <%= f.select :status_eq,
            options_for_select([
              ["Tous", ""],
              ["Brouillon", "draft"],
              ["Publié", "published"],
              ["Annulé", "canceled"]
            ], params.dig(:q, :status_eq)),
            {},
            { class: "form-select" } %>
      </div>
      <div class="col-md-2">
        <label class="form-label">Filtre</label>
        <%= select_tag :scope,
            options_for_select([
              ["Toutes", ""],
              ["À venir uniquement", "upcoming"],
              ["Publiées uniquement", "published"]
            ], params[:scope]),
            { class: "form-select" } %>
      </div>
      <div class="col-md-4 d-flex align-items-end justify-content-end gap-2">
        <%= f.submit "Filtrer", class: "btn btn-outline-primary" %>
        <%= link_to "Réinitialiser", admin_panel_initiations_path, class: "btn btn-outline-secondary" %>
      </div>
    <% end %>
  </div>
</div>

<!-- Initiations à venir -->
<% if @upcoming_initiations.any? %>
  <div class="card mb-4">
    <div class="card-header bg-primary text-white">
      <h5 class="mb-0">
        <i class="bi bi-calendar-event me-2"></i>
        Initiations à venir (<%= @upcoming_initiations.count %>)
      </h5>
    </div>
    <div class="card-body">
      <div class="table-responsive">
        <table class="table table-hover">
          <thead>
            <tr>
              <th>Titre</th>
              <th>Date/Heure</th>
              <th>Statut</th>
              <th>Places</th>
              <th>Participants</th>
              <th>Bénévoles</th>
              <th>Liste d'attente</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <% @upcoming_initiations.each do |initiation| %>
              <tr>
                <td><%= initiation.title %></td>
                <td>
                  <%= l(initiation.start_at, format: :short) if initiation.start_at %>
                  <br>
                  <small class="text-muted">10h15-12h00</small>
                </td>
                <td>
                  <% case initiation.status %>
                  <% when 'published' %>
                    <span class="badge bg-success">Publié</span>
                  <% when 'draft' %>
                    <span class="badge bg-secondary">Brouillon</span>
                  <% when 'canceled' %>
                    <span class="badge bg-danger">Annulé</span>
                  <% end %>
                </td>
                <td>
                  <% if initiation.full? %>
                    <span class="badge bg-danger">COMPLET</span>
                  <% else %>
                    <span class="badge bg-success">
                      <%= initiation.participants_count %>/<%= initiation.max_participants %>
                    </span>
                  <% end %>
                </td>
                <td><%= initiation.participants_count %></td>
                <td><%= initiation.volunteers_count %></td>
                <td>
                  <% waitlist_count = initiation.waitlist_entries.active.count %>
                  <% if waitlist_count > 0 %>
                    <span class="badge bg-warning"><%= waitlist_count %></span>
                  <% else %>
                    <span class="text-muted">0</span>
                  <% end %>
                </td>
                <td>
                  <div class="btn-group btn-group-sm">
                    <%= link_to "Voir", admin_panel_initiation_path(initiation), class: "btn btn-outline-primary" %>
                    <%= link_to "Présences", presences_admin_panel_initiation_path(initiation), class: "btn btn-outline-info" %>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
  </div>
<% end %>

<!-- Initiations passées -->
<% if @past_initiations.any? %>
  <div class="card">
    <div class="card-header bg-secondary text-white">
      <h5 class="mb-0">
        <i class="bi bi-calendar-check me-2"></i>
        Initiations passées (<%= @past_initiations.count %>)
      </h5>
    </div>
    <div class="card-body">
      <div class="table-responsive">
        <table class="table table-hover">
          <thead>
            <tr>
              <th>Titre</th>
              <th>Date/Heure</th>
              <th>Statut</th>
              <th>Places</th>
              <th>Participants</th>
              <th>Bénévoles</th>
              <th>Liste d'attente</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <% @past_initiations.each do |initiation| %>
              <tr class="opacity-75">
                <td><%= initiation.title %></td>
                <td>
                  <%= l(initiation.start_at, format: :short) if initiation.start_at %>
                  <br>
                  <small class="text-muted">10h15-12h00</small>
                </td>
                <td>
                  <% case initiation.status %>
                  <% when 'published' %>
                    <span class="badge bg-success">Publié</span>
                  <% when 'draft' %>
                    <span class="badge bg-secondary">Brouillon</span>
                  <% when 'canceled' %>
                    <span class="badge bg-danger">Annulé</span>
                  <% end %>
                </td>
                <td>
                  <% if initiation.full? %>
                    <span class="badge bg-danger">COMPLET</span>
                  <% else %>
                    <span class="badge bg-success">
                      <%= initiation.participants_count %>/<%= initiation.max_participants %>
                    </span>
                  <% end %>
                </td>
                <td><%= initiation.participants_count %></td>
                <td><%= initiation.volunteers_count %></td>
                <td>
                  <% waitlist_count = initiation.waitlist_entries.active.count %>
                  <% if waitlist_count > 0 %>
                    <span class="badge bg-warning"><%= waitlist_count %></span>
                  <% else %>
                    <span class="text-muted">0</span>
                  <% end %>
                </td>
                <td>
                  <div class="btn-group btn-group-sm">
                    <%= link_to "Voir", admin_panel_initiation_path(initiation), class: "btn btn-outline-primary" %>
                    <%= link_to "Présences", presences_admin_panel_initiation_path(initiation), class: "btn btn-outline-info" %>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
  </div>
<% end %>

<!-- Message si aucune initiation -->
<% if @upcoming_initiations.empty? && @past_initiations.empty? %>
  <div class="alert alert-info">
    Aucune initiation trouvée.
  </div>
<% end %>
```

---

## ✅ Vue 2 : Show Initiation

**Fichier** : `app/views/admin_panel/initiations/show.html.erb`

```erb
<% 
  breadcrumb_items = [
    { label: "Initiations", url: admin_panel_initiations_path },
    { label: @initiation.title, url: nil }
  ]
%>

<%= render 'admin_panel/shared/breadcrumb', breadcrumb_items: breadcrumb_items %>

<div class="d-flex justify-content-between align-items-center mb-4">
  <h1><%= @initiation.title %></h1>
  <div class="btn-group">
    <%= link_to "Présences", presences_admin_panel_initiation_path(@initiation), class: "btn btn-primary" %>
    <% if current_user&.role&.code.in?(%w[ADMIN SUPERADMIN]) %>
      <%= link_to "Éditer", edit_initiation_path(@initiation), class: "btn btn-outline-warning", target: "_blank" %>
    <% end %>
    <%= link_to "Retour", admin_panel_initiations_path, class: "btn btn-outline-secondary" %>
  </div>
</div>

<!-- Détails Initiation -->
<div class="card mb-4">
  <div class="card-header">
    <h5 class="mb-0">Détails</h5>
  </div>
  <div class="card-body">
    <div class="row">
      <div class="col-md-6">
        <p><strong>Date :</strong> <%= l(@initiation.start_at, format: :long) if @initiation.start_at %></p>
        <p><strong>Heure :</strong> 10h15-12h00</p>
        <p><strong>Lieu :</strong> <%= @initiation.location_text %></p>
      </div>
      <div class="col-md-6">
        <p><strong>Statut :</strong>
          <% case @initiation.status %>
          <% when 'published' %>
            <span class="badge bg-success">Publié</span>
          <% when 'draft' %>
            <span class="badge bg-secondary">Brouillon</span>
          <% when 'canceled' %>
            <span class="badge bg-danger">Annulé</span>
          <% end %>
        </p>
        <p><strong>Places :</strong>
          <% if @initiation.full? %>
            <span class="badge bg-danger">COMPLET</span>
          <% else %>
            <span class="badge bg-success">
              <%= @initiation.participants_count %>/<%= @initiation.max_participants %>
            </span>
          <% end %>
        </p>
        <p><strong>Bénévoles :</strong> <%= @initiation.volunteers_count %></p>
      </div>
    </div>
    <% if @initiation.description.present? %>
      <hr>
      <p><strong>Description :</strong></p>
      <p><%= simple_format(@initiation.description) %></p>
    <% end %>
  </div>
</div>

<!-- Panel Bénévoles -->
<div class="card mb-4">
  <div class="card-header d-flex justify-content-between align-items-center">
    <h5 class="mb-0">Bénévoles (<%= @volunteers.count %>)</h5>
  </div>
  <div class="card-body">
    <% if @volunteers.any? %>
      <div class="table-responsive">
        <table class="table table-sm">
          <thead>
            <tr>
              <th>Nom</th>
              <th>Email</th>
              <th>Statut</th>
              <th>Matériel</th>
              <th>Essai gratuit</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <% @volunteers.each do |attendance| %>
              <tr>
                <td><%= attendance.participant_name %></td>
                <td><%= attendance.user.email %></td>
                <td>
                  <span class="badge bg-<%= attendance.status == 'present' ? 'success' : 'secondary' %>">
                    <%= attendance.status.humanize %>
                  </span>
                </td>
                <td>
                  <% if attendance.equipment_note.present? %>
                    <small><%= attendance.equipment_note %></small>
                  <% else %>
                    <span class="text-muted">-</span>
                  <% end %>
                </td>
                <td>
                  <% if attendance.free_trial_used? %>
                    <span class="badge bg-danger">Oui</span>
                  <% else %>
                    <span class="text-muted">Non</span>
                  <% end %>
                </td>
                <td>
                  <%= button_to "Retirer bénévole", toggle_volunteer_admin_panel_initiation_path(@initiation, attendance_id: attendance.id),
                      method: :patch, class: "btn btn-sm btn-outline-warning" %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    <% else %>
      <p class="text-muted">Aucun bénévole inscrit.</p>
    <% end %>
  </div>
</div>

<!-- Panel Participants -->
<div class="card mb-4">
  <div class="card-header d-flex justify-content-between align-items-center">
    <h5 class="mb-0">Participants (<%= @participants.count %>)</h5>
  </div>
  <div class="card-body">
    <% if @participants.any? %>
      <div class="table-responsive">
        <table class="table table-sm">
          <thead>
            <tr>
              <th>Nom</th>
              <th>Email</th>
              <th>Type</th>
              <th>Statut</th>
              <th>Matériel</th>
              <th>Essai gratuit</th>
              <th>Adhésion</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <% @participants.each do |attendance| %>
              <tr>
                <td><%= attendance.participant_name %></td>
                <td><%= attendance.user.email %></td>
                <td>
                  <% if attendance.for_child? %>
                    <span class="badge bg-info">Enfant</span>
                  <% else %>
                    <span class="badge bg-primary">Parent</span>
                  <% end %>
                </td>
                <td>
                  <span class="badge bg-<%= attendance.status == 'present' ? 'success' : 'secondary' %>">
                    <%= attendance.status.humanize %>
                  </span>
                </td>
                <td>
                  <% if attendance.equipment_note.present? %>
                    <small><%= attendance.equipment_note %></small>
                    <% if attendance.roller_size.present? %>
                      <br><small class="text-muted">Taille: <%= attendance.roller_size %></small>
                    <% end %>
                  <% else %>
                    <span class="text-muted">-</span>
                  <% end %>
                </td>
                <td>
                  <% if attendance.free_trial_used? %>
                    <span class="badge bg-danger">Oui</span>
                  <% else %>
                    <span class="text-muted">Non</span>
                  <% end %>
                </td>
                <td>
                  <% is_member = attendance.for_child? ? 
                      attendance.child_membership&.active? : 
                      attendance.user.memberships.active_now.exists? %>
                  <% if is_member %>
                    <span class="badge bg-success">Adhérent</span>
                  <% else %>
                    <span class="badge bg-warning">Non adhérent</span>
                  <% end %>
                </td>
                <td>
                  <%= button_to "Ajouter bénévole", toggle_volunteer_admin_panel_initiation_path(@initiation, attendance_id: attendance.id),
                      method: :patch, class: "btn btn-sm btn-outline-success" %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    <% else %>
      <p class="text-muted">Aucun participant inscrit.</p>
    <% end %>
  </div>
</div>

<!-- Panel Matériel demandé -->
<% if @equipment_requests.any? %>
  <div class="card mb-4">
    <div class="card-header d-flex justify-content-between align-items-center">
      <h5 class="mb-0">Matériel demandé</h5>
      <%= link_to "Gérer le stock", admin_panel_roller_stocks_path, class: "btn btn-sm btn-outline-primary" %>
    </div>
    <div class="card-body">
      <div class="row">
        <% @equipment_requests.each do |size, count| %>
          <div class="col-md-3 mb-2">
            <div class="d-flex justify-content-between align-items-center p-2 border rounded">
              <span><strong>Taille <%= size %></strong></span>
              <span class="badge bg-primary"><%= count %> demande<%= 's' if count > 1 %></span>
            </div>
          </div>
        <% end %>
      </div>
      <div class="mt-3">
        <small class="text-muted">
          <i class="bi bi-info-circle"></i> 
          Total : <%= @equipment_requests.values.sum %> demande<%= 's' if @equipment_requests.values.sum > 1 %> de matériel
        </small>
      </div>
    </div>
  </div>
<% end %>

<!-- Panel Liste d'attente -->
<div class="card mb-4">
  <div class="card-header d-flex justify-content-between align-items-center">
    <h5 class="mb-0">Liste d'attente (<%= @waitlist_entries.count %>)</h5>
  </div>
  <div class="card-body">
    <% if @waitlist_entries.any? %>
      <div class="table-responsive">
        <table class="table table-sm">
          <thead>
            <tr>
              <th>Position</th>
              <th>Nom</th>
              <th>Email</th>
              <th>Statut</th>
              <th>Date</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <% @waitlist_entries.each do |entry| %>
              <tr>
                <td><strong>#<%= entry.position %></strong></td>
                <td><%= entry.participant_name %></td>
                <td><%= entry.user.email %></td>
                <td>
                  <% case entry.status %>
                  <% when 'pending' %>
                    <span class="badge bg-secondary">En attente</span>
                  <% when 'notified' %>
                    <span class="badge bg-warning">Notifié</span>
                  <% when 'converted' %>
                    <span class="badge bg-success">Converti</span>
                  <% when 'cancelled' %>
                    <span class="badge bg-danger">Annulé</span>
                  <% end %>
                </td>
                <td><%= l(entry.created_at, format: :short) %></td>
                <td>
                  <div class="btn-group btn-group-sm">
                    <% if entry.pending? %>
                      <%= button_to "Notifier", notify_waitlist_admin_panel_initiation_path(@initiation, waitlist_entry_id: entry.hashid),
                          method: :post, class: "btn btn-outline-warning" %>
                    <% elsif entry.notified? %>
                      <%= button_to "Convertir", convert_waitlist_admin_panel_initiation_path(@initiation, waitlist_entry_id: entry.hashid),
                          method: :post, class: "btn btn-outline-success" %>
                    <% end %>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    <% else %>
      <p class="text-muted">Aucune personne en liste d'attente.</p>
    <% end %>
  </div>
</div>
```

---

## ✅ Vue 3 : Presences Initiation

**Fichier** : `app/views/admin_panel/initiations/presences.html.erb`

```erb
<% 
  breadcrumb_items = [
    { label: "Initiations", url: admin_panel_initiations_path },
    { label: @initiation.title, url: admin_panel_initiation_path(@initiation) },
    { label: "Présences", url: nil }
  ]
%>

<%= render 'admin_panel/shared/breadcrumb', breadcrumb_items: breadcrumb_items %>

<div class="d-flex justify-content-between align-items-center mb-4">
  <h1>Présences - <%= @initiation.title %></h1>
  <%= link_to "Retour", admin_panel_initiation_path(@initiation), class: "btn btn-outline-secondary" %>
</div>

<!-- En-tête -->
<div class="card mb-4">
  <div class="card-body">
    <div class="row">
      <div class="col-md-6">
        <p><strong>Date :</strong> <%= l(@initiation.start_at, format: :long) if @initiation.start_at %></p>
        <p><strong>Heure :</strong> 10h15-12h00</p>
        <p><strong>Lieu :</strong> <%= @initiation.location_text %></p>
      </div>
      <div class="col-md-6">
        <p><strong>Places :</strong>
          <span class="badge bg-<%= @initiation.full? ? 'danger' : 'success' %>">
            <%= @initiation.participants_count %>/<%= @initiation.max_participants %>
          </span>
        </p>
        <p><strong>Bénévoles :</strong> <%= @initiation.volunteers_count %></p>
      </div>
    </div>
  </div>
</div>

<%= form_with url: update_presences_admin_panel_initiation_path(@initiation), method: :patch, local: true do |f| %>
  <!-- Tableau Bénévoles -->
  <div class="card mb-4">
    <div class="card-header">
      <h5 class="mb-0">Bénévoles (<%= @volunteers.count %>)</h5>
    </div>
    <div class="card-body">
      <% if @volunteers.any? %>
        <div class="table-responsive">
          <table class="table table-sm">
            <thead>
              <tr>
                <th>Nom</th>
                <th>Email</th>
                <th>Matériel</th>
                <th>Présence</th>
                <th>Bénévole</th>
              </tr>
            </thead>
            <tbody>
              <% @volunteers.each do |attendance| %>
                <%= f.hidden_field "attendance_ids[]", value: attendance.id %>
                <tr>
                  <td><%= attendance.participant_name %></td>
                  <td><%= attendance.user.email %></td>
                  <td>
                    <% if attendance.equipment_note.present? %>
                      <small><%= attendance.equipment_note %></small>
                    <% else %>
                      <span class="text-muted">-</span>
                    <% end %>
                  </td>
                  <td>
                    <%= f.select "presences[#{attendance.id}]",
                        options_for_select([
                          ["Inscrit", "registered"],
                          ["Présent", "present"],
                          ["Absent", "absent"],
                          ["No-show", "no_show"]
                        ], attendance.status),
                        {},
                        { class: "form-select form-select-sm" } %>
                  </td>
                  <td>
                    <%= f.check_box "is_volunteer[#{attendance.id}]", { checked: attendance.is_volunteer? }, "1", "0" %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% else %>
        <p class="text-muted">Aucun bénévole inscrit.</p>
      <% end %>
    </div>
  </div>

  <!-- Tableau Participants -->
  <div class="card mb-4">
    <div class="card-header">
      <h5 class="mb-0">Participants (<%= @participants.count %>)</h5>
    </div>
    <div class="card-body">
      <% if @participants.any? %>
        <div class="table-responsive">
          <table class="table table-sm">
            <thead>
              <tr>
                <th>Nom</th>
                <th>Email</th>
                <th>Matériel</th>
                <th>Essai gratuit</th>
                <th>Présence</th>
                <th>Bénévole</th>
              </tr>
            </thead>
            <tbody>
              <% @participants.each do |attendance| %>
                <%= f.hidden_field "attendance_ids[]", value: attendance.id %>
                <tr>
                  <td><%= attendance.participant_name %></td>
                  <td><%= attendance.user.email %></td>
                  <td>
                    <% if attendance.equipment_note.present? %>
                      <small><%= attendance.equipment_note %></small>
                      <% if attendance.roller_size.present? %>
                        <br><small class="text-muted">Taille: <%= attendance.roller_size %></small>
                      <% end %>
                    <% else %>
                      <span class="text-muted">-</span>
                    <% end %>
                  </td>
                  <td>
                    <% if attendance.free_trial_used? %>
                      <span class="badge bg-danger">Oui</span>
                    <% else %>
                      <span class="text-muted">Non</span>
                    <% end %>
                  </td>
                  <td>
                    <%= f.select "presences[#{attendance.id}]",
                        options_for_select([
                          ["Inscrit", "registered"],
                          ["Présent", "present"],
                          ["Absent", "absent"],
                          ["No-show", "no_show"]
                        ], attendance.status),
                        {},
                        { class: "form-select form-select-sm" } %>
                  </td>
                  <td>
                    <%= f.check_box "is_volunteer[#{attendance.id}]", { checked: attendance.is_volunteer? }, "1", "0" %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% else %>
        <p class="text-muted">Aucun participant inscrit.</p>
      <% end %>
    </div>
  </div>

  <!-- Actions -->
  <div class="card">
    <div class="card-body">
      <%= f.submit "Sauvegarder présences", class: "btn btn-primary btn-lg" %>
      <%= link_to "Annuler", admin_panel_initiation_path(@initiation), class: "btn btn-outline-secondary" %>
    </div>
  </div>
<% end %>
```

---

## ✅ Vue 4 : Index RollerStock

**Fichier** : `app/views/admin_panel/roller_stocks/index.html.erb`

```erb
<% 
  breadcrumb_items = [
    { label: "Stock Rollers", url: nil }
  ]
%>

<%= render 'admin_panel/shared/breadcrumb', breadcrumb_items: breadcrumb_items %>

<div class="d-flex justify-content-between align-items-center mb-4">
  <h1>Stock Rollers</h1>
  <%= link_to "Nouveau stock", new_admin_panel_roller_stock_path, class: "btn btn-primary" %>
</div>

<!-- Filtres -->
<div class="card mb-4">
  <div class="card-body">
    <%= search_form_for @q, url: admin_panel_roller_stocks_path, method: :get, class: "row g-3" do |f| %>
      <div class="col-md-3">
        <%= f.label :is_active_eq, "Statut", class: "form-label" %>
        <%= f.select :is_active_eq,
            options_for_select([
              ["Tous", ""],
              ["Actifs", true],
              ["Inactifs", false]
            ], params.dig(:q, :is_active_eq)),
            {},
            { class: "form-select" } %>
      </div>
      <div class="col-md-3">
        <label class="form-label">Scope</label>
        <%= select_tag :scope,
            options_for_select([
              ["Tous", ""],
              ["Disponibles", "available"]
            ], params[:scope]),
            { class: "form-select" } %>
      </div>
      <div class="col-md-4 d-flex align-items-end gap-2">
        <%= f.submit "Filtrer", class: "btn btn-outline-primary" %>
        <%= link_to "Réinitialiser", admin_panel_roller_stocks_path, class: "btn btn-outline-secondary" %>
      </div>
    <% end %>
  </div>
</div>

<!-- Tableau Stock -->
<div class="card mb-4">
  <div class="card-body">
    <% if @roller_stocks.any? %>
      <div class="table-responsive">
        <table class="table table-hover">
          <thead>
            <tr>
              <th>Taille (EU)</th>
              <th>Quantité</th>
              <th>Statut</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <% @roller_stocks.each do |stock| %>
              <tr>
                <td><strong><%= stock.size %></strong></td>
                <td>
                  <% if stock.quantity > 0 %>
                    <span class="badge bg-success"><%= stock.quantity %></span>
                  <% else %>
                    <span class="badge bg-danger">0</span>
                  <% end %>
                </td>
                <td>
                  <% if stock.is_active? %>
                    <span class="badge bg-success">Actif</span>
                  <% else %>
                    <span class="badge bg-secondary">Inactif</span>
                  <% end %>
                </td>
                <td>
                  <div class="btn-group btn-group-sm">
                    <%= link_to "Voir", admin_panel_roller_stock_path(stock), class: "btn btn-outline-primary" %>
                    <%= link_to "Éditer", edit_admin_panel_roller_stock_path(stock), class: "btn btn-outline-secondary" %>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
      
      <!-- Pagination -->
      <div class="mt-3">
        <%== pagy_bootstrap_nav(@pagy) if @pagy.pages > 1 %>
      </div>
    <% else %>
      <div class="alert alert-info">
        Aucun stock trouvé.
      </div>
    <% end %>
  </div>
</div>

<!-- Demandes en attente -->
<% if @pending_requests.any? %>
  <div class="card">
    <div class="card-header">
      <h5 class="mb-0">Demandes en attente</h5>
    </div>
    <div class="card-body">
      <div class="table-responsive">
        <table class="table table-sm">
          <thead>
            <tr>
              <th>Nom</th>
              <th>Email</th>
              <th>Taille demandée</th>
              <th>Initiation</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            <% @pending_requests.each do |attendance| %>
              <tr>
                <td><%= attendance.participant_name %></td>
                <td><%= attendance.user.email %></td>
                <td><strong><%= attendance.roller_size %></strong></td>
                <td><%= attendance.event.title %></td>
                <td><%= l(attendance.created_at, format: :short) %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
  </div>
<% end %>
```

---

## ✅ Checklist Globale

### **Phase 5 (Semaine 5)**
- [x] Créer vue index initiations (sections séparées, bouton création conditionnel)
- [x] Créer vue show initiations (panel matériel, bouton édition conditionnel)
- [x] Créer vue presences initiations (statuts traduits)
- [x] Créer vue index roller_stocks
- [x] Créer vue show roller_stocks
- [x] Créer vue new/edit roller_stocks
- [x] Helpers traduction (attendance_status_fr, waitlist_status_fr)
- [x] Tester toutes les vues (tests RSpec)

---

## 🔐 Permissions dans les Vues

**Boutons conditionnels** :
- Bouton "Créer une initiation" : Visible uniquement si `current_user&.role&.level.to_i >= 60`
- Bouton "Éditer" : Visible uniquement si `current_user&.role&.level.to_i >= 60`

**Sidebar** : Les liens sont conditionnels selon le grade (voir `app/views/admin/shared/_sidebar.html.erb`)

---

**Retour** : [README Initiations](./README.md) | [INDEX principal](../INDEX.md) | [Permissions](../PERMISSIONS.md)

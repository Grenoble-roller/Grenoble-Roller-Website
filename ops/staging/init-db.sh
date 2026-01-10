#!/bin/bash
###############################################################################
# Script d'initialisation de la base de données STAGING
# Usage: ./ops/staging/init-db.sh
# Effectue: db:migrate (PostgreSQL - inclut Solid Queue) + db:seed
#
# ⚠️  SOLID QUEUE :
#    - Solid Queue utilise PostgreSQL (même base que l'application)
#    - Les migrations Solid Queue sont dans db/migrate
#    - Gérées par db:migrate normal
#
# ⚠️  IMPORTANT : Ce script nécessite que le conteneur soit running
#    - Si le conteneur s'arrête (Solid Queue crash), redémarrer d'abord
#    - Le docker-entrypoint applique automatiquement les migrations SQLite au démarrage
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Charger les modules nécessaires
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/core/colors.sh"
source "${LIB_DIR}/core/logging.sh"
source "${LIB_DIR}/docker/containers.sh"

CONTAINER_NAME="grenoble-roller-staging"

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🌱 INITIALISATION BASE DE DONNÉES - STAGING"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Vérifier que le conteneur est running
if ! container_is_running "$CONTAINER_NAME"; then
    log_error "❌ Le conteneur ${CONTAINER_NAME} n'est pas en cours d'exécution"
    log_error "Démarrez-le avec: docker compose -f ops/staging/docker-compose.yml up -d"
    exit 1
fi

log_success "✅ Conteneur ${CONTAINER_NAME} est running"

# 1. Vérifier si seeds.rb a changé (comparaison MD5)
log "🔍 Vérification de seeds.rb..."
if [ -f "$REPO_DIR/db/seeds.rb" ]; then
    LOCAL_SEEDS_HASH=$(md5sum "$REPO_DIR/db/seeds.rb" 2>/dev/null | cut -d' ' -f1 || echo "")
    CONTAINER_SEEDS_HASH=$(docker exec "$CONTAINER_NAME" md5sum /rails/db/seeds.rb 2>/dev/null | cut -d' ' -f1 || echo "")
    
    if [ -n "$LOCAL_SEEDS_HASH" ] && [ -n "$CONTAINER_SEEDS_HASH" ]; then
        if [ "$LOCAL_SEEDS_HASH" != "$CONTAINER_SEEDS_HASH" ]; then
            log_warning "⚠️  seeds.rb a changé localement"
            log_warning "   Local:    ${LOCAL_SEEDS_HASH:0:8}..."
            log_warning "   Conteneur: ${CONTAINER_SEEDS_HASH:0:8}..."
            log_warning "   → Rebuild nécessaire pour prendre en compte les changements"
            log_warning "   Exécutez: ./ops/staging/deploy.sh --force"
            read -p "Continuer quand même ? (o/N) : " choice || choice="N"
            if [[ ! "$choice" =~ ^[OoYy]$ ]]; then
                log_info "Annulé"
                exit 0
            fi
        else
            log_success "✅ seeds.rb identique (pas de rebuild nécessaire)"
        fi
    fi
else
    log_error "❌ Fichier seeds.rb introuvable: $REPO_DIR/db/seeds.rb"
    exit 1
fi

# 2. Appliquer les migrations principales (PostgreSQL)
# ⚠️  IMPORTANT : db:migrate ne fait QUE appliquer les migrations en attente
#    - Ne supprime AUCUNE donnée existante
#    - Ne touche QUE la base PostgreSQL principale
#    - La queue SQLite reste complètement intacte
log "🔄 Application des migrations principales (PostgreSQL)..."
log_info "   ℹ️  db:migrate est SÉCURISÉ : applique uniquement les migrations en attente"
log_info "   ℹ️  Aucune donnée existante ne sera supprimée"
if docker exec "$CONTAINER_NAME" bin/rails db:migrate 2>&1 | tee -a /tmp/init-db.log; then
    log_success "✅ Migrations principales appliquées avec succès"
else
    log_error "❌ Échec des migrations principales"
    exit 1
fi

# Solid Queue utilise maintenant PostgreSQL (même base que l'application)
# Les migrations Solid Queue sont incluses dans db/migrate et gérées par db:migrate ci-dessus
log_info "ℹ️  Solid Queue utilise PostgreSQL (migrations incluses dans db:migrate)"

# 3. Seed de la base de données
# ⚠️ IMPORTANT : Utiliser seeds_staging.rb qui NE SUPPRIME PAS les données existantes
# seeds.rb contient des destroy_all qui supprimeraient toutes les données !
log "🌱 Exécution du seed staging..."
log_warning "⚠️  Cette opération va peupler la base de données (SANS supprimer les données existantes)"
log_info "   Utilisation de db/seeds_staging.rb (find_or_create_by! uniquement)"

# Vérifier que seeds_staging.rb existe
if [ ! -f "$REPO_DIR/db/seeds_staging.rb" ]; then
    log_error "❌ Fichier db/seeds_staging.rb introuvable"
    log_error "   Ce fichier est requis pour staging (sans destroy_all)"
    exit 1
fi

read -p "Continuer ? (o/N) : " choice || choice="N"
if [[ ! "$choice" =~ ^[OoYy]$ ]]; then
    log_info "Seed annulé"
    exit 0
fi

# Copier seeds_staging.rb dans le conteneur si nécessaire
log "📋 Copie de seeds_staging.rb dans le conteneur..."
if docker cp "$REPO_DIR/db/seeds_staging.rb" "${CONTAINER_NAME}:/rails/db/seeds_staging.rb"; then
    log_success "✅ Fichier copié dans le conteneur"
else
    log_error "❌ Échec de la copie du fichier"
    exit 1
fi

# Exécuter seeds_staging.rb via runner (car Rails ne charge pas seeds_staging.rb par défaut)
if docker exec "$CONTAINER_NAME" bin/rails runner "load Rails.root.join('db', 'seeds_staging.rb')" 2>&1 | tee -a /tmp/init-db.log; then
    log_success "✅ Seed staging terminé avec succès"
    
    # Vérifier le résultat
    ROLE_COUNT=$(docker exec "$CONTAINER_NAME" bin/rails runner "puts Role.count" 2>/dev/null | tr -d '\n\r' || echo "0")
    USER_COUNT=$(docker exec "$CONTAINER_NAME" bin/rails runner "puts User.count" 2>/dev/null | tr -d '\n\r' || echo "0")
    log_info "📊 Résultat:"
    log_info "   - Rôles: ${ROLE_COUNT}"
    log_info "   - Utilisateurs: ${USER_COUNT}"
else
    log_error "❌ Échec du seed staging"
    log_error "Consultez les logs ci-dessus pour plus de détails"
    exit 1
fi

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "✅ INITIALISATION TERMINÉE"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


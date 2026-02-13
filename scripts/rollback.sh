#!/bin/bash
#
# Production Rollback Script
# Usage: ./scripts/rollback.sh [IMAGE_TAG] [MIGRATION_STEPS]
#
# Examples:
#   ./scripts/rollback.sh main-abc1234        # Rollback to specific tag
#   ./scripts/rollback.sh main-abc1234 1      # Rollback to tag + rollback 1 migration
#   ./scripts/rollback.sh --list              # List deployment history
#   ./scripts/rollback.sh --previous          # Rollback to previous deployment
#
# This script should be copied to the production server at:
#   /home/stadmin/st_intent_harvest/scripts/rollback.sh
#

set -e

# Configuration
APP_NAME="${APP_NAME:-st_intent_harvest}"
APP_PATH="${APP_PATH:-/home/stadmin/${APP_NAME}}"
DEPLOY_HISTORY_FILE="${APP_PATH}/.deploy_history"
MAX_RETRIES=30
RETRY_INTERVAL=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# Show deployment history
show_history() {
    header "📋 Deployment History (Last 10)"

    if [ ! -f "$DEPLOY_HISTORY_FILE" ]; then
        log_warning "No deployment history found at $DEPLOY_HISTORY_FILE"
        exit 1
    fi

    echo ""
    echo "Timestamp                     | Deployed Tag       | Previous Tag"
    echo "------------------------------|--------------------|------------------"

    tail -n 10 "$DEPLOY_HISTORY_FILE" | while IFS='|' read -r timestamp deployed_tag previous_tag; do
        printf "%-29s | %-18s | %-18s\n" "$timestamp" "$deployed_tag" "$previous_tag"
    done

    echo ""
}

# Get previous deployment tag
get_previous_tag() {
    if [ ! -f "$DEPLOY_HISTORY_FILE" ]; then
        log_error "No deployment history found"
        exit 1
    fi

    # Ensure there are at least two deployments in history
    HISTORY_LINES=$(wc -l < "$DEPLOY_HISTORY_FILE")
    if [ "$HISTORY_LINES" -lt 2 ]; then
        log_error "Not enough deployment history to rollback (need at least 2 deployments)"
        exit 1
    fi

    # Get the second-to-last line (previous deployment)
    PREVIOUS_TAG=$(tail -n 2 "$DEPLOY_HISTORY_FILE" | head -n 1 | cut -d'|' -f2)

    if [ -z "$PREVIOUS_TAG" ] || [ "$PREVIOUS_TAG" = "none" ]; then
        log_error "No previous deployment found to rollback to"
        exit 1
    fi

    echo "$PREVIOUS_TAG"
}

# Perform rollback
do_rollback() {
    local IMAGE_TAG=$1
    local MIGRATION_STEPS=${2:-0}

    # Validate that MIGRATION_STEPS is a non-negative integer
    if ! [[ "$MIGRATION_STEPS" =~ ^[0-9]+$ ]]; then
        log_error "Invalid migration rollback steps: '${MIGRATION_STEPS}'. Must be a non-negative integer."
        exit 1
    fi

    header "🔄 Rolling back ${APP_NAME}"

    log_info "Target image tag: ${IMAGE_TAG}"
    log_info "Migration rollback steps: ${MIGRATION_STEPS}"

    cd "$APP_PATH"

    # Verify image exists
    log_info "Verifying image exists..."
    if ! pull_output=$(docker pull ghcr.io/arya020595/${APP_NAME}:${IMAGE_TAG} 2>&1); then
        log_error "Failed to pull image: ghcr.io/arya020595/${APP_NAME}:${IMAGE_TAG}"
        echo "$pull_output" >&2
        if echo "$pull_output" | grep -qiE "not found|manifest unknown"; then
            echo ""
            echo "Image appears to be missing. Available tags can be found at:"
            echo "  https://github.com/arya020595/${APP_NAME}/pkgs/container/${APP_NAME}"
        fi
        exit 1
    fi
    log_success "Image verified"

    # Update .env file
    log_info "Updating .env with rollback image..."
    if [ ! -f .env ]; then
        log_error ".env file not found at ${APP_PATH}/.env"
        log_error "Cannot update DOCKER_IMAGE; aborting rollback."
        exit 1
    fi
    sed -i "s|^DOCKER_IMAGE=.*|DOCKER_IMAGE=ghcr.io/arya020595/${APP_NAME}:${IMAGE_TAG}|" .env || true
    grep -q "^DOCKER_IMAGE=" .env || echo "DOCKER_IMAGE=ghcr.io/arya020595/${APP_NAME}:${IMAGE_TAG}" >> .env
    log_success ".env updated"

    # Rollback migrations if requested
    if [ "$MIGRATION_STEPS" -gt 0 ]; then
        log_info "Rolling back ${MIGRATION_STEPS} migration(s)..."
        docker compose exec -T web rails db:rollback STEP=${MIGRATION_STEPS}
        log_success "Migrations rolled back"
    fi

    # Restart services
    log_info "Restarting services..."
    docker compose up -d

    # Wait for health check
    log_info "Waiting for health check..."
    local retry_count=0
    while [ $retry_count -lt $MAX_RETRIES ]; do
        local container_id
        container_id=$(docker compose ps -q web || true)
        if [ -n "$container_id" ]; then
            local health_status
            health_status=$(docker inspect --format '{{.State.Health.Status}}' "$container_id" 2>/dev/null || echo "unknown")
            if [ "$health_status" = "healthy" ]; then
                log_success "Service is healthy!"
                break
            fi
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -eq $MAX_RETRIES ]; then
            log_error "Health check failed after $((MAX_RETRIES * RETRY_INTERVAL))s"
            docker compose ps
            docker compose logs --tail=50 web
            exit 1
        fi

        echo "  Attempt ${retry_count}/${MAX_RETRIES}..."
        sleep $RETRY_INTERVAL
    done

    # Record rollback in history (maintain consistent format)
    local timestamp
    timestamp="$(date -Iseconds)"
    local previous_tag=""
    if [ -f "$DEPLOY_HISTORY_FILE" ]; then
        previous_tag="$(tail -n 1 "$DEPLOY_HISTORY_FILE" | awk -F'|' '{print $2}')"
    fi
    echo "${timestamp}|${IMAGE_TAG}|${previous_tag}" >> "$DEPLOY_HISTORY_FILE"
    # Keep only last 10 deployments
    tail -n 10 "$DEPLOY_HISTORY_FILE" > "${DEPLOY_HISTORY_FILE}.tmp" && mv "${DEPLOY_HISTORY_FILE}.tmp" "$DEPLOY_HISTORY_FILE"

    header "✅ Rollback completed successfully!"
    echo ""
    echo "Rolled back to: ${IMAGE_TAG}"
    echo ""
    docker compose ps
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [IMAGE_TAG] [MIGRATION_STEPS]"
    echo ""
    echo "Options:"
    echo "  --list, -l       Show deployment history"
    echo "  --previous, -p   Rollback to previous deployment"
    echo "  --help, -h       Show this help message"
    echo ""
    echo "Arguments:"
    echo "  IMAGE_TAG        Docker image tag to rollback to (e.g., main-abc1234)"
    echo "  MIGRATION_STEPS  Number of migrations to rollback (default: 0)"
    echo ""
    echo "Examples:"
    echo "  $0 --list                    # Show deployment history"
    echo "  $0 --previous                # Rollback to previous deployment"
    echo "  $0 main-abc1234              # Rollback to specific tag"
    echo "  $0 main-abc1234 1            # Rollback to tag + rollback 1 migration"
    echo ""
    echo "Environment Variables:"
    echo "  APP_NAME    Application name (default: st_intent_harvest)"
    echo "  APP_PATH    Application path (default: /home/stadmin/\$APP_NAME)"
}

# Main
main() {
    case "${1:-}" in
        --list|-l)
            show_history
            ;;
        --previous|-p)
            PREVIOUS_TAG=$(get_previous_tag)
            log_info "Previous deployment tag: ${PREVIOUS_TAG}"
            read -p "Rollback to ${PREVIOUS_TAG}? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                do_rollback "$PREVIOUS_TAG" "${2:-0}"
            else
                log_warning "Rollback cancelled"
            fi
            ;;
        --help|-h)
            show_usage
            ;;
        "")
            show_usage
            exit 1
            ;;
        *)
            if [[ "$1" == --* ]]; then
                log_error "Unknown option: $1"
                show_usage
                exit 1
            fi
            do_rollback "$1" "${2:-0}"
            ;;
    esac
}

main "$@"

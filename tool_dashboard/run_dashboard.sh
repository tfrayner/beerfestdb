#!/usr/bin/env bash
# run_with_healthcheck.sh
#
# Starts CBF_tool_page.py via streamlit and restarts it if the
# Streamlit healthcheck endpoint stops responding.
#
# Usage:
#   ./run_with_healthcheck.sh [--port PORT] [--interval SECS] [--max-restarts N] [--streamlit-path /path/to/streamlit]
#
# Defaults:
#   PORT            8501
#   INTERVAL        30   (seconds between health polls)
#   MAX_RESTARTS    0    (0 = unlimited)
#   STREAMLIT_PATH "streamlit" (i.e. assumed to be in current $PATH)

set -euo pipefail

# ---------- defaults ----------------------------------------------------------
PORT=8501
INTERVAL=30
MAX_RESTARTS=0
HEALTH_URL="http://localhost:${PORT}/_stcore/health"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STREAMLIT_SCRIPT="${SCRIPT_DIR}/CBF_tool_page.py"
STREAMLIT_PATH="streamlit"
BACKOFF_INITIAL=5   # seconds to wait before first restart attempt
BACKOFF_MAX=300     # cap on backoff delay

# ---------- argument parsing --------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port)        PORT="$2";         HEALTH_URL="http://localhost:${PORT}/_stcore/health"; shift 2 ;;
        --interval)    INTERVAL="$2";     shift 2 ;;
        --max-restarts) MAX_RESTARTS="$2"; shift 2 ;;
	    --streamlit-path) STREAMLIT_PATH="$2"; shift 2;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ---------- helpers -----------------------------------------------------------
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

start_streamlit() {
    log "Starting streamlit on port ${PORT}..."
    ${STREAMLIT_PATH} run \
        --server.port "${PORT}" \
        --server.headless true \
        "${STREAMLIT_SCRIPT}" &
    STREAMLIT_PID=$!
    log "Streamlit started (PID ${STREAMLIT_PID})"
}

stop_streamlit() {
    if [[ -n "${STREAMLIT_PID:-}" ]] && kill -0 "${STREAMLIT_PID}" 2>/dev/null; then
        log "Stopping streamlit (PID ${STREAMLIT_PID})..."
        kill "${STREAMLIT_PID}"
        wait "${STREAMLIT_PID}" 2>/dev/null || true
    fi
    STREAMLIT_PID=""
}

cleanup() {
    log "Caught signal — shutting down."
    stop_streamlit
    exit 0
}

is_healthy() {
    local http_code
    http_code=$(curl -sf -o /dev/null -w "%{http_code}" \
        --max-time 10 "${HEALTH_URL}" 2>/dev/null) || return 1
    [[ "${http_code}" == "200" ]]
}

# ---------- main loop ---------------------------------------------------------
trap cleanup SIGINT SIGTERM

RESTART_COUNT=0
BACKOFF=${BACKOFF_INITIAL}

start_streamlit

# Give streamlit a moment to initialise before the first health check.
sleep "${BACKOFF_INITIAL}"

while true; do
    sleep "${INTERVAL}"

    # Check whether the process is still alive.
    if [[ -n "${STREAMLIT_PID:-}" ]] && ! kill -0 "${STREAMLIT_PID}" 2>/dev/null; then
        log "WARNING: Streamlit process (PID ${STREAMLIT_PID}) has exited unexpectedly."
        STREAMLIT_PID=""
    fi

    if ! is_healthy; then
        log "WARNING: Health check failed for ${HEALTH_URL}"

        RESTART_COUNT=$(( RESTART_COUNT + 1 ))
        if [[ "${MAX_RESTARTS}" -gt 0 && "${RESTART_COUNT}" -gt "${MAX_RESTARTS}" ]]; then
            log "ERROR: Reached maximum restart limit (${MAX_RESTARTS}). Exiting."
            stop_streamlit
            exit 1
        fi

        log "Restart #${RESTART_COUNT} — waiting ${BACKOFF}s before restarting..."
        stop_streamlit
        sleep "${BACKOFF}"

        # Exponential backoff, capped at BACKOFF_MAX.
        BACKOFF=$(( BACKOFF * 2 ))
        [[ "${BACKOFF}" -gt "${BACKOFF_MAX}" ]] && BACKOFF="${BACKOFF_MAX}"

        start_streamlit
        sleep "${BACKOFF_INITIAL}"   # grace period for new process to come up
    else
        # Healthy — reset backoff.
        BACKOFF=${BACKOFF_INITIAL}
    fi
done

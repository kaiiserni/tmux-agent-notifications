#!/usr/bin/env bash

HOOK_EVENT="$1"
LOG_FILE="$HOME/.claude/notifications.log"
TIMESTAMP=$(date '+%H:%M:%S')

if [ ! -t 0 ]; then
    JSON_DATA=$(cat)
fi

# Extract project name from cwd
if [ -n "$JSON_DATA" ]; then
    CWD=$(echo "$JSON_DATA" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
    PROJECT_NAME=$(basename "${CWD:-unknown}")
    PARENT_DIR=$(basename "$(dirname "$CWD")" 2>/dev/null)
    # Detect git worktrees (parent ends in .git)
    if [[ "$PARENT_DIR" == *.git ]]; then
        DISPLAY_NAME="${PARENT_DIR%.git}/$PROJECT_NAME"
    else
        DISPLAY_NAME="$PROJECT_NAME"
    fi
else
    PROJECT_NAME="unknown"
    DISPLAY_NAME="unknown"
fi

# Claude session title (strip leading symbols)
SESSION_TITLE=$(tmux display-message -p '#{pane_title}' 2>/dev/null | sed 's/^[^a-zA-Z0-9]* *//')
[[ "$SESSION_TITLE" == "Claude Code" ]] && SESSION_TITLE=""

parse_json() {
    echo "$JSON_DATA" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*: *"\([^"]*\)".*/\1/'
}

NOTIF_DIR="$HOME/.claude/.notifications"
mkdir -p "$NOTIF_DIR"

# Read configurable options from tmux
get_option() {
    tmux show-option -gqv "$1" 2>/dev/null
}

SESSION_PREFIX=$(get_option "@claude-notif-session-prefix")
SESSION_PREFIX="${SESSION_PREFIX:-cc-}"
NOTIF_FG=$(get_option "@claude-notif-fg")
NOTIF_FG="${NOTIF_FG:-#c8d3f5}"
ALERT_FG=$(get_option "@claude-notif-alert-fg")
ALERT_FG="${ALERT_FG:-yellow}"
ALERT_STYLE=$(get_option "@claude-notif-alert-style")
ALERT_STYLE="${ALERT_STYLE:-bold}"
ALERT_INDICATOR=$(get_option "@claude-notif-alert-indicator")
ALERT_INDICATOR="${ALERT_INDICATOR:- #[fg=red,bold](*)#[default]}"

is_user_watching() {
    tmux list-clients -F '#{pane_id}' 2>/dev/null | grep -q "^${TMUX_PANE}$"
}

tmux_alert() {
    local msg="$1"
    local session="${SESSION_PREFIX}${PROJECT_NAME}"
    local label="$DISPLAY_NAME"
    [ -n "$SESSION_TITLE" ] && label="$DISPLAY_NAME ($SESSION_TITLE)"

    if is_user_watching; then
        return 0
    fi

    echo "#[fg=${NOTIF_FG}][$TIMESTAMP] $label: #[fg=${ALERT_FG},${ALERT_STYLE}]$msg #[default]" > "$NOTIF_DIR/$PROJECT_NAME"
    echo "${TMUX_PANE}" > "$NOTIF_DIR/.pane_$PROJECT_NAME"
    tmux refresh-client -S 2>/dev/null

    if tmux has-session -t "$session" 2>/dev/null; then
        tmux set -t "$session" @cc_alert "$ALERT_INDICATOR"
        local log_pane="$session:0.2"
        if tmux list-panes -t "$session:0" -F '#{pane_index}' 2>/dev/null | grep -q '^2$'; then
            tmux set -p -t "$log_pane" pane-border-style 'fg=red'
        fi
    fi
}

log_event() {
    local icon="$1"
    local msg="$2"
    local label="$DISPLAY_NAME"
    [ -n "$SESSION_TITLE" ] && label="$DISPLAY_NAME ($SESSION_TITLE)"
    echo "[$TIMESTAMP] $icon $label: $msg" >> "$LOG_FILE"
}

tmux_clear_alert() {
    local session="${SESSION_PREFIX}${PROJECT_NAME}"

    rm -f "$NOTIF_DIR/$PROJECT_NAME" "$NOTIF_DIR/.pane_$PROJECT_NAME"
    tmux refresh-client -S 2>/dev/null

    if tmux has-session -t "$session" 2>/dev/null; then
        tmux set -t "$session" @cc_alert ""
        for pane in $(tmux list-panes -s -t "$session" -F '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null); do
            tmux set -p -t "$pane" pane-border-style 'fg=default' 2>/dev/null
        done
    fi
}

case "$HOOK_EVENT" in
    "Stop")
        log_event "done" "Agent has finished"
        tmux_alert "Agent has finished"
        ;;
    "Notification")
        MESSAGE=$(parse_json "message")
        MESSAGE=${MESSAGE:-"Needs attention"}
        MESSAGE=${MESSAGE//Claude/Agent}
        log_event "" "$MESSAGE"
        tmux_alert "$MESSAGE"
        ;;
    "UserPromptSubmit")
        tmux_clear_alert
        ;;
esac

exit 0

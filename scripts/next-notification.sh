#!/usr/bin/env bash

DIR="$HOME/.claude/.notifications"
[ ! -d "$DIR" ] && exit 0

SESSION_PREFIX=$(tmux show-option -gqv "@claude-notif-session-prefix" 2>/dev/null)
SESSION_PREFIX="${SESSION_PREFIX:-cc-}"

# Oldest notification first (waiting longest)
TARGET=$(ls -tr "$DIR" 2>/dev/null | grep -v '^\.' | head -1)
[ -z "$TARGET" ] && tmux display-message "No pending notifications" && exit 0

# Jump to the exact pane that created this notification
if [ -f "$DIR/.pane_$TARGET" ]; then
    PANE_ID=$(cat "$DIR/.pane_$TARGET")
    if tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -q "^${PANE_ID}$"; then
        tmux switch-client -t "$PANE_ID"
        tmux select-pane -t "$PANE_ID"
        exit 0
    fi
fi

# Fallback: try session with prefix
SESSION="${SESSION_PREFIX}${TARGET}"
if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux switch-client -t "$SESSION"
else
    tmux display-message "Session for $TARGET not found"
fi

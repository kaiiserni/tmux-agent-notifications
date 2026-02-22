#!/usr/bin/env bash

SESSION="$1"
PANE_PATH="$2"
PANE_ID="$3"
NOTIF_DIR="$HOME/.claude/.notifications"

SESSION_PREFIX=$(tmux show-option -gqv "@claude-notif-session-prefix" 2>/dev/null)
SESSION_PREFIX="${SESSION_PREFIX:-cc-}"

# Try pane path first (covers worktrees), then session name
PROJECT=""
if [ -n "$PANE_PATH" ]; then
    CANDIDATE=$(basename "$PANE_PATH")
    [ -f "$NOTIF_DIR/$CANDIDATE" ] && PROJECT="$CANDIDATE"
fi
if [ -z "$PROJECT" ] && [[ "$SESSION" == ${SESSION_PREFIX}* ]]; then
    CANDIDATE="${SESSION#$SESSION_PREFIX}"
    [ -f "$NOTIF_DIR/$CANDIDATE" ] && PROJECT="$CANDIDATE"
fi
[ -z "$PROJECT" ] && exit 0

# Only clear if the focused pane created this notification
if [ -n "$PANE_ID" ] && [ -f "$NOTIF_DIR/.pane_$PROJECT" ]; then
    EXPECTED_PANE=$(cat "$NOTIF_DIR/.pane_$PROJECT")
    [ "$PANE_ID" != "$EXPECTED_PANE" ] && exit 0
fi

rm -f "$NOTIF_DIR/$PROJECT" "$NOTIF_DIR/.pane_$PROJECT"
if [[ "$SESSION" == ${SESSION_PREFIX}* ]]; then
    tmux set -t "$SESSION" @cc_alert "" 2>/dev/null
    for pane in $(tmux list-panes -s -t "$SESSION" -F '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null); do
        tmux set -p -t "$pane" pane-border-style 'fg=default' 2>/dev/null
    done
fi
tmux refresh-client -S 2>/dev/null

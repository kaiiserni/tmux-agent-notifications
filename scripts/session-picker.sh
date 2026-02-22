#!/usr/bin/env bash

SELECTED=$(tmux list-sessions -F '#S' | while read -r s; do
    alert=$(tmux show -t "$s" -v @cc_alert 2>/dev/null)
    if [ -n "$alert" ]; then
        echo "(*) $s"
    else
        echo "   $s"
    fi
done | fzf --reverse --header='Switch session' | sed 's/^[(*) ]*//')

[ -z "$SELECTED" ] && exit 0

# Find clear script via plugin environment variable
SCRIPTS_DIR=$(tmux show-environment -g TMUX_CLAUDE_NOTIF_SCRIPTS 2>/dev/null | cut -d= -f2)
if [ -n "$SCRIPTS_DIR" ] && [ -x "$SCRIPTS_DIR/clear-notification.sh" ]; then
    "$SCRIPTS_DIR/clear-notification.sh" "$SELECTED"
fi

tmux switch-client -t "$SELECTED"

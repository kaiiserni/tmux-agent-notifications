#!/usr/bin/env bash
SESSION="$1"
PANE_PATH="$2"
PANE_ID="$3"
NOTIF_DIR="$HOME/.claude/.notifications"

[ -z "$PANE_ID" ] && exit 0

LIVE_PANES=$(tmux list-panes -a -F '#{pane_id}' 2>/dev/null)

for pane_file in "$NOTIF_DIR"/.pane_*; do
    [ -f "$pane_file" ] || continue
    STORED_PANE=$(cat "$pane_file")
    NOTIF_KEY=$(basename "$pane_file" | sed 's/^\.pane_//')

    # Clear if: this is the focused pane, or pane no longer exists, or empty pane ID
    if [ "$STORED_PANE" = "$PANE_ID" ] || ! echo "$LIVE_PANES" | grep -q "^${STORED_PANE}$" || [ -z "$(echo "$STORED_PANE" | tr -d '[:space:]')" ]; then
        rm -f "$pane_file" "$NOTIF_DIR/$NOTIF_KEY"
    fi
done

tmux refresh-client -S 2>/dev/null

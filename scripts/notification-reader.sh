#!/usr/bin/env bash

DIR="$HOME/.claude/.notifications"
[ ! -d "$DIR" ] && exit 0

FILES=$(ls -t "$DIR" 2>/dev/null | grep -v '^\.')
[ -z "$FILES" ] && exit 0

TOTAL=$(echo "$FILES" | wc -l | tr -d ' ')

# Read max display count from tmux option
MAX_DISPLAY=$(tmux show-option -gqv "@claude-notif-max-display" 2>/dev/null)
MAX_DISPLAY="${MAX_DISPLAY:-2}"

# Separator color
SEP_FG=$(tmux show-option -gqv "@claude-notif-separator-fg" 2>/dev/null)
SEP_FG="${SEP_FG:-#444a73}"

OUTPUT=""
SHOWN=0
while IFS= read -r file; do
    [ $SHOWN -ge "$MAX_DISPLAY" ] && break
    CONTENT=$(cat "$DIR/$file" 2>/dev/null)
    [ -z "$CONTENT" ] && continue
    [ -n "$OUTPUT" ] && OUTPUT="$OUTPUT  #[fg=${SEP_FG}]|#[default]  "
    OUTPUT="$OUTPUT$CONTENT"
    SHOWN=$((SHOWN + 1))
done <<< "$FILES"

if [ "$TOTAL" -gt "$SHOWN" ]; then
    OUTPUT="$OUTPUT  #[fg=${SEP_FG}]|#[fg=yellow,bold]  +$((TOTAL - SHOWN)) more"
elif [ "$TOTAL" -gt 1 ]; then
    OUTPUT="#[fg=${SEP_FG}]($TOTAL) #[default]$OUTPUT"
fi

echo "$OUTPUT"

# tmux-claude-notifications

Per-project notifications for Claude Code agents in your tmux status bar. Each agent gets its own notification that only disappears when you focus that specific pane.

## Features

- Multi-agent support: each project gets its own notification slot
- Smart clearing: notifications disappear only when you focus the exact pane
- Worktree-aware: shows `Project/worktree` instead of just the worktree name
- Session picker with notification indicators (fzf)
- `prefix + n` jumps to the oldest pending notification
- Notification log viewer
- Fully configurable colors, keybindings, and display options

## Requirements

- tmux 3.2+
- [Claude Code](https://claude.ai/claude-code) CLI
- [fzf](https://github.com/junegunn/fzf) (for session picker)

## Installation

### With TPM

Add to your `~/.tmux.conf`:

```tmux
set -g @plugin 'kaiiserni/tmux-claude-notifications'
```

Reload tmux: `prefix + I`

### Manual

```bash
git clone https://github.com/kaiiserni/tmux-claude-notifications.git ~/.tmux/plugins/tmux-claude-notifications
```

Add to your `~/.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-claude-notifications/claude-notifications.tmux
```

## Claude Code Setup

Add the following hooks to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.tmux/plugins/tmux-claude-notifications/scripts/claude-hook.sh Stop"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.tmux/plugins/tmux-claude-notifications/scripts/claude-hook.sh Notification"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.tmux/plugins/tmux-claude-notifications/scripts/claude-hook.sh UserPromptSubmit"
          }
        ]
      }
    ]
  }
}
```

## Configuration

All options are set via tmux `@` variables. Add these **before** the plugin line in your `~/.tmux.conf`:

### Keybindings

| Option | Default | Description |
|--------|---------|-------------|
| `@claude-notif-key-next` | `n` | Jump to oldest notification |
| `@claude-notif-key-picker` | `S` | Session picker with indicators |
| `@claude-notif-key-log` | _(none)_ | Log viewer popup |
| `@claude-notif-key-toggle` | _(none)_ | Toggle status line 2 |

```tmux
set -g @claude-notif-key-next 'n'
set -g @claude-notif-key-log 'N'
set -g @claude-notif-key-toggle 'T'
```

### Display

| Option | Default | Description |
|--------|---------|-------------|
| `@claude-notif-status-line` | `on` | Enable status line 2 for notifications |
| `@claude-notif-status-bg` | `default` | Background color for status line 2 |
| `@claude-notif-max-display` | `2` | Max notifications shown at once |
| `@claude-notif-fg` | `#c8d3f5` | Notification text color |
| `@claude-notif-alert-fg` | `yellow` | Alert message color |
| `@claude-notif-alert-style` | `bold` | Alert message style |
| `@claude-notif-separator-fg` | `#444a73` | Separator color between notifications |
| `@claude-notif-session-prefix` | `cc-` | Session name prefix for your Claude sessions |
| `@claude-notif-alert-indicator` | ` #[fg=red,bold](*)#[default]` | Status-left indicator for sessions with alerts |

```tmux
# TokyoNight Moon theme example
set -g @claude-notif-status-bg '#2f334d'
set -g @claude-notif-fg '#c8d3f5'
set -g @claude-notif-separator-fg '#444a73'
```

## How It Works

```
Claude Code hooks          tmux hooks
     |                          |
     v                          v
claude-hook.sh          clear-notification.sh
     |                          |
     v                          v
~/.claude/.notifications/   (reads pane ID)
  ProjectA                      |
  ProjectB                      v
  .pane_ProjectA          removes matching file
  .pane_ProjectB
     |
     v
notification-reader.sh --> status line 2
```

1. When Claude stops or sends a notification, `claude-hook.sh` writes a file per project
2. `notification-reader.sh` reads these files and displays them in status line 2
3. When you focus a pane, `clear-notification.sh` checks if it matches a notification's source pane
4. Only the matching notification is cleared — others remain visible

## Scripts

| Script | Purpose |
|--------|---------|
| `claude-hook.sh` | Main hook for Claude Code events |
| `notification-reader.sh` | Reads notifications for status line 2 |
| `clear-notification.sh` | Clears notification on pane/session focus |
| `next-notification.sh` | Jumps to the pane of the oldest notification |
| `session-picker.sh` | fzf session picker with alert indicators |
| `log-viewer.sh` | Notification log viewer popup |

## License

MIT

#!/usr/bin/env bash
# Read tmux-agent-indicator state for a given pane and emit a tmux-format coloured glyph.
# Usage: claude-indicator.sh <pane_id> [bold]
# Called from window-status-format where #{pane_id} is expanded before the shell runs.

PANE_ID="${1:-}"
BOLD="${2:-}"
[ -z "$PANE_ID" ] && exit 0

STATE=$(tmux show-environment -g "TMUX_AGENT_PANE_${PANE_ID}_STATE" 2>/dev/null | grep -o '[^=]*$')

if [ -n "$BOLD" ]; then
  case "$STATE" in
    running)     echo "#[fg=#a6e3a1,bold]● ";;
    needs-input) echo "#[fg=#f9e2af,bold]● ";;
    done)        echo "#[fg=#6c7086,bold]○ ";;
    *)           echo "  ";;
  esac
else
  case "$STATE" in
    running)     echo "#[fg=#a6e3a1]● ";;
    needs-input) echo "#[fg=#f9e2af]● ";;
    done)        echo "#[fg=#6c7086]○ ";;
    *)           echo "  ";;
  esac
fi

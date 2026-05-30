#!/usr/bin/env bash
# Bootstrap entry point — detects platform and delegates to the appropriate installer.
#
# Usage:
#   bash install.sh           # full install
#   bash install.sh --dry-run # print commands without running them

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

case "$(uname -s)" in
  Darwin)
    exec bash "$SCRIPT_DIR/install-mac.sh" "$@"
    ;;
  Linux)
    exec bash "$SCRIPT_DIR/install-linux.sh" "$@"
    ;;
  *)
    echo "Unsupported platform: $(uname -s)" >&2
    exit 1
    ;;
esac

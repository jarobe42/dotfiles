#!/usr/bin/env bash
# Bootstrap a fresh macOS install.
# Safe to re-run: all steps check before acting.
#
# Usage:
#   bash install-mac.sh           # full install
#   bash install-mac.sh --dry-run # print commands without running them

set -Eeuo pipefail

########################################################
# Flags
########################################################

DRY_RUN=false
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done
export DRY_RUN

########################################################
# Helpers (minimal, before common.sh is available)
########################################################

BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

info()    { printf "${BLUE}${BOLD}ℹ${RESET} ${BLUE}%s${RESET}\n" "$1"; }
success() { printf "${GREEN}${BOLD}✔${RESET} ${GREEN}%s${RESET}\n" "$1"; }
warn()    { printf "${YELLOW}${BOLD}⚠${RESET} ${YELLOW}%s${RESET}\n" "$1"; }
error()   { printf "${RED}${BOLD}✖${RESET} ${RED}%s${RESET}\n" "$1" >&2; }

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf "${YELLOW}[dry-run]${RESET} %s\n" "$*"
  else
    "$@"
  fi
}

header() {
  echo -e "\n${BOLD}${BLUE}══ $1 ══${RESET}"
}

########################################################
# Pre-flight
########################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export DOTFILES="$SCRIPT_DIR"

info "DOTFILES = $DOTFILES"

if [[ "$DRY_RUN" == true ]]; then
  warn "Dry-run mode — no changes will be made"
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  error "This script is for macOS only. Use install-linux.sh on Linux."
  exit 1
fi

########################################################
# Phase 1: Homebrew
########################################################

header "Homebrew"

if command -v brew &>/dev/null; then
  info "Homebrew already installed"
  run brew update
else
  info "Installing Homebrew..."
  if [[ "$DRY_RUN" == true ]]; then
    warn "[dry-run] /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  success "Homebrew installed"
fi

########################################################
# Phase 2: Install packages
########################################################

header "Packages"

# Add DOTFILES/bin to PATH so dot-packages is available
export PATH="$DOTFILES/bin:$PATH"

run dot-packages install
success "Packages done"

########################################################
# Phase 3: Link dotfiles
########################################################

header "Dotfiles"

run dot backup
run dot link all --verbose
success "Dotfiles linked"

########################################################
# Phase 4: Set default shell
########################################################

header "Shell"

run dot-shell change
success "Shell configured"

########################################################
# Phase 5: Git identity
########################################################

header "Git"

if [[ "$DRY_RUN" == true ]]; then
  info "[dry-run] skipping interactive git setup"
else
  dot-git setup
fi

########################################################
# Phase 6: Krew (kubectl plugin manager)
########################################################

header "Krew (kubectl plugin manager)"

run dot-cloud krew
success "Krew ready"

########################################################
# Done — print manual steps
########################################################

echo -e "\n${GREEN}${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║  Bootstrap complete!                         ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${RESET}\n"

cat <<'EOF'
Manual steps still required:

  1. Restart your terminal (shell change takes effect)

  2. Install neovim plugins on first launch:
     nvim  (lazy.nvim will run automatically)

  3. Configure keyboard layout if needed:
     System Settings > Keyboard

  4. Authenticate 1Password and sign in to sync credentials

  5. Set ANTHROPIC_API_KEY in ~/.zshenv.local for Zed's Claude assistant:
     export ANTHROPIC_API_KEY="$(op read 'op://Personal/Anthropic API/credential')"

EOF

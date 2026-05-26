#!/usr/bin/env bash
# Bootstrap a fresh CachyOS install.
# Safe to re-run: all steps check before acting.
#
# Usage:
#   bash install.sh           # full install
#   bash install.sh --dry-run # print commands without running them

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

########################################################
# Phase 1: System update
########################################################

header "System update"

run sudo pacman -Syu --noconfirm
success "System up to date"

########################################################
# Phase 2: Bootstrap paru (AUR helper)
########################################################

header "paru (AUR helper)"

if command -v paru &>/dev/null; then
  info "paru already installed"
else
  info "Installing paru from AUR..."
  run sudo pacman -S --needed --noconfirm git base-devel

  local_tmp=$(mktemp -d)
  trap 'rm -rf "$local_tmp"' EXIT

  run git clone https://aur.archlinux.org/paru.git "$local_tmp/paru"
  run bash -c "cd '$local_tmp/paru' && makepkg -si --noconfirm"

  success "paru installed"
fi

########################################################
# Phase 3: Install packages
########################################################

header "Packages"

# Add DOTFILES/bin to PATH so dot-packages is available
export PATH="$DOTFILES/bin:$PATH"

run dot-packages install
success "Packages done"

########################################################
# Phase 4: Link dotfiles
########################################################

header "Dotfiles"

run dot backup
run dot link all --verbose
success "Dotfiles linked"

########################################################
# Phase 5: Set default shell
########################################################

header "Shell"

run dot-shell change
success "Shell configured"

########################################################
# Phase 6: Git identity
########################################################

header "Git"

if [[ "$DRY_RUN" == true ]]; then
  info "[dry-run] skipping interactive git setup"
else
  dot-git setup
fi

########################################################
# Phase 7: Systemd user services
########################################################

header "Services"

run dot-services enable
success "Services enabled"

########################################################
# Phase 8: Niri first-run setup
########################################################

header "Niri"

run dot-niri setup
success "Niri ready"

########################################################
# Phase 9: Krew (kubectl plugin manager)
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

  1. Log out and back in (shell change takes effect, Docker group applies)

  2. Select "Niri" from the display manager on next login
     - Or: exec niri  (from a TTY)

  3. Set monitor outputs in ~/.config/niri/config.kdl
     Run inside a niri session:  niri msg outputs

  4. Install neovim plugins on first launch:
     nvim  (lazy.nvim will run automatically)

  5. Set a wallpaper (optional):
     Edit the swaybg line in ~/.config/niri/config.kdl

  6. Customise waybar, mako, and fuzzel in ~/.config/

EOF

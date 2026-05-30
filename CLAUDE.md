# CLAUDE.md — dotfiles repo

## Purpose

This repo is the single source of truth for setting up a personal environment
on both **Linux (CachyOS + GNOME)** and **macOS** from scratch. A fresh machine
should be fully productive after running one command:

```bash
bash install.sh
```

`install.sh` detects the platform and delegates to `install-linux.sh` or
`install-mac.sh` automatically.

"Fully productive" means: shell configured, editor working with plugins, git
set up, cloud tools (AWS + kubectl) authenticated, all preferred apps installed.
Nothing should require manual hunting after the bootstrap completes.

---

## Guiding principles

### Prefer common, well-maintained tools

When choosing a tool or package, default to the option with the broadest
adoption and active maintenance — not the most feature-rich or interesting
one. Examples:

- `kubectl` + `kubectx` + `k9s` over obscure K8s TUI wrappers
- `helm` over custom templating scripts
- `ghostty` (active, popular) over a niche terminal with a clever feature
- `waybar` (widely used Wayland bar) over something more bespoke

If a tool hasn't had a commit in 2+ years, there's almost certainly a better
maintained alternative. Find it.

### Simple, reproducible installs

- `install.sh` must be **idempotent** — safe to run multiple times on the
  same machine without side effects
- Package lists are the canonical record of what should be installed. If you
  install something manually, add it to the right list
- Don't hard-code usernames, hostnames, or absolute paths. Use `$HOME`,
  `$XDG_CONFIG_HOME`, `$DOTFILES`
- Machine-specific config belongs in `.zshrc.local` or `.gitconfig-local`,
  never committed

### Avoid unnecessary bespoke config

Don't invent custom solutions for problems that standard tools solve well.
Examples of what NOT to do:

- Writing a custom log-tailing script when `stern` exists
- Bespoke AWS credential handling when `credential_process` + `op` is the
  standard pattern
- Custom prompt from scratch when the existing nicknisi-derived prompt works

The threshold for custom config: only if no maintained tool exists, or the
tool's defaults are genuinely unsuitable and a small config change fixes it.

### Completeness over minimalism

This is not a minimal rice. It's a working environment. When in doubt,
include the tool. Missing a tool on a fresh machine is more disruptive than
having one extra package installed.

---

## Repo structure

```
dotfiles/
├── install.sh              # platform-detecting entry point
├── install-linux.sh        # CachyOS/Arch bootstrap
├── install-mac.sh          # macOS bootstrap
├── bin/
│   ├── dot                 # symlink manager (link/unlink/backup/clean)
│   ├── dot-*               # subcommands — each is a discrete setup phase
│   ├── aws-op-credentials  # 1Password-backed AWS credential_process helper
│   └── lib/common.sh       # shared logging, colours, spinner, is_mac/is_linux
├── config/
│   ├── shared/             # linked on both platforms
│   │   ├── zsh/            # shell (.zshenv, .zshrc, .zsh_aliases, .zsh_cloud…)
│   │   ├── nvim/           # neovim (nisi.setup via lazy.nvim)
│   │   ├── git/            # git config (no personal identity — set via dot git setup)
│   │   ├── aws/            # AWS CLI config (credential_process, no stored secrets)
│   │   └── …
│   ├── linux/              # Linux-only configs
│   │   └── albert/         # app launcher (Meta+D)
│   └── mac/                # macOS-only configs (empty — add as needed)
└── packages/
    ├── linux/
    │   ├── base.txt        # core CLI tools
    │   ├── desktop.txt     # Wayland stack + GUI apps
    │   ├── cloud.txt       # kubectl, helm, k9s, aws-cli, etc.
    │   ├── aur.txt         # AUR-only packages
    │   └── dev.txt         # language toolchains (populate as needed)
    └── mac/
        └── Brewfile        # all macOS packages (brew + cask + fonts)
```

---

## Making changes

### Adding a package

**Linux:** Add to the appropriate `packages/linux/*.txt` file with a comment.
AUR-only goes in `aur.txt`. Cloud/K8s tooling goes in `cloud.txt`.

**macOS:** Add to `packages/mac/Brewfile` — `brew` for CLI tools, `cask` for
GUI apps, fonts use `cask "font-*"`.

**Validate:** `bash install.sh --dry-run`

### Adding a config

1. Decide if it's shared (both platforms), linux-only, or mac-only
2. Create `config/shared/<tool>/`, `config/linux/<tool>/`, or `config/mac/<tool>/`
3. `dot link <tool>` — or just `dot link all` (skips already-linked)
4. Test it. The config should work on first boot without further editing
   (use sensible defaults; let `.local` files handle overrides)

### Adding a new `dot-*` subcommand

1. Create `bin/dot-<name>` — executable bash script
2. Source `$DOTFILES/bin/lib/common.sh` for logging functions and `is_mac`/`is_linux`
3. Include a `# Description: ...` comment on line 2 (shown in `dot help`)
4. If platform-specific, guard with `is_mac` or `is_linux` at the top
5. If it's a bootstrap phase, add it to the appropriate `install-*.sh`

### Modifying install scripts

- Each phase uses `run <cmd>` — this respects `--dry-run` automatically
- Phases should be idempotent (`command -v foo` checks, `--needed` flags, etc.)
- `install-linux.sh`: packages → dotfiles → shell → git → services → GNOME → krew
- `install-mac.sh`: homebrew → packages → dotfiles → shell → git → krew

---

## Testing

**Linux — Docker dry-run:**
```bash
docker run --rm --platform linux/amd64 \
  -v "$(pwd):/dotfiles" \
  -e DOTFILES=/dotfiles \
  archlinux:latest \
  bash -c "export PATH=/dotfiles/bin:\$PATH && bash /dotfiles/install-linux.sh --dry-run"
```

**macOS — link test (on this machine):**
```bash
export DOTFILES=/path/to/dotfiles
export PATH="$DOTFILES/bin:$PATH"
dot link all --verbose
```

Both should exit 0. If they don't, fix before committing.

---

## What this repo does NOT do

- Store secrets — credentials live in 1Password, fetched at runtime
- Install GUI themes beyond what's in the committed configs
- Manage personal data (SSH keys, GPG keys, browser profiles)

These are handled outside the repo and documented as manual post-install steps
in the install scripts' printed output.

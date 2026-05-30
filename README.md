# dotfiles

Personal dotfiles for CachyOS + GNOME. Managed with a custom `dot` CLI — no
external tool dependency, just shell scripts.

## Quickstart

On a fresh CachyOS install:

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
bash install.sh
```

That's it. The script is safe to re-run.

---

## What `install.sh` does

1. `sudo pacman -Syu` — system update
2. Installs `paru` (AUR helper) if not present
3. Installs all packages from `packages/`
4. Backs up any conflicting dotfiles, then symlinks everything
5. Sets default shell to zsh
6. Prompts for git identity (written to `~/.gitconfig-local`)
7. Enables systemd user services (pipewire, wireplumber)
8. Enables GDM and verifies GNOME is installed

Prints a list of remaining manual steps at the end.

---

## Directory structure

```
dotfiles/
├── bin/
│   ├── dot              # main CLI
│   ├── dot-git          # git identity setup
│   ├── dot-gnome        # GNOME first-run setup
│   ├── dot-packages     # install packages
│   ├── dot-services     # enable systemd user services
│   ├── dot-shell        # set default shell
│   ├── dot-update       # update everything
│   └── lib/common.sh    # shared logging/colour helpers
├── config/              # symlinked into ~/.config/
│   ├── albert/          # app launcher (Meta+D)
│   ├── ghostty/         # terminal emulator
│   ├── git/             # git config + global ignore
│   ├── lazygit/         # lazygit config
│   ├── nvim/            # neovim (nisi setup via lazy.nvim)
│   ├── ripgrep/         # ripgrep defaults
│   ├── zed/             # Zed editor (theme, vim mode, Claude assistant)
│   └── zsh/             # shell config
├── packages/
│   ├── base.txt         # core CLI tools
│   ├── desktop.txt      # Wayland stack + GUI apps
│   ├── aur.txt          # AUR packages
│   └── dev.txt          # dev toolchains (add as needed)
└── install.sh
```

---

## `dot` CLI reference

`dot` is the dotfiles manager. Add `dotfiles/bin` to your PATH and all
`dot-*` scripts become available as subcommands.

### Built-in commands

```bash
dot link [all | <pkg>] [-v]   # symlink config/<pkg> → ~/.config/<pkg>
dot unlink [all | <pkg>] [-v] # remove symlinks
dot backup [-d <dir>]         # backup existing files before linking
dot clean                     # remove broken symlinks
```

**Linking a single package:**
```bash
dot link niri       # links config/niri → ~/.config/niri
dot link zsh        # links config/zsh  → ~/.config/zsh
```

**Full link with verbose output:**
```bash
dot link all -v
```

### Subcommands

```bash
dot packages [install | install <list> | list] [--dry-run]
dot git setup
dot shell change
dot shell terminfo
dot services [enable | status]
dot gnome [setup | dirs]
dot update [packages | nvim | dotfiles | zsh | all]
```

---

## Day-to-day usage

### After making config changes

Changes to files in `config/` take effect immediately — the files are
symlinked, so edits in either location are the same file.

Reload zsh:
```bash
reload!
```

### Adding a new config

1. Create `config/<tool>/` with the config file(s).
2. Run `dot link <tool>`.
3. Commit.

```bash
mkdir -p config/zed
# ... add config/zed/settings.json
dot link zed
git add config/zed
git commit -m "add zed config"
```

### Updating everything

```bash
dot update all
```

Runs: pacman/paru update → neovim plugins → zsh plugins → dotfiles git pull.

Individual updates:
```bash
dot update packages   # pacman -Syu + paru -Sua
dot update nvim       # :Lazy sync
dot update zsh        # git pull on all zfetch plugins
dot update dotfiles   # git pull --ff-only
```

### Installing new packages

1. Add the package name to the appropriate `packages/*.txt` file.
2. Run `dot packages install <list>` (or `install all`).
3. Commit the package list change.

```bash
echo "htop" >> packages/base.txt
dot packages install base
git add packages/base.txt && git commit -m "add htop"
```

---

## Machine-specific overrides

These files are sourced automatically but not committed — create them for
anything machine-specific.

| File | Purpose |
|------|---------|
| `~/.zshrc.local` | Machine-specific shell config (work proxies, extra PATH, etc.) |
| `~/.zshenv.local` | Machine-specific env vars sourced on every shell invocation |
| `~/.gitconfig-local` | Git identity + credential helper (written by `dot git setup`) |

---

## What the `dot` link command does

`dot link all` symlinks:
- Each directory in `config/` → `~/.config/<name>`
- `config/zsh/.zshenv` → `~/.zshenv` (special case — must live in `$HOME`)

It skips anything already correctly linked, and warns (does not overwrite) if a
real file exists at the target. Run `dot backup` first if you have existing
configs to preserve.

---

## Neovim

Config is at `config/nvim/`. Uses `lazy.nvim` for plugin management, with the
`nisi` setup module:

```lua
-- config/nvim/init.lua
local nisi = require("nisi")
nisi.setup({
  python = true,
  transparent = true,
  colorscheme = "tokyonight-night",
})
```

On first launch, `lazy.nvim` installs all plugins automatically.

Useful commands:
```
:Lazy          — plugin manager UI
:LspInfo       — active LSP servers for current file
:Mason         — LSP/tool installer
:checkhealth   — diagnose any setup issues
```

---

## Extending with new `dot` subcommands

Any executable named `dot-<something>` in your `$PATH` is automatically
discovered by `dot` and shown in `dot help`.

```bash
# Create a new subcommand
cat > bin/dot-fonts << 'EOF'
#!/usr/bin/env bash
# Description: Install and refresh fonts
fc-cache -fv
EOF
chmod +x bin/dot-fonts

# Now available as:
dot fonts
```

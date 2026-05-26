# .zshenv is sourced on all invocations of the shell, unless the -f option is set.
# It should contain commands to set the command search path and important env vars.
# Should not produce output or assume an attached tty.

export XDG_CONFIG_HOME="$HOME/.config"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# DOTFILES points to the root of this repo.
# Resolved from the location of this file: config/zsh/.zshenv → (up 3) = dotfiles root
export DOTFILES="$(dirname "$(dirname "$(dirname "$(readlink -f "${(%):-%N}")")")")"

export CACHEDIR="$HOME/.local/share"
export VIM_TMP="$HOME/.vim-tmp"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

[[ -d "$CACHEDIR" ]] || mkdir -p "$CACHEDIR"
[[ -d "$VIM_TMP" ]] || mkdir -p "$VIM_TMP"

[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local

fpath=(
    $DOTFILES/config/zsh/functions
    /usr/share/zsh/site-functions
    $fpath
)

typeset -aU path

export EDITOR='nvim'
export GIT_EDITOR='nvim'

# uv and user-installed tools
export PATH="$HOME/.local/bin:$PATH"

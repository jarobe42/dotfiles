########################################################
# Completion initialisation
# Must happen near the top before any completion config
########################################################

source "$ZDOTDIR/.zsh_functions"

autoload -U compinit add-zsh-hook
compinit


########################################################
# PATH
########################################################

prepend_path $DOTFILES/bin        # dot CLI and custom scripts
prepend_path $HOME/bin            # personal one-off scripts
prepend_path $HOME/.local/bin     # uv tools, pip installs, etc.

# Code directory — used by the c() function in .zsh_functions
if [[ -d ~/Projects ]]; then
    export CODE_DIR=~/Projects
fi


########################################################
# Shell behaviour
########################################################

export REPORTTIME=10    # print time for commands taking > 10s
export KEYTIMEOUT=1     # 10ms delay for key sequences (vi mode)

setopt NO_BG_NICE       # don't lower priority of background jobs
setopt NO_HUP           # don't kill background jobs when shell exits
setopt NO_LIST_BEEP
setopt LOCAL_OPTIONS
setopt LOCAL_TRAPS
setopt PROMPT_SUBST

# History
setopt EXTENDED_HISTORY          # record timestamp in history
setopt HIST_REDUCE_BLANKS        # strip extra blanks
setopt SHARE_HISTORY             # share history across all sessions
setopt HIST_IGNORE_ALL_DUPS      # deduplicate history

setopt COMPLETE_ALIASES


########################################################
# Key bindings
# Terminal navigation keycodes vary by terminal emulator.
# These cover the most common cases.
########################################################

bindkey "^[[1;5C" forward-word                      # Ctrl-right
bindkey "^[[1;5D" backward-word                     # Ctrl-left
bindkey '^[^[[C' forward-word
bindkey '^[^[[D' backward-word
bindkey '^[[1;3D' beginning-of-line                 # Alt-left
bindkey '^[[1;3C' end-of-line                       # Alt-right
bindkey '^[[5D' beginning-of-line
bindkey '^[[5C' end-of-line
bindkey '^?' backward-delete-char                   # Backspace
if [[ "${terminfo[kdch1]}" != "" ]]; then
    bindkey "${terminfo[kdch1]}" delete-char        # Delete (terminfo)
else
    bindkey "^[[3~" delete-char
    bindkey "^[3;5~" delete-char
    bindkey "\e[3~" delete-char
fi
bindkey "^A" vi-beginning-of-line
bindkey -M viins "^F" vi-forward-word
bindkey -M viins "^E" vi-add-eol
bindkey "^J" history-beginning-search-forward       # history prefix search
bindkey "^K" history-beginning-search-backward


########################################################
# Completion styling
########################################################

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'    # case-insensitive
zstyle ':completion:*' insert-tab pending               # no tab-completion with pasted content
zstyle ':completion:*' completer _expand _complete _files _correct _approximate
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' group-name ''


########################################################
# tmux auto-attach
# Attach to (or create) a session called "main" on every new terminal.
# -A: attach if the session exists, create it if not.
# exec: replaces the outer shell so there's no dangling process.
# Skipped if already inside tmux, or if tmux isn't installed yet.
########################################################

if command -v tmux &>/dev/null && [[ -z "$TMUX" ]]; then
  exec tmux new-session -A -s main
fi

########################################################
# Plugin setup
# Uses zfetch (defined in .zsh_functions) — a minimal git-based plugin manager.
# Plugins are cloned to $ZPLUGDIR on first use and sourced automatically.
########################################################

export ZPLUGDIR="$CACHEDIR/zsh/plugins"
[[ -d "$ZPLUGDIR" ]] || mkdir -p "$ZPLUGDIR"
typeset -A plugins

zfetch mafredri/zsh-async async.plugin.zsh              # async worker (needed for prompt)
zfetch zsh-users/zsh-syntax-highlighting                # syntax highlighting as you type
zfetch zsh-users/zsh-autosuggestions                    # fish-style suggestions from history
zfetch grigorii-zander/zsh-npm-scripts-autocomplete     # npm script tab completion
zfetch Aloxaf/fzf-tab                                   # replace completion menu with fzf


########################################################
# Tool hooks
# Each tool injects itself into the shell here.
########################################################

# Node version management via fnm
if [[ -x "$(command -v fnm)" ]]; then
    eval "$(fnm env --use-on-cd)"
fi

# Custom terminfo (for italic support in tmux/nvim)
[[ -e ~/.terminfo ]] && export TERMINFO_DIRS=~/.terminfo:/usr/share/terminfo

# fzf — fuzzy finder shell integration
if [[ -x "$(command -v fzf)" ]]; then
  export FZF_DEFAULT_COMMAND='fd --type f'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_DEFAULT_OPTS="--color bg:-1,bg+:-1,fg:-1,fg+:#feffff,hl:#993f84,hl+:#d256b5,info:#676767,prompt:#676767,pointer:#676767"
  source <(fzf --zsh)
fi

# zoxide — smarter cd with frecency
if [[ -x "$(command -v zoxide)" ]]; then
    eval "$(zoxide init zsh --hook pwd)"
fi

# direnv — per-directory env vars
if [[ -x "$(command -v direnv)" ]]; then
    eval "$(direnv hook zsh)"
fi

# pnpm (if used)
if [[ -x "$(command -v pnpm)" ]]; then
  export PNPM_HOME="$HOME/.local/share/pnpm"
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi


########################################################
# Coloured man pages
########################################################

export MANROFFOPT='-c'
export LESS_TERMCAP_mb=$(tput bold; tput setaf 2)
export LESS_TERMCAP_md=$(tput bold; tput setaf 6)
export LESS_TERMCAP_me=$(tput sgr0)
export LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4)
export LESS_TERMCAP_se=$(tput rmso; tput sgr0)
export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 7)
export LESS_TERMCAP_ue=$(tput rmul; tput sgr0)
export LESS_TERMCAP_mr=$(tput rev)
export LESS_TERMCAP_mh=$(tput dim)


########################################################
# Local overrides
# Machine-specific config that isn't committed.
########################################################

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.localrc ]] && source ~/.localrc


########################################################
# Source remaining config files
########################################################

for file in "$ZDOTDIR/.zsh_prompt" "$ZDOTDIR/.zsh_aliases" "$ZDOTDIR/.zsh_cloud"; do
    [[ -f $file ]] && source $file
done

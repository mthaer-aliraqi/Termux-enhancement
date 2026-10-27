#!/data/data/com.termux/files/usr/bin/bash
# Termux auto-setup v4.
# - Every network or package step is retried up to 3 times in total.
# - If a required step still fails after 3 tries, the script prints a red error and stops.
# - Installs all dependencies first, then checks each one before configuring anything.
# Safe to run more than once.

set -u

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
ok()   { printf '\033[1;32m[OK] %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$1"; }
fail() { printf '\033[1;31m[X] ERROR: %s\033[0m\n' "$1"; printf '\033[1;31m[X] Setup stopped. Fix the problem above and run the script again.\033[0m\n'; exit 1; }

# retry <description> <command...>
# Tries the command up to 3 times (1 try + 2 retries), waiting 3 seconds between tries.
retry() {
  local desc="$1"; shift
  local attempt=1
  until "$@"; do
    if [ "$attempt" -ge 3 ]; then
      return 1
    fi
    attempt=$((attempt + 1))
    warn "$desc failed. Retry $attempt of 3 in 3 seconds..."
    sleep 3
  done
  return 0
}

say "1/8 Updating package list"
retry "pkg update" pkg update -y || fail "pkg update failed after 3 tries. Check your internet connection."
retry "pkg upgrade" pkg upgrade -y || warn "pkg upgrade had problems after 3 tries. Continuing with installed versions."

say "2/8 Installing zsh and all dependencies"
PACKAGES="zsh git curl unzip ca-certificates fzf eza bat tealdeer htop micro nano termux-api python python-pip openjdk-17 nodejs util-linux gawk sed grep coreutils"
for p in $PACKAGES; do
  retry "Installing $p" pkg install -y "$p" || fail "Could not install '$p' after 3 tries. Run: pkg install -y $p"
  ok "$p installed"
done

say "3/8 Checking every dependency is available"
MISSING=""
for cmd in zsh git curl unzip fzf eza bat tldr htop micro nano termux-battery-status python pip java node column awk sed grep cut sort wc head; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd found"
  else
    MISSING="$MISSING $cmd"
  fi
done
if [ -n "$MISSING" ]; then
  fail "Missing commands:$MISSING. Install their packages and run the script again."
fi
ok "All dependencies are available"

say "3b Downloading tldr help pages"
retry "tldr page update" tldr --update || warn "tldr pages could not be downloaded. You can run: tldr --update later"

say "4/8 Connecting storage"
if [ ! -d "$HOME/storage" ]; then
  termux-setup-storage
  sleep 3
fi
[ -d "$HOME/storage" ] || fail "Storage is not connected. Allow storage access when asked, then run the script again."
ok "Storage ready"

say "5/8 Downloading zsh plugins"
mkdir -p ~/.zsh
if [ ! -d ~/.zsh/zsh-autosuggestions ]; then
  retry "Downloading zsh-autosuggestions" git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions \
    || fail "Could not download zsh-autosuggestions after 3 tries. Check your internet connection."
fi
if [ ! -d ~/.zsh/zsh-syntax-highlighting ]; then
  retry "Downloading zsh-syntax-highlighting" git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting \
    || fail "Could not download zsh-syntax-highlighting after 3 tries. Check your internet connection."
fi
ok "Plugins ready"

say "6/8 Writing zsh settings (colors, completion, snippets)"
touch ~/.zshrc
sed -i '/# >>> termux-setup >>>/,/# <<< termux-setup <<</d' ~/.zshrc
cat >> ~/.zshrc << 'EOF'
# >>> termux-setup >>>

autoload -Uz colors && colors
PROMPT='%F{magenta}%B🐧 %b%F{yellow}📁 %~ %F{green}❯%f '

autoload -Uz compinit && compinit
zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
bindkey -M menuselect '^[[Z' reverse-menu-complete

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

alias ls='eza --icons --color=always --group-directories-first'
alias ll='eza -lah --icons --color=always --group-directories-first'
alias tree='eza --tree --icons --color=always --level=2'
alias cat='bat --paging=never --style=plain'
alias top='htop'

snipadd() { sed -i "/^$1|/d" ~/.snippets.txt 2>/dev/null; echo "$1|$2" >> ~/.snippets.txt && echo "saved: $1"; }
snipls()  { cat ~/.snippets.txt 2>/dev/null | column -t -s'|'; }

snip-pick() {
  local cmd
  cmd=$(cut -d'|' -f2- ~/.snippets.txt 2>/dev/null | fzf --height 40% --reverse --prompt='snippet> ')
  [[ -n $cmd ]] && LBUFFER+="$cmd"
  zle reset-prompt
}
zle -N snip-pick
bindkey '\es' snip-pick

[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# <<< termux-setup <<<
EOF
[ $? -eq 0 ] || fail "Could not write ~/.zshrc. Check free storage space."
ok "zsh settings written (only once)"

say "7/8 Adding snippets and icon font"
touch ~/.snippets.txt || fail "Could not create ~/.snippets.txt"
add_snip() {
  sed -i "/^$1|/d" ~/.snippets.txt
  printf '%s|%s\n' "$1" "$2" >> ~/.snippets.txt
}
add_snip "update"        "pkg update -y"
add_snip "upgrade"       "pkg update -y && pkg upgrade -y"
add_snip "install"       "pkg install -y "
add_snip "remove"        "pkg uninstall -y "
add_snip "search-pkg"    "pkg search "
add_snip "storage"       "termux-setup-storage"
add_snip "go-home"       "cd ~"
add_snip "go-storage"    "cd ~/storage/shared"
add_snip "go-downloads"  "cd ~/storage/downloads"
add_snip "ls-all"        "ls -lah"
add_snip "find-big"      "du -ah . 2>/dev/null | sort -rh | head -20"
add_snip "disk"          "df -h"
add_snip "edit-zshrc"    "nano ~/.zshrc"
add_snip "reload"        "source ~/.zshrc"
add_snip "git-status"    "git status"
add_snip "git-log"       "git log --oneline --graph --decorate -20"
add_snip "git-commit"    "git commit -m ''"
add_snip "git-push"      "git push"
add_snip "py-version"    "python --version"
add_snip "py-http"       "python -m http.server 8000"
add_snip "java-version"  "java -version"
add_snip "node-init"     "npm init -y"
add_snip "battery"       "termux-battery-status"
add_snip "wifi"          "termux-wifi-connectioninfo"
add_snip "clip-get"      "termux-clipboard-get"
add_snip "clip-set"      "termux-clipboard-set"
add_snip "clear"         "clear"
ok "Snippets ready: $(wc -l < ~/.snippets.txt) entries"

if [ ! -f ~/.termux/font.ttf ]; then
  mkdir -p ~/.termux
  retry "Downloading icon font" curl -fL -o ~/jbm.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip \
    || fail "Could not download the icon font after 3 tries. Check your internet connection."
  unzip -o -q ~/jbm.zip -d ~/jbm || fail "Could not unzip the icon font."
  cp ~/jbm/JetBrainsMonoNerdFont-Regular.ttf ~/.termux/font.ttf || fail "Could not install the icon font."
  rm -rf ~/jbm.zip ~/jbm
  ok "Icon font installed"
else
  ok "Icon font already installed"
fi
termux-reload-settings 2>/dev/null

say "8/8 Setting zsh as default shell"
if chsh -s zsh 2>/dev/null; then
  ok "zsh is now the default shell"
else
  warn "Default shell not changed. Run manually: chsh -s zsh"
fi

printf '\n\033[1;32mSetup finished. Close Termux and open it again.\033[0m\n'
printf 'Try: Alt+S for the snippet menu, and ll to list files with icons.\n'

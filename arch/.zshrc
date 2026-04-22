# 1. Instant Prompt (Optional but recommended for speed)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

# 2. Set the Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# 3. Define Plugins (KEEP your autocomplete plugins here)
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# 4. Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# 5. Keybindings & Autocomplete Styles
bindkey '^ ' autosuggest-accept
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"

# 6. Load p10k config (This line is usually added by the wizard)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
alias killport='sudo fuser -k -n tcp'
alias ls='exa -l'
alias anime="ani-cli"

alias hyprc='nano ~/.config/hypr/hyprland.conf'
alias c='cursor .'

# Find and kill a process by port number
kp() {
  if [ -z "$1" ]; then
    echo "Usage: kp <port_number>"
    return 1
  fi
  
  PID=$(lsof -t -i:"$1")
  
  if [ -z "$PID" ]; then
    echo "No process found on port $1"
  else
    echo "Killing process $PID on port $1..."
    kill -9 $PID
  fi
}

. "$HOME/.local/bin/env"

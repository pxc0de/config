###############################################################################
alias ga="git add"
alias gc="git commit -m"
alias gs="git status"
alias gp="git push origin -u HEAD"
alias gpom="git pull origin main"
# Delete all local branches except main
alias gdab="git branch | grep -v 'main' | xargs git branch -D"
###############################################################################
# Custom prompt with git status and directory
###############################################################################
# Catppuccin Macchiato colors
LAVENDER="%F{#b7bdf8}"
PEACH="%F{#f5a97f}"
RED="%F{#ed8796}"
MAUVE="%F{#c6a0f6}"
RESET="%f"

# Git status and branch function
git_status() {
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -z "$branch" ]; then
    return
  fi

  local git_stat=$(git status --porcelain 2>/dev/null)
  local symbols=""
  [[ "$git_stat" == *"??"* ]] && symbols+="?"
  [[ "$git_stat" == *" M"* ]] && symbols+="!"
  [[ "$git_stat" == *"A "*  ]] && symbols+="+"
  [[ "$git_stat" == *"D "*  ]] && symbols+="✘"
  [[ "$git_stat" == *"R "*  ]] && symbols+="»"
  [[ "$git_stat" == *"UU"* ]] && symbols+="="

  echo " ${MAUVE}${branch}${RESET}${symbols:+ (${MAUVE}${symbols}${RESET})}"
}

# Build prompt
setopt PROMPT_SUBST
precmd() { echo }

PROMPT='%B${LAVENDER}🚀 %3~${RESET}$(git_status)
${PEACH}❯${RESET} %b'
###############################################################################
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. "$HOME/.local/bin/env"

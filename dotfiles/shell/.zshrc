###############################################################################
alias ga="git add"
alias gc="git commit -m"
alias gs="git status"
alias gp="git push origin -u HEAD"
alias gpom="git pull origin main"
# Delete all local branches except main
alias gdab="git branch | grep -v 'main' | xargs git branch -D"
###############################################################################
# My custom prompt with directory and git branch, I dont want git status
###############################################################################
# Catppuccin Macchiato colors
LAVENDER="%F{#b7bdf8}"
PEACH="%F{#f5a97f}"
RED="%F{#ed8796}"
MAUVE="%F{#c6a0f6}"
RESET="%f"

# Git branch if git repo else silent
git_branch() {
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -z "$branch" ]; then
    return
  fi

  echo " ${MAUVE}${branch}${RESET}"
}

# Build prompt
setopt PROMPT_SUBST
precmd() { echo }

PROMPT='%B${LAVENDER}🚀 %3~${RESET}$(git_branch)
${PEACH}❯${RESET} %b'
###############################################################################
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. "$HOME/.local/bin/env"

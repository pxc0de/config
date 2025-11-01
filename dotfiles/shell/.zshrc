###############################################################################
alias ga="git add"
alias gc="git commit -m"
alias gs="git status"
alias gp="git push origin -u HEAD"
alias gpom="git pull origin main"
# Delete all local branches except main
alias gdab="git branch | grep -v 'main' | xargs git branch -D"
###############################################################################
# Starship settings:
###############################################################################
eval "$(starship init zsh)"
###############################################################################


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

. "$HOME/.local/bin/env"

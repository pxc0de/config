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


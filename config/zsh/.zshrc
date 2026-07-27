HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

autoload -uZ compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

autoload -Uz colors && colors


git_branch(){
	local branch
	branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
	echo " %F{yellow} -> ${branch}%f"
}

setopt PROMPT_SUBST
PROMPT='%F{green}%n%f %F{blue}%~%f$(git_branch) %F{mauve}->%f '

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null

alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'

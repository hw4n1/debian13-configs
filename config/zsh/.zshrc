HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

autoload -Uz colors && colors

git_branch(){
	local branch
	branch=$(git symbolic-ref --short HEAD 2>/dev/null) \
		|| branch=$(git rev-parse --short HEAD 2>/dev/null) \
		|| return
	local icon=$'\ue0a0'
	echo " %F{yellow}${icon} ${branch}%f"
}

setopt PROMPT_SUBST
PROMPT='%F{green}%n%f %F{blue}%~%f$(git_branch) %F{141}->%f '

[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
	&& source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
	&& source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias kali='docker run -it --rm -v "$PWD":/work kalilinux/kali-rolling'
alias clear='printf "\033c"'

export PATH="$HOME/go/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local

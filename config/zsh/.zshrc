HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# ── aureola ── el menu de completado a juego con el resto
zstyle ':completion:*' list-colors 'di=38;2;185;212;240:ln=38;2;196;182;242:ex=38;2;242;168;192'
zstyle ':completion:*:descriptions' format '%F{#565575}󰫢 %d%f'
zstyle ':completion:*:warnings'     format '%F{#ef8fa8}󰀦 sin coincidencias%f'

autoload -Uz colors && colors

# ── aureola ── prompt
# Paleta: config/theme/aureola.conf
#   ╭─ 󰋑 usuario 󰫢 ruta 󰫢  rama 󰏫
#   ╰─ 󰫢
typeset -g AUREOLA_ROSE="#f2a8c0"
typeset -g AUREOLA_HALO="#b9d4f0"
typeset -g AUREOLA_LAVANDA="#c4b6f2"
typeset -g AUREOLA_MENTA="#9fe0cf"
typeset -g AUREOLA_ORO="#f0dcae"
typeset -g AUREOLA_BLUSH="#ef8fa8"
typeset -g AUREOLA_OVERLAY="#565575"

git_branch(){
	local rama
	rama=$(git symbolic-ref --short HEAD 2>/dev/null) \
		|| rama=$(git rev-parse --short HEAD 2>/dev/null) \
		|| return
	local sucio=""
	git diff --quiet --ignore-submodules HEAD 2>/dev/null || sucio=" %F{$AUREOLA_ORO}󰏫%f"
	printf ' %%F{%s}󰫢%%f %%F{%s} %s%%f%s' \
		"$AUREOLA_OVERLAY" "$AUREOLA_LAVANDA" "$rama" "$sucio"
}

setopt PROMPT_SUBST
PROMPT='
%F{$AUREOLA_OVERLAY}╭─%f %F{$AUREOLA_ROSE}󰋑%f %F{$AUREOLA_ROSE}%n%f %F{$AUREOLA_OVERLAY}󰫢%f %F{$AUREOLA_HALO}%~%f$(git_branch)
%F{$AUREOLA_OVERLAY}╰─%f %(?.%F{$AUREOLA_MENTA}.%F{$AUREOLA_BLUSH})󰫢%f '
RPROMPT='%(?..%F{$AUREOLA_BLUSH}󰅖 %?%f )%F{$AUREOLA_OVERLAY}󰥔 %*%f'

# El texto sugerido, apagado para que no compita con lo que escribes
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565575'

[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
	&& source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
	&& source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── aureola ── resaltado de sintaxis con la paleta del escritorio
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]="fg=#9fe0cf"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#9fe0cf"
ZSH_HIGHLIGHT_STYLES[function]="fg=#9fe0cf"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#9fe0cf"
ZSH_HIGHLIGHT_STYLES[precommand]="fg=#9fe0cf,italic"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#ef8fa8,bold"
ZSH_HIGHLIGHT_STYLES[path]="fg=#b9d4f0,underline"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#f0dcae"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#f0dcae"
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=#f0dcae"
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]="fg=#c4b6f2"
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]="fg=#c4b6f2"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#565575,italic"
ZSH_HIGHLIGHT_STYLES[redirection]="fg=#f2a8c0"
ZSH_HIGHLIGHT_STYLES[globbing]="fg=#f2a8c0"

alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias kali='docker run -it --rm -v "$PWD":/work kalilinux/kali-rolling'
alias dquilt='quilt --quiltrc=$HOME/.quiltrc-dpkg'
alias clear='printf "\033c"'
alias paleta='cat ~/setup/config/theme/aureola.conf'

export PATH="$HOME/go/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
[[ -d /usr/lib/ccache ]] && export PATH="/usr/lib/ccache:$PATH"

# nvim si esta (lo instala ./setup.sh --dev en ~/.local/bin), nano de reserva:
# dch, git commit, bts y reportbug abren lo que diga esto.
if [[ -z "$EDITOR" ]]; then
	if (( $+commands[nvim] )); then
		export EDITOR=nvim
	else
		export EDITOR=nano
	fi
fi
export VISUAL="$EDITOR"
(( $+commands[nvim] )) && alias vi='nvim' && alias vim='nvim'

# Menos + colores de la paleta para man
export LESS='-R'
export MANROFFOPT='-P -c'
export LESS_TERMCAP_md=$'\e[38;2;242;168;192m'   # negrita  -> rosa
export LESS_TERMCAP_us=$'\e[38;2;196;182;242m'   # subrayado-> lavanda
export LESS_TERMCAP_so=$'\e[48;2;185;212;240;38;2;23;22;34m'  # busqueda
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'

[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

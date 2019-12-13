# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="clean"
ZSH_THEME="agnoster"
DEFAULT_USER=$(whoami)
prompt_context(){}


# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" "powerlevel9k/powerlevel9k")

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(git)
plugins=(
    git
    colored-man-pages
    colorize
    pip
    python
    brew
    osx
    docker
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias k=kubectl

if [ "$OSTYPE" = "darwin"  ]; then
    alias ll='exa -la'
    alias emacs='/Applications/Emacs.app/Contents/MacOS/Emacs'
    # Function to call IntelliJ Idea from command line at directory and passing all possible parameters
    function idea {
        open -a /Applications/IntelliJ\ Idea\ CE.app/Contents/MacOS/idea $@
    }
    # Coreutils overriding the MAC utils
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
    export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
    export PATH="/usr/local/Cellar/gnu-getopt/1.1.6/bin:$PATH"

fi

# DGD Function for git page
ghp () {
    repo="https://"`git config --get remote.origin.url | sed 's|git@||' | sed 's|\.git||' | sed 's|:|/|'`
    case "$OSTYPE" in
        darwin*)
            open "$repo/pulls"
            ;;
        linux*)
            xdg-open "$repo/pulls"
            ;;
    esac
}

alias emacsnw='emacs -nw'
alias watch='watch '
eval "$(hub alias -s)"

# Path Manipulation
function pathClean() {
    # Cleans path of duplicated portions.
    NEWPATH=$(echo $1 | sed 's/:/\'$'\n/g' | perl -ne 'print unless $seen{$_}++' | paste -s -d':' -)
    echo "$NEWPATH"
}

function fpathClean() {
    # Cleans fpath of duplicated portions
    NEWPATH=$(echo $1 | sed -e 's/ /\'$'\n/g' | perl -ne 'print unless $seen{$_}++' | paste -s -d' ' -)
    echo $NEWPATH
}

## PATH Fixing and changing local variables

if [ "$(file /cibo)" = "/cibo: directory" ]; then
    export PATH=/cibo/shared-scripts:$HOME/.local/bin:/usr/local/opt/swagger-codegen@2/bin:$PATH
fi
export PATH=$(pathClean $PATH)


PATH="$HOME/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"$HOME/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"; export PERL_MM_OPT;

# SSH SETTINGS.

SSH_ENV="$HOME/.ssh/env"

function start_agent {
    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add;
}

# Source SSH settings, if applicable

if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    #ps ${SSH_AGENT_PID} doesn't work under cywgin
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi

# Pyenv
eval "$(pyenv init -)"
# Pyenv Virtualenv
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

case "$OSTYPE" in
    darwin*)
        # Brew Specifics
        fpath=(/usr/local/share/zsh-completions /usr/local/share/zsh/site-functions $fpath)
        # fpath=$(fpathClean "$fpath")
        source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        source /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh
        source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ;;
    linux*)
        # Brew Specifics
        fpath=($HOMEBREW_PREFIX/share/zsh-completions $HOMEBREW_PREFIX/share/share/zsh/site-functions $fpath)
        # fpath=$(fpathClean "$fpath")
        source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        source $HOMEBREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh
        source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ;;
esac

# Add in emacs keybindings
bindkey -e

if [ -d $HOME/.zsh_settings ]; then
    # Sourcing completions etc.
    for PROFILE_SCRIPT in $( ls $HOME/.zsh_settings/*.zsh ); do
        # echo "Sourcing $PROFILE_SCRIPT"
        source $PROFILE_SCRIPT
    done
fi

TOKENS_FILE="$HOME/tokens/github_tokens.zsh"
if [ -e $TOKENS_FILE ]; then
    source $TOKENS_FILE
fi

# Some crazy autoloading
# autoload -U bashcompinit && bashcompinit
# autoload -U compinit && compinit
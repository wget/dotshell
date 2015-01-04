# System-wide .bashrc file for interactive bash(2) shells.

#{{{ General settings
#-------------------------------------------------------------------------------
# Even if the same checks have been performed in our profile file, this is
# needed if someone wants just to use our bashrc and source it from its
# profile file without doing any checks.

# Leave if the shell is not Bash.
[ -z "$BASH" ] && return

# Leave if not running interactively.
case $- in
    *i*);;
    *)return;;
esac

# Leave if the builtin Bash shopt command is not found. This means we have
# a huge problem here. User needs to be warned.
if ! type shopt >/dev/null 2>&1; then
    echo "[${RED}-${OFF}] [$0] shopt was not found but this shell reports to be Bash."
    return
fi

# Leave if Bash is set to be POSIX compliant.
if shopt -oq posix; then
    echo "[${GREEN}-${OFF}] [$0] POSIX compliant mode enabled. Not sourcing further."
    return
fi

# Check the window size after each typed command and, if necessary, update the
# values of LINES and COLUMNS shell variables.
shopt -s checkwinsize

if [ -r /etc/bash_completion ]; then
    . /etc/bash_completion
elif [ -r /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

# Display directly file content from compressed files by making the 'less'
# command aware of some non-text input files, see lesspipe(1).
[ -x /bin/lesspipe ] && eval $(/bin/lesspipe) ||\
[ -x /usr/sbin/lesspipe.sh ] && eval $(/usr/sbin/lesspipe.sh)

# If the command-not-found package is installed, use it and suggest
# installation of packages in interactive bash sessions.
#
# NOTE: the ArchLinux command-not-found handler is defined by the shell script
# located at /etc/profile.d/cnf.sh which is automatically sourced by our
# /etc/profile which sources all files present in /etc/profile.d. On ArchLinux,
# the command-not-found command is actually cnf-lookup, so checking for each
# possible location of command-not-found is enough to avoid defining an uneeded
# handler.
if [ -x '/usr/lib/command-not-found' ]; then
    function command_not_found_handle() {
        /usr/bin/command-not-found "$1"
        if [ ! $? -eq 0 ]; then
            echo "bash: $1: command not found"
        fi

        # In UNIX the 127 value returned by the shell means the command was not
        # found.
        return 127
    }
elif [ -x '/usr/share/command-not-found/command-not-found' ]; then
    function command_not_found_handle() {
        /usr/share/command-not-found/command-not-found "$1"
        if [ ! $? -eq 0 ]; then
            echo "bash: $1: command not found"
        fi
        return 127
    }
elif [ -x '/usr/bin/cnf-lookup' ]; then
    function command_not_found_handle() {
        cnf-lookup -c $1
        if [ ! $? -eq 0 ]; then
            echo "bash: $1: command not found"
        fi
        return 127
    }
fi
#}}}

#{{{ Historic management
#-------------------------------------------------------------------------------
# Append to the history file, don't overwrite it.
shopt -s histappend

# By default console commands' history is saved only when you type 'exit' in
# your GUI console. When you close your GUI terminal typically with 'x' in the
# wondow corner, it does not work.
# Use the following line to enable autosaving after every command execution and
# make the history accessible from every terminal tabs or windows (e.g.: if ls
# is executed in one, switch to another already-running terminal and then press
# up, ls shows up).
#
# -a: append history lines from this session to the history file;
# -c: clear the history list by deleting all of the entries;
# -r: read the history file and append the contents to the history list
#
# - No need to check if the history command is present, it's built-in bash.
# - Need to issue at least a command to get the history updated in an
# already-open terminal.
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# Line matching any previous line history will not be saved (ignoredups), and
# lines beginning with a space character are not saved in the history
# (ignorespace). ignoreboth is a shortcut for these two values.
HISTCONTROL=ignoreboth

# Max number of lines command to save in the history (default 500).
HISTSIZE=1000

# The maximum number of lines (default 500) contained in our custom history
# file which is defined with HISTFILE attribute (default to ~/.bash_history).
# This parameter is not needed here as we do not change HISTFILE location.
#HISTFILESIZE=2000

#}}}

#{{{ Prompt management
#-------------------------------------------------------------------------------
# This PS1 syntax is only valid for Bash, other shells like zsh uses another one
# (e.g. %n instead of \u for the username).
if [ $EUID -ne 0 ]; then
    # The variable PROMPT_COMMAND contains a regular bash command that is
    # executed just before the command prompt is displayed. This variable can be
    # thus used to modify prompt, as it is executed at each time. e.g.:
    # PROMPT_COMMAND=${COMMAND_PROMPT}:+$PROMPT_COMMAND;} 'YOUR COMMAND HERE'
    PS1='\[\e[31m\][\[\e[1;32m\]\u\[\e[00m\]@\h \[\e[36m\]\W\[\e[00m\]\[\e[31m\]]\[\e[00m\]\$ '
else
    PS1='\[\e[31m\][\[\e[1;31m\]\u\[\e[0m\]@\h \[\e[36m\]\W\[\e[31m\]]\[\e[1;31m\]\$\[\e[0m\] '
fi

case $TERM in
    screen)
        PS1='(screen)'$PS1
    ;;
esac

# Enable git prompt
if [ -r /usr/share/git/git-prompt.sh ]; then
    . /usr/share/git/git-prompt.sh
    PS1='$(__git_ps1 "(%s)")'$PS1
fi

# Prompt used in interactive prompt, e.g. when written on several lines with
# \ '> ' is the default.
PS2='> '

# Prompt used when answering to a question asked by script '' is the default.
PS3=''

# Prompt used by "set -x" command in scripts for debug information '+ ' is the
# default.
PS4='+ '
#}}}

#{{{ Aliases
#-------------------------------------------------------------------------------
# Function used below checking if external tools are available. Can be used
# from the shell directly since this is a function.
function checkDep() {
    local deps=($1)
    local notFound=()

    for i in "${deps[@]}"; do
        if ! type $i >/dev/null 2>&1; then
            notFound+=($i)
        fi
    done

    if [ ${#notFound[@]} -eq 0 ]; then
        return 0
    fi

    if [ ${#notFound[@]} -eq 1 ]; then
        echo "[${RED}-${OFF}] \"$i\" was found! Aborted."
        return 1
    fi

    if [ ${#notFound[@]} -gt 1 ]; then
        echo -n "[${RED}-${OFF}] "
        for i in "${notFound[@]}"; do
            echo -n "\"$i\" "
        done
        echo "were not found. Aborted."
        return 2
    fi
}

# Specific to GNU coreutils
if ls --version >/dev/null 2>&1; then

    # Override default color database used by dircolors.
    if [ -r "~/.dircolors" ]; then
        eval "$(dircolors -b ~/.dircolors)"
    fi

    # See this link for details
    # http://www.bigsoft.co.uk/blog/index.php/2008/04/11/configuring-ls_colors
    # http://backup.noiseandheat.com/blog/2011/12/os-x-lion-terminal-colours/
    #LS_COLORS='di=1:fi=0:ln=31:pi=5:so=5:bd=5:cd=5:or=31:*.deb=90'
    #export LS_COLORS

    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'

    # For security reasons, redefine the default GNU behaviour.
    alias rm='rm --preserve-root'

# Specific BSD utils
else
    # See
    # http://www.marinamele.com/2014/05/customize-colors-of-your-terminal-in-mac-os-x.html
    export CLICOLOR=1
    # Try to have the same colors as the default GNU ones; but LSCOLORS does
    # not have yellow.
    LSCOLORS=ExGxFxdxCxHgHghbabacad
fi

alias ll='ls -alh'

# Add colors to manpages (man is using less as internal pager).
export LESS_TERMCAP_mb=$(tput bold; tput setaf 2) # green
export LESS_TERMCAP_md=$(tput bold; tput setaf 6) # cyan
export LESS_TERMCAP_me=$(tput sgr0)
export LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4) # yellow on blue
export LESS_TERMCAP_se=$(tput rmso; tput sgr0)
export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 7) # white
export LESS_TERMCAP_ue=$(tput rmul; tput sgr0)
export LESS_TERMCAP_mr=$(tput rev)
export LESS_TERMCAP_mh=$(tput dim)
export LESS_TERMCAP_ZN=$(tput ssubm)
export LESS_TERMCAP_ZV=$(tput rsubm)
export LESS_TERMCAP_ZO=$(tput ssupm)
export LESS_TERMCAP_ZW=$(tput rsupm)

# Only ANSI color escape sequences are output in raw form to be interpreted by
# the shell.
LESS="--RAW-CONTROL-CHARS"

# Using dig (which is available on OS X too, by default) is the fastest way to
# get our public IP address. We could have defined the code inside an alias
# instead, but this is causing a problem with nested quotes which are simply
# not interpreted. Moreover, proceeding with aliases we werelosing syntax
# highlighting.
function myip() {
    if type dig >/dev/null 2>&1; then
       dig +short myip.opendns.com @resolver1.opendns.com
    else
      echo "[${RED}-${OFF}] dig was not found! This command is usually found in the 'dnsutils' package of common GNU/Linux distributions."
    fi
}

# Display a UNIX command line histogram (graphical view) of the 20 most used
# commands. Taken from: http://www.smallmeans.com/notes/shell-history/
function chart() {

    checkDep "history awk sort uniq head"
    if [ $? -gt 0 ]; then return 1; fi

    # Retrieve history (bash built-in)
    history|

    # Use the AWK language to only print the 2nd column. Using cut does not
    # work, since items are right aligned, and algorithm must be changed in
    # order to handle this (aligment of  |  80 is different from | 100).
    awk '{print $2}'|

    # Sort, so that similar commands come in groups
    sort|

    # Count subsequent items (-c prepends count)
    uniq -c|

    # Sort in descending order (reverse)
    sort -rn|

    # Get the 20 most frequent commands
    head -20|


    awk '!max{max=$1;}{
         r="";
         i=s=60*$1/max;
         while(i-->0) {
             r=r"#";
         }
         printf "%15s %5d %s %s",$2,$1,r,"\n";
     }'
}
chart

#}}}

#{{{ SSH-agent management
#-------------------------------------------------------------------------------
# Load ssh-agent and use its environment variables.
# README: Please ensure this part of script is loaded from the profile file
# level (/etc/profile or ~/.bash_profile). This will avoid the ssh-agent
# process to be forked each time the user launches a new login shell (TTY or in
# UI) and avoid high memory increase.
set -o functrace
function ssh-agentManagement
{
    if ! type ssh-agent >/dev/null 2>&1; then
        echo "[${RED}-${OFF}] ssh-agent not found!"
        return 1
    fi

    if ! type ssh-add >/dev/null 2>&1; then
        echo "[${RED}-${OFF}] ssh-add not found!"
        return 1
    fi

    local destinationFolder="$HOME/.ssh"

    # Ensure the destination folder really exists before continuing.
    if [ -f "$destinationFolder" ]; then
        echo "[${RED}-${OFF}] \"$destinationFolder\" is already a file. Aborted."
        return 2
    elif [ ! -d "$destinationFolder" ] && ! mkdir -p "$destinationFolder" >/dev/null 2>&1; then
        echo "[${RED}-${OFF}] Cannot create \"$destinationFolder\". Please check your file permissions. Aborted."
        return 3
    fi

    local destinationFile="$destinationFolder/agent"
    
    if [ -r "$destinationFile" ]; then
        source "$destinationFile" >/dev/null 2>&1
    fi

    # If there is a valid ssh-agent socket, we assume ssh-agent is already
    # loaded, don't need to load it again and stop now then.
    if [ -S "$SSH_AUTH_SOCK" ]; then
        return 6
    fi

    # If we haven't any keys stored, why use ssh-agent? Don't launch it then.
    local keysLocationFile="$destinationFolder/keys_location"
    if [ -r "$keysLocationFile" ]; then
        local keysLocation=$(<"$keysLocationFile")
    fi
    if [ ! -r "$destinationFolder/id_rsa" ] &&
       [ ! -r "$destinationFolder/id_dsa" ] &&
       [ ! -r "$destinationFolder/id_ecdsa" ] &&
       [ ! -r "$destinationFolder/identity" ] && 
       [ -z "$keysLocation" ]; then
        return 5
    fi
    
    if [ -f "$destinationFile" ] && [ ! -r "$destinationFile" ]; then
        echo "[${RED}-${OFF}] \"$destinationFile\" isn't readable and your ssh-agent won't be usable in other sessions. Aborted."
        return 4
    fi

    # NOTE: Brackets are only needed to replace the following bash error
    # message 'bash: agent: Permission denied' with our own.
    if { ! ssh-agent > "$destinationFile"; } 2>/dev/null; then
        echo "[${RED}-${OFF}] Unable to launch ssh-agent. Please check the file permission for \"$destinationFile\". Aborted."
        return 3
    fi
    source "$destinationFile" >/dev/null 2>&1

    echo "[${GREEN}+${OFF}] Using ssh-agent \(PID $SSH_AGENT_PID\)"

    # Load keys from the default location if any
    ssh-add

    # Load other keys where the location has been defined by the user.
    
    # NOTE: These keys paths have to be defined as absolute path, as bash
    # cannot expands vars recursively.
    if [ -n "$keysLocationFile" ]; then
        # Transform space delimited keysLocation variable into an array for
        # easy usage.
        keysLocation=($keysLocation)
        for ((i = O; i < ${#keysLocation[@]}; i++)); do
            if [ ! -r "${keysLocation[i]}" ]; then
                echo "[${RED}-${OFF}] The SSH-key \"${keysLocation[i]}\" specified at line $(($i + 1)) of \"$keysLocationFile\" isn't readable."
            else
                ssh-add "$keysLocation"
            fi
        done
    fi
}
ssh-agentManagement
#}}}

#{{{ Platform specific
#-------------------------------------------------------------------------------
# Source platform specific code from another file
#
# NOTE: The location "./bash_specific.bashrc" cannot be used since this will
# only check the current directory the user sourcing this script is in (default
# is /home when booting the machine). This is not what we want. Get inspiration
# from
# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
function getScriptDirectory() {
    local source="${BASH_SOURCE[0]}"
    local dir=''
    # Resolve $source until the file is no longer a symlink
    while [ -h "$source" ]; do
        dir="$(cd -P "${source%/*}" && echo ${PWD})"
        source="$(readlink "$source")"
        # If $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
        [[ $source != /* ]] && source="$dir/$source"
    done
    dir="$(cd -P "${source%/*}" && echo ${PWD})"
    scriptDirectory="$dir"
}
getScriptDirectory
if [ -r "${scriptDirectory}/bash_specific.bashrc" ]; then
    . ${scriptDirectory}/bash_specific.bashrc
fi
unset scriptDirectory

#}}}

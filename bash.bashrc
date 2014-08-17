# System-wide .bashrc file for interactive bash(2) shells.

# To enable the settings / commands in this file for login shells as well, this
# file has to be sourced in /etc/profile.
#
# The /etc/bash.bashrc file isn't a standard location, the latter is only
# available in some linux distributions, as packagers have defined
# a -DSYS_BASHRC="/etc/bash.bashrc" flag at the Bash compilation time in order
# to provide a system-wide bashrc location.

#{{{ Terminal colors
#-------------------------------------------------------------------------------
BLUE="[34;01m"
CYAN="[36;01m"
CYANN="[36m"
GREEN="[32;01m"
RED="[31;01m"
PURP="[35;01m"
OFF="[0m"
#}}}

#{{{ General settings
#-------------------------------------------------------------------------------
# If not running interactively don't do anything and quit config.

# An interactive shell reads command from user input, displays a prompt (if
# using default settings) and enables jobs control. A shell running a script is
# always running in non-interactive mode. 
[[ $- != *i* ]] && return
# The following method is unsufficient to check if a shell is interactive, do
# not use it. It is only valid if the user hasn't modified the default PS1
# variable used in interactive mode (default is empty), which might not be the
# case.
#[ -z "$PS1" ] && return

# Load a 256 colors terminal emulator, useful for advanced colorschemes in Vim.
# if [ -e /usr/share/terminfo/x/xterm-256color ] \
#     || [ -e /usr/share/terminfo/x/xterm+256color ]; then
#     export TERM='xterm-256color'
# else
#     export TERM='xterm-color'
# fi

# Check the window size after each typed command and, if necessary, update the
# values of LINES and COLUMNS shell variables.
if type shopt >/dev/null 2>&1; then
    shopt -s checkwinsize
fi

# Enable bash completion in interactive shells only if the shells don't have to
# be POSIX compliant.
if [ "! shopt -oq posix" ]; then
    if [ -r /etc/bash_completion ]; then
        . /etc/bash_completion
    elif [ -r /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    fi
fi

# Display directly file content from compressed files by making the 'less'
# command  more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# If the Debian command-not-found package is installed, use it and suggests
# installation of packages in interactive bash sessions.
#
# Checking before defining the function is needed to avoid redefining an
# unneeded handler always present in memory.
if [ -x /usr/bin/command-not-found ] || [ -x /usr/share/command-not-found ]; then
    function command_not_found_handle
    {
        # NOTE: the ArchLinux command-not-found handler is defined by the
        # /etc/profile.d/cnf.sh shell script. This script is automatically
        # sourced by my custom /etc/profile which sources all files present in
        # /etc/profile.d. On ArchLinux, the command-not-found command is
        # actually cnf-lookup, so checking for command-not-found at its
        # different possible locations is sufficient to avoid defining an
        # uneeded handler.
        if [ -x /usr/bin/command-not-found ]; then
            /usr/bin/command-not-found "$1"
        elif [ -x /usr/share/command-not-found ]; then
            /usr/share/command-not-found/command-not-found "$1"
        fi
    }
fi
#}}}

#{{{ File permissions
#-------------------------------------------------------------------------------
# On UNIX, a umask is used to determine the file permission for newly created
# files. The default permissions are 777 for the directories and 666 for the
# files. The umask applies a NOT AND mask on these default values.
#
# By default, the regular users have a 0002 umask, the permissions are 775
# (rwxrwxr-x) for the directories and 664 (rw-rw-r--) for the files.
#
# By default, the root user has a 0022 umask, the default permissions are 755
# (rwxr-xr-x) for the directories and 644 (rw-r--r--) for the files.
umask 077
# This mask will define for all kind of users (regular and root) permissions as
# 700 for directories and 600 for files. 
#}}}

#{{{ Historic management
#-------------------------------------------------------------------------------
# Append to the history file, don't overwrite it.
if type shopt >/dev/null 2>&1; then
    shopt -s histappend
fi

# By default console commands' history is saved only when you type 'exit' in
# your GUI console. When you close your console with 'x' in the corner, it does
# not happen.
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

# Line matching the previous line history won't be saved.
# NOTE: HISTCONTROL is a colon separated list.
# HISTCONTROL=ignoredups

# Lines which begin with a space character are not saved in the history.
# HISTCONTROL+=:ignorespace

# ignoreboth is a shortcut for ignoredups and ignorespace described just above.
HISTCONTROL=ignoreboth

# Max number of lines command to save in the history (default 500).
HISTSIZE=1000

# The maximum number of lines (default 500) contained in our custom history
# file which defined with HISTFILE attribute (default to ~/.bash_history).
# This parameter isn't needed here as we don't change HISTFILE location.
#HISTFILESIZE=2000

#}}}

#{{{ Prompt management
#-------------------------------------------------------------------------------
# Colorize and customize the prompt 

# This configuration is only valid for Bash as other shells like zsh uses
# another syntax (e.g. %n instead of \u for the username)
if [ "$BASH" ]; then
    if type tput >/dev/null 2>&1; then
        if [ $EUID -ne 0 ]; then
            # The variable PROMPT_COMMAND contains a regular bash command that
            # is executed just before the command prompt is displayed.  This
            # variable can be thus used to modify prompt, as it is executed at
            # each time.
            # e.g.: PROMPT_COMMAND=${COMMAND_PROMPT}:+$PROMPT_COMMAND;}
            # 'YOUR COMMAND HERE'
            PS1='\[\e[31m\][\[\e[1;32m\]\u\[\e[00m\]@\h \[\e[36m\]\W\[\e[00m\]\[\e[31m\]]\[\e[00m\]\$ '
        else
            PS1='\[\e[31m\][\[\e[1;31m\]\u\[\e[0m\]@\h \[\e[36m\]\W\[\e[31m\]]\[\e[1;31m\]\$\[\e[0m\] '
        fi
    else
        PS1='[\u@\h \W]\$ '
    fi
fi

case ${TERM} in
    #xterm*|rxvt*|Eterm|aterm|kterm|gnome*)
    #;;
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
# dircolors enhances the colored command output; for example with ls,
# broken (orphan) symlinks will be shown in a red hue.
if type dircolors >/dev/null 2>&1 && [ $(uname) == 'Darwin' ] || [ $(uname) == 'Linux' ]; then
    [ -r "~/.dircolors" ] && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Checking here if the 'ls' command has all the argument is needed because
# busybox might not have all of these.
if ls -alh >/dev/null 2>&1; then
    alias ll='ls -alh'
fi

# For security reasons, redefine the default behaviour
if [[ "$(uname)" == "Linux" ]]; then
    alias rm='rm --preserve-root'
fi

# Add some colors to the less command
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

LESS="--RAW-CONTROL-CHARS"

# Add the fatest way to get our public ip address
alias myip='
if type dig >/dev/null 2>&1; then
    dig +short myip.opendns.com @resolver1.opendns.com
else
  echo "[${RED}-${OFF}] dig was not found! This command is usually found in the 'dnsutils' package of common GNU/Linux distributions."
fi'
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

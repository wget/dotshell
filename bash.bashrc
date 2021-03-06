# System-wide .bashrc file for interactive bash(2) shells.


#{{{ Bash check
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
    echo "[-] [$0] shopt was not found but this shell reports to be Bash."
    return
fi

# Leave if Bash is set to be POSIX compliant.
if shopt -oq posix; then
    echo "[-] [$0] POSIX compliant mode enabled. Not sourcing further."
    return
fi

#}}}

#{{{ Load libraries
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# I: - A string to prepend to our error message
# P: Simply load our lib. The strange name is to avoid clashes.
# O: /
#-------------------------------------------------------------------------------
function __BashrcRequireCoreLib() {

    if ! type readlink >/dev/null 2>&1; then
        if [[ -z "$1" ]]; then
            echo "${FUNCNAME[1]}: Unable to locate the required"\
                 "core library: readlink not found. Aborted."
        else
            echo "$1: ${FUNCNAME[1]}: Unable to locate the required"\
                 "core library: readlink not found. Aborted."
        fi
    fi

    # Get script directory (symlinks supported)
    local source="${BASH_SOURCE[0]}"
    local dir=''
    # Resolve $source until the file is no longer a symlink
    while [ -h "$source" ]; do
        dir="$(cd -P "${source%/*}" && echo "${PWD}")"
        source="$(readlink "$source")"
        # If $source was a relative symlink, we need to resolve it relative to
        # the path where the symlink file was located
        [[ $source != /* ]] && source="$dir/$source"
    done
    dir="$(cd -P "${source%/*}" && echo "${PWD}")"

    if . "$dir/utils.sh" >/dev/null 2>&1; then
        initColors
        initEffects
        return 0
    fi
    if [[ -z "$1" ]]; then
        echo "${FUNCNAME[1]}: Unable to load the required core library. Aborted."
    else
        echo "$1: ${FUNCNAME[1]}: Unable to load the required core library. Aborted."
    fi
    return 1
}

#-------------------------------------------------------------------------------
# I: /
# P: Free the declarations of functions and the global variable retval loaded
#    by our lib
# O: /
#-------------------------------------------------------------------------------
function __BashrcFreeCoreLib() {

    getScriptDirectory

    # When executing this command against our lib, we have to avoid to saw off
    # the branch on which we are sitting, because our lib is using the
    # functions we want to undeclare. To avoid such a problem, we had to modify
    # the function undeclareFunctions and specify a third argument used as
    # a safe guard in order to recover the functions names in retval.
    #
    # However since we are in a script, the only way to modify our parent
    # environment is to source a file
    # (src.: http://mywiki.wooledge.org/BashFAQ/060)
    # As we don't want to source a file, let's use the Bash specific here
    # string (<<<) feature. <<< expands the string and foward it to the
    # program's stdin.  (src.: http://unix.stackexchange.com/a/76407/146454)
    undeclareFunctions "$retval/utils.sh" "" "retval"
    for func in "${retval[@]}"; do
        source /dev/stdin <<< "unset -f \"$func\""
    done

    # Even if we remove global functions, global variables created inside
    # global functions are not removed. We need to remove them manually.
    unset retval
}

#}}}

#{{{ General settings
#-------------------------------------------------------------------------------
# Check the window size after each typed command and, if necessary, update the
# values of LINES and COLUMNS shell variables.
shopt -s checkwinsize

if [[ -r /etc/bash_completion &&
      -f /etc/bash_completion ]]; then
    . /etc/bash_completion
elif [[ -r /usr/share/bash-completion/bash_completion &&
        -f /usr/share/bash-completion/bash_completion ]]; then
    . /usr/share/bash-completion/bash_completion
fi

# Display directly file content from compressed files by making the 'less'
# command aware of some non-text input files, see lesspipe(1).
#
# Note 1: Don't try to use 'source' or 'exec' or remove $(). This doesn't work.
# Note 2: Contrary to the man pages and languages like C/C++, && and || have the
# same precedence in Bash. The latter will thus evaluate
# A && B || C && D as (((A && B) || C) && D)
# taking elements from left to right. Which will gives A, B, D. Using 'if'
# statements is much more cleaner.
if [[ -x /bin/lesspipe &&
      -f /bin/lesspipe ]]; then
    eval $(/bin/lesspipe)
elif [[ -x /usr/sbin/lesspipe.sh &&
        -r /usr/sbin/lesspipe.sh ]]; then
    eval $(/usr/sbin/lesspipe.sh)
fi

# If the command-not-found package is installed, use it and suggest
# installation of packages in interactive bash sessions.
#
# NOTE: the ArchLinux command-not-found handler is defined by the shell script
# located at /etc/profile.d/cnf.sh which is automatically sourced by our
# /etc/profile which sources all files present in /etc/profile.d. On ArchLinux,
# the command-not-found command is actually cnf-lookup, so checking for each
# possible location of command-not-found is enough to avoid defining an uneeded
# handler.
if [[ -x /usr/lib/command-not-found &&
      -f /usr/lib/command-not-found ]]; then
    function command_not_found_handle() {
        /usr/bin/command-not-found "$1"
        if [ ! $? -eq 0 ]; then
            echo "bash: $1: command not found"
        fi

        # In UNIX the 127 value returned by the shell means the command was not
        # found.
        return 127
    }
elif [[ -x /usr/share/command-not-found/command-not-found &&
        -f /usr/share/command-not-found/command-not-found ]]; then
    function command_not_found_handle() {
        /usr/share/command-not-found/command-not-found "$1"
        if [ ! $? -eq 0 ]; then
            echo "bash: $1: command not found"
        fi
        return 127
    }
elif [[ -x /usr/bin/cnf-lookup &&
        -f /usr/bin/cnf-lookup ]]; then
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
# the GUI console. When you close your GUI terminal typically with 'x' in the
# window corner, it does not work.
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

# The maximum number of lines (default 500) contained in a custom history file
# which is defined with HISTFILE attribute (default to ~/.bash_history). This
# parameter is not needed here as we do not have a custom HISTFILE location.
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
if [[ -r /usr/share/git/git-prompt.sh &&
      -f /usr/share/git/git-prompt.sh ]]; then
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
# Specific to GNU coreutils
if ls --version >/dev/null 2>&1; then

    # Override default color database used by dircolors.
    if [[ -r ~/.dircolors &&
          -f ~/.dircolors ]]; then
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

alias ll='LC_ALL='"'"'C.UTF-8'"'"' ls -alh'

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

#-------------------------------------------------------------------------------
# I: The number of characters we want
# P: 
# O: /
#-------------------------------------------------------------------------------
function randpass() {
    < /dev/urandom LC_CTYPE=C tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;
}

# Using dig (which is available on OS X too, by default) is the fastest way to
# get our public IP address. We could have defined the code inside an alias
# instead, but this is causing a problem with nested quotes which are simply
# not interpreted. Moreover, proceeding with aliases we werelosing syntax
# highlighting.
function myip() {

    __BashrcRequireCoreLib bashrc || return 1

    if ! checkDeps dig; then
        error "dig was not found! This command is usually found in the" \
              "'dnsutils' package of common GNU/Linux distributions."
        __BashrcFreeCoreLib
        return
    fi

    dig +short myip.opendns.com @resolver1.opendns.com

    __BashrcFreeCoreLib
}

# Display a UNIX command line histogram (graphical view) of the 20 most used
# commands. Taken from: http://www.smallmeans.com/notes/shell-history/
function chart() {

    __BashrcRequireCoreLib bashrc || return 1

    if ! checkDeps history awk sort uniq head; then
        error "The following commands are not installed: ${retval[@]}. Aborted."
        __BashrcFreeCoreLib
        return
    fi

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

    __BashrcFreeCoreLib
}

# Allow to explain what a command does without having to read each man pages of
# the subcommands involved. Source:
# https://www.mankier.com/blog/explaining-shell-commands-in-the-shell.html
function explain() {

    __BashrcRequireCoreLib bashrc || return 1

    if ! checkDeps curl; then
        error "The following commands are not installed: ${retval[@]}. Aborted."
        __BashrcFreeCoreLib
        return
    fi

    if [ "$#" -eq 0 ]; then
        while read  -p "Command: " cmd; do
            curl -Gs "https://www.mankier.com/api/explain/?cols="$(tput cols) --data-urlencode "q=$cmd"
        done
        # Called only on signals catched by bash except SIGINT, and other
        # system signals
        echo "Bye!"
    elif [ "$#" -eq 1 ]; then
        curl -Gs "https://www.mankier.com/api/explain/?cols="$(tput cols) --data-urlencode "q=$1"
    else
        echo "Usage"
        echo "explain                  interactive mode."
        echo "explain 'cmd -o | ...'   one quoted command to explain it."
    fi

    __BashrcFreeCoreLib
}

# Check the local weather. based on a idea from 
# https://twitter.com/agoncal/status/701362981767086082
# and http://ipinfo.io/
function weather() {

    __BashrcRequireCoreLib bashrc || return 1
    
    if ! checkDeps curl; then
        error "${FUNCNAME[0]}: The following commands are not installed: ${retval[@]}. Aborted."
        __BashrcFreeCoreLib
        return
    fi
    curl http://wttr.in/$(curl -s ipinfo.io/city)

    __BashrcFreeCoreLib
}

# src.: http://superuser.com/a/665181/456258
function tarCompressWithProgress() {

    __BashrcRequireCoreLib bashrc || return 1

    if ! checkDeps uname tar pv awk; then
        error "${FUNCNAME[0]}: The following commands are not installed: ${retval[@]}. Aborted."
        __BashrcFreeCoreLib
        return
    fi

    if [[ $# -ne 3 ]]; then
        echo "${FUNCNAME[0]} <folder to compress> <command used to compress"\
        "with arguments> <destination compressed file>"
        __BashrcFreeCoreLib
        return
    fi

    if [[ $(uname) == "Linux" ]]; then
        tar cf - "$1" -P | pv -s $(du -sb "$1" | awk '{print $1}') | "$2" > "$3"
    else
        tar cf - "$1" -P | pv -s $(($(du -sk "$1" | awk '{print $1}') * 1024)) | "$2" > "$3"
    fi

    __BashrcFreeCoreLib
}
#}}}

#{{{ SSH-agent management
#-------------------------------------------------------------------------------
# Load ssh-agent and use its environment variables. This function must be
# sourced from the profile file level to avoid the ssh-agent process to be
# forked each time the user launches a new login shell (TTY or in UI) and avoid
# high memory increase.
function manageSshAgent() {

    __BashrcRequireCoreLib bashrc || return 1

    if ! requireDeps ssh-agent ssh-add umask mkdir chmod; then
        __BashrcFreeCoreLib
        return 1
    fi

    local destinationFolder="$HOME/.ssh"

    # Ensure the destination folder really exists, is writable and executable
    # before continuing.
    # If it does not exists, try to create it.
    if [ ! -e "$destinationFolder" ]; then

        # Reset default umask
        [ $UID == 0 ] && umask 0022 || umask 0002
        if ! mkdir -p "$destinationFolder" >/dev/null 2>&1; then
            error "${FUNCNAME[0]}: Cannot create \"$destinationFolder\". Please"\
            "check the permissions of the parent folder. Aborted."
            __BashrcFreeCoreLib
            return 2
        fi
    fi

    if [ -f "$destinationFolder" ]; then
        error "${FUNCNAME[0]}: \"$destinationFolder\" is already a file."\
        "Aborted."
        __BashrcFreeCoreLib
        return 3
    fi

    if [ ! -d "$destinationFolder" ]; then
        error "${FUNCNAME[0]}: \"$destinationFolder\" is a special file (block"\
        "device, socket, pipe,...). Aborted."
        __BashrcFreeCoreLib
        return 4
    fi

    if [ ! -x "$destinationFolder" ] &&
         ! chmod u+rwx "$destinationFolder"; then
        error "${FUNCNAME[0]}: \"$destinationFolder\" is not executable and"\
        "permissions cannot be changed. Maybe this folder belongs to another"\
        "user. Aborted."
        __BashrcFreeCoreLib
        return 5
    fi

    local agentFile="$destinationFolder/agent"
    if [ ! -f "$agentFile" ]; then
        # Writing or removing a file from a folder is only authorized if that
        # folder is writable.
        if [ ! -w "$destinationFolder" ] && ! chmod u+rwx "$destinationFolder"; then
            error "${FUNCNAME[0]}: \"$destinationFolder\" is not writable and"\
            "permissions cannot be changed. Maybe this folder belongs to another"\
            "user. Aborted."
            __BashrcFreeCoreLib
            return 6
        fi

        # If the file exists, this means this is not a regular file, try to remove it.
        if [ -e "$agentFile" ]; then
            if [ -d "$agentFile" ]; then
                confirm "${FUNCNAME[0]}: \"$agentFile\" is a directory, do you"\
                "want to remove it? [y/N] "
            else
                confirm "${FUNCNAME[0]}: \"$agentFile\" already exist and is"\
                "not a regular file, do you want to remove it? [y/N] "
            fi

            if $retval; then
                if ! rm -fr "$agentFile" >/dev/null 2>&1; then
                    error "${FUNCNAME[0]}: \"$agentFile\" cannot be removed."\
                    "Aborted."
                    __BashrcFreeCoreLib
                    return 7
                fi
                success "${FUNCNAME[0]}: \"$agentFile\" removed."
            else
                error "${FUNCNAME[0]}: \"$agentFile\" will not be removed."\
                "Aborted."
                __BashrcFreeCoreLib
                return 8
            fi
        fi

        # Create an empty regular file
        [ $UID == 0 ] && umask 0022 || umask 0002
        echo -n '' > "$agentFile"
    fi
    
    if [ ! -r "$agentFile" ] && chmod u+r "$agentFile"; then
        error "${FUNCNAME[0]}: \"$agentFile\" cannot be made readable: your"\
        "ssh-agent will not be usable in other sessions. Aborted."
        __BashrcFreeCoreLib
        return 9
    fi

    # Try to recover the previously ssh-agent socket. If it is valid, we assume
    # ssh-agent is already loaded and we don't need to load it again.
    if source "$agentFile" >/dev/null 2>&1 && [ -S "$SSH_AUTH_SOCK" ]; then
        __BashrcFreeCoreLib
        return 10
    fi

    # If we have no keys stored, do not launch ssh-agent.
    local keysLocationFile="$destinationFolder/keys"
    local keysLocation=()
    if [ -r "$keysLocationFile" ] && [ -f "$keysLocationFile" ]; then
        keysLocation=$(<"$keysLocationFile")
    fi

    if [ ! -r "$destinationFolder/id_rsa" ] &&
       [ ! -r "$destinationFolder/id_dsa" ] &&
       [ ! -r "$destinationFolder/id_ecdsa" ] &&
       [ ! -r "$destinationFolder/identity" ] && 
       [ -z "$keysLocation" ]; then
        warning "${FUNCNAME[0]}: No ssh keys to read. Not using ssh-agent."
        __BashrcFreeCoreLib
        return 11
    fi

    if [ ! -w "$agentFile" ] && chmod u+w "$agentFile"; then
        error "${FUNCNAME[0]}: \"$agentFile\" cannot be made writable: unable"\
        "to launch ssh-agent. Aborted."
        __BashrcFreeCoreLib
        return 12
    fi
    
    if ! ssh-agent > "$agentFile" >/dev/null 2>&1; then
        error "${FUNCNAME[0]}: Unable to launch ssh-agent. Aborted."
        __BashrcFreeCoreLib
        return 13
    fi

    source "$agentFile" >/dev/null 2>&1

    success "${FUNCNAME[0]}: Using ssh-agent \(PID $SSH_AGENT_PID\)"

    # Load keys from the default location if any
    ssh-add

    # Load other keys where the location has been defined by the user.
    if [ -n "$keysLocationFile" ]; then
        # Transform space delimited keysLocation variable into an array for
        # easy usage.
        keysLocation=($keysLocation)
        for ((i = O; i < ${#keysLocation[@]}; i++)); do
            if [ ! -r "${keysLocation[i]}" ]; then
                warning "${FUNCNAME[0]}: The SSH-key \"${keysLocation[i]}\""\
                "specified at line $(($i + 1)) in \"$keysLocationFile\" is not"\
                "readable."
                continue
            fi

            # NOTE: These keys paths have to be defined as absolute path, as bash
            # cannot expands vars recursively.
            if [[ "${keysLocation[i]}" == */../* ||\
                  "${keysLocation[i]}" == */./* ||\
                  "${keysLocation[i]}" == ..* ||\
                  "${keysLocation[i]}" == .* ]]; then
                warning "${FUNCNAME[0]}: The SSH-key \"${keysLocation[i]}\""\
                "specified at line $(($i + 1)) is not an absolute path."\
                "Skipped."
                continue
            fi
            ssh-add "$keysLocation"
        done
    fi

    __BashrcFreeCoreLib
}
manageSshAgent

#}}}

#{{{ Platform specific
#-------------------------------------------------------------------------------
# Source platform specific code from another file
function __BashrcReloadBashSpecific() {

    __BashrcRequireCoreLib bashrc || return 1

    # NOTE: The location "./bash_specific.bashrc" cannot be used since this will
    # only check the current directory the user sourcing this script is in (default
    # is /home when booting the machine). This is not what we want. Thus we need to
    # call our global command we created.
    getScriptDirectory

    if [ -r "$retval/bash_specific.bashrc" ]; then
        . $retval/bash_specific.bashrc
    fi

    __BashrcFreeCoreLib
}
#}}}


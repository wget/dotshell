# /etc/profile: system-wide .profile file for the Bourne shell (sh(1))
# and Bourne compatible shells (bash(1), ksh(1), ash(1), ...).

#{{{ Terminal colors
#-------------------------------------------------------------------------------
BLUE="[34;01m"
CYAN="[36;01m"
CYANN="[36m"
GREEN="[32;01m"
RED="[31;01m"
ORANGE="[33;01m"
PURP="[35;01m"
OFF="[0m"
#}}}

#{{{ File permissions
#-------------------------------------------------------------------------------
# On UNIX, a umask is used to determine the file permission for newly created
# files. The default permissions are 777 for the directories and 666 for the
# files. The umask applies a NOT AND mask on these default values. By default,
# - regular users have a 0002 umask which means
#   775 (rwxrwxr-x) for directories
#   664 (rw-rw-r--) for files.
# - root user has a 0022 umask which means
#   755 (rwxr-xr-x) for directories
#   644 (rw-r--r--) for files.
# This mask will define for all regular and root users permissions as
# 700 for directories and 600 for files.
umask 077

# The default umask is now handled by pam_umask.
# See pam_umask(8) and /etc/login.defs.
umask 077

# Set our default path
export PATH="/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin:/usr/local/bin:."

# When compiling in CLI, enable ccache by taking precedence over the usual gcc
# toolchain and use the one customized by ccache package.
if [ -d "/usr/lib/ccache/bin" ]; then
    export PATH="/usr/lib/ccache/bin/:$PATH"
fi

# Change the default editor to vim if it exists.
if type vim >/dev/null 2>&1; then
    export EDITOR="vim"
fi

# Load other script profiles from /etc/profile.d
if [ -d "/etc/profile.d" ]; then
    for i in /etc/profile.d/*.sh; do
        if [ -r $i ]; then
            . $i
        fi
    done
    unset i
fi

# - An interative shell is a shell we can interract directly with. By contrast,
# a non interactive shell is started when we run a shell script. We can force
# a shell script to run in interactive mode with -i as parameter, this will
# have as consequence to jhave a more versbose output
# - A login shell is the shell started by the login process or by X.
# Interactive non-login shell are shells we start manually from another shell
# or by opening a terminal window. We can force a shell script to source the
# profiles files with the --login parameter, but aliases will not be executed,
# even if profile files declare it explicitly.

# Load system-wide and user specific bashrc configuration to make it available
# in TTY too.
# The file is sourced only if we are in interactive mode, if we are using bash
# and if the file is available.

# Relying on the PS1 presence to check if the script is run in interactive mode
# or not is really a weak check and bad practice. PS1 variable can be easily
# crafted in the profile files and the script can be run with the --login
# parameter to source the profile files. Relying on the $- is much more
# reliable since it cannot be overriden (a variable cannot contain the minus
# character).
# The =~ extended operator used in [[ ]] has been made available from Bash 3.0,
# we can use *i* in a switch case if we want to be even more backward
# compatible, but using =~ is enough.
if [[ "$-" =~ "i" && "$BASH" ]]; then
    # System-wide (might not be sourced as the location can be overriden with
    # the following compilation flag -DSYS_BASHRC="/etc/bash.bashrc").
    if [ -r "/etc/bash.bashrc" ]; then
        . "/etc/bash.bashrc"
    fi
    # User specific
    if [ -r "~/.bashrc" ]; then
        . "~/.bashrc"
    fi
fi

# Termcap is outdated, old, and crusty, kill it.
#unset TERMCAP

# Man is much better than us at figuring this out
#unset MANPATH

# Disable annoying beep PC speaker sound
setterm -blength 0


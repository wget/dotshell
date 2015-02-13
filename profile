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

#}}}

# Load other script profiles from /etc/profile.d
if [ -d "/etc/profile.d" ]; then
    for i in "/etc/profile.d/*.sh"; do
        if [ -r "$i" ]; then
            . "$i"
        fi
    done
    unset i
fi

# Set our default path
export PATH="$PATH:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin:/usr/local/bin"

# Change the default editor to vim if it exists.
if type vim >/dev/null 2>&1; then
    export EDITOR="vim"
fi

# - An interative shell is a shell we can interract directly with. By contrast,
#   a non interactive shell is started when we run a shell script. We can force
#   a shell script to run in interactive mode with -i as parameter, this will
#   have as consequence to have a more verbose output. A shell running a script
#   is always running in non-interactive mode.
# - A login shell is the shell started by the login process or by X.
#   Interactive non-login shell are shells we start manually from another shell
#   or by opening a terminal window. We can force a shell script to source the
#   profile files with the --login parameter, but aliases will not be executed,
#   even if profile files declare them explicitly.
#
# Relying on the PS1 presence to check if the script is run in interactive mode
# or not is really a weak check and bad practice. PS1 variable can be easily
# crafted in the profile files and the script can be run with the --login
# parameter to source the profile files. Relying on the $- is much more
# reliable since it cannot be overriden (a variable cannot contain the minus
# character). The =~ extended operator used in [[ ]] has been made available
# from Bash 3.0. Using *i* allows us to be even more backward compatible.
#
# Load system-wide and user specific bashrc configuration to make it available
# in TTY too.
# The file is sourced only if we are in interactive mode, if we are using Bash
# and if the file is available.
case $- in
    *i*)
        if [ -n "$BASH" ]; then
            # System-wide Bashrc. This location is only available in some Linux
            # distributions and depends on the compilation flag
            # -DSYS_BASHRC="/etc/bash.bashrc" packagers have defined.
            if [ -r "/etc/bash.bashrc" ]; then
                . "/etc/bash.bashrc"
            fi

            # User specific
            if [ -r "~/.bashrc" ]; then
                . "~/.bashrc"
            fi
        fi
    ;;
esac

# Disable annoying beep PC speaker sound. setterm set terminal TTY attributes.
# And is only valid for Linux and Minix.
if setterm --version >/dev/null 2>&1; then
    setterm -blength 0 >/dev/null 2>&1
fi

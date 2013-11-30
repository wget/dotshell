# /etc/profile: system-wide .profile file for the Bourne shell (sh(1))
# and Bourne compatible shells (bash(1), ksh(1), ash(1), ...).

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

# Load system-wide and user specific bashrc configuration to make it available
# in TTY too.
# The file is sourced only if we are in interactive mode, if we are using bash
# and if the file is available.
if [ "$PS1" ] && [ "$BASH" ]; then
    # System-wide (not necessary to be sourced if Bash is compiled with
    # -DSYS_BASHRC="/etc/bash.bashrc" flag which defines a system-wide Bashrc).
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


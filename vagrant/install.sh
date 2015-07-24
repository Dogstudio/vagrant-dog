#!/usr/bin/env bash
#
#   Installer for "Vagrant Dog"
#
#   Author: Thierry 'Epagneul' Lagasse <epagneul@dogstudio.be>
#   Since: Jul 2015
#
# =============================================================================

SEP="$(printf '%0.1s' "-"{1..80})"$'\n'

# -----------------------------------------------------------------------------

function echo_success { echo -ne "$1\033[70G\033[0;39m[   \033[1;32mOK\033[0;39m    ]\n"; }
function echo_failure { echo -ne "$1\033[70G\033[0;39m[ \033[1;31mFAILED\033[0;39m  ]\n"; }

# -----------------------------------------------------------------------------

function confirm {
    echo -en "\a" ; read -p "$1" BOOL_CONFIRM
    if [[ $BOOL_CONFIRM =~ [YyOo] ]]; then true ; else false ; fi
}

function askcontinue {
    READVAR="$2"
    if [ -n "$READVAR" ] || ! read -p "$1" READVAR || [ -n "$READVAR" ]; then
        echo "$READVAR"
    else
        false
    fi
}

# -----------------------------------------------------------------------------

# Get current script
SCRIPT_URL="git@gitlab.dogstudio.be:devtools/vagrantdog.git"
SCRIPT_BRANCH="develop"
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd -P)

# Install from remote 
if [[ $(basename $0) != "install.sh" ]]; then
    echo -e "\tDownloading"
    git archive --remote $SCRIPT_URL $SCRIPT_BRANCH | tar -x -C ./ && bash install.sh

# Install localy
else
    echo "URL: ${SCRIPT_URL}"
    echo "PATH: ${SCRIPT_PATH}"

fi
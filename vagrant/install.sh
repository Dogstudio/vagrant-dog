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
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}/../"` && pwd -P)
BACKUP_FILES="README.md vagrant.json"

# Install from remote 
if [[ $(basename $0) != "install.sh" ]]; then

    echo -en "\t- Backuping existing files"
    for FILE in $BACKUP_FILES; do
        if [[ -e ${SCRIPT_PATH}/$FILE ]]; then
            cp ${SCRIPT_PATH}/README.md ${SCRIPT_PATH}/README.md.back
        fi
    done

    echo -en "\t- Downloading VagrantDog"
    git archive --remote $SCRIPT_URL $SCRIPT_BRANCH | tar -x -C ./ && bash vagrant/install.sh

# Install localy
else

    echo -en "\t- Restoring files"
    for FILE in $(ls ${SCRIPT_PATH}/**/*.back); do
        mv -f "$FILE" "${FILE%%.back}"
    done

    # if confirm "Want configure your project : " ; then
    #     PROJECT_NAME=$(askcontinue "Enter the project name : ")
    #     PROJECT_IP_PRIVATE=$(askcontinue "Enter the private IP (default: 10.0.1.9) : ")
    #     PROJECT_IP_PUBLIC=$(askcontinue "Enter the private IP (ex: 192.168.1.200 ou 200) : ")
    # fi
fi
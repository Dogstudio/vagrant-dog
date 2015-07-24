#!/usr/bin/env bash
#
#   Installer for "Vagrant Dog"
#
#   Author: Thierry 'Epagneul' Lagasse <epagneul@dogstudio.be>
#   Since: Jul 2015
#
# -----------------------------------------------------------------------------

# Get current script
SCRIPT_URL="git@gitlab.dogstudio.be:devtools/vagrantdog.git"
SCRIPT_BRANCH="develop"
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd -P)


# Install from remote 
if [[ $(basename $0) != "install.sh" ]]; then
    echo -e "\tDownloading"
    git archive --remote $SCRIPT_URL $SCRIPT_BRANCH | tar -x -C ./ && bash install.sh


echo "URL: ${SCRIPT_URL}"
echo "PATH: ${SCRIPT_PATH}"

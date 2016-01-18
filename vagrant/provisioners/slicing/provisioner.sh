#!/bin/bash
#
# Vagrant Provisionner for Slicing (frontend)
#   - NPM
#   - Gulp
#   - Bower
#
# @author   Dogstudio
# @since    Sept. 2015
#
# =============================================================================

PROJECT_NAME=$( echo $1 | sed -e 's/[A-Z]/\L&/g;s/ /_/g')
PROJECT_HOST=$2
PROJECT_ROOT=$3
PRIVATE_IP=$4

LOG_FILE="/vagrant/.vagrant/deploy.log"

# =============================================================================

CLL="\r$(printf '%*s\n' 80)\r"
SEP="\r$(printf '%0.1s' "-"{1..80})"

function echo_line    { echo -en "${CLL}$*\n"; }
function echo_success { echo -en "${CLL}$*\033[69G\033[0;39m[   \033[1;32mOK\033[0;39m    ]\n"; }
function echo_failure { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;31mFAILED\033[0;39m  ]\n"; }
function echo_warning { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;33mWARNING\033[0;39m ]\n"; }
function echo_done    { echo -en "${CLL}$*\033[69G\033[0;39m[  \033[1;34mDONE\033[0;39m   ]\n"; }

# -----------------------------------------------------------------------------

# NODEJS AND SLICING TOOLS
echo_line "Node.js and slicing tools"

SLINE="\t- Adding Node.js package"
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash - >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Installing Node.js"
apt-get install -y nodejs >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Installing Build tools"
apt-get install --yes build-essential >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Installing Bower"
npm install -g bower >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Installing Gulp"
npm install -g gulp >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Enabling tools in /cut"
cd "${PROJECT_ROOT}cut/"
npm install && bower install >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE
cd "${PROJECT_ROOT}"

# =============================================================================

#!/bin/bash
#
# Vagrant Provisionner for Mongodb
#
# =============================================================================

PROJECT_NAME=$( echo $1 | sed -e 's/[A-Z]/\L&/g;s/ /_/g')
PROJECT_HOST=$2
PROJECT_ROOT=$3
PRIVATE_IP=$4

LOG_FILE="/vagrant/.vagrant/deploy.log"
DB_ROOT_PASS="vagrant"
DB_DUMP_FILE="/vagrant/.vagrant/dump.sql"

# =============================================================================

CLL="\r$(printf '%*s\n' 80)\r"
SEP="\r$(printf '%0.1s' "-"{1..80})"

function echo_line    { echo -en "${CLL}$*\n"; }
function echo_success { echo -en "${CLL}$*\033[69G\033[0;39m[   \033[1;32mOK\033[0;39m    ]\n"; }
function echo_failure { echo -en    "${CLL}$*\033[69G\033[0;39m[ \033[1;31mFAILED\033[0;39m  ]\n"; }
function echo_warning { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;33mWARNING\033[0;39m ]\n"; }
function echo_done    { echo -en "${CLL}$*\033[69G\033[0;39m[  \033[1;34mDONE\033[0;39m   ]\n"; }

# -----------------------------------------------------------------------------

# MONGODB
echo_line "Nodejs"

SLINE="\t- Update system"
sudo apt-get update -y >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Get dependencies"
sudo apt-get install -y git-core curl build-essential openssl libssl-dev >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Get nodejs"
sudo curl -sL https://deb.nodesource.com/setup | sudo bash >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Install nodejs"
sudo apt-get install -y nodejs >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Node version: "
echo_done $SLINE `node -v`

SLINE="\t- Install nodemon"
sudo npm install -g nodemon >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Install pm2"
sudo npm install -g pm2 >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Npm version: "
echo_done $SLINE `npm -v`

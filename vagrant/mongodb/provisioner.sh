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
function echo_failure { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;31mFAILED\033[0;39m  ]\n"; }
function echo_warning { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;33mWARNING\033[0;39m ]\n"; }
function echo_done    { echo -en "${CLL}$*\033[69G\033[0;39m[  \033[1;34mDONE\033[0;39m   ]\n"; }

# -----------------------------------------------------------------------------

# MONGODB
echo_line "Mongodb"

SLINE="\t- Key"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10 >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure
SLINE="\t- Requirements"
sudo apt-get install lsb-release >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- File list"
echo "deb http://repo.mongodb.org/apt/debian "$(lsb_release -sc)"/mongodb-org/3.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list >>$LOG_FILE 2>&1

sudo apt-get update  >>$LOG_FILE 2>&1

SLINE="\t- Installation"
sudo apt-get install -y mongodb-org >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Start mongodb"
sudo service mongod start >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

if grep -q "waiting for connections on port" /var/log/mongodb/mongod.log
then
    echo_done "Mongodb is running"
else
    echo_failure "Mongodb is not running"
fi

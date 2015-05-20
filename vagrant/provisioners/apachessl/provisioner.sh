#!/bin/bash
#
# Vagrant provisioner for SSL support on Apache 2
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

# =============================================================================

# Apache2 (Pouwa)
echo_line "Enabling SSL Support for Apache2"

if [[ ! -f /etc/apache2/sites-enabled/default-ssl ]]; then

    SLINE="\t- Configuration"
    a2enmod ssl >>$LOG_FILE 2>&1 &&
    /etc/init.d/apache2 restart >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE

    SLINE="\t- Configure vHost"
    pushd /etc/apache2/sites-available >>$LOG_FILE &&
    cp default-ssl default-ssl.back && cp default-ssl default-ssl.new &&
    awk '/<Directory \/var\/www/,/AllowOverride None/{sub("None", "All",$0)}{print}' default-ssl.new > default-ssl &&
    sed -i -e "s|/var/www|${PROJECT_ROOT}|" default-ssl &&

    echo_success $SLINE || echo_failure $SLINE

    SLINE="\t- Activate SSL vHost"
    a2ensite default-ssl >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE

    SLINE="\t- Restart"
    /etc/init.d/apache2 restart >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE
fi
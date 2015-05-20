#!/bin/bash
#
# Vagrant Provisionner for PHP Dev
#   - Apache
#   - MySQL
#   - PHP-fpm
#
# @author   Akarun for KRKN <akarun@krkn.be> and Passtech <akarun@passtech.be>
# @since    August 2014
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

# MAILCATCHER
echo_line "Mailcatcher"

SLINE="\t- Mailutils"
apt-get install -y mailutils >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Ruby"
test $(which ruby) && echo_done $SLINE || ( apt-get install -y ruby-full >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure )

SLINE="\t- SQLite"
test $(which sqlite3) && echo_done $SLINE || ( apt-get install -y libsqlite3-dev >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure )

SLINE="\t- Mailcatcher"
gem install mailcatcher >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Mailcatcher php mod"
# Add config to mods-available for PHP
echo "sendmail_path = /usr/bin/env catchmail --smtp-ip 0.0.0.0 -f mailcatcher@vagrant.dev" | tee /etc/php5/mods-available/mailcatcher.ini &&
# Enable sendmail config for all php SAPIs (apache2, fpm, cli)
php5enmod mailcatcher &&
# Restart Apache if using mod_php
service apache2 restart >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Mailcatcher start on boot"
cp /vagrant/vagrant/mailcatcher/mailcatcher /etc/init.d/mailcatcher &&
chmod a+x /etc/init.d/mailcatcher &&
# set as an auto boot service
update-rc.d mailcatcher defaults >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Mailcatcher start"
/etc/init.d/mailcatcher start >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

# =============================================================================

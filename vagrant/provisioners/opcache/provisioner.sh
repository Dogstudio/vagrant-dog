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
SCONFIG="
zend_extension=/usr/lib/php5/20100525/opcache.so\n
opcache.revalidate_freq=0\n
opcache.validate_timestamps=0\n
opcache.memory_consumption=192\n
opcache.interned_strings_buffer=16\n
opcache.max_accelerated_files=6000\n
opcache.fast_shutdown=1\n
opcache.enable_cli=1";

# OPCACHE
echo_line "OPCache"

SLINE="\t- Pecl"
sudo apt-get install -y php-pear >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Build"
sudo apt-get install -y build-essential php5-dev >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Opcache"
sudo pecl install zendopcache-7.0.2 >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Config"
printf $SCONFIG | sudo tee /etc/php5/mods-available/opcache.ini >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Symlink"
sudo ln -s /etc/php5/mods-available/opcache.ini /etc/php5/conf.d/20-opcache.ini >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Restart apache"
sudo service apache2 restart >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Restart apache"
cat /vagrant/vagrant/opcache/opcache-gui.ini >> /etc/php5/mods-available/phalcon.ini && >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

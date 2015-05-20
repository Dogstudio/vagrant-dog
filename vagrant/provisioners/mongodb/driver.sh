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

SLINE="\t- Pear"
sudo apt-get -y install php5-dev php5-cli php-pear >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Mongo driver"
sudo pecl install mongo >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure

SLINE="\t- Add extension"

grep -q 'mongo.so' /etc/php5/apache2/php.ini || 
tee -a /etc/php5/apache2/php.ini >>$LOG_FILE <<EOF
extension=mongo.so
EOF

echo "extension=mongo.so" >> /etc/php5/apache2/php.ini >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure
cat /vagrant/vagrant/mongodb/mongo.ini >> /etc/php5/mods-available/mongo.ini >>$LOG_FILE 2>&1

sudo ln -s /etc/php5/mods-available/mongo.ini /etc/php5/apache/conf.d/mongo.ini >>$LOG_FILE 2>&1
sudo ln -s /etc/php5/mods-available/mongo.ini /etc/php5/cli/conf.d/mongo.ini >>$LOG_FILE 2>&1
sudo ln -s /etc/php5/mods-available/mongo.ini /etc/php5/fpm/conf.d/mongo.ini >>$LOG_FILE 2>&1

SLINE="\t- Restart server"
service apache2 restart >>$LOG_FILE 2>&1 &&

echo_done "Mongo php driver installed"

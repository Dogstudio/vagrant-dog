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

LOG_FILE="/vagrant/.vagrant/deploy.log"

# =============================================================================

CLL="\r$(printf '%*s\n' 80)\r"
SEP="\r$(printf '%0.1s' "-"{1..80})"

function echo_line    { echo -en "${CLL}$*\n"; }
function echo_success { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;32mOK\033[0;39m      ]\n"; }
function echo_failure { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;31mFAILED\033[0;39m  ]\n"; }
function echo_warning { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;33mWARNING\033[0;39m ]\n"; }
function echo_skip    { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;34mSKIPPED\033[0;39m ]\n"; }
function echo_done    { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;34mDONE\033[0;39m    ]\n"; }
function process_end {
    if (( $# > 0 )); then
        echo_failure "ERROR($1) : $2"
        echo_line "${SEP}"
        exit 1
    else
        echo_line "${SEP}"
        exit 0
    fi
}

# =============================================================================

# Update and package list
echo_line "${SEP}"

# =============================================================================

# ELASTICSEARCH

echo_line "ElasticSearch\n"

SLINE="\t- Install Java"
test $(which java) && echo_done $SLINE || ( apt-get install -y openjdk-7-jre-headless >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE)

SLINE="\t- Download"
SLINE2="\t- Installation"
if [[ ! -f /etc/init.d/elasticsearch ]]; then
    pushd /tmp >>$LOG_FILE
    wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.4.deb >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE
    dpkg -i elasticsearch-1.4.4.deb >>$LOG_FILE 2>&1 && echo_success $SLINE2 || echo_failure $SLINE2

    # set as an auto boot service
    update-rc.d elasticsearch defaults  >>$LOG_FILE 2>&1
    popd >>$LOG_FILE
else
    echo_skip $SLINE
    echo_done $SLINE2
fi

SLINE="\t- Start"
service elasticsearch start >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Install HEAD Plugin"
test /usr/share/elasticsearch/plugins/head && echo_done $SLINE || (/usr/share/elasticsearch/bin/plugin -install mobz/elasticsearch-head >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE)

# =============================================================================
# End
process_end
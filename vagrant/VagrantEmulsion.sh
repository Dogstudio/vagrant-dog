#!/bin/bash
#
# Vagrant Provisionner for PHP Dev
#   - NginX
#   - MySQL
#   - PHP-fpm
#
# @author   Akarun for KRKN <akarun@krkn.be> and Passtech <akarun@passtech.be>
# @since    August 2014
#
# =============================================================================
START_TIME=$SECONDS
PROJECT_NAME=$1
PROJECT_HOST=$2
LOG_FILE="/vagrant/.vagrant/deploy.log"
DB_ROOT_PASS="vagrant"
DB_DUMP_FILE="/vagrant/.vagrant/dump.sql"

# =============================================================================
SEP="$(printf '%0.1s' "-"{1..80})\n"
function echo_success { echo -ne "\033[60G\033[0;39m[   \033[1;32mOK\033[0;39m    ]\n\r"; }
function echo_failure { echo -ne "\033[60G\033[0;39m[ \033[1;31mFAILED\033[0;39m  ]\n\r"; }
function echo_warning { echo -ne "\033[60G\033[0;39m[ \033[1;33mWARNING\033[0;39m ]\n\r"; }
function echo_done  { echo -ne "\033[60G\033[0;39m[   \033[1;34mDONE\033[0;39m  ]\n\r"; }

function process_end {
    if [[ $1 > 0 ]]; then
        echo -en "${SEP}Error $1 : $2" ; echo_failure
    else
        ELAPSED_TIME=$(($SECONDS - $START_TIME))
        echo -en "${SEP}Deploy completed in $(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec"
        echo_success

        echo -en "Current IPs : \n"
        ifconfig | awk -v RS="\n\n" '{ for (i=1; i<=NF; i++) if ($i == "inet" && $(i+1) ~ /^addr:/) address = substr($(i+1), 6); if (address != "127.0.0.1") printf "\t%s\t%s\n", $1, address }'
    fi

    echo -e "\a" # DING... The Box is hot!
    exit 0
}

# =============================================================================

# Clear LOG
echo "" > $LOG_FILE

# Update and package list
echo -en "${SEP}\nSystem Update"

apt-get -yq update >>$LOG_FILE 2>&1 && #apt-get -yq upgrade >>$LOG_FILE 2>&1 &&
echo_success || process_end 1 "Unable to update the system"

# Sharing fix
echo "SELINUX=disabled" >> /etc/selinux/config

# =============================================================================

# Tools
echo -en "Install Tools\n"

echo -en "\t- Python Software Properties"
test $(which add-apt-repository) && echo_done || ( apt-get install -y python-software-properties >>$LOG_FILE 2>&1 || echo_failure )

echo -en "\t- Vim"
test $(which vim) && echo_done || ( apt-get install -y vim >>$LOG_FILE 2>&1 && echo_success || echo_failure )

echo -en "\t- Apg"
test $(which apg) && echo_done || ( apt-get install -y apg >>$LOG_FILE 2>&1 && echo_success || echo_failure )

echo -en "\t- Zip"
test $(which zip) && echo_done || ( apt-get install -y zip unzip >>$LOG_FILE 2>&1 && echo_success || echo_failure )

echo -en "\t- Git"
test $(which git) && echo_done || ( apt-get install -y git >>$LOG_FILE 2>&1 && echo_success || echo_failure )

# -----------------------------------------------------------------------------

# Prompt and aliases
echo -en "Prompt and aliases"

grep -q 'alias duh' /root/.bashrc || tee -a /root/.bashrc >>$LOG_FILE <<EOF
# Prompt
export PS1="\n\[\033[1;31m\][\u@\h \#|\W]\[\033[0m\]\n\[$(tput bold)\]↪ "
# Use colors
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias l='clear; ls -la'
alias duh='du -hs'
alias tree="find . | sed 's/[^/]*\//|   /g;s/| *\([^| ]\)/+--- \1/'"
alias wget="wget -c"
alias work='supervisor -w bin,static -e js,jade -i files,node_modules,src,static bin/server.js'

cd /vagrant
EOF

cp -f /root/.bashrc /home/vagrant/ && chown vagrant: /home/vagrant/.bashrc &&
sed -i -e "/PS1/s/31m/32m/" /home/vagrant/.bashrc &&
echo_success

# VIM Config.
echo -en "Vim config"

sed -e "/^\"syntax/s/^\"//" -i /etc/vim/vimrc        # Activer la coloration syntaxique
sed -e "/showcmd/s/^\"//" -i /etc/vim/vimrc
sed -e "/showmatch/s/^\"//" -i /etc/vim/vimrc        # Show matching brackets.
sed -e "/ignorecase/s/^\"//" -i /etc/vim/vimrc       # Recherche sans tenir compte de la casse
sed -e "/smartcase/s/^\"//" -i /etc/vim/vimrc        # Do smart case matching

tee -a /etc/vim/vimrc >>$LOG_FILE <<EOF
set tabstop=4
set viminfo=\'20,\"50
set history=50
set ruler
EOF
echo_success

# Remove MOTD
echo "" > /etc/motd
sed -i -e '/uname/s/^/#/' /etc/init.d/motd

# -----------------------------------------------------------------------------

# MySQL
echo -en "Install MySQL\t"

if [[ -z $(which mysql) ]]; then
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"

    apt-get install -y mysql-server mysql-client >>$LOG_FILE 2>&1 &&
    echo_success || echo_failure
else
    echo_done
fi

# Preparing DB
echo -en "\t- Enable MySQL remote access\t"
sed -i -e '/bind-address/s/^/# /' /etc/mysql/my.cnf >>$LOG_FILE 2>&1 &&
service mysql restart >>$LOG_FILE 2>&1 &&
echo_success || echo_failure

echo -en "\t- Create DB and User 'vagrant'\t"
mysql -u"root" -p"${DB_ROOT_PASS}" <<EOF
CREATE USER 'vagrant'@'localhost' IDENTIFIED BY 'vagrant';
CREATE USER 'vagrant'@'%' IDENTIFIED BY 'vagrant';
GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'localhost';
GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%';
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS ${PROJECT_NAME,,} CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci';
EOF
echo_success

if [ -e "$DB_DUMP_FILE" ]; then
    echo -en "\t- Populate DB with old dump.\t"
    mysql -u"root" -p"${DB_ROOT_PASS}" "${PROJECT_NAME,,}" < $DB_DUMP_FILE
    echo_done
fi

# -----------------------------------------------------------------------------


# Apache2 (Pouwa)
echo -en "Install Apache2\t"
if [[ ! -f /etc/apache2/apache2.conf ]]; then
    apt-get install -y apache2 apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert >>$LOG_FILE 2>&1 &&
    a2enmod rewrite >>$LOG_FILE 2>&1

    sed -i -e '/HostnameLookups/s/On/Off/' /etc/apache2/apache2.conf
    sed -i -e '/^#AddDefaultCharset/s/#//' /etc/apache2/conf.d/charset
    echo "EnableSendfile Off" > /etc/apache2/conf.d/vagrant

    /etc/init.d/apache2 restart >>$LOG_FILE 2>&1 &&
    echo_success || process_end 1 "Unable to install of configure Apache2"

    echo -en "\tSetting Apache Host\t"
    pushd /etc/apache2/sites-available  >>$LOG_FILE &&
    cp default default.back && cp default default.new &&

    sed -i -e "s/\/var\/www/\/vagrant\/public/" default.new &&
    awk '/<Directory \/vagrant\/public\/>/,/AllowOverride None/{sub("None", "All",$0)}{print}' default.new > default

    /etc/init.d/apache2 restart >>$LOG_FILE 2>&1 &&
    echo_success || echo_failure
fi

# -----------------------------------------------------------------------------

# PHP
echo -en "Install PHP\t"
apt-get install -y libapache2-mod-php5 php5-common php5-mysql php5-curl php5-gd php5-mcrypt php5-cli >>$LOG_FILE 2>&1 &&

sed -i -e "/display_errors/s/Off/On/" /etc/php5/apache2/php.ini >>$LOG_FILE 2>&1 &&
echo_success || echo_failure

# =============================================================================

# Composer
echo -en "Install Composer\t"

if [[ -z $(which composer) ]]; then
    curl -sS https://getcomposer.org/installer | php >>$LOG_FILE 2>&1 &&
    chmod a+x composer.phar >>$LOG_FILE 2>&1 &&
    mv composer.phar /usr/local/bin/composer >>$LOG_FILE 2>&1 &&
    echo_success || echo_failure
else
    echo_done
fi

# =============================================================================

# Project
echo -en "Deploy project sources"
pushd /vagrant/public >/dev/null &&
echo_success || echo_failure

# Composer
if [ -e "composer.json" ]; then
    composer update
fi

# =============================================================================

# End
process_end

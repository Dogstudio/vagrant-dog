#!/bin/bash
#
# Vagrant Provisioner for PHP Dev
#   - Apache
#   - MySQL
#   - PHP-fpm
#
# @author   Thierry 'Epagneul' Lagasse <epagneul@dogstudio.be>
# @since    August 2014
#
# =============================================================================

# VARS

PROJECT_HOST=$1
PROJECT_ROOT=$2

PROJECT_DEV_ROOT="${PROJECT_ROOT}dev/public"
PROJECT_CUT_ROOT="${PROJECT_ROOT}cut/public"

PROJECT_NAME=$( echo $PROJECT_HOST | sed -e 's/[A-Z]/\L&/g;s/[\-\.]/_/g')

LOG_FILE="/vagrant/.vagrant/deploy.log"
APACHE_LOG_DIR="/var/log/apache2/"
README_FILE="/vagrant/README.md"
DB_ROOT_PASS="vagrant"
DB_DUMP_FILE="/vagrant/database/dump.sql"


# SKELS

VHOST_SKEL="<VirtualHost *:80>
    ServerAdmin webmaster@localhost

    ServerName ##PROJECT_NAME
    DocumentRoot ##PROJECT_DEV_ROOT

    <Directory />
        Options FollowSymLinks
        AllowOverride None
    </Directory>

    <Directory ##PROJECT_DEV_ROOT>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
        Order allow,deny
        allow from all
    </Directory>

    ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
    <Directory /usr/lib/cgi-bin>
        AllowOverride None
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        Order allow,deny
        Allow from all
    </Directory>

    ##VHOST_ALIAS_CUT

    # OTHERALIAS
</VirtualHost>"

VHOST_ALIAS_CUT="
    Alias /cut ##PROJECT_CUT_ROOT
    <Directory ##PROJECT_CUT_ROOT>
        Options Indexes MultiViews FollowSymLinks
        AllowOverride All
        Require all granted
        Order allow,deny
        Allow from all
    </Directory>
"

# =============================================================================

CLL="\r$(printf '%*s\n' 80)\r"
SEP="\r$(printf '%0.1s' "-"{1..80})"

function echo_line    { echo -en "${CLL}$*\n"; }
function echo_success { echo -en "${CLL}$*\033[69G\033[0;39m[   \033[1;32mOK\033[0;39m    ]\n"; }
function echo_failure { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;31mFAILED\033[0;39m  ]\n"; }
function echo_warning { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;33mWARNING\033[0;39m ]\n"; }
function echo_done    { echo -en "${CLL}$*\033[69G\033[0;39m[  \033[1;34mDONE\033[0;39m   ]\n"; }

function process_end {
    echo_line "${SEP}"

    if (( $# > 0 )); then
        echo_failure "ERROR($1) : $2" ; exit 1

    else
        echo_line "Current IPs :"
        ifconfig | awk -v RS="\n\n" '{ for (i=1; i<=NF; i++) if ($i == "inet" && $(i+1) ~ /^addr:/) address = substr($(i+1), 6); if (address != "127.0.0.1") printf "\r\040\040\040\040%s --> %s\n", $1, address; }'

        echo_success "Deploy completed !"
    fi

    echo_line "${SEP}\n"
    exit 0
}

# =============================================================================

# Clear LOG
echo "" > $LOG_FILE

# Prepare README
grep -q '## Vagrant' $README_FILE || tee -a $README_FILE >>$LOG_FILE <<EOF

---

## Vagrant

EOF

# Update and package list
echo_line "${SEP}"

apt-get -yq update >>$LOG_FILE 2>&1 &&
echo_success "System Updated" || process_end 1 "Unable to update the system"

# =============================================================================

# MySQL
echo_line "MySQL"

if [ -z "$(which mysql)" ]; then

    SLINE="\t- Installation"

    debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"

    apt-get install -y mysql-server mysql-client >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE

    # Preparing DB
    SLINE="\t- Enable MySQL remote access\t"

    sed -i -e '/bind-address/s/^/# /' /etc/mysql/my.cnf >>$LOG_FILE 2>&1 &&
    service mysql restart >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE

fi

SLINE="\t- Create database : ${PROJECT_NAME}"

mysql -u"root" -p"${DB_ROOT_PASS}" <<EOF
CREATE USER 'vagrant'@'localhost' IDENTIFIED BY 'vagrant';
CREATE USER 'vagrant'@'%' IDENTIFIED BY 'vagrant';
GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'localhost';
GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%';
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${PROJECT_NAME}\` CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci';
EOF


if [ -e "$DB_DUMP_FILE" ]; then

    SLINE="\t- Populate DB with \"${DB_DUMP_FILE}\"."
    mysql -u"root" -p"${DB_ROOT_PASS}" "${PROJECT_NAME}" < $DB_DUMP_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE

fi

# =============================================================================

# Apache2 (Pouwa)
echo_line "Apache2"

if [ ! -f /etc/apache2/apache2.conf ]; then

    SLINE="\t- Installation"
    apt-get install -y apache2 apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE

    SLINE="\t- Configuration"
    a2enmod rewrite >>$LOG_FILE 2>&1 &&
    sed -i -e '/HostnameLookups/s/On/Off/' /etc/apache2/apache2.conf &&
    echo "EnableSendfile Off" > /etc/apache2/conf-enabled/vagrant.conf &&
    /etc/init.d/apache2 restart >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE

fi

# Prepare Alias for CUT
if [ -d "$PROJECT_CUT_ROOT" ]; then

    SLINE="\t- Prepare alias for \"CUTs\""
    VHOST_ALIAS_CUT=$(eval "echo -e \"$(echo -e "$VHOST_ALIAS_CUT" | sed -e 's/##/$/g')\"")
    echo_success $SLINE || echo_failure $SLINE

else
    VHOST_ALIAS_CUT=''

fi

# vHost
SLINE="\t- Default vHost"
VHOST_SKEL=$(eval "echo -e \"$(echo -e "$VHOST_SKEL" | sed -e 's/##/$/g')\"")
pushd /etc/apache2/sites-available >>$LOG_FILE &&
echo "$VHOST_SKEL" > 000-default.conf &&
echo_success $SLINE || echo_failure $SLINE

# Service priority
SLINE="\t- Change startup priority"
for LINK in $(find /etc/rc*.d -name "S*apache*"); do
    mv $LINK $(dirname $LINK)/S10apache2 >>$LOG_FILE
done
echo_success $SLINE || echo_failure $SLINE

# Restart Apache
SLINE="\t- Restart"
/etc/init.d/apache2 restart >>$LOG_FILE 2>&1 &&
echo_success $SLINE || echo_failure $SLINE

# =============================================================================

# PHP
echo_line "PHP"

if [ -z "$(which php)" ]; then

    SLINE="\t- Install"
    apt-get install -y libapache2-mod-php5 php5-common php5-mysql php5-curl php5-gd php5-mcrypt php5-cli >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE

    SLINE="\t- Configure"
    sed -i -e "/display_errors/s/Off/On/" /etc/php5/apache2/php.ini >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE

fi


# =============================================================================

# Composer / Project
echo_line "Composer & Project"

if [ -z "$(which composer)" ]; then

    SLINE="\t- Install composer"
    curl -sS https://getcomposer.org/installer | php >>$LOG_FILE 2>&1 &&
    chmod a+x composer.phar >>$LOG_FILE 2>&1 &&
    mv composer.phar /usr/local/bin/composer >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE

fi

SLINE="\t- Project"
pushd ${PROJECT_ROOT} >/dev/null &&
echo_success $SLINE || echo_failure $SLINE


# =============================================================================


# End
process_end

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

PROJECT_HOST=$1
PROJECT_ROOT=$2
PROJECT_NAME=$( echo $PROJECT_HOST | sed -e 's/[A-Z]/\L&/g;s/-/_/g')

LOG_FILE="/vagrant/.vagrant/deploy.log"
README_FILE="/vagrant/README.md"
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

apt-get -yq update >>$LOG_FILE 2>&1 && #apt-get -yq upgrade >>$LOG_FILE 2>&1 &&
echo_success "System Updated" || process_end 1 "Unable to update the system"

# Sharing fix
echo "SELINUX=disabled" >> /etc/selinux/config

# =============================================================================

# Tools
echo_line "Install Tools\n"

SLINE="\t- Python Software Properties"
test $(which add-apt-repository) && echo_done $SLINE || ( apt-get install -y python-software-properties >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE )

SLINE="\t- Vim"
test $(which vim) && echo_done $SLINE || ( apt-get install -y vim >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure )

SLINE="\t- Apg"
test $(which apg) && echo_done $SLINE || ( apt-get install -y apg >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE )

SLINE="\t- Zip"
test $(which zip) && echo_done $SLINE || ( apt-get install -y zip unzip >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE )

SLINE="\t- Git"
test $(which git) && echo_done $SLINE || ( apt-get install -y git >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure )

SLINE="\t- Curl"
test $(which curl) && echo_done $SLINE || ( apt-get install -y curl >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure )

# Vagrant commands from VMs
tee -a /root/.vagrant-scripts >>$LOG_FILE <<EOF
#! /bin/bash
function vagrant() {
    case \$1 in
        'halt')
            sudo init 0
            ;;
        *)
            echo "Oupss. You're in the VM..."
            ;;
    esac      
}
EOF

cp -f /root/.vagrant-scripts /home/vagrant/ && chown vagrant: /home/vagrant/.vagrant-scripts &&
echo_success "\t- Vagrant Commands"

# Prompt and aliases
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

# Vagrant commands
source /root/.vagrant-scripts
alias vhalt='vagrant halt'

cd /vagrant
EOF

cp -f /root/.bashrc /home/vagrant/ && chown vagrant: /home/vagrant/.bashrc &&
sed -i -e "/source/s/root/home\/vagrant/" /home/vagrant/.bashrc &&
sed -i -e "/PS1/s/31m/32m/" /home/vagrant/.bashrc &&
echo_success "\t- Bash & Aliases"

# VIM Config.
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
echo_success "\t- Vim config"

# SSH Config
echo "" > /var/run/motd.dynamic &&
sed -e "/PrintLastLog/s/yes/no/" -i /etc/ssh/sshd_config &&
service ssh restart >>$LOG_FILE 2>&1 &&
echo_success "\t- SSH config" || echo_failure "\t- SSH config"

# -----------------------------------------------------------------------------

# MySQL
echo_line "MySQL"

if [[ -z $(which mysql) ]]; then
    SLINE="\t- Installation"

    debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"

    apt-get install -y mysql-server mysql-client >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE
fi

# Preparing DB
SLINE="\t- Enable MySQL remote access\t"

sed -i -e '/bind-address/s/^/# /' /etc/mysql/my.cnf >>$LOG_FILE 2>&1 &&
service mysql restart >>$LOG_FILE 2>&1 &&
echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Create database : ${PROJECT_NAME,,}"

mysql -u"root" -p"${DB_ROOT_PASS}" <<EOF
CREATE USER 'vagrant'@'localhost' IDENTIFIED BY 'vagrant';
CREATE USER 'vagrant'@'%' IDENTIFIED BY 'vagrant';
GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'localhost';
GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%';
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${PROJECT_NAME,,}\` CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci';
EOF



if [ -e "$DB_DUMP_FILE" ]; then
    SLINE="\t- Populate DB with old dump."
    mysql -u"root" -p"${DB_ROOT_PASS}" "${PROJECT_NAME,,}" < $DB_DUMP_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE
fi

# -----------------------------------------------------------------------------


# Apache2 (Pouwa)
echo_line "Apache2"

if [[ ! -f /etc/apache2/apache2.conf ]]; then
    
    SLINE="\t- Installation"
    apt-get install -y apache2 apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE
    
    SLINE="\t- Configuration"
    a2enmod rewrite >>$LOG_FILE 2>&1 &&
    sed -i -e '/HostnameLookups/s/On/Off/' /etc/apache2/apache2.conf &&
    sed -i -e '/^#AddDefaultCharset/s/#//' /etc/apache2/conf.d/charset &&
    echo "EnableSendfile Off" > /etc/apache2/conf.d/vagrant &&
    /etc/init.d/apache2 restart >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE

    SLINE="\t- Configure vHost"
    pushd /etc/apache2/sites-available >>$LOG_FILE &&
    cp default default.back && cp default default.new &&
    awk '/<Directory \/var\/www/,/AllowOverride None/{sub("None", "All",$0)}{print}' default.new > default &&
    sed -i -e "s|/var/www|${PROJECT_ROOT}|" default &&
    
    echo_success $SLINE || echo_failure $SLINE

    SLINE="\t- Restart"
    /etc/init.d/apache2 restart >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure $SLINE
fi

# -----------------------------------------------------------------------------

# PHP
echo_line "PHP"

SLINE="\t- Install"
apt-get install -y libapache2-mod-php5 php5-common php5-mysql php5-curl php5-gd php5-mcrypt php5-cli >>$LOG_FILE 2>&1 &&
echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Configure"
sed -i -e "/display_errors/s/Off/On/" /etc/php5/apache2/php.ini >>$LOG_FILE 2>&1 &&
echo_success $SLINE || echo_failure $SLINE

# =============================================================================

# Composer / Project
echo_line "Composer & Project"

if [[ -z $(which composer) ]]; then
    
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

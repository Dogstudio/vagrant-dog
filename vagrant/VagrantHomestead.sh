#!/bin/bash
#
# Vagrant Provisionner for Homestead machine
#
# @author   Akarun for KRKN <akarun@krkn.be> and Passtech <akarun@passtech.be>
# @since    Jan 2015    
#
# =============================================================================

PROJECT_NAME=$( echo $1 | sed -e 's/[A-Z]/\L&/g;s/ /_/g')
PROJECT_HOST=$2
PROJECT_ROOT=$3

LOG_FILE="/vagrant/.vagrant/deploy.log"
DB_ROOT_PASS="secret"
DB_DUMP_FILE="/vagrant/.vagrant/dump.sql"

# =============================================================================

CLL="\r$(printf '%*s\n' 80)\r"
SEP="\r$(printf '%0.1s' "-"{1..80})"

function echo_line    { echo -en "${CLL}$*\n"; }
function echo_success { echo -en "${CLL}$*\033[69G\033[0;39m[   \033[1;32mOK\033[0;39m    ]\n"; }
function echo_failure { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;31mFAILED\033[0;39m  ]\n"; }
function echo_warning { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;33mWARNING\033[0;39m ]\n"; }
function echo_done    { echo -en "${CLL}$*\033[69G\033[0;39m[   \033[1;34mDONE\033[0;39m  ]\n"; }

function process_end {
    echo_line "${SEP}"

    if (( $# > 0 )); then
        echo_failure "ERROR($1) : $2" ; exit 1
        
    else
        echo_line "Current IPs :"
        ifconfig | awk -v RS="\n\n" '{ for (i=1; i<=NF; i++) if ($i == "inet" && $(i+1) ~ /^addr:/) address = substr($(i+1), 6); if (address != "127.0.0.1") printf "\r\040\040\040\040%s --> %s\n", $1, address; }'
        
        echo_success "Deploy completed !"; exit 0
    fi

    echo_line "${SEP}"
    exit 0
}

# =============================================================================

# Clear LOG
echo "" > $LOG_FILE

# Update and package list
echo_line "${SEP}"

apt-get -yq update >>$LOG_FILE 2>&1 && #apt-get -yq upgrade >>$LOG_FILE 2>&1 &&
echo_success "System Updated" || process_end 1 "Unable to update the system"

# Sharing fix
echo "SELINUX=disabled" >> /etc/selinux/config


# =============================================================================

# Tools
echo_line "Shell & Packages"

SLINE="\t- Apg"
test $(which apg) && echo_done || ( apt-get install -y apg >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE )

SLINE="\t- Zip"
test $(which zip) && echo_done || ( apt-get install -y zip unzip >>$LOG_FILE 2>&1 && echo_success $SLINE || echo_failure $SLINE )

# Vagrant commands from VMs
tee -a /root/.vagrant-scripts >>$LOG_FILE <<EOF
#! /bin/bash
function vagrant() {
    case $1 in
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
alias work='supervisor -w bin,static -e js,jade -i files,node_modules,src,static bin/server.js'

# Vagrant commands
source .vagrant-scripts
alias vhalt='vagrant halt'

cd /vagrant
EOF

cp -f /root/.bashrc /home/vagrant/ && chown vagrant: /home/vagrant/.bashrc &&
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
# PROJECT
# -----------------------------------------------------------------------------
echo_line "Projects sources"

# Composer && laravel
/usr/local/bin/composer self-update >>$LOG_FILE 2>&1 &&
echo_success "\t- Composer updated" || echo_failure "\t- Error during Composer update"

if [[ ! -d "$PROJECT_ROOT" ]]; then
    mkdir -p "$PROJECT_ROOT" && cd "$PROJECT_ROOT/.."
    PROJECT_SUBNAME=$(basename $PROJECT_ROOT)

    composer create-project --prefer-dist laravel/laravel $PROJECT_SUBNAME dev-develop >>$LOG_FILE 2>&1 && 
    echo_success "\t- Project created" || echo_failure "\t- Unable to create project in ${PROJECT_ROOT}."

elif [[ -e "${PROJECT_ROOT}/composer.json" ]]; then
    cd "$PROJECT_ROOT/" &&
    
    composer update >>$LOG_FILE 2>&1 &&
    echo_success "\t- Project updated" || echo_failure "\t- Error during project update"

fi


# -----------------------------------------------------------------------------
# MySQL
# -----------------------------------------------------------------------------
echo_line "Prepare MySQL"

# Preparing DB
SLINE="\t- Enable MySQL remote access"
sed -i -e '/bind-address/s/^/# /' /etc/mysql/my.cnf >>$LOG_FILE 2>&1 &&
service mysql restart >>$LOG_FILE 2>&1 &&
echo_success $SLINE || echo_failure $SLINE

SLINE="\t- Create DB and User 'vagrant'"
mysql -u"root" -p"${DB_ROOT_PASS}" >>$LOG_FILE 2>&1 <<EOF
CREATE USER 'vagrant'@'localhost' IDENTIFIED BY 'vagrant';
CREATE USER 'vagrant'@'%' IDENTIFIED BY 'vagrant';
GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'localhost';
GRANT ALL PRIVILEGES ON *.* TO 'vagrant'@'%';
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \${PROJECT_NAME,,}\` CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci';
EOF
echo_success $SLINE

if [ -e "$DB_DUMP_FILE" ]; then
    mysql -u"root" -p"${DB_ROOT_PASS}" "${PROJECT_NAME,,}" < $DB_DUMP_FILE
    echo_done "\t- Populate DB with old dump."
fi


# -----------------------------------------------------------------------------
# NginX
# -----------------------------------------------------------------------------
echo_line "Prepare NginX"

tee -a /etc/nginx/sites-available/${PROJECT_HOST,,} >>$LOG_FILE <<EOF
server {
    listen 80;
    server_name ${PROJECT_HOST,,};
    root "${PROJECT_ROOT}";

    index index.html index.htm index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/error.log error;

    error_page 404 /index.php;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_intercept_errors on;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -fs "/etc/nginx/sites-available/${PROJECT_HOST,,}" "/etc/nginx/sites-enabled/${PROJECT_HOST,,}"
echo_success "\t- NginX configured"

service nginx restart >>$LOG_FILE 2>&1 && 
service php5-fpm restart >>$LOG_FILE 2>&1 &&
echo_success "\t- Nginx restarted" || echo_failure "\t- Error during Nginx restart"



# =============================================================================

# End
process_end

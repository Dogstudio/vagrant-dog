#!/bin/bash
#
# Vagrant Provisionner for Markdown Doc and Directory Index
#
#   Based on : https://github.com/AdamWhitcroft/Apaxy
#
# @author   Akarun for KRKN <akarun@krkn.be> and Passtech <akarun@passtech.be>
# @since    Jul 2015
#
# =============================================================================

LOG_FILE="/vagrant/.vagrant/deploy.log"
PROV_PATH="/vagrant/vagrant/provisioners/markdoc"
PROJECT_NAME=${1:-VagrantDog}

# =============================================================================

CLL="\r$(printf '%*s\n' 80)\r"
SEP="\r$(printf '%0.1s' "-"{1..80})"

function echo_line    { echo -en "${CLL}$*\n"; }
function echo_success { echo -en "${CLL}$*\033[69G\033[0;39m[   \033[1;32mOK\033[0;39m    ]\n"; }
function echo_failure { echo -en "${CLL}$*\033[69G\033[0;39m[ \033[1;31mFAILED\033[0;39m  ]\n"; }

# =============================================================================
echo_line "${SEP}"

pushd /tmp >>$LOG_FILE 2>&1

# -----------------------------------------------------------------------------

echo_line "DirectoryIndex (with Fancydir)"

SLINE="\t- Install Fancydir"
mkdir -p /usr/share/apache2/apaxy/ &&
cp -r $PROV_PATH/fancydir/theme /usr/share/apache2/apaxy/ &&
echo_success $SLINE || echo_failure

SLINE="\t- Configure Fancydir"
sed -e "s/PROJECT_NAME/${PROJECT_NAME}/" -i /usr/share/apache2/apaxy/theme/header.html &&
echo_success $SLINE || echo_failure

SLINE="\t- Update Apache"
mv /etc/apache2/mods-available/autoindex.conf /etc/apache2/mods-available/autoindex.old &&
cp $PROV_PATH/fancydir/autoindex.conf /etc/apache2/mods-available &&
a2enmod autoindex >>$LOG_FILE 2>&1 &&
service apache2 restart >>$LOG_FILE 2>&1 &&
echo_success $SLINE || echo_failure

# -----------------------------------------------------------------------------

echo_line "Markdown Render (with Pandoc)"

if [ -z "$(which pandoc)" ]; then

    SLINE="\t- Install Pandoc"
    wget https://github.com/jgm/pandoc/releases/download/1.15.0.6/pandoc-1.15.0.6-1-amd64.deb >>$LOG_FILE 2>&1 &&
    dpkg -i pandoc-1.15.0.6-1-amd64.deb >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure

fi  


SLINE="\t- Install Apache Pandoc"
cp -r $PROV_PATH/pandoc/etc/* /etc/ &&
cp -r $PROV_PATH/pandoc/usr/* /usr/ &&
chmod a+x /usr/share/apache-pandoc/pandoc.py >>$LOG_FILE 2>&1 &&
sudo a2enconf pandoc >>$LOG_FILE 2>&1 &&
echo_success $SLINE || echo_failure

SLINE="\t- Enable mods"
a2enmod cgi >>$LOG_FILE 2>&1 &&
a2enmod actions >>$LOG_FILE 2>&1 &&
a2enmod cgid >>$LOG_FILE 2>&1 &&
service apache2 restart >>$LOG_FILE 2>&1 &&
echo_success $SLINE || echo_failure

# -----------------------------------------------------------------------------

if [ -d /vagrant/doc ]; then

    SLINE="\t- Add \"doc\" alias for Apache"
    sed -i '/LogLevel/i\
    Alias \/doc \/vagrant\/doc\/\
    <Directory \/vagrant\/doc>\
        Options Indexes\
        AllowOverride All\
        Require all granted\
        Order allow,deny\
        Allow from all\
    <\/Directory>\
    ' /etc/apache2/sites-available/000-default.conf >>$LOG_FILE 2>&1 &&
    service apache2 restart >>$LOG_FILE 2>&1 &&
    echo_success $SLINE || echo_failure
fi

popd >>$LOG_FILE 2>&1

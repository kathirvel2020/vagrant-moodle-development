#!/usr/bin/env bash

MYROOTUSER='root'
MYROOTPASS='mysql'
HOST='dev.local'
DBTYPE='mysqli'
DBHOST='localhost'
DBNAME='moodle'
DBUSER='mdluser'
DBPASS='password'
ADMINUSER="admin"
ADMINPASSWORD="Admin1!"
WWWROOT="https://${HOST}"
MOODLE='/var/www/moodle'
MOODLEDATA='/var/www/moodledata'
GITREPO="git://git.moodle.org/moodle.git"
GITBRANCH=master
TIMEZONE="America\/Toronto"

# Exit on detecting a Moodle config.php
if [ -f ${MOODLE}/config.php ]; then
  echo "Error : Moodle config.php file detected. Exiting..."
  exit 1
fi
echo "No Moodle config.php file, starting installation..."

# =========================================
echo "Installing latest operating system updates..."
# =========================================
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get upgrade -y

# =========================================
echo "Configuring Bash..."
# =========================================
echo "
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
" >>~/.bashrc

cat <<EOF >> ~/.inputrc
## arrow up
"\e[A":history-search-backward
## arrow down
"\e[B":history-search-forward
## home
"\e[1~": beginning-of-line
## end
"\e[4~": end-of-line
## ctrl-right
"\e[1;5C": forward-word
## ctrl-left
"\e[1;5D": backward-word
## escape clear the line (same as CTRL-U) - has side effects
#Escape: unix-line-discard
set show-all-if-ambiguous on 
set completion-ignore-case on
EOF

cat <<EOF >> ~/.bash_aliases
# my custom aliases
alias md='mkdir'
alias rd='rmdir'
alias del='rm'
alias dirs='find -name'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ..;cd ..'
alias ....='cd ..;cd ..;cd ..'
alias edit='nano'
alias apache='sudo /etc/init.d/apache2'
alias tgz='tar -cvzf'
alias untgz='tar -xvzf'
alias dir='ls -l'
EOF

cat <<EOF >> ~/.bash_profile
# set PATH so it includes user's private bin
if [ -d $HOME/bin ] ; then
    mkdir ~/bin
fi
PATH=$HOME/bin:$PATH
EOF

cat <<EOF >> ~/.bashrc
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF

# =========================================
echo "Installing Apache..."
# =========================================
apt-get install -y apache2 > /dev/null 2>&1
echo "--- Enabling mod-rewrite ---"
a2enmod rewrite > /dev/null 2>&1

echo "Installing Apache SSL certificate..."
make-ssl-cert generate-default-snakeoil --force-overwrite
a2enmod ssl
a2ensite default-ssl.conf
sed -i "s/\/var\/www\/html/${MOODLE//\//\\\/}/" /etc/apache2/sites-available/default-ssl.conf

# =========================================
echo "Configuring Apache..."
# =========================================
# Copy custom Apache2 site config over.
cp -f /vagrant/config/000-default.conf /etc/apache2/sites-enabled/

# =========================================
# echo "Installing Let's Encrypt SSL certificate..."
# =========================================
# Ref: https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-ubuntu-14-04
# git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt
# pushd /opt/letsencrypt >/dev/null
# # Temporarily setup a swap file so that the gcc compiler doesn't fail.
# dd if=/dev/zero of=/swapfile bs=1024 count=524288
# chmod 600 /swapfile
# mkswap /swapfile
# swapon /swapfile
# ./letsencrypt-auto --apache -d $HOST
# swapoff /swapfile
# rm /swapfile
# # Setup the certificat renewal script (certs are currently only valid for 90 days).
# cd /usr/local/sbin
# wget http://do.co/le-renew
# chmod +x /usr/local/sbin/le-renew
# popd >/dev/null
# # Add Let's Encrypt to the crontab
# cat <<EOF > /etc/cron.d/letsencrypt
# 30 2 * * 1 /usr/local/sbin/le-renew ${MOODLE} >> /var/log/le-renew.log
# EOF

# cat <<EOF > /etc/apache2/apache2.conf
#     Mutex file:\${APACHE_LOCK_DIR} default
#     PidFile \${APACHE_PID_FILE}
#     User \${APACHE_RUN_USER}
#     Group \${APACHE_RUN_GROUP}
#     Timeout 300
#     KeepAlive On
#     MaxKeepAliveRequests 100
#     KeepAliveTimeout 5
#     HostnameLookups Off
#     AccessFileName .htaccess
#     <FilesMatch "^\.ht">
#         Require all denied
#     </FilesMatch>
#     IncludeOptional mods-enabled/*.load
#     IncludeOptional mods-enabled/*.conf
#     Include ports.conf
#     IncludeOptional conf-enabled/*.conf
# EOF

# =========================================
echo "Installing PHP and any required modules..."
# =========================================
apt-get -y install \
    php5 \
    php5-cli \
    php-pear \
    php5-curl \
    php5-xmlrpc \
    php5-gd \
    php5-intl \
    php-soap \
    php5-json \
    php5-mcrypt \
    php5-dev \
    php5-xdebug \
    php5-xsl \
    > /dev/null 2>&1

# =========================================
echo "Configuring PHP..."
# =========================================
# Not require for Moodle as it handles it in it's developer settings.
# echo -e "\n--- We definitly need to see the PHP errors, turning them on ---\n"
# sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
# sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini

# Ref: https://www.devside.net/wamp-server/apache-and-php-limits-and-timeouts
sed -i "s/register_globals = .*/register_globals = Off/" /etc/php5/apache2/php.ini
sed -i "s/safe_mode = .*/safe_mode = Off/" /etc/php5/apache2/php.ini
sed -i "s/session.save_handler = .*/session.save_handler = files/" /etc/php5/apache2/php.ini
sed -i "s/magic_quotes_gpc = .*/magic_quotes_gpc = Off/" /etc/php5/apache2/php.ini
sed -i "s/magic_quotes_runtime = .*/magic_quotes_runtime = Off/" /etc/php5/apache2/php.ini
sed -i "s/file_uploads = .*/file_uploads = On/" /etc/php5/apache2/php.ini
sed -i "s/session.auto_start = .*/session.auto_start = Off/" /etc/php5/apache2/php.ini
sed -i "s/session.bug_compat_warn = .*/session.bug_compat_warn = Off/" /etc/php5/apache2/php.ini
sed -i "s/memory_limit = .*/memory_limit = 384M/" /etc/php5/apache2/php.ini
sed -i "s/post_max_size = .*/post_max_size = 999M/" /etc/php5/apache2/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 999M/" /etc/php5/apache2/php.ini
sed -i "s/max_execution_time = .*/max_execution_time = 600/" /etc/php5/apache2/php.ini
sed -i "s/max_input_time = .*/max_input_time = 300/" /etc/php5/apache2/php.ini
sed -i "s/date.timezone = .*/date.timezone = ${TIMEZONE}/" /etc/php5/apache2/php.ini

# PHP Debugger
cat <<EOF >> /etc/php5/apache2/php.ini
[xdebug]
zend_extension=/usr/lib/php5/20131226/xdebug.so
xdebug.remote_enable=1
xdebug.remote_handler=dbgp
xdebug.remote_mode=req
xdebug.remote_host=10.0.2.2
xdebug.remote_port=9000
EOF

# # PHP Profiling
# pecl install -f xhprof > /dev/null 2>&1
# cp -f /vagrant/config/xhprof.ini /etc/php5/mods-available/
# php5enmod xhprof > /dev/null 2>&1
# apt-get -y install graphviz > /dev/null 2>&1
# # TODO need to set /usr/bin/dot in config.php

# =========================================
echo "Restarting Apache..."
# =========================================
service apache2 restart

# =========================================
echo "Installing MySQL..."
# =========================================
#echo "mysql-server-5.5 mysql-server/root_password password $MYROOTPASS" | debconf-set-selections
#echo "mysql-server-5.5 mysql-server/root_password_again password $MYROOTPASS" | debconf-set-selections
echo "mysql-server mysql-server/root_password password $MYROOTPASS" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYROOTPASS" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $MYROOTPASS" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $MYROOTPASS" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $MYROOTPASS" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections
apt-get -y install \
    mysql-server-5.5 \
    php5-mysql \
    phpmyadmin \
    > /dev/null 2>&1

# =========================================
echo "Configuring MySQL..."
# =========================================
# Rename MySQL root user to keep simple.
mysql -u $MYROOTUSER -p$MYROOTPASS -e "
    UPDATE mysql.user set user = '${MYROOTUSER}' where user = 'root'
    FLUSH PRIVILEGES"

# =========================================
echo  "Installing phpMyAdmin..."
# =========================================
apt-get install phpmyadmin

# =========================================
echo "Installing Boris..."
# =========================================
echo "--- Turn off disabled pcntl functions so we can use Boris ---"
# Ref: http://www.sitepoint.com/say-hello-to-boris-a-better-repl-for-php/
sed -i "s/disable_functions = .*//" /etc/php5/cli/php.ini
sudo -u vagrant git clone git://github.com/d11wtq/boris.git /bin/boris
echo 'export PATH="$PATH:/bin/boris/bin"' >> ~/.bashrc

# =========================================
echo "Restarting Apache..."
# =========================================
service apache2 reload > /dev/null 2>&1

# =========================================
echo "Installing Git..."
# =========================================
# Install Git.
apt-get install -y git > /dev/null 2>&1
# Tell Git who you are
echo -n "Enter your Git full name: "; read -e INFO
git config --global user.name "${INFO}"
echo -n "Enter your Git email address: "; read -e INFO
git config --global user.email "${INFO}"
# Select your favorite text editor
git config --global core.editor nano
# Set Git aliases
git config --global alias.unpush "log @{u}.."
# Install SSH key for github.com
ssh-keyscan -Ht rsa github.com >> ~/.ssh/known_hosts

# =========================================
echo "Installing Mercurial SVN..."
# =========================================
apt-get install -y hgsvn > /dev/null 2>&1

# =========================================
echo "Installing Unzip..."
# =========================================
apt-get install -y unzip > /dev/null 2>&1

# Get Moodle core source.
if [ -f /vagrant/config/git.repo ]; then
    GITREPO=$(</vagrant/config/git.repo)
    if [ -f /vagrant/config/git.branch ]; then
        GITBRANCH=$(</vagrant/config/git.branch)
    fi
fi

# =========================================
echo "Installing Moodle..."
# =========================================
if [ $GITBRANCH == 'master' ]; then
    echo "Retrieving Moodle Master version..."
    git clone $GITREPO ${MOODLE}
else
    echo "Retrieving Moodle version ${GITBRANCH}..."
    git clone $GITREPO --branch $GITBRANCH ${MOODLE}
fi
git remote add upstream git://git.moodle.org/moodle.git
ln -s /vagrant/moodle ~/moodle

# =========================================
echo "Installing Moodle plugins..."
# =========================================
# Get code checker.
sudo -u vagrant git clone https://github.com/moodlehq/moodle-local_codechecker.git ${MOODLE}/local/codechecker

# Get Language Tag tool for Atto.
sudo -u vagrant git clone https://github.com/julenpardo/moodle-atto_multilang2.git ${MOODLE}/lib/editor/atto/plugins/multilang2
# Get Language Filter.
sudo -u vagrant git clone https://github.com/iarenaza/moodle-filter_multilang2.git ${MOODLE}/filter/multilang2
#git clone git@github.com:vanyog/moodle-filter_multilangsecond.git ${MOODLE}/filter/multilangsecond

# Get themes.
sudo -u vagrant git clone https://bitbucket.org/covuni/moodle-theme_adaptable.git ${MOODLE}/theme/adaptable
sudo -u vagrant git clone https://github.com/gjb2048/moodle-theme_essential.git ${MOODLE}/theme/essential
sudo -u vagrant git clone https://github.com/kennibc/moodle-theme_evolved.git ${MOODLE}/theme/evolved
sudo -u vagrant git clone https://github.com/kennibc/moodle-theme_pioneer.git ${MOODLE}/theme/pioneer
sudo -u vagrant git clone https://github.com/superawesomeme/moodle-theme_aardvark.git ${MOODLE}/theme/aardvark
sudo -u vagrant git clone https://github.com/dualcube/moodle-theme_crisp.git ${MOODLE}/theme/crisp
sudo -u vagrant git clone https://github.com/vidyamantra/moodle-theme_eduhub.git ${MOODLE}/theme/eduhub

sudo -u vagrant git clone https://github.com/moodlerooms/moodle-theme_snap.git ${MOODLE}/theme/snap
sudo -u vagrant hg clone https://bitbucket.org/nephzatofficial/moodle-theme_academi ${MOODLE}/theme/academi
sudo -u vagrant hg clone https://bitbucket.org/nephzatofficial/moodle-theme_eguru ${MOODLE}/theme/eguru
sudo -u vagrant hg clone https://bitbucket.org/nephzatofficial/moodle-theme_klass ${MOODLE}/theme/klass

sudo -u vagrant git clone https://github.com/bmbrands/theme_bootstrap.git ${MOODLE}/theme/bootstrap
sudo -u vagrant git clone https://github.com/roelmann/moodle-theme_flexibase.git ${MOODLE}/theme/flexibase
sudo -u vagrant git clone https://github.com/bmbrands/moodle-theme_elegance.git ${MOODLE}/theme/elegance

# =========================================
echo "Installing moodledata..."
# =========================================
# Make Moodle dataroot.
if [ ! -d "${MOODLEDATA}" ]; then
  mkdir -p ${MOODLEDATA}
  chmod -R 777 ${MOODLEDATA}
  # Install French Language Pack - ref: https://download.moodle.org/langpack/3.0/
  mkdir ${MOODLEDATA}/lang
  cd mkdir ${MOODLEDATA}/lang
  wget https://download.moodle.org/download.php/direct/langpack/3.0/fr.zip
  unzip fr.zip fr/
  rm fr.zip
  wget https://download.moodle.org/download.php/direct/langpack/3.0/fr_ca.zip
  unzip fr_ca.zip fr_ca/
  rm fr_ca.zip
  ln -s /vagrant/moodledata ~/moodledata
fi

# =========================================
echo "Installing Moodle database..."
# =========================================
# Check if Moodle database exists.
if [ mysql -u $MYROOTUSER -p$MYROOTPASS -e "USE ${DBNAME}" > /dev/null 2>&1 ]; then
    echo "Error : Detected existing Moodle database, exiting."
    exit 1
else
    echo "Moodle database not found. Creating database..."
    #mysql -u $MYROOTUSER -p$MYROOTPASS -e echo "DROP DATABASE IF EXISTS ${DBNAME}"
    mysql -u $MYROOTUSER -p$MYROOTPASS -e "
        SET SESSION sql_mode=STRICT_ALL_TABLES;
        SET GLOBAL innodb_file_format = barracuda;
        SET GLOBAL innodb_file_format_max = barracuda;
        SET GLOBAL innodb_file_per_table=1;
        CREATE DATABASE moodle DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
        GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON ${DBNAME}.* TO ${DBUSER}@localhost IDENTIFIED BY '${DBPASS}';
        FLUSH PRIVILEGES;"
    pushd ${MOODLE} >/dev/null
    php admin/cli/mysql_compressed_rows.php --list
    popd >/dev/null
    echo "Moodle database created."
fi
echo "Restarting Apache..."
service apache2 reload > /dev/null 2>&1

# =========================================
echo "Configuring Moodle database..."
# =========================================
php ${MOODLE}/admin/cli/install.php --lang=en \
  --lang="en" \
  --non-interactive \
  --agree-license \
  --allow-unstable \
  --wwwroot=${WWWROOT} \
  --dataroot=${MOODLEDATA} \
  --dbtype=${DBTYPE} \
  --dbhost=${DBHOST} \
  --dbname=${DBNAME} \
  --dbuser=${DBUSER} \
  --dbpass=${DBPASS} \
  --prefix=mdl_ \
  --fullname="Site fullname - CHANGEME" \
  --shortname="Site shortname - CHANGEME" \
  --summary="Site summary - CHANGEME" \
  --adminuser="${ADMINUSER}" \
  --adminpass="${ADMINPASSWORD}" \
  --adminemail="moodle@localhost.invalid"
chown www-data:g-data -R /var/www/moodle

# =========================================
echo "Adding Moodle to the crontab..."
# =========================================
cat <<EOF > /etc/cron.d/moodle
* * * * * www-data /usr/bin/env php ${MOODLE}/admin/cli/cron.php
EOF

echo "
You will need to add a hosts file entry for:

    192.168.33.33  ${HOST}

To login to Moodle, go to:

    ${WWWROOT} (User: ${ADMINUSER}, Password: ${ADMINPASSWORD})

To login phpMyAdmin, go to:

    ${WWWROOT}/phpmyadmin (User: ${MYROOTUSER}, Password: ${MYROOTPASS})

You can connect to the server using:

    vagrant ssh

...or by using a terminal to:

    ${HOST} on port 22; or localhost on port 2222

This VitualBox: dev
"

# =========================================
echo "Cleaning up..."
# =========================================
apt-get autoclean && apt-get clean

exit 0

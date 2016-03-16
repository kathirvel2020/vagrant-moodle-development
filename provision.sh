#!/usr/bin/env bash

WEBSERVER='apache'  # 'apache' OR 'nginx' (not implemented yet)
MYROOTUSER='root'
MYROOTPASS='dbpass'
HOST='dev.local'
DBTYPE='mysqli'  # 'mysqli' OR 'pgsql' (untested)
DBHOST='localhost'
DBNAME='moodle'
DBUSER='mdluser'
DBPASS='mdlpass'
ADMINUSER="admin"
ADMINPASSWORD="Admin1!"
WWWROOT="https://${HOST}"
MOODLE='/var/www/moodle'
MOODLEDATA='/var/www/moodledata'
GITREPO="git://git.moodle.org/moodle.git" # Override in config/moodle-repo.git.
GITBRANCH=master                          # Override in config/moodle-branch.git.
TIMEZONE="America\/Toronto"
# Define colours
: ${BOLD='\033[1;33m'}
: ${RED='\033[1;31m'}
: ${NC='\033[0m'} # No Color

# Exit on detecting a Moodle config.php
if [ -f ${MOODLE}/config.php ]; then
  echo "${RED}Error : Moodle config.php file detected. Exiting...${NC}"
  exit 1
fi
echo "No Moodle config.php file, starting installation..."

# =========================================
echo "${BOLD}Installing latest operating system updates...${NC}"
# =========================================
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get upgrade -y

# =========================================
echo "${BOLD}Configuring Bash...${NC}"
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

if [ "$WEBSERVER" == "nginx" ]; then
    echo "${RED}Nginx has not been implemented yet. Using Apache instead...${NC}"
    WEBSERVER="apache"
fi

if [ "$WEBSERVER" == "apache" ]; then
    # =========================================
    echo "${BOLD}Installing Apache...${NC}"
    # =========================================
    apt-get install -y apache2 libapache2-mod-php5 > /dev/null 2>&1
    echo "--- Enabling mod-rewrite ---"
    a2enmod rewrite > /dev/null 2>&1

    echo "Installing Apache SSL certificate..."
    make-ssl-cert generate-default-snakeoil --force-overwrite
    a2enmod ssl
    a2ensite default-ssl.conf
    sed -i "s/\/var\/www\/html/${MOODLE//\//\\\/}/" /etc/apache2/sites-available/default-ssl.conf

    # =========================================
    echo "${BOLD}Configuring Apache...${NC}"
    # =========================================
    # Copy custom Apache2 site config over.
    cp -f /vagrant/config/000-default.conf /etc/apache2/sites-enabled/
    
    alias restartweb='service apache2 restart'
fi

if [ "$WEBSERVER" == "nginx" ]; then
    echo "Nginx has not been implemented yet. Using Apache instead..."    
fi

# =========================================
echo "${BOLD}Installing PHP and any required modules...${NC}"
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
    libapache2-mod-php5 \
    > /dev/null 2>&1

# =========================================
echo "${BOLD}Configuring PHP...${NC}"
# =========================================

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

# =========================================
echo "${BOLD}Restarting $WEBSERVER...${NC}"
# =========================================
restartweb

if [ "$DBTYPE" == "mysqli" ]; then # MySQL
    # =========================================
    echo "${BOLD}Installing MySQL...${NC}"
    # =========================================
    echo "mysql-server mysql-server/root_password password $MYROOTPASS" | debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $MYROOTPASS" | debconf-set-selections
    # Some settings for phpMyAdmin
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
    echo "${BOLD}Configuring MySQL...${NC}"
    # =========================================
    # Rename MySQL root user to keep simple.
    mysql -u $MYROOTUSER -p$MYROOTPASS -e "
        UPDATE mysql.user set user = '${MYROOTUSER}' where user = 'root';
        FLUSH PRIVILEGES;"
    # =========================================
    echo  "${BOLD}Installing phpMyAdmin...${NC}"
    # =========================================
    apt-get install phpmyadmin
fi

if [ "$DBTYPE" == "pgsql" ]; then # Postgres
    # =========================================
    echo "${BOLD}Installing Postgres...${NC}"
    # =========================================
    echo "Include /etc/apache2/conf.d/phppgadmin" >> /etc/apache2/apache2.conf
    apt-get -y install \
        postgresql \
        postgresql-client \
        postgresql-contrib \
        php5-pgsql \
        > /dev/null 2>&1
    # =========================================
    echo "${BOLD}Configuring Postgres...${NC}"
    # =========================================
    PGHBAFILE=$(find /etc/postgresql -name pg_hba.conf | head -n 1)
    cat <<EOF > "${PGHBAFILE}"
local   all             postgres                                peer
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     peer
host    ${DBNAME}    ${DBUSER}        127.0.0.1/32            trust
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
EOF
    service postgresql restart
    sudo -u postgres createuser -SRDU postgres ${DBUSER}
    sudo -u postgres createdb -E UTF-8 -O ${DBUSER} -U ${DBUSER} ${DBNAME}

    # =========================================
    echo  "${BOLD}Installing phpPgAdmin...${NC}"
    # =========================================
    apt-get install phppgadmin
fi

# =========================================
echo "${BOLD}Installing Git...${NC}"
# =========================================
# Install Git.
apt-get install -y git > /dev/null 2>&1
# Tell Git who you are
if [ $# -eq 2 ]; then
    git config --global user.name "$1"
    git config --global user.email "$2"
fi
# Select your favorite text editor
git config --global core.editor nano
# Set Git aliases
git config --global alias.unpush "log @{u}.."
# Install SSH key for github.com
ssh-keyscan -Ht rsa github.com >> ~/.ssh/known_hosts

# =========================================
echo "${BOLD}Installing Mercurial SVN...${NC}"
# =========================================
apt-get install -y hgsvn > /dev/null 2>&1

# =========================================
echo "${BOLD}Installing Unzip...${NC}"
# =========================================
apt-get install -y unzip > /dev/null 2>&1

# =========================================
echo "${BOLD}Cleaning up...${NC}"
# =========================================
apt-get autoclean && apt-get clean

# Get Moodle core source.
if [ -f /vagrant/config/moodle-repo.git ]; then
    GITREPO=$(</vagrant/config/moodle-repo.git)
    if [ -f /vagrant/config/moodle-branch.git ]; then
        GITBRANCH=$(</vagrant/config/moodle-branch.git)
    fi
fi

# =========================================
echo "${BOLD}Installing Boris...${NC}"
# =========================================
echo "--- Turn off disabled pcntl functions so we can use Boris ---"
# Ref: http://www.sitepoint.com/say-hello-to-boris-a-better-repl-for-php/
sed -i "s/disable_functions = .*//" /etc/php5/cli/php.ini
sudo -u vagrant git clone git://github.com/d11wtq/boris.git /bin/boris
echo 'export PATH="$PATH:/bin/boris/bin"' >> ~/.bashrc

# =========================================
echo "${BOLD}Restarting $WEBSERVER...${NC}"
# =========================================
restartweb

# =========================================
echo "${BOLD}Installing Moodle...${NC}"
# =========================================
if [ $GITBRANCH == 'master' ]; then
    echo "${BOLD}Retrieving Moodle Master version...${NC}"
    git clone $GITREPO ${MOODLE}
else
    echo "${BOLD}Retrieving Moodle version ${GITBRANCH}...${NC}"
    git clone $GITREPO --branch $GITBRANCH ${MOODLE}
fi
ln -s ${MOODLE} ~/moodle

# =========================================
echo "${BOLD}Installing Moodle plugins...${NC}"
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
echo "${BOLD}Installing moodledata...${NC}"
# =========================================
# Make Moodle dataroot.
if [ ! -d "${MOODLEDATA}" ]; then
  mkdir -p ${MOODLEDATA}
  chmod -R 777 ${MOODLEDATA}
  # Install French Language Pack - ref: https://download.moodle.org/langpack/3.0/
  mkdir ${MOODLEDATA}/lang
  pushd ${MOODLEDATA}/lang >/dev/null
  wget https://download.moodle.org/download.php/direct/langpack/3.0/fr.zip
  unzip fr.zip fr/
  rm fr.zip
  wget https://download.moodle.org/download.php/direct/langpack/3.0/
  unzip fr_ca.zip fr_ca/
  rm fr_ca.zip
  popd >/dev/null
  ln -s ${MOODLEDATA} ~/moodledata
fi

# =========================================
echo "${BOLD}Installing Moodle database...${NC}"
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
    echo "Moodle database created."
fi
echo "Restarting Apache..."
service apache2 reload > /dev/null 2>&1

# =========================================
echo "${BOLD}Configuring Moodle database...${NC}"
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
chown www-data:www-data -R /var/www/moodle

# =========================================
echo "${BOLD}Adding Moodle to the crontab...${NC}"
# =========================================
cat <<EOF > /etc/cron.d/moodle
* * * * * www-data /usr/bin/env php ${MOODLE}/admin/cli/cron.php
EOF

echo "${BOLD}
You will need to add a hosts file entry for:

    192.168.33.33  ${HOST}

To login to Moodle, go to:

    ${WWWROOT} (User: ${ADMINUSER}, Password: ${ADMINPASSWORD})

"
if [ "$DBTYPE" == "pgsql" ]; then
    echo "To login phpPgAdmin, go to:

    ${WWWROOT}/phppgadmin (User: ${MYROOTUSER}, Password: ${MYROOTPASS})"
else
    echo "To login phpMyAdmin, go to:

    ${WWWROOT}/phpmyadmin (User: ${MYROOTUSER}, Password: ${MYROOTPASS})"
fi

echo "

You can connect to the server using:

    vagrant ssh

...or by using a terminal to:

    ${HOST} on port 22; or localhost on port 2222

Name of this VitualBox: dev
${NC}"

exit 0

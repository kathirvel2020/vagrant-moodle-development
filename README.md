# Vagrant Moodle Development

## Copyright

Copyright © 2016 TNG Consulting Inc. - http://www.tngconsulting.ca/

Vagrant Moodle Development is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Vagrant Moodle Developement is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Vagrant Moodle Development.  If not, see <http://www.gnu.org/licenses/>.

## Authors

Michael Milette - Lead Developer

## Description

This repository provides a Vagrant based system to create a Moodle LAMP instance running a Ubuntu Trusty64 virtual machine using the VirtualBox. This is perfect for local testing and development installations.

After setup is complete you will have a Moodle LAMP instance running in a virtual machine on your local development computer.

The resulting package will include:

* LAMP (Ubuntu 14.04 LTS 64-bit Linux, Apache, MySQL, PHP)
* Moodle (latest version)
* Moodle add-ons/plugins including:
  * Local: Code Checker
  * Filter: multilang2
  * Atto: multilang2
  * Theme: Adaptable
  * Theme: Bootstrap
  * Language Pack: French
  * Language Pack: French Canadian
* Moodle MDK
* Moodle Moosh
* Boris
* Mercurial SVN
* Git
* phpMyAdmin
* Self-signed SSL certificate
* Unzip
* XDEBUG

This has been tested using Vagrant 1.8.1.

Status: ALPHA

## Requirements

Before you begin, make sure that you have installed the following applications on your local development computer:

* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/downloads.html)
* [Git](https://git-scm.com/downloads)

## Changes

2016-03-15 - Initial version. See the CHANGELOG.md for additional information.

## Installation and Configuration

Clone this project

    git clone git@github.com:michael-milette/vagrant-moodle-development.git mymoodle
    cd mymoodle

Add the following line to the *hosts* file on your local development machine:
...on Windows - c:\windows\system32\drivers\etc\hosts
...on Ubuntu  - /etc/hosts
...on OS X    - /private/etc/hosts

    dev.local 192.168.33.33

If you want to use a different IP address, you will need to modify it in *Vagrantfile*.

You may also want to customize the fillowing files:

* *config\moodle-repo.git* - This file contains the URL to the Moodle Git repository (you can point it to your own fork).
* *config\moodle-branch.git* - This file contains the version of Moodle that you want to install. Example: MOODLE_30_STABLE.

## Security considerations

The vagrant environment created is only suitable for local development and testing and should not be used for a publicly accessible websites without additional security hardening.

## Usage
    
The following commands can be executed from within the mymoodle directory:

* vagrant up - starts the virtual machine. If running for the first time, will install everything required for Moodle development.
* vagrant ssh - connects you to the virtual machine in a terminal.
* vagrant suspend - hybernates the virtual machine in its current state.
* vagrant halt - shutdown the virtual machine gracefully.
* vagrant destroy - Deletes the virtual machine.
* vagrant help - Displays a complete list of vagrant commands.

## Default Credentials

phpMyAdmin or phpPgAdmin:

    url: https://dev.local/phpmyadmin (if using mysql)
    url: https://dev.local/phppgadmin (if using postgres)
    username: root
    password: dbpass

Moodle database:

    database: moodle
    username: mdluser
    password: mdlpass

Moodle administrator login:

    username: admin
    password: Admin1!

SSH (if using PuTTY or SCP):

    username: vagrant
    password: vagrant

Local Files:

    Moodle site root: moodle  (/vagrant/moodle or ~/moodle)
    Moodle data: moodledata   (/vagrant/moodledata or ~/moodledata)

Moodle will be available at https://dev.local/

## TIP: Avoiding self-signed SSL certificate warnings

To avoid the warning displayed by your web browser, go to the website at https://dev.local and:

### Chrome
1. Click on Advanced, then Proceed to dev.local (unsafe) to bypass SSL warning in Chrome.
1. Click the Lock (next to URL address) > Certificate Information
1. Click Details tab > Export
1. Enter *dev.local.cer* and save it on the desktop.
1. Click Chrome Settings > Show advanced settings > HTTPS/SSL > Manage Certificates > Trusted Root Certification Authorities tab.
1. Select the certificate.
1. Click the *Import* button.
1. Click Next.
1. Click Browse and select the *dev.local.cer* file on your desktop and click Open.
1. Click the *Next* button.
1. Select *Place all certificates in the following store*
1. Click Browse and select *Trusted Root Certification Authorities*
1. Click Next
1. Click the *Finish* button followed by Yes, OK and Close.
1. Close the *Settings* tab
1. Close and restart Chrome.

### Firefox
1. Click on *I Understand the Risks*, then click on *Add Exception....*
1. Click on *Add Exception*.
1. Click *Confirm Security Exception*.
1. Close and restart Firefox.

### Internet Explorer
1. Click on *Continue to this website (not recommended)* to bypass SSL warning in Internet Explorer.
1. Click *View certificates*.
1. Click the *Certification Path* tab.
1. Select the root certificate and click *View Certificate*.
1. Click *Install Certificate*
1. Click *Next*
1. Select *Place all certificates in the following store*, click *Browse*, select *Trusted Root Certificate Authorities*, click *OK* and click *Next*.
1. Click *Finish*.
1. Click *Yes*.
1. Click *OK* twice.
1. Close and restart Internet Explorer.

## Uninstallation

There are 3 quick steps required to completely uninstall Vagrant Moodle Development:

1. In the mymoodle directory, enter the following command:
   *vagrant destroy*
2. Delete the mymoodle directory.
3. Remove the *dev.local 192.168.33.33* line from your *hosts* file.

## Motivation

The development of this script was motivated by the author's own web development efforts and is supported by TNG Consulting Inc.

## Further information

For more information regarding this vagrant script, for support or to report a bug, visit the project page at:

    http://github.com/michael-milette/vagrant-moodle-development

## Right-to-left support

This has not been tested with for support in right-to-left (RTL) languages.

If you want to use this script with a RTL language and it doesn't work as-is,
feel free to prepare a pull request and submit it to the project page at:

    http://github.com/michael-milette/vagrant-moodle-development

## Future

Some ideas we are toying with for the future include adding the ability to do the following during installation:

* Optionally also create WordPress and Drupal environments.
* Use a MariaDB or PostgresSQL database instead of MySQL.
* Use Nginx instead of Apache.
* Cache the installation files for Moodle, WordPress and Drupal to reduce download time.
* Performance optimization.

## Reference

* [How to install Moodle via Git with Postgres, Nginx, PHP on Ubuntu](https://www.digitalocean.com/community/tutorials/how-to-install-moodle-via-git-with-postgres-nginx-and-php-on-an-ubuntu-12-04-vps)
* [How to install Moodle on Ubuntu using Nginx](http://www.techoism.com/how-to-install-moodle-on-ubuntu-using-nginx/)
* [Apache and PHP limits and timeouts](https://www.devside.net/wamp-server/apache-and-php-limits-and-timeouts)
* https://github.com/digitalsparky/moodle-vagrant

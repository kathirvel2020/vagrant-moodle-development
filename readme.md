# Vagrant Moodle Development

This repository provides a template Vagrantfile to create a Moodle LAMP instance running a Ubuntu Trusty64 virtual machine
using the VirtualBox. This is perfect for local testing and development installations.

After setup is complete you will have a Moodle LAMP instance running on your local machine.

Status: ALPHA

## Software Requirements

Make sure your development machine has:
* VirtualBox( https://www.virtualbox.org/wiki/Downloads )
* Vagrant ( https://www.vagrantup.com/downloads.html )
* Git ( https://git-scm.com/downloads )

## Installation

Clone and startup this project

    git clone git@github.com:michael-milette/vagrant-moodle-development.git mymoodle
    cd mymoodle
    vagrant up

You will need to add the following line to your host file:
...on Windows - c:\windows\system32\drivers\etc\hosts
...on Ubuntu  - /etc/hosts
...on OS X    - /private/etc/hosts

    dev.local 192.168.33.33

The resulting package will include:

* LAMP (Ubuntu 14.04 LTS 64-bit Linux, Apache, MySQL, PHP)
* Moodle (latest version)
* Moodle add-ons including:
** Local: Code Checker
** Filter: multilang2
** Atto: multilang2
** Theme: Adaptable
** Theme: Bootstrap
** Language Pack: French
** Language Pack: French Canadian
* Boris
* Mercurial SVN
* Git
* phpMyAdmin
* Self-signed SSL certificate
* Unzip
* XDEBUG

This has been tested using Vagrant 1.8.1.

## Basic Vagrant Commands

The following commands can be executed from within the mymoodle directory:

* vagrant up - starts the virtual machine. If running for the first time, will install everything required for Moodle development.
* vagrant ssh - connects you to the virtual machine in a terminal.
* vagrant suspend - hybernates the virtual machine in its current state.
* vagrant halt - shutdown the virtual machine gracefully.
* vagrant destroy - Deletes the virtual machine.

## Default Credentials

phpMyAdmin:

    url: https://dev.local/phpmyadmin
    username: root
    password: mysql

Moodle database:

    database: moodle
    username: mdluser
    password: password

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

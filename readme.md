# Vagrant Moodle Development

This repository provides a template Vagrantfile to create a Moodle LAMP instance running a Ubuntu Trusty64 virtual machine
using the VirtualBox. This is perfect for local testing and development installations.

After setup is complete you will have a Moodle LAMP instance running on your local machine.

## Software Requirements

Make sure your development machine has:
* VirtualBox( https://www.virtualbox.org/wiki/Downloads )
* Vagrant ( https://www.vagrantup.com/downloads.html )
* Git ( https://git-scm.com/downloads )

## Installation

Clone this project

    git clone git@github.com:michael-milette/vagrant-moodle-development.git mymoodle
    cd mymoodle
    vagrant up

You will need to add the following line to your host file (on Windows - c:\windows\system32\drivers\etc\hosts):

    dev.local 192.168.33.10


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

# Default Credentials

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

Local Files

    Moodle site root: moodle
    Moodle data: moodledata

Moodle will be available at http://dev.local/

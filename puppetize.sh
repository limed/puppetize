#!/bin/bash
# Copyright (c) 2012 Oregon State University - Network Engineering
# All rights reserved.
#
# Puppetize a debian server.

PUPPET_SERVER=$1
APTITUDE="aptitude -q -y"
CODENAME=$(lsb_release -c | awk '{print $2}')

export http_proxy="http://proxy.oregonstate.edu:3128"
export DEBIAN_FRONTEND="noninteractive"

if [ -z ${PUPPET_SERVER} ]; then
    echo "Usage: $0 [puppetmaster]"
    exit
fi

echo " === Installing required packages === "
dpkg -l ntpdate > /dev/null 2>&1 && ${APTITUDE} install ntpdate
dpkg -l lsb-release > /dev/null 2>&1 && ${APTITUDE} install lsb-release

echo " === Importing puppetlabs repo === "
test -f /etc/apt/sources.list.d/puppetlabs.list || echo "deb http://apt.puppetlabs.com/debian $CODENAME main" > /etc/apt/sources.list.d/puppetlabs.list

echo " === Syncing time ==="
ntpdate time.oregonstate.edu

echo " === Deleting unwanteds ==="
dpkg -l cfengine2 > /dev/null 2>&1 && ${APTITUDE} remove cfengine2
${APTITUDE} remove lpr nfs-common exim4 > /dev/null
rm -f /etc/apt/sources.list.d/*.backport.list

echo " === Installing puppet === "
wget -q -O - http://apt.puppetlabs.com/keyring.gpg | apt-key add -
${APTITUDE} update
${APTITUDE} install puppet facter

FQDN=`facter fqdn`

cat > /etc/puppet/puppet.conf << PUPPETCONF
[main]
    server      = ${PUPPET_SERVER}
    vardir      = /var/lib/puppet
    logdir      = /var/log/puppet
    rundir      = /var/run/puppet
    ssldir      = $vardir/ssl

[agent]
    certname    = ${FQDN}
    report      = true
    pluginsync  = true
PUPPETCONF

sed -i 's/START=no/START=yes/g' /etc/default/puppet

echo " === Starting puppet agent === "
/etc/init.d/puppet start

echo " === Clean up === "
aptitude search ~c | awk '{print $2}' | xargs dpkg --purge

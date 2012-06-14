#!/bin/bash
# Copyright (c) 2012 Oregon State University - Network Engineering
# All rights reserved.
#
# Puppetize an enterprise linux server.

export http_proxy='http://proxy.oregonstate.edu:3128'

yum clean all
yum install -y ntp ntpdate redhat-lsb openssh-clients

PUPPET_REPO="http://yum.puppetlabs.com"
ARCH=`uname -i`
RELEASE=`lsb_release -r | awk '{print $2}'`
PUPPET_SERVER=$1

if [ -z ${PUPPET_SERVER} ]; then
    echo "Usage: $0 [puppetmaster]"
    exit
fi

if [ $(echo "${RELEASE} >= 6" | bc ) -eq 1 ]; then
    rpm -ivh "http://yum.puppetlabs.com/el/6/products/${ARCH}/puppetlabs-release-6-1.noarch.rpm"
else
    rpm -ivh "http://yum.puppetlabs.com/el/5/products/${ARCH}/puppetlabs-release-5-1.noarch.rpm"
fi

# Adjust time
ntprunning=`ps -ax | grep ntpd | grep -v grep`
[ -n $ntprunning ] && /sbin/service ntpd stop
ntpdate time.oregonstate.edu
[ -n $ntprunning ] && /sbin/service ntpd start

yum install -y facter puppet

FQDN=`facter fqdn`

cat > /etc/puppet/puppet.conf << PUPPETCONF
[main]
    server      = ${PUPPET_SERVER}
    vardir      = /var/lib/puppet
    logdir      = /var/log/puppet
    rundir      = /var/run/puppet
    ssldir      = /var/lib/puppet/ssl

[agent]
    certname    = ${FQDN}
    report      = true
    pluginsync  = true
PUPPETCONF


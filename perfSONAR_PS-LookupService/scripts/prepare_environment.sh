#!/bin/bash

MAKEROOT=""
if [[ $EUID -ne 0 ]];
then
    MAKEROOT="sudo "
fi

echo "Adding 'perfsonar' user and group..."
$MAKEROOT /usr/sbin/groupadd perfsonar 2> /dev/null || :
$MAKEROOT /usr/sbin/useradd -g perfsonar -s /sbin/nologin -c "perfSONAR User" -d /tmp perfsonar 2> /dev/null || :

echo "Creating '/var/log/perfsonar'..."
$MAKEROOT mkdir -p /var/log/perfsonar
$MAKEROOT chown perfsonar:perfsonar /var/log/perfsonar

echo "Creating '/var/lib/perfsonar/lookup_service'..."
$MAKEROOT mkdir -p /var/lib/perfsonar/lookup_service/xmldb
if [ ! -f /var/lib/perfsonar/lookup_service/xmldb/DB_CONFIG ];
then
    echo "Creating '/var/lib/perfsonar/lookup_service/xmldb/DB_CONFIG'..."
    $MAKEROOT `dirname $0`/../scripts/psCreateLookupDB --directory /var/lib/perfsonar/lookup_service/xmldb
fi

echo "Setting permissions in '/var/lib/perfsonar/lookup_service'..."
$MAKEROOT chown -R perfsonar:perfsonar /var/lib/perfsonar/lookup_service

echo "Linking init script..."
$MAKEROOT ln -s /opt/perfsonar_ps/lookup_service/scripts/lookup_service /etc/init.d/lookup_service

echo "Running chkconfig..."
$MAKEROOT /sbin/chkconfig --add lookup_service

echo "Starting Lookup Service..."
$MAKEROOT /etc/init.d/lookup_service start

echo "Removing temporary files..."
$MAKEROOT rm -f /opt/perfsonar_ps/lookup_service/dependencies
$MAKEROOT rm -f /opt/perfsonar_ps/lookup_service/scripts/install_dependencies.sh
$MAKEROOT rm -f /opt/perfsonar_ps/lookup_service/scripts/prepare_environment.sh

echo "Exiting prepare_environment.sh"

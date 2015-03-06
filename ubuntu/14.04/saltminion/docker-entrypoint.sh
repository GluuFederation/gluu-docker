#!/bin/bash

echo $SALT_MASTER_IPADDR || echo No SALT_MASTER_IPADDR
sudo sed -i /etc/salt/minion-stub -e s/REPLACE_ME/$SALT_MASTER_IPADDR/ || exit 0
cat /etc/salt/minion-stub || exit 0

/usr/bin/salt-minion

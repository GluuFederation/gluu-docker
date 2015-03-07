#!/bin/bash

sed -i /etc/salt/minion-stub -e s/REPLACE_ME/$SALT_MASTER_IPADDR/ || exit 0
cat /etc/salt/minion-stub || exit 0
echo $SALT_MASTER_IPADDR && cp /etc/salt/minion-stub /etc/salt/minion

/usr/bin/salt-minion

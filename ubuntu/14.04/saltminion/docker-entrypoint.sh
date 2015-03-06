#!/bin/bash

echo $SALT_MASTER_IP
sudo sed -i /etc/salt/minion-stub -e s/REPLACE_ME/$SALT_MASTER_IP/ || exit 0

/usr/bin/salt-minion

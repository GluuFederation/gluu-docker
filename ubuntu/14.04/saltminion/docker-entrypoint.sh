#!/bin/sh

# Keeping it low-key for now, shouldn't affect current setup.
echo $SALT_MASTER_IP || echo SALT_MASTER_IP isn't set
sudo sed -i /etc/salt/minion-stub -e "s/REPLACE_ME/$SALT_MASTER_IP/" || exit 0

/usr/bin/salt-minion

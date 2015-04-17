#!/bin/bash

sed -i /etc/salt/minion -e s/SALT_MASTER_IPADDR/$SALT_MASTER_IPADDR/ || exit 0

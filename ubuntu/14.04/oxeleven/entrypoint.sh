#!/bin/bash
set -e

if [ ! -f /touched ]; then
    touch /touched
    pin=$(cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 6)
    softhsm2-util --init-token --slot 0 --label "detoken" --so-pin $pin --pin $pin
    slotid=$(softhsm2-util --show-slots | head -n 2 | tail -n 1 | sed 's/Slot //g')
    [[ -z "${OXUUID}" ]] && uuid=$(cat /proc/sys/kernel/random/uuid) || uuid="${OXUUID}"
    cat /tmp/oxeleven-config.json.tmpl | sed -e "s/\oxPIN/$pin/" -e "s/\oxSLOT/$slotid/" -e "s/\oxUUID/$uuid/" - > /etc/gluu/conf/oxeleven-config.json
fi

exec gosu root /usr/bin/supervisord
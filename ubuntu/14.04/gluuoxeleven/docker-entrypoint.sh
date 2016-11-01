#!/bin/bash
set -e

if [ "$1" = 'oxeleven' ] && [ ! -z "$2" ]; then
    pin="$2"
    softhsm2-util --init-token --slot 0 --label "detoken" --so-pin $pin --pin $pin
    slotid=$(softhsm2-util --show-slots | head -n 2 | tail -n 1 | sed 's/Slot //g')
    cat conf/oxeleven-config.json.tmpl | sed -e "s/\oxPIN/$pin/" -e "s/\oxSLOT/$slotid/" - > conf/oxeleven-config.json
    exec gosu root catalina.sh run
fi

exec "$@"

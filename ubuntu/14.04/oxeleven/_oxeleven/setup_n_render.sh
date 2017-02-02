#!/bin/bash

softhsm2-util --init-token --slot 0 --label "detoken" --so-pin 1234 --pin 1234
slotid=$(softhsm2-util --show-slots | head -n 2 | tail -n 1 | sed 's/Slot //g')
cat /tmp/oxeleven-config.json.tmpl | sed -e "s/\oxPIN/$pin/" -e "s/\oxSLOT/$slotid/" - > /tmp/oxeleven-config.json

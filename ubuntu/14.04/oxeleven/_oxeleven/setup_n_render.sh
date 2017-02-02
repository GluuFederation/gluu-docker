#!/bin/bash

PIN=1234
softhsm2-util --init-token --slot 0 --label "detoken" --so-pin $PIN --pin $PIN
slotid=$(softhsm2-util --show-slots | head -n 2 | tail -n 1 | sed 's/Slot //g')
cat /tmp/oxeleven-config.json.tmpl | sed -e "s/\oxPIN/$PIN/" -e "s/\oxSLOT/$slotid/" - > /tmp/oxeleven-config.json

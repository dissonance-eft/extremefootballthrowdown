#!/bin/bash
# EFT srcds launch script — managed by systemd (eft-srcds.service)
# For regional latency: Vultr Miami or DigitalOcean NYC recommended for NA + South America

cd /home/gmod/server

exec ./srcds_run \
    -game garrysmod \
    +gamemode extremefootballthrowdown \
    +map eft_slamdunk_v6 \
    +maxplayers 24 \
    -norestart \
    -tickrate 66 \
    +sv_lan 0 \
    -port 27015 \
    "$@"

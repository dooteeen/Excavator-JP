#!/bin/bash

. /etc/container_environment.sh

if [ -z "$BUCKET" ]; then echo 'BUCKET environment variable is not set!'; exit 1; fi
if [ -z "$REMOTE_HOST" ]; then 'REMOTE_HOST environment variable is not set!'; exit 1; fi

if [ -z "`grep "$(ssh-keyscan $REMOTE_HOST 2>/dev/null)" /root/.ssh/known_hosts`" ]; then
    ssh-keyscan $REMOTE_HOST >> /root/.ssh/known_hosts
fi
if [ ! -f /root/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "Excavator-$BUCKET" -f /root/.ssh/id_ed25519 -N ''
fi

#!/bin/bash -eu

HOSTNAME=$1
SHORT_HOSTNAME=$(echo $HOSTNAME | cut -d '.' -f 1)

echo "127.0.0.1 $SHORT_HOSTNAME $HOSTNAME" > /tmp/hosts
awk '!/127\.0\.0\.1|127\.0\.1\.1/' /etc/hosts >> /tmp/hosts
sudo cp /tmp/hosts /etc/hosts

echo "$SHORT_HOSTNAME" > /tmp/hostname
sudo cp /tmp/hostname /etc/hostname
sudo hostname $SHORT_HOSTNAME

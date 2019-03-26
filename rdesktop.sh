#!/bin/bash

target=$1

if ! host $target &>/dev/null; then
    target=${target/computer/192.168.0.}
fi

echo "Connecting to $target"
#exec rdesktop -u ictadmin -p - -k nl-be -r disk:map=share/ -g 1024x768 $target
exec rdesktop -u ictadmin -k nl-be -r disk:map=share/ -g 1600x900 $target &

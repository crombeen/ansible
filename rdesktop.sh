#!/bin/bash

echo "Connecting to ${@/computer/192.168.0.}"
#exec rdesktop -u ictadmin -p - -k nl-be -r disk:map=share/ -g 1024x768 ${@/computer/192.168.0.}
exec rdesktop -u ictadmin -k nl-be -r disk:map=share/ -g 1600x900 ${@/computer/192.168.0.} &

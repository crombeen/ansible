#!/bin/bash

target=$1

if ! host $target &>/dev/null; then
    target=${target/computer/192.168.0.}
fi

echo "Connecting to $target"
exec vncviewer $target -CompressLevel=2 -QualityLevel=1 -PreferredEncoding=ZRLE &

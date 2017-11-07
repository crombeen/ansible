#!/bin/bash

echo "Connecting to ${@/computer/192.168.0.}"
exec vncviewer ${@/computer/192.168.0.} -CompressLevel=2 -QualityLevel=1 -PreferredEncoding=ZRLE &

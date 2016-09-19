#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2016, Dag Wieers <dag@wieers.com>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

DOCUMENTATION = '''
---
module: wakeonlan
version_added: 2.2
short_description: Send a magic Wake-on-LAN (WoL) broadcast packet
description:
   - The M(wakeonlan) module sends magic Wake-on-LAN (WoL) broadcast packets.
options:
  mac:
    description:
      - MAC address to send Wake-on-LAN broadcast packet for
    required: true
    default: null
  broadcast:
    description:
      - Network broadcast address to use for broadcasting magic Wake-on-LAN packet
    required: false
    default: 255.255.255.255
  port:
    description:
      - UDP port to use for magic Wake-on-LAN packet
    required: false
    default: 7
  check_arp:
    description:
      - Enable check-mode support (using arping to IP)
      - This only works if scapy is installed and the module is ran with root privileges
    required: false
    default: true
  ip:
    description:
      - IP address required for check_arp (arping) support
    required: false
    default: None
  timeout:
    description:
      - Timeout in seconds for sending and waiting to arping replies
    required: false
    default: 60
author: "Dag Wieers (@dagwieers)"
todo:
  - Does not have SecureOn password support
notes:
  - This module support check-mode (using arping) if scapy is available and when run as root
  - This module sends a magic packet, and verifies if the system comes up (when check_arp is enabled)
  - If check_arp (arping)is not enabled, this module does not know whether it worked and always returns changed
  - Wake-on-LAN only works if the target system was properly configured for Wake-on-LAN (in the BIOS and/or the OS)
  - Some BIOSes have a different (configurable) Wake-on-LAN boot order (i.e. PXE first) when woken from poweroff
'''

EXAMPLES = '''
# Send a magic Wake-on-LAN packet to 00:CA:FE:BA:BE:00
- local_action: wakeonlan mac=00:CA:FE:BA:BE:00 broadcast=192.168.1.255

- wakeonlan: mac=00:CA:FE:BA:BE:00 port=9
  delegate_to: localhost
'''

RETURN='''
# Default return values
'''

from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.pycompat24 import get_exception

import os
import socket
import struct

try:
    from scapy.all import srp1, Ether, ARP
    HAS_SCAPY = True
except ImportError:
    HAS_SCAPY = False

def arping(mac, ip, timeout):
    """Arping function takes IP Address or Network, returns nested mac/ip list"""
    for i in range(timeout/2):
        ans = srp1(Ether(dst=mac)/ARP(pdst=ip), timeout=2, verbose=0)
        if ans: break
    return ans

def wakeonlan(module, mac, broadcast, port):
    """ Send a magic Wake-on-LAN packet. """

    mac_orig = mac

    # Remove possible seperator from MAC address
    if len(mac) == 12 + 5:
        mac = mac.replace(mac[2], '')

    # If we don't end up with 12 hexadecimal characters, fail
    if len(mac) != 12:
        module.fail_json(msg="Incorrect MAC address length: %s" % mac_orig)

    # Test if it converts to an integer, otherwise fail
    try:
        int(mac, 16)
    except ValueError:
        module.fail_json(msg="Incorrect MAC address format: %s" % mac_orig)
 
    # Create payload for magic packet
    data = ''
    padding = ''.join(['FFFFFFFFFFFF', mac * 20])
    for i in range(0, len(padding), 2):
        data = ''.join([data, struct.pack('B', int(padding[i: i + 2], 16))])

    # Broadcast payload to network
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    try:
        sock.sendto(data, (broadcast, port))
    except socket.error:
        e = get_exception()
        module.fail_json(msg=str(e))


def main():
    module = AnsibleModule(
        argument_spec = dict(
            mac = dict(required=True, type='str'),
            broadcast = dict(required=False, default='255.255.255.255'),
            port = dict(required=False, type='int', default=7),
            check_arp = dict(required=False, type='bool', default=(HAS_SCAPY and os.getuid() == 0)),
            ip = dict(required=False, type='str', default=None),
            timeout = dict(required=False, type='int', default=60),
        ),
        supports_check_mode = HAS_SCAPY and os.getuid(),
    )

    mac = module.params.get('mac')
    broadcast = module.params.get('broadcast')
    port = module.params.get('port')
    check_arp = module.params.get('check_arp')
    ip = module.params.get('ip')
    timeout = module.params.get('timeout')

    if check_arp and not HAS_SCAPY:
        module.fail_json(msg="python module scapy is required when using arping (check-mode support)")

    if check_arp and not ip:
        module.fail_json(msg="ip address is required when using arping (check-mode support)")

    if check_arp and os.getuid() != 0:
        module.fail_json(msg="check_arp (check-mode support) only works as root")

    # Test to see if system is on using arping
    if check_arp:
        found_before = arping(mac, ip, 2)

        # Always perform Wake-on-LAN
        wakeonlan(module, mac, broadcast, port)

        # If system was not up, test to see if system comes up
        if not found_before:
            found_after = arping(mac, ip, timeout)

            if found_after:
                module.exit_json(changed=True)
            else:
                module.fail_json(msg="System was not detected using arping, either mac=%s/ip=%s is wrong or WoL is not configured." % (mac, ip))

        else:
            module.exit_json(changed=False)

    # If check_arp was not enabled, only perform Wake-on-LAN and report change
    else:
        wakeonlan(module, mac, broadcast, port)
        module.exit_json(changed=True)

if __name__ == '__main__':
    main()
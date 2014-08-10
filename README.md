## Note

This 1.4 version is compatible with OpenWrt AA and up. Version 1.5 is available at the openwrt/packages feed, but is not compatible with OpenWrt AA.

## What is mwan3

Mwan3 is a couple of lines of code that simplifies the usage of more (up to 250) WAN interfaces in OpenWRT. It is
hotplug driven and it allows for any combination of primary, secondary or more failover interfaces, load balanced
or not, for any combination of traffic. Mwan3 makes policy routing with multiple wan's easy. Mwan3 can monitor the
state of interfaces by sending pings to a configured tracking host and failover if necessary.

## Why should i use mwan3?

- If you have multiple internet connections, you want to control which traffic goes through which wan's.
- Mwan3 can handle multiple levels of primary and backup interfaces, load-balanced or not. Different sources can have
different primary or backup wan's.
- Mwan3 uses flowmask to be compatible with other packages (such as OpenVPN, PPTP VPN, QoS-script, Tunnels, etc) as
you can configure traffic to use the default routing table.
- Mwan3 can also load-balance traffic originating from the router itself.

## Requirements

Mwan3 is successfully tested on OpenWRT trunk r40512. You need the following packages (which should be installed
automatically if missing): ip, iptables, iptables-mod-conntrack, iptables-mod-conntrack-extra, iptables-mod-ipopt.
Mwan3 is limited to max 250 wan interfaces.

## How does it work

Mwan3 is triggered by hotplug-events. When an interface comes up it creates a new routing table and new iptables
rules. A new routing table is created for each interface. It then sets up iptables rules and uses iptables MARK to
mark certain traffic. Based on ip rules the kernel determines which routing table to use. When an interface goes
down, mwan3 deletes all the rules and routes to that interface in all created routing tables. Mwan3 is not a daemon
that runs in the background. Ones all the routes and rules are in place, it exits. The kernel takes care of all the
routing decisions. If you want to apply a change you have made to mwan3 configuration, you have to trigger a hotplug
event:

## How to install and configure

Please check the wiki http://wiki.openwrt.org/doc/howto/mwan3 for the more info.

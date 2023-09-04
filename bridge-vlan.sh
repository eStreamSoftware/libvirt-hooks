#!/bin/bash -e

# Execute in started event
[ "$2" != 'started' ] && exit 0

# Setup logger tag
tag="qemu-hook $0"

logger -t $tag -p user.info "$0 $@"

# Check xmlstarlet utility
which xmlstarlet || (logger -t $tag -p user.err "ERROR: xmlstarlet not found"; exit 1)

# Check bridge utility
which bridge || (logger -t $tag -p user.err "ERROR: bridge utility not found"; exit 1)

cat | xmlstarlet sel -t -m '//interface[@type="bridge"]' -v 'concat(source/@bridge, " ", target/@dev)' --nl | while read bridge iface; do
  [ -d "/sys/class/net/$bridge/bridge" ] || (logger -t $tag -p user.err "Bridge $bridge for iface $iface does not exist"; exit 1)
  
  [ -f "/sys/class/net/$bridge/bridge/vlan_filtering" ] && vlan_filtering=`cat "/sys/class/net/$bridge/bridge/vlan_filtering"` || vlan_filtering=0
  [ "$vlan_filtering" == "1" ] || logger -t $tag -p user.warning "vlan_filtering $vlan_filering not enable in $bridge"

  [ -f "/sys/class/net/$bridge/bridge/default_pvid" ] && default_pvid=`cat "/sys/class/net/$bridge/bridge/default_pvid"` || default_pvid=1

  # Tagged all VLANs other than PVID
  vid=$((default_pvid - 1))
  [ $vid -ge 1 ] && bridge vlan add dev $iface vid 1-$vid

  vid=$((default_pvid + 1))
  [ $vid -le 4094 ] && bridge vlan add dev $iface vid $vid-4094
done

exit 0
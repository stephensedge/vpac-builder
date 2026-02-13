#!/bin/bash
set -x
set -e

# Disable swap
swapoff -a

# L3 partitioning
echo "Partitioning the cache"
pqos -e "llc:0=$NON_RT_CACHE;llc:1=$RT_CACHE"
pqos -a "llc:1=$RT_CORES"

# Process bus / networking
echo "Configuring network card interrupts and threads"
for nic in $NICS
do
	echo "Disabling NIC power management"
	ethtool --set-eee $nic eee off || echo EEE failed or not supported
	ethtool --change $nic wol d
	echo on > /sys/class/net/$nic/power/control
	IRQS=$(grep $nic /proc/interrupts | cut -d':' -f1)
	for irq in $IRQS
	do
		echo $CPUMASK | tee /proc/irq/$irq/smp_affinity
		tasks=$(ps axo pid,command | grep -e "irq/$irq-" | grep -v grep | awk '{print $1}')
		for pid in $tasks
		do
		taskset -p "0x$CPUMASK" $pid
		done
	done
done

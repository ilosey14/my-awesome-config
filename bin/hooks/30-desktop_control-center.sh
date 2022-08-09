#!/bin/bash
# discover system devices

echo CONFIG_NAME=settings

# cpu
echo '# CPU temperature input...'

labels='^Package|^Tdie|^Tclt'
cpu_temp_cmd=/sys/class/thermal/thermal_zonw0/temp

for f in /sys/class/hwmon/hwmon*/temp*_label
do
	label=$( cat $f )

	if [[ "$label" =~ $labels ]]
	then
		cpu_temp_cmd='cat '${f/label/input}
		cpu_temp_max=$( cat ${f/label/max} )

		echo "# ... found \"$label\" at $cpu_temp_cmd"
		break
	fi
done

# total memory
echo '# Total system memory...'

total_system_memory=$( free | awk '/^Mem/ { print int($2 / 1024) + 1 }' )
echo "# ... $total_system_memory MiB"

# config

echo cpu_temp_cmd=\"$cpu_temp_cmd\"
echo cpu_temp_max=$cpu_temp_max
echo total_system_memory=$total_system_memory

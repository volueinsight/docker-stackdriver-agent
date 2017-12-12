#!/bin/sh

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server/
echo INSTANCE_ID=$HOSTNAME >> /etc/default/stackdriver-agent

/etc/init.d/stackdriver-agent start

while true; do
	sleep 60
	agent_pid=$(cat /var/run/stackdriver-agent.pid 2>/dev/null)

	ps -p $agent_pid > /dev/null 2>&1
	if [ $? != 0 ]; then
		echo "Stackdriver agent pid not found!"
		break;
	fi
done

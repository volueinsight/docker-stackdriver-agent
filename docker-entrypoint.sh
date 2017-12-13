#!/bin/sh

NAME=stackdriver-agent
DAEMON=/opt/stackdriver/collectd/sbin/stackdriver-collectd

CONFIG=/opt/stackdriver/collectd/etc/collectd.conf
CONFIG_TEMPLATE=/opt/stackdriver/collectd/etc/collectd.conf.tmpl
#INSTANCE_ID=$HOSTNAME

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server/:/opt/stackdriver/collectd/lib64:/opt/stackdriver/collectd/lib"

MAXWAIT=30

# Gracefully exit if the package has been removed.
test -x $DAEMON || exit 0

ulimit -c unlimited

get_instance_id () {
    local iid

    # Allow override of instance id in sysconfig file.
    if [ -n "$INSTANCE_ID" ]; then
        iid=$INSTANCE_ID
    elif [ -r /opt/stackdriver/hostid ]; then
        iid=$(cat /opt/stackdriver/hostid)
    elif [ -z "$SKIP_METADATA_CHECKS" ]; then
        # GCP: If we're running on GCE, this will return the instance ID.
        iid=$(curl --silent --connect-timeout 1 -f -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/instance/id 2>/dev/null)
        if [ -z "$iid" ]; then
          # Not running on GCE. Checking AWS.
          # AWS: If we're on EC2, this ought to return the instance id.
          iid=$(curl --silent --connect-timeout 1 -f http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
        fi
    elif [ -r /sys/hypervisor/uuid -a $(cat /sys/hypervisor/version/extra |grep -c amazon) -eq 0 ]; then
        iid=$(cat /sys/hypervisor/uuid)
    else
        echo 'Unable to discover an id for this machine!' >&2
    fi

    echo $iid
}

# return:
#   0 if config was generated successfully.
#   1 if there is a authentication or permissions error.
gen_config() {
    # Check if the application default credentials file is in the system
    # location.
    if [ ! -f /etc/google/auth/application_default_credentials.json ]; then
        # See if the instance has the correct monitoring scopes.
        INSTANCE_SCOPES=$(curl --silent --connect-timeout 1 -f -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/scopes 2>/dev/null || /bin/true)
        if [ `echo "$INSTANCE_SCOPES" | grep -cE '(monitoring.write|monitoring|cloud-platform)$'` -lt 1 ]; then
            echo "The instance has neither the application default" \
              "credentials file nor the correct monitoring scopes; Exiting." >/dev/stderr
            return 1
        fi
    else
        echo "Sufficient authentication scope found to talk to the" \
          "Stackdriver Monitoring API."
    fi

    local IID=$(get_instance_id)
    if [ -z "$IID" ]; then
        echo "Unable to discover instance id. Exiting."
    else
        echo "Hostname \"$IID\"" > $CONFIG
    fi
    cat $CONFIG_TEMPLATE >> $CONFIG
    return 0
}

# return:
#   0 if config is fine
#   1 if there is a syntax error
#   2 if there is no configuration
check_config() {
    if test ! -e "$CONFIG"; then
        return 2
    fi
    if ! $DAEMON -t -C "$CONFIG"; then
        return 1
    fi
    return 0
}

# return:
#   0 if the daemon has been started
#   1 if the daemon was already running
#   2 if the daemon could not be started
#   3 if the daemon was not supposed to be started
d_start() {
    GOOGLE_MONITORING_ENABLE=$(curl --silent --connect-timeout 1 -f -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/attributes/google-monitoring-enable 2>/dev/null)
    if [ -n "$GOOGLE_MONITORING_ENABLE" -a "$GOOGLE_MONITORING_ENABLE" = "0" ]; then
        echo "Disabled via metadata" >/dev/stderr
        return 3
    fi

    # allow setting a proxy
    if [ -n "$PROXY_URL" ]; then
        export https_proxy=$PROXY_URL
    fi

    if ! gen_config || ! check_config; then
        echo "not starting, configuration error" >/dev/stderr
        return 3
    fi

    $DAEMON -f -C "$CONFIG" || return 2
    return 0
}

d_start

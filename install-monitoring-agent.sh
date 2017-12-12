#!/bin/bash
# Copyright 2014-2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Install and start the Google Stackdriver monitoring agent.
#
# This script does the following:
#
#   1. Configures the required apt or yum repository.
#      The environment variable REPO_SUFFIX can be set to alter which
#      repository is used. A dash (-) will be inserted prior to the supplied
#      suffix. Example values are 'unstable' or '20151027-1'.
#   2. Installs the monitoring agent.
#   3. Starts the monitoring agent.
#

# Name of the monitoring agent.
AGENT_NAME='stackdriver-agent'

# Host that serves the repositories.
REPO_HOST='packages.cloud.google.com'

# URL for the monitoring agent documentation.
MONITORING_AGENT_DOCS_URL="https://cloud.google.com/monitoring/agent"

# URL documentation which lists supported platforms for running the monitoring agent.
MONITORING_AGENT_SUPPORTED_URL="${MONITORING_AGENT_DOCS_URL}/#supported_operating_systems"

  CODENAME="$(lsb_release -sc)"
  REPO_NAME="google-cloud-monitoring-${CODENAME}${REPO_SUFFIX+-${REPO_SUFFIX}}"
  cat > /etc/apt/sources.list.d/google-cloud-monitoring.list <<EOM
deb http://${REPO_HOST}/apt ${REPO_NAME} main
EOM
  curl --connect-timeout 10 -s -f "https://${REPO_HOST}/apt/doc/apt-key.gpg" | apt-key add -
  apt-get -qq update || { \
    echo "Could not update apt repositories."; \
    echo "Please check your network connectivity and"; \
    echo "make sure you are running a supported Ubuntu/Debian distribution."; \
    echo "See ${MONITORING_AGENT_SUPPORTED_URL} for a list of supported platforms."; \
    exit 1; \
  }

  DEBIAN_FRONTEND=noninteractive apt-get -y -q install "${AGENT_NAME}"

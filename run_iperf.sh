#!/bin/bash

source inputs.sh
set -ex

ssh ${PW_USER}@${commands_resource_1_publicIp} << EOF
source inputs.sh
echo ${commands_resource_1_privateIp}
echo "Running on server side:"
echo | iperf3 -s -1 &
sleep 2

echo "Running on client side:"
echo | iperf3 -c ${commands_resource_1_privateIp}
sleep 30
exit
EOF
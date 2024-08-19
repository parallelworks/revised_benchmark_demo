#!/bin/bash

source inputs.sh
set -ex

ssh ${PW_USER}@${resource_publicIp} << EOF
source inputs.sh
echo ${resource_privateIp}
echo "Running on server side:"
echo | iperf3 -s -1 &
sleep 2

echo "Running on client side:"
echo | iperf3 -c ${resource_privateIp}
sleep 30
exit
EOF
#!/bin/bash

SYS_FAN=$(snmpwalk -v2c -c public localhost 1.3.6.1.4.1.6574.1.4.1.0 | awk '{print $NF}')
CPU_FAN=$(snmpwalk -v2c -c public localhost 1.3.6.1.4.1.6574.1.4.2.0 | awk '{print $NF}')

STATE=0
RESULT="System Fan: OK; CPU Fan: OK"

if [ "$SYS_FAN" -ne 1 ]; then
  STATE=2
  RESULT="CRITICAL - System Fan Failure"
fi

if [ "$CPU_FAN" -ne 1 ]; then
  STATE=2
  RESULT="CRITICAL - CPU Fan Failure"
fi

echo "$RESULT"
exit $STATE

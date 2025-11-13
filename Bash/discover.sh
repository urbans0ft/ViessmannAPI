#!/bin/bash

installationId=$(source ./get.sh "/iot/v1/equipment/installations" | jq -r '.data[].id')
gatewaySerial=$(source ./get.sh "/iot/v1/equipment/gateways" | jq -r '.data[].serial')
deviceId=$(source ./get.sh "/iot/v1/equipment/installations/$installationId/gateways/$gatewaySerial/devices" | jq -r '.data[0].id')

echo "{" >$SETTING_JSON_FILE
echo "    \"installationId\": \"$installationId\"," >>$SETTING_JSON_FILE
echo "    \"gatewaySerial\": \"$gatewaySerial\"," >>$SETTING_JSON_FILE
echo "    \"deviceId\": \"$deviceId\"" >>$SETTING_JSON_FILE
echo "}" >>$SETTING_JSON_FILE
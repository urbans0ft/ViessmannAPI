#!/bin/bash
#accountJsonFile=".account.json"
#tokenJsonFile=".token.json"
#
#if [[ ! -f $accountJsonFile ]]; then
#    echo "File '$accountJsonFile' is missing."
#    exit 1
#fi
#
#if [[ ! -f $tokenJsonFile ]]; then
#    echo "File '$tokenJsonFile' is missing."
#    exit 1
#fi
#
#clientId=$(cat .account.json | jq --raw-output '.client.id')
#refreshToken=$(cat $tokenJsonFile | jq --raw-output '.refresh_token')
#
echo $clientId
echo $refresh_token

curl -X POST "https://iam.viessmann.com/idp/v2/token" \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "grant_type=refresh_token&client_id=$clientId" \
-d "refresh_token=$refresh_token" >$TOKEN_JSON_FILE
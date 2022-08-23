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

# if token is present load it
if [[ -f $TOKEN_JSON_FILE ]]; then
    refresh_token=$(cat .token.json | jq -r '.refresh_token')
fi

if [[ -z $refresh_token ]]; then
	error "No 'refresh_token' available. Maybe you forgot to login?"
	echo "Try: ./api.sh --login"
	exit 1
fi

curl -X POST "https://iam.viessmann.com/idp/v2/token" \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "grant_type=refresh_token&client_id=$clientId" \
-d "refresh_token=$refresh_token" >$TOKEN_JSON_FILE
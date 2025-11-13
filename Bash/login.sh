#!/bin/bash

acccountName=$(cat .account.json | jq --raw-output '.account.name')
accountPassword=$(cat .account.json | jq --raw-output '.account.password')

clientId=$(cat .account.json | jq --raw-output '.client.id')
redirectUri=$(cat .account.json | jq --raw-output '.client.uri')

# https://tonyxu-io.github.io/pkce-generator/
#codeChallenge='CDJmhfp54ZsvkmsvJEhACXKFJVCv7lbwyHVs7PlMV2s'
#codeVerifier='d_2EdIcbf~ZkX_CnAa9bA25.2RxOof6v.27ESHG0WJEnOQUJKHTZiTqu9x1-a65KbXht7KJrE.bBQREFr0_wbrKk-C-X2WbikF-Va~nqY4qCdycxBhQ9ZwTJmFHGjEW4'
codeChallenge=$(cat .account.json | jq --raw-output '.authorization.challenge')
codeVerifier=$(cat .account.json | jq --raw-output '.authorization.verifier')

authorizationScheme='https'
authorizationServer='iam.viessmann-climatesolutions.com'
authorizationPath='/idp/v2/authorize'
authorizationQuery="client_id=$clientId"
authorizationQuery+="&redirect_uri=$redirectUri"
authorizationQuery+="&scope=IoT%20User%20offline_access"
authorizationQuery+="&response_type=code"
#authorizationQuery+="&code_challenge_method=S256"
authorizationQuery+="&code_challenge=$codeChallenge"

tokenPath='/idp/v2/token'

authorizationUrl="${authorizationScheme}://${authorizationServer}${authorizationPath}?${authorizationQuery}"
tokenUrl="${authorizationScheme}://${authorizationServer}${tokenPath}"

authorizationCode=$(curl $authorizationUrl \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "isiwebuserid=$acccountName" \
    --data-urlencode 'hidden-password=00' \
    --data-urlencode "isiwebpasswd=$accountPassword" \
    --data-urlencode 'submitbtn=LOGIN' | \
    grep '?code=' | \
    sed -E 's/^.*code=([^"]+).*$/\1/')

curl $tokenUrl \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data "client_id=$clientId" \
    --data "redirect_uri=$redirectUri" \
    --data "grant_type=authorization_code" \
    --data "code_verifier=$codeVerifier" \
    --data "code=$authorizationCode" >.token.json


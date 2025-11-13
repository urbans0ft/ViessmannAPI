#!/bin/bash

curl "https://api.viessmann.com/users/v1/users/me?sections=identity" \
    -s \
    -H "Authorization: Bearer $access_token"
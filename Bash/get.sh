#!/bin/bash
curl "https://api.viessmann.com$1" \
    -s \
    -H "Authorization: Bearer $access_token"
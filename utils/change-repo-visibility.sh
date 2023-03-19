#!/usr/bin/env sh

repo="$1"
visibility="${2:-public}"
token="$QUAY_APP_TOKEN"

curl --fail --silent -X "POST" \
  "https://quay.rdnxk.com/api/v1/repository/${repo}/changevisibility" \
  -H "Authorization: Bearer $token" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"visibility\": \"$visibility\"}"

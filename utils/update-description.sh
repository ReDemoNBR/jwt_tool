#!/usr/bin/env sh

basedir="$(realpath "$(dirname "$0")/..")"
repo="$1"
file="${2:-README.md}"
token="$QUAY_APP_TOKEN"

content="$(cat "$basedir/$file")"

data="$(jq -cn --arg content "$content" '{description: $content}')"

curl --fail --silent -X "PUT" \
  "https://quay.rdnxk.com/api/v1/repository/$repo" \
  -H "Authorization: Bearer $token" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "$data"

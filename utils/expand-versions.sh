#!/usr/bin/env bash

set -e

version="$1"
build_date="$2"
suffix="$3"

if [[ -z "$version" ]]; then
    echo "version is required"
    exit 1
fi

major="$(echo "$version" | cut -d. -f1)"
minor="$(echo "$version" | cut -d. -f2)"
patch="$(echo "$version" | cut -d. -f3)"

output=()

if [[ -n "$suffix" ]]; then
    ## considering version=1.2.3 ; build_date=2023-02-04T12:34:56Z with suffix=alpine
    ## output will be:
    ## alpine 1-alpine 1.2-alpine 1.2.3-alpine 1.2.3-alpine_2023-02-04T12:34:56Z
    output+=("$suffix")
    for variant in "$major" "${major}.$minor" "${major}.${minor}.$patch"; do
        output+=("${variant}-$suffix")
    done
    [[ -n "$build_date" ]] && output+=("${major}.${minor}.${patch}-${suffix}_$build_date")
else
    ## considering version=1.2.3 with empty suffix
    ## output will be:
    ## 1 1.2 1.2.3 1.2.3_2023-02-04T12:34:56Z
    for variant in "$major" "${major}.$minor" "${major}.${minor}.$patch" ; do
        output+=("$variant")
    done
    [[ -n "$build_date" ]] && output+=("${major}.${minor}.${patch}_$build_date")
fi

echo "${output[*]}"

#!/usr/bin/env sh

manifest_list="$1"
platform="$2"

[ -z "$manifest_list" ] && echo "Manifest List remote address is required" && exit 1

## Gets the **ManifestList** digest, not the platform specific image manifest digest
if [ -z "$platform" ]; then
	skopeo inspect --format "{{.Digest}}" "docker://$manifest_list"
	exit 0
fi

manifest="$(skopeo inspect --raw "docker://$manifest_list")"

echo "$manifest" | jq -cr --arg platform "$platform" '.manifests
	| map({
		([.platform.os,.platform.architecture,.platform.variant] | del(..|select(.==null)) | join("/")): .digest
	})
	| add
	| .[$platform]'

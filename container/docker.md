## Supported tags and `Containerfile` links

-   [`2.2.6-bullseye`, `2.2-bullseye`, `2-bullseye`, `2.2.6`, `2.2`, `2`, `bullseye`, `latest`](https://github.com/ReDemoNBR/jwt_tool/blob/master/container/debian/Containerfile)
-   [`2.2.6-alpine`, `2.2-alpine`, `2-alpine`, `alpine`](https://github.com/ReDemoNBR/jwt_tool/blob/master/container/alpine/Containerfile)

## Image Variants
### \<version> | \<version>-bullseye
This is the defacto image. If you are unsure about what your needs are, you probably want to use this one.
These images are based on Bullseye release of Debian.

### \<version>-alpine
This image is based on the popular [Alpine Linux](https://alpinelinux.org/) which is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

## Source of these images
-   Repository: <https://gitlab.com/rdnxk/jwt_tool>
-   Issues: <https://gitlab.com/rdnxk/jwt_tool/-/issues>

These images are automatically updated on a weekly basis.
Attestations, SBOM and Signatures are attached to the image digests:
-   **Attestation**: Attestation predicate is attached with [SPDX](https://spdx.dev) in JSON (`application/spdx+json`) format. SPDX is an open standard widely used for software package data exchange
-   **SBOM**: SBOM is attached with [Syft](https://github.com/anchore/syft) in JSON (`application/vnd.syft+json`) format. Syft SBOMs are good for using in conjunction with [Grype](https://github.com/anchore/grype) for vulnerability scanning

### OCI Artifacts
Other OCI artifacts are pushed to this repository. They include the License, Public Key and README with the following tags
-   **license**: Refer to the latest license
-   **license_\<DATE>**: Refer to the license that was pushed at specified `DATE` datetime. Useful if the latest license was updated
-   **publickey**: Refer to the latest public key
-   **publickey_\<DATE>**: Refer to the public key that was pushed at specified `DATE` datetime. Useful when the keys used to sign the old image and artificats got rotated
-   **readme**: Refer to the lastest README
-   **readme_\<DATE>**: Refer to the README that was pushed at the specified `DATE` datetime. Useful if the latest README was updated.

The public keys can be used to validate the authenticity of the images and artifacts. They can be used as below
```bash
## Display signatures and artifacts related to image
$ cosign triangulate docker.io/redemonbr/podman-steroids:latest
$ cosign tree docker.io/redemonbr/podman-steroids:latest

## Pulls/Downloads the public key (it will be saved as cosign.pub)
$ oras pull docker.io/redemonbr/podman-steroids:publickey
## Verify image (via manifest/tag or digest), SBOM and attestation
$ cosign verify --key cosign.pub docker.io/redemonbr/podman-steroids:latest
$ cosign verify --key cosign.pub docker.io/redemonbr/podman-steroids@sha256:...
$ cosign verify --attachment sbom --key cosign.pub docker.io/redemonbr/podman-steroids@sha256:...
$ cosign verify-attestation --type spdxjson --key cosign.pub docker.io/redemonbr/podman-steroids@sha256:...
```

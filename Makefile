all: build push sign sbom artifacts readme
default: all

-include vars.mk

## CONSTANTS
comma = ,
TAG_DEFAULT = bullseye
CONFIG_TYPE = application/vnd.rdnxk.manifest.config.v1+json
PEM_TYPE = application/x-pem-file
MARKDOWN_TYPE = text/markdown
TEMP_DIR = .tmp

ifdef $(CI_PIPELINE_CREATED_AT)
__BUILD_DATE = $(CI_PIPELINE_CREATED_AT)
else
__BUILD_DATE = $$(date -u +%Y-%m-%dT%H:%M:%SZ)
endif
BUILD_DATE = $(subst :,-,$(__BUILD_DATE))

JWT_TOOL_VERSION ?= 2.2.6

## Functions
get_platform_digest = $(shell bash utils/get-digest.sh "$(REMOTE_IMAGE_NAME)" "$(1)")
get_list_digest = $(shell bash utils/get-digest.sh "$(REMOTE_IMAGE_NAME)")
pretty_platform = $(subst /,,$(patsubst linux/%,%,$(1)))

## TEMP DIR
$(TEMP_DIR):
	@mkdir -p $@

## CLEAN
clean:
	@rm -fr "${TEMP_DIR}"

## ARTIFACTS
.PHONY: artifacts
artifacts: $(TEMP_DIR)/license.json $(TEMP_DIR)/publickey.json $(TEMP_DIR)/readme.json

$(TEMP_DIR)/license.json: $(TEMP_DIR)
	@jq -nf artifacts/annotation.tmpl.jq \
		--arg file LICENSE \
		--arg date $(BUILD_DATE) > $(TEMP_DIR)/license.json
	@oras push \
		--config artifacts/config.json:${CONFIG_TYPE} \
		--annotation-file $(TEMP_DIR)/license.json \
		$(REMOTE_IMAGE_REPO):license,license_$(BUILD_DATE) \
		LICENSE:${MARKDOWN_TYPE}

$(TEMP_DIR)/publickey.json: $(TEMP_DIR)
	@jq -nf artifacts/annotation.tmpl.jq \
		--arg file cosign.pub \
		--arg date $(BUILD_DATE) > $(TEMP_DIR)/publickey.json
	@oras push \
		--config artifacts/config.json:${CONFIG_TYPE} \
		--annotation-file $(TEMP_DIR)/publickey.json \
		$(REMOTE_IMAGE_REPO):publickey,publickey_$(BUILD_DATE) \
		${COSIGN_PUBLIC_KEY}:${PEM_TYPE}

$(TEMP_DIR)/readme.json: $(TEMP_DIR) readme
	@jq -nf artifacts/annotation.tmpl.jq \
		--arg file README.md \
		--arg date $(BUILD_DATE) > $(TEMP_DIR)/readme.json
	@oras push \
		--config artifacts/config.json:${CONFIG_TYPE} \
		--annotation-file $(TEMP_DIR)/readme.json \
		$(REMOTE_IMAGE_REPO):readme,readme_$(BUILD_DATE) \
		$(TEMP_DIR)/README.md:${MARKDOWN_TYPE}

## BUILD
.PHONY: build
build:
	@echo Building ${TAG_SUFFIX} variant for ${BUILD_PLATFORM}
	@${BUILDER} build ${BUILD_OPTS} \
		--manifest ${LOCAL_IMAGE_NAME} \
		--platform ${BUILD_PLATFORM} \
		--file ${BUILD_CONTEXT}/${TAG_SUFFIX}/Containerfile ${BUILD_CONTEXT}

## PUSH
.PHONY: push
push:
	@echo Pushing image
	$(eval versions = $(shell bash utils/expand-versions.sh $(JWT_TOOL_VERSION) $(BUILD_DATE) $(TAG_SUFFIX)))
ifeq ($(TAG_SUFFIX), $(TAG_DEFAULT))
	$(eval versions += $(shell bash utils/expand-versions.sh $(JWT_TOOL_VERSION) $(BUILD_DATE)))
endif
	@$(foreach tag, $(versions), \
		echo Pushing $(REMOTE_IMAGE_REPO):$(tag) ; \
		$(BUILDER) manifest push --all ${PUSH_OPTS} $(LOCAL_IMAGE_NAME) docker://$(REMOTE_IMAGE_REPO):$(tag) ; \
	)

## SBOM
.PHONY: sbom
sbom:
	@echo SBOM and attestation
	$(eval platforms = $(subst $(comma), , $(BUILD_PLATFORM)))
	@$(foreach platform, $(platforms),\
		$(eval arch = $(call pretty_platform,$(platform))) \
		$(eval digest = $(call get_platform_digest,$(platform))) \
		TEMP_DIR=$(TEMP_DIR) arch=$(arch) digest=$(digest) \
			$(MAKE) --no-print-directory $(TEMP_DIR)/sbom-$(arch).syft.json ; \
		TEMP_DIR=$(TEMP_DIR) arch=$(arch) digest=$(digest) \
			$(MAKE) --no-print-directory sbom-$(arch) ; \
	)

$(TEMP_DIR)/sbom-$(arch).syft.json: $(TEMP_DIR)
	@syft packages \
		--output syft-json=$(TEMP_DIR)/sbom-$(arch).syft.json \
		--output spdx-json=$(TEMP_DIR)/sbom-$(arch).spdx.json \
		$(REMOTE_IMAGE_REPO)@$(digest)

.PHONY: sbom-$(arch)
sbom-$(arch): $(TEMP_DIR)
	@cosign attach sbom \
		--type syft \
		--sbom $(TEMP_DIR)/sbom-$(arch).syft.json \
		$(REMOTE_IMAGE_REPO)@$(digest)
	@cosign sign --yes \
		--attachment sbom \
		--key ${COSIGN_PRIVATE_KEY} \
		$(REMOTE_IMAGE_REPO)@$(digest)
	@cosign verify \
		--attachment sbom \
		--key ${COSIGN_PUBLIC_KEY} \
		$(REMOTE_IMAGE_REPO)@$(digest) > /dev/null
	@cosign attest --yes \
		--type spdxjson \
		--predicate $(TEMP_DIR)/sbom-$(arch).spdx.json \
		--key ${COSIGN_PRIVATE_KEY} $(REMOTE_IMAGE_REPO)@$(digest)
	@cosign verify-attestation \
		--type spdxjson \
		--key ${COSIGN_PUBLIC_KEY} \
		$(REMOTE_IMAGE_REPO)@$(digest) > /dev/null

## SIGN
.PHONY: sign
sign:
	@echo Signing images and manifest list
	$(eval digest = $(call get_list_digest))
	@cosign sign --yes --recursive --key ${COSIGN_PRIVATE_KEY} $(REMOTE_IMAGE_REPO)@$(digest)
	@cosign verify --key ${COSIGN_PUBLIC_KEY} $(REMOTE_IMAGE_NAME) > /dev/null

.PHONY: readme
readme: $(TEMP_DIR)/README.md

$(TEMP_DIR)/README.md: $(TEMP_DIR)
	@echo Generating rdnxk readme
	@cat ./container/docker.md > $(TEMP_DIR)/README.md
	@echo "" >> $(TEMP_DIR)/README.md
	@cat ./README.md >> $(TEMP_DIR)/README.md

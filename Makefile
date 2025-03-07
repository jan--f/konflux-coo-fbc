## Tools
TOOLS_DIR = $(shell pwd)/.tmp/bin
OPM=$(TOOLS_DIR)/opm
OPM_VERSION = v1.47.0

.PHONY: generate
generate: generate-catalog

.PHONY: generate-catalog
generate-catalog: $(OPM)
	$(OPM) alpha render-template basic --output yaml --migrate-level bundle-object-to-csv-metadata catalog/catalog-template.yaml > catalog/coo-product/catalog.yaml
	# pre 4.17 the catalog should have bundle-object
	$(OPM) alpha render-template basic --output yaml catalog/catalog-template.yaml > catalog/coo-product-4.16/catalog.yaml
	# FBC repo issues shown here https://gitlab.cee.redhat.com/konflux/docs/users/-/merge_requests/189/diffs
	sed -i 's|quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle|registry.redhat.io/cluster-observability-operator/cluster-observability-operator-bundle|g' catalog/coo-product/catalog.yaml
	sed -i 's|quay.io/redhat-user-workloads/cluster-observabilit-tenant/cluster-observability-operator/cluster-observability-operator-bundle|registry.redhat.io/cluster-observability-operator/cluster-observability-operator-bundle|g' catalog/coo-product-4.16/catalog.yaml

.PHONY: lint
lint: lint-pipelines

.PHONY: lint-pipelines
lint-pipelines: .tekton
	@echo ">> running yamllint on all pipeline files"
ifeq (, $(shell command -v yamllint 2> /dev/null))
	@echo "yamllint not installed so skipping" && exit 1
else
	yamllint .tekton
endif

$(TOOLS_DIR):
	@mkdir -p $(TOOLS_DIR)

.PHONY: opm
$(OPM) opm: $(TOOLS_DIR)
	@{ \
		[[ -f $(OPM) ]] && exit 0 ;\
		set -ex ;\
		OS=$(shell go env GOOS) && ARCH=$(shell go env GOARCH) && \
		curl -sSLo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/$(OPM_VERSION)/$${OS}-$${ARCH}-opm ;\
		chmod +x $(OPM) ;\
	}

# Install all required tools
.PHONY: tools
tools: $(OPM)
	@{ \
		set -ex ;\
		tools_file=.github/tools ;\
		echo '# DO NOT EDIT! Autogenerated by make tools' > $$tools_file ;\
		echo '' >> $$tools_file ;\
		echo  $$(basename $(OPM)) $(OPM_VERSION) >> $$tools_file ;\
	}

.PHONY: clean-tools
clean-tools:
	rm -rf $(TOOLS_DIR)

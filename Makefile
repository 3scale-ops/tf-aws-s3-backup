CONTAINER_ENGINE ?= $(which docker)
TEST_CONTAINER_IMAGE = quay.io/3scale/soyuz:v0.3.0-ci
TEST_CONTAINER_RUN = $(CONTAINER_ENGINE) run -ti --rm -w /src -v $(PWD):/src $(TEST_CONTAINER_IMAGE)

help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install-test-tools: ## Install test dependencies
	GO111MODULE=on go get github.com/raviqqe/liche

update-test-tools: ## Update test dependencies
	GO111MODULE=on go get -u github.com/raviqqe/liche

test: test-docs test-terraform ## Run all tests

container-test: container-test-docs container-test-terraform ## Run all tests with container

test-terraform: test-terraform-fmt ## Run all terraform tests

container-test-terraform: container-test-terraform-fmt ## Run all terraform tests with container

TF_FMT_CHECK_CMD = terraform fmt -check -diff -recursive .

test-terraform-fmt: ## Run terraform format test
	$(TF_FMT_CHECK_CMD)

container-test-terraform-fmt: ## Run terraform format test with container
	$(TEST_CONTAINER_RUN) $(TF_FMT_CHECK_CMD)

test-docs: test-docs-relative-links ## Run all documentation tests

container-test-docs: container-test-docs-relative-links ## Run all documentation tests with container

DOCS_LICHE_CMD = liche -r . --exclude http.*

test-docs-relative-links: ## Run documentation relative links tests
	$(DOCS_LICHE_CMD)

container-test-docs-relative-links: ## Run documentation relative links tests with container
	$(TEST_CONTAINER_RUN) $(DOCS_LICHE_CMD)

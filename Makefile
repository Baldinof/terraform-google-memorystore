# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Make will use bash instead of sh
SHELL := /usr/bin/env bash

# Docker build config variables
CREDENTIALS_PATH 			?= /cft/workdir/credentials.json
DOCKER_ORG 				:= gcr.io/cloud-foundation-cicd
DOCKER_TAG_BASE_KITCHEN_TERRAFORM 	?= 2.3.0
DOCKER_REPO_BASE_KITCHEN_TERRAFORM 	:= ${DOCKER_ORG}/cft/kitchen-terraform:${DOCKER_TAG_BASE_KITCHEN_TERRAFORM}

all: check_shell check_python check_golang check_terraform test_check_headers check_headers check_trailing_whitespace generate_docs ## Run all linters and update documentation

# The .PHONY directive tells make that this isn't a real target and so
# the presence of a file named 'check_shell' won't cause this target to stop
# working
.PHONY: check_shell
check_shell: ## Lint shell scripts
	@source test/make.sh && check_shell

.PHONY: check_python
check_python: ## Lint Python source files
	@source test/make.sh && check_python

.PHONY: check_golang
check_golang: ## Lint Go source files
	@source test/make.sh && golang

.PHONY: check_terraform
check_terraform: ## Lint Terraform source files
	@source test/make.sh && check_terraform

.PHONY: check_shebangs
check_shebangs: ## Check that scripts have correct shebangs
	@source test/make.sh && check_bash

.PHONY: check_trailing_whitespace
check_trailing_whitespace:
	@source test/make.sh && check_trailing_whitespace

.PHONY: test_check_headers
test_check_headers:
	@echo "Testing the validity of the header check"
	@source test/make.sh && check_headers

.PHONY: check_headers
check_headers: ## Check that source files have appropriate boilerplate
	@source test/make.sh && check_headers

# Integration tests
.PHONY: test_integration
test_integration: ## Run integration tests
	bundle install
	bundle exec kitchen create
	bundle exec kitchen converge
	bundle exec kitchen converge
	bundle exec kitchen verify
	bundle exec kitchen destroy

.PHONY: generate_docs
generate_docs: ## Update README documentation for Terraform variables and outputs
	@source test/make.sh && generate_docs

# Run docker
.PHONY: docker_run
docker_run: ## Launch a shell within the Docker test environment
	docker run --rm -it \
		-e SERVICE_ACCOUNT_JSON \
		-e CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE=${CREDENTIALS_PATH} \
		-e GOOGLE_APPLICATION_CREDENTIALS=${CREDENTIALS_PATH} \
		-v $(CURDIR):/cft/workdir \
		${DOCKER_REPO_BASE_KITCHEN_TERRAFORM} \
		/bin/bash

.PHONY: docker_create
docker_create: ## Run `kitchen create` within the Docker test environment
	docker run --rm -it \
		-e SERVICE_ACCOUNT_JSON \
		-e CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE=${CREDENTIALS_PATH} \
		-e GOOGLE_APPLICATION_CREDENTIALS=${CREDENTIALS_PATH} \
		-v $(CURDIR):/cft/workdir \
		${DOCKER_REPO_BASE_KITCHEN_TERRAFORM} \
		/bin/bash -c "kitchen create"

.PHONY: docker_converge
docker_converge: ## Run `kitchen converge` within the Docker test environment
	docker run --rm -it \
		-e SERVICE_ACCOUNT_JSON \
		-e CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE=${CREDENTIALS_PATH} \
		-e GOOGLE_APPLICATION_CREDENTIALS=${CREDENTIALS_PATH} \
		-v $(CURDIR):/cft/workdir \
		${DOCKER_REPO_BASE_KITCHEN_TERRAFORM} \
		/bin/bash -c "kitchen converge && kitchen converge"

.PHONY: docker_verify
docker_verify: ## Run `kitchen verify` within the Docker test environment
	docker run --rm -it \
		-e SERVICE_ACCOUNT_JSON \
		-e CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE=${CREDENTIALS_PATH} \
		-e GOOGLE_APPLICATION_CREDENTIALS=${CREDENTIALS_PATH} \
		-v $(CURDIR):/cft/workdir \
		${DOCKER_REPO_BASE_KITCHEN_TERRAFORM} \
		/bin/bash -c "kitchen verify"

.PHONY: docker_destroy
docker_destroy: ## Run `kitchen destroy` within the Docker test environment
	docker run --rm -it \
		-e SERVICE_ACCOUNT_JSON \
		-e CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE=${CREDENTIALS_PATH} \
		-e GOOGLE_APPLICATION_CREDENTIALS=${CREDENTIALS_PATH} \
		-v $(CURDIR):/cft/workdir \
		${DOCKER_REPO_BASE_KITCHEN_TERRAFORM} \
		/bin/bash -c "kitchen destroy"

.PHONY: test_integration_docker
test_integration_docker: docker_create docker_converge docker_verify docker_destroy ## Run a full integration test cycle
	@echo "Running test-kitchen tests in docker"

help: ## Prints help for targets with comments
	@grep -E '^[a-zA-Z._-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

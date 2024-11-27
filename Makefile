# Copyright 2023 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

-include env.sh
export

help: ## Display this help screen.
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

auth: ## Authenticate with your individual GCP credentials.
	@echo "################################################################################" && \
	echo "# Authenticating ..." && \
	echo "################################################################################" && \
	gcloud auth login
    
env ?= dev
AUTO_APPROVE_FLAG :=
deploy: ## Deploy infrastructure to your project. Optionally set env=<dev|test|prod> (default=dev).
	@echo "################################################################################" && \
	echo "# Deploy $$env environment" && \
	echo "################################################################################" && \
	if [ "$(auto-approve)" = "true" ]; then \
		AUTO_APPROVE_FLAG="-auto-approve"; \
	fi; \
	cd terraform/envs/$(env) && \
	terraform init -backend-config='bucket=${VERTEX_PROJECT_ID}-tfstate' && \
	terraform apply -var 'project_id=${VERTEX_PROJECT_ID}' -var 'region=${VERTEX_LOCATION}' $$AUTO_APPROVE_FLAG

undeploy: ## Destroy the infrastructure in your project. Optionally set env=<dev|test|prod> (default=dev).
	@echo "################################################################################" && \
	echo "# Destroy $$env environment" && \
	echo "################################################################################" && \
	if [ "$(auto-approve)" = "true" ]; then \
		AUTO_APPROVE_FLAG="-auto-approve"; \
	fi; \
	cd terraform/envs/$(env) && \
	terraform init -backend-config='bucket=${VERTEX_PROJECT_ID}-tfstate' && \
	terraform destroy -var 'project_id=${VERTEX_PROJECT_ID}' -var 'region=${VERTEX_LOCATION}' $$AUTO_APPROVE_FLAG

install: ## Set up local Python environment for development.
	@echo "################################################################################" && \
	echo "# Install Python dependencies" && \
	echo "################################################################################" && \
	cd model && \
	poetry install --no-root && \
	cd ../pipelines && \
	poetry install --with dev && \
	cd ../components && \
	poetry install --with dev && \
	cd ../package && \
	poetry install --with dev  && \
	cd ../utils && \
	poetry install --no-root

packages ?= pipelines components package
test: ## Run unit tests. Optionally set packages=<pipelines and/or components> (default="pipelines components").
	@echo "################################################################################" && \
	echo "# Test $$packages package(s)" && \
	echo "################################################################################" && \
	for package in $$packages ; do \
		echo "Testing $$package package" && \
		cd $$package && \
		poetry run pytest && \
		cd .. ; \
	done

increment ?= false
part ?= patch
add_user ?= true
build-package: ## Build Python Custom Package (under package/). Optionally set increment=<true|false> (default=false), part=<major|minor|patch> (default=patch), add_user=<true|false> (default=true).
	@echo "################################################################################" && \
	echo "# Building Python Custom Package..." && \
	echo "################################################################################" && \
	cd utils && \
	if [ "$(increment)" = "true" ]; then echo "### Incrementing Package Version..." && poetry run python increment_toml_version.py ../package/pyproject.toml --part $(part); fi; if [ "$(add_user)" = "true" ]; then echo "### Adding User to Package Version..." && poetry run python update_toml_version.py ../package/pyproject.toml; fi; cd ../package && \
	echo "### Running Tests..." && \
	poetry run pytest && \
	echo "### Building Package..." && \
	poetry build && \
	echo "done."
    
# Source: https://medium.com/google-cloud/python-packages-via-gcps-artifact-registry-ce1714f8e7c1
# If it doesn not work, try running in the package directory: poetry self update && poetry self add keyrings.google-artifactregistry-auth

publish-package: build-package ## Publish Custom Package (under package/) to AR. Optionally set add_user=<true|false> (default=true).
	@echo "################################################################################" && \
	echo "# Publish Custom Package to Artifact Registry ..." && \
	echo "     Project ID:" ${VERTEX_PROJECT_ID} && \
	echo "     Repository name:" ${AR_PYTHON} && \
	echo "################################################################################" && \
	cd package  && \
	echo "# Configuring GCP repository..." && \
	poetry config repositories.gcp https://${AR_PYTHON} && \
	echo "# Pushing Package..." && \
	poetry publish --build --repository gcp  && \
	echo "done."
    
compile: ## Compile pipeline. Set pipeline=<training|prediction>.
	@echo "################################################################################" && \
	echo "# Compile $$pipeline pipeline" && \
	echo "################################################################################" && \
	cd pipelines/src && \
	poetry run kfp dsl compile --py pipelines/${pipeline}.py --output pipelines/${pipeline}.yaml --function pipeline

images ?= training prediction
suffix ?= pipelines
build: ## Build and push container(s). Set images=<enrichment and/or other_folder> (default="enrichment").
	@echo "################################################################################" && \
	echo "# Build $$images image(s)" && \
	echo "################################################################################" && \
	cd model && \
	for image in $$images ; do \
		echo "Build $$image image" && \
		gcloud builds submit . \
		--region=${VERTEX_LOCATION} \
		--project=${VERTEX_PROJECT_ID} \
		--gcs-source-staging-dir=${STAGING_IMGS_BUCKET}/source \
		--substitutions=_DOCKER_TARGET=$$image,_DESTINATION_IMAGE_URI=${AR_IMAGES_REPO}/$$image:${suffix} \
		--suppress-logs ; \
	done

compile ?= true
build ?= false
cache ?= true
wait ?= false
run: ## Run a pipeline. Set pipeline=<training|prediction>. Optionally set compile=<true|false> (default=true), build=<true|false> (default=false), cache=<true|false> (default=true). wait=<true|false> (default=false).
	@if [ $(compile) = "true" ]; then \
		$(MAKE) compile ; \
	elif [ $(compile) != "false" ]; then \
		echo "ValueError: compile must be either true or false" ; \
		exit ; \
	fi && \
	if [ $(build) = "true" ]; then \
		$(MAKE) build ; \
	elif [ $(build) != "false" ]; then \
		echo "ValueError: build must be either true or false" ; \
		exit ; \
	fi && \
	echo "################################################################################" && \
	echo "# Run $$pipeline pipeline" && \
	echo "################################################################################" && \
	cd pipelines/src && \
	ENABLE_PIPELINE_CACHING=$$cache poetry run python -m pipelines.utils.trigger_pipeline \
		--template_path=pipelines/${pipeline}.yaml --display_name=${pipeline} --wait=${wait}

register: ## Register a pipeline in AR. Set pipeline=<your_pipeline>. Optionally set compile=<true|false> (default=true).
	@if [ $(compile) = "true" ]; then \
		$(MAKE) compile ; \
	elif [ $(compile) != "false" ]; then \
		echo "ValueError: compile must be either true or false" ; \
		exit ; \
	fi && \
	echo "################################################################################" && \
	echo "# Registering $$pipeline pipeline" && \
	echo "################################################################################" && \
	cd pipelines && \
	poetry run python -m pipelines.utils.upload_pipeline \
	--dest=https://${AR_PIPELINES_REPO} \
	--yaml=src/pipelines/${pipeline}.yaml \
	--tag=latest \
	--tag=$(RESOURCE_SUFFIX) \
	--extra_headers="$(DESCRIPTION)"
    
deploy-function: ## Deploy cloud function to trigger pipelines (with its associated pubsub topic), make sure to fill needed variables in env.sh file. 
	@echo "Creating Pub/Sub topic..."
	gcloud pubsub topics create ${PUBSUB_TOPIC} || true

	@echo "Deploying cloud function..."
	gcloud functions deploy ${CLOUD_FUNCTION} \
		--gen2 \
		--runtime=${RUN_TIME} \
		--source=${SOURCE} \
		--entry-point=${ENTRY_POINT} \
		--trigger-topic=${PUBSUB_TOPIC} \
		--project=${VERTEX_PROJECT_ID} \
		--region=${VERTEX_LOCATION} \
		--service-account=${VERTEX_SA_EMAIL} \
		--set-env-vars=VERTEX_PROJECT_ID=${VERTEX_PROJECT_ID},VERTEX_LOCATION=${VERTEX_LOCATION},VERTEX_PIPELINE_ROOT=${VERTEX_PIPELINE_ROOT},VERTEX_SA_EMAIL=${VERTEX_SA_EMAIL}

bucket ?= bucket_name
name_file ?= example/file.csv
params ?= "{\"key1\":\"value1\",\"key2\":\"value2\"}"

enable_caching ?= False
pipeline ?= training

create_event_trigger: ## Create event-based trigger. Set pipeline=<pipeline_to_trigger>, bucket=<name_of_your_bucket_to_track>, name_file=<files_to_track_prefix>. Optionally set enable_caching=<True|False> (default=False), params=<your_pipeline_parameters_str> (default="{}"; use \" for inner dictionary keys).
	@$(MAKE) auth_sa && \
	$(MAKE) register pipeline=$(pipeline) && \
	echo "################################################################################" && \
	echo "# Registered at: $(AR_PIPELINES_REPO)/$(pipeline)/latest" && \
	echo "################################################################################" && \
	echo "# Creating event-based trigger:" && \
	echo "#     Project: $(VERTEX_PROJECT_ID)" && \
	echo "#     Event bucket: $(bucket)" && \
	echo "#     File prefix: $(name_file)" && \
	echo "#     Pipeline configs:" && \
	echo "#          Pipeline parameters: $(params)" && \
	echo "#          Pipeline caching: $(enable_caching)" && \
	echo "################################################################################" && \
	cd pipelines && \
	poetry run python -m pipelines.utils.create_pipeline_trigger \
	--bucket=$(bucket) \
	--topic_name=${PUBSUB_TOPIC} \
	--custom_attributes='{"template_path":"$(AR_PIPELINES_REPO)/$(pipeline)/latest", "display_name":"$(pipeline)","enable_caching":"$(enable_caching)", "pipeline_parameters": $(params)}' \
	--event_types=OBJECT_FINALIZE \
	--blob_name_prefix=$(name_file) \
	--payload_format=JSON_API_V1;

list_event_triggers: ## List event-based trigger. Set bucket=<your_bucket_to_track>.
	@echo "################################################################################" && \
	echo "# Listing event triggers for bucket: $(bucket)" && \
	echo "################################################################################" && \
	cd pipelines && \
	poetry run python -m pipelines.utils.create_pipeline_trigger \
	--bucket=$(bucket) \
	--function=list;

event_trigger_details: ## Event-based trigger details. Set bucket=<your_bucket_to_track>, notification_id=<Notification ID integer>.
	@echo "################################################################################" && \
	echo "# Event trigger details, notification ID: $(notification_id)" && \
	echo "################################################################################" && \
	cd pipelines && \
	poetry run python -m pipelines.utils.create_pipeline_trigger \
	--bucket=$(bucket) \
	--function=details \
	--notification_id=$(notification_id)
    
delete_event_trigger: ## Delete event-based trigger. Set bucket=<your_bucket_to_track>, notification_id=<Notification ID integer>.
	@echo "################################################################################" && \
	echo "# Delete event trigger, notification ID: $(notification_id)" && \
	echo "################################################################################" && \
	cd pipelines && \
	poetry run python -m pipelines.utils.create_pipeline_trigger \
	--bucket=$(bucket) \
	--function=delete \
	--notification_id=$(notification_id)

schedule ?= "00 16 * * *" 
pipeline_schedule_no ?= 1 

create_cron_trigger: ## Create cron-based trigger. Set pipeline=<pipeline_to_schedule> (default=training). Optionally set schedule=<your_cron_shedule> (default="30 16 * * *"), pipeline_schedule_no=<no_of_schedule_for_a_pipeline> (default=1), enable_caching=<True|False> (default=False), params=<your_pipeline_parameters_str> (default="{}"; use \" for inner dictionary keys). Docs: https://cloud.google.com/scheduler/docs/schedule-run-cron-job-gcloud.
	@$(MAKE) register pipeline=$(pipeline) && \
	echo "################################################################################" && \
	echo "# Registered at: $(AR_PIPELINES_REPO)/$(pipeline)/latest" && \
	echo "################################################################################" && \
	echo "# Creating cron-based trigger:" && \
	echo "#     Project: $(VERTEX_PROJECT_ID)" && \
	echo "#     Pipeline configs:" && \
	echo "#          Pipeline parameters: $(params)" && \
	echo "#          Pipeline caching: $(enable_caching)" && \
	echo "################################################################################" && \
	gcloud scheduler jobs create pubsub $(pipeline)-$(pipeline_schedule_no)  \
		--schedule=$(schedule) \
		--topic=${PUBSUB_TOPIC} \
		--location="$(LOCATION)" \
		--message-body='{"template_path":"$(AR_PIPELINES_REPO)/$(pipeline)/latest", "display_name":"$(pipeline)","enable_caching":"$(enable_caching)", "pipeline_parameters": $(params)}';   

run_cron: ## Force cron job to run immediatly. Set cron_id (typically pipeline-pipeline_schedule_no).
	@echo "################################################################################" && \
	echo "Running cron $(cron_id) immediatly" && \
	echo "################################################################################" && \
	gcloud scheduler jobs run $(cron_id) --location=$(LOCATION)
    
list_cron:
	@echo "################################################################################" && \
	echo "Listing scheduler jobs..." && \
	echo "################################################################################" && \
	gcloud scheduler jobs list --location=$(LOCATION)
    
delete_cron: ## Delete cron job to run immediatly. Set cron_id (typically pipeline-pipeline_schedule_no). 
	@echo "################################################################################" && \
	echo "Deleting cron $(cron_id)" && \
	echo "################################################################################" && \
	gcloud scheduler jobs delete $(cron_id) --location=$(LOCATION)
    
pre-commit: ## Run pre-commit checks for pipelines.
	@cd pipelines && \
	poetry run pre-commit run --all-files
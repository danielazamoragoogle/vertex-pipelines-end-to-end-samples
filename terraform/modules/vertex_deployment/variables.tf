/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "project_id" {
  description = "The ID of the Google Cloud project in which to provision resources."
  type        = string
}

variable "region" {
  description = "Google Cloud region to use for resources and Vertex Pipelines execution."
  type        = string
}

variable "zone" {
  description = "Google Cloud zone to use for resources that need it (e.g. Vertex Workbench)."
  type        = string
}

variable "gcp_service_list" {
  description = "List of Google Cloud APIs to enable on the project."
  type        = list(string)
  default = [
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "dataflow.googleapis.com",
    "iam.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
  ]
}

variable "disable_services_on_destroy" {
  description = "If true, disable the service when the Terraform resource is destroyed. Defaults to true. May be useful in the event that a project is long-lived but the infrastructure running in that project changes frequently."
  type        = bool
  default     = true
}
variable "disable_dependent_services" {
  description = "If true, services that are enabled and which depend on this service should also be disabled when this service is destroyed. If false or unset, an error will be generated if any enabled services depend on this service when destroying it."
  type        = bool
  default     = true
}

variable "pipelines_sa_project_roles" {
  description = "List of project IAM roles to be granted to the Vertex Pipelines service account."
  type        = list(string)
  default = [
    "roles/aiplatform.user",
    "roles/artifactregistry.reader",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/bigquery.user",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor",
    "roles/storage.admin",
    "roles/storage.objectUser"
  ]
}

variable "user_project_roles" {
  description = "List of project IAM roles to be granted to the Golden Path Users."
  type        = list(string)
  default  = [
    "roles/artifactregistry.admin", 
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/bigquery.user",
    "roles/cloudbuild.builds.editor",
    "roles/cloudbuild.integrations.editor",
    "roles/logging.viewer",
    "roles/logging.logWriter",
    "roles/notebooks.admin",
    "roles/secretmanager.secretAccessor", 
    "roles/secretmanager.secretVersionAdder",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/storage.admin",
    "roles/storage.objectUser",
    "roles/aiplatform.admin",
    "roles/viewer" 
  ]
}

variable "users" {
	  type= list(string)
	  default = [
      "user:datasciencedani@gmail.com",
      ]
	}

variable "user_ldaps" {
	  type= list(string)
	  default = [
      "datasciencedani",
      ]
	}
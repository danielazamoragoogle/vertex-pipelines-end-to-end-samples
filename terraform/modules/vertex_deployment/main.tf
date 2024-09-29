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

## Google Cloud APIs to enable ##
resource "google_project_service" "gcp_services" {
  for_each                   = toset(var.gcp_service_list)
  project                    = var.project_id
  service                    = each.key
  disable_on_destroy         = var.disable_services_on_destroy
  disable_dependent_services = var.disable_dependent_services
}

## Service Accounts ##

# Vertex Pipelines service account
resource "google_service_account" "vertex_ai_pipelines_service_account" {
  project      = var.project_id
  account_id   = "vertex-ai-pipelines-sa" 
  display_name = "Vertex AI Pipelines Service Account"
  depends_on   = [google_project_service.gcp_services]
}


## GCS buckets ##
resource "google_storage_bucket" "vertex_ai_pipeline_artifacts_bucket" {
  name                        = "${var.project_id}-vertex-ai-pipeline-artifacts" 
  location                    = var.region
  project                     = var.project_id
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  depends_on                  = [google_project_service.gcp_services]
}


## Vertex Metadata store ##
resource "google_vertex_ai_metadata_store" "default_metadata_store" {
  provider    = google-beta
  name        = "default"
  description = "Default metadata store"
  project     = var.project_id
  region      = var.region
  depends_on  = [google_project_service.gcp_services]
}

## Artifact Registry - container images ##
resource "google_artifact_registry_repository" "vertex_ai_container_images_repository" {
  repository_id = "vertex-ai-container-images" 
  description   = "Container image repository for Vertex AI components"
  project       = var.project_id
  location      = var.region
  format        = "DOCKER"
  depends_on    = [google_project_service.gcp_services]
}

## Artifact Registry - KFP pipelines ##
resource "google_artifact_registry_repository" "vertex_ai_pipelines_repository" {
  repository_id = "vertex-ai-pipelines" 
  description   = "KFP repository for Vertex AI Pipelines"
  project       = var.project_id
  location      = var.region
  format        = "KFP"
  depends_on    = [google_project_service.gcp_services]
}

## Artifact Registry - Vertex AI Packages ##
resource "google_artifact_registry_repository" "vertex_ai_packages_repository" {
  repository_id = "vertex-ai-packages"
  description   = "Repository for Vertex AI Packages"
  project       = var.project_id
  location      = var.region
  format        = "PYTHON" # Important: Set the format to PYTHON
  depends_on    = [google_project_service.gcp_services]
}

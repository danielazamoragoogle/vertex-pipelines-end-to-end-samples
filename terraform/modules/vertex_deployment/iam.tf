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

# Vertex Pipelines SA project roles
resource "google_project_iam_member" "pipelines_sa_project_roles" {
  for_each = toset(var.pipelines_sa_project_roles)
  project  = var.project_id
  role     = each.key
  member   = google_service_account.vertex_ai_pipelines_service_account.member
}

# User project roles
locals {
	  members_to_roles = {
	    for p in setproduct(
	      toset(var.users),
	      toset(var.user_project_roles)
	    ) :
	    "${p[0]}-${p[1]}" => {
	      member = p[0]
	      role   = p[1]
	    }
	  }
	}
	  resource "google_project_iam_member" "main" {
	  for_each = local.members_to_roles
	  project = var.project_id
	  role    = each.value.role
	  member  = each.value.member
	
  }
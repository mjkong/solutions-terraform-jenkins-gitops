/**
 * Copyright 2020 Google LLC
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
# try 2
/*****************************************
  Jenkins GKE
 *****************************************/
module "gke" {
  source                   = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster/"
  version                  = "~> 17.0"
  project_id               = var.project_id
  name                     = var.cluster_name
  regional                 = false
  region                   = "us-east1"
  zones                    = ["us-east1-b","us-east1-c"]
  network                  = data.terraform_remote_state.vpc.outputs.vpc_name
  subnetwork               = data.terraform_remote_state.vpc.outputs.subnet_names[0]
  ip_range_pods            = var.ip_range_pods_name
  ip_range_services        = var.ip_range_services_name
  logging_service          = "logging.googleapis.com/kubernetes"
  monitoring_service       = "monitoring.googleapis.com/kubernetes"
  remove_default_node_pool = true
  service_account          = "create"
  identity_namespace       = "${var.project_id}.svc.id.goog"
  node_metadata            = "GKE_METADATA_SERVER"
  node_pools = [
    {
      name                      = "dev-pool"
      machine_type              = "e2-medium"
      node_locations            = "us-east1-b,us-east1-c"
      min_count                 = 3
      max_count                 = 6
      local_ssd_count           = 0
      local_ssd_ephemeral_count = 0
      disk_size_gb              = 100
      disk_type                 = "pd-standard"
      image_type                = "COS"
      auto_repair               = true
      auto_upgrade              = true
      service_account           = "nonprodmachineuser@stable-splicer-326102.iam.gserviceaccount.com"
    }
  ]
}

/*****************************************
  IAM Bindings GKE SVC
 *****************************************/
# allow GKE to pull images from GCR
resource "google_project_iam_member" "gke" {
  project = var.project_id
  role    = "roles/storage.objectViewer"

  member = "serviceAccount:${module.gke.service_account}"
}

/*****************************************
  Jenkins Workload Identity
 *****************************************/
module "workload_identity" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "~> 7.0"
  project_id          = var.project_id
  name                = "${module.gke.name}-wi"
  namespace           = "default"
  use_existing_k8s_sa = false
}

# enable GSA to add and delete pods for jenkins builders
resource "google_project_iam_member" "cluster-dev" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = module.workload_identity.gcp_service_account_fqn
}

data "google_client_config" "default" {
}
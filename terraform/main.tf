resource "google_cloud_scheduler_job" "start_job" {
  name        = var.start_job_name
  description = var.start_job_description
  project     = var.project_id
  region      = var.region
  schedule    = var.start_job_schedule
  time_zone   = var.time_zone

  pubsub_target {
    topic_name = google_pubsub_topic.start_topic.id
    data       = base64encode(var.start_message)
  }
}

resource "google_cloud_scheduler_job" "stop_job" {
  name        = var.stop_job_name
  description = var.stop_job_description
  project     = var.project_id
  region      = var.region
  schedule    = var.stop_job_schedule
  time_zone   = var.time_zone

  pubsub_target {
    topic_name = google_pubsub_topic.stop_topic.id
    data       = base64encode(var.stop_message)
  }
}

resource "google_pubsub_topic" "start_topic" {
  project                    = var.project_id
  name                       = var.start_topic
  labels                     = var.topic_labels
  kms_key_name               = var.topic_kms_key_name
  message_retention_duration = var.topic_message_retention_duration
}

resource "google_pubsub_topic" "stop_topic" {
  project                    = var.project_id
  name                       = var.stop_topic
  labels                     = var.topic_labels
  kms_key_name               = var.topic_kms_key_name
  message_retention_duration = var.topic_message_retention_duration
}

resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name                        = "gcf-source-${random_id.bucket_prefix.hex}"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
}

module "function_start_compute_instances" {
  count                 = lookup(var.start_compute_function, "enabled", false) ? 1 : 0
  source                = "./modules/pubsub-function"
  name                  = "start-gce-instances"
  project_id            = var.project_id
  description           = "Function for starting Compute Engine instances"
  bucket_name           = google_storage_bucket.default.name
  source_dir            = "${path.module}/../functions/compute"
  location              = var.region
  entry_point           = "startInstances"
  pubsub_topic          = google_pubsub_topic.start_topic.id
  service_account_email = var.start_compute_function.service_account_email
  timeout               = var.start_compute_function.timeout
  available_memory      = var.start_compute_function.available_memory
  max_instance_count    = var.start_compute_function.max_instance_count
}

module "function_stop_compute_instances" {
  count                 = lookup(var.stop_compute_function, "enabled", false) ? 1 : 0
  source                = "./modules/pubsub-function"
  name                  = "stop-gce-instances"
  project_id            = var.project_id
  description           = "Function for stopping Compute Engine instances"
  bucket_name           = google_storage_bucket.default.name
  source_dir            = "${path.module}/../functions/compute"
  location              = var.region
  entry_point           = "stopInstances"
  pubsub_topic          = google_pubsub_topic.stop_topic.id
  service_account_email = var.stop_compute_function.service_account_email
  timeout               = var.stop_compute_function.timeout
  available_memory      = var.stop_compute_function.available_memory
  max_instance_count    = var.stop_compute_function.max_instance_count
}

module "function_start_sql_instances" {
  count                 = lookup(var.start_sql_function, "enabled", false) ? 1 : 0
  source                = "./modules/pubsub-function"
  name                  = "start-sql-instances"
  project_id            = var.project_id
  description           = "Function for starting Cloud SQL instances"
  bucket_name           = google_storage_bucket.default.name
  source_dir            = "${path.module}/../functions/sql"
  location              = var.region
  entry_point           = "startInstances"
  pubsub_topic          = google_pubsub_topic.start_topic.id
  service_account_email = var.start_sql_function.service_account_email
  timeout               = var.start_sql_function.timeout
  available_memory      = var.start_sql_function.available_memory
  max_instance_count    = var.start_sql_function.max_instance_count
}

module "function_stop_sql_instances" {
  count                 = lookup(var.stop_sql_function, "enabled", false) ? 1 : 0
  source                = "./modules/pubsub-function"
  name                  = "stop-sql-instances"
  project_id            = var.project_id
  description           = "Function for stopping Cloud SQL instances"
  bucket_name           = google_storage_bucket.default.name
  source_dir            = "${path.module}/../functions/sql"
  location              = var.region
  entry_point           = "stopInstances"
  pubsub_topic          = google_pubsub_topic.stop_topic.id
  service_account_email = var.stop_sql_function.service_account_email
  timeout               = var.stop_sql_function.timeout
  available_memory      = var.stop_sql_function.available_memory
  max_instance_count    = var.stop_sql_function.max_instance_count
}

module "function_start_gke_node_pools" {
  count                 = lookup(var.start_gke_function, "enabled", false) ? 1 : 0
  source                = "./modules/pubsub-function"
  name                  = "start-gke-node-pools"
  project_id            = var.project_id
  description           = "Function for starting GKE node pools"
  bucket_name           = google_storage_bucket.default.name
  source_dir            = "${path.module}/../functions/gke"
  location              = var.region
  entry_point           = "startInstances"
  pubsub_topic          = google_pubsub_topic.start_topic.id
  service_account_email = var.start_gke_function.service_account_email
  timeout               = var.start_gke_function.timeout
  available_memory      = var.start_gke_function.available_memory
  max_instance_count    = var.start_gke_function.max_instance_count
}

module "function_stop_gke_node_pools" {
  count                 = lookup(var.stop_gke_function, "enabled", false) ? 1 : 0
  source                = "./modules/pubsub-function"
  name                  = "stop-gke-node-pools"
  project_id            = var.project_id
  description           = "Function for stopping GKE node pools"
  bucket_name           = google_storage_bucket.default.name
  source_dir            = "${path.module}/../functions/gke"
  location              = var.region
  entry_point           = "stopInstances"
  pubsub_topic          = google_pubsub_topic.stop_topic.id
  service_account_email = var.stop_gke_function.service_account_email
  timeout               = var.stop_gke_function.timeout
  available_memory      = var.stop_gke_function.available_memory
  max_instance_count    = var.stop_gke_function.max_instance_count
}
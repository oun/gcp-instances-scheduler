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
  source                = "./modules/pubsub-function"
  name                  = "start-compute-instances"
  project_id            = var.project_id
  description           = "Function for starting Compute Engine instances"
  bucket_name           = google_storage_bucket.default.name
  source_dir            = "${path.module}/../functions/compute"
  location              = var.region
  entry_point           = "startInstances"
  pubsub_topic          = google_pubsub_topic.start_topic.id
  service_account_email = var.service_account_emails.start_compute_function
}

module "function_stop_compute_instances" {
  source                = "./modules/pubsub-function"
  name                  = "stop-compute-instances"
  project_id            = var.project_id
  description           = "Function for stopping Compute Engine instances"
  bucket_name           = google_storage_bucket.default.name
  source_dir            = "${path.module}/../functions/compute"
  location              = var.region
  entry_point           = "stopInstances"
  pubsub_topic          = google_pubsub_topic.stop_topic.id
  service_account_email = var.service_account_emails.stop_compute_function
}

module "function_start_sql_instances" {
  source                = "./modules/pubsub-function"
  name                  = "start-sql-instances"
  project_id            = var.project_id
  description           = "Function for starting Cloud SQL instances"
  bucket_name           = google_storage_bucket.default.name
  source_dir            = "${path.module}/../functions/sql"
  location              = var.region
  entry_point           = "startInstances"
  pubsub_topic          = google_pubsub_topic.start_topic.id
  service_account_email = var.service_account_emails.start_sql_function
}

module "function_stop_sql_instances" {
  source                = "./modules/pubsub-function"
  name                  = "stop-sql-instances"
  project_id            = var.project_id
  description           = "Function for stopping Cloud SQL instances"
  bucket_name           = google_storage_bucket.default.name
  source_dir            = "${path.module}/../functions/sql"
  location              = var.region
  entry_point           = "stopInstances"
  pubsub_topic          = google_pubsub_topic.stop_topic.id
  service_account_email = var.service_account_emails.stop_sql_function
}
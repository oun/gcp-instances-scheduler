locals {
  scheduled_project = coalesce(var.scheduled_resource_filter.project, var.project_id)
  pubsub_message    = jsonencode({ project = local.scheduled_project, labels = var.scheduled_resource_filter.labels })

  trigger_sa_email      = var.create_trigger_service_account ? google_service_account.trigger_sa[0].email : var.trigger_service_account_email
  gce_function_sa_email = var.gce_function_config.enabled && var.gce_function_config.create_service_account ? google_service_account.gce_function_sa[0].email : var.gce_function_config.service_account_email
  sql_function_sa_email = var.sql_function_config.enabled && var.sql_function_config.create_service_account ? google_service_account.sql_function_sa[0].email : var.sql_function_config.service_account_email
  gke_function_sa_email = var.gke_function_config.enabled && var.gke_function_config.create_service_account ? google_service_account.gke_function_sa[0].email : var.gke_function_config.service_account_email
}

resource "google_cloud_scheduler_job" "start_job" {
  name        = var.start_job_name
  description = var.start_job_description
  project     = var.project_id
  region      = var.region
  schedule    = var.start_job_schedule
  time_zone   = var.time_zone

  pubsub_target {
    topic_name = google_pubsub_topic.start_topic.id
    data       = base64encode(local.pubsub_message)
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
    data       = base64encode(local.pubsub_message)
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

resource "google_service_account" "trigger_sa" {
  count = var.create_trigger_service_account ? 1 : 0

  account_id   = var.trigger_service_account_id
  display_name = "Service Account for pubsub trigger"
  project      = var.project_id
}

resource "google_service_account" "gce_function_sa" {
  count = var.gce_function_config.enabled && var.gce_function_config.create_service_account ? 1 : 0

  account_id   = var.gce_function_config.service_account_id
  display_name = "Service Account for start stop gce function"
  project      = var.project_id
}

resource "google_service_account" "sql_function_sa" {
  count = var.sql_function_config.enabled && var.sql_function_config.create_service_account ? 1 : 0

  account_id   = var.sql_function_config.service_account_id
  display_name = "Service Account for start stop sql function"
  project      = var.project_id
}

resource "google_service_account" "gke_function_sa" {
  count = var.gke_function_config.enabled && var.gke_function_config.create_service_account ? 1 : 0

  account_id   = var.gke_function_config.service_account_id
  display_name = "Service Account for start stop gke function"
  project      = var.project_id
}

resource "google_cloud_run_service_iam_member" "start_gce_function" {
  count = var.gce_function_config.enabled && var.create_trigger_service_account ? 1 : 0

  project  = module.function_start_gce_instances[0].project
  location = module.function_start_gce_instances[0].location
  service  = module.function_start_gce_instances[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.trigger_sa_email}"
}

resource "google_cloud_run_service_iam_member" "stop_gce_function" {
  count = var.gce_function_config.enabled && var.create_trigger_service_account ? 1 : 0

  project  = module.function_stop_gce_instances[0].project
  location = module.function_stop_gce_instances[0].location
  service  = module.function_stop_gce_instances[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.trigger_sa_email}"
}

resource "google_cloud_run_service_iam_member" "start_sql_function" {
  count = var.sql_function_config.enabled && var.create_trigger_service_account ? 1 : 0

  project  = module.function_start_sql_instances[0].project
  location = module.function_start_sql_instances[0].location
  service  = module.function_start_sql_instances[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.trigger_sa_email}"
}

resource "google_cloud_run_service_iam_member" "stop_sql_function" {
  count = var.sql_function_config.enabled && var.create_trigger_service_account ? 1 : 0

  project  = module.function_stop_sql_instances[0].project
  location = module.function_stop_sql_instances[0].location
  service  = module.function_stop_sql_instances[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.trigger_sa_email}"
}

resource "google_cloud_run_service_iam_member" "start_gke_function" {
  count = var.gke_function_config.enabled && var.create_trigger_service_account ? 1 : 0

  project  = module.function_start_gke_node_pools[0].project
  location = module.function_start_gke_node_pools[0].location
  service  = module.function_start_gke_node_pools[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.trigger_sa_email}"
}

resource "google_cloud_run_service_iam_member" "stop_gke_function" {
  count = var.gke_function_config.enabled && var.create_trigger_service_account ? 1 : 0

  project  = module.function_stop_gke_node_pools[0].project
  location = module.function_stop_gke_node_pools[0].location
  service  = module.function_stop_gke_node_pools[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${local.trigger_sa_email}"
}

resource "google_project_iam_member" "gce_function" {
  count = var.gce_function_config.enabled && var.gce_function_config.create_service_account ? 1 : 0

  project = local.scheduled_project
  role    = "roles/compute.instanceAdmin.v1"
  member  = google_service_account.gce_function_sa[0].member
}

resource "google_project_iam_member" "sql_function" {
  count = var.sql_function_config.enabled && var.sql_function_config.create_service_account ? 1 : 0

  project = local.scheduled_project
  role    = "roles/cloudsql.editor"
  member  = google_service_account.sql_function_sa[0].member
}

resource "google_project_iam_member" "gke_function" {
  count = var.gke_function_config.enabled && var.gke_function_config.create_service_account ? 1 : 0

  project = local.scheduled_project
  role    = "roles/container.clusterAdmin"
  member  = google_service_account.gke_function_sa[0].member
}

module "function_start_gce_instances" {
  count                         = var.gce_function_config.enabled ? 1 : 0
  source                        = "./modules/pubsub-function"
  name                          = "start-gce-instances"
  project_id                    = var.project_id
  description                   = "Function for starting Compute Engine instances"
  bucket_name                   = google_storage_bucket.default.name
  source_dir                    = "${path.module}/../functions/gce"
  location                      = var.region
  entry_point                   = "startInstances"
  pubsub_topic                  = google_pubsub_topic.start_topic.id
  service_account_email         = local.gce_function_sa_email
  timeout                       = var.gce_function_config.timeout
  available_memory              = var.gce_function_config.available_memory
  max_instance_count            = var.gce_function_config.max_instance_count
  function_labels               = var.function_labels
  trigger_service_account_email = local.trigger_sa_email
}

module "function_stop_gce_instances" {
  count                         = var.gce_function_config.enabled ? 1 : 0
  source                        = "./modules/pubsub-function"
  name                          = "stop-gce-instances"
  project_id                    = var.project_id
  description                   = "Function for stopping Compute Engine instances"
  bucket_name                   = google_storage_bucket.default.name
  source_dir                    = "${path.module}/../functions/gce"
  location                      = var.region
  entry_point                   = "stopInstances"
  pubsub_topic                  = google_pubsub_topic.stop_topic.id
  service_account_email         = local.gce_function_sa_email
  timeout                       = var.gce_function_config.timeout
  available_memory              = var.gce_function_config.available_memory
  max_instance_count            = var.gce_function_config.max_instance_count
  function_labels               = var.function_labels
  trigger_service_account_email = local.trigger_sa_email
}

module "function_start_sql_instances" {
  count                         = var.sql_function_config.enabled ? 1 : 0
  source                        = "./modules/pubsub-function"
  name                          = "start-sql-instances"
  project_id                    = var.project_id
  description                   = "Function for starting Cloud SQL instances"
  bucket_name                   = google_storage_bucket.default.name
  source_dir                    = "${path.module}/../functions/sql"
  location                      = var.region
  entry_point                   = "startInstances"
  pubsub_topic                  = google_pubsub_topic.start_topic.id
  service_account_email         = local.sql_function_sa_email
  timeout                       = var.sql_function_config.timeout
  available_memory              = var.sql_function_config.available_memory
  max_instance_count            = var.sql_function_config.max_instance_count
  function_labels               = var.function_labels
  trigger_service_account_email = local.trigger_sa_email
}

module "function_stop_sql_instances" {
  count                         = var.sql_function_config.enabled ? 1 : 0
  source                        = "./modules/pubsub-function"
  name                          = "stop-sql-instances"
  project_id                    = var.project_id
  description                   = "Function for stopping Cloud SQL instances"
  bucket_name                   = google_storage_bucket.default.name
  source_dir                    = "${path.module}/../functions/sql"
  location                      = var.region
  entry_point                   = "stopInstances"
  pubsub_topic                  = google_pubsub_topic.stop_topic.id
  service_account_email         = local.sql_function_sa_email
  timeout                       = var.sql_function_config.timeout
  available_memory              = var.sql_function_config.available_memory
  max_instance_count            = var.sql_function_config.max_instance_count
  function_labels               = var.function_labels
  trigger_service_account_email = local.trigger_sa_email
}

module "function_start_gke_node_pools" {
  count                 = var.gke_function_config.enabled ? 1 : 0
  source                = "./modules/pubsub-function"
  name                  = "start-gke-node-pools"
  project_id            = var.project_id
  description           = "Function for starting GKE node pools"
  bucket_name           = google_storage_bucket.default.name
  source_dir            = "${path.module}/../functions/gke"
  location              = var.region
  entry_point           = "startInstances"
  pubsub_topic          = google_pubsub_topic.start_topic.id
  service_account_email = local.gke_function_sa_email
  timeout               = var.gke_function_config.timeout
  available_memory      = var.gke_function_config.available_memory
  max_instance_count    = var.gke_function_config.max_instance_count
  environment_variables = {
    SHUTDOWN_TAINT_KEY   = var.gke_function_config.shutdown_taint_key
    SHUTDOWN_TAINT_VALUE = var.gke_function_config.shutdown_taint_value
  }
  function_labels               = var.function_labels
  trigger_service_account_email = local.trigger_sa_email
}

module "function_stop_gke_node_pools" {
  count                 = var.gke_function_config.enabled ? 1 : 0
  source                = "./modules/pubsub-function"
  name                  = "stop-gke-node-pools"
  project_id            = var.project_id
  description           = "Function for stopping GKE node pools"
  bucket_name           = google_storage_bucket.default.name
  source_dir            = "${path.module}/../functions/gke"
  location              = var.region
  entry_point           = "stopInstances"
  pubsub_topic          = google_pubsub_topic.stop_topic.id
  service_account_email = local.gke_function_sa_email
  timeout               = var.gke_function_config.timeout
  available_memory      = var.gke_function_config.available_memory
  max_instance_count    = var.gke_function_config.max_instance_count
  environment_variables = {
    SHUTDOWN_TAINT_KEY   = var.gke_function_config.shutdown_taint_key
    SHUTDOWN_TAINT_VALUE = var.gke_function_config.shutdown_taint_value
  }
  function_labels               = var.function_labels
  trigger_service_account_email = local.trigger_sa_email
}
locals {
  scheduled_projects = [for schedule in var.schedules : schedule.project]
  pubsub_messages    = [for index, schedule in var.schedules : jsonencode({ project = local.scheduled_projects[index], labels = schedule.resource_labels })]
  pubsub_attributes  = [for index, schedule in var.schedules : { for type in schedule.resource_types : type => "true" }]

  trigger_sa_email      = var.create_trigger_service_account ? google_service_account.trigger_sa[0].email : var.trigger_service_account_email
  gce_function_sa_email = var.gce_function_config.enabled && var.gce_function_config.create_service_account ? google_service_account.gce_function_sa[0].email : var.gce_function_config.service_account_email
  sql_function_sa_email = var.sql_function_config.enabled && var.sql_function_config.create_service_account ? google_service_account.sql_function_sa[0].email : var.sql_function_config.service_account_email
  gke_function_sa_email = var.gke_function_config.enabled && var.gke_function_config.create_service_account ? google_service_account.gke_function_sa[0].email : var.gke_function_config.service_account_email
}

resource "google_cloud_scheduler_job" "start_job" {
  count = length(var.schedules)

  name        = try(var.schedules[count.index].start_job_name, "start-instances-${count.index}")
  description = try(var.schedules[count.index].start_job_description, "")
  project     = var.project_id
  region      = var.region
  schedule    = var.schedules[count.index].start_schedule
  time_zone   = var.time_zone

  pubsub_target {
    topic_name = google_pubsub_topic.start_topic.id
    data       = base64encode(local.pubsub_messages[count.index])
    attributes = local.pubsub_attributes[count.index]
  }
}

resource "google_cloud_scheduler_job" "stop_job" {
  count = length(var.schedules)

  name        = try(var.schedules[count.index].stop_job_name, "stop-instances-${count.index}")
  description = try(var.schedules[count.index].stop_job_description, "")
  project     = var.project_id
  region      = var.region
  schedule    = var.schedules[count.index].stop_schedule
  time_zone   = var.time_zone

  pubsub_target {
    topic_name = google_pubsub_topic.stop_topic.id
    data       = base64encode(local.pubsub_messages[count.index])
    attributes = local.pubsub_attributes[count.index]
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
  for_each = var.gce_function_config.enabled && var.gce_function_config.create_service_account ? toset(local.scheduled_projects) : []

  project = each.value
  role    = "roles/compute.instanceAdmin.v1"
  member  = google_service_account.gce_function_sa[0].member
}

resource "google_project_iam_member" "sql_function" {
  for_each = var.sql_function_config.enabled && var.sql_function_config.create_service_account ? toset(local.scheduled_projects) : []

  project = each.value
  role    = "roles/cloudsql.editor"
  member  = google_service_account.sql_function_sa[0].member
}

resource "google_project_iam_member" "gke_function" {
  for_each = var.gke_function_config.enabled && var.gke_function_config.create_service_account ? toset(local.scheduled_projects) : []

  project = each.value
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
  pubsub_filter                 = { attribute = "gce", value = "true" }
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
  pubsub_filter                 = { attribute = "gce", value = "true" }
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
  pubsub_filter                 = { attribute = "sql", value = "true" }
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
  pubsub_filter                 = { attribute = "sql", value = "true" }
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
  pubsub_filter                 = { attribute = "gke", value = "true" }
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
  pubsub_filter                 = { attribute = "gke", value = "true" }
}
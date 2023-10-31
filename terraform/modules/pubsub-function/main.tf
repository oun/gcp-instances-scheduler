data "archive_file" "default" {
  type        = "zip"
  output_path = "/tmp/${var.name}/function-source.zip"
  source_dir  = var.source_dir
}

resource "google_storage_bucket_object" "default" {
  name   = format("%s/%s-%s.zip", var.name, "function-source", data.archive_file.default.output_md5)
  bucket = var.bucket_name
  source = data.archive_file.default.output_path
}

resource "google_cloudfunctions2_function" "default" {
  name        = var.name
  project     = var.project_id
  location    = var.location
  description = var.description

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point
    source {
      storage_source {
        bucket = var.bucket_name
        object = google_storage_bucket_object.default.name
      }
    }
  }

  service_config {
    max_instance_count             = coalesce(var.max_instance_count, 1)
    min_instance_count             = var.min_instance_count
    available_memory               = coalesce(var.available_memory, "256M")
    timeout_seconds                = coalesce(var.timeout, 540)
    ingress_settings               = coalesce(var.ingress_settings, "ALLOW_INTERNAL_ONLY")
    all_traffic_on_latest_revision = true
    service_account_email          = var.service_account_email
    environment_variables          = var.environment_variables
  }

  event_trigger {
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    trigger_region = var.location
    pubsub_topic   = var.pubsub_topic
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }

  labels = var.function_labels
}
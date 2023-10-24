data "archive_file" "default" {
  type        = "zip"
  output_path = "/tmp/${var.name}/function-source.zip"
  source_dir  = var.source_dir
}

resource "google_storage_bucket_object" "default" {
  name   = "${var.name}/function-source.zip"
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
    max_instance_count             = var.max_instance_count
    min_instance_count             = 1
    available_memory               = var.available_memory
    timeout_seconds                = var.timeout
    ingress_settings               = var.ingress_settings
    all_traffic_on_latest_revision = true
    service_account_email          = var.service_account_email
  }

  event_trigger {
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    trigger_region = var.location
    pubsub_topic   = var.pubsub_topic
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }
}
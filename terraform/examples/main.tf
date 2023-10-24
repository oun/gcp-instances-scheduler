locals {
  message = "{\"project\": \"${var.scheduled_project_id}\"}"
}

resource "google_service_account" "compute_function" {
  account_id   = "start-stop-compute-function"
  project      = var.project_id
  display_name = "Cloud Function Service Account"
}

resource "google_service_account" "sql_function" {
  account_id   = "start-stop-sql-function"
  project      = var.project_id
  display_name = "Cloud Function Service Account"
}

resource "google_project_iam_member" "compute_function" {
  project = var.scheduled_project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = google_service_account.compute_function.member
}

resource "google_project_iam_member" "sql_function" {
  project = var.scheduled_project_id
  role    = "roles/cloudsql.editor"
  member  = google_service_account.sql_function.member
}

module "start_stop_scheduler" {
  source             = "../"
  project_id         = var.project_id
  region             = var.region
  start_topic        = "start-instance-event"
  stop_topic         = "stop-instance-event"
  start_job_schedule = "0 8 * * 1-5"
  stop_job_schedule  = "0 20 * * 1-5"
  time_zone          = "Asia/Bangkok"
  service_account_emails = {
    start_compute_function = google_service_account.compute_function.email
    stop_compute_function  = google_service_account.compute_function.email
    start_sql_function     = google_service_account.sql_function.email
    stop_sql_function      = google_service_account.sql_function.email
  }
  start_message = local.message
  stop_message  = local.message
}
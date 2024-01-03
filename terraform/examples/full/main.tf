resource "google_service_account" "gce_function" {
  account_id   = "start-stop-gce-function"
  project      = var.project_id
  display_name = "Cloud Function Service Account"
}

resource "google_service_account" "sql_function" {
  account_id   = "start-stop-sql-function"
  project      = var.project_id
  display_name = "Cloud Function Service Account"
}

resource "google_service_account" "gke_function" {
  account_id   = "start-stop-gke-function"
  project      = var.project_id
  display_name = "Cloud Function Service Account"
}

resource "google_project_iam_member" "gce_function" {
  project = var.scheduled_project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = google_service_account.gce_function.member
}

resource "google_project_iam_member" "sql_function" {
  project = var.scheduled_project_id
  role    = "roles/cloudsql.editor"
  member  = google_service_account.sql_function.member
}

resource "google_project_iam_member" "gke_function" {
  project = var.scheduled_project_id
  role    = "roles/container.clusterAdmin"
  member  = google_service_account.gke_function.member
}

module "start_stop_scheduler" {
  source             = "../../"
  project_id         = var.project_id
  region             = var.region
  start_topic        = "start-instance-event"
  stop_topic         = "stop-instance-event"
  start_job_schedule = "0 8 * * 1-5"
  stop_job_schedule  = "0 20 * * 1-5"
  time_zone          = "Asia/Bangkok"
  scheduled_resource_filter = {
    project = var.scheduled_project_id
  }

  start_stop_gce_function = {
    enabled               = true
    service_account_email = google_service_account.gce_function.email
  }
  start_stop_sql_function = {
    enabled               = true
    service_account_email = google_service_account.sql_function.email
  }
  start_stop_gke_function = {
    enabled               = true
    service_account_email = google_service_account.gke_function.email
  }
}
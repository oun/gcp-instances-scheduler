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

  gce_function_config = {
    enabled = true
  }
  sql_function_config = {
    enabled = true
  }
  gke_function_config = {
    enabled = true
  }
}
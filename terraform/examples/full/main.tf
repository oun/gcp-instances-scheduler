module "start_stop_scheduler" {
  source     = "../../"
  project_id = var.project_id
  region     = var.region
  time_zone  = "Asia/Bangkok"

  schedules = [
    {
      start_job_name = "start-instances"
      stop_job_name  = "stop-instances"
      start_schedule = "0 8 * * 1-5"
      stop_schedule  = "0 20 * * 1-5"
      project        = var.scheduled_project_id
    }
  ]

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
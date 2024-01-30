module "start_stop_scheduler" {
  source     = "../../"
  project_id = var.project_id
  region     = var.region
  time_zone  = "Asia/Bangkok"

  schedules = [
    {
      start_schedule = "0 8 * * 1-5"
      stop_schedule  = "0 20 * * 1-5"
      project        = var.scheduled_project_id
    }
  ]
}
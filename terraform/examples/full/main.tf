module "start_stop_scheduler" {
  source     = "../../"
  project_id = var.project_id
  region     = var.region
  time_zone  = "Asia/Bangkok"

  schedules = [
    {
      # Start and stop schedules for CloudSQL and Compute Engine instances
      start_job_name = "start-instances"
      stop_job_name  = "stop-instances"
      start_schedule = "0 8 * * 1-5"
      stop_schedule  = "0 20 * * 1-5"
      project        = var.scheduled_project_id
      resource_types = ["gce", "sql"]
    },
    {
      # Start and stop schedules for GKE node pools with resource label
      start_job_name  = "start-node-pools"
      stop_job_name   = "stop-node-pools"
      start_schedule  = "0 8 * * 1-5"
      stop_schedule   = "0 20 * * 1-5"
      project         = var.scheduled_project_id
      resource_types  = ["gke"]
      resource_labels = { preemptible = "true" }
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
# Functions to Start and Stop Google Cloud Resources

Cloud Schedulers and Cloud Functions to automatically start and stop Compute Engine instance, SQL instance and Google Kubernetes Engine node pool on a regular schedule. This can be used in non-production environment that you need to stop on a nightly basis and restart them in the morning to save costs.

## Architecture

![docs/architecture.jpeg](docs/architecture.jpeg)

This includes the following Google Components:
- `Cloud scheduler` to make calls on a set schedule to start and stop the instance.
- `Pubsub topics` to send message for each start and stop event.
- `Cloud functions` to start and stop the instances we want to schedule.
- `Cloud SQL`, `GKE cluster`, `Compute Engine instance` we want to run on a schedule.

## Usage

There is a Terraform module that you can use to provision Cloud scheduler, Pubsub topics and cloud functions. Example can be seen in [`terraform/examples`](./terraform/examples/) directory.

```
module "start_stop_scheduler" {
  source             = "github.com/oun/gcp-instances-scheduler.git//terraform"
  project_id         = <project-id>
  region             = <region>
  start_topic        = "start-instance-event"
  stop_topic         = "stop-instance-event"
  start_job_schedule = "0 8 * * 1-5"
  stop_job_schedule  = "0 20 * * 1-5"
  time_zone          = "Asia/Bangkok"
  start_message      = "{\"project\": \"project-id\"}"
  stop_message       = "{\"project\": \"project-id\"}"
}
```
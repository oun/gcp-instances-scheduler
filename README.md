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
resource "google_service_account" "gce_function" {
  account_id   = "start-stop-gce-function"
  project      = "scheduler-project-id"
  display_name = "Cloud Function Service Account"
}

resource "google_project_iam_member" "gce_function" {
  project = "gce-instance-project-id"
  role    = "roles/compute.instanceAdmin.v1"
  member  = google_service_account.gce_function.member
}

module "start_stop_scheduler" {
  source             = "github.com/oun/gcp-instances-scheduler.git//terraform"
  project_id         = "scheduler-project-id"
  region             = "asia-southeast1"
  start_job_schedule = "0 8 * * 1-5"
  stop_job_schedule  = "0 20 * * 1-5"
  time_zone          = "Asia/Bangkok"
  start_message      = "{\"project\": \"gce-instance-project-id\"}"
  stop_message       = "{\"project\": \"gce-instance-project-id\"}"

  start_compute_function = {
    enabled               = true
    service_account_email = google_service_account.gce_function.email
  }
  stop_compute_function = {
    enabled               = true
    service_account_email = google_service_account.gce_function.email
  }
}
```

## Versioning

We use SemVer for versioning. For the versions available, see the [tags](https://github.com/oun/gcp-instances-scheduler/tags) on this repository.

## Authors

- Worawat - Initial work

## License

This project is licensed under the Apache-2.0 License - see the [LICENSE](./LICENSE) file for details.

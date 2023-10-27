# Terraform Start Stop Scheduler Module

This module setup Cloud Scheduler jobs to trigger Cloud Functions via pubsub topics to start and stop Compute Engine instances, GKE node pools and Cloud SQL instances.

## Usage

The following simple example setup scheduler to schedule Compute instance in the project gce-instance-project-id to start at 8AM and stop at 8PM on Monday to Friday. There are example in [`terraform/examples`](./terraform/examples/) directory.

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
  start_topic        = "start-instance-event"
  stop_topic         = "stop-instance-event"
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

Then perform the following commands:

- `terraform init` to get the plugins.
- `terraform plan` to see the infrastructure plan.
- `terraform apply` to apply the infrastructure build.
- `terraform destroy` to destroy the built infrastructure.

## Inputs

| Name                             | Description                                          | Type     | Default                | Required |
| -------------------------------- | ---------------------------------------------------- | -------- | ---------------------- | :------: |
| project_id                       | The project ID to host resources.                    | `string` | n/a                    |   yes    |
| region                           | The region to host resources.                        | `string` | n/a                    |   yes    |
| start_job_name                   | The name of scheduler that trigger start event.      | `string` | "start-instances"      |   yes    |
| start_job_description            | The additional text to describe the job.             | `string` | ""                     |    no    |
| start_job_schedule               | The job frequency in cron syntax.                    | `string` | n/a                    |   yes    |
| start_message                    | The message to send to the start event topic.        | `string` | "{}"                   |    no    |
| stop_job_name                    | The name of scheduler that trigger stop event.       | `string` | "stop-instances"       |    no    |
| stop_job_description             | The additional text to describe the job.             | `string` | ""                     |   yes    |
| stop_job_schedule                | The job frequency in cron syntax.                    | `string` | n/a                    |    no    |
| stop_message                     | The message to send to the stop event topic.         | `string` | "{}"                   |    no    |
| timezone                         | The timezone to use in scheduler.                    | `string` | "Etc/UTC"              |    no    |
| start_topic                      | The Pub/Sub topic name for start event.              | `string` | "start-instance-event" |    no    |
| stop_topic                       | The Pub/Sub topic name for stop event.               | `string` | "stop-instance-event"  |    no    |
| topic_labels                     | A map of labels to assign to the Pub/Sub topic.      | `string` | {}                     |    no    |
| topic_kms_key_name               | The resource name of the Cloud KMS CryptoKey.        | `string` | n/a                    |    no    |
| topic_message_retention_duration | The minimum duration in seconds to retain a message. | `string` | n/a                    |    no    |
| start_compute_function           | The settings for start compute instances function.   | `object` | n/a                    |    no    |
| stop_compute_function            | The settings for stop compute instances function.    | `object` | n/a                    |    no    |
| start_sql_function               | The settings for start SQL instances function.       | `object` | n/a                    |    no    |
| stop_sql_function                | The settings for stop SQL instances function.        | `object` | n/a                    |    no    |
| start_gke_function               | The settings for start GKE node pools function.      | `object` | n/a                    |    no    |
| stop_gke_function                | The settings for stop GKE node pools function.       | `object` | n/a                    |    no    |

The `cloud function` settings block:

| Name                  | Description                                                                                                                | Type     | Default | Required |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------- | -------- | ------- | :------: |
| enabled               | Whether the cloud function is enabled. When enabled, the cloud function will be deployed and recieved trigger from pubsub. | `bool`   | false   |   yes    |
| service_account_email | The service account to run function as.                                                                                    | `string` | n/a     |    no    |
| timeout               | The amount of time in seconds allotted for the execution of the function.                                                  | `number` | 540     |    no    |
| available_memory      | The amount of memory allotted for the function to use.                                                                     | `string` | "256M"  |    no    |
| max_instance_count    | The limit on the maximum number of function instances that may coexist at a given time.                                    | `number` | 1       |    no    |

## Requirements

These sections describe requirements for using this module.

### Softwares

The following dependencies must be available:

- Terraform >= 0.13.0
- Terraform Google Provider >= 4.34.0

### IAM Roles

A service account with the following roles must be used to provision the resources of this module:

- Storage Admin: `roles/storage.admin`
- PubSub Editor: `roles/pubsub.editor`
- Cloudscheduler Admin: `roles/cloudscheduler.admin`
- Cloudfunctions Developer: `roles/cloudfunctions.developer`

### Enable APIs

A project with the following APIs enabled must be used to host the resources of this module:

- Cloud Scheduler API - `cloudscheduler.googleapis.com`
- Cloud Function API - `cloudfunctions.googleapis.com`
- Eventarc API - `eventarc.googleapis.com`
- Cloud Run API - `run.googleapis.com`
- Cloud Build API - `cloudbuild.googleapis.com`
- Cloud SQL Admin API - `sqladmin.googleapis.com`
- Kubernetes Engine API - `container.googleapis.com`

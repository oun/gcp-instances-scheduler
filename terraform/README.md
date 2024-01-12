# Terraform Start Stop Scheduler Module

This module setup Cloud Scheduler jobs to trigger Cloud Functions via pubsub topics to start and stop Compute Engine instances, GKE node pools and Cloud SQL instances.

## Usage

The following simple example setup scheduler to schedule Compute instance in the project gce-instance-project-id to start at 8AM and stop at 8PM on Monday to Friday. There are example in [`terraform/examples`](./terraform/examples/) directory.

```
module "start_stop_scheduler" {
  source             = "github.com/oun/gcp-instances-scheduler.git//terraform"
  project_id         = "scheduler-project-id"
  region             = "asia-southeast1"
  start_topic        = "start-instance-event"
  stop_topic         = "stop-instance-event"
  start_job_schedule = "0 8 * * 1-5"
  stop_job_schedule  = "0 20 * * 1-5"
  time_zone          = "Asia/Bangkok"

  scheduled_resource_filter = {
    project = "gce-instance-project-id"
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
```

Then perform the following commands:

- `terraform init` to get the plugins.
- `terraform plan` to see the infrastructure plan.
- `terraform apply` to apply the infrastructure build.
- `terraform destroy` to destroy the built infrastructure.

## Inputs

| Name                             | Description                                                                                     | Type          | Default                 | Required |
| -------------------------------- | ----------------------------------------------------------------------------------------------- | ------------- | ----------------------- | :------: |
| project_id                       | The project ID to host resources.                                                               | `string`      | n/a                     |   yes    |
| region                           | The region to host resources.                                                                   | `string`      | n/a                     |   yes    |
| start_job_name                   | The name of scheduler that trigger start event.                                                 | `string`      | `start-instances`       |   yes    |
| start_job_description            | The additional text to describe the job.                                                        | `string`      | ``                      |    no    |
| start_job_schedule               | The job frequency in cron syntax.                                                               | `string`      | n/a                     |   yes    |
| stop_job_name                    | The name of scheduler that trigger stop event.                                                  | `string`      | `stop-instances`        |    no    |
| stop_job_description             | The additional text to describe the job.                                                        | `string`      | ``                      |   yes    |
| stop_job_schedule                | The job frequency in cron syntax.                                                               | `string`      | n/a                     |    no    |
| scheduled_resource_filter        | The filter that filter resources for scheduling.                                                | `object`      | `{}`                    |    no    |
| timezone                         | The timezone to use in scheduler.                                                               | `string`      | `Etc/UTC`               |    no    |
| start_topic                      | The Pub/Sub topic name for start event.                                                         | `string`      | `start-instance-event`  |    no    |
| stop_topic                       | The Pub/Sub topic name for stop event.                                                          | `string`      | `stop-instance-event`   |    no    |
| topic_labels                     | A map of labels to assign to the Pub/Sub topic.                                                 | `map(string)` | `{}`                    |    no    |
| topic_kms_key_name               | The resource name of the Cloud KMS CryptoKey.                                                   | `string`      | n/a                     |    no    |
| topic_message_retention_duration | The minimum duration in seconds to retain a message.                                            | `string`      | n/a                     |    no    |
| gce_function_config              | The settings for start/stop compute instances function.                                         | `object`      | `{"enabled": false}`    |    no    |
| sql_function_config              | The settings for start/stop SQL instances function.                                             | `object`      | `{"enabled": false}`    |    no    |
| gke_function_config              | The settings for start/stop GKE node pools function.                                            | `object`      | `{"enabled": false}`    |    no    |
| function_labels                  | A set of key/value label pairs to assign to the function.                                       | `map(string)` | `{}`                    |    no    |
| create_trigger_service_account   | If the service account to trigger function should be created.                                   | `bool`        | `true`                  |    no    |
| trigger_service_account_id       | The name of the service account that will be created if create_trigger_service_account is true. | `string`      | `sa-start-stop-trigger` |    no    |
| trigger_service_account_email    | The existing service account to trigger functions.                                              | `string`      | n/a                     |    no    |

The `scheduled_resource_filter` block:

| Name    | Description                       | Type          | Default      | Required |
| ------- | --------------------------------- | ------------- | ------------ | :------: |
| project | The project ID to host resources. | `string`      | `project_id` |    no    |
| labels  | The resource labels.              | `map(string)` | n/a          |    no    |

The `cloud function` settings block:

| Name                   | Description                                                                                                                | Type     | Default | Required |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------- | -------- | ------- | :------: |
| enabled                | Whether the cloud function is enabled. When enabled, the cloud function will be deployed and recieved trigger from pubsub. | `bool`   | `false` |   yes    |
| create_service_account | If the service account to run function should be created.                                                                  | `bool`   | n/a     |    no    |
| service_account_id     | The name of the service account that will be created if create_service_account is true.                                    | `string` | n/a     |    no    |
| service_account_email  | The service account to run function as.                                                                                    | `string` | n/a     |    no    |
| timeout                | The amount of time in seconds allotted for the execution of the function.                                                  | `number` | `540`   |    no    |
| available_memory       | The amount of memory allotted for the function to use.                                                                     | `string` | `256M`  |    no    |
| max_instance_count     | The limit on the maximum number of function instances that may coexist at a given time.                                    | `number` | `1`     |    no    |

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
- Pub/Sub API - `pubsub.googleapis.com`
- Cloud Run API - `run.googleapis.com`
- Artifact Registry API - `artifactregistry.googleapis.com`
- Cloud Build API - `cloudbuild.googleapis.com`
- Cloud SQL Admin API - `sqladmin.googleapis.com`
- Kubernetes Engine API - `container.googleapis.com`

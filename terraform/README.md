# Terraform Start Stop Scheduler Module

This module setup Cloud Scheduler jobs to trigger Cloud Functions via pubsub topics to start and stop Compute Engine instances, GKE node pools and Cloud SQL instances.

## Usage

The following simple example setup scheduler to schedule Compute instance in the project gce-instance-project-id to start at 8AM and stop at 8PM on Monday to Friday. There are example in [`terraform/examples`](./terraform/examples/) directory.

```
module "start_stop_scheduler" {
  source             = "github.com/oun/gcp-instances-scheduler.git//terraform"
  project_id         = "scheduler-project-id"
  region             = "asia-southeast1"
  time_zone          = "Asia/Bangkok"

  schedules = [
    {
      start_job_name = "start-instances"
      stop_job_name  = "stop-instances"
      start_schedule = "0 8 * * 1-5"
      stop_schedule  = "0 20 * * 1-5"
      project        = "resource-project-id"
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
```

Then perform the following commands:

- `terraform init` to get the plugins.
- `terraform plan` to see the infrastructure plan.
- `terraform apply` to apply the infrastructure build.
- `terraform destroy` to destroy the built infrastructure.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_trigger_service_account"></a> [create\_trigger\_service\_account](#input\_create\_trigger\_service\_account) | If the service account to trigger function should be created. | `bool` | `true` | no |
| <a name="input_function_labels"></a> [function\_labels](#input\_function\_labels) | A set of key/value label pairs to assign to the function. | `map(string)` | `{}` | no |
| <a name="input_gce_function_config"></a> [gce\_function\_config](#input\_gce\_function\_config) | The settings for start and stop Compute instances function. | <pre>object({<br>    enabled                = optional(bool, true)<br>    create_service_account = optional(bool, true)<br>    service_account_id     = optional(string, "sa-start-stop-gce-function")<br>    service_account_email  = optional(string)<br>    timeout                = optional(number)<br>    available_memory       = optional(string)<br>    max_instance_count     = optional(number)<br>  })</pre> | <pre>{<br>  "enabled": false<br>}</pre> | no |
| <a name="input_gke_function_config"></a> [gke\_function\_config](#input\_gke\_function\_config) | The settings for start and stop GKE function. | <pre>object({<br>    enabled                = optional(bool, true)<br>    create_service_account = optional(bool, true)<br>    service_account_id     = optional(string, "sa-start-stop-gke-function")<br>    service_account_email  = optional(string)<br>    timeout                = optional(number)<br>    available_memory       = optional(string)<br>    max_instance_count     = optional(number)<br>    shutdown_taint_key     = optional(string)<br>    shutdown_taint_value   = optional(string)<br>  })</pre> | <pre>{<br>  "enabled": false<br>}</pre> | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project where resources will be created. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region in which resources will be applied. | `string` | n/a | yes |
| <a name="input_schedules"></a> [schedules](#input\_schedules) | n/a | <pre>list(object({<br>    start_schedule        = string<br>    stop_schedule         = string<br>    start_job_name        = string<br>    stop_job_name         = string<br>    start_job_description = optional(string)<br>    stop_job_description  = optional(string)<br>    project               = string<br>    resource_types        = optional(list(string), ["gce", "sql", "gke"])<br>    resource_labels       = optional(map(string))<br>  }))</pre> | n/a | yes |
| <a name="input_sql_function_config"></a> [sql\_function\_config](#input\_sql\_function\_config) | The settings for start and stop SQL instance function. | <pre>object({<br>    enabled                = optional(bool, true)<br>    create_service_account = optional(bool, true)<br>    service_account_id     = optional(string, "sa-start-stop-sql-function")<br>    service_account_email  = optional(string)<br>    timeout                = optional(number)<br>    available_memory       = optional(string)<br>    max_instance_count     = optional(number)<br>  })</pre> | <pre>{<br>  "enabled": false<br>}</pre> | no |
| <a name="input_start_topic"></a> [start\_topic](#input\_start\_topic) | The Pub/Sub topic name for start event. | `string` | `"start-instance-event"` | no |
| <a name="input_stop_topic"></a> [stop\_topic](#input\_stop\_topic) | The Pub/Sub topic name for stop event. | `string` | `"stop-instance-event"` | no |
| <a name="input_time_zone"></a> [time\_zone](#input\_time\_zone) | The timezone to use in scheduler | `string` | `"Etc/UTC"` | no |
| <a name="input_topic_kms_key_name"></a> [topic\_kms\_key\_name](#input\_topic\_kms\_key\_name) | The resource name of the Cloud KMS CryptoKey to be used to protect access to messages published on this topic. | `string` | `null` | no |
| <a name="input_topic_labels"></a> [topic\_labels](#input\_topic\_labels) | A map of labels to assign to the Pub/Sub topic. | `map(string)` | `{}` | no |
| <a name="input_topic_message_retention_duration"></a> [topic\_message\_retention\_duration](#input\_topic\_message\_retention\_duration) | The minimum duration in seconds to retain a message after it is published to the topic. | `string` | `null` | no |
| <a name="input_trigger_service_account_email"></a> [trigger\_service\_account\_email](#input\_trigger\_service\_account\_email) | Service account to use as the identity for the Eventarc trigger. | `string` | `null` | no |
| <a name="input_trigger_service_account_id"></a> [trigger\_service\_account\_id](#input\_trigger\_service\_account\_id) | The name of the service account that will be created if create\_trigger\_service\_account is true. | `string` | `"sa-start-stop-trigger"` | no |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

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

The `schedules` block:

| Name                   | Description                                              | Type     | Default | Required |
| ---------------------- | -------------------------------------------------------- | -------- | ------- | :------: |
| start_schedule         | The start job frequency in cron syntax.                  | `string` | n/a     | yes      |
| stop_schedule          | The stop job frequency in cron syntax.                   | `string` | n/a     | yes      |
| start_job_name         | The name of scheduler that trigger start event.          | `string` | n/a     | yes      |
| stop_job_name          | The name of scheduler that trigger stop event.           | `string` | n/a     | yes      |
| start_job_description  | The additional text to describe the start job.           | `string` | n/a     | no       |
| stop_job_description   | The additional text to describe the stop job.            | `string` | n/a     | no       |
| project                | The project that host resources.                         | `string` | n/a     | yes      |
| resource_types         | The list of resource types. Default to all supported types. | `list(string)` | `["gce", "sql", "gke"]` | no      |
| resource_labels        | The optional resource labels.                           | `map(string)` | n/a     | no       |

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

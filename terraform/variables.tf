variable "project_id" {
  type        = string
  description = "The project where resources will be created."
}

variable "region" {
  type        = string
  description = "The region in which resources will be applied."
}

variable "start_job_name" {
  type        = string
  description = "The name of the scheduled job to run"
  default     = "start-instances"
}

variable "start_job_description" {
  type        = string
  description = "Addition text to describe the job"
  default     = ""
}

variable "start_job_schedule" {
  type        = string
  description = "The job frequency, in cron syntax"
}

variable "stop_job_name" {
  type        = string
  description = "The name of the scheduled job to run"
  default     = "stop-instances"
}

variable "stop_job_description" {
  type        = string
  description = "Addition text to describe the job"
  default     = ""
}

variable "stop_job_schedule" {
  type        = string
  description = "The job frequency, in cron syntax"
}

variable "time_zone" {
  type        = string
  description = "The timezone to use in scheduler"
  default     = "Etc/UTC"
}

variable "start_topic" {
  type        = string
  description = "The Pub/Sub topic name for start event."
  default     = "start-instance-event"
}

variable "stop_topic" {
  type        = string
  description = "The Pub/Sub topic name for stop event."
  default     = "stop-instance-event"
}

variable "topic_labels" {
  type        = map(string)
  description = "A map of labels to assign to the Pub/Sub topic."
  default     = {}
}

variable "scheduled_resource_filter" {
  type = object({
    project = optional(string)
    labels  = optional(map(string))
  })
  description = "The filter that filter resources for scheduling."
  default = {
  }
}

variable "topic_kms_key_name" {
  type        = string
  description = "The resource name of the Cloud KMS CryptoKey to be used to protect access to messages published on this topic."
  default     = null
}

variable "topic_message_retention_duration" {
  type        = string
  description = "The minimum duration in seconds to retain a message after it is published to the topic."
  default     = null
}

variable "start_stop_gce_function" {
  type = object({
    enabled               = bool
    service_account_email = optional(string)
    timeout               = optional(number)
    available_memory      = optional(string)
    max_instance_count    = optional(number)
  })
  description = "The start Compute Engine instances function settings."
  default = {
    enabled = false
  }
}

variable "start_stop_sql_function" {
  type = object({
    enabled               = bool
    service_account_email = optional(string)
    timeout               = optional(number)
    available_memory      = optional(string)
    max_instance_count    = optional(number)
  })
  description = "The start SQL instance function settings."
  default = {
    enabled = false
  }
}

variable "start_stop_gke_function" {
  type = object({
    enabled               = bool
    service_account_email = optional(string)
    timeout               = optional(number)
    available_memory      = optional(string)
    max_instance_count    = optional(number)
    shutdown_taint_key    = optional(string)
    shutdown_taint_value  = optional(string)
  })
  description = "The start GKE function settings."
  default = {
    enabled = false
  }
}

variable "function_labels" {
  type        = map(string)
  default     = {}
  description = "A set of key/value label pairs to assign to the function."
}

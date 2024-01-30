variable "project_id" {
  type        = string
  description = "The project where resources will be created."
}

variable "region" {
  type        = string
  description = "The region in which resources will be applied."
}

variable "schedules" {
  type = list(object({
    start_schedule        = string
    stop_schedule         = string
    start_job_name        = string
    stop_job_name         = string
    start_job_description = optional(string)
    stop_job_description  = optional(string)
    project               = string
    resource_labels       = optional(map(string))
  }))
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

variable "gce_function_config" {
  type = object({
    enabled                = optional(bool, true)
    create_service_account = optional(bool, true)
    service_account_id     = optional(string, "sa-start-stop-gce-function")
    service_account_email  = optional(string)
    timeout                = optional(number)
    available_memory       = optional(string)
    max_instance_count     = optional(number)
  })
  default = {
    enabled = false
  }
  description = "The settings for start and stop Compute instances function."
}

variable "sql_function_config" {
  type = object({
    enabled                = optional(bool, true)
    create_service_account = optional(bool, true)
    service_account_id     = optional(string, "sa-start-stop-sql-function")
    service_account_email  = optional(string)
    timeout                = optional(number)
    available_memory       = optional(string)
    max_instance_count     = optional(number)
  })
  default = {
    enabled = false
  }
  description = "The settings for start and stop SQL instance function."
}

variable "gke_function_config" {
  type = object({
    enabled                = optional(bool, true)
    create_service_account = optional(bool, true)
    service_account_id     = optional(string, "sa-start-stop-gke-function")
    service_account_email  = optional(string)
    timeout                = optional(number)
    available_memory       = optional(string)
    max_instance_count     = optional(number)
    shutdown_taint_key     = optional(string)
    shutdown_taint_value   = optional(string)
  })
  default = {
    enabled = false
  }
  description = "The settings for start and stop GKE function."
}

variable "function_labels" {
  type        = map(string)
  default     = {}
  description = "A set of key/value label pairs to assign to the function."
}

variable "create_trigger_service_account" {
  type        = bool
  description = "If the service account to trigger function should be created."
  default     = true
}

variable "trigger_service_account_id" {
  type        = string
  description = "The name of the service account that will be created if create_trigger_service_account is true."
  default     = "sa-start-stop-trigger"
}

variable "trigger_service_account_email" {
  type        = string
  default     = null
  description = "Service account to use as the identity for the Eventarc trigger."
}

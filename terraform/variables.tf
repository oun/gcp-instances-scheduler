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

variable "start_message" {
  type        = string
  description = "The data to send in the topic message."
  default     = "{}"
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

variable "stop_message" {
  type        = string
  description = "The data to send in the topic message."
  default     = "{}"
}

variable "time_zone" {
  type        = string
  description = "The timezone to use in scheduler"
  default     = "Etc/UTC"
}

variable "start_topic" {
  type        = string
  description = "The Pub/Sub topic name for start event."
}

variable "stop_topic" {
  type        = string
  description = "The Pub/Sub topic name for stop event."
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

variable "service_account_emails" {
  type = object({
    start_compute_function = string
    stop_compute_function  = string
    start_sql_function     = string
    stop_sql_function      = string
  })
  description = "The existing service accounts to run cloud functions."
  default = {
    start_compute_function = ""
    stop_compute_function  = ""
    start_sql_function     = ""
    stop_sql_function      = ""
  }
}